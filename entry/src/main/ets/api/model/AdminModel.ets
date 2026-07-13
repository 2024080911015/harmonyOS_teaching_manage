import {
  AcademicStatus,
  ApprovalAction,
  ApprovalBusinessType,
  ClassroomStatus,
  CourseSelectionStatus,
  DateString,
  DateTimeString,
  EnabledStatus,
  Gender,
  PageQuery,
  RoomType,
  UserRole,
  WeekType
} from '../core/ApiTypes'
import {
  AcademicStaffRoleProfile,
  StudentRoleProfile,
  TeacherRoleProfile
} from './ProfileModel'

/** 人员分页查询条件。 */
export interface UserQuery extends PageQuery {
  role?: UserRole
  status?: EnabledStatus
  departmentId?: number
  classId?: number
  keyword?: string
}

/** 人员列表项。 */
export interface UserSummaryInfo {
  id: number
  account: string
  realName: string
  role: UserRole
  gender: Gender
  phone: string | null
  email: string | null
  departmentId: number | null
  classId: number | null
  status: EnabledStatus
  lastLoginAt: DateTimeString | null
  departmentName: string | null
  className: string | null
}

/** 管理端人员详情。 */
export interface UserDetailInfo extends UserSummaryInfo {
  avatarUrl: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
  grade: string | null
  majorName: string | null
  roleProfile:
    StudentRoleProfile |
    TeacherRoleProfile |
    AcademicStaffRoleProfile |
    null
}

/** 管理员预建账号请求。 */
export interface CreateUserRequest {
  account: string
  initialPassword: string
  realName: string
  role: UserRole
  gender?: Gender
  phone?: string
  email?: string
  avatarUrl?: string
  departmentId?: number
  classId?: number

  studentNo?: string
  admissionDate?: DateString
  academicStatus?: AcademicStatus
  earnedCredits?: number

  employeeNo?: string
  professionalTitle?: string
  introduction?: string

  responsibilityArea?: string
  approvalLevel?: number
}

/** 管理端修改人员资料。 */
export interface UpdateUserRequest {
  realName?: string
  gender?: Gender
  phone?: string | null
  email?: string | null
  avatarUrl?: string | null
  departmentId?: number | null
  classId?: number | null

  studentNo?: string
  admissionDate?: DateString | null
  academicStatus?: AcademicStatus
  earnedCredits?: number

  employeeNo?: string
  professionalTitle?: string | null
  introduction?: string | null
  responsibilityArea?: string | null
  approvalLevel?: number
}

export interface UpdateUserStatusRequest {
  status: EnabledStatus
}

export interface ResetPasswordRequest {
  newPassword: string
}

export interface CreateDepartmentRequest {
  departmentCode: string
  departmentName: string
  managerName?: string
}

export interface UpdateDepartmentRequest {
  departmentCode?: string
  departmentName?: string
  managerName?: string | null
  status?: EnabledStatus
}

export interface CreateDepartmentResult {
  departmentId: number
}

export interface CreateClassRequest {
  classCode: string
  className: string
  grade: string
  majorName: string
  departmentId: number
  campus?: string
  studentCount?: number
  counselorName?: string
}

export interface UpdateClassRequest {
  classCode?: string
  className?: string
  grade?: string
  majorName?: string
  departmentId?: number
  campus?: string | null
  studentCount?: number
  counselorName?: string | null
  status?: EnabledStatus
}

export interface CreateClassResult {
  classId: number
}

export interface CreateClassroomRequest {
  classroomCode: string
  classroomName: string
  campus: string
  building: string
  floor?: number
  roomType: RoomType
  capacity: number
  equipment?: string
  status?: ClassroomStatus
}

export interface UpdateClassroomRequest {
  classroomCode?: string
  classroomName?: string
  campus?: string
  building?: string
  floor?: number | null
  roomType?: RoomType
  capacity?: number
  equipment?: string | null
  status?: ClassroomStatus
}

export interface CreateClassroomResult {
  classroomId: number
}

export interface CreateSemesterRequest {
  semesterCode: string
  semesterName: string
  startDate: DateString
  endDate: DateString
}

export interface UpdateSemesterRequest {
  semesterCode?: string
  semesterName?: string
  startDate?: DateString
  endDate?: DateString
  status?: EnabledStatus
}

export interface CreateSemesterResult {
  semesterId: number
}

export interface CreateCourseRequest {
  courseCode: string
  courseName: string
  teacherId: number
  departmentId: number
  capacity?: number
  credit?: number
  selectionStart: DateTimeString
  selectionEnd: DateTimeString
  selectionStatus?: CourseSelectionStatus
  status?: EnabledStatus
  description?: string
}

export interface UpdateCourseRequest {
  courseCode?: string
  courseName?: string
  teacherId?: number
  departmentId?: number
  capacity?: number
  credit?: number
  selectionStart?: DateTimeString
  selectionEnd?: DateTimeString
  selectionStatus?: CourseSelectionStatus
  status?: EnabledStatus
  description?: string | null
}

export interface CreateCourseResult {
  courseId: number
}

export interface UpdateCourseStatusRequest {
  status: EnabledStatus
  selectionStatus?: CourseSelectionStatus
}

export interface CreateScheduleRequest {
  courseId: number
  classroomId: number
  semester: string
  startWeek: number
  endWeek: number
  weekDay: number
  startSection: number
  endSection: number
  weekType: WeekType
}

export interface UpdateScheduleRequest {
  courseId?: number
  classroomId?: number
  semester?: string
  startWeek?: number
  endWeek?: number
  weekDay?: number
  startSection?: number
  endSection?: number
  weekType?: WeekType
}

export interface CreateScheduleResult {
  scheduleId: number
}

export interface ApprovalQuery {
  businessType?: ApprovalBusinessType
  approverId?: number
}

export interface ApprovalRecordInfo {
  id: number
  businessType: ApprovalBusinessType
  businessId: number
  approverId: number
  action: ApprovalAction
  comment: string | null
  createdAt: DateTimeString
  approverName: string
}
