import {
  DateString,
  DateTimeString,
  LeaveStatus,
  LeaveType
} from '../core/ApiTypes'

/** 提交请假请求。 */
export interface CreateLeaveRequest {
  leaveType: LeaveType
  startDate: DateString
  endDate: DateString
  startSection?: number
  endSection?: number
  reason: string
  attachmentUrl?: string
  courseIds: Array<number>
}

export interface CreateLeaveResult {
  leaveId: number
  leaveNo: string
}

export interface LeaveQuery {
  status?: LeaveStatus
}

export interface TeachingLeaveQuery {
  courseId?: number
  status?: LeaveStatus
}

/** 请假关联课程。 */
export interface LeaveCourseInfo {
  id: number
  courseCode: string
  courseName: string
  teacherId: number
  teacherName: string
}

/** 请假详情或列表项。 */
export interface LeaveInfo {
  id: number
  leaveNo: string
  applicantId: number
  leaveType: LeaveType
  startDate: DateString
  endDate: DateString
  startSection: number | null
  endSection: number | null
  reason: string
  attachmentUrl: string | null
  status: LeaveStatus
  reviewerId: number | null
  reviewComment: string | null
  reviewedAt: DateTimeString | null
  cancelReason: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString

  applicantName: string
  studentNo: string | null
  className: string | null
  reviewerName: string | null
  courses: Array<LeaveCourseInfo>
}

export interface CancelLeaveRequest {
  reason?: string
}

export interface LeaveReviewRequest {
  comment?: string
}
