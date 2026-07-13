import {
  DateTimeString,
  EnabledStatus,
  Gender,
  UserRole
} from '../core/ApiTypes'

/** 登录请求。 */
export interface LoginRequest {
  account: string
  password: string
}

/** 登录成功结果。 */
export interface LoginResult {
  token: string
  expiresAt: DateTimeString
  userId: number
  account: string
  realName: string
  role: UserRole
  departmentId: number | null
  classId: number | null
}

/** 当前 Token 对应的用户信息。 */
export interface CurrentUserInfo {
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
}

/** 修改密码请求。 */
export interface ChangePasswordRequest {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}
