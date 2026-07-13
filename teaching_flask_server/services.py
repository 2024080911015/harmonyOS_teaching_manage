from __future__ import annotations

from datetime import date, timedelta
from typing import Any


def intervals_overlap(a_start: int, a_end: int, b_start: int, b_end: int) -> bool:
    return a_start <= b_end and a_end >= b_start


def week_type_matches(week_type: str, week: int) -> bool:
    return (
        week_type == "ALL"
        or (week_type == "ODD" and week % 2 == 1)
        or (week_type == "EVEN" and week % 2 == 0)
    )


def week_patterns_overlap(
    start_a: int,
    end_a: int,
    type_a: str,
    start_b: int,
    end_b: int,
    type_b: str,
) -> bool:
    low = max(start_a, start_b)
    high = min(end_a, end_b)
    if low > high:
        return False
    for week in range(low, high + 1):
        if week_type_matches(type_a, week) and week_type_matches(type_b, week):
            return True
    return False


def semester_for_date(conn, target: date):
    return conn.execute(
        """
        SELECT *
        FROM semester
        WHERE status = 1
          AND date(start_date) <= date(?)
          AND date(end_date) >= date(?)
        ORDER BY start_date DESC
        LIMIT 1
        """,
        (target.isoformat(), target.isoformat()),
    ).fetchone()


def semester_by_code(conn, code: str):
    return conn.execute(
        "SELECT * FROM semester WHERE semester_code = ? AND status = 1",
        (code,),
    ).fetchone()


def week_number(semester_row, target: date) -> int:
    start = date.fromisoformat(semester_row["start_date"])
    return ((target - start).days // 7) + 1


def date_for_week_day(semester_row, week: int, week_day: int) -> date:
    start = date.fromisoformat(semester_row["start_date"])
    return start + timedelta(days=(week - 1) * 7 + (week_day - 1))


def effective_schedules_for_date(conn, target: date) -> tuple[Any, int | None, list[dict]]:
    semester = semester_for_date(conn, target)
    if semester is None:
        return None, None, []

    week = week_number(semester, target)
    rows = conn.execute(
        """
        SELECT
            cs.*,
            c.teacher_id,
            c.course_code,
            c.course_name,
            u.real_name AS teacher_name,
            cr.classroom_code,
            cr.classroom_name
        FROM course_schedule cs
        JOIN course c ON c.id = cs.course_id
        JOIN sys_user u ON u.id = c.teacher_id
        JOIN classroom cr ON cr.id = cs.classroom_id
        WHERE cs.semester = ?
          AND cs.status = 'ACTIVE'
          AND cs.start_week <= ?
          AND cs.end_week >= ?
        """,
        (semester["semester_code"], week, week),
    ).fetchall()

    result: list[dict] = []
    for row in rows:
        if not week_type_matches(row["week_type"], week):
            continue
        item = dict(row)

        room_change = conn.execute(
            """
            SELECT * FROM schedule_change
            WHERE schedule_id = ?
              AND status = 'APPROVED'
              AND change_type = 'ROOM'
            ORDER BY COALESCE(reviewed_at, created_at) DESC, id DESC
            LIMIT 1
            """,
            (row["id"],),
        ).fetchone()
        effective_room_id = room_change["new_classroom_id"] if room_change else row["classroom_id"]
        effective_room = conn.execute(
            "SELECT classroom_code, classroom_name FROM classroom WHERE id = ?",
            (effective_room_id,),
        ).fetchone()

        change = conn.execute(
            """
            SELECT *
            FROM schedule_change
            WHERE schedule_id = ?
              AND status = 'APPROVED'
              AND change_type IN ('TIME', 'BOTH')
              AND new_week = ?
            ORDER BY COALESCE(reviewed_at, created_at) DESC, id DESC
            LIMIT 1
            """,
            (row["id"], week),
        ).fetchone()
        if change is not None:
            item["effective_week_day"] = change["new_week_day"]
            item["effective_start_section"] = change["new_start_section"]
            item["effective_end_section"] = change["new_end_section"]
            if change["change_type"] == "BOTH":
                effective_room_id = change["new_classroom_id"]
                effective_room = conn.execute(
                    "SELECT classroom_code, classroom_name FROM classroom WHERE id = ?",
                    (effective_room_id,),
                ).fetchone()
            item["changed"] = True
            item["change_id"] = change["id"]
        else:
            item["effective_week_day"] = row["week_day"]
            item["effective_start_section"] = row["start_section"]
            item["effective_end_section"] = row["end_section"]
            item["changed"] = room_change is not None
            item["change_id"] = room_change["id"] if room_change else None

        item["effective_classroom_id"] = effective_room_id
        item["effective_classroom_code"] = effective_room["classroom_code"] if effective_room else None
        item["effective_classroom_name"] = effective_room["classroom_name"] if effective_room else None
        result.append(item)
    return semester, week, result


def room_course_conflict(
    conn,
    classroom_id: int,
    target: date,
    start_section: int,
    end_section: int,
    *,
    exclude_schedule_id: int | None = None,
) -> dict | None:
    _semester, _week, schedules = effective_schedules_for_date(conn, target)
    weekday = target.isoweekday()
    for item in schedules:
        if exclude_schedule_id is not None and item["id"] == exclude_schedule_id:
            continue
        if item["effective_classroom_id"] != classroom_id:
            continue
        if item["effective_week_day"] != weekday:
            continue
        if intervals_overlap(
            item["effective_start_section"],
            item["effective_end_section"],
            start_section,
            end_section,
        ):
            return item
    return None


def teacher_course_conflict(
    conn,
    teacher_id: int,
    target: date,
    start_section: int,
    end_section: int,
    *,
    exclude_schedule_id: int | None = None,
) -> dict | None:
    _semester, _week, schedules = effective_schedules_for_date(conn, target)
    weekday = target.isoweekday()
    for item in schedules:
        if exclude_schedule_id is not None and item["id"] == exclude_schedule_id:
            continue
        if item["teacher_id"] != teacher_id:
            continue
        if item["effective_week_day"] != weekday:
            continue
        if intervals_overlap(
            item["effective_start_section"],
            item["effective_end_section"],
            start_section,
            end_section,
        ):
            return item
    return None


def room_booking_conflict(
    conn,
    classroom_id: int,
    target: date,
    start_section: int,
    end_section: int,
    *,
    exclude_booking_id: int | None = None,
):
    sql = """
        SELECT * FROM room_booking
        WHERE classroom_id = ?
          AND booking_date = ?
          AND status IN ('PENDING', 'APPROVED')
          AND start_section <= ?
          AND end_section >= ?
    """
    params: list[Any] = [classroom_id, target.isoformat(), end_section, start_section]
    if exclude_booking_id is not None:
        sql += " AND id <> ?"
        params.append(exclude_booking_id)
    return conn.execute(sql, params).fetchone()


def recurring_schedule_conflict(
    conn,
    *,
    semester_code: str,
    teacher_id: int,
    classroom_id: int,
    start_week: int,
    end_week: int,
    week_day: int,
    start_section: int,
    end_section: int,
    week_type: str,
    exclude_schedule_id: int | None = None,
) -> dict | None:
    rows = conn.execute(
        """
        SELECT cs.*, c.teacher_id, c.course_name
        FROM course_schedule cs
        JOIN course c ON c.id = cs.course_id
        WHERE cs.semester = ?
          AND cs.status = 'ACTIVE'
          AND cs.week_day = ?
          AND cs.start_section <= ?
          AND cs.end_section >= ?
        """,
        (semester_code, week_day, end_section, start_section),
    ).fetchall()
    for row in rows:
        if exclude_schedule_id is not None and row["id"] == exclude_schedule_id:
            continue
        if row["teacher_id"] != teacher_id and row["classroom_id"] != classroom_id:
            continue
        if not week_patterns_overlap(
            start_week,
            end_week,
            week_type,
            row["start_week"],
            row["end_week"],
            row["week_type"],
        ):
            continue
        return {
            "type": "TEACHER" if row["teacher_id"] == teacher_id else "CLASSROOM",
            "schedule": dict(row),
        }
    return None


def existing_booking_for_recurring_schedule(
    conn,
    *,
    semester_row,
    classroom_id: int,
    start_week: int,
    end_week: int,
    week_day: int,
    start_section: int,
    end_section: int,
    week_type: str,
):
    for week in range(start_week, end_week + 1):
        if not week_type_matches(week_type, week):
            continue
        target = date_for_week_day(semester_row, week, week_day)
        booking = room_booking_conflict(
            conn,
            classroom_id,
            target,
            start_section,
            end_section,
        )
        if booking is not None:
            return {"date": target.isoformat(), "booking": dict(booking)}
    return None


def schedule_change_conflicts(conn, change_row) -> list[dict]:
    base = conn.execute(
        """
        SELECT cs.*, c.teacher_id, c.course_name
        FROM course_schedule cs
        JOIN course c ON c.id = cs.course_id
        WHERE cs.id = ?
        """,
        (change_row["schedule_id"],),
    ).fetchone()
    if base is None:
        return [{"type": "DATA", "message": "原排课不存在"}]

    semester = semester_by_code(conn, base["semester"])
    if semester is None:
        return [{"type": "DATA", "message": "缺少对应学期配置"}]

    conflicts: list[dict] = []
    change_type = change_row["change_type"]

    if change_type == "ROOM":
        new_room = change_row["new_classroom_id"]
        for week in range(base["start_week"], base["end_week"] + 1):
            if not week_type_matches(base["week_type"], week):
                continue
            target = date_for_week_day(semester, week, base["week_day"])
            room_conflict = room_course_conflict(
                conn,
                new_room,
                target,
                base["start_section"],
                base["end_section"],
                exclude_schedule_id=base["id"],
            )
            if room_conflict:
                conflicts.append({
                    "type": "CLASSROOM",
                    "message": "新教室与其他课程排课冲突",
                    "date": target.isoformat(),
                    "detail": room_conflict,
                })
                break
            booking = room_booking_conflict(
                conn, new_room, target, base["start_section"], base["end_section"]
            )
            if booking:
                conflicts.append({
                    "type": "BOOKING",
                    "message": "新教室与已有预约冲突",
                    "date": target.isoformat(),
                    "detail": dict(booking),
                })
                break
        return conflicts

    target = date_for_week_day(semester, change_row["new_week"], change_row["new_week_day"])
    room_id = base["classroom_id"] if change_type == "TIME" else change_row["new_classroom_id"]
    start = change_row["new_start_section"]
    end = change_row["new_end_section"]

    teacher_conflict = teacher_course_conflict(
        conn,
        base["teacher_id"],
        target,
        start,
        end,
        exclude_schedule_id=base["id"],
    )
    if teacher_conflict:
        conflicts.append({"type": "TEACHER", "message": "教师在新时段已有其他课程", "detail": teacher_conflict})

    room_conflict = room_course_conflict(
        conn,
        room_id,
        target,
        start,
        end,
        exclude_schedule_id=base["id"],
    )
    if room_conflict:
        conflicts.append({"type": "CLASSROOM", "message": "新教室或新时段已有课程", "detail": room_conflict})

    booking = room_booking_conflict(conn, room_id, target, start, end)
    if booking:
        conflicts.append({"type": "BOOKING", "message": "新教室或新时段已有预约", "detail": dict(booking)})

    return conflicts
