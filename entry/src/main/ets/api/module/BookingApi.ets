import { ApiClient } from '../core/ApiClient'
import {
  NoData,
  QueryParams
} from '../core/ApiTypes'
import {
  BookingInfo,
  BookingLogInfo,
  BookingQuery,
  BookingReviewRequest,
  CancelBookingRequest,
  CreateBookingRequest,
  CreateBookingResult,
  FinishExpiredBookingResult,
  PendingBookingQuery
} from '../model/BookingModel'

/** 教室申请与审批接口。 */
export class BookingApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async create(
    request: CreateBookingRequest
  ): Promise<CreateBookingResult> {
    return this.client.post<CreateBookingResult>(
      '/bookings',
      request
    )
  }

  async getMyBookings(
    query: BookingQuery = {}
  ): Promise<Array<BookingInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('status', query.status)
    return this.client.get<Array<BookingInfo>>(
      '/bookings/my',
      params
    )
  }

  async getDetail(bookingId: number): Promise<BookingInfo> {
    return this.client.get<BookingInfo>(
      `/bookings/${bookingId}`
    )
  }

  async cancel(
    bookingId: number,
    reason?: string
  ): Promise<void> {
    const request: CancelBookingRequest = {
      reason: reason
    }
    await this.client.post<NoData>(
      `/bookings/${bookingId}/cancel`,
      request
    )
  }

  async getLogs(
    bookingId: number
  ): Promise<Array<BookingLogInfo>> {
    return this.client.get<Array<BookingLogInfo>>(
      `/bookings/${bookingId}/logs`
    )
  }

  async getPending(
    query: PendingBookingQuery = {}
  ): Promise<Array<BookingInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('applicantRole', query.applicantRole)
    return this.client.get<Array<BookingInfo>>(
      '/bookings/pending',
      params
    )
  }

  async approve(
    bookingId: number,
    comment?: string
  ): Promise<void> {
    const request: BookingReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/bookings/${bookingId}/approve`,
      request
    )
  }

  async reject(
    bookingId: number,
    comment: string
  ): Promise<void> {
    const request: BookingReviewRequest = {
      comment: comment
    }
    await this.client.post<NoData>(
      `/bookings/${bookingId}/reject`,
      request
    )
  }

  async finishExpired(): Promise<number> {
    const result = await this.client.post<FinishExpiredBookingResult>(
      '/bookings/finish-expired'
    )
    return result.finishedCount
  }
}
