import { ApiClient } from '../core/ApiClient'
import {
  NoData,
  PageResult,
  QueryParams
} from '../core/ApiTypes'
import {
  ManagedNotificationInfo,
  NotificationDetailInfo,
  NotificationQuery,
  PublishNotificationRequest,
  PublishNotificationResult,
  PublishedNotificationInfo,
  ReceivedNotificationInfo,
  UnreadCountInfo
} from '../model/NotificationModel'

/** 通知接口。 */
export class NotificationApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async getReceived(
    query: NotificationQuery = {}
  ): Promise<PageResult<ReceivedNotificationInfo>> {
    const params: QueryParams = new QueryParams()
    params.set('page', query.page)
    params.set('pageSize', query.pageSize)
    params.set('unread', query.unread)
    return this.client.get<PageResult<ReceivedNotificationInfo>>(
      '/notifications',
      params
    )
  }

  async getUnreadCount(): Promise<number> {
    const result = await this.client.get<UnreadCountInfo>(
      '/notifications/unread-count'
    )
    return result.count
  }

  async getDetail(
    notificationId: number
  ): Promise<NotificationDetailInfo> {
    return this.client.get<NotificationDetailInfo>(
      `/notifications/${notificationId}`
    )
  }

  async markRead(notificationId: number): Promise<void> {
    await this.client.post<NoData>(
      `/notifications/${notificationId}/read`
    )
  }

  async publish(
    request: PublishNotificationRequest
  ): Promise<PublishNotificationResult> {
    return this.client.post<PublishNotificationResult>(
      '/notifications',
      request
    )
  }

  async getPublishedByMe(): Promise<Array<PublishedNotificationInfo>> {
    return this.client.get<Array<PublishedNotificationInfo>>(
      '/notifications/published/my'
    )
  }

  async getManageList(): Promise<Array<ManagedNotificationInfo>> {
    return this.client.get<Array<ManagedNotificationInfo>>(
      '/notifications/manage'
    )
  }

  async withdraw(notificationId: number): Promise<void> {
    await this.client.post<NoData>(
      `/notifications/${notificationId}/withdraw`
    )
  }
}
