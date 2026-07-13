from __future__ import annotations

import sqlite3
from datetime import datetime

from flask import Blueprint, g, request
from werkzeug.security import generate_password_hash

from api_utils import (
    ACCOUNT_RE,
    as_float,
    as_int,
    body_json,
    fail,
    ok,
    page_result,
    pagination,
    parse_date,
    parse_datetime,
    utc_now_sql,
)
from auth_guard import roles_required
from db import get_db
from services import (
    existing_booking_for_recurring_schedule,
    recurring_schedule_conflict,
    semester_by_code,
)

bp = Blueprint("admin", __name__, url_prefix="/api/admin")

MANAGER_ROLES = ("ACADEMIC_STAFF", "ADMIN")


def _user_detail(conn, user_id: int):
    row = conn.execute(
        """
        SELECT u.*, d.department_name, cg.class_name, cg.grade, cg.major_name
        FROM sys_user u
        LEFT JOIN department d ON d.id = u.department_id
        LEFT JOIN class_group cg ON cg.id = u.class_id
        WHERE u.id = ?
        """,
        (user_id,),
    ).fetchone()
    if row is None:
        return None
    data = dict(row)
    data.pop("password_hash", None)
    if row["role"] == "STUDENT":
        profile = conn.execute("SELECT * FROM student_profile WHERE user_id = ?", (user_id,)).fetchone()
    elif row["role"] == "TEACHER":
        profile = conn.execute("SELECT * FROM teacher_profile WHERE user_id = ?", (user_id,)).fetchone()
    else:
        profile = conn.execute("SELECT * FROM academic_staff_profile WHERE user_id = ?", (user_id,)).fetchone()
    data["role_profile"] = dict(profile) if profile else None
    return data


@bp.get("/users")
@roles_required(*MANAGER_ROLES)
def users():
    page, page_size, offset = pagination()
    where = ["1=1"]
    params: list = []
    if request.args.get("role"):
        where.append("u.role = ?")
        params.append(request.args["role"])
    if request.args.get("status") is not None:
        where.append("u.status = ?")
        params.append(request.args["status"])
    if request.args.get("departmentId"):
        where.append("u.department_id = ?")
        params.append(request.args["departmentId"])
    if request.args.get("classId"):
        where.append("u.class_id = ?")
        params.append(request.args["classId"])
    if request.args.get("keyword"):
        keyword = f"%{request.args['keyword']}%"
        where.append("(u.account LIKE ? OR u.real_name LIKE ?)")
        params.extend([keyword, keyword])
    where_sql = " AND ".join(where)
    conn = get_db()
    total = conn.execute(f"SELECT COUNT(*) FROM sys_user u WHERE {where_sql}", params).fetchone()[0]
    rows = conn.execute(
        f"""
        SELECT u.id, u.account, u.real_name, u.role, u.gender, u.phone, u.email,
               u.department_id, u.class_id, u.status, u.last_login_at,
               d.department_name, cg.class_name
        FROM sys_user u
        LEFT JOIN department d ON d.id = u.department_id
        LEFT JOIN class_group cg ON cg.id = u.class_id
        WHERE {where_sql}
        ORDER BY u.role, u.account
        LIMIT ? OFFSET ?
        """,
        params + [page_size, offset],
    ).fetchall()
    return ok(page_result([dict(row) for row in rows], total, page, page_size))


@bp.post("/users")
@roles_required(*MANAGER_ROLES)
def create_user():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    account = str(body.get("account", "")).strip()
    password = str(body.get("initialPassword", ""))
    real_name = str(body.get("realName", "")).strip()
    role = str(body.get("role", "")).upper()
    if not ACCOUNT_RE.fullmatch(account):
        return fail(40001, "账号必须为3到32位字母、数字、点、下划线或短横线")
    if len(password) < 6 or len(password) > 64:
        return fail(40001, "初始密码长度必须为6到64位")
    if not real_name:
        return fail(40001, "真实姓名不能为空")
    if role not in {"STUDENT", "TEACHER", "ACADEMIC_STAFF", "ADMIN"}:
        return fail(40001, "role不合法")
    if g.current_user["role"] == "ACADEMIC_STAFF" and role in {"ACADEMIC_STAFF", "ADMIN"}:
        return fail(40301, "只有管理员可以创建教务或管理员账号", 403)

    try:
        gender = as_int(body.get("gender", 0), "gender", minimum=0)
        if gender not in {0, 1, 2}:
            return fail(40001, "gender必须为0、1或2")
        department_id = as_int(body.get("departmentId"), "departmentId", required=False, minimum=1)
        class_id = as_int(body.get("classId"), "classId", required=False, minimum=1)
    except ValueError as exc:
        return fail(40001, str(exc))

    conn = get_db()
    if department_id and conn.execute("SELECT 1 FROM department WHERE id = ? AND status = 1", (department_id,)).fetchone() is None:
        return fail(40401, "院系不存在或已停用", 404)
    if class_id:
        class_row = conn.execute("SELECT department_id FROM class_group WHERE id = ? AND status = 1", (class_id,)).fetchone()
        if class_row is None:
            return fail(40402, "班级不存在或已停用", 404)
        department_id = class_row["department_id"]
    if role == "STUDENT" and class_id is None:
        return fail(40001, "学生账号必须指定classId")
    if role != "STUDENT":
        class_id = None

    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO sys_user(
                account, password_hash, real_name, role, gender, phone, email,
                avatar_url, department_id, class_id, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            """,
            (
                account,
                generate_password_hash(password),
                real_name,
                role,
                gender,
                body.get("phone") or None,
                body.get("email") or None,
                body.get("avatarUrl") or None,
                department_id,
                class_id,
            ),
        )
        user_id = cursor.lastrowid
        if role == "STUDENT":
            student_no = str(body.get("studentNo") or account).strip()
            conn.execute(
                """
                INSERT INTO student_profile(
                    user_id, student_no, admission_date, academic_status, earned_credits
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    student_no,
                    body.get("admissionDate") or None,
                    body.get("academicStatus", "ACTIVE"),
                    float(body.get("earnedCredits", 0)),
                ),
            )
        elif role == "TEACHER":
            conn.execute(
                """
                INSERT INTO teacher_profile(
                    user_id, employee_no, professional_title, introduction
                ) VALUES (?, ?, ?, ?)
                """,
                (
                    user_id,
                    str(body.get("employeeNo") or account).strip(),
                    body.get("professionalTitle") or None,
                    body.get("introduction") or None,
                ),
            )
        else:
            conn.execute(
                """
                INSERT INTO academic_staff_profile(
                    user_id, employee_no, responsibility_area, approval_level
                ) VALUES (?, ?, ?, ?)
                """,
                (
                    user_id,
                    str(body.get("employeeNo") or account).strip(),
                    body.get("responsibilityArea") or None,
                    int(body.get("approvalLevel", 1)),
                ),
            )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40901, f"账号、学号或工号重复，或数据不合法：{exc}", 409)
    except Exception:
        conn.rollback()
        return fail(50001, "账号创建失败", 500)
    return ok(_user_detail(conn, user_id), "账号创建成功", 201)


@bp.get("/users/<int:user_id>")
@roles_required(*MANAGER_ROLES)
def user_detail(user_id: int):
    data = _user_detail(get_db(), user_id)
    if data is None:
        return fail(40401, "用户不存在", 404)
    return ok(data)


@bp.put("/users/<int:user_id>")
@roles_required(*MANAGER_ROLES)
def update_user(user_id: int):
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    conn = get_db()
    user = conn.execute("SELECT * FROM sys_user WHERE id = ?", (user_id,)).fetchone()
    if user is None:
        return fail(40401, "用户不存在", 404)
    if g.current_user["role"] == "ACADEMIC_STAFF" and user["role"] in {"ACADEMIC_STAFF", "ADMIN"}:
        return fail(40301, "教务人员不能修改教务或管理员账号", 403)

    common_map = {
        "realName": "real_name",
        "gender": "gender",
        "phone": "phone",
        "email": "email",
        "avatarUrl": "avatar_url",
        "departmentId": "department_id",
        "classId": "class_id",
    }
    fields = []
    params = []
    for api_name, db_name in common_map.items():
        if api_name in body:
            fields.append(f"{db_name} = ?")
            params.append(body.get(api_name) or None)

    try:
        conn.execute("BEGIN IMMEDIATE")
        if fields:
            fields.append("updated_at = ?")
            params.extend([utc_now_sql(), user_id])
            conn.execute(f"UPDATE sys_user SET {', '.join(fields)} WHERE id = ?", params)

        if user["role"] == "STUDENT":
            mapping = {
                "studentNo": "student_no",
                "admissionDate": "admission_date",
                "academicStatus": "academic_status",
                "earnedCredits": "earned_credits",
            }
            table = "student_profile"
        elif user["role"] == "TEACHER":
            mapping = {
                "employeeNo": "employee_no",
                "professionalTitle": "professional_title",
                "introduction": "introduction",
            }
            table = "teacher_profile"
        else:
            mapping = {
                "employeeNo": "employee_no",
                "responsibilityArea": "responsibility_area",
                "approvalLevel": "approval_level",
            }
            table = "academic_staff_profile"
        p_fields = []
        p_params = []
        for api_name, db_name in mapping.items():
            if api_name in body:
                p_fields.append(f"{db_name} = ?")
                p_params.append(body.get(api_name) or None)
        if p_fields:
            p_fields.append("updated_at = ?")
            p_params.extend([utc_now_sql(), user_id])
            conn.execute(f"UPDATE {table} SET {', '.join(p_fields)} WHERE user_id = ?", p_params)
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40901, f"数据重复或不合法：{exc}", 409)
    except Exception:
        conn.rollback()
        return fail(50001, "用户资料更新失败", 500)
    return ok(_user_detail(conn, user_id), "用户资料更新成功")


@bp.post("/users/<int:user_id>/status")
@roles_required(*MANAGER_ROLES)
def user_status(user_id: int):
    body = body_json() or {}
    try:
        status = int(body.get("status"))
    except (TypeError, ValueError):
        return fail(40001, "status必须为0或1")
    if status not in {0, 1}:
        return fail(40001, "status必须为0或1")
    conn = get_db()
    user = conn.execute("SELECT role FROM sys_user WHERE id = ?", (user_id,)).fetchone()
    if user is None:
        return fail(40401, "用户不存在", 404)
    if user_id == g.current_user["id"] and status == 0:
        return fail(40901, "不能停用自己的账号", 409)
    if g.current_user["role"] == "ACADEMIC_STAFF" and user["role"] in {"ACADEMIC_STAFF", "ADMIN"}:
        return fail(40301, "教务人员不能修改高权限账号状态", 403)
    conn.execute("UPDATE sys_user SET status = ?, updated_at = ? WHERE id = ?", (status, utc_now_sql(), user_id))
    if status == 0:
        conn.execute("UPDATE auth_token SET revoked = 1 WHERE user_id = ?", (user_id,))
    conn.commit()
    return ok(None, "账号状态已更新")


@bp.post("/users/<int:user_id>/reset-password")
@roles_required(*MANAGER_ROLES)
def reset_password(user_id: int):
    body = body_json() or {}
    password = str(body.get("newPassword", ""))
    if len(password) < 6 or len(password) > 64:
        return fail(40001, "新密码长度必须为6到64位")
    conn = get_db()
    user = conn.execute("SELECT role FROM sys_user WHERE id = ?", (user_id,)).fetchone()
    if user is None:
        return fail(40401, "用户不存在", 404)
    if g.current_user["role"] == "ACADEMIC_STAFF" and user["role"] in {"ACADEMIC_STAFF", "ADMIN"}:
        return fail(40301, "教务人员不能重置高权限账号密码", 403)
    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            "UPDATE sys_user SET password_hash = ?, updated_at = ? WHERE id = ?",
            (generate_password_hash(password), utc_now_sql(), user_id),
        )
        conn.execute("UPDATE auth_token SET revoked = 1 WHERE user_id = ?", (user_id,))
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "密码重置失败", 500)
    return ok(None, "密码已重置，原Token已失效")


# ---------- 院系、班级、教室基础数据 ----------

@bp.post("/departments")
@roles_required(*MANAGER_ROLES)
def create_department():
    body = body_json() or {}
    code = str(body.get("departmentCode", "")).strip()
    name = str(body.get("departmentName", "")).strip()
    if not code or not name:
        return fail(40001, "院系代码和名称不能为空")
    conn = get_db()
    try:
        cursor = conn.execute(
            "INSERT INTO department(department_code, department_name, manager_name) VALUES (?, ?, ?)",
            (code, name, body.get("managerName") or None),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        return fail(40901, "院系代码已存在", 409)
    return ok({"departmentId": cursor.lastrowid}, "院系创建成功", 201)


@bp.put("/departments/<int:department_id>")
@roles_required(*MANAGER_ROLES)
def update_department(department_id: int):
    body = body_json() or {}
    conn = get_db()
    row = conn.execute("SELECT 1 FROM department WHERE id = ?", (department_id,)).fetchone()
    if row is None:
        return fail(40401, "院系不存在", 404)
    conn.execute(
        """
        UPDATE department
        SET department_code = COALESCE(?, department_code),
            department_name = COALESCE(?, department_name),
            manager_name = ?, status = COALESCE(?, status), updated_at = ?
        WHERE id = ?
        """,
        (
            body.get("departmentCode"), body.get("departmentName"),
            body.get("managerName"), body.get("status"), utc_now_sql(), department_id,
        ),
    )
    conn.commit()
    return ok(None, "院系更新成功")


@bp.post("/classes")
@roles_required(*MANAGER_ROLES)
def create_class():
    body = body_json() or {}
    required = ["classCode", "className", "grade", "majorName", "departmentId"]
    if any(body.get(key) in {None, ""} for key in required):
        return fail(40001, "班级代码、名称、年级、专业和院系不能为空")
    conn = get_db()
    try:
        cursor = conn.execute(
            """
            INSERT INTO class_group(
                class_code, class_name, grade, major_name, department_id,
                campus, student_count, counselor_name
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                body["classCode"], body["className"], str(body["grade"]),
                body["majorName"], body["departmentId"], body.get("campus"),
                int(body.get("studentCount", 0)), body.get("counselorName"),
            ),
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40901, f"班级数据不合法：{exc}", 409)
    return ok({"classId": cursor.lastrowid}, "班级创建成功", 201)


@bp.put("/classes/<int:class_id>")
@roles_required(*MANAGER_ROLES)
def update_class(class_id: int):
    body = body_json() or {}
    conn = get_db()
    row = conn.execute("SELECT * FROM class_group WHERE id = ?", (class_id,)).fetchone()
    if row is None:
        return fail(40401, "班级不存在", 404)
    values = {
        "class_code": body.get("classCode", row["class_code"]),
        "class_name": body.get("className", row["class_name"]),
        "grade": str(body.get("grade", row["grade"])),
        "major_name": body.get("majorName", row["major_name"]),
        "department_id": body.get("departmentId", row["department_id"]),
        "campus": body.get("campus", row["campus"]),
        "student_count": body.get("studentCount", row["student_count"]),
        "counselor_name": body.get("counselorName", row["counselor_name"]),
        "status": body.get("status", row["status"]),
    }
    conn.execute(
        """
        UPDATE class_group SET class_code=?, class_name=?, grade=?, major_name=?,
            department_id=?, campus=?, student_count=?, counselor_name=?, status=?, updated_at=?
        WHERE id=?
        """,
        (*values.values(), utc_now_sql(), class_id),
    )
    conn.commit()
    return ok(None, "班级更新成功")


@bp.post("/classrooms")
@roles_required(*MANAGER_ROLES)
def create_classroom():
    body = body_json() or {}
    required = ["classroomCode", "classroomName", "campus", "building", "roomType", "capacity"]
    if any(body.get(key) in {None, ""} for key in required):
        return fail(40001, "教室编号、名称、校区、教学楼、类型和容量不能为空")
    conn = get_db()
    try:
        cursor = conn.execute(
            """
            INSERT INTO classroom(
                classroom_code, classroom_name, campus, building, floor,
                room_type, capacity, equipment, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                body["classroomCode"], body["classroomName"], body["campus"],
                body["building"], body.get("floor"), body["roomType"],
                int(body["capacity"]), body.get("equipment"), body.get("status", "AVAILABLE"),
            ),
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40901, f"教室数据不合法：{exc}", 409)
    return ok({"classroomId": cursor.lastrowid}, "教室创建成功", 201)


@bp.put("/classrooms/<int:classroom_id>")
@roles_required(*MANAGER_ROLES)
def update_classroom(classroom_id: int):
    body = body_json() or {}
    conn = get_db()
    row = conn.execute("SELECT * FROM classroom WHERE id = ?", (classroom_id,)).fetchone()
    if row is None:
        return fail(40401, "教室不存在", 404)
    mapping = {
        "classroomCode": "classroom_code", "classroomName": "classroom_name",
        "campus": "campus", "building": "building", "floor": "floor",
        "roomType": "room_type", "capacity": "capacity", "equipment": "equipment",
        "status": "status",
    }
    fields, params = [], []
    for api_name, db_name in mapping.items():
        if api_name in body:
            fields.append(f"{db_name} = ?")
            params.append(body[api_name])
    if not fields:
        return ok(None, "没有需要修改的字段")
    fields.append("updated_at = ?")
    params.extend([utc_now_sql(), classroom_id])
    try:
        conn.execute(f"UPDATE classroom SET {', '.join(fields)} WHERE id = ?", params)
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40901, f"教室数据不合法：{exc}", 409)
    return ok(None, "教室更新成功")


# ---------- 学期、课程和排课 ----------

@bp.post("/semesters")
@roles_required(*MANAGER_ROLES)
def create_semester():
    body = body_json() or {}
    code = str(body.get("semesterCode", "")).strip()
    name = str(body.get("semesterName", "")).strip()
    try:
        start = parse_date(body.get("startDate"), "startDate")
        end = parse_date(body.get("endDate"), "endDate")
    except ValueError as exc:
        return fail(40001, str(exc))
    if not code or not name:
        return fail(40001, "学期代码和名称不能为空")
    if end < start:
        return fail(40001, "endDate不能早于startDate")
    conn = get_db()
    try:
        cursor = conn.execute(
            "INSERT INTO semester(semester_code, semester_name, start_date, end_date) VALUES (?, ?, ?, ?)",
            (code, name, start.isoformat(), end.isoformat()),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        return fail(40901, "学期代码已存在", 409)
    return ok({"semesterId": cursor.lastrowid}, "学期创建成功", 201)


@bp.put("/semesters/<int:semester_id>")
@roles_required(*MANAGER_ROLES)
def update_semester(semester_id: int):
    body = body_json() or {}
    conn = get_db()
    row = conn.execute("SELECT * FROM semester WHERE id = ?", (semester_id,)).fetchone()
    if row is None:
        return fail(40401, "学期不存在", 404)
    start = body.get("startDate", row["start_date"])
    end = body.get("endDate", row["end_date"])
    if end < start:
        return fail(40001, "endDate不能早于startDate")
    conn.execute(
        """
        UPDATE semester SET semester_code=?, semester_name=?, start_date=?, end_date=?,
            status=?, updated_at=? WHERE id=?
        """,
        (
            body.get("semesterCode", row["semester_code"]),
            body.get("semesterName", row["semester_name"]),
            start, end, body.get("status", row["status"]), utc_now_sql(), semester_id,
        ),
    )
    conn.commit()
    return ok(None, "学期更新成功")


@bp.post("/courses")
@roles_required(*MANAGER_ROLES)
def create_course():
    body = body_json() or {}
    required = ["courseCode", "courseName", "teacherId", "departmentId", "selectionStart", "selectionEnd"]
    if any(body.get(key) in {None, ""} for key in required):
        return fail(40001, "课程编号、名称、教师、院系和选课时间不能为空")
    try:
        start = parse_datetime(body["selectionStart"], "selectionStart")
        end = parse_datetime(body["selectionEnd"], "selectionEnd")
        capacity = as_int(body.get("capacity", 50), "capacity", minimum=1)
        credit = as_float(body.get("credit", 0), "credit", minimum=0)
    except ValueError as exc:
        return fail(40001, str(exc))
    if end <= start:
        return fail(40001, "selectionEnd必须晚于selectionStart")
    conn = get_db()
    teacher = conn.execute("SELECT role, status FROM sys_user WHERE id = ?", (body["teacherId"],)).fetchone()
    if teacher is None or teacher["role"] != "TEACHER" or teacher["status"] != 1:
        return fail(40002, "teacherId必须对应正常教师")
    try:
        cursor = conn.execute(
            """
            INSERT INTO course(
                course_code, course_name, teacher_id, department_id, capacity,
                credit, selection_start, selection_end, selection_status, status, description
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                body["courseCode"], body["courseName"], body["teacherId"], body["departmentId"],
                capacity, credit, start.isoformat(sep=" "), end.isoformat(sep=" "),
                body.get("selectionStatus", "CLOSED"), body.get("status", 1), body.get("description"),
            ),
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40901, f"课程数据不合法：{exc}", 409)
    return ok({"courseId": cursor.lastrowid}, "课程创建成功", 201)


@bp.put("/courses/<int:course_id>")
@roles_required(*MANAGER_ROLES)
def update_course(course_id: int):
    body = body_json() or {}
    conn = get_db()
    row = conn.execute("SELECT * FROM course WHERE id = ?", (course_id,)).fetchone()
    if row is None:
        return fail(40401, "课程不存在", 404)
    capacity = int(body.get("capacity", row["capacity"]))
    if capacity < row["selected_count"]:
        return fail(40901, "容量不能小于当前已选人数", 409)
    values = {
        "course_code": body.get("courseCode", row["course_code"]),
        "course_name": body.get("courseName", row["course_name"]),
        "teacher_id": body.get("teacherId", row["teacher_id"]),
        "department_id": body.get("departmentId", row["department_id"]),
        "capacity": capacity,
        "credit": body.get("credit", row["credit"]),
        "selection_start": str(body.get("selectionStart", row["selection_start"])).replace("T", " "),
        "selection_end": str(body.get("selectionEnd", row["selection_end"])).replace("T", " "),
        "selection_status": body.get("selectionStatus", row["selection_status"]),
        "status": body.get("status", row["status"]),
        "description": body.get("description", row["description"]),
    }
    try:
        conn.execute(
            """
            UPDATE course SET course_code=?, course_name=?, teacher_id=?, department_id=?,
                capacity=?, credit=?, selection_start=?, selection_end=?, selection_status=?,
                status=?, description=?, updated_at=? WHERE id=?
            """,
            (*values.values(), utc_now_sql(), course_id),
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40902, f"课程数据不合法：{exc}", 409)
    return ok(None, "课程更新成功")


@bp.post("/courses/<int:course_id>/status")
@roles_required(*MANAGER_ROLES)
def course_status(course_id: int):
    body = body_json() or {}
    conn = get_db()
    cursor = conn.execute(
        "UPDATE course SET status = ?, selection_status = COALESCE(?, selection_status), updated_at = ? WHERE id = ?",
        (body.get("status", 1), body.get("selectionStatus"), utc_now_sql(), course_id),
    )
    conn.commit()
    if cursor.rowcount == 0:
        return fail(40401, "课程不存在", 404)
    return ok(None, "课程状态已更新")


def _schedule_payload(body: dict, old=None):
    def get(name, default=None):
        return body[name] if name in body else default
    course_id = int(get("courseId", old["course_id"] if old else 0))
    classroom_id = int(get("classroomId", old["classroom_id"] if old else 0))
    semester = str(get("semester", old["semester"] if old else ""))
    start_week = int(get("startWeek", old["start_week"] if old else 0))
    end_week = int(get("endWeek", old["end_week"] if old else 0))
    week_day = int(get("weekDay", old["week_day"] if old else 0))
    start_section = int(get("startSection", old["start_section"] if old else 0))
    end_section = int(get("endSection", old["end_section"] if old else 0))
    week_type = str(get("weekType", old["week_type"] if old else "ALL")).upper()
    if not course_id or not classroom_id or not semester:
        raise ValueError("courseId、classroomId和semester不能为空")
    if start_week < 1 or end_week < start_week:
        raise ValueError("周次范围不合法")
    if week_day < 1 or week_day > 7:
        raise ValueError("weekDay必须为1到7")
    if start_section < 1 or end_section < start_section:
        raise ValueError("节次范围不合法")
    if week_type not in {"ALL", "ODD", "EVEN"}:
        raise ValueError("weekType必须为ALL、ODD或EVEN")
    return course_id, classroom_id, semester, start_week, end_week, week_day, start_section, end_section, week_type


def _validate_schedule(conn, payload, exclude_id=None):
    course_id, classroom_id, semester_code, start_week, end_week, week_day, start_section, end_section, week_type = payload
    course = conn.execute("SELECT teacher_id FROM course WHERE id = ? AND status = 1", (course_id,)).fetchone()
    if course is None:
        return "课程不存在或已停用", None
    room = conn.execute("SELECT status FROM classroom WHERE id = ?", (classroom_id,)).fetchone()
    if room is None or room["status"] != "AVAILABLE":
        return "教室不存在或不可用", None
    semester = semester_by_code(conn, semester_code)
    if semester is None:
        return "学期不存在或已停用", None
    conflict = recurring_schedule_conflict(
        conn,
        semester_code=semester_code,
        teacher_id=course["teacher_id"],
        classroom_id=classroom_id,
        start_week=start_week,
        end_week=end_week,
        week_day=week_day,
        start_section=start_section,
        end_section=end_section,
        week_type=week_type,
        exclude_schedule_id=exclude_id,
    )
    if conflict:
        return "教师或教室与已有排课冲突", conflict
    booking = existing_booking_for_recurring_schedule(
        conn,
        semester_row=semester,
        classroom_id=classroom_id,
        start_week=start_week,
        end_week=end_week,
        week_day=week_day,
        start_section=start_section,
        end_section=end_section,
        week_type=week_type,
    )
    if booking:
        return "排课与已有教室预约冲突", booking
    return None, None


@bp.post("/schedules")
@roles_required(*MANAGER_ROLES)
def create_schedule():
    body = body_json() or {}
    try:
        payload = _schedule_payload(body)
    except (ValueError, TypeError) as exc:
        return fail(40001, str(exc))
    conn = get_db()
    message, detail = _validate_schedule(conn, payload)
    if message:
        return fail(40901, message, 409, detail)
    try:
        cursor = conn.execute(
            """
            INSERT INTO course_schedule(
                course_id, classroom_id, semester, start_week, end_week,
                week_day, start_section, end_section, week_type, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')
            """,
            payload,
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        return fail(40902, str(exc), 409)
    return ok({"scheduleId": cursor.lastrowid}, "排课创建成功", 201)


@bp.put("/schedules/<int:schedule_id>")
@roles_required(*MANAGER_ROLES)
def update_schedule(schedule_id: int):
    body = body_json() or {}
    conn = get_db()
    old = conn.execute("SELECT * FROM course_schedule WHERE id = ?", (schedule_id,)).fetchone()
    if old is None:
        return fail(40401, "排课不存在", 404)
    try:
        payload = _schedule_payload(body, old)
    except (ValueError, TypeError) as exc:
        return fail(40001, str(exc))
    message, detail = _validate_schedule(conn, payload, exclude_id=schedule_id)
    if message:
        return fail(40901, message, 409, detail)
    conn.execute(
        """
        UPDATE course_schedule SET course_id=?, classroom_id=?, semester=?, start_week=?,
            end_week=?, week_day=?, start_section=?, end_section=?, week_type=?, updated_at=?
        WHERE id=?
        """,
        (*payload, utc_now_sql(), schedule_id),
    )
    conn.commit()
    return ok(None, "排课更新成功")


@bp.post("/schedules/<int:schedule_id>/cancel")
@roles_required(*MANAGER_ROLES)
def cancel_schedule(schedule_id: int):
    conn = get_db()
    cursor = conn.execute(
        "UPDATE course_schedule SET status = 'CANCELLED', updated_at = ? WHERE id = ?",
        (utc_now_sql(), schedule_id),
    )
    conn.commit()
    if cursor.rowcount == 0:
        return fail(40401, "排课不存在", 404)
    return ok(None, "排课已取消")


@bp.get("/approvals")
@roles_required(*MANAGER_ROLES)
def approvals():
    conn = get_db()
    sql = """
        SELECT ar.*, u.real_name AS approver_name
        FROM approval_record ar
        JOIN sys_user u ON u.id = ar.approver_id
        WHERE 1=1
    """
    params: list = []
    if request.args.get("businessType"):
        sql += " AND ar.business_type = ?"
        params.append(request.args["businessType"])
    if request.args.get("approverId"):
        sql += " AND ar.approver_id = ?"
        params.append(request.args["approverId"])
    sql += " ORDER BY ar.created_at DESC"
    rows = conn.execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])
