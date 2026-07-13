import { ApiClient } from '../core/ApiClient'
import {
  NoData,
  PageResult,
  QueryParams
} from '../core/ApiTypes'
import {
  ApprovalQuery,
  ApprovalRecordInfo,
  CreateClassRequest,
  CreateClassResult,
  CreateClassroomRequest,
  CreateClassroomResult,
  CreateCourseRequest,
  CreateCourseResult,
  CreateDepartmentRequest,
  CreateDepartmentResult,
  CreateScheduleRequest,
  CreateScheduleResult,
  CreateSemesterRequest,
  CreateSemesterResult,
  CreateUserRequest,
  ResetPasswordRequest,
  UpdateClassRequest,
  UpdateClassroomRequest,
  UpdateCourseRequest,
  UpdateCourseStatusRequest,
  UpdateDepartmentRequest,
  UpdateScheduleRequest,
  UpdateSemesterRequest,
  UpdateUserRequest,
  UpdateUserStatusRequest,
  UserDetailInfo,
  UserQuery,
  UserSummaryInfo
} from '../model/AdminModel'

/** 教务和管理员接口。 */
export class AdminApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async getUsers(
    query: UserQuery = {}
  ): Promise<PageResult<UserSummaryInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('page', query.page)
    params.set('pageSize', query.pageSize)
    params.set('role', query.role)
    params.set('status', query.status)
    params.set('departmentId', query.departmentId)
    params.set('classId', query.classId)
    params.set('keyword', query.keyword)
    return this.client.get<PageResult<UserSummaryInfo>>(
      '/admin/users',
      params
    )
  }

  async createUser(
    request: CreateUserRequest
  ): Promise<UserDetailInfo> {
    return this.client.post<UserDetailInfo>(
      '/admin/users',
      request
    )
  }

  async getUser(userId: number): Promise<UserDetailInfo> {
    return this.client.get<UserDetailInfo>(
      `/admin/users/${userId}`
    )
  }

  async updateUser(
    userId: number,
    request: UpdateUserRequest
  ): Promise<UserDetailInfo> {
    return this.client.put<UserDetailInfo>(
      `/admin/users/${userId}`,
      request
    )
  }

  async updateUserStatus(
    userId: number,
    request: UpdateUserStatusRequest
  ): Promise<void> {
    await this.client.post<NoData>(
      `/admin/users/${userId}/status`,
      request
    )
  }

  async resetUserPassword(
    userId: number,
    request: ResetPasswordRequest
  ): Promise<void> {
    await this.client.post<NoData>(
      `/admin/users/${userId}/reset-password`,
      request
    )
  }

  async createDepartment(
    request: CreateDepartmentRequest
  ): Promise<CreateDepartmentResult> {
    return this.client.post<CreateDepartmentResult>(
      '/admin/departments',
      request
    )
  }

  async updateDepartment(
    departmentId: number,
    request: UpdateDepartmentRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/departments/${departmentId}`,
      request
    )
  }

  async createClass(
    request: CreateClassRequest
  ): Promise<CreateClassResult> {
    return this.client.post<CreateClassResult>(
      '/admin/classes',
      request
    )
  }

  async updateClass(
    classId: number,
    request: UpdateClassRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/classes/${classId}`,
      request
    )
  }

  async createClassroom(
    request: CreateClassroomRequest
  ): Promise<CreateClassroomResult> {
    return this.client.post<CreateClassroomResult>(
      '/admin/classrooms',
      request
    )
  }

  async updateClassroom(
    classroomId: number,
    request: UpdateClassroomRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/classrooms/${classroomId}`,
      request
    )
  }

  async createSemester(
    request: CreateSemesterRequest
  ): Promise<CreateSemesterResult> {
    return this.client.post<CreateSemesterResult>(
      '/admin/semesters',
      request
    )
  }

  async updateSemester(
    semesterId: number,
    request: UpdateSemesterRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/semesters/${semesterId}`,
      request
    )
  }

  async createCourse(
    request: CreateCourseRequest
  ): Promise<CreateCourseResult> {
    return this.client.post<CreateCourseResult>(
      '/admin/courses',
      request
    )
  }

  async updateCourse(
    courseId: number,
    request: UpdateCourseRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/courses/${courseId}`,
      request
    )
  }

  async updateCourseStatus(
    courseId: number,
    request: UpdateCourseStatusRequest
  ): Promise<void> {
    await this.client.post<NoData>(
      `/admin/courses/${courseId}/status`,
      request
    )
  }

  async createSchedule(
    request: CreateScheduleRequest
  ): Promise<CreateScheduleResult> {
    return this.client.post<CreateScheduleResult>(
      '/admin/schedules',
      request
    )
  }

  async updateSchedule(
    scheduleId: number,
    request: UpdateScheduleRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      `/admin/schedules/${scheduleId}`,
      request
    )
  }

  async cancelSchedule(scheduleId: number): Promise<void> {
    await this.client.post<NoData>(
      `/admin/schedules/${scheduleId}/cancel`
    )
  }

  async getApprovals(
    query: ApprovalQuery = {}
  ): Promise<Array<ApprovalRecordInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('businessType', query.businessType)
    params.set('approverId', query.approverId)
    return this.client.get<Array<ApprovalRecordInfo>>(
      '/admin/approvals',
      params
    )
  }
}
