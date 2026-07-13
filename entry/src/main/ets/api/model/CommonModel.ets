import {
  ClassroomStatus,
  DateString,
  DateTimeString,
  EnabledStatus,
  RoomType,
  ScheduleStatus,
  WeekType
} from '../core/ApiTypes'

/** 健康检查结果。 */
export interface HealthInfo {
  status: string
}

/** 院系基础信息。 */
export interface DepartmentInfo {
  id: number
  departmentCode: string
  departmentName: string
  managerName: string | null
}

/** 班级信息。 */
export interface ClassGroupInfo {
  id: number
  classCode: string
  className: string
  grade: string
  majorName: string
  departmentId: number
  departmentName: string
  campus: string | null
  studentCount: number
  counselorName: string | null
  status: EnabledStatus
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 学期信息。 */
export interface SemesterInfo {
  id: number
  semesterCode: string
  semesterName: string
  startDate: DateString
  endDate: DateString
  status: EnabledStatus
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 教室信息。 */
export interface ClassroomInfo {
  id: number
  classroomCode: string
  classroomName: string
  campus: string
  building: string
  floor: number | null
  roomType: RoomType
  capacity: number
  equipment: string | null
  status: ClassroomStatus
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 教室列表查询条件。 */
export interface ClassroomQuery {
  status?: ClassroomStatus
  campus?: string
  roomType?: RoomType
  minCapacity?: number
}

/** 空闲教室查询条件。 */
export interface AvailableClassroomQuery {
  date: DateString
  startSection: number
  endSection: number
  participantCount: number
}

/** 某一天实际生效的课表项。 */
export interface TimetableScheduleInfo {
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

  teacherId: number
  courseCode: string
  courseName: string
  teacherName: string
  classroomCode: string
  classroomName: string

  effectiveWeekDay: number
  effectiveStartSection: number
  effectiveEndSection: number
  effectiveClassroomId: number
  effectiveClassroomCode: string | null
  effectiveClassroomName: string | null
  changed: boolean
  changeId: number | null
}

/** 本人某一天的课表结果。 */
export interface TimetableInfo {
  date: DateString
  semester: SemesterInfo | null
  week: number | null
  schedules: Array<TimetableScheduleInfo>
}
