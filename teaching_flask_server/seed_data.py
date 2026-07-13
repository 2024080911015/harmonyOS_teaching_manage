from __future__ import annotations

import argparse
import json
import random
import secrets
import sqlite3
from collections import Counter
from datetime import date, datetime, timedelta
from pathlib import Path

from werkzeug.security import check_password_hash, generate_password_hash

from config import Config
from db import connect_db
from migrate import migrate


DEFAULT_USER_COUNT = 2000
DEFAULT_PASSWORD = "Test123456"
DEFAULT_RANDOM_SEED = 20260711

SURNAMES = list("赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜戚谢邹喻柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳酆鲍史唐费廉岑薛雷贺倪汤滕殷罗毕郝邬安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵湛汪祁毛禹狄米贝明臧计伏成戴谈宋茅庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄危江童颜郭梅盛林刁钟徐邱骆高夏蔡田樊胡凌霍虞万支柯昝管卢莫经房裘缪干解应宗丁宣贲邓郁单杭洪包诸左石崔吉钮龚程嵇邢滑裴陆荣翁荀羊甄曲家封芮羿储靳汲邴糜松井段富巫乌焦巴弓牧隗山谷车侯宓蓬全郗班仰秋仲伊宫宁仇栾暴甘钭厉戎祖武符刘景詹束龙叶幸司韶黎乔苍双闻莘党翟谭贡劳逄姬申扶堵冉宰郦雍却璩桑桂濮牛寿通边扈燕冀郏浦尚农温别庄晏柴瞿阎充慕连茹习宦艾鱼容向古易慎戈廖庾终暨居衡步都耿满弘匡国文寇广禄阙东欧殳沃利蔚越夔隆师巩厍聂晁勾敖融冷訾辛阚那简饶空曾毋沙乜养鞠须丰巢关蒯相查后荆红游竺权逯盖益桓公")
GIVEN_CHARS = list("子轩宇浩梓涵雨欣思远嘉怡俊杰明哲诗涵若曦泽宇欣妍博文晓彤佳琪天佑晨曦瑞雪志远雅婷文昊梦瑶亦辰语桐奕凡可馨景行知夏书言安然清越云舒星河沐阳锦程嘉言静姝怀瑾乐成")

DEPARTMENTS = [
    ("CS", "计算机科学与技术学院", "张明远", ["计算机科学与技术", "软件工程", "网络工程"]),
    ("AI", "人工智能学院", "李思源", ["人工智能", "数据科学与大数据技术", "智能科学与技术"]),
    ("EE", "电子信息工程学院", "王建国", ["电子信息工程", "通信工程", "自动化"]),
    ("ME", "机械工程学院", "陈志强", ["机械设计制造及其自动化", "机器人工程", "工业设计"]),
    ("BA", "经济管理学院", "周雅琴", ["工商管理", "会计学", "金融学"]),
    ("FL", "外国语学院", "吴静怡", ["英语", "商务英语", "翻译"]),
    ("MA", "数学与统计学院", "赵文博", ["数学与应用数学", "统计学", "信息与计算科学"]),
    ("AR", "建筑与艺术学院", "孙清华", ["建筑学", "视觉传达设计", "环境设计"]),
]

COURSE_NAMES = [
    "程序设计基础", "数据结构", "算法设计与分析", "数据库原理", "计算机网络",
    "操作系统", "软件工程", "Web应用开发", "移动应用开发", "信息安全导论",
    "人工智能导论", "机器学习", "深度学习", "自然语言处理", "计算机视觉",
    "数字电路", "信号与系统", "通信原理", "自动控制原理", "嵌入式系统",
    "高等数学", "线性代数", "概率论与数理统计", "离散数学", "数值分析",
    "大学英语", "学术写作", "跨文化交际", "管理学原理", "经济学基础",
    "会计学基础", "市场营销", "工程制图", "机械原理", "大学物理",
    "创新创业实践", "职业生涯规划", "项目管理", "设计思维", "科研方法训练",
]

ROOM_TYPES = ["NORMAL", "MULTIMEDIA", "COMPUTER", "LABORATORY"]
CAMPUSES = ["中心校区", "东湖校区", "大学城校区"]
BUILDINGS = ["博学楼", "明德楼", "致远楼", "格物楼", "笃行楼", "创新中心"]
TITLES = ["助教", "讲师", "副教授", "教授"]


def sql_time(value: datetime) -> str:
    return value.replace(microsecond=0).isoformat(sep=" ")


def generated_name(index: int) -> str:
    surname = SURNAMES[index % len(SURNAMES)]
    first = GIVEN_CHARS[(index * 7 + 3) % len(GIVEN_CHARS)]
    second = GIVEN_CHARS[(index * 13 + 11) % len(GIVEN_CHARS)]
    return surname + first + second


def insert_one(conn: sqlite3.Connection, sql: str, values: tuple) -> int:
    return int(conn.execute(sql, values).lastrowid)


def clear_database(conn: sqlite3.Connection) -> None:
    tables = [
        "room_booking_log", "approval_record", "notification_recipient",
        "leave_request_course", "auth_token", "schedule_change", "room_booking",
        "leave_request", "course_enrollment", "notification", "course_schedule",
        "course", "student_profile", "teacher_profile", "academic_staff_profile",
        "sys_user", "class_group", "classroom", "semester", "department",
    ]
    for table in tables:
        conn.execute(f"DELETE FROM {table}")
    conn.execute("DELETE FROM sqlite_sequence")


def create_foundation(conn: sqlite3.Connection) -> dict[str, list]:
    department_ids: list[int] = []
    for code, name, manager, _majors in DEPARTMENTS:
        department_ids.append(insert_one(
            conn,
            "INSERT INTO department(department_code, department_name, manager_name) VALUES (?, ?, ?)",
            (f"TEST_{code}", name, manager),
        ))

    class_rows: list[dict] = []
    for i in range(60):
        dep_index = i % len(DEPARTMENTS)
        dep_id = department_ids[dep_index]
        major = DEPARTMENTS[dep_index][3][(i // len(DEPARTMENTS)) % 3]
        grade = str(2023 + (i // 15))
        class_no = i // 8 + 1
        class_id = insert_one(
            conn,
            """
            INSERT INTO class_group(
                class_code, class_name, grade, major_name, department_id,
                campus, student_count, counselor_name
            ) VALUES (?, ?, ?, ?, ?, ?, 0, ?)
            """,
            (
                f"TEST_CL{i + 1:03d}", f"{grade}级{major}{class_no}班", grade,
                major, dep_id, CAMPUSES[dep_index % len(CAMPUSES)],
                generated_name(8000 + i),
            ),
        )
        class_rows.append({"id": class_id, "department_id": dep_id, "grade": grade})

    classroom_rows: list[dict] = []
    for i in range(100):
        room_type = ROOM_TYPES[i % len(ROOM_TYPES)]
        capacity = [40, 60, 80, 120][i % 4]
        status = "AVAILABLE" if i < 94 else ("MAINTENANCE" if i < 98 else "DISABLED")
        campus = CAMPUSES[i % len(CAMPUSES)]
        building = BUILDINGS[(i // 3) % len(BUILDINGS)]
        floor = i % 6 + 1
        room_no = f"{floor}{i % 20 + 1:02d}"
        room_id = insert_one(
            conn,
            """
            INSERT INTO classroom(
                classroom_code, classroom_name, campus, building, floor,
                room_type, capacity, equipment, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                f"TEST_R{i + 1:03d}", f"{building}{room_no}室", campus, building,
                floor, room_type, capacity,
                "智慧黑板、投影仪、无线麦克风" if room_type != "NORMAL" else "黑板、投影仪",
                status,
            ),
        )
        classroom_rows.append({"id": room_id, "capacity": capacity, "status": status})

    semesters = [
        ("2025-SPRING", "2024-2025学年第二学期", "2025-02-24", "2025-07-06", 1),
        ("2025-FALL", "2025-2026学年第一学期", "2025-09-01", "2026-01-18", 1),
        ("2026-SPRING", "2025-2026学年第二学期", "2026-02-23", "2026-07-12", 1),
        ("2026-FALL", "2026-2027学年第一学期", "2026-09-01", "2027-01-17", 1),
    ]
    semester_ids = []
    for code, name, start, end, status in semesters:
        semester_ids.append(insert_one(
            conn,
            "INSERT INTO semester(semester_code, semester_name, start_date, end_date, status) VALUES (?, ?, ?, ?, ?)",
            (code, name, start, end, status),
        ))

    return {
        "departments": department_ids,
        "classes": class_rows,
        "classrooms": classroom_rows,
        "semesters": semester_ids,
    }


def role_counts(total: int) -> dict[str, int]:
    students = round(total * 0.90)
    teachers = round(total * 0.075)
    staff = round(total * 0.02)
    admins = total - students - teachers - staff
    return {"STUDENT": students, "TEACHER": teachers, "ACADEMIC_STAFF": staff, "ADMIN": admins}


def create_users(
    conn: sqlite3.Connection,
    foundation: dict[str, list],
    total: int,
    password: str,
) -> dict[str, list[int]]:
    counts = role_counts(total)
    password_hash = generate_password_hash(password)
    users: dict[str, list[int]] = {role: [] for role in counts}
    class_counts: Counter[int] = Counter()
    serial = 0

    for role, amount in counts.items():
        for i in range(amount):
            serial += 1
            if role == "STUDENT":
                prefix, width = "student", 4
                class_row = foundation["classes"][i % len(foundation["classes"])]
                class_id = class_row["id"]
                department_id = class_row["department_id"]
                class_counts[class_id] += 1
                status = 0 if i % 50 == 49 else 1
            elif role == "TEACHER":
                prefix, width = "teacher", 3
                class_id = None
                department_id = foundation["departments"][i % len(foundation["departments"])]
                status = 0 if i % 75 == 74 else 1
            elif role == "ACADEMIC_STAFF":
                prefix, width = "staff", 3
                class_id = None
                department_id = foundation["departments"][i % len(foundation["departments"])]
                status = 1
            else:
                prefix, width = "admin", 2
                class_id = None
                department_id = foundation["departments"][i % len(foundation["departments"])]
                status = 1

            account = f"test_{prefix}_{i + 1:0{width}d}"
            user_id = insert_one(
                conn,
                """
                INSERT INTO sys_user(
                    account, password_hash, real_name, role, gender, phone, email,
                    avatar_url, department_id, class_id, status, last_login_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    account, password_hash, generated_name(serial), role, (i % 2) + 1,
                    f"1{30 + serial % 70:02d}{serial:08d}"[-11:],
                    f"{account}@test.example.com",
                    f"https://api.dicebear.com/9.x/initials/svg?seed={account}",
                    department_id, class_id, status,
                    sql_time(datetime.now() - timedelta(days=i % 45, hours=i % 24)),
                ),
            )
            users[role].append(user_id)

            if role == "STUDENT":
                academic_status = "ACTIVE" if status else ("SUSPENDED" if i % 2 else "WITHDRAWN")
                conn.execute(
                    """
                    INSERT INTO student_profile(
                        user_id, student_no, admission_date, academic_status, earned_credits
                    ) VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        user_id, f"S{2023000000 + i + 1}",
                        f"{foundation['classes'][i % 60]['grade']}-09-01",
                        academic_status, float((i * 3) % 120),
                    ),
                )
            elif role == "TEACHER":
                conn.execute(
                    """
                    INSERT INTO teacher_profile(
                        user_id, employee_no, professional_title, introduction
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (
                        user_id, f"T{10000 + i + 1}", TITLES[(i // 20) % len(TITLES)],
                        f"主要承担{COURSE_NAMES[i % len(COURSE_NAMES)]}相关课程教学与科研工作。",
                    ),
                )
            else:
                employee_prefix = "A" if role == "ADMIN" else "E"
                conn.execute(
                    """
                    INSERT INTO academic_staff_profile(
                        user_id, employee_no, responsibility_area, approval_level
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (
                        user_id, f"{employee_prefix}{20000 + i + 1}",
                        "系统管理与权限维护" if role == "ADMIN" else "教学运行、排课与业务审批",
                        9 if role == "ADMIN" else 2 + i % 3,
                    ),
                )

    for class_id, count in class_counts.items():
        conn.execute("UPDATE class_group SET student_count = ? WHERE id = ?", (count, class_id))
    return users


def create_courses(
    conn: sqlite3.Connection,
    foundation: dict[str, list],
    users: dict[str, list[int]],
    now: datetime,
) -> tuple[list[dict], list[int]]:
    active_teachers = [
        user_id for user_id in users["TEACHER"]
        if conn.execute("SELECT status FROM sys_user WHERE id = ?", (user_id,)).fetchone()[0] == 1
    ]
    available_rooms = [row for row in foundation["classrooms"] if row["status"] == "AVAILABLE"]
    courses: list[dict] = []
    schedule_ids: list[int] = []
    for i in range(240):
        teacher_id = active_teachers[i % len(active_teachers)]
        department_id = conn.execute(
            "SELECT department_id FROM sys_user WHERE id = ?", (teacher_id,)
        ).fetchone()[0]
        course_id = insert_one(
            conn,
            """
            INSERT INTO course(
                course_code, course_name, teacher_id, department_id, capacity,
                credit, selection_start, selection_end, selection_status, status, description
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'OPEN', 1, ?)
            """,
            (
                f"TEST_C{i + 1:04d}", f"{COURSE_NAMES[i % len(COURSE_NAMES)]}（{i // len(COURSE_NAMES) + 1}班）",
                teacher_id, department_id, 80, [1.0, 1.5, 2.0, 2.5, 3.0][i % 5],
                sql_time(now - timedelta(days=60)), sql_time(now + timedelta(days=60)),
                "包含理论讲授、课堂练习、阶段作业和课程项目，供完整业务流程测试使用。",
            ),
        )
        phase = 7 if i >= len(active_teachers) else 0
        slot = (i + phase) % 30
        room = available_rooms[i % len(available_rooms)]
        schedule_id = insert_one(
            conn,
            """
            INSERT INTO course_schedule(
                course_id, classroom_id, semester, start_week, end_week,
                week_day, start_section, end_section, week_type, status
            ) VALUES (?, ?, '2026-FALL', 1, 18, ?, ?, ?, ?, ?)
            """,
            (
                course_id, room["id"], slot // 6 + 1, slot % 6 * 2 + 1,
                slot % 6 * 2 + 2, ["ALL", "ALL", "ODD", "EVEN"][i % 4],
                "CANCELLED" if i % 40 == 39 else "ACTIVE",
            ),
        )
        courses.append({"id": course_id, "slot": slot, "teacher_id": teacher_id})
        schedule_ids.append(schedule_id)
    return courses, schedule_ids


def create_enrollments(
    conn: sqlite3.Connection,
    users: dict[str, list[int]],
    courses: list[dict],
    now: datetime,
) -> dict[int, list[int]]:
    active_students = [
        user_id for user_id in users["STUDENT"]
        if conn.execute("SELECT status FROM sys_user WHERE id = ?", (user_id,)).fetchone()[0] == 1
    ]
    selected_by_student: dict[int, list[int]] = {}
    for i, student_id in enumerate(active_students):
        selected: list[int] = []
        used_slots: set[int] = set()
        cursor = (i * 6) % len(courses)
        while len(selected) < 6:
            course = courses[cursor % len(courses)]
            if course["slot"] not in used_slots:
                conn.execute(
                    """
                    INSERT INTO course_enrollment(
                        course_id, student_id, status, selected_at, created_at, updated_at
                    ) VALUES (?, ?, 'SELECTED', ?, ?, ?)
                    """,
                    (
                        course["id"], student_id,
                        sql_time(now - timedelta(days=(i + len(selected)) % 45)),
                        sql_time(now - timedelta(days=(i + len(selected)) % 45)), sql_time(now),
                    ),
                )
                selected.append(course["id"])
                used_slots.add(course["slot"])
            cursor += 1
        selected_by_student[student_id] = selected
        if i % 5 == 0:
            dropped = courses[(cursor + 17) % len(courses)]["id"]
            if dropped not in selected:
                conn.execute(
                    """
                    INSERT INTO course_enrollment(
                        course_id, student_id, status, selected_at, dropped_at
                    ) VALUES (?, ?, 'DROPPED', ?, ?)
                    """,
                    (dropped, student_id, sql_time(now - timedelta(days=50)), sql_time(now - timedelta(days=20))),
                )

    for i, course in enumerate(courses):
        if i % 7 == 0:
            conn.execute("UPDATE course SET selection_status = 'CLOSED' WHERE id = ?", (course["id"],))
        if i % 53 == 52:
            conn.execute("UPDATE course SET status = 0, selection_status = 'CLOSED' WHERE id = ?", (course["id"],))
    return selected_by_student


def create_notifications(
    conn: sqlite3.Connection,
    foundation: dict[str, list],
    users: dict[str, list[int]],
    now: datetime,
) -> None:
    publishers = [
        row[0] for row in conn.execute(
            """
            SELECT id FROM sys_user
            WHERE role IN ('TEACHER', 'ACADEMIC_STAFF', 'ADMIN') AND status = 1
            ORDER BY id
            """
        )
    ]
    active_students = [
        row[0] for row in conn.execute("SELECT id FROM sys_user WHERE role = 'STUDENT' AND status = 1")
    ]
    for i in range(120):
        audience = ["ALL_STUDENTS", "CLASS", "DEPARTMENT", "USER"][i % 4]
        target_class = target_department = target_user = None
        if audience == "CLASS":
            target_class = foundation["classes"][i % len(foundation["classes"])]["id"]
            recipients = [row[0] for row in conn.execute(
                "SELECT id FROM sys_user WHERE class_id = ? AND status = 1", (target_class,)
            )]
        elif audience == "DEPARTMENT":
            target_department = foundation["departments"][i % len(foundation["departments"])]
            recipients = [row[0] for row in conn.execute(
                "SELECT id FROM sys_user WHERE department_id = ? AND status = 1", (target_department,)
            )]
        elif audience == "USER":
            target_user = active_students[(i * 17) % len(active_students)]
            recipients = [target_user]
        else:
            recipients = active_students
        status = "WITHDRAWN" if i % 13 == 12 else "PUBLISHED"
        published_at = now - timedelta(days=i % 70, hours=i % 12)
        notification_id = insert_one(
            conn,
            """
            INSERT INTO notification(
                publisher_id, title, content, audience_type, target_class_id,
                target_department_id, target_user_id, status, published_at,
                withdrawn_at, expires_at, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                publishers[i % len(publishers)], f"测试通知{i + 1:03d}：{['教学安排', '考试提醒', '活动公告', '个人事项'][i % 4]}",
                f"这是第{i + 1}条完整测试通知，用于验证通知列表、详情、范围筛选、已读状态和撤回功能。",
                audience, target_class, target_department, target_user, status,
                sql_time(published_at), sql_time(now - timedelta(days=1)) if status == "WITHDRAWN" else None,
                sql_time(now + timedelta(days=30 - i % 20)), sql_time(published_at), sql_time(now),
            ),
        )
        conn.executemany(
            """
            INSERT INTO notification_recipient(notification_id, user_id, is_read, read_at, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            [
                (
                    notification_id, user_id, 1 if (user_id + i) % 3 else 0,
                    sql_time(published_at + timedelta(hours=6)) if (user_id + i) % 3 else None,
                    sql_time(published_at),
                )
                for user_id in recipients
            ],
        )


def create_leaves(
    conn: sqlite3.Connection,
    users: dict[str, list[int]],
    selected_by_student: dict[int, list[int]],
    now: datetime,
) -> None:
    students = list(selected_by_student)
    reviewers = users["ACADEMIC_STAFF"] + users["ADMIN"]
    statuses = ["PENDING", "APPROVED", "REJECTED", "CANCELLED"]
    for i in range(600):
        student_id = students[(i * 11) % len(students)]
        status = statuses[i % len(statuses)]
        start = date(2026, 9, 1) + timedelta(days=i % 100)
        end = start + timedelta(days=1 if i % 10 == 0 else 0)
        reviewer = reviewers[i % len(reviewers)] if status in {"APPROVED", "REJECTED"} else None
        leave_id = insert_one(
            conn,
            """
            INSERT INTO leave_request(
                leave_no, applicant_id, leave_type, start_date, end_date,
                start_section, end_section, reason, attachment_url, status,
                reviewer_id, review_comment, reviewed_at, cancel_reason,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                f"TEST_LV2026{i + 1:05d}", student_id, ["SICK", "PERSONAL", "OTHER"][i % 3],
                start.isoformat(), end.isoformat(), 1 + i % 6, 2 + i % 6,
                ["身体不适需要就医", "家庭事务需要处理", "参加校级学科竞赛"][i % 3],
                f"https://files.test.example.com/leaves/{i + 1}.pdf" if i % 4 == 0 else None,
                status, reviewer,
                "情况属实，同意请假" if status == "APPROVED" else ("材料不足，暂不批准" if status == "REJECTED" else None),
                sql_time(now - timedelta(days=i % 20)) if reviewer else None,
                "个人行程调整，撤销申请" if status == "CANCELLED" else None,
                sql_time(now - timedelta(days=30 + i % 30)), sql_time(now - timedelta(days=i % 20)),
            ),
        )
        selected_courses = selected_by_student[student_id]
        for course_id in selected_courses[: 1 + i % 2]:
            conn.execute(
                "INSERT INTO leave_request_course(leave_request_id, course_id) VALUES (?, ?)",
                (leave_id, course_id),
            )
        if status in {"APPROVED", "REJECTED"}:
            conn.execute(
                """
                INSERT INTO approval_record(business_type, business_id, approver_id, action, comment, created_at)
                VALUES ('LEAVE_REQUEST', ?, ?, ?, ?, ?)
                """,
                (
                    leave_id, reviewer, "APPROVE" if status == "APPROVED" else "REJECT",
                    "情况属实，同意请假" if status == "APPROVED" else "材料不足，暂不批准",
                    sql_time(now - timedelta(days=i % 20)),
                ),
            )


def create_schedule_changes(
    conn: sqlite3.Connection,
    foundation: dict[str, list],
    courses: list[dict],
    schedule_ids: list[int],
    users: dict[str, list[int]],
    now: datetime,
) -> None:
    reviewers = users["ACADEMIC_STAFF"] + users["ADMIN"]
    available_rooms = [row for row in foundation["classrooms"] if row["status"] == "AVAILABLE"]
    statuses = ["PENDING", "APPROVED", "REJECTED", "CANCELLED"]
    for i in range(180):
        change_type = ["TIME", "ROOM", "BOTH"][i % 3]
        status = statuses[i % len(statuses)]
        reviewer = reviewers[i % len(reviewers)] if status in {"APPROVED", "REJECTED"} else None
        needs_time = change_type in {"TIME", "BOTH"}
        needs_room = change_type in {"ROOM", "BOTH"}
        new_start = 1 + ((i + 2) % 6) * 2
        change_id = insert_one(
            conn,
            """
            INSERT INTO schedule_change(
                change_no, schedule_id, applicant_id, change_type, new_classroom_id,
                new_week, new_week_day, new_start_section, new_end_section,
                reason, status, reviewer_id, review_comment, reviewed_at,
                cancel_reason, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                f"TEST_SC2026{i + 1:05d}", schedule_ids[i], courses[i]["teacher_id"], change_type,
                available_rooms[(i + 13) % len(available_rooms)]["id"] if needs_room else None,
                2 + i % 16 if needs_time else None, 1 + (i + 1) % 5 if needs_time else None,
                new_start if needs_time else None, new_start + 1 if needs_time else None,
                ["参加学术会议，申请调整授课时间", "原教室设备维护，申请更换教室", "配合学院大型活动调整安排"][i % 3],
                status, reviewer,
                "已核对教学安排，同意调整" if status == "APPROVED" else ("与其他教学安排冲突" if status == "REJECTED" else None),
                sql_time(now - timedelta(days=i % 15)) if reviewer else None,
                "原计划有变，撤销调课" if status == "CANCELLED" else None,
                sql_time(now - timedelta(days=20 + i % 25)), sql_time(now - timedelta(days=i % 15)),
            ),
        )
        if status in {"APPROVED", "REJECTED"}:
            conn.execute(
                """
                INSERT INTO approval_record(business_type, business_id, approver_id, action, comment, created_at)
                VALUES ('SCHEDULE_CHANGE', ?, ?, ?, ?, ?)
                """,
                (
                    change_id, reviewer, "APPROVE" if status == "APPROVED" else "REJECT",
                    "已核对教学安排，同意调整" if status == "APPROVED" else "与其他教学安排冲突",
                    sql_time(now - timedelta(days=i % 15)),
                ),
            )


def create_bookings(
    conn: sqlite3.Connection,
    foundation: dict[str, list],
    users: dict[str, list[int]],
    now: datetime,
) -> None:
    applicants = [
        row[0] for row in conn.execute(
            """
            SELECT id FROM sys_user
            WHERE role IN ('STUDENT', 'TEACHER') AND status = 1
            ORDER BY id
            LIMIT 450
            """
        )
    ]
    reviewers = users["ACADEMIC_STAFF"] + users["ADMIN"]
    rooms = [row for row in foundation["classrooms"] if row["status"] == "AVAILABLE"]
    statuses = ["PENDING", "APPROVED", "REJECTED", "CANCELLED", "FINISHED"]
    for i in range(500):
        status = statuses[i % len(statuses)]
        room = rooms[i % len(rooms)]
        if status in {"PENDING", "APPROVED"}:
            booking_date = now.date() + timedelta(days=1 + i // len(rooms))
        else:
            booking_date = now.date() - timedelta(days=1 + i // len(rooms))
        reviewer = reviewers[i % len(reviewers)] if status in {"APPROVED", "REJECTED", "FINISHED"} else None
        start_section = 1 + (i % 6) * 2
        created = now - timedelta(days=20 + i % 30)
        booking_id = insert_one(
            conn,
            """
            INSERT INTO room_booking(
                booking_no, applicant_id, classroom_id, booking_date,
                start_section, end_section, purpose, participant_count, status,
                reviewer_id, review_comment, reviewed_at, cancel_reason,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                f"TEST_RB2026{i + 1:05d}", applicants[i % len(applicants)], room["id"],
                booking_date.isoformat(), start_section, start_section + 1,
                ["课程小组研讨", "学生社团活动", "学术讲座彩排", "课程项目答辩"][i % 4],
                min(room["capacity"], 10 + i % 55), status, reviewer,
                "申请信息完整，场地可用" if status in {"APPROVED", "FINISHED"} else ("同一时段已有教学安排" if status == "REJECTED" else None),
                sql_time(created + timedelta(days=2)) if reviewer else None,
                "活动计划取消" if status == "CANCELLED" else None,
                sql_time(created), sql_time(now - timedelta(days=i % 10)),
            ),
        )
        conn.execute(
            """
            INSERT INTO room_booking_log(
                booking_id, operator_id, action, old_status, new_status, remark, created_at
            ) VALUES (?, ?, 'SUBMIT', NULL, 'PENDING', '提交教室预约申请', ?)
            """,
            (booking_id, applicants[i % len(applicants)], sql_time(created)),
        )
        if i % 7 == 0:
            conn.execute(
                """
                INSERT INTO room_booking_log(
                    booking_id, operator_id, action, old_status, new_status, remark, created_at
                ) VALUES (?, ?, 'UPDATE', 'PENDING', 'PENDING', '补充活动说明和参与人数', ?)
                """,
                (booking_id, applicants[i % len(applicants)], sql_time(created + timedelta(days=1))),
            )
        if status != "PENDING":
            action = {"APPROVED": "APPROVE", "REJECTED": "REJECT", "CANCELLED": "CANCEL", "FINISHED": "FINISH"}[status]
            operator = applicants[i % len(applicants)] if status == "CANCELLED" else reviewer
            conn.execute(
                """
                INSERT INTO room_booking_log(
                    booking_id, operator_id, action, old_status, new_status, remark, created_at
                ) VALUES (?, ?, ?, 'PENDING', ?, ?, ?)
                """,
                (
                    booking_id, operator, action, status,
                    "测试预约状态流转记录", sql_time(created + timedelta(days=2)),
                ),
            )
        if status in {"APPROVED", "REJECTED"}:
            conn.execute(
                """
                INSERT INTO approval_record(business_type, business_id, approver_id, action, comment, created_at)
                VALUES ('ROOM_BOOKING', ?, ?, ?, ?, ?)
                """,
                (
                    booking_id, reviewer, "APPROVE" if status == "APPROVED" else "REJECT",
                    "申请信息完整，场地可用" if status == "APPROVED" else "同一时段已有教学安排",
                    sql_time(created + timedelta(days=2)),
                ),
            )


def create_tokens(conn: sqlite3.Connection, users: dict[str, list[int]], now: datetime) -> None:
    sample_users = users["STUDENT"][:70] + users["TEACHER"][:30] + users["ACADEMIC_STAFF"][:15] + users["ADMIN"][:5]
    for i, user_id in enumerate(sample_users):
        conn.execute(
            """
            INSERT INTO auth_token(token, user_id, expires_at, revoked, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                f"test-token-{i + 1:03d}-{secrets.token_hex(16)}", user_id,
                sql_time(now + timedelta(days=7)) if i % 4 else sql_time(now - timedelta(days=1)),
                1 if i % 5 == 0 else 0, sql_time(now - timedelta(days=i % 10)),
            ),
        )


def validate(conn: sqlite3.Connection, requested_users: int, password: str) -> dict[str, int]:
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    if integrity != "ok":
        raise RuntimeError(f"SQLite integrity_check failed: {integrity}")
    foreign_key_errors = conn.execute("PRAGMA foreign_key_check").fetchall()
    if foreign_key_errors:
        raise RuntimeError(f"Foreign key errors: {foreign_key_errors[:5]}")
    actual_users = conn.execute("SELECT COUNT(*) FROM sys_user").fetchone()[0]
    if actual_users != requested_users:
        raise RuntimeError(f"Expected {requested_users} users, got {actual_users}")
    profile_count = sum(
        conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        for table in ("student_profile", "teacher_profile", "academic_staff_profile")
    )
    if profile_count != requested_users:
        raise RuntimeError(f"Expected {requested_users} role profiles, got {profile_count}")
    bad_course_counts = conn.execute(
        """
        SELECT COUNT(*) FROM course c
        WHERE c.selected_count != (
            SELECT COUNT(*) FROM course_enrollment ce
            WHERE ce.course_id = c.id AND ce.status = 'SELECTED'
        )
        """
    ).fetchone()[0]
    if bad_course_counts:
        raise RuntimeError(f"Course selected_count mismatch: {bad_course_counts} rows")
    bad_class_counts = conn.execute(
        """
        SELECT COUNT(*) FROM class_group cg
        WHERE cg.student_count != (SELECT COUNT(*) FROM sys_user u WHERE u.class_id = cg.id)
        """
    ).fetchone()[0]
    if bad_class_counts:
        raise RuntimeError(f"Class student_count mismatch: {bad_class_counts} rows")
    sample_hash = conn.execute("SELECT password_hash FROM sys_user ORDER BY id LIMIT 1").fetchone()[0]
    if not check_password_hash(sample_hash, password):
        raise RuntimeError("Generated password cannot authenticate")

    counts = {}
    for row in conn.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
    ):
        counts[row[0]] = conn.execute(f"SELECT COUNT(*) FROM {row[0]}").fetchone()[0]
    return counts


def write_report(path: Path, counts: dict[str, int], roles: dict[str, int], password: str) -> None:
    payload = {
        "generated_at": datetime.now().replace(microsecond=0).isoformat(),
        "database": str(Path(Config.DATABASE).resolve()),
        "shared_password": password,
        "accounts": {
            "student": "test_student_0001 ...",
            "teacher": "test_teacher_001 ...",
            "academic_staff": "test_staff_001 ...",
            "admin": "test_admin_01 ...",
        },
        "role_counts": roles,
        "table_counts": counts,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="为教学过程管理系统生成完整的关联测试数据")
    parser.add_argument("--users", type=int, default=DEFAULT_USER_COUNT, help="测试账号总数，默认 2000")
    parser.add_argument("--password", default=DEFAULT_PASSWORD, help="所有测试账号共用密码")
    parser.add_argument("--seed", type=int, default=DEFAULT_RANDOM_SEED, help="随机种子")
    parser.add_argument(
        "--replace", action="store_true",
        help="清空数据库中的全部现有业务数据后重新生成（危险操作，必须显式指定）",
    )
    args = parser.parse_args()
    if args.users < 100:
        raise SystemExit("--users 不能小于 100，否则无法生成完整的角色和业务分布")
    if len(args.password) < 6:
        raise SystemExit("--password 至少需要 6 位")

    random.seed(args.seed)
    now = datetime.now()
    conn = connect_db(Config.DATABASE)
    try:
        migrate(conn)
        existing = conn.execute("SELECT COUNT(*) FROM sys_user").fetchone()[0]
        if existing and not args.replace:
            raise SystemExit(
                f"数据库已有 {existing} 个用户。为保护现有数据，未执行生成；"
                "确认要清空全部业务数据时请显式添加 --replace。"
            )
        conn.execute("BEGIN IMMEDIATE")
        if args.replace:
            clear_database(conn)
        foundation = create_foundation(conn)
        users = create_users(conn, foundation, args.users, args.password)
        courses, schedules = create_courses(conn, foundation, users, now)
        selected = create_enrollments(conn, users, courses, now)
        create_notifications(conn, foundation, users, now)
        create_leaves(conn, users, selected, now)
        create_schedule_changes(conn, foundation, courses, schedules, users, now)
        create_bookings(conn, foundation, users, now)
        create_tokens(conn, users, now)
        counts = validate(conn, args.users, args.password)
        conn.commit()
        report_path = Path(__file__).resolve().parent / "data" / "test_data_summary.json"
        write_report(report_path, counts, role_counts(args.users), args.password)
        print(f"测试数据生成完成：{Config.DATABASE}")
        print(f"测试账号总数：{args.users}；统一密码：{args.password}")
        print(f"明细报告：{report_path}")
        for table, count in counts.items():
            print(f"  {table}: {count}")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
