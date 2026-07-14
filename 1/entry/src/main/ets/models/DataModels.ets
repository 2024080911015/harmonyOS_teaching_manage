// 用户角色枚举
export enum UserRole {
  STUDENT = 'student',        // 学生
  TEACHER = 'teacher',        // 老师
  ACADEMIC_AFFAIRS = 'academic_affairs',  // 教务处
  COLLEGE_LEADER = 'college_leader'       // 学院领导
}

// 用户信息
export interface User {
  id: string
  name: string
  role: UserRole
  department?: string  // 所属系/部门
  college?: string     // 所属学院
}

// 课程状态枚举
export enum CourseStatus {
  NORMAL = '正常上课',
  ADJUSTED = '已调课',
  SUSPENDED = '停课',
  MAKEUP = '补课'
}

// 预约状态枚举
export enum BookingStatus {
  PENDING_ACADEMIC = 'pending_academic',    // 待教务处审核
  PENDING_COLLEGE = 'pending_college',      // 待学院领导审核
  APPROVED = 'approved',                     // 已通过
  REJECTED = 'rejected',                     // 已拒绝
  CANCELLED = 'cancelled',                   // 已取消
  PENDING_CANCEL = 'pending_cancel',         // 待取消审批
  AUTO_APPROVED = 'auto_approved'            // 自动通过
}

// 周数范围
export interface WeekRange {
  startWeek: number  // 开始周
  endWeek: number    // 结束周
}

// 详细时间段
export interface DetailedSchedule {
  dayOfWeek: number      // 星期几（1-7）
  startLesson: number    // 开始节次
  endLesson: number      // 结束节次
  weekRange: WeekRange   // 周数范围
}

// 课程排课信息（用于调课管理）
export interface CourseSchedule {
  id: string
  courseId: string  // 关联的课程ID（AppModels.Course）
  name: string
  teacherId: string
  teacherName: string
  department: string   // 所属系
  college: string      // 所属学院
  hours: number        // 学时
  schedule: string     // 上课时间（简略描述）
  detailedSchedule?: DetailedSchedule[]  // 详细时间段
  classroom: string    // 教室
  credit: number       // 学分
  description?: string // 课程描述
  weekRange?: WeekRange  // 周数范围
  courseStatus: CourseStatus  // 课程状态
  originalCourseId?: string  // 如果是调课后的课程，记录原课程ID
}

// 调课申请状态
export enum AdjustmentStatus {
  PENDING_ACADEMIC = 'pending_academic',   // 待教务处审批
  PENDING_COLLEGE = 'pending_college',     // 待学院领导审批
  APPROVED = 'approved',                   // 已通过
  REJECTED = 'rejected',                   // 已拒绝
  AUTO_APPROVED = 'auto_approved',         // 自动通过（学时<8）
  PENDING_CANCEL = 'pending_cancel',       // 待取消审批（已审核通过的申请需要教务处审批才能取消）
  CANCELLED = 'cancelled'                  // 已取消
}

// 审批信息
export interface ApprovalInfo {
  approverId: string        // 审批人ID
  approverName: string      // 审批人姓名
  approvalTime: string      // 审批时间
  approvalComment?: string  // 审批意见
  isApproved: boolean       // 是否通过
}

// 审批类型
export enum ApprovalType {
  AUTO = 'auto',                        // 自动通过（学时<8）
  ACADEMIC_AFFAIRS = 'academic_affairs', // 教务处审批（8≤学时≤12）
  COLLEGE_LEADER = 'college_leader'      // 学院领导审批（学时>12）
}

// 调课申请
export interface CourseAdjustment {
  id: string
  courseId: string
  courseName: string
  teacherId: string
  teacherName: string
  department: string
  college: string
  originalSchedule: string      // 原上课时间
  newSchedule: string           // 新上课时间
  originalClassroom: string     // 原教室
  newClassroom: string          // 新教室
  hours: number                 // 调课学时
  reason: string                // 调课原因
  status: AdjustmentStatus
  approvalType: ApprovalType    // 审批类型
  createTime: string            // 申请时间
  updateTime: string            // 更新时间
  // 周数范围
  weekRange?: WeekRange
  // 新周数范围（调课后）
  newWeekRange?: WeekRange
  // 原详细时间段
  originalDetailedSchedule?: DetailedSchedule[]
  // 新详细时间段
  newDetailedSchedule?: DetailedSchedule[]
  // 教务处审批信息（学时≥8时需要）
  academicAffairsApproval?: ApprovalInfo
  // 学院领导审批信息（学时>12时需要）
  collegeLeaderApproval?: ApprovalInfo
  // 取消审批信息（已审核通过的申请需要教务处审批才能取消）
  cancelApproval?: ApprovalInfo
}

// 统计数据 - 各系调课量
export interface DepartmentStats {
  department: string
  totalAdjustments: number      // 总调课量
  pendingCount: number          // 待处理数
  approvedCount: number         // 已通过数
  rejectedCount: number         // 已拒绝数
}

// 统计数据 - 老师调课补完情况
export interface TeacherStats {
  teacherId: string
  teacherName: string
  department: string
  totalAdjustments: number      // 总调课申请数
  completedCount: number        // 已完成补课数
  pendingCount: number          // 待补课数
  completionRate: number        // 完成率（百分比）
}

// 审批权限判断
export function getApprovalType(hours: number): ApprovalType {
  if (hours < 8) {
    return ApprovalType.AUTO
  } else if (hours <= 12) {
    return ApprovalType.ACADEMIC_AFFAIRS
  } else {
    return ApprovalType.COLLEGE_LEADER
  }
}

// 角色显示名称
export function getRoleName(role: UserRole): string {
  switch (role) {
    case UserRole.STUDENT:
      return '学生'
    case UserRole.TEACHER:
      return '老师'
    case UserRole.ACADEMIC_AFFAIRS:
      return '教务处'
    case UserRole.COLLEGE_LEADER:
      return '学院领导'
    default:
      return '未知'
  }
}

// 状态显示名称
export function getStatusName(status: AdjustmentStatus): string {
  switch (status) {
    case AdjustmentStatus.PENDING_ACADEMIC:
      return '待教务处审批'
    case AdjustmentStatus.PENDING_COLLEGE:
      return '待学院领导审批'
    case AdjustmentStatus.APPROVED:
      return '已通过'
    case AdjustmentStatus.REJECTED:
      return '已拒绝'
    case AdjustmentStatus.AUTO_APPROVED:
      return '自动通过'
    default:
      return '未知'
  }
}
