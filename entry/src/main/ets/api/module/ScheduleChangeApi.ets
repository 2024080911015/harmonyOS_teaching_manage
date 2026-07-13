import { ApiClient } from '../core/ApiClient'
import {
  NoData,
  QueryParams
} from '../core/ApiTypes'
import {
  CancelScheduleChangeRequest,
  CreateScheduleChangeRequest,
  CreateScheduleChangeResult,
  ScheduleChangeInfo,
  ScheduleChangeQuery,
  ScheduleChangeReviewRequest,
  ScheduleConflictResult
} from '../model/ScheduleChangeModel'

/** 教师调课与教务审批接口。 */
export class ScheduleChangeApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async create(
    request: CreateScheduleChangeRequest
  ): Promise<CreateScheduleChangeResult> {
    return this.client.post<CreateScheduleChangeResult>(
      '/schedule-changes',
      request
    )
  }

  async getMyChanges(
    query: ScheduleChangeQuery = {}
  ): Promise<Array<ScheduleChangeInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('status', query.status)
    return this.client.get<Array<ScheduleChangeInfo>>(
      '/schedule-changes/my',
      params
    )
  }

  async getDetail(
    changeId: number
  ): Promise<ScheduleChangeInfo> {
    return this.client.get<ScheduleChangeInfo>(
      `/schedule-changes/${changeId}`
    )
  }

  async getConflicts(
    changeId: number
  ): Promise<ScheduleConflictResult> {
    return this.client.get<ScheduleConflictResult>(
      `/schedule-changes/${changeId}/conflicts`
    )
  }

  async cancel(
    changeId: number,
    reason?: string
  ): Promise<void> {
    const request: CancelScheduleChangeRequest = {
      reason: reason
    }
    await this.client.post<NoData>(
      `/schedule-changes/${changeId}/cancel`,
      request
    )
  }

  async getPending(): Promise<Array<ScheduleChangeInfo>> {
    return this.client.get<Array<ScheduleChangeInfo>>(
      '/schedule-changes/pending'
    )
  }

  async approve(
    changeId: number,
    comment?: string
  ): Promise<void> {
    const request: ScheduleChangeReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/schedule-changes/${changeId}/approve`,
      request
    )
  }

  async reject(
    changeId: number,
    comment: string
  ): Promise<void> {
    const request: ScheduleChangeReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/schedule-changes/${changeId}/reject`,
      request
    )
  }
}
