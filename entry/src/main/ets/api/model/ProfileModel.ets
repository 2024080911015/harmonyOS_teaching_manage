import {
  AcademicStatus,
  DateString,
  DateTimeString,
  EnabledStatus,
  Gender,
  UserRole
} from '../core/ApiTypes'

/** 学生角色资料。 */
export interface StudentRoleProfile {
  id: number
  userId: number
  studentNo: string
  admissionDate: DateString | null
  academicStatus: AcademicStatus
  earnedCredits: number
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 教师角色资料。 */
export interface TeacherRoleProfile {
  id: number
  userId: number
  employeeNo: string
  professionalTitle: string | null
  introduction: string | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 教务或管理员角色资料。 */
export interface AcademicStaffRoleProfile {
  id: number
  userId: number
  employeeNo: string
  responsibilityArea: string | null
  approvalLevel: number
  createdAt: DateTimeString
  updatedAt: DateTimeString
}

/** 完整个人资料。 */
export interface UserProfileInfo {
  id: number
  account: string
  realName: string
  role: UserRole
  gender: Gender
  phone: string | null
  email: string | null
  avatarUrl: string | null
  departmentId: number | null
  classId: number | null
  status: EnabledStatus
  lastLoginAt: DateTimeString | null
  createdAt: DateTimeString
  updatedAt: DateTimeString

  departmentName: string | null
  className: string | null
  grade: string | null
  majorName: string | null
  campus?: string | null

  roleProfile:
    StudentRoleProfile |
    TeacherRoleProfile |
    AcademicStaffRoleProfile |
    null
}

/** 本人允许修改的资料。 */
export interface UpdateProfileRequest {
  gender?: Gender
  phone?: string | null
  email?: string | null
  avatarUrl?: string | null

  /** 学生可修改。 */
  admissionDate?: DateString | null

  /** 教师可修改。 */
  professionalTitle?: string | null
  introduction?: string | null
}

export interface StudentHomeSummary {
  selectedCourseCount: number
  pendingBookingCount: number
  pendingLeaveCount: number
  unreadNotificationCount: number
}

export interface TeacherHomeSummary {
  teachingCourseCount: number
  pendingBookingCount: number
  pendingScheduleChangeCount: number
  unreadNotificationCount: number
}

export interface ManagerHomeSummary {
  pendingBookingCount: number
  pendingLeaveCount: number
  pendingScheduleChangeCount: number
  unreadNotificationCount: number
}

/** 角色主页聚合数据。 */
export interface HomeInfo {
  profile: UserProfileInfo
  role: UserRole
  summary:
    StudentHomeSummary |
    TeacherHomeSummary |
    ManagerHomeSummary
}
