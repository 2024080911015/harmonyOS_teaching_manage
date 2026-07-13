import {
  BinaryFlag,
  DateTimeString,
  NotificationAudienceType,
  NotificationStatus,
  PageQuery,
  UserRole
} from '../core/ApiTypes'

/** 收到的通知分页查询条件。 */
export interface NotificationQuery extends PageQuery {
  unread?: boolean
}

/** 收到的通知列表项。 */
export interface ReceivedNotificationInfo {
  id: number
  title: string
  content: string
  audienceType: NotificationAudienceType
  publishedAt: DateTimeString
  expiresAt: DateTimeString | null
  publisherId: number
  publisherName: string
  isRead: BinaryFlag
  readAt: DateTimeString | null
}

/** 通知详情。 */
export interface NotificationDetailInfo {
  id: number
  publisherId: number
  title: string
  content: string
  audienceType: NotificationAudienceType
  targetClassId: number | null
  targetDepartmentId: number | null
  targetUserId: number | null
  status: NotificationStatus
  publishedAt: DateTimeString
  withdrawnAt: DateTimeString | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
  expiresAt: DateTimeString | null
  publisherName: string
  publisherRole: UserRole
  isRead: BinaryFlag | null
  readAt: DateTimeString | null
}

/** 未读数量结果。 */
export interface UnreadCountInfo {
  count: number
}

/** 发布通知请求。 */
export interface PublishNotificationRequest {
  title: string
  content: string
  audienceType: NotificationAudienceType
  expiresAt: DateTimeString
  targetClassId?: number
  targetDepartmentId?: number
  targetUserId?: number
}

/** 发布通知结果。 */
export interface PublishNotificationResult {
  notificationId: number
  recipientCount: number
}

/** 本人发布的通知及阅读统计。 */
export interface PublishedNotificationInfo {
  id: number
  publisherId: number
  title: string
  content: string
  audienceType: NotificationAudienceType
  targetClassId: number | null
  targetDepartmentId: number | null
  targetUserId: number | null
  status: NotificationStatus
  publishedAt: DateTimeString
  withdrawnAt: DateTimeString | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
  expiresAt: DateTimeString | null
  recipientCount: number
  readCount: number
}

/** 教务通知管理列表项。 */
export interface ManagedNotificationInfo {
  id: number
  publisherId: number
  title: string
  content: string
  audienceType: NotificationAudienceType
  targetClassId: number | null
  targetDepartmentId: number | null
  targetUserId: number | null
  status: NotificationStatus
  publishedAt: DateTimeString
  withdrawnAt: DateTimeString | null
  createdAt: DateTimeString
  updatedAt: DateTimeString
  expiresAt: DateTimeString | null
  publisherName: string
  publisherRole: UserRole
}
