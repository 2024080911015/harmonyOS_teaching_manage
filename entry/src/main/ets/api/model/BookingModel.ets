import {
  BookingLogAction,
  BookingStatus,
  DateString,
  DateTimeString,
  UserRole
} from '../core/ApiTypes'

/** 提交教室申请。 */
export interface CreateBookingRequest {
  classroomId: number
  bookingDate: DateString
  startSection: number
  endSection: number
  purpose: string
  participantCount: number
}

export interface CreateBookingResult {
  bookingId: number
  bookingNo: string
}

/** 本人申请列表查询条件。 */
export interface BookingQuery {
  status?: BookingStatus
}

/** 待审批申请查询条件。 */
export interface PendingBookingQuery {
  applicantRole?: UserRole
}

/** 教室申请详情或列表项。 */
export interface BookingInfo {
  id: number
  bookingNo: string
  applicantId: number
  applicantName: string
  applicantRole: UserRole
  classroomId: number
  classroomCode: string
  classroomName: string
  campus: string
  building: string
  bookingDate: DateString
  startSection: number
  endSection: number
  purpose: string
  participantCount: number
  status: BookingStatus
  reviewerId: number | null
  reviewerName: string | null
  reviewComment: string | null
  reviewedAt: DateTimeString | null
  cancelReason?: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 取消申请请求。 */
export interface CancelBookingRequest {
  reason?: string
}

/** 审批请求。 */
export interface BookingReviewRequest {
  comment?: string
}

/** 教室申请操作日志。 */
export interface BookingLogInfo {
  id: number
  bookingId: number
  operatorId: number | null
  action: BookingLogAction
  oldStatus: BookingStatus | null
  newStatus: BookingStatus | null
  remark: string | null
  createdAt: DateTimeString
  operatorName: string | null
  operatorRole: UserRole | null
}

/** 批量结束过期预约的结果。 */
export interface FinishExpiredBookingResult {
  finishedCount: number
}
