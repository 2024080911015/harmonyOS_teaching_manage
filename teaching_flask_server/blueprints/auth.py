from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from flask import Blueprint, current_app, g
from werkzeug.security import check_password_hash, generate_password_hash

from api_utils import body_json, fail, ok, text, utc_now_sql
from auth_guard import auth_required
from db import get_db

bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@bp.post("/login")
def login():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")

    account = str(body.get("account", "")).strip()
    password = str(body.get("password", ""))
    if not account or not password:
        return fail(40001, "账号和密码不能为空")

    conn = get_db()
    user = conn.execute(
        """
        SELECT id, account, password_hash, real_name, role, status,
               department_id, class_id
        FROM sys_user
        WHERE account = ?
        """,
        (account,),
    ).fetchone()

    if user is None or not check_password_hash(user["password_hash"], password):
        return fail(40101, "账号或密码错误", 401)
    if user["status"] != 1:
        return fail(40302, "账号已停用", 403)

    token = secrets.token_urlsafe(32)
    expires = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(
        days=current_app.config["TOKEN_EXPIRE_DAYS"]
    )
    expires_sql = expires.replace(microsecond=0).isoformat(sep=" ")

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            "INSERT INTO auth_token(token, user_id, expires_at) VALUES (?, ?, ?)",
            (token, user["id"], expires_sql),
        )
        conn.execute(
            "UPDATE sys_user SET last_login_at = ?, updated_at = ? WHERE id = ?",
            (utc_now_sql(), utc_now_sql(), user["id"]),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        current_app.logger.exception("登录写入Token失败")
        return fail(50001, "登录失败", 500)

    return ok(
        {
            "token": token,
            "expiresAt": expires_sql,
            "userId": user["id"],
            "account": user["account"],
            "realName": user["real_name"],
            "role": user["role"],
            "departmentId": user["department_id"],
            "classId": user["class_id"],
        },
        "登录成功",
    )


@bp.get("/me")
@auth_required
def me():
    conn = get_db()
    user = conn.execute(
        """
        SELECT id, account, real_name, role, gender, phone, email, avatar_url,
               department_id, class_id, status, last_login_at
        FROM sys_user WHERE id = ?
        """,
        (g.current_user["id"],),
    ).fetchone()
    return ok(dict(user))


@bp.post("/logout")
@auth_required
def logout():
    conn = get_db()
    conn.execute(
        "UPDATE auth_token SET revoked = 1 WHERE token = ?",
        (g.current_token,),
    )
    conn.commit()
    return ok(None, "退出成功")


@bp.put("/password")
@auth_required
def change_password():
    body = body_json()
    if body is None:
        return fail(40001, "请求体必须是JSON对象")
    old_password = str(body.get("oldPassword", ""))
    new_password = str(body.get("newPassword", ""))
    confirm = str(body.get("confirmPassword", ""))
    if len(new_password) < 6 or len(new_password) > 64:
        return fail(40001, "新密码长度必须为6到64位")
    if new_password != confirm:
        return fail(40001, "两次输入的新密码不一致")

    conn = get_db()
    row = conn.execute(
        "SELECT password_hash FROM sys_user WHERE id = ?",
        (g.current_user["id"],),
    ).fetchone()
    if row is None or not check_password_hash(row["password_hash"], old_password):
        return fail(40002, "原密码错误")

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            "UPDATE sys_user SET password_hash = ?, updated_at = ? WHERE id = ?",
            (generate_password_hash(new_password), utc_now_sql(), g.current_user["id"]),
        )
        conn.execute(
            "UPDATE auth_token SET revoked = 1 WHERE user_id = ? AND token <> ?",
            (g.current_user["id"], g.current_token),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        return fail(50001, "修改密码失败", 500)
    return ok(None, "密码修改成功")
