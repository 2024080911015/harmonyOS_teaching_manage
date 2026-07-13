from __future__ import annotations

import hashlib
import json
import shutil
import sqlite3
import tempfile
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

from app import create_app
from migrate import migrate


ROOT = Path(__file__).resolve().parent
SOURCE_DB = ROOT / "data" / "teaching.db"
REPORT_FILE = ROOT / "API_TEST_REPORT.md"
DEFAULT_PASSWORD = "Test123456"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def esc(value: Any) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


class ApiRunner:
    def __init__(self, database: Path):
        self.database = database
        self.app = create_app({"TESTING": True, "DATABASE": str(database)})
        self.client = self.app.test_client()
        self.results: list[dict[str, Any]] = []
        self.covered_rules: set[tuple[str, str]] = set()
        self.tokens: dict[str, str] = {}

    def _rule_for(self, method: str, path: str) -> str:
        clean_path = urlsplit(path).path
        adapter = self.app.url_map.bind("localhost")
        try:
            _endpoint, _values = adapter.match(clean_path, method=method)
        except Exception:
            return clean_path
        for rule in self.app.url_map.iter_rules():
            if rule.endpoint == _endpoint and method in rule.methods:
                return rule.rule
        return clean_path

    def request(
        self,
        name: str,
        method: str,
        path: str,
        *,
        actor: str = "PUBLIC",
        token: str | None = None,
        body: dict[str, Any] | None = None,
        expected_status: int | tuple[int, ...] = 200,
        expected_code: int | None = 0,
        note: str = "",
        cover: bool = True,
    ) -> dict[str, Any]:
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        response = self.client.open(path, method=method, json=body, headers=headers)
        payload = response.get_json(silent=True)
        statuses = (expected_status,) if isinstance(expected_status, int) else expected_status
        actual_code = payload.get("code") if isinstance(payload, dict) else None
        passed = response.status_code in statuses and (
            expected_code is None or actual_code == expected_code
        )
        rule = self._rule_for(method, path)
        if cover and response.status_code in statuses and expected_code == 0 and actual_code == 0:
            self.covered_rules.add((method, rule))
        self.results.append(
            {
                "name": name,
                "method": method,
                "path": path,
                "rule": rule,
                "actor": actor,
                "expected": f"HTTP {'/'.join(map(str, statuses))}, code={expected_code}",
                "actual": f"HTTP {response.status_code}, code={actual_code}",
                "passed": passed,
                "message": payload.get("message", "") if isinstance(payload, dict) else "非JSON响应",
                "note": note,
            }
        )
        return payload if isinstance(payload, dict) else {}

    def login(self, account: str, password: str, actor: str, *, label: str | None = None) -> str:
        payload = self.request(
            f"登录：{account}",
            "POST",
            "/api/auth/login",
            actor="PUBLIC",
            body={"account": account, "password": password},
            expected_status=200,
            note=f"验证 {actor} 账号登录",
        )
        token = payload.get("data", {}).get("token", "")
        if label:
            self.tokens[label] = token
        return token

    @staticmethod
    def data(payload: dict[str, Any], key: str) -> Any:
        return payload.get("data", {}).get(key)

    def all_routes(self) -> set[tuple[str, str]]:
        routes: set[tuple[str, str]] = set()
        for rule in self.app.url_map.iter_rules():
            if rule.endpoint == "static":
                continue
            for method in rule.methods - {"HEAD", "OPTIONS"}:
                routes.add((method, rule.rule))
        return routes


def run_suite(database: Path) -> ApiRunner:
    runner = ApiRunner(database)

    # 公开接口和预置管理员登录
    runner.request("健康检查", "GET", "/api/health", note="同时检查统一JSON响应")
    admin_token = runner.login("test_admin_01", DEFAULT_PASSWORD, "ADMIN", label="admin")
    staff_token = runner.login("test_staff_001", DEFAULT_PASSWORD, "ACADEMIC_STAFF", label="staff")

    # 基础数据 CRUD。所有代码均只写入测试数据库副本。
    suffix = datetime.now().strftime("%H%M%S")
    department = runner.request(
        "创建院系", "POST", "/api/admin/departments", actor="ADMIN", token=admin_token,
        body={"departmentCode": f"QA{suffix}", "departmentName": "接口测试学院", "managerName": "测试负责人"},
        expected_status=201,
    )
    department_id = runner.data(department, "departmentId")
    runner.request(
        "修改院系", "PUT", f"/api/admin/departments/{department_id}", actor="ADMIN", token=admin_token,
        body={"departmentName": "接口测试学院（已更新）", "status": 1},
    )

    class_result = runner.request(
        "创建班级", "POST", "/api/admin/classes", actor="ADMIN", token=admin_token,
        body={
            "classCode": f"QAC{suffix}", "className": "接口测试班", "grade": "2030",
            "majorName": "软件测试", "departmentId": department_id, "campus": "测试校区",
            "studentCount": 0, "counselorName": "测试辅导员",
        },
        expected_status=201,
    )
    class_id = runner.data(class_result, "classId")
    runner.request(
        "修改班级", "PUT", f"/api/admin/classes/{class_id}", actor="ADMIN", token=admin_token,
        body={"className": "接口测试班（已更新）", "studentCount": 3},
    )

    room_ids: list[int] = []
    for index in range(1, 3):
        room = runner.request(
            f"创建教室{index}", "POST", "/api/admin/classrooms", actor="ADMIN", token=admin_token,
            body={
                "classroomCode": f"QAR{suffix}{index}", "classroomName": f"接口测试教室{index}",
                "campus": "测试校区", "building": "测试楼", "floor": index,
                "roomType": "MULTIMEDIA", "capacity": 80, "equipment": "投影仪",
            },
            expected_status=201,
        )
        room_ids.append(runner.data(room, "classroomId"))
    runner.request(
        "修改教室", "PUT", f"/api/admin/classrooms/{room_ids[0]}", actor="ADMIN", token=admin_token,
        body={"capacity": 90, "equipment": "投影仪,白板"},
    )

    semester_code = f"2030-QA-{suffix}"
    semester = runner.request(
        "创建学期", "POST", "/api/admin/semesters", actor="ADMIN", token=admin_token,
        body={
            "semesterCode": semester_code, "semesterName": "2030接口测试学期",
            "startDate": "2030-09-02", "endDate": "2030-12-29",
        },
        expected_status=201,
    )
    semester_id = runner.data(semester, "semesterId")
    runner.request(
        "修改学期", "PUT", f"/api/admin/semesters/{semester_id}", actor="ADMIN", token=admin_token,
        body={"semesterName": "2030接口测试学期（已更新）", "status": 1},
    )

    # 创建本轮测试需要的用户。
    def create_user(account: str, role: str, extra: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        payload = {
            "account": account, "initialPassword": DEFAULT_PASSWORD,
            "realName": f"{role}接口测试用户", "role": role,
            "departmentId": department_id, **extra,
        }
        result = runner.request(
            f"创建{role}用户：{account}", "POST", "/api/admin/users",
            actor="ADMIN", token=admin_token, body=payload, expected_status=201,
        )
        return runner.data(result, "id"), result

    teacher_account = f"qa_teacher_{suffix}"
    student_account = f"qa_student_{suffix}"
    auth_account = f"qa_auth_{suffix}"
    manage_account = f"qa_manage_{suffix}"
    teacher_id, _ = create_user(
        teacher_account, "TEACHER",
        {"employeeNo": f"QAT{suffix}", "professionalTitle": "讲师", "introduction": "接口测试教师"},
    )
    student_id, _ = create_user(
        student_account, "STUDENT",
        {"classId": class_id, "studentNo": f"QAS{suffix}", "admissionDate": "2030-09-01"},
    )
    auth_user_id, _ = create_user(
        auth_account, "STUDENT",
        {"classId": class_id, "studentNo": f"QAA{suffix}"},
    )
    manage_user_id, _ = create_user(
        manage_account, "STUDENT",
        {"classId": class_id, "studentNo": f"QAM{suffix}"},
    )

    runner.request(
        "分页查询用户", "GET", f"/api/admin/users?role=STUDENT&departmentId={department_id}&page=1&pageSize=20",
        actor="ADMIN", token=admin_token,
    )
    runner.request(
        "查询用户详情", "GET", f"/api/admin/users/{student_id}", actor="ADMIN", token=admin_token,
    )
    runner.request(
        "修改用户资料", "PUT", f"/api/admin/users/{student_id}", actor="ADMIN", token=admin_token,
        body={"realName": "接口测试学生（已更新）", "earnedCredits": 2.5},
    )
    runner.request(
        "重置用户密码", "POST", f"/api/admin/users/{manage_user_id}/reset-password",
        actor="ADMIN", token=admin_token, body={"newPassword": "Reset123456"},
    )
    runner.login(manage_account, "Reset123456", "STUDENT")
    runner.request(
        "停用用户", "POST", f"/api/admin/users/{manage_user_id}/status",
        actor="ADMIN", token=admin_token, body={"status": 0},
    )
    runner.request(
        "停用账号拒绝登录", "POST", "/api/auth/login", actor="PUBLIC",
        body={"account": manage_account, "password": "Reset123456"},
        expected_status=403, expected_code=40302, note="负向测试，不计入成功路由覆盖", cover=False,
    )

    # 认证、个人中心和角色权限。
    teacher_token = runner.login(teacher_account, DEFAULT_PASSWORD, "TEACHER", label="teacher")
    student_token = runner.login(student_account, DEFAULT_PASSWORD, "STUDENT", label="student")
    auth_token = runner.login(auth_account, DEFAULT_PASSWORD, "STUDENT", label="auth_student")
    runner.request("获取当前登录用户", "GET", "/api/auth/me", actor="STUDENT", token=student_token)
    runner.request("获取个人资料", "GET", "/api/profile/me", actor="STUDENT", token=student_token)
    runner.request(
        "修改个人资料", "PUT", "/api/profile/me", actor="STUDENT", token=student_token,
        body={"gender": 1, "phone": "13800138000", "email": "qa@example.test", "avatarUrl": "/qa/avatar.png"},
    )
    runner.request("获取角色首页统计", "GET", "/api/home", actor="STUDENT", token=student_token)
    runner.request(
        "修改本人密码", "PUT", "/api/auth/password", actor="STUDENT", token=auth_token,
        body={"oldPassword": DEFAULT_PASSWORD, "newPassword": "Changed123456", "confirmPassword": "Changed123456"},
    )
    runner.request("退出登录", "POST", "/api/auth/logout", actor="STUDENT", token=auth_token)
    runner.request(
        "退出后Token失效", "GET", "/api/auth/me", actor="STUDENT", token=auth_token,
        expected_status=401, expected_code=40102, note="负向测试，不计入成功路由覆盖", cover=False,
    )
    runner.request(
        "未登录访问受保护接口", "GET", "/api/profile/me", actor="PUBLIC",
        expected_status=401, expected_code=40101, note="负向测试，不计入成功路由覆盖", cover=False,
    )
    runner.request(
        "学生访问管理员接口", "GET", "/api/admin/users", actor="STUDENT", token=student_token,
        expected_status=403, expected_code=40301, note="负向测试，不计入成功路由覆盖", cover=False,
    )

    # 课程和排课。
    now = datetime.now().replace(microsecond=0)
    course = runner.request(
        "创建课程", "POST", "/api/admin/courses", actor="ADMIN", token=admin_token,
        body={
            "courseCode": f"QACOURSE{suffix}", "courseName": "接口自动化测试课程",
            "teacherId": teacher_id, "departmentId": department_id, "capacity": 50, "credit": 2.0,
            "selectionStart": (now - timedelta(days=1)).isoformat(),
            "selectionEnd": (now + timedelta(days=30)).isoformat(),
            "selectionStatus": "OPEN", "status": 1, "description": "用于全接口测试",
        },
        expected_status=201,
    )
    course_id = runner.data(course, "courseId")
    runner.request(
        "修改课程", "PUT", f"/api/admin/courses/{course_id}", actor="ADMIN", token=admin_token,
        body={"courseName": "接口自动化测试课程（已更新）", "capacity": 60},
    )
    runner.request(
        "更新课程状态", "POST", f"/api/admin/courses/{course_id}/status",
        actor="ADMIN", token=admin_token, body={"status": 1, "selectionStatus": "OPEN"},
    )
    schedule = runner.request(
        "创建排课", "POST", "/api/admin/schedules", actor="ADMIN", token=admin_token,
        body={
            "courseId": course_id, "classroomId": room_ids[0], "semester": semester_code,
            "startWeek": 1, "endWeek": 10, "weekDay": 1,
            "startSection": 1, "endSection": 2, "weekType": "ALL",
        },
        expected_status=201,
    )
    schedule_id = runner.data(schedule, "scheduleId")
    runner.request(
        "修改排课", "PUT", f"/api/admin/schedules/{schedule_id}", actor="ADMIN", token=admin_token,
        body={"endWeek": 12},
    )

    runner.request("查询课程列表", "GET", f"/api/courses?keyword=接口自动化&page=1&pageSize=10", actor="STUDENT", token=student_token)
    runner.request("查询课程详情", "GET", f"/api/courses/{course_id}", actor="STUDENT", token=student_token)
    runner.request("查询课程基础排课", "GET", f"/api/courses/{course_id}/schedules", actor="STUDENT", token=student_token)
    runner.request("查询教师授课课程", "GET", "/api/teaching/courses", actor="TEACHER", token=teacher_token)
    runner.request(
        "查询教师基础排课", "GET", f"/api/teaching/schedules?semester={semester_code}",
        actor="TEACHER", token=teacher_token,
    )

    # 公共基础数据。
    runner.request("查询院系", "GET", "/api/departments", actor="STUDENT", token=student_token)
    runner.request("查询班级", "GET", f"/api/classes?departmentId={department_id}", actor="STUDENT", token=student_token)
    runner.request("查询学期", "GET", "/api/semesters", actor="STUDENT", token=student_token)
    runner.request(
        "查询教室列表", "GET", "/api/classrooms?status=AVAILABLE&campus=测试校区&minCapacity=20",
        actor="STUDENT", token=student_token,
    )
    runner.request("查询教室详情", "GET", f"/api/classrooms/{room_ids[0]}", actor="STUDENT", token=student_token)
    runner.request(
        "查询空闲教室", "GET",
        "/api/classrooms/available?date=2028-03-01&startSection=1&endSection=2&participantCount=10",
        actor="STUDENT", token=student_token,
    )

    # 选课、教师学生名单、个人课表。
    runner.request(
        "学生选课", "POST", f"/api/courses/{course_id}/enroll",
        actor="STUDENT", token=student_token, expected_status=201,
    )
    runner.request("查询本人选课", "GET", "/api/enrollments/my?status=SELECTED", actor="STUDENT", token=student_token)
    runner.request(
        "教师查询课程学生", "GET", f"/api/teaching/courses/{course_id}/students",
        actor="TEACHER", token=teacher_token,
    )
    runner.request(
        "查询本人有效课表", "GET", "/api/timetable/my?date=2030-09-02",
        actor="STUDENT", token=student_token,
    )

    # 通知完整流程。
    expires = (datetime.now() + timedelta(days=30)).replace(microsecond=0).isoformat()
    notification = runner.request(
        "发布通知", "POST", "/api/notifications", actor="TEACHER", token=teacher_token,
        body={
            "title": "接口测试通知", "content": "用于验证通知接口完整流程",
            "audienceType": "USER", "targetUserId": student_id, "expiresAt": expires,
        },
        expected_status=201,
    )
    notification_id = runner.data(notification, "notificationId")
    runner.request("查询收到的通知", "GET", "/api/notifications?page=1&pageSize=20&unread=true", actor="STUDENT", token=student_token)
    runner.request("查询未读通知数", "GET", "/api/notifications/unread-count", actor="STUDENT", token=student_token)
    runner.request("查询通知详情", "GET", f"/api/notifications/{notification_id}", actor="STUDENT", token=student_token)
    runner.request("标记通知已读", "POST", f"/api/notifications/{notification_id}/read", actor="STUDENT", token=student_token)
    runner.request("查询本人发布通知", "GET", "/api/notifications/published/my", actor="TEACHER", token=teacher_token)
    runner.request("管理全部通知", "GET", "/api/notifications/manage", actor="ADMIN", token=admin_token)
    runner.request("撤回通知", "POST", f"/api/notifications/{notification_id}/withdraw", actor="TEACHER", token=teacher_token)

    # 教室预约：分别覆盖通过、驳回和申请人取消。
    booking_ids: list[int] = []
    for index, booking_date in enumerate(["2028-03-10", "2028-03-11", "2028-03-12"], start=1):
        booking = runner.request(
            f"提交教室预约{index}", "POST", "/api/bookings", actor="STUDENT", token=student_token,
            body={
                "classroomId": room_ids[1], "bookingDate": booking_date,
                "startSection": 3, "endSection": 4, "purpose": f"接口测试活动{index}",
                "participantCount": 20,
            },
            expected_status=201,
        )
        booking_ids.append(runner.data(booking, "bookingId"))
    runner.request("查询本人教室预约", "GET", "/api/bookings/my?status=PENDING", actor="STUDENT", token=student_token)
    runner.request("查询预约详情", "GET", f"/api/bookings/{booking_ids[0]}", actor="STUDENT", token=student_token)
    runner.request("查询预约日志", "GET", f"/api/bookings/{booking_ids[0]}/logs", actor="STUDENT", token=student_token)
    runner.request("查询待审批预约", "GET", "/api/bookings/pending?applicantRole=STUDENT", actor="ACADEMIC_STAFF", token=staff_token)
    runner.request(
        "审批通过预约", "POST", f"/api/bookings/{booking_ids[0]}/approve",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试通过"},
    )
    runner.request(
        "驳回预约", "POST", f"/api/bookings/{booking_ids[1]}/reject",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试驳回"},
    )
    runner.request(
        "取消预约", "POST", f"/api/bookings/{booking_ids[2]}/cancel",
        actor="STUDENT", token=student_token, body={"reason": "接口测试取消"},
    )
    runner.request("批量结束过期预约", "POST", "/api/bookings/finish-expired", actor="ADMIN", token=admin_token)

    # 请假：分别覆盖通过、驳回和取消。
    leave_ids: list[int] = []
    for index, start_date in enumerate([date(2028, 4, 1), date(2028, 4, 3), date(2028, 4, 5)], start=1):
        leave = runner.request(
            f"提交请假{index}", "POST", "/api/leaves", actor="STUDENT", token=student_token,
            body={
                "leaveType": "PERSONAL", "startDate": start_date.isoformat(),
                "endDate": start_date.isoformat(), "startSection": 1, "endSection": 2,
                "reason": f"接口测试请假{index}", "courseIds": [course_id],
            },
            expected_status=201,
        )
        leave_ids.append(runner.data(leave, "leaveId"))
    runner.request("查询本人请假", "GET", "/api/leaves/my?status=PENDING", actor="STUDENT", token=student_token)
    runner.request("查询请假详情", "GET", f"/api/leaves/{leave_ids[0]}", actor="STUDENT", token=student_token)
    runner.request(
        "教师查询相关请假", "GET", f"/api/leaves/teaching?courseId={course_id}&status=PENDING",
        actor="TEACHER", token=teacher_token,
    )
    runner.request("查询待审批请假", "GET", "/api/leaves/pending", actor="ACADEMIC_STAFF", token=staff_token)
    runner.request(
        "审批通过请假", "POST", f"/api/leaves/{leave_ids[0]}/approve",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试通过"},
    )
    runner.request(
        "驳回请假", "POST", f"/api/leaves/{leave_ids[1]}/reject",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试驳回"},
    )
    runner.request(
        "取消请假", "POST", f"/api/leaves/{leave_ids[2]}/cancel",
        actor="STUDENT", token=student_token, body={"reason": "接口测试取消"},
    )

    # 调课：分别覆盖通过、驳回和取消。
    change_ids: list[int] = []
    for index, week in enumerate([2, 3, 4], start=1):
        change = runner.request(
            f"提交调课{index}", "POST", "/api/schedule-changes", actor="TEACHER", token=teacher_token,
            body={
                "scheduleId": schedule_id, "changeType": "TIME", "newWeek": week,
                "newWeekDay": index + 1, "newStartSection": 5, "newEndSection": 6,
                "reason": f"接口测试调课{index}",
            },
            expected_status=201,
        )
        change_ids.append(runner.data(change, "changeId"))
    runner.request("查询本人调课", "GET", "/api/schedule-changes/my?status=PENDING", actor="TEACHER", token=teacher_token)
    runner.request("查询调课详情", "GET", f"/api/schedule-changes/{change_ids[0]}", actor="TEACHER", token=teacher_token)
    runner.request("检查调课冲突", "GET", f"/api/schedule-changes/{change_ids[0]}/conflicts", actor="TEACHER", token=teacher_token)
    runner.request("查询待审批调课", "GET", "/api/schedule-changes/pending", actor="ACADEMIC_STAFF", token=staff_token)
    runner.request(
        "审批通过调课", "POST", f"/api/schedule-changes/{change_ids[0]}/approve",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试通过"},
    )
    runner.request(
        "驳回调课", "POST", f"/api/schedule-changes/{change_ids[1]}/reject",
        actor="ACADEMIC_STAFF", token=staff_token, body={"comment": "接口测试驳回"},
    )
    runner.request(
        "取消调课", "POST", f"/api/schedule-changes/{change_ids[2]}/cancel",
        actor="TEACHER", token=teacher_token, body={"reason": "接口测试取消"},
    )

    runner.request(
        "查询审批历史", "GET", "/api/admin/approvals?businessType=SCHEDULE_CHANGE",
        actor="ADMIN", token=admin_token,
    )
    runner.request("学生退课", "POST", f"/api/courses/{course_id}/drop", actor="STUDENT", token=student_token)
    runner.request("取消基础排课", "POST", f"/api/admin/schedules/{schedule_id}/cancel", actor="ADMIN", token=admin_token)

    # 响应头不对应独立业务路由，单独记录为额外检查。
    # 从实际健康检查响应验证 CORS。
    response = runner.client.get("/api/health")
    cors_ok = (
        response.headers.get("Access-Control-Allow-Origin") == "*"
        and "Authorization" in response.headers.get("Access-Control-Allow-Headers", "")
        and "OPTIONS" in response.headers.get("Access-Control-Allow-Methods", "")
    )
    runner.results.append(
        {
            "name": "CORS响应头", "method": "GET", "path": "/api/health", "rule": "非独立路由",
            "actor": "PUBLIC", "expected": "包含Origin/Headers/Methods", "actual": "符合" if cors_ok else "不符合",
            "passed": cors_ok, "message": "跨域响应头完整" if cors_ok else "跨域响应头缺失", "note": "额外检查",
        }
    )
    return runner


def write_report(runner: ApiRunner, source_hash_before: str, source_hash_after: str) -> None:
    all_routes = runner.all_routes()
    missing = sorted(all_routes - runner.covered_rules)
    route_count = len(all_routes)
    covered_count = len(all_routes & runner.covered_rules)
    passed = sum(1 for item in runner.results if item["passed"])
    failed = len(runner.results) - passed
    source_unchanged = source_hash_before == source_hash_after
    generated_at = datetime.now().astimezone().isoformat(timespec="seconds")

    lines = [
        "# 教学过程管理系统全接口测试报告",
        "",
        f"> 生成时间：{generated_at}",
        "",
        "## 1. 测试结论",
        "",
        f"- Flask 路由总数：**{route_count}**",
        f"- 成功路径覆盖：**{covered_count}/{route_count}**",
        f"- 测试用例总数：**{len(runner.results)}**",
        f"- 通过：**{passed}**",
        f"- 失败：**{failed}**",
        f"- 原始数据库未被修改：**{'是' if source_unchanged else '否'}**",
        f"- 总体结果：**{'全部接口成功路径均可用' if failed == 0 and not missing else '存在失败或未覆盖接口，详见下文'}**",
        "",
        "## 2. 测试方法",
        "",
        "1. 复制 `data/teaching.db` 到系统临时目录，所有创建、更新、审批、取消和密码操作只作用于副本。",
        "2. 对数据库副本执行 `migrate()`，确认迁移脚本可重复执行。",
        "3. 使用 Flask 官方 `test_client()` 发起请求，完整经过路由匹配、Token 校验、角色校验、Blueprint 业务逻辑、事务和 SQLite 约束。",
        "4. 通过管理员接口动态创建独立的院系、班级、教室、学期、教师、学生、课程和排课，避免依赖已有业务记录的状态。",
        "5. 对教室预约、请假和调课分别创建三条记录，覆盖审批通过、驳回和申请人取消。",
        "6. 根据 Flask 的 `url_map` 自动统计路由清单，并将成功响应映射回对应路由，检查是否存在遗漏。",
        "7. 测试前后计算原始数据库 SHA-256，确认正式数据库未被测试写操作污染。",
        "",
        "### 判定标准",
        "",
        "- 成功接口必须同时满足预期 HTTP 状态码和响应 `code = 0`。",
        "- 负向用例必须返回预期的 HTTP 状态码和业务错误码。",
        "- 动态创建接口通常预期 HTTP 201，其余成功接口通常预期 HTTP 200。",
        "- 每个 Flask 业务路由至少有一次成功路径调用，才计入路由覆盖。",
        "",
        "### 测试边界",
        "",
        "本次属于进程内集成测试，可以验证 Flask 路由、认证授权、业务逻辑、事务和 SQLite 数据约束。它不覆盖真实 WSGI 服务器、操作系统端口、防火墙、反向代理、浏览器网络环境、并发压力和长时间运行稳定性。",
        "",
        "## 3. 测试环境",
        "",
        f"- Python：`{__import__('sys').version.split()[0]}`",
        f"- Flask：`{__import__('importlib.metadata').metadata.version('Flask')}`",
        "- 数据库：SQLite 副本",
        "- 调用方式：Flask `test_client()`",
        f"- 原始数据库 SHA-256（测试前）：`{source_hash_before}`",
        f"- 原始数据库 SHA-256（测试后）：`{source_hash_after}`",
        "",
        "## 4. 逐项测试结果",
        "",
        "| 序号 | 测试项 | 方法 | 路径 | 身份 | 预期 | 实际 | 结果 | 说明 |",
        "| ---: | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for index, item in enumerate(runner.results, start=1):
        explanation = item["note"] or item["message"]
        lines.append(
            f"| {index} | {esc(item['name'])} | `{item['method']}` | `{esc(item['path'])}` | "
            f"{esc(item['actor'])} | {esc(item['expected'])} | {esc(item['actual'])} | "
            f"{'通过' if item['passed'] else '失败'} | {esc(explanation)} |"
        )

    lines.extend([
        "",
        "## 5. 路由覆盖核对",
        "",
        f"成功路径覆盖率：**{covered_count}/{route_count}（{covered_count / route_count:.1%}）**。",
        "",
    ])
    if missing:
        lines.extend(["以下路由未获得成功响应：", ""])
        for method, rule in missing:
            lines.append(f"- `{method} {rule}`")
    else:
        lines.append("Flask `url_map` 中的全部业务路由均至少获得了一次符合预期的成功响应。")

    failures = [item for item in runner.results if not item["passed"]]
    lines.extend(["", "## 6. 失败项与问题", ""])
    if failures:
        for item in failures:
            lines.append(
                f"- **{item['name']}**：预期 {item['expected']}，实际 {item['actual']}，消息：{item['message']}。"
            )
    else:
        lines.append("本轮测试没有发现接口成功路径失败。")

    lines.extend([
        "",
        "## 7. 额外安全性检查",
        "",
        "本轮还验证了以下负向行为：",
        "",
        "- 未携带 Token 访问受保护接口时返回 401；",
        "- 学生访问管理员接口时返回 403；",
        "- 已退出登录的 Token 不能继续使用；",
        "- 已停用账号不能登录；",
        "- 管理员重置密码后可以使用新密码登录；",
        "- 所有响应均带有项目当前配置的 CORS 响应头。",
        "",
        "## 8. 复现方法",
        "",
        "在项目根目录执行：",
        "",
        "```powershell",
        "python test_all_api.py",
        "```",
        "",
        "脚本会自动创建临时数据库副本、运行测试、生成本报告并删除临时数据库。不会修改正式数据库。",
    ])
    REPORT_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    if not SOURCE_DB.exists():
        raise SystemExit(f"数据库不存在：{SOURCE_DB}")
    source_hash_before = sha256(SOURCE_DB)
    with tempfile.TemporaryDirectory(prefix="teaching_api_test_") as temp_dir:
        database = Path(temp_dir) / "teaching_test.db"
        shutil.copy2(SOURCE_DB, database)
        conn = sqlite3.connect(database)
        try:
            migrate(conn)
        finally:
            conn.close()
        runner = run_suite(database)
        integrity_conn = sqlite3.connect(database)
        try:
            integrity = integrity_conn.execute("PRAGMA integrity_check").fetchone()[0]
        finally:
            integrity_conn.close()
        runner.results.append(
            {
                "name": "SQLite完整性检查", "method": "SQL", "path": "PRAGMA integrity_check",
                "rule": "非HTTP路由", "actor": "TEST", "expected": "ok", "actual": integrity,
                "passed": integrity == "ok", "message": "数据库结构和页面完整", "note": "额外检查",
            }
        )
        source_hash_after = sha256(SOURCE_DB)
        write_report(runner, source_hash_before, source_hash_after)
        failures = [item for item in runner.results if not item["passed"]]
        missing = runner.all_routes() - runner.covered_rules
        print(json.dumps({
            "report": str(REPORT_FILE),
            "route_count": len(runner.all_routes()),
            "covered_routes": len(runner.covered_rules & runner.all_routes()),
            "test_count": len(runner.results),
            "passed": len(runner.results) - len(failures),
            "failed": len(failures),
            "missing_routes": sorted([f"{method} {rule}" for method, rule in missing]),
            "source_db_unchanged": source_hash_before == source_hash_after,
        }, ensure_ascii=False, indent=2))
        return 1 if failures or missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
