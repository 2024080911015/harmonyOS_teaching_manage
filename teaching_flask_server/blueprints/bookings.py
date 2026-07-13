from __future__ import annotations

import sqlite3
from datetime import date

from flask import Blueprint, g, request

from api_utils import as_int, body_json, business_no, fail, ok, page_result, pagination, parse_date, utc_now_sql
from auth_guard import auth_required, roles_required
from db import get_db
from services import room_booking_conflict, room_course_conflict

bp = Blueprint("bookings", __name__, url_prefix="/api/bookings")


def _detail(conn, booking_id: int):
    return conn.execute(
        """
        SELECT rb.*, applicant.real_name AS applicant_name,
               applicant.role AS applicant_role,
               cr.classroom_code, cr.classroom_name, cr.campus, cr.building,
               reviewer.real_name AS reviewer_name
        FROM room_booking rb
        JOIN sys_user applicant ON applicant.id = rb.applicant_id
        JOIN classroom cr ON cr.id = rb.classroom_id
        LEFT JOIN sys_user reviewer ON reviewer.id = rb.reviewer_id
        WHERE rb.id = ?
        """,
        (booking_id,),
    ).fetchone()


def _add_log(conn, booking_id: int, operator_id: int | None, action: str, old_status: str | None, new_status: str | None, remark: str | None):
    conn.execute(
        """
        INSERT INTO room_booking_log(
            booking_id, operator_id, action, old_status, new_status, remark
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        (booking_id, operator_id, action, old_status, new_status, remark),
    )


@bp.post("")
@roles_required("STUDENT", "TEACHER")
def create_booking():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    try:
        classroom_id = as_int(body.get("classroomId"), "classroomId", minimum=1)
        booking_date = parse_date(body.get("bookingDate"), "bookingDate")
        start = as_int(body.get("startSection"), "startSection", minimum=1)
        end = as_int(body.get("endSection"), "endSection", minimum=1)
        participants = as_int(body.get("participantCount"), "participantCount", minimum=1)
    except ValueError as exc:
        return fail(40001, str(exc))
    purpose = str(body.get("purpose", "")).strip()
    if not purpose:
        return fail(40001, "purpose不能为空")
    if end < start:
        return fail(40001, "endSection不能小于startSection")
    if booking_date < date.today():
        return fail(40001, "不能申请过去的日期")

    conn = get_db()
    room = conn.execute("SELECT * FROM classroom WHERE id = ?", (classroom_id,)).fetchone()
    if room is None:
        return fail(40401, "教室不存在", 404)
    if room["status"] != "AVAILABLE":
        return fail(40901, "教室当前维修或停用", 409)
    if participants > room["capacity"]:
        return fail(40902, "参与人数超过教室容量", 409)
    course_conflict = room_course_conflict(conn, classroom_id, booking_date, start, end)
    if course_conflict:
        return fail(40903, "该教室在所选时段已有课程", 409, course_conflict)
    if room_booking_conflict(conn, classroom_id, booking_date, start, end):
        return fail(40904, "该教室在所选时段已有预约", 409)

    booking_no = business_no("RB")
    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO room_booking(
                booking_no, applicant_id, classroom_id, booking_date,
                start_section, end_section, purpose, participant_count, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
            """,
            (
                booking_no,
                g.current_user["id"],
                classroom_id,
                booking_date.isoformat(),
                start,
                end,
                purpose,
                participants,
            ),
        )
        booking_id = cursor.lastrowid
        _add_log(conn, booking_id, g.current_user["id"], "SUBMIT", None, "PENDING", "提交教室申请")
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40905, str(exc), 409)
    except Exception:
        conn.rollback()
        return fail(50001, "教室申请提交失败", 500)
    return ok({"bookingId": booking_id, "bookingNo": booking_no}, "申请提交成功", 201)


@bp.get("/my")
@roles_required("STUDENT", "TEACHER")
def my_bookings():
    conn = get_db()
    sql = "SELECT * FROM v_room_booking_detail WHERE applicant_id = ?"
    params: list = [g.current_user["id"]]
    if request.args.get("status"):
        sql += " AND status = ?"
        params.append(request.args["status"])
    sql += " ORDER BY created_at DESC"
    rows = conn.execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/<int:booking_id>")
@auth_required
def booking_detail(booking_id: int):
    conn = get_db()
    row = _detail(conn, booking_id)
    if row is None:
        return fail(40401, "申请不存在", 404)
    if g.current_user["role"] not in {"ACADEMIC_STAFF", "ADMIN"} and row["applicant_id"] != g.current_user["id"]:
        return fail(40301, "无权查看该申请", 403)
    return ok(dict(row))


@bp.post("/<int:booking_id>/cancel")
@roles_required("STUDENT", "TEACHER")
def cancel_booking(booking_id: int):
    body = body_json() or {}
    reason = str(body.get("reason", "")).strip() or "申请人取消"
    conn = get_db()
    row = conn.execute(
        "SELECT * FROM room_booking WHERE id = ? AND applicant_id = ?",
        (booking_id, g.current_user["id"]),
    ).fetchone()
    if row is None:
        return fail(40401, "申请不存在", 404)
    if row["status"] not in {"PENDING", "APPROVED"}:
        return fail(40901, "当前状态不能取消", 409)
    if date.fromisoformat(row["booking_date"]) < date.today():
        return fail(40902, "已过使用日期，不能取消", 409)

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            UPDATE room_booking
            SET status = 'CANCELLED', cancel_reason = ?, updated_at = ?
            WHERE id = ?
            """,
            (reason, utc_now_sql(), booking_id),
        )
        _add_log(conn, booking_id, g.current_user["id"], "CANCEL", row["status"], "CANCELLED", reason)
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "取消失败", 500)
    return ok(None, "申请已取消")


@bp.get("/<int:booking_id>/logs")
@auth_required
def booking_logs(booking_id: int):
    conn = get_db()
    booking = conn.execute("SELECT applicant_id FROM room_booking WHERE id = ?", (booking_id,)).fetchone()
    if booking is None:
        return fail(40401, "申请不存在", 404)
    if g.current_user["role"] not in {"ACADEMIC_STAFF", "ADMIN"} and booking["applicant_id"] != g.current_user["id"]:
        return fail(40301, "无权查看日志", 403)
    rows = conn.execute(
        """
        SELECT l.*, u.real_name AS operator_name, u.role AS operator_role
        FROM room_booking_log l
        LEFT JOIN sys_user u ON u.id = l.operator_id
        WHERE l.booking_id = ?
        ORDER BY l.created_at, l.id
        """,
        (booking_id,),
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/pending")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def pending_bookings():
    conn = get_db()
    sql = "SELECT * FROM v_room_booking_detail WHERE status = 'PENDING'"
    params: list = []
    if request.args.get("applicantRole"):
        sql += " AND applicant_role = ?"
        params.append(request.args["applicantRole"])
    sql += " ORDER BY created_at"
    rows = conn.execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])


def _review(booking_id: int, action: str):
    body = body_json() or {}
    comment = str(body.get("comment", "")).strip()
    if action == "REJECT" and not comment:
        return fail(40001, "驳回必须填写原因")

    conn = get_db()
    row = conn.execute("SELECT * FROM room_booking WHERE id = ?", (booking_id,)).fetchone()
    if row is None:
        return fail(40401, "申请不存在", 404)
    if row["status"] != "PENDING":
        return fail(40901, "申请已处理", 409)

    new_status = "APPROVED" if action == "APPROVE" else "REJECTED"
    if action == "APPROVE":
        target = date.fromisoformat(row["booking_date"])
        room = conn.execute("SELECT status FROM classroom WHERE id = ?", (row["classroom_id"],)).fetchone()
        if room is None or room["status"] != "AVAILABLE":
            return fail(40902, "教室当前不可用", 409)
        course_conflict = room_course_conflict(
            conn,
            row["classroom_id"],
            target,
            row["start_section"],
            row["end_section"],
        )
        if course_conflict:
            return fail(40903, "审批时发现该教室已有课程", 409, course_conflict)
        other = room_booking_conflict(
            conn,
            row["classroom_id"],
            target,
            row["start_section"],
            row["end_section"],
            exclude_booking_id=booking_id,
        )
        if other:
            return fail(40904, "审批时发现该教室已有其他预约", 409)

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            UPDATE room_booking
            SET status = ?, reviewer_id = ?, review_comment = ?,
                reviewed_at = ?, updated_at = ?
            WHERE id = ? AND status = 'PENDING'
            """,
            (new_status, g.current_user["id"], comment or None, utc_now_sql(), utc_now_sql(), booking_id),
        )
        conn.execute(
            """
            INSERT INTO approval_record(business_type, business_id, approver_id, action, comment)
            VALUES ('ROOM_BOOKING', ?, ?, ?, ?)
            """,
            (booking_id, g.current_user["id"], action, comment or None),
        )
        _add_log(conn, booking_id, g.current_user["id"], action, "PENDING", new_status, comment or None)
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40905, str(exc), 409)
    except Exception:
        conn.rollback()
        return fail(50001, "审批失败", 500)
    return ok(None, "审批通过" if action == "APPROVE" else "已驳回")


@bp.post("/<int:booking_id>/approve")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def approve_booking(booking_id: int):
    return _review(booking_id, "APPROVE")


@bp.post("/<int:booking_id>/reject")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def reject_booking(booking_id: int):
    return _review(booking_id, "REJECT")


@bp.post("/finish-expired")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def finish_expired():
    conn = get_db()
    rows = conn.execute(
        "SELECT id, status FROM room_booking WHERE status = 'APPROVED' AND date(booking_date) < date('now')"
    ).fetchall()
    try:
        conn.execute("BEGIN IMMEDIATE")
        for row in rows:
            conn.execute(
                "UPDATE room_booking SET status = 'FINISHED', updated_at = ? WHERE id = ?",
                (utc_now_sql(), row["id"]),
            )
            _add_log(conn, row["id"], g.current_user["id"], "FINISH", "APPROVED", "FINISHED", "教务人员批量结束过期预约")
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "更新失败", 500)
    return ok({"finishedCount": len(rows)}, "过期预约处理完成")
