import { ApiClient } from '../core/ApiClient'
import {
  EnrollmentStatus,
  NoData,
  PageResult,
  QueryParams
} from '../core/ApiTypes'
import {
  CourseDetailInfo,
  CourseInfo,
  CourseQuery,
  CourseScheduleInfo,
  CourseStudentInfo,
  EnrollmentRecordInfo,
  TeachingScheduleInfo
} from '../model/CourseModel'

/** 课程、选课和教师授课接口。 */
export class CourseApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async getCourses(
    query: CourseQuery = {}
  ): Promise<PageResult<CourseInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('page', query.page)
    params.set('pageSize', query.pageSize)
    params.set('selectionStatus', query.selectionStatus)
    params.set('departmentId', query.departmentId)
    params.set('keyword', query.keyword)
    return this.client.get<PageResult<CourseInfo>>(
      '/courses',
      params
    )
  }

  async getCourse(courseId: number): Promise<CourseDetailInfo> {
    return this.client.get<CourseDetailInfo>(
      `/courses/${courseId}`
    )
  }

  async getCourseSchedules(
    courseId: number
  ): Promise<Array<CourseScheduleInfo>> {
    return this.client.get<Array<CourseScheduleInfo>>(
      `/courses/${courseId}/schedules`
    )
  }

  async getMyEnrollments(
    status?: EnrollmentStatus
  ): Promise<Array<EnrollmentRecordInfo>> {
    const query: QueryParams = new QueryParams()
    query.set('status', status)
    return this.client.get<Array<EnrollmentRecordInfo>>(
      '/enrollments/my',
      query
    )
  }

  async enroll(courseId: number): Promise<void> {
    await this.client.post<NoData>(
      `/courses/${courseId}/enroll`
    )
  }

  async drop(courseId: number): Promise<void> {
    await this.client.post<NoData>(
      `/courses/${courseId}/drop`
    )
  }

  async getTeachingCourses(): Promise<Array<CourseInfo>> {
    return this.client.get<Array<CourseInfo>>(
      '/teaching/courses'
    )
  }

  async getCourseStudents(
    courseId: number
  ): Promise<Array<CourseStudentInfo>> {
    return this.client.get<Array<CourseStudentInfo>>(
      `/teaching/courses/${courseId}/students`
    )
  }

  async getTeachingSchedules(
    semester?: string
  ): Promise<Array<TeachingScheduleInfo>> {
    const query: QueryParams = new QueryParams()
    query.set('semester', semester)
    return this.client.get<Array<TeachingScheduleInfo>>(
      '/teaching/schedules',
      query
    )
  }
}
