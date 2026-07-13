from __future__ import annotations

from functools import wraps

from flask import g, request

from api_utils import fail
from db import get_db


def _bearer_token() -> str | None:
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None
    token = header[7:].strip()
    return token or None


def auth_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        token = _bearer_token()
        if token is None:
            return fail(40101, "未登录或未携带Token", 401)

        conn = get_db()
        user = conn.execute(
            """
            SELECT
                u.id, u.account, u.real_name, u.role, u.status,
                u.department_id, u.class_id,
                t.id AS token_id, t.expires_at
            FROM auth_token t
            JOIN sys_user u ON u.id = t.user_id
            WHERE t.token = ?
              AND t.revoked = 0
              AND datetime(t.expires_at) > datetime('now')
            """,
            (token,),
        ).fetchone()

        if user is None or user["status"] != 1:
            return fail(40102, "Token无效、已过期或账号已停用", 401)

        g.current_user = dict(user)
        g.current_token = token
        return fn(*args, **kwargs)

    return wrapper


def roles_required(*roles: str):
    allowed = set(roles)

    def decorator(fn):
        @wraps(fn)
        @auth_required
        def wrapper(*args, **kwargs):
            if g.current_user["role"] not in allowed:
                return fail(40301, "无权执行该操作", 403)
            return fn(*args, **kwargs)

        return wrapper

    return decorator
