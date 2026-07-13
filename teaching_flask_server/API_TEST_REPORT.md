# 教学过程管理系统全接口测试报告

> 生成时间：2026-07-13T10:59:33+08:00

## 1. 测试结论

- Flask 路由总数：**78**
- 成功路径覆盖：**78/78**
- 测试用例总数：**99**
- 通过：**99**
- 失败：**0**
- 原始数据库未被修改：**是**
- 总体结果：**全部接口成功路径均可用**

## 2. 测试方法

1. 复制 `data/teaching.db` 到系统临时目录，所有创建、更新、审批、取消和密码操作只作用于副本。
2. 对数据库副本执行 `migrate()`，确认迁移脚本可重复执行。
3. 使用 Flask 官方 `test_client()` 发起请求，完整经过路由匹配、Token 校验、角色校验、Blueprint 业务逻辑、事务和 SQLite 约束。
4. 通过管理员接口动态创建独立的院系、班级、教室、学期、教师、学生、课程和排课，避免依赖已有业务记录的状态。
5. 对教室预约、请假和调课分别创建三条记录，覆盖审批通过、驳回和申请人取消。
6. 根据 Flask 的 `url_map` 自动统计路由清单，并将成功响应映射回对应路由，检查是否存在遗漏。
7. 测试前后计算原始数据库 SHA-256，确认正式数据库未被测试写操作污染。

### 判定标准

- 成功接口必须同时满足预期 HTTP 状态码和响应 `code = 0`。
- 负向用例必须返回预期的 HTTP 状态码和业务错误码。
- 动态创建接口通常预期 HTTP 201，其余成功接口通常预期 HTTP 200。
- 每个 Flask 业务路由至少有一次成功路径调用，才计入路由覆盖。

### 测试边界

本次属于进程内集成测试，可以验证 Flask 路由、认证授权、业务逻辑、事务和 SQLite 数据约束。它不覆盖真实 WSGI 服务器、操作系统端口、防火墙、反向代理、浏览器网络环境、并发压力和长时间运行稳定性。

## 3. 测试环境

- Python：`3.13.6`
- Flask：`3.1.2`
- 数据库：SQLite 副本
- 调用方式：Flask `test_client()`
- 原始数据库 SHA-256（测试前）：`6350ed7239ce2d1ee9027e46552c284b194f74051afea3d40fe0f6bc5a52dfa0`
- 原始数据库 SHA-256（测试后）：`6350ed7239ce2d1ee9027e46552c284b194f74051afea3d40fe0f6bc5a52dfa0`

## 4. 逐项测试结果

| 序号 | 测试项 | 方法 | 路径 | 身份 | 预期 | 实际 | 结果 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 健康检查 | `GET` | `/api/health` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 同时检查统一JSON响应 |
| 2 | 登录：test_admin_01 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 ADMIN 账号登录 |
| 3 | 登录：test_staff_001 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 ACADEMIC_STAFF 账号登录 |
| 4 | 创建院系 | `POST` | `/api/admin/departments` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 院系创建成功 |
| 5 | 修改院系 | `PUT` | `/api/admin/departments/9` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 院系更新成功 |
| 6 | 创建班级 | `POST` | `/api/admin/classes` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 班级创建成功 |
| 7 | 修改班级 | `PUT` | `/api/admin/classes/61` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 班级更新成功 |
| 8 | 创建教室1 | `POST` | `/api/admin/classrooms` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 教室创建成功 |
| 9 | 创建教室2 | `POST` | `/api/admin/classrooms` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 教室创建成功 |
| 10 | 修改教室 | `PUT` | `/api/admin/classrooms/101` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 教室更新成功 |
| 11 | 创建学期 | `POST` | `/api/admin/semesters` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 学期创建成功 |
| 12 | 修改学期 | `PUT` | `/api/admin/semesters/5` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 学期更新成功 |
| 13 | 创建TEACHER用户：qa_teacher_105927 | `POST` | `/api/admin/users` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 账号创建成功 |
| 14 | 创建STUDENT用户：qa_student_105927 | `POST` | `/api/admin/users` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 账号创建成功 |
| 15 | 创建STUDENT用户：qa_auth_105927 | `POST` | `/api/admin/users` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 账号创建成功 |
| 16 | 创建STUDENT用户：qa_manage_105927 | `POST` | `/api/admin/users` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 账号创建成功 |
| 17 | 分页查询用户 | `GET` | `/api/admin/users?role=STUDENT&departmentId=9&page=1&pageSize=20` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 18 | 查询用户详情 | `GET` | `/api/admin/users/2002` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 19 | 修改用户资料 | `PUT` | `/api/admin/users/2002` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 用户资料更新成功 |
| 20 | 重置用户密码 | `POST` | `/api/admin/users/2004/reset-password` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 密码已重置，原Token已失效 |
| 21 | 登录：qa_manage_105927 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 STUDENT 账号登录 |
| 22 | 停用用户 | `POST` | `/api/admin/users/2004/status` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 账号状态已更新 |
| 23 | 停用账号拒绝登录 | `POST` | `/api/auth/login` | PUBLIC | HTTP 403, code=40302 | HTTP 403, code=40302 | 通过 | 负向测试，不计入成功路由覆盖 |
| 24 | 登录：qa_teacher_105927 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 TEACHER 账号登录 |
| 25 | 登录：qa_student_105927 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 STUDENT 账号登录 |
| 26 | 登录：qa_auth_105927 | `POST` | `/api/auth/login` | PUBLIC | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 验证 STUDENT 账号登录 |
| 27 | 获取当前登录用户 | `GET` | `/api/auth/me` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 28 | 获取个人资料 | `GET` | `/api/profile/me` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 29 | 修改个人资料 | `PUT` | `/api/profile/me` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 个人资料更新成功 |
| 30 | 获取角色首页统计 | `GET` | `/api/home` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 31 | 修改本人密码 | `PUT` | `/api/auth/password` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 密码修改成功 |
| 32 | 退出登录 | `POST` | `/api/auth/logout` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 退出成功 |
| 33 | 退出后Token失效 | `GET` | `/api/auth/me` | STUDENT | HTTP 401, code=40102 | HTTP 401, code=40102 | 通过 | 负向测试，不计入成功路由覆盖 |
| 34 | 未登录访问受保护接口 | `GET` | `/api/profile/me` | PUBLIC | HTTP 401, code=40101 | HTTP 401, code=40101 | 通过 | 负向测试，不计入成功路由覆盖 |
| 35 | 学生访问管理员接口 | `GET` | `/api/admin/users` | STUDENT | HTTP 403, code=40301 | HTTP 403, code=40301 | 通过 | 负向测试，不计入成功路由覆盖 |
| 36 | 创建课程 | `POST` | `/api/admin/courses` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 课程创建成功 |
| 37 | 修改课程 | `PUT` | `/api/admin/courses/241` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 课程更新成功 |
| 38 | 更新课程状态 | `POST` | `/api/admin/courses/241/status` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 课程状态已更新 |
| 39 | 创建排课 | `POST` | `/api/admin/schedules` | ADMIN | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 排课创建成功 |
| 40 | 修改排课 | `PUT` | `/api/admin/schedules/241` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 排课更新成功 |
| 41 | 查询课程列表 | `GET` | `/api/courses?keyword=接口自动化&page=1&pageSize=10` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 42 | 查询课程详情 | `GET` | `/api/courses/241` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 43 | 查询课程基础排课 | `GET` | `/api/courses/241/schedules` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 44 | 查询教师授课课程 | `GET` | `/api/teaching/courses` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 45 | 查询教师基础排课 | `GET` | `/api/teaching/schedules?semester=2030-QA-105927` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 46 | 查询院系 | `GET` | `/api/departments` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 47 | 查询班级 | `GET` | `/api/classes?departmentId=9` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 48 | 查询学期 | `GET` | `/api/semesters` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 49 | 查询教室列表 | `GET` | `/api/classrooms?status=AVAILABLE&campus=测试校区&minCapacity=20` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 50 | 查询教室详情 | `GET` | `/api/classrooms/101` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 51 | 查询空闲教室 | `GET` | `/api/classrooms/available?date=2028-03-01&startSection=1&endSection=2&participantCount=10` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 52 | 学生选课 | `POST` | `/api/courses/241/enroll` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 选课成功 |
| 53 | 查询本人选课 | `GET` | `/api/enrollments/my?status=SELECTED` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 54 | 教师查询课程学生 | `GET` | `/api/teaching/courses/241/students` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 55 | 查询本人有效课表 | `GET` | `/api/timetable/my?date=2030-09-02` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 56 | 发布通知 | `POST` | `/api/notifications` | TEACHER | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 通知发布成功 |
| 57 | 查询收到的通知 | `GET` | `/api/notifications?page=1&pageSize=20&unread=true` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 58 | 查询未读通知数 | `GET` | `/api/notifications/unread-count` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 59 | 查询通知详情 | `GET` | `/api/notifications/121` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 60 | 标记通知已读 | `POST` | `/api/notifications/121/read` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 已标记为已读 |
| 61 | 查询本人发布通知 | `GET` | `/api/notifications/published/my` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 62 | 管理全部通知 | `GET` | `/api/notifications/manage` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 63 | 撤回通知 | `POST` | `/api/notifications/121/withdraw` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 通知撤回成功 |
| 64 | 提交教室预约1 | `POST` | `/api/bookings` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 申请提交成功 |
| 65 | 提交教室预约2 | `POST` | `/api/bookings` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 申请提交成功 |
| 66 | 提交教室预约3 | `POST` | `/api/bookings` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 申请提交成功 |
| 67 | 查询本人教室预约 | `GET` | `/api/bookings/my?status=PENDING` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 68 | 查询预约详情 | `GET` | `/api/bookings/501` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 69 | 查询预约日志 | `GET` | `/api/bookings/501/logs` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 70 | 查询待审批预约 | `GET` | `/api/bookings/pending?applicantRole=STUDENT` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 71 | 审批通过预约 | `POST` | `/api/bookings/501/approve` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 审批通过 |
| 72 | 驳回预约 | `POST` | `/api/bookings/502/reject` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 已驳回 |
| 73 | 取消预约 | `POST` | `/api/bookings/503/cancel` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 申请已取消 |
| 74 | 批量结束过期预约 | `POST` | `/api/bookings/finish-expired` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 过期预约处理完成 |
| 75 | 提交请假1 | `POST` | `/api/leaves` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 请假申请提交成功 |
| 76 | 提交请假2 | `POST` | `/api/leaves` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 请假申请提交成功 |
| 77 | 提交请假3 | `POST` | `/api/leaves` | STUDENT | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 请假申请提交成功 |
| 78 | 查询本人请假 | `GET` | `/api/leaves/my?status=PENDING` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 79 | 查询请假详情 | `GET` | `/api/leaves/601` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 80 | 教师查询相关请假 | `GET` | `/api/leaves/teaching?courseId=241&status=PENDING` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 81 | 查询待审批请假 | `GET` | `/api/leaves/pending` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 82 | 审批通过请假 | `POST` | `/api/leaves/601/approve` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 审批通过 |
| 83 | 驳回请假 | `POST` | `/api/leaves/602/reject` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 已驳回 |
| 84 | 取消请假 | `POST` | `/api/leaves/603/cancel` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 请假申请已取消 |
| 85 | 提交调课1 | `POST` | `/api/schedule-changes` | TEACHER | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 调课申请提交成功 |
| 86 | 提交调课2 | `POST` | `/api/schedule-changes` | TEACHER | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 调课申请提交成功 |
| 87 | 提交调课3 | `POST` | `/api/schedule-changes` | TEACHER | HTTP 201, code=0 | HTTP 201, code=0 | 通过 | 调课申请提交成功 |
| 88 | 查询本人调课 | `GET` | `/api/schedule-changes/my?status=PENDING` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 89 | 查询调课详情 | `GET` | `/api/schedule-changes/181` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 90 | 检查调课冲突 | `GET` | `/api/schedule-changes/181/conflicts` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 91 | 查询待审批调课 | `GET` | `/api/schedule-changes/pending` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 92 | 审批通过调课 | `POST` | `/api/schedule-changes/181/approve` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 审批通过 |
| 93 | 驳回调课 | `POST` | `/api/schedule-changes/182/reject` | ACADEMIC_STAFF | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 已驳回 |
| 94 | 取消调课 | `POST` | `/api/schedule-changes/183/cancel` | TEACHER | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 调课申请已取消 |
| 95 | 查询审批历史 | `GET` | `/api/admin/approvals?businessType=SCHEDULE_CHANGE` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | success |
| 96 | 学生退课 | `POST` | `/api/courses/241/drop` | STUDENT | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 退课成功 |
| 97 | 取消基础排课 | `POST` | `/api/admin/schedules/241/cancel` | ADMIN | HTTP 200, code=0 | HTTP 200, code=0 | 通过 | 排课已取消 |
| 98 | CORS响应头 | `GET` | `/api/health` | PUBLIC | 包含Origin/Headers/Methods | 符合 | 通过 | 额外检查 |
| 99 | SQLite完整性检查 | `SQL` | `PRAGMA integrity_check` | TEST | ok | ok | 通过 | 额外检查 |

## 5. 路由覆盖核对

成功路径覆盖率：**78/78（100.0%）**。

Flask `url_map` 中的全部业务路由均至少获得了一次符合预期的成功响应。

## 6. 失败项与问题

本轮测试没有发现接口成功路径失败。

## 7. 额外安全性检查

本轮还验证了以下负向行为：

- 未携带 Token 访问受保护接口时返回 401；
- 学生访问管理员接口时返回 403；
- 已退出登录的 Token 不能继续使用；
- 已停用账号不能登录；
- 管理员重置密码后可以使用新密码登录；
- 所有响应均带有项目当前配置的 CORS 响应头。

## 8. 复现方法

在项目根目录执行：

```powershell
python test_all_api.py
```

脚本会自动创建临时数据库副本、运行测试、生成本报告并删除临时数据库。不会修改正式数据库。
