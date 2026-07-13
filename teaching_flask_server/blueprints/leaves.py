from __future__ import annotations

import sqlite3
from datetime import date

from flask import Blueprint, g, request

from api_utils import as_int, body_json, business_no, fail, ok, parse_date, utc_now_sql
from auth_guard import auth_required, roles_required
from db import get_db

bp = Blueprint("leaves", __name__, url_prefix="/api/leaves")


def _detail(conn, leave_id: int):
    row = conn.execute(
        """
        SELECT lr.*, applicant.real_name AS applicant_name,
               sp.student_no, cg.class_name, reviewer.real_name AS reviewer_name
        FROM leave_request lr
        JOIN sys_user applicant ON applicant.id = lr.applicant_id
        LEFT JOIN student_profile sp ON sp.user_id = applicant.id
        LEFT JOIN class_group cg ON cg.id = applicant.class_id
        LEFT JOIN sys_user reviewer ON reviewer.id = lr.reviewer_id
        WHERE lr.id = ?
        """,
        (leave_id,),
    ).fetchone()
    if row is None:
        return None
    data = dict(row)
    courses = conn.execute(
        """
        SELECT c.id, c.course_code, c.course_name, c.teacher_id,
               u.real_name AS teacher_name
        FROM leave_request_course lrc
        JOIN course c ON c.id = lrc.course_id
        JOIN sys_user u ON u.id = c.teacher_id
        WHERE lrc.leave_request_id = ?
        ORDER BY c.course_code
        """,
        (leave_id,),
    ).fetchall()
    data["courses"] = [dict(item) for item in courses]
    return data


@bp.post("")
@roles_required("STUDENT")
def create_leave():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    leave_type = str(body.get("leaveType", "")).upper()
    if leave_type not in {"SICK", "PERSONAL", "OTHER"}:
        return fail(40001, "leaveType必须为SICK、PERSONAL或OTHER")
    try:
        start_date = parse_date(body.get("startDate"), "startDate")
        end_date = parse_date(body.get("endDate"), "endDate")
        start_section = as_int(body.get("startSection"), "startSection", required=False, minimum=1)
        end_section = as_int(body.get("endSection"), "endSection", required=False, minimum=1)
    except ValueError as exc:
        return fail(40001, str(exc))
    if end_date < start_date:
        return fail(40001, "endDate不能早于startDate")
    if start_date < date.today():
        return fail(40001, "不能申请已过去的日期")
    if (start_section is None) != (end_section is None):
        return fail(40001, "startSection和endSection必须同时填写或同时为空")
    if start_section is not None and end_section < start_section:
        return fail(40001, "endSection不能小于startSection")

    reason = str(body.get("reason", "")).strip()
    if not reason:
        return fail(40001, "reason不能为空")
    course_ids = body.get("courseIds")
    if not isinstance(course_ids, list) or not course_ids:
        return fail(40001, "courseIds必须是非空课程ID数组")
    try:
        course_ids = sorted({int(value) for value in course_ids})
    except (TypeError, ValueError):
        return fail(40001, "courseIds中只能包含整数")

    conn = get_db()
    valid_rows = conn.execute(
        f"""
        SELECT course_id
        FROM course_enrollment
        WHERE student_id = ? AND status = 'SELECTED'
          AND course_id IN ({','.join('?' for _ in course_ids)})
        """,
        [g.current_user["id"], *course_ids],
    ).fetchall()
    valid_ids = {row["course_id"] for row in valid_rows}
    if valid_ids != set(course_ids):
        return fail(40002, "只能为自己当前已选课程提交请假")

    leave_no = business_no("LV")
    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO leave_request(
                leave_no, applicant_id, leave_type, start_date, end_date,
                start_section, end_section, reason, attachment_url, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
            """,
            (
                leave_no,
                g.current_user["id"],
                leave_type,
                start_date.isoformat(),
                end_date.isoformat(),
                start_section,
                end_section,
                reason,
                body.get("attachmentUrl") or None,
            ),
        )
        leave_id = cursor.lastrowid
        conn.executemany(
            "INSERT INTO leave_request_course(leave_request_id, course_id) VALUES (?, ?)",
            [(leave_id, course_id) for course_id in course_ids],
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40901, str(exc), 409)
    except Exception:
        conn.rollback()
        return fail(50001, "请假申请提交失败", 500)
    return ok({"leaveId": leave_id, "leaveNo": leave_no}, "请假申请提交成功", 201)


@bp.get("/my")
@roles_required("STUDENT")
def my_leaves():
    conn = get_db()
    sql = "SELECT id FROM leave_request WHERE applicant_id = ?"
    params: list = [g.current_user["id"]]
    if request.args.get("status"):
        sql += " AND status = ?"
        params.append(request.args["status"])
    sql += " ORDER BY created_at DESC"
    ids = conn.execute(sql, params).fetchall()
    return ok([_detail(conn, row["id"]) for row in ids])


@bp.get("/<int:leave_id>")
@auth_required
def leave_detail(leave_id: int):
    conn = get_db()
    data = _detail(conn, leave_id)
    if data is None:
        return fail(40401, "请假申请不存在", 404)
    role = g.current_user["role"]
    if role == "STUDENT" and data["applicant_id"] != g.current_user["id"]:
        return fail(40301, "无权查看该申请", 403)
    if role == "TEACHER":
        related = conn.execute(
            """
            SELECT 1
            FROM leave_request_course lrc
            JOIN course c ON c.id = lrc.course_id
            WHERE lrc.leave_request_id = ? AND c.teacher_id = ?
            """,
            (leave_id, g.current_user["id"]),
        ).fetchone()
        if related is None:
            return fail(40301, "无权查看与本人课程无关的请假", 403)
    return ok(data)


@bp.post("/<int:leave_id>/cancel")
@roles_required("STUDENT")
def cancel_leave(leave_id: int):
    body = body_json() or {}
    reason = str(body.get("reason", "")).strip() or "学生取消"
    conn = get_db()
    row = conn.execute(
        "SELECT status FROM leave_request WHERE id = ? AND applicant_id = ?",
        (leave_id, g.current_user["id"]),
    ).fetchone()
    if row is None:
        return fail(40401, "请假申请不存在", 404)
    if row["status"] != "PENDING":
        return fail(40901, "只有待审批申请可以取消", 409)
    conn.execute(
        """
        UPDATE leave_request
        SET status = 'CANCELLED', cancel_reason = ?, updated_at = ?
        WHERE id = ?
        """,
        (reason, utc_now_sql(), leave_id),
    )
    conn.commit()
    return ok(None, "请假申请已取消")


@bp.get("/teaching")
@roles_required("TEACHER")
def teaching_leaves():
    conn = get_db()
    sql = """
        SELECT DISTINCT lr.id
        FROM leave_request lr
        JOIN leave_request_course lrc ON lrc.leave_request_id = lr.id
        JOIN course c ON c.id = lrc.course_id
        WHERE c.teacher_id = ?
    """
    params: list = [g.current_user["id"]]
    if request.args.get("courseId"):
        sql += " AND c.id = ?"
        params.append(request.args["courseId"])
    if request.args.get("status"):
        sql += " AND lr.status = ?"
        params.append(request.args["status"])
    sql += " ORDER BY lr.created_at DESC"
    ids = conn.execute(sql, params).fetchall()
    return ok([_detail(conn, row["id"]) for row in ids])


@bp.get("/pending")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def pending_leaves():
    conn = get_db()
    ids = conn.execute(
        "SELECT id FROM leave_request WHERE status = 'PENDING' ORDER BY created_at"
    ).fetchall()
    return ok([_detail(conn, row["id"]) for row in ids])


def _review(leave_id: int, action: str):
    body = body_json() or {}
    comment = str(body.get("comment", "")).strip()
    if action == "REJECT" and not comment:
        return fail(40001, "驳回必须填写原因")
    conn = get_db()
    row = conn.execute("SELECT status FROM leave_request WHERE id = ?", (leave_id,)).fetchone()
    if row is None:
        return fail(40401, "请假申请不存在", 404)
    if row["status"] != "PENDING":
        return fail(40901, "申请已处理", 409)
    new_status = "APPROVED" if action == "APPROVE" else "REJECTED"
    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            UPDATE leave_request
            SET status = ?, reviewer_id = ?, review_comment = ?,
                reviewed_at = ?, updated_at = ?
            WHERE id = ? AND status = 'PENDING'
            """,
            (new_status, g.current_user["id"], comment or None, utc_now_sql(), utc_now_sql(), leave_id),
        )
        conn.execute(
            """
            INSERT INTO approval_record(business_type, business_id, approver_id, action, comment)
            VALUES ('LEAVE_REQUEST', ?, ?, ?, ?)
            """,
            (leave_id, g.current_user["id"], action, comment or None),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "审批失败", 500)
    return ok(None, "审批通过" if action == "APPROVE" else "已驳回")


@bp.post("/<int:leave_id>/approve")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def approve_leave(leave_id: int):
    return _review(leave_id, "APPROVE")


@bp.post("/<int:leave_id>/reject")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def reject_leave(leave_id: int):
    return _review(leave_id, "REJECT")
