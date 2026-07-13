from __future__ import annotations

from flask import Blueprint, g

from api_utils import body_json, fail, ok, utc_now_sql
from auth_guard import auth_required
from db import get_db

bp = Blueprint("profile", __name__, url_prefix="/api")


def _profile(conn, user_id: int):
    user = conn.execute(
        """
        SELECT u.*, d.department_name, cg.class_name, cg.grade, cg.major_name, cg.campus
        FROM sys_user u
        LEFT JOIN department d ON d.id = u.department_id
        LEFT JOIN class_group cg ON cg.id = u.class_id
        WHERE u.id = ?
        """,
        (user_id,),
    ).fetchone()
    if user is None:
        return None
    data = dict(user)
    role = user["role"]
    if role == "STUDENT":
        extra = conn.execute(
            "SELECT * FROM student_profile WHERE user_id = ?",
            (user_id,),
        ).fetchone()
    elif role == "TEACHER":
        extra = conn.execute(
            "SELECT * FROM teacher_profile WHERE user_id = ?",
            (user_id,),
        ).fetchone()
    elif role in {"ACADEMIC_STAFF", "ADMIN"}:
        extra = conn.execute(
            "SELECT * FROM academic_staff_profile WHERE user_id = ?",
            (user_id,),
        ).fetchone()
    else:
        extra = None
    data["roleProfile"] = dict(extra) if extra else None
    data.pop("password_hash", None)
    return data


@bp.get("/profile/me")
@auth_required
def get_profile():
    data = _profile(get_db(), g.current_user["id"])
    return ok(data)


@bp.put("/profile/me")
@auth_required
def update_profile():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")

    allowed_common = {
        "gender": "gender",
        "phone": "phone",
        "email": "email",
        "avatarUrl": "avatar_url",
    }
    fields: list[str] = []
    params: list = []
    for api_name, db_name in allowed_common.items():
        if api_name in body:
            value = body[api_name]
            if api_name == "gender":
                try:
                    value = int(value)
                except (TypeError, ValueError):
                    return fail(40001, "gender必须为0、1或2")
                if value not in {0, 1, 2}:
                    return fail(40001, "gender必须为0、1或2")
            fields.append(f"{db_name} = ?")
            params.append(value if value not in {""} else None)

    conn = get_db()
    try:
        conn.execute("BEGIN IMMEDIATE")
        if fields:
            fields.append("updated_at = ?")
            params.extend([utc_now_sql(), g.current_user["id"]])
            conn.execute(
                f"UPDATE sys_user SET {', '.join(fields)} WHERE id = ?",
                params,
            )

        role = g.current_user["role"]
        if role == "STUDENT" and "admissionDate" in body:
            conn.execute(
                "UPDATE student_profile SET admission_date = ?, updated_at = ? WHERE user_id = ?",
                (body.get("admissionDate") or None, utc_now_sql(), g.current_user["id"]),
            )
        elif role == "TEACHER":
            teacher_fields = []
            teacher_params = []
            for api_name, db_name in {
                "professionalTitle": "professional_title",
                "introduction": "introduction",
            }.items():
                if api_name in body:
                    teacher_fields.append(f"{db_name} = ?")
                    teacher_params.append(body.get(api_name) or None)
            if teacher_fields:
                teacher_fields.append("updated_at = ?")
                teacher_params.extend([utc_now_sql(), g.current_user["id"]])
                conn.execute(
                    f"UPDATE teacher_profile SET {', '.join(teacher_fields)} WHERE user_id = ?",
                    teacher_params,
                )
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "个人资料更新失败", 500)
    return ok(_profile(conn, g.current_user["id"]), "个人资料更新成功")


@bp.get("/home")
@auth_required
def home():
    conn = get_db()
    user_id = g.current_user["id"]
    role = g.current_user["role"]
    data = {"profile": _profile(conn, user_id), "role": role, "summary": {}}

    if role == "STUDENT":
        data["summary"] = {
            "selectedCourseCount": conn.execute(
                "SELECT COUNT(*) FROM course_enrollment WHERE student_id = ? AND status = 'SELECTED'",
                (user_id,),
            ).fetchone()[0],
            "pendingBookingCount": conn.execute(
                "SELECT COUNT(*) FROM room_booking WHERE applicant_id = ? AND status = 'PENDING'",
                (user_id,),
            ).fetchone()[0],
            "pendingLeaveCount": conn.execute(
                "SELECT COUNT(*) FROM leave_request WHERE applicant_id = ? AND status = 'PENDING'",
                (user_id,),
            ).fetchone()[0],
        }
    elif role == "TEACHER":
        data["summary"] = {
            "teachingCourseCount": conn.execute(
                "SELECT COUNT(*) FROM course WHERE teacher_id = ? AND status = 1",
                (user_id,),
            ).fetchone()[0],
            "pendingBookingCount": conn.execute(
                "SELECT COUNT(*) FROM room_booking WHERE applicant_id = ? AND status = 'PENDING'",
                (user_id,),
            ).fetchone()[0],
            "pendingScheduleChangeCount": conn.execute(
                "SELECT COUNT(*) FROM schedule_change WHERE applicant_id = ? AND status = 'PENDING'",
                (user_id,),
            ).fetchone()[0],
        }
    else:
        data["summary"] = {
            "pendingBookingCount": conn.execute(
                "SELECT COUNT(*) FROM room_booking WHERE status = 'PENDING'"
            ).fetchone()[0],
            "pendingLeaveCount": conn.execute(
                "SELECT COUNT(*) FROM leave_request WHERE status = 'PENDING'"
            ).fetchone()[0],
            "pendingScheduleChangeCount": conn.execute(
                "SELECT COUNT(*) FROM schedule_change WHERE status = 'PENDING'"
            ).fetchone()[0],
        }
    data["summary"]["unreadNotificationCount"] = conn.execute(
        "SELECT COUNT(*) FROM notification_recipient WHERE user_id = ? AND is_read = 0",
        (user_id,),
    ).fetchone()[0]
    return ok(data)
