from __future__ import annotations

import sqlite3

from flask import Blueprint, g, request

from api_utils import fail, ok, page_result, pagination, parse_date, utc_now_sql
from auth_guard import auth_required, roles_required
from db import get_db
from services import effective_schedules_for_date

bp = Blueprint("courses", __name__, url_prefix="/api")


def _course_schedules(conn, course_id: int):
    rows = conn.execute(
        """
        SELECT cs.*, cr.classroom_code, cr.classroom_name, cr.campus, cr.building
        FROM course_schedule cs
        JOIN classroom cr ON cr.id = cs.classroom_id
        WHERE cs.course_id = ? AND cs.status = 'ACTIVE'
        ORDER BY cs.semester DESC, cs.week_day, cs.start_section
        """,
        (course_id,),
    ).fetchall()
    return [dict(row) for row in rows]


@bp.get("/courses")
@auth_required
def course_list():
    page, page_size, offset = pagination()
    conn = get_db()
    where = ["c.status = 1"]
    params: list = []
    if request.args.get("selectionStatus"):
        where.append("c.selection_status = ?")
        params.append(request.args["selectionStatus"])
    if request.args.get("departmentId"):
        where.append("c.department_id = ?")
        params.append(request.args["departmentId"])
    if request.args.get("keyword"):
        where.append("(c.course_code LIKE ? OR c.course_name LIKE ?)")
        keyword = f"%{request.args['keyword']}%"
        params.extend([keyword, keyword])
    where_sql = " AND ".join(where)
    total = conn.execute(f"SELECT COUNT(*) FROM course c WHERE {where_sql}", params).fetchone()[0]
    rows = conn.execute(
        f"""
        SELECT c.*, u.real_name AS teacher_name, d.department_name,
               c.capacity - c.selected_count AS remaining_count
        FROM course c
        JOIN sys_user u ON u.id = c.teacher_id
        JOIN department d ON d.id = c.department_id
        WHERE {where_sql}
        ORDER BY c.course_code
        LIMIT ? OFFSET ?
        """,
        params + [page_size, offset],
    ).fetchall()
    items = []
    for row in rows:
        item = dict(row)
        item["schedules"] = _course_schedules(conn, row["id"])
        items.append(item)
    return ok(page_result(items, total, page, page_size))


@bp.get("/courses/<int:course_id>")
@auth_required
def course_detail(course_id: int):
    conn = get_db()
    row = conn.execute(
        """
        SELECT c.*, u.real_name AS teacher_name, d.department_name,
               c.capacity - c.selected_count AS remaining_count
        FROM course c
        JOIN sys_user u ON u.id = c.teacher_id
        JOIN department d ON d.id = c.department_id
        WHERE c.id = ?
        """,
        (course_id,),
    ).fetchone()
    if row is None:
        return fail(40401, "课程不存在", 404)
    data = dict(row)
    data["schedules"] = _course_schedules(conn, course_id)
    if g.current_user["role"] == "STUDENT":
        enrollment = conn.execute(
            "SELECT status, selected_at, dropped_at FROM course_enrollment WHERE course_id = ? AND student_id = ?",
            (course_id, g.current_user["id"]),
        ).fetchone()
        data["myEnrollment"] = dict(enrollment) if enrollment else None
    return ok(data)


@bp.get("/courses/<int:course_id>/schedules")
@auth_required
def course_schedules(course_id: int):
    return ok(_course_schedules(get_db(), course_id))


@bp.get("/enrollments/my")
@roles_required("STUDENT")
def my_enrollments():
    conn = get_db()
    status = request.args.get("status")
    sql = """
        SELECT ce.*, c.course_code, c.course_name, c.credit,
               c.teacher_id, u.real_name AS teacher_name
        FROM course_enrollment ce
        JOIN course c ON c.id = ce.course_id
        JOIN sys_user u ON u.id = c.teacher_id
        WHERE ce.student_id = ?
    """
    params: list = [g.current_user["id"]]
    if status:
        sql += " AND ce.status = ?"
        params.append(status)
    sql += " ORDER BY ce.updated_at DESC"
    rows = conn.execute(sql, params).fetchall()
    items = []
    for row in rows:
        item = dict(row)
        item["schedules"] = _course_schedules(conn, row["course_id"])
        items.append(item)
    return ok(items)


@bp.post("/courses/<int:course_id>/enroll")
@roles_required("STUDENT")
def enroll(course_id: int):
    conn = get_db()
    course = conn.execute("SELECT id FROM course WHERE id = ?", (course_id,)).fetchone()
    if course is None:
        return fail(40401, "课程不存在", 404)
    old = conn.execute(
        "SELECT id, status FROM course_enrollment WHERE course_id = ? AND student_id = ?",
        (course_id, g.current_user["id"]),
    ).fetchone()
    if old and old["status"] == "SELECTED":
        return fail(40901, "已经选择该课程", 409)

    try:
        conn.execute("BEGIN IMMEDIATE")
        if old:
            conn.execute(
                """
                UPDATE course_enrollment
                SET status = 'SELECTED', selected_at = ?, dropped_at = NULL, updated_at = ?
                WHERE id = ?
                """,
                (utc_now_sql(), utc_now_sql(), old["id"]),
            )
        else:
            conn.execute(
                "INSERT INTO course_enrollment(course_id, student_id, status) VALUES (?, ?, 'SELECTED')",
                (course_id, g.current_user["id"]),
            )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40902, str(exc), 409)
    except Exception:
        conn.rollback()
        return fail(50001, "选课失败", 500)
    return ok(None, "选课成功", 201)


@bp.post("/courses/<int:course_id>/drop")
@roles_required("STUDENT")
def drop(course_id: int):
    conn = get_db()
    row = conn.execute(
        """
        SELECT ce.id, ce.status, c.selection_status, c.selection_end
        FROM course_enrollment ce
        JOIN course c ON c.id = ce.course_id
        WHERE ce.course_id = ? AND ce.student_id = ?
        """,
        (course_id, g.current_user["id"]),
    ).fetchone()
    if row is None or row["status"] != "SELECTED":
        return fail(40401, "没有有效选课记录", 404)
    if row["selection_status"] != "OPEN":
        return fail(40901, "当前课程已关闭退选", 409)

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            UPDATE course_enrollment
            SET status = 'DROPPED', dropped_at = ?, updated_at = ?
            WHERE id = ?
            """,
            (utc_now_sql(), utc_now_sql(), row["id"]),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "退课失败", 500)
    return ok(None, "退课成功")


@bp.get("/teaching/courses")
@roles_required("TEACHER")
def teaching_courses():
    conn = get_db()
    rows = conn.execute(
        """
        SELECT c.*, d.department_name,
               c.capacity - c.selected_count AS remaining_count
        FROM course c
        JOIN department d ON d.id = c.department_id
        WHERE c.teacher_id = ?
        ORDER BY c.status DESC, c.course_code
        """,
        (g.current_user["id"],),
    ).fetchall()
    items = []
    for row in rows:
        item = dict(row)
        item["schedules"] = _course_schedules(conn, row["id"])
        items.append(item)
    return ok(items)


@bp.get("/teaching/courses/<int:course_id>/students")
@roles_required("TEACHER")
def course_students(course_id: int):
    conn = get_db()
    owns = conn.execute(
        "SELECT 1 FROM course WHERE id = ? AND teacher_id = ?",
        (course_id, g.current_user["id"]),
    ).fetchone()
    if owns is None:
        return fail(40301, "只能查看自己授课课程的学生", 403)
    rows = conn.execute(
        """
        SELECT ce.status AS enrollment_status, ce.selected_at,
               u.id AS user_id, u.real_name, u.gender, u.email, u.phone,
               sp.student_no, sp.academic_status,
               cg.class_name, cg.grade, cg.major_name
        FROM course_enrollment ce
        JOIN sys_user u ON u.id = ce.student_id
        LEFT JOIN student_profile sp ON sp.user_id = u.id
        LEFT JOIN class_group cg ON cg.id = u.class_id
        WHERE ce.course_id = ? AND ce.status = 'SELECTED'
        ORDER BY cg.class_name, sp.student_no
        """,
        (course_id,),
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/teaching/schedules")
@roles_required("TEACHER")
def teaching_schedules():
    conn = get_db()
    sql = """
        SELECT cs.*, c.course_code, c.course_name,
               cr.classroom_code, cr.classroom_name
        FROM course_schedule cs
        JOIN course c ON c.id = cs.course_id
        JOIN classroom cr ON cr.id = cs.classroom_id
        WHERE c.teacher_id = ?
    """
    params: list = [g.current_user["id"]]
    if request.args.get("semester"):
        sql += " AND cs.semester = ?"
        params.append(request.args["semester"])
    sql += " ORDER BY cs.semester DESC, cs.week_day, cs.start_section"
    rows = conn.execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/timetable/my")
@auth_required
def my_timetable():
    try:
        target = parse_date(request.args.get("date"), "date")
    except ValueError as exc:
        return fail(40001, str(exc))
    conn = get_db()
    semester, week, schedules = effective_schedules_for_date(conn, target)
    role = g.current_user["role"]
    if role == "STUDENT":
        selected = {
            row["course_id"]
            for row in conn.execute(
                "SELECT course_id FROM course_enrollment WHERE student_id = ? AND status = 'SELECTED'",
                (g.current_user["id"],),
            ).fetchall()
        }
        schedules = [item for item in schedules if item["course_id"] in selected]
    elif role == "TEACHER":
        schedules = [item for item in schedules if item["teacher_id"] == g.current_user["id"]]
    elif role not in {"ACADEMIC_STAFF", "ADMIN"}:
        schedules = []
    schedules = [item for item in schedules if item["effective_week_day"] == target.isoweekday()]
    schedules.sort(key=lambda item: item["effective_start_section"])
    return ok({
        "date": target.isoformat(),
        "semester": dict(semester) if semester else None,
        "week": week,
        "schedules": schedules,
    })
