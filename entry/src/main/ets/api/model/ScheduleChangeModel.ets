import {
  DateString,
  DateTimeString,
  ScheduleChangeStatus,
  ScheduleChangeType
} from '../core/ApiTypes'

/** 提交调课请求。 */
export interface CreateScheduleChangeRequest {
  scheduleId: number
  changeType: ScheduleChangeType
  reason: string
  newClassroomId?: number
  newWeek?: number
  newWeekDay?: number
  newStartSection?: number
  newEndSection?: number
}

export interface CreateScheduleChangeResult {
  changeId: number
  changeNo: string
}

export interface ScheduleChangeQuery {
  status?: ScheduleChangeStatus
}

/** 调课详情或列表项。 */
export interface ScheduleChangeInfo {
  id: number
  changeNo: string
  scheduleId: number
  applicantId: number
  changeType: ScheduleChangeType
  newClassroomId: number | null
  newWeek: number | null
  newWeekDay: number | null
  newStartSection: number | null
  newEndSection: number | null
  reason: string
  status: ScheduleChangeStatus
  reviewerId: number | null
  reviewComment: string | null
  reviewedAt: DateTimeString | null
  cancelReason: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString

  courseCode: string
  courseName: string
  semester: string
  startWeek: number
  endWeek: number
  weekDay: number
  startSection: number
  endSection: number
  oldClassroomId: number
  oldClassroomCode: string
  oldClassroomName: string
  newClassroomCode: string | null
  newClassroomName: string | null
  applicantName: string
  reviewerName: string | null
}

/** 冲突项。后端可能返回 TEACHER、CLASSROOM、BOOKING 或 DATA。 */
export interface ScheduleConflictInfo {
  type: string
  message: string
  date?: DateString
  detail?: Object | null
}

export interface ScheduleConflictResult {
  hasConflict: boolean
  conflicts: Array<ScheduleConflictInfo>
}

export interface CancelScheduleChangeRequest {
  reason?: string
}

export interface ScheduleChangeReviewRequest {
  comment?: string
}
