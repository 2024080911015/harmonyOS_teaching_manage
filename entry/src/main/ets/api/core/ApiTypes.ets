/**
 * 教学过程管理系统 API 公共类型
 *
 * 本文件只保存：
 * 1. 所有接口共用的响应结构
 * 2. 分页结构
 * 3. 查询参数类型
 * 4. 全项目统一使用的枚举
 *
 * 具体业务数据类型放在 model 目录中。
 */

/* =========================================================
 * 一、基础公共类型
 * =========================================================
 */

/**
 * 后端统一响应格式。
 *
 * 成功示例：
 * {
 *   "code": 0,
 *   "message": "success",
 *   "data": {}
 * }
 *
 * 失败示例：
 * {
 *   "code": 40001,
 *   "message": "参数错误",
 *   "data": null
 * }
 */
export interface ApiResponse<T> {
  code: number
  message: string
  data: T | null
}

/**
 * 后端分页返回格式。
 *
 * 注意：当前 Flask 服务端返回的是 items，
 * 不能写成 list。
 */
export interface PageResult<T> {
  items: Array<T>
  total: number
  page: number
  pageSize: number
}

/**
 * 没有返回业务数据的接口使用该类型。
 *
 * 例如：
 * POST /auth/logout
 * POST /courses/{id}/enroll
 */
export type NoData = null

/**
 * 日期字符串。
 *
 * 格式：
 * YYYY-MM-DD
 *
 * 例如：
 * 2026-09-10
 */
export type DateString = string

/**
 * 日期时间字符串。
 *
 * 格式：
 * YYYY-MM-DD HH:mm:ss
 *
 * 例如：
 * 2026-09-10 08:30:00
 */
export type DateTimeString = string

/**
 * URL 查询参数允许使用的值。
 */
export type QueryValue =
  string |
  number |
  boolean |
  null |
  undefined

/**
 * 通用 URL 查询参数。
 *
 * ArkTS 不支持把对象字面量赋给 Record 等动态对象类型，
 * 因此这里用显式声明的类封装 Map。
 */
export class QueryParams {
  private values: Map<string, QueryValue> =
    new Map<string, QueryValue>()

  set(key: string, value: QueryValue): QueryParams {
    if (value !== null && value !== undefined) {
      this.values.set(key, value)
    }
    return this
  }

  forEach(
    callback: (value: QueryValue, key: string) => void
  ): void {
    this.values.forEach(
      (value: QueryValue, key: string) => {
        callback(value, key)
      }
    )
  }
}

/**
 * 通用分页查询参数。
 *
 * 具体模块可以在自己的 Model 中扩展。
 */
export interface PageQuery {
  page?: number
  pageSize?: number
}


/* =========================================================
 * 二、用户相关枚举
 * =========================================================
 */

/**
 * 用户角色。
 */
export enum UserRole {
  STUDENT = 'STUDENT',
  TEACHER = 'TEACHER',
  ACADEMIC_STAFF = 'ACADEMIC_STAFF',
  ADMIN = 'ADMIN'
}

/**
 * 通用启用状态。
 *
 * 用于：
 * - 用户
 * - 院系
 * - 班级
 * - 课程
 * - 学期
 */
export enum EnabledStatus {
  DISABLED = 0,
  ENABLED = 1
}

/**
 * 性别。
 */
export enum Gender {
  UNKNOWN = 0,
  MALE = 1,
  FEMALE = 2
}

/**
 * 学生学籍状态。
 */
export enum AcademicStatus {
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
  GRADUATED = 'GRADUATED',
  WITHDRAWN = 'WITHDRAWN'
}


/* =========================================================
 * 三、课程和排课枚举
 * =========================================================
 */

/**
 * 课程选课开放状态。
 */
export enum CourseSelectionStatus {
  OPEN = 'OPEN',
  CLOSED = 'CLOSED'
}

/**
 * 排课状态。
 */
export enum ScheduleStatus {
  ACTIVE = 'ACTIVE',
  CANCELLED = 'CANCELLED'
}

/**
 * 课程单双周类型。
 */
export enum WeekType {
  ALL = 'ALL',
  ODD = 'ODD',
  EVEN = 'EVEN'
}

/**
 * 学生选课状态。
 */
export enum EnrollmentStatus {
  SELECTED = 'SELECTED',
  DROPPED = 'DROPPED'
}


/* =========================================================
 * 四、教室相关枚举
 * =========================================================
 */

/**
 * 教室类型。
 */
export enum RoomType {
  NORMAL = 'NORMAL',
  MULTIMEDIA = 'MULTIMEDIA',
  COMPUTER = 'COMPUTER',
  LABORATORY = 'LABORATORY'
}

/**
 * 教室管理状态。
 *
 * AVAILABLE 只表示教室本身正常，
 * 不代表指定时间一定空闲。
 */
export enum ClassroomStatus {
  AVAILABLE = 'AVAILABLE',
  MAINTENANCE = 'MAINTENANCE',
  DISABLED = 'DISABLED'
}

/**
 * 教室申请状态。
 */
export enum BookingStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
  FINISHED = 'FINISHED'
}

/**
 * 教室申请日志动作。
 */
export enum BookingLogAction {
  SUBMIT = 'SUBMIT',
  UPDATE = 'UPDATE',
  APPROVE = 'APPROVE',
  REJECT = 'REJECT',
  CANCEL = 'CANCEL',
  FINISH = 'FINISH'
}


/* =========================================================
 * 五、请假相关枚举
 * =========================================================
 */

/**
 * 请假类型。
 */
export enum LeaveType {
  SICK = 'SICK',
  PERSONAL = 'PERSONAL',
  OTHER = 'OTHER'
}

/**
 * 请假申请状态。
 */
export enum LeaveStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED'
}


/* =========================================================
 * 六、调课相关枚举
 * =========================================================
 */

/**
 * 调课类型。
 */
export enum ScheduleChangeType {
  TIME = 'TIME',
  ROOM = 'ROOM',
  BOTH = 'BOTH'
}

/**
 * 调课申请状态。
 */
export enum ScheduleChangeStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED'
}

/**
 * 调课冲突类型。
 */
export enum ConflictType {
  TEACHER = 'TEACHER',
  CLASSROOM = 'CLASSROOM'
}


/* =========================================================
 * 七、通知相关枚举
 * =========================================================
 */

/**
 * 通知接收范围。
 */
export enum NotificationAudienceType {
  ALL_STUDENTS = 'ALL_STUDENTS',
  CLASS = 'CLASS',
  DEPARTMENT = 'DEPARTMENT',
  USER = 'USER'
}

/**
 * 通知状态。
 */
export enum NotificationStatus {
  PUBLISHED = 'PUBLISHED',
  WITHDRAWN = 'WITHDRAWN'
}


/* =========================================================
 * 八、审批相关枚举
 * =========================================================
 */

/**
 * 审批业务类型。
 */
export enum ApprovalBusinessType {
  ROOM_BOOKING = 'ROOM_BOOKING',
  LEAVE_REQUEST = 'LEAVE_REQUEST',
  SCHEDULE_CHANGE = 'SCHEDULE_CHANGE'
}

/**
 * 审批动作。
 */
export enum ApprovalAction {
  APPROVE = 'APPROVE',
  REJECT = 'REJECT'
}


/* =========================================================
 * 九、通用数字标记
 * =========================================================
 */

/**
 * 数据库中的 0 / 1 标记。
 *
 * 可用于：
 * - isRead
 * - revoked
 */
export enum BinaryFlag {
  NO = 0,
  YES = 1
}
