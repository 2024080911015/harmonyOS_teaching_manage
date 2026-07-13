# 教学过程管理系统 Flask 接口文档

所有账号由教务/管理员预先创建，不提供公开注册接口。

## 通用约定

- Base URL: `/api`
- 认证: `Authorization: Bearer <token>`
- 成功: `{"code":0,"message":"success","data":...}`

## 认证与个人中心

### POST `/api/auth/login`
- 权限: 公开
- 作用: 账号密码登录，返回Token、用户ID、姓名和角色。
- 请求: JSON：account，password
- 返回: 登录信息与Token
- 规则: 账号停用、密码错误均拒绝；Token默认有效7天。

### GET `/api/auth/me`
- 权限: 已登录
- 作用: 获取当前Token对应的账号基本信息。
- 请求: 无
- 返回: 当前用户信息
- 规则: Token过期、撤销或账号停用时返回401。

### POST `/api/auth/logout`
- 权限: 已登录
- 作用: 撤销当前Token。
- 请求: 无
- 返回: 无
- 规则: 退出后当前Token立即失效。

### PUT `/api/auth/password`
- 权限: 已登录
- 作用: 修改当前用户密码。
- 请求: JSON：oldPassword，newPassword，confirmPassword
- 返回: 无
- 规则: 新密码6-64位；修改后撤销同一用户的其他Token。

### GET `/api/profile/me`
- 权限: 已登录
- 作用: 获取公共资料和角色专属资料。
- 请求: 无
- 返回: 用户、院系、班级及roleProfile
- 规则: 学生读取student_profile；教师读取teacher_profile；教务/管理员读取academic_staff_profile。

### PUT `/api/profile/me`
- 权限: 已登录
- 作用: 修改本人可编辑资料。
- 请求: JSON：gender，phone，email，avatarUrl；教师可附professionalTitle、introduction
- 返回: 更新后的资料
- 规则: 学籍状态、学分、审批等级等敏感字段不能由本人修改。

### GET `/api/home`
- 权限: 已登录
- 作用: 返回角色主页所需的资料和待办统计。
- 请求: 无
- 返回: profile、role、summary
- 规则: 学生、教师、教务返回不同统计字段。

## 基础数据与课表

### GET `/api/departments`
- 权限: 已登录
- 作用: 查询启用院系。
- 请求: 无
- 返回: 院系列表
- 规则: 用于人员、课程和通知范围选择。

### GET `/api/classes`
- 权限: 已登录
- 作用: 查询启用班级。
- 请求: Query：departmentId可选
- 返回: 班级列表
- 规则: 按年级和班级名称排序。

### GET `/api/semesters`
- 权限: 已登录
- 作用: 查询启用学期及起止日期。
- 请求: 无
- 返回: 学期列表
- 规则: 学期日期用于将实际日期换算为教学周。

### GET `/api/classrooms`
- 权限: 已登录
- 作用: 查询教室基础信息。
- 请求: Query：status、campus、roomType、minCapacity
- 返回: 教室列表
- 规则: AVAILABLE仅表示教室本身正常，不等于指定时段空闲。

### GET `/api/classrooms/{id}`
- 权限: 已登录
- 作用: 查询单个教室详情。
- 请求: Path：id
- 返回: 教室详情
- 规则: 不存在返回404。

### GET `/api/classrooms/available`
- 权限: 已登录
- 作用: 查询指定日期与节次的空闲教室。
- 请求: Query：date、startSection、endSection、participantCount
- 返回: 可用教室列表
- 规则: 同时排除课程占用、调课后的有效占用和待审批/已通过预约。

### GET `/api/timetable/my`
- 权限: 已登录
- 作用: 按日期查询本人有效课表。
- 请求: Query：date
- 返回: 学期、教学周、有效排课
- 规则: 自动叠加已审批调课；学生仅返回已选课程，教师仅返回本人授课。

## 通知模块

### GET `/api/notifications`
- 权限: 已登录
- 作用: 查询本人收到的通知。
- 请求: Query：page、pageSize、unread可选
- 返回: 分页通知列表
- 规则: 只返回仍为PUBLISHED的通知。

### GET `/api/notifications/unread-count`
- 权限: 已登录
- 作用: 查询未读通知数量。
- 请求: 无
- 返回: count
- 规则: 主页角标使用。

### GET `/api/notifications/{id}`
- 权限: 已登录
- 作用: 查询通知详情。
- 请求: Path：id
- 返回: 通知、发布人和本人阅读状态
- 规则: 接收人、发布人或教务/管理员可查看。

### POST `/api/notifications/{id}/read`
- 权限: 已登录
- 作用: 标记通知已读。
- 请求: Path：id
- 返回: 无
- 规则: 只更新当前用户自己的接收记录。

### POST `/api/notifications`
- 权限: 教师/教务/管理员
- 作用: 发布通知并生成接收记录。
- 请求: JSON：title，content，audienceType，expiresAt；按范围附targetClassId/targetDepartmentId/targetUserId
- 返回: notificationId、recipientCount
- 规则: 范围支持ALL_STUDENTS、CLASS、DEPARTMENT、USER。

### GET `/api/notifications/published/my`
- 权限: 教师/教务/管理员
- 作用: 查询本人发布的通知及阅读统计。
- 请求: 无
- 返回: 通知列表、接收数、已读数
- 规则: 用于发布记录页面。

### GET `/api/notifications/manage`
- 权限: 教务/管理员
- 作用: 查询所有教师和教务发布的通知。
- 请求: 无
- 返回: 全部通知列表
- 规则: 用于教务撤回任意通知。

### POST `/api/notifications/{id}/withdraw`
- 权限: 教师/教务/管理员
- 作用: 撤回通知。
- 请求: Path：id
- 返回: 无
- 规则: 教师只能撤回本人且未到截止时间的通知；教务/管理员可撤回任意通知。

## 课程、选课与教师课程学生

### GET `/api/courses`
- 权限: 已登录
- 作用: 分页查询有效课程、容量、余量和基础排课。
- 请求: Query：page、pageSize、selectionStatus、departmentId、keyword
- 返回: 课程分页列表
- 规则: remainingCount=capacity-selectedCount。

### GET `/api/courses/{id}`
- 权限: 已登录
- 作用: 查询课程详情。
- 请求: Path：id
- 返回: 课程、教师、院系、排课；学生附myEnrollment
- 规则: 不存在返回404。

### GET `/api/courses/{id}/schedules`
- 权限: 已登录
- 作用: 查询课程基础排课。
- 请求: Path：id
- 返回: 排课列表
- 规则: 一次性调课请使用/timetable/my获取有效课表。

### GET `/api/enrollments/my`
- 权限: 学生
- 作用: 查询自己的选课和退课记录。
- 请求: Query：status可选
- 返回: 选课记录与排课
- 规则: status为SELECTED或DROPPED。

### POST `/api/courses/{id}/enroll`
- 权限: 学生
- 作用: 选择课程或恢复已退课程。
- 请求: Path：id
- 返回: 无
- 规则: 数据库与后端校验角色、开放时间、容量、单双周时间冲突。

### POST `/api/courses/{id}/drop`
- 权限: 学生
- 作用: 退选课程。
- 请求: Path：id
- 返回: 无
- 规则: 课程需处于开放状态；自动同步已选人数。

### GET `/api/teaching/courses`
- 权限: 教师
- 作用: 查询本人授课课程。
- 请求: 无
- 返回: 课程与基础排课列表
- 规则: 仅按course.teacher_id查询。

### GET `/api/teaching/courses/{id}/students`
- 权限: 教师
- 作用: 查询本人课程的当前选课学生。
- 请求: Path：id
- 返回: 学生学号、姓名、班级和选课状态
- 规则: 教师不能查看其他教师课程名单。

### GET `/api/teaching/schedules`
- 权限: 教师
- 作用: 查询本人基础排课。
- 请求: Query：semester可选
- 返回: 排课列表
- 规则: 调课后的指定日期有效课表使用/timetable/my。

## 教室申请与审批

### POST `/api/bookings`
- 权限: 学生/教师
- 作用: 提交教室使用申请。
- 请求: JSON：classroomId，bookingDate，startSection，endSection，purpose，participantCount
- 返回: bookingId、bookingNo
- 规则: 校验日期、教室状态、容量、课程占用和预约冲突；写入SUBMIT日志。

### GET `/api/bookings/my`
- 权限: 学生/教师
- 作用: 查询本人教室申请。
- 请求: Query：status可选
- 返回: 申请列表
- 规则: 包括审批状态和意见。

### GET `/api/bookings/{id}`
- 权限: 申请人/教务/管理员
- 作用: 查询申请详情。
- 请求: Path：id
- 返回: 申请人、教室和审批信息
- 规则: 普通用户只能看自己的申请。

### POST `/api/bookings/{id}/cancel`
- 权限: 申请人
- 作用: 取消待审批或未使用的已通过申请。
- 请求: JSON：reason可选
- 返回: 无
- 规则: 写入CANCEL日志。

### GET `/api/bookings/{id}/logs`
- 权限: 申请人/教务/管理员
- 作用: 查询教室申请操作日志。
- 请求: Path：id
- 返回: SUBMIT/APPROVE/REJECT/CANCEL/FINISH日志
- 规则: 满足个人主页“教室申请日志”。

### GET `/api/bookings/pending`
- 权限: 教务/管理员
- 作用: 查询待审批申请。
- 请求: Query：applicantRole可选
- 返回: 待审批列表
- 规则: 可筛选TEACHER或STUDENT。

### POST `/api/bookings/{id}/approve`
- 权限: 教务/管理员
- 作用: 审批通过教室申请。
- 请求: JSON：comment可选
- 返回: 无
- 规则: 审批时重新检查教室、课程和其他预约冲突；写审批记录和日志。

### POST `/api/bookings/{id}/reject`
- 权限: 教务/管理员
- 作用: 驳回教室申请。
- 请求: JSON：comment必填
- 返回: 无
- 规则: 写审批记录和REJECT日志。

### POST `/api/bookings/finish-expired`
- 权限: 教务/管理员
- 作用: 批量结束已过日期的APPROVED预约。
- 请求: 无
- 返回: finishedCount
- 规则: 更新为FINISHED并写日志。

## 学生请假

### POST `/api/leaves`
- 权限: 学生
- 作用: 提交请假申请并关联受影响课程。
- 请求: JSON：leaveType，startDate，endDate，startSection/endSection可选，reason，attachmentUrl可选，courseIds
- 返回: leaveId、leaveNo
- 规则: courseIds必须是本人当前已选课程。

### GET `/api/leaves/my`
- 权限: 学生
- 作用: 查询本人请假及历史。
- 请求: Query：status可选
- 返回: 请假及关联课程列表
- 规则: 不另建历史表，以状态区分。

### GET `/api/leaves/{id}`
- 权限: 学生本人/相关教师/教务/管理员
- 作用: 查询请假详情。
- 请求: Path：id
- 返回: 学生、课程和审批信息
- 规则: 教师只能查看与本人课程相关的请假。

### POST `/api/leaves/{id}/cancel`
- 权限: 学生本人
- 作用: 取消待审批请假。
- 请求: JSON：reason可选
- 返回: 无
- 规则: 仅PENDING可取消。

### GET `/api/leaves/teaching`
- 权限: 教师
- 作用: 查询与本人课程相关的学生请假。
- 请求: Query：courseId、status可选
- 返回: 请假列表
- 规则: 通过leave_request_course与course.teacher_id过滤。

### GET `/api/leaves/pending`
- 权限: 教务/管理员
- 作用: 查询待审批请假。
- 请求: 无
- 返回: 待审批列表
- 规则: 包含关联课程。

### POST `/api/leaves/{id}/approve`
- 权限: 教务/管理员
- 作用: 审批通过请假。
- 请求: JSON：comment可选
- 返回: 无
- 规则: 更新请假并写approval_record。

### POST `/api/leaves/{id}/reject`
- 权限: 教务/管理员
- 作用: 驳回请假。
- 请求: JSON：comment必填
- 返回: 无
- 规则: 更新请假并写approval_record。

## 教师调课

### POST `/api/schedule-changes`
- 权限: 教师
- 作用: 提交本人课程调课。
- 请求: JSON：scheduleId，changeType，reason；ROOM附newClassroomId；TIME附newWeek/newWeekDay/newStartSection/newEndSection；BOTH包含全部
- 返回: changeId、changeNo
- 规则: 提交时检查教师归属、教室状态、教师冲突、课程占用和预约冲突。

### GET `/api/schedule-changes/my`
- 权限: 教师
- 作用: 查询本人调课申请与记录。
- 请求: Query：status可选
- 返回: 调课列表
- 规则: PENDING/APPROVED/REJECTED/CANCELLED。

### GET `/api/schedule-changes/{id}`
- 权限: 申请教师/教务/管理员
- 作用: 查询调课详情。
- 请求: Path：id
- 返回: 原排课、新方案和审批信息
- 规则: 普通教师只能查看自己的。

### GET `/api/schedule-changes/{id}/conflicts`
- 权限: 申请教师/教务/管理员
- 作用: 重新检查调课方案冲突。
- 请求: Path：id
- 返回: hasConflict、conflicts
- 规则: 审批前必须再次检查。

### POST `/api/schedule-changes/{id}/cancel`
- 权限: 申请教师
- 作用: 取消待审批调课。
- 请求: JSON：reason可选
- 返回: 无
- 规则: 仅PENDING可取消。

### GET `/api/schedule-changes/pending`
- 权限: 教务/管理员
- 作用: 查询待审批调课。
- 请求: 无
- 返回: 待审批列表
- 规则: 用于教务端待办。

### POST `/api/schedule-changes/{id}/approve`
- 权限: 教务/管理员
- 作用: 审批通过调课。
- 请求: JSON：comment可选
- 返回: 无
- 规则: 审批通过后由有效课表计算叠加调课，不破坏原排课历史。

### POST `/api/schedule-changes/{id}/reject`
- 权限: 教务/管理员
- 作用: 驳回调课。
- 请求: JSON：comment必填
- 返回: 无
- 规则: 写审批记录。

## 教务/管理员：人员与基础数据

### GET `/api/admin/users`
- 权限: 教务/管理员
- 作用: 分页查询人员。
- 请求: Query：page、pageSize、role、status、departmentId、classId、keyword
- 返回: 人员分页列表
- 规则: 教务人员不能管理教务或管理员账号。

### POST `/api/admin/users`
- 权限: 教务/管理员
- 作用: 预先创建账号和角色资料。
- 请求: JSON：account，initialPassword，realName，role及角色专属字段
- 返回: 完整用户信息
- 规则: 所有账号由管理员预建；教务只能创建学生和教师，管理员可创建全部角色。

### GET `/api/admin/users/{id}`
- 权限: 教务/管理员
- 作用: 查询人员完整资料。
- 请求: Path：id
- 返回: 公共资料与roleProfile
- 规则: 密码摘要永不返回。

### PUT `/api/admin/users/{id}`
- 权限: 教务/管理员
- 作用: 修改人员、学籍、职称或教务资料。
- 请求: JSON：需要修改的字段
- 返回: 更新后用户资料
- 规则: 角色和账号原则上不通过此接口修改。

### POST `/api/admin/users/{id}/status`
- 权限: 教务/管理员
- 作用: 启用或停用账号。
- 请求: JSON：status(0/1)
- 返回: 无
- 规则: 停用时撤销全部Token；不能停用自己。

### POST `/api/admin/users/{id}/reset-password`
- 权限: 教务/管理员
- 作用: 重置用户密码。
- 请求: JSON：newPassword
- 返回: 无
- 规则: 重置后撤销该用户全部Token。

### POST `/api/admin/departments`
- 权限: 教务/管理员
- 作用: 新增院系。
- 请求: JSON：departmentCode，departmentName，managerName可选
- 返回: departmentId
- 规则: 代码唯一。

### PUT `/api/admin/departments/{id}`
- 权限: 教务/管理员
- 作用: 修改院系。
- 请求: JSON：院系字段
- 返回: 无
- 规则: 可修改status。

### POST `/api/admin/classes`
- 权限: 教务/管理员
- 作用: 新增班级。
- 请求: JSON：classCode，className，grade，majorName，departmentId等
- 返回: classId
- 规则: 代码唯一。

### PUT `/api/admin/classes/{id}`
- 权限: 教务/管理员
- 作用: 修改班级。
- 请求: JSON：班级字段
- 返回: 无
- 规则: 支持状态、人数和辅导员。

### POST `/api/admin/classrooms`
- 权限: 教务/管理员
- 作用: 新增教室。
- 请求: JSON：classroomCode，classroomName，campus，building，roomType，capacity等
- 返回: classroomId
- 规则: 教室代码唯一。

### PUT `/api/admin/classrooms/{id}`
- 权限: 教务/管理员
- 作用: 修改教室属性和状态。
- 请求: JSON：需要修改的字段
- 返回: 无
- 规则: 维修或停用教室不能被新申请使用。

## 教务/管理员：学期、课程与排课

### POST `/api/admin/semesters`
- 权限: 教务/管理员
- 作用: 新增学期。
- 请求: JSON：semesterCode，semesterName，startDate，endDate
- 返回: semesterId
- 规则: 学期代码唯一。

### PUT `/api/admin/semesters/{id}`
- 权限: 教务/管理员
- 作用: 修改学期。
- 请求: JSON：学期字段
- 返回: 无
- 规则: 日期用于课程占用校验。

### POST `/api/admin/courses`
- 权限: 教务/管理员
- 作用: 新增课程。
- 请求: JSON：courseCode，courseName，teacherId，departmentId，capacity，credit，selectionStart，selectionEnd，selectionStatus
- 返回: courseId
- 规则: 教师必须为正常TEACHER。

### PUT `/api/admin/courses/{id}`
- 权限: 教务/管理员
- 作用: 修改课程。
- 请求: JSON：课程字段
- 返回: 无
- 规则: 容量不得小于当前已选人数。

### POST `/api/admin/courses/{id}/status`
- 权限: 教务/管理员
- 作用: 修改课程启用及选课开放状态。
- 请求: JSON：status，selectionStatus可选
- 返回: 无
- 规则: 用于开放/关闭选课或停用课程。

### POST `/api/admin/schedules`
- 权限: 教务/管理员
- 作用: 新增课程排课。
- 请求: JSON：courseId，classroomId，semester，startWeek，endWeek，weekDay，startSection，endSection，weekType
- 返回: scheduleId
- 规则: 校验教师冲突、教室冲突、单双周和已有预约。

### PUT `/api/admin/schedules/{id}`
- 权限: 教务/管理员
- 作用: 修改排课。
- 请求: JSON：需要修改的排课字段
- 返回: 无
- 规则: 排除自身后重新检查冲突。

### POST `/api/admin/schedules/{id}/cancel`
- 权限: 教务/管理员
- 作用: 取消基础排课。
- 请求: Path：id
- 返回: 无
- 规则: 状态改为CANCELLED，保留记录。

### GET `/api/admin/approvals`
- 权限: 教务/管理员
- 作用: 查询审批历史。
- 请求: Query：businessType、approverId可选
- 返回: 审批记录列表
- 规则: 业务类型为ROOM_BOOKING、LEAVE_REQUEST、SCHEDULE_CHANGE。
