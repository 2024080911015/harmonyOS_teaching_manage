from __future__ import annotations

import sqlite3

from flask import Blueprint, g, request

from api_utils import as_int, body_json, business_no, fail, ok, utc_now_sql
from auth_guard import auth_required, roles_required
from db import get_db
from services import schedule_change_conflicts

bp = Blueprint("schedule_changes", __name__, url_prefix="/api/schedule-changes")


def _detail(conn, change_id: int):
    row = conn.execute(
        """
        SELECT sc.*,
               c.course_code, c.course_name,
               cs.semester, cs.start_week, cs.end_week, cs.week_day,
               cs.start_section, cs.end_section, cs.classroom_id AS old_classroom_id,
               old_room.classroom_code AS old_classroom_code,
               old_room.classroom_name AS old_classroom_name,
               new_room.classroom_code AS new_classroom_code,
               new_room.classroom_name AS new_classroom_name,
               applicant.real_name AS applicant_name,
               reviewer.real_name AS reviewer_name
        FROM schedule_change sc
        JOIN course_schedule cs ON cs.id = sc.schedule_id
        JOIN course c ON c.id = cs.course_id
        JOIN classroom old_room ON old_room.id = cs.classroom_id
        LEFT JOIN classroom new_room ON new_room.id = sc.new_classroom_id
        JOIN sys_user applicant ON applicant.id = sc.applicant_id
        LEFT JOIN sys_user reviewer ON reviewer.id = sc.reviewer_id
        WHERE sc.id = ?
        """,
        (change_id,),
    ).fetchone()
    return dict(row) if row else None


@bp.post("")
@roles_required("TEACHER")
def create_change():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    try:
        schedule_id = as_int(body.get("scheduleId"), "scheduleId", minimum=1)
    except ValueError as exc:
        return fail(40001, str(exc))
    change_type = str(body.get("changeType", "")).upper()
    if change_type not in {"TIME", "ROOM", "BOTH"}:
        return fail(40001, "changeType必须为TIME、ROOM或BOTH")
    reason = str(body.get("reason", "")).strip()
    if not reason:
        return fail(40001, "reason不能为空")

    conn = get_db()
    base = conn.execute(
        """
        SELECT cs.*, c.teacher_id
        FROM course_schedule cs
        JOIN course c ON c.id = cs.course_id
        WHERE cs.id = ?
        """,
        (schedule_id,),
    ).fetchone()
    if base is None:
        return fail(40401, "原排课不存在", 404)
    if base["teacher_id"] != g.current_user["id"]:
        return fail(40301, "只能调整自己的课程", 403)

    new_room = None
    new_week = None
    new_week_day = None
    new_start = None
    new_end = None
    try:
        if change_type in {"ROOM", "BOTH"}:
            new_room = as_int(body.get("newClassroomId"), "newClassroomId", minimum=1)
            room = conn.execute("SELECT status FROM classroom WHERE id = ?", (new_room,)).fetchone()
            if room is None:
                return fail(40402, "新教室不存在", 404)
            if room["status"] != "AVAILABLE":
                return fail(40901, "新教室当前不可用", 409)
        if change_type in {"TIME", "BOTH"}:
            new_week = as_int(body.get("newWeek"), "newWeek", minimum=1)
            new_week_day = as_int(body.get("newWeekDay"), "newWeekDay", minimum=1)
            new_start = as_int(body.get("newStartSection"), "newStartSection", minimum=1)
            new_end = as_int(body.get("newEndSection"), "newEndSection", minimum=1)
            if new_week_day > 7:
                return fail(40001, "newWeekDay必须为1到7")
            if new_end < new_start:
                return fail(40001, "newEndSection不能小于newStartSection")
            if not (base["start_week"] <= new_week <= base["end_week"]):
                return fail(40001, "newWeek必须位于原课程周次范围内")
    except ValueError as exc:
        return fail(40001, str(exc))

    if change_type == "ROOM":
        duplicate = conn.execute(
            """
            SELECT 1 FROM schedule_change
            WHERE schedule_id = ? AND change_type = 'ROOM'
              AND status IN ('PENDING', 'APPROVED')
            """,
            (schedule_id,),
        ).fetchone()
    else:
        duplicate = conn.execute(
            """
            SELECT 1 FROM schedule_change
            WHERE schedule_id = ? AND new_week = ?
              AND change_type IN ('TIME', 'BOTH')
              AND status IN ('PENDING', 'APPROVED')
            """,
            (schedule_id, new_week),
        ).fetchone()
    if duplicate:
        return fail(40902, "该排课已经存在同范围的待审批或已通过调课", 409)

    change_no = business_no("SC")
    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO schedule_change(
                change_no, schedule_id, applicant_id, change_type,
                new_classroom_id, new_week, new_week_day,
                new_start_section, new_end_section, reason, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
            """,
            (
                change_no,
                schedule_id,
                g.current_user["id"],
                change_type,
                new_room,
                new_week,
                new_week_day,
                new_start,
                new_end,
                reason,
            ),
        )
        change_id = cursor.lastrowid
        row = conn.execute("SELECT * FROM schedule_change WHERE id = ?", (change_id,)).fetchone()
        conflicts = schedule_change_conflicts(conn, row)
        if conflicts:
            conn.rollback()
            return fail(40903, "调课方案存在冲突", 409, conflicts)
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40904, str(exc), 409)
    except Exception:
        conn.rollback()
        return fail(50001, "调课申请提交失败", 500)
    return ok({"changeId": change_id, "changeNo": change_no}, "调课申请提交成功", 201)


@bp.get("/my")
@roles_required("TEACHER")
def my_changes():
    conn = get_db()
    sql = "SELECT id FROM schedule_change WHERE applicant_id = ?"
    params: list = [g.current_user["id"]]
    if request.args.get("status"):
        sql += " AND status = ?"
        params.append(request.args["status"])
    sql += " ORDER BY created_at DESC"
    ids = conn.execute(sql, params).fetchall()
    return ok([_detail(conn, row["id"]) for row in ids])


@bp.get("/<int:change_id>")
@auth_required
def detail(change_id: int):
    conn = get_db()
    data = _detail(conn, change_id)
    if data is None:
        return fail(40401, "调课申请不存在", 404)
    if g.current_user["role"] not in {"ACADEMIC_STAFF", "ADMIN"} and data["applicant_id"] != g.current_user["id"]:
        return fail(40301, "无权查看该申请", 403)
    return ok(data)


@bp.get("/<int:change_id>/conflicts")
@auth_required
def conflicts(change_id: int):
    conn = get_db()
    row = conn.execute("SELECT * FROM schedule_change WHERE id = ?", (change_id,)).fetchone()
    if row is None:
        return fail(40401, "调课申请不存在", 404)
    if g.current_user["role"] not in {"ACADEMIC_STAFF", "ADMIN"} and row["applicant_id"] != g.current_user["id"]:
        return fail(40301, "无权检查该申请", 403)
    result = schedule_change_conflicts(conn, row)
    return ok({"hasConflict": bool(result), "conflicts": result})


@bp.post("/<int:change_id>/cancel")
@roles_required("TEACHER")
def cancel(change_id: int):
    body = body_json() or {}
    reason = str(body.get("reason", "")).strip() or "教师取消"
    conn = get_db()
    row = conn.execute(
        "SELECT status FROM schedule_change WHERE id = ? AND applicant_id = ?",
        (change_id, g.current_user["id"]),
    ).fetchone()
    if row is None:
        return fail(40401, "调课申请不存在", 404)
    if row["status"] != "PENDING":
        return fail(40901, "只有待审批申请可以取消", 409)
    conn.execute(
        """
        UPDATE schedule_change
        SET status = 'CANCELLED', cancel_reason = ?, updated_at = ?
        WHERE id = ?
        """,
        (reason, utc_now_sql(), change_id),
    )
    conn.commit()
    return ok(None, "调课申请已取消")


@bp.get("/pending")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def pending():
    conn = get_db()
    ids = conn.execute(
        "SELECT id FROM schedule_change WHERE status = 'PENDING' ORDER BY created_at"
    ).fetchall()
    return ok([_detail(conn, row["id"]) for row in ids])


def _review(change_id: int, action: str):
    body = body_json() or {}
    comment = str(body.get("comment", "")).strip()
    if action == "REJECT" and not comment:
        return fail(40001, "驳回必须填写原因")
    conn = get_db()
    row = conn.execute("SELECT * FROM schedule_change WHERE id = ?", (change_id,)).fetchone()
    if row is None:
        return fail(40401, "调课申请不存在", 404)
    if row["status"] != "PENDING":
        return fail(40901, "申请已处理", 409)
    if action == "APPROVE":
        conflicts = schedule_change_conflicts(conn, row)
        if conflicts:
            return fail(40902, "调课方案存在冲突，不能审批通过", 409, conflicts)

    new_status = "APPROVED" if action == "APPROVE" else "REJECTED"
    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            UPDATE schedule_change
            SET status = ?, reviewer_id = ?, review_comment = ?,
                reviewed_at = ?, updated_at = ?
            WHERE id = ? AND status = 'PENDING'
            """,
            (new_status, g.current_user["id"], comment or None, utc_now_sql(), utc_now_sql(), change_id),
        )
        conn.execute(
            """
            INSERT INTO approval_record(business_type, business_id, approver_id, action, comment)
            VALUES ('SCHEDULE_CHANGE', ?, ?, ?, ?)
            """,
            (change_id, g.current_user["id"], action, comment or None),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "审批失败", 500)
    return ok(None, "审批通过" if action == "APPROVE" else "已驳回")


@bp.post("/<int:change_id>/approve")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def approve(change_id: int):
    return _review(change_id, "APPROVE")


@bp.post("/<int:change_id>/reject")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def reject(change_id: int):
    return _review(change_id, "REJECT")
