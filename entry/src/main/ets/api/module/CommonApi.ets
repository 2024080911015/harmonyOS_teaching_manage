import { ApiClient } from '../core/ApiClient'
import { QueryParams } from '../core/ApiTypes'
import {
  AvailableClassroomQuery,
  ClassGroupInfo,
  ClassroomInfo,
  ClassroomQuery,
  DepartmentInfo,
  HealthInfo,
  SemesterInfo,
  TimetableInfo
} from '../model/CommonModel'

/** 健康检查、基础数据、教室和本人课表接口。 */
export class CommonApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async health(): Promise<HealthInfo> {
    return this.client.get<HealthInfo>(
      '/health',
      undefined,
      false
    )
  }

  async getDepartments(): Promise<Array<DepartmentInfo>> {
    return this.client.get<Array<DepartmentInfo>>('/departments')
  }

  async getClasses(
    departmentId?: number
  ): Promise<Array<ClassGroupInfo>> {
    const query: QueryParams = new QueryParams()
    query.set('departmentId', departmentId)
    return this.client.get<Array<ClassGroupInfo>>(
      '/classes',
      query
    )
  }

  async getSemesters(): Promise<Array<SemesterInfo>> {
    return this.client.get<Array<SemesterInfo>>('/semesters')
  }

  async getClassrooms(
    query: ClassroomQuery = {}
  ): Promise<Array<ClassroomInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('status', query.status)
    params.set('campus', query.campus)
    params.set('roomType', query.roomType)
    params.set('minCapacity', query.minCapacity)
    return this.client.get<Array<ClassroomInfo>>(
      '/classrooms',
      params
    )
  }

  async getClassroom(
    classroomId: number
  ): Promise<ClassroomInfo> {
    return this.client.get<ClassroomInfo>(
      `/classrooms/${classroomId}`
    )
  }

  async getAvailableClassrooms(
    query: AvailableClassroomQuery
  ): Promise<Array<ClassroomInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('date', query.date)
    params.set('startSection', query.startSection)
    params.set('endSection', query.endSection)
    params.set('participantCount', query.participantCount)
    return this.client.get<Array<ClassroomInfo>>(
      '/classrooms/available',
      params
    )
  }

  async getMyTimetable(
    date: string
  ): Promise<TimetableInfo> {
    const query: QueryParams = new QueryParams()
    query.set('date', date)
    return this.client.get<TimetableInfo>(
      '/timetable/my',
      query
    )
  }
}
