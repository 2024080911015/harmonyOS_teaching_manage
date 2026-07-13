from __future__ import annotations

import sqlite3
from datetime import datetime

from flask import Blueprint, g, request

from api_utils import body_json, fail, ok, page_result, pagination, parse_datetime, utc_now_sql
from auth_guard import auth_required, roles_required
from db import get_db

bp = Blueprint("notifications", __name__, url_prefix="/api/notifications")


def _notification_detail(conn, notification_id: int):
    return conn.execute(
        """
        SELECT n.*, u.real_name AS publisher_name, u.role AS publisher_role
        FROM notification n
        JOIN sys_user u ON u.id = n.publisher_id
        WHERE n.id = ?
        """,
        (notification_id,),
    ).fetchone()


@bp.get("")
@auth_required
def received_notifications():
    page, page_size, offset = pagination()
    user_id = g.current_user["id"]
    unread = request.args.get("unread")
    sql_where = " nr.user_id = ? AND n.status = 'PUBLISHED' "
    params: list = [user_id]
    if unread in {"1", "true", "True"}:
        sql_where += " AND nr.is_read = 0 "

    conn = get_db()
    total = conn.execute(
        f"""
        SELECT COUNT(*)
        FROM notification_recipient nr
        JOIN notification n ON n.id = nr.notification_id
        WHERE {sql_where}
        """,
        params,
    ).fetchone()[0]
    rows = conn.execute(
        f"""
        SELECT
            n.id, n.title, n.content, n.audience_type, n.published_at,
            n.expires_at, n.publisher_id, u.real_name AS publisher_name,
            nr.is_read, nr.read_at
        FROM notification_recipient nr
        JOIN notification n ON n.id = nr.notification_id
        JOIN sys_user u ON u.id = n.publisher_id
        WHERE {sql_where}
        ORDER BY n.published_at DESC
        LIMIT ? OFFSET ?
        """,
        params + [page_size, offset],
    ).fetchall()
    return ok(page_result([dict(row) for row in rows], total, page, page_size))


@bp.get("/unread-count")
@auth_required
def unread_count():
    count = get_db().execute(
        """
        SELECT COUNT(*)
        FROM notification_recipient nr
        JOIN notification n ON n.id = nr.notification_id
        WHERE nr.user_id = ? AND nr.is_read = 0 AND n.status = 'PUBLISHED'
        """,
        (g.current_user["id"],),
    ).fetchone()[0]
    return ok({"count": count})


@bp.get("/<int:notification_id>")
@auth_required
def detail(notification_id: int):
    conn = get_db()
    notification = _notification_detail(conn, notification_id)
    if notification is None:
        return fail(40401, "通知不存在", 404)

    role = g.current_user["role"]
    can_view = (
        notification["publisher_id"] == g.current_user["id"]
        or role in {"ACADEMIC_STAFF", "ADMIN"}
        or conn.execute(
            "SELECT 1 FROM notification_recipient WHERE notification_id = ? AND user_id = ?",
            (notification_id, g.current_user["id"]),
        ).fetchone()
        is not None
    )
    if not can_view:
        return fail(40301, "无权查看该通知", 403)

    recipient = conn.execute(
        "SELECT is_read, read_at FROM notification_recipient WHERE notification_id = ? AND user_id = ?",
        (notification_id, g.current_user["id"]),
    ).fetchone()
    data = dict(notification)
    data["isRead"] = recipient["is_read"] if recipient else None
    data["readAt"] = recipient["read_at"] if recipient else None
    return ok(data)


@bp.post("/<int:notification_id>/read")
@auth_required
def mark_read(notification_id: int):
    conn = get_db()
    cursor = conn.execute(
        """
        UPDATE notification_recipient
        SET is_read = 1, read_at = COALESCE(read_at, ?)
        WHERE notification_id = ? AND user_id = ?
        """,
        (utc_now_sql(), notification_id, g.current_user["id"]),
    )
    conn.commit()
    if cursor.rowcount == 0:
        return fail(40401, "未找到该通知的接收记录", 404)
    return ok(None, "已标记为已读")


@bp.post("")
@roles_required("TEACHER", "ACADEMIC_STAFF", "ADMIN")
def publish():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")

    title = str(body.get("title", "")).strip()
    content = str(body.get("content", "")).strip()
    audience = str(body.get("audienceType", "ALL_STUDENTS")).upper()
    if not title or not content:
        return fail(40001, "标题和内容不能为空")
    if audience not in {"ALL_STUDENTS", "CLASS", "DEPARTMENT", "USER"}:
        return fail(40001, "audienceType不合法")

    target_class = body.get("targetClassId")
    target_department = body.get("targetDepartmentId")
    target_user = body.get("targetUserId")
    try:
        expires = parse_datetime(body.get("expiresAt"), "expiresAt", required=True)
    except ValueError as exc:
        return fail(40001, str(exc))
    if expires <= datetime.now():
        return fail(40001, "通知截止时间必须晚于当前时间")
    expires_sql = expires.replace(microsecond=0).isoformat(sep=" ")

    if audience == "CLASS" and not target_class:
        return fail(40001, "指定班级通知必须提供targetClassId")
    if audience == "DEPARTMENT" and not target_department:
        return fail(40001, "指定院系通知必须提供targetDepartmentId")
    if audience == "USER" and not target_user:
        return fail(40001, "指定用户通知必须提供targetUserId")

    conn = get_db()
    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO notification(
                publisher_id, title, content, audience_type,
                target_class_id, target_department_id, target_user_id,
                expires_at, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PUBLISHED')
            """,
            (
                g.current_user["id"],
                title,
                content,
                audience,
                target_class if audience == "CLASS" else None,
                target_department if audience == "DEPARTMENT" else None,
                target_user if audience == "USER" else None,
                expires_sql,
            ),
        )
        notification_id = cursor.lastrowid

        if audience == "ALL_STUDENTS":
            recipients = conn.execute(
                "SELECT id FROM sys_user WHERE role = 'STUDENT' AND status = 1"
            ).fetchall()
        elif audience == "CLASS":
            recipients = conn.execute(
                "SELECT id FROM sys_user WHERE class_id = ? AND status = 1",
                (target_class,),
            ).fetchall()
        elif audience == "DEPARTMENT":
            recipients = conn.execute(
                "SELECT id FROM sys_user WHERE department_id = ? AND status = 1",
                (target_department,),
            ).fetchall()
        else:
            recipients = conn.execute(
                "SELECT id FROM sys_user WHERE id = ? AND status = 1",
                (target_user,),
            ).fetchall()

        if not recipients:
            conn.rollback()
            return fail(40002, "接收范围内没有有效用户")

        conn.executemany(
            "INSERT OR IGNORE INTO notification_recipient(notification_id, user_id) VALUES (?, ?)",
            [(notification_id, row["id"]) for row in recipients],
        )
        conn.commit()
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        return fail(40002, f"通知数据不符合要求：{exc}")
    except Exception:
        conn.rollback()
        return fail(50001, "通知发布失败", 500)

    return ok({"notificationId": notification_id, "recipientCount": len(recipients)}, "通知发布成功", 201)


@bp.get("/published/my")
@roles_required("TEACHER", "ACADEMIC_STAFF", "ADMIN")
def my_published():
    rows = get_db().execute(
        """
        SELECT n.*,
               (SELECT COUNT(*) FROM notification_recipient nr WHERE nr.notification_id = n.id) AS recipient_count,
               (SELECT COUNT(*) FROM notification_recipient nr WHERE nr.notification_id = n.id AND nr.is_read = 1) AS read_count
        FROM notification n
        WHERE n.publisher_id = ?
        ORDER BY n.published_at DESC
        """,
        (g.current_user["id"],),
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/manage")
@roles_required("ACADEMIC_STAFF", "ADMIN")
def manage_all():
    rows = get_db().execute(
        """
        SELECT n.*, u.real_name AS publisher_name, u.role AS publisher_role
        FROM notification n
        JOIN sys_user u ON u.id = n.publisher_id
        ORDER BY n.published_at DESC
        """
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.post("/<int:notification_id>/withdraw")
@roles_required("TEACHER", "ACADEMIC_STAFF", "ADMIN")
def withdraw(notification_id: int):
    conn = get_db()
    row = _notification_detail(conn, notification_id)
    if row is None:
        return fail(40401, "通知不存在", 404)
    if row["status"] != "PUBLISHED":
        return fail(40901, "通知已撤回", 409)

    role = g.current_user["role"]
    if role == "TEACHER":
        if row["publisher_id"] != g.current_user["id"]:
            return fail(40301, "教师只能撤回自己发布的通知", 403)
        if row["expires_at"] and datetime.fromisoformat(row["expires_at"]) <= datetime.now():
            return fail(40902, "通知已过期，不能撤回", 409)

    conn.execute(
        """
        UPDATE notification
        SET status = 'WITHDRAWN', withdrawn_at = ?, updated_at = ?
        WHERE id = ?
        """,
        (utc_now_sql(), utc_now_sql(), notification_id),
    )
    conn.commit()
    return ok(None, "通知撤回成功")
