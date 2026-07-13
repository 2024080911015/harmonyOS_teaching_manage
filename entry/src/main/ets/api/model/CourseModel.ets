import {
  AcademicStatus,
  CourseSelectionStatus,
  DateTimeString,
  EnabledStatus,
  EnrollmentStatus,
  Gender,
  PageQuery,
  ScheduleStatus,
  WeekType
} from '../core/ApiTypes'

/** 课程分页查询条件。 */
export interface CourseQuery extends PageQuery {
  selectionStatus?: CourseSelectionStatus
  departmentId?: number
  keyword?: string
}

/** 基础排课信息。 */
export interface CourseScheduleInfo {
  id: number
  courseId: number
  classroomId: number
  semester: string
  startWeek: number
  endWeek: number
  weekDay: number
  startSection: number
  endSection: number
  weekType: WeekType
  status: ScheduleStatus
  createdAt: DateTimeString
  updatedAt: DateTimeString

  classroomCode: string
  classroomName: string
  campus?: string
  building?: string
}

/** 课程列表项，也用于教师授课课程列表。 */
export interface CourseInfo {
  id: number
  courseCode: string
  courseName: string
  teacherId: number
  departmentId: number
  capacity: number
  selectedCount: number
  credit: number
  selectionStart: DateTimeString
  selectionEnd: DateTimeString
  selectionStatus: CourseSelectionStatus
  status: EnabledStatus
  description: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString

  teacherName?: string
  departmentName: string
  remainingCount: number
  schedules: Array<CourseScheduleInfo>
}

/** 课程详情中的本人选课状态。 */
export interface MyEnrollmentInfo {
  status: EnrollmentStatus
  selectedAt: DateTimeString
  droppedAt: DateTimeString | null
}

/** 课程详情。 */
export interface CourseDetailInfo extends CourseInfo {
  myEnrollment?: MyEnrollmentInfo | null
}

/** 学生选课记录。 */
export interface EnrollmentRecordInfo {
  id: number
  courseId: number
  studentId: number
  status: EnrollmentStatus
  selectedAt: DateTimeString
  droppedAt: DateTimeString | null
  createdAt: DateTimeString
  updatedAt: DateTimeString

  courseCode: string
  courseName: string
  credit: number
  teacherId: number
  teacherName: string
  schedules: Array<CourseScheduleInfo>
}

/** 教师课程中的学生。 */
export interface CourseStudentInfo {
  enrollmentStatus: EnrollmentStatus
  selectedAt: DateTimeString
  userId: number
  realName: string
  gender: Gender
  email: string | null
  phone: string | null
  studentNo: string
  academicStatus: AcademicStatus
  className: string | null
  grade: string | null
  majorName: string | null
}

/** 教师基础排课。 */
export interface TeachingScheduleInfo {
  id: number
  courseId: number
  classroomId: number
  semester: string
  startWeek: number
  endWeek: number
  weekDay: number
  startSection: number
  endSection: number
  weekType: WeekType
  status: ScheduleStatus
  createdAt: DateTimeString
  updatedAt: DateTimeString

  courseCode: string
  courseName: string
  classroomCode: string
  classroomName: string
}
