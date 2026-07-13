from __future__ import annotations

from datetime import date

from flask import Blueprint, request

from api_utils import as_int, fail, ok, parse_date
from auth_guard import auth_required
from db import get_db
from services import room_booking_conflict, room_course_conflict

bp = Blueprint("common", __name__, url_prefix="/api")


@bp.get("/departments")
@auth_required
def departments():
    rows = get_db().execute(
        "SELECT id, department_code, department_name, manager_name FROM department WHERE status = 1 ORDER BY department_name"
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/classes")
@auth_required
def classes():
    department_id = request.args.get("departmentId")
    sql = """
        SELECT cg.*, d.department_name
        FROM class_group cg
        JOIN department d ON d.id = cg.department_id
        WHERE cg.status = 1
    """
    params = []
    if department_id:
        sql += " AND cg.department_id = ?"
        params.append(department_id)
    sql += " ORDER BY cg.grade DESC, cg.class_name"
    rows = get_db().execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/semesters")
@auth_required
def semesters():
    rows = get_db().execute(
        "SELECT * FROM semester WHERE status = 1 ORDER BY start_date DESC"
    ).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/classrooms")
@auth_required
def classrooms():
    conn = get_db()
    sql = "SELECT * FROM classroom WHERE 1=1"
    params = []
    if request.args.get("status"):
        sql += " AND status = ?"
        params.append(request.args["status"])
    if request.args.get("campus"):
        sql += " AND campus = ?"
        params.append(request.args["campus"])
    if request.args.get("roomType"):
        sql += " AND room_type = ?"
        params.append(request.args["roomType"])
    if request.args.get("minCapacity"):
        sql += " AND capacity >= ?"
        params.append(request.args["minCapacity"])
    sql += " ORDER BY campus, building, floor, classroom_code"
    rows = conn.execute(sql, params).fetchall()
    return ok([dict(row) for row in rows])


@bp.get("/classrooms/<int:classroom_id>")
@auth_required
def classroom_detail(classroom_id: int):
    row = get_db().execute("SELECT * FROM classroom WHERE id = ?", (classroom_id,)).fetchone()
    if row is None:
        return fail(40401, "教室不存在", 404)
    return ok(dict(row))


@bp.get("/classrooms/available")
@auth_required
def available_classrooms():
    try:
        target = parse_date(request.args.get("date"), "date")
        start = as_int(request.args.get("startSection"), "startSection", minimum=1)
        end = as_int(request.args.get("endSection"), "endSection", minimum=1)
        participants = as_int(
            request.args.get("participantCount", 1),
            "participantCount",
            minimum=1,
        )
    except ValueError as exc:
        return fail(40001, str(exc))
    if end < start:
        return fail(40001, "endSection不能小于startSection")

    conn = get_db()
    rows = conn.execute(
        """
        SELECT * FROM classroom
        WHERE status = 'AVAILABLE' AND capacity >= ?
        ORDER BY capacity, campus, building, classroom_code
        """,
        (participants,),
    ).fetchall()
    available = []
    for row in rows:
        if room_course_conflict(conn, row["id"], target, start, end):
            continue
        if room_booking_conflict(conn, row["id"], target, start, end):
            continue
        available.append(dict(row))
    return ok(available)
