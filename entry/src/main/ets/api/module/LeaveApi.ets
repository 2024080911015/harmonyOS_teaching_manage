import { ApiClient } from '../core/ApiClient'
import {
  NoData,
  QueryParams
} from '../core/ApiTypes'
import {
  CancelLeaveRequest,
  CreateLeaveRequest,
  CreateLeaveResult,
  LeaveInfo,
  LeaveQuery,
  LeaveReviewRequest,
  TeachingLeaveQuery
} from '../model/LeaveModel'

/** 学生请假、教师查看和教务审批接口。 */
export class LeaveApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async create(
    request: CreateLeaveRequest
  ): Promise<CreateLeaveResult> {
    return this.client.post<CreateLeaveResult>(
      '/leaves',
      request
    )
  }

  async getMyLeaves(
    query: LeaveQuery = {}
  ): Promise<Array<LeaveInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('status', query.status)
    return this.client.get<Array<LeaveInfo>>(
      '/leaves/my',
      params
    )
  }

  async getDetail(leaveId: number): Promise<LeaveInfo> {
    return this.client.get<LeaveInfo>(
      `/leaves/${leaveId}`
    )
  }

  async cancel(
    leaveId: number,
    reason?: string
  ): Promise<void> {
    const request: CancelLeaveRequest = {
      reason: reason
    }
    await this.client.post<NoData>(
      `/leaves/${leaveId}/cancel`,
      request
    )
  }

  async getTeachingLeaves(
    query: TeachingLeaveQuery = {}
  ): Promise<Array<LeaveInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('courseId', query.courseId)
    params.set('status', query.status)
    return this.client.get<Array<LeaveInfo>>(
      '/leaves/teaching',
      params
    )
  }

  async getPending(): Promise<Array<LeaveInfo>> {
    return this.client.get<Array<LeaveInfo>>(
      '/leaves/pending'
    )
  }

  async approve(
    leaveId: number,
    comment?: string
  ): Promise<void> {
    const request: LeaveReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/leaves/${leaveId}/approve`,
      request
    )
  }

  async reject(
    leaveId: number,
    comment: string
  ): Promise<void> {
    const request: LeaveReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/leaves/${leaveId}/reject`,
      request
    )
  }
}
