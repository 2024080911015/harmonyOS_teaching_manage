from __future__ import annotations

import re
import secrets
from datetime import date, datetime, timezone
from typing import Any

from flask import jsonify, request


ACCOUNT_RE = re.compile(r"^[A-Za-z0-9_.-]{3,32}$")


def _camel_key(name: str) -> str:
    parts = name.split("_")
    return parts[0] + "".join(part[:1].upper() + part[1:] for part in parts[1:])


def camelize(value: Any) -> Any:
    if isinstance(value, dict):
        return {_camel_key(str(k)): camelize(v) for k, v in value.items()}
    if isinstance(value, list):
        return [camelize(item) for item in value]
    if isinstance(value, tuple):
        return [camelize(item) for item in value]
    return value


def ok(data: Any = None, message: str = "success", status: int = 200):
    return jsonify({"code": 0, "message": message, "data": camelize(data)}), status


def fail(code: int, message: str, status: int = 400, data: Any = None):
    return jsonify({"code": code, "message": message, "data": camelize(data)}), status


def body_json() -> dict[str, Any] | None:
    body = request.get_json(silent=True)
    return body if isinstance(body, dict) else None


def text(value: Any, *, required: bool = False, max_len: int | None = None) -> str | None:
    if value is None:
        if required:
            raise ValueError("字段不能为空")
        return None
    value = str(value).strip()
    if not value:
        if required:
            raise ValueError("字段不能为空")
        return None
    if max_len is not None and len(value) > max_len:
        raise ValueError(f"字段长度不能超过{max_len}")
    return value


def as_int(value: Any, name: str, *, required: bool = True, minimum: int | None = None) -> int | None:
    if value is None or value == "":
        if required:
            raise ValueError(f"{name}不能为空")
        return None
    try:
        number = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name}必须是整数") from exc
    if minimum is not None and number < minimum:
        raise ValueError(f"{name}不能小于{minimum}")
    return number


def as_float(value: Any, name: str, *, required: bool = True, minimum: float | None = None) -> float | None:
    if value is None or value == "":
        if required:
            raise ValueError(f"{name}不能为空")
        return None
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name}必须是数字") from exc
    if minimum is not None and number < minimum:
        raise ValueError(f"{name}不能小于{minimum}")
    return number


def parse_date(value: Any, name: str) -> date:
    raw = text(value, required=True)
    try:
        return date.fromisoformat(raw)
    except ValueError as exc:
        raise ValueError(f"{name}格式必须为YYYY-MM-DD") from exc


def parse_datetime(value: Any, name: str, *, required: bool = True) -> datetime | None:
    if value is None or value == "":
        if required:
            raise ValueError(f"{name}不能为空")
        return None
    raw = str(value).strip().replace("T", " ")
    try:
        return datetime.fromisoformat(raw)
    except ValueError as exc:
        raise ValueError(f"{name}格式必须为YYYY-MM-DD HH:MM:SS") from exc


def utc_now_sql() -> str:
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0).isoformat(sep=" ")


def business_no(prefix: str) -> str:
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return f"{prefix}{stamp}{secrets.randbelow(10000):04d}"


def pagination(default_size: int = 20, max_size: int = 100) -> tuple[int, int, int]:
    try:
        page = max(1, int(request.args.get("page", "1")))
        page_size = max(1, min(max_size, int(request.args.get("pageSize", str(default_size)))))
    except ValueError:
        page, page_size = 1, default_size
    return page, page_size, (page - 1) * page_size


def page_result(items: list[dict], total: int, page: int, page_size: int) -> dict:
    return {"items": items, "total": total, "page": page, "pageSize": page_size}


def row_dict(row) -> dict | None:
    return dict(row) if row is not None else None
