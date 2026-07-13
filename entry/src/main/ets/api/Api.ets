import { common } from '@kit.AbilityKit'

import {
  ApiClient,
  UnauthorizedHandler
} from './core/ApiClient'

import {
  SessionInfo,
  SessionStore
} from './core/SessionStore'

import { AuthApi } from './module/AuthApi'
import { ProfileApi } from './module/ProfileApi'
import { CommonApi } from './module/CommonApi'
import { NotificationApi } from './module/NotificationApi'
import { CourseApi } from './module/CourseApi'
import { BookingApi } from './module/BookingApi'
import { LeaveApi } from './module/LeaveApi'
import { ScheduleChangeApi } from './module/ScheduleChangeApi'
import { AdminApi } from './module/AdminApi'

/**
 * 教学管理系统统一 API 入口。
 *
 * 整个项目只创建一个 TeachingApi 实例，
 * 所有业务模块共用同一个 ApiClient。
 */
export class TeachingApi {
  /**
   * 全项目统一网络请求客户端。
   */
  private readonly client: ApiClient

  /**
   * 各业务 API 模块。
   */
  readonly auth: AuthApi
  readonly profile: ProfileApi
  readonly common: CommonApi
  readonly notification: NotificationApi
  readonly course: CourseApi
  readonly booking: BookingApi
  readonly leave: LeaveApi
  readonly scheduleChange: ScheduleChangeApi
  readonly admin: AdminApi

  constructor() {
    /*
     * 整个项目只创建一个 ApiClient。
     */
    this.client = new ApiClient()

    /*
     * 所有业务模块共用同一个 ApiClient。
     */
    this.auth = new AuthApi(this.client)
    this.profile = new ProfileApi(this.client)
    this.common = new CommonApi(this.client)

    this.notification =
      new NotificationApi(this.client)

    this.course = new CourseApi(this.client)
    this.booking = new BookingApi(this.client)
    this.leave = new LeaveApi(this.client)

    this.scheduleChange =
      new ScheduleChangeApi(this.client)

    this.admin = new AdminApi(this.client)
  }

  /**
   * 初始化 API 模块。
   *
   * 应用启动时必须调用一次，
   * 用于初始化 Preferences 会话存储。
   */
  async init(
    context: common.Context
  ): Promise<void> {
    await SessionStore.init(context)
  }

  /**
   * 设置登录失效回调。
   *
   * 当服务器返回 401 或 Token 失效时，
   * ApiClient 会清除本地会话，
   * 然后调用这个回调。
   */
  setUnauthorizedHandler(
    handler: UnauthorizedHandler | null
  ): void {
    this.client.setUnauthorizedHandler(handler)
  }

  /**
   * 判断本地是否保存了登录会话。
   *
   * 注意：
   * 这里只能判断本地有没有 Token，
   * Token 是否仍然有效，需要调用 /auth/me 验证。
   */
  async hasSession(): Promise<boolean> {
    return SessionStore.hasSession()
  }

  /**
   * 获取本地保存的完整会话。
   */
  async getSession(): Promise<SessionInfo | null> {
    return SessionStore.getSession()
  }

  /**
   * 清除本地会话。
   *
   * 通常由退出登录或 Token 失效时调用。
   */
  async clearSession(): Promise<void> {
    await SessionStore.clear()
  }
}

/**
 * 整个项目统一使用的 API 实例。
 *
 * 页面和业务代码不要再 new TeachingApi()。
 */
export const Api: TeachingApi =
  new TeachingApi()