from __future__ import annotations

import argparse
import sqlite3

from werkzeug.security import generate_password_hash

from config import Config
from db import connect_db


def main() -> None:
    parser = argparse.ArgumentParser(description="创建首个系统管理员账号")
    parser.add_argument("--account", default="admin")
    parser.add_argument("--password", required=True)
    parser.add_argument("--name", default="系统管理员")
    parser.add_argument("--employee-no", default=None)
    args = parser.parse_args()

    if len(args.password) < 6:
        raise SystemExit("密码至少6位")

    conn = connect_db(Config.DATABASE)
    try:
        conn.execute("BEGIN IMMEDIATE")
        cursor = conn.execute(
            """
            INSERT INTO sys_user(account, password_hash, real_name, role, status)
            VALUES (?, ?, ?, 'ADMIN', 1)
            """,
            (args.account, generate_password_hash(args.password), args.name),
        )
        user_id = cursor.lastrowid
        conn.execute(
            """
            INSERT INTO academic_staff_profile(user_id, employee_no, responsibility_area, approval_level)
            VALUES (?, ?, 'SYSTEM_ADMIN', 9)
            """,
            (user_id, args.employee_no or args.account),
        )
        conn.commit()
        print(f"管理员创建成功：user_id={user_id}, account={args.account}")
    except sqlite3.IntegrityError as exc:
        conn.rollback()
        raise SystemExit(f"创建失败，账号或工号可能已存在：{exc}") from exc
    finally:
        conn.close()


if __name__ == "__main__":
    main()
