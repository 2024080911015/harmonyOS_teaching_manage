import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'

import {
  DateTimeString,
  UserRole
} from './ApiTypes'

export interface SessionInfo {
  token: string
  userId: number
  account: string
  realName: string
  role: UserRole
  expiresAt: DateTimeString
}

//用于存储登录状态的类
export class SessionStore{
  private static readonly STORE_NAME: string =
    'teaching_api_session'
  private static readonly KEY_TOKEN: string = 'token'
  private static readonly KEY_USER_ID: string = 'userId'
  private static readonly KEY_ACCOUNT: string = 'account'
  private static readonly KEY_REAL_NAME: string = 'realName'
  private static readonly KEY_ROLE: string = 'role'
  private static readonly KEY_EXPIRES_AT: string = 'expiresAt'


  private static store: preferences.Preferences | null = null

  //初始化数据库用
  static async init(context:common.Context):Promise<void>{
    if (SessionStore.store !== null) {
      return
    }
    SessionStore.store =
      await preferences.getPreferences(
        context,
        {
          name: SessionStore.STORE_NAME
        }
      )
  }

  //返回保存的登录状态
  private static requireStore(): preferences.Preferences {
    if (SessionStore.store === null) {
      throw new Error(
        'SessionStore尚未初始化，请先调用SessionStore.init()'
      )
    }

    return SessionStore.store
  }
  //保存登录状态
  static async save(
    session: SessionInfo
  ): Promise<void> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    await store.put(
      SessionStore.KEY_TOKEN,
      session.token
    )

    await store.put(
      SessionStore.KEY_USER_ID,
      session.userId
    )

    await store.put(
      SessionStore.KEY_ACCOUNT,
      session.account
    )

    await store.put(
      SessionStore.KEY_REAL_NAME,
      session.realName
    )

    await store.put(
      SessionStore.KEY_ROLE,
      session.role
    )

    await store.put(
      SessionStore.KEY_EXPIRES_AT,
      session.expiresAt
    )

    // 将修改真正写入持久化存储。
    await store.flush()
  }

  //获取token
  /**
   * 获取Token。
   *
   * ApiClient发送需要登录的请求时使用。
   * 没有Token时返回空字符串。
   */
  static async getToken(): Promise<string> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    const value = await store.get(
      SessionStore.KEY_TOKEN,
      ''
    )

    if (typeof value !== 'string') {
      return ''
    }

    return value
  }

  /**
   * 获取当前用户ID。
   *
   * 没有登录时返回0。
   */
  static async getUserId(): Promise<number> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    const value = await store.get(
      SessionStore.KEY_USER_ID,
      0
    )

    if (typeof value !== 'number') {
      return 0
    }

    return value
  }

  /**
   * 获取当前用户角色。
   *
   * 没有会话或角色值错误时返回null。
   */
  static async getRole(): Promise<UserRole | null> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    const value = await store.get(
      SessionStore.KEY_ROLE,
      ''
    )

    if (typeof value !== 'string') {
      return null
    }

    return SessionStore.parseRole(value)
  }

  /**
   * 获取完整会话信息。
   *
   * 没有登录信息或数据损坏时返回null。
   */
  static async getSession(): Promise<SessionInfo | null> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    const tokenValue = await store.get(
      SessionStore.KEY_TOKEN,
      ''
    )

    const userIdValue = await store.get(
      SessionStore.KEY_USER_ID,
      0
    )

    const accountValue = await store.get(
      SessionStore.KEY_ACCOUNT,
      ''
    )

    const realNameValue = await store.get(
      SessionStore.KEY_REAL_NAME,
      ''
    )

    const roleValue = await store.get(
      SessionStore.KEY_ROLE,
      ''
    )

    const expiresAtValue = await store.get(
      SessionStore.KEY_EXPIRES_AT,
      ''
    )

    // 检查存储的数据类型是否正确。
    if (
      typeof tokenValue !== 'string' ||
        typeof userIdValue !== 'number' ||
        typeof accountValue !== 'string' ||
        typeof realNameValue !== 'string' ||
        typeof roleValue !== 'string' ||
        typeof expiresAtValue !== 'string'
    ) {
      return null
    }

    // Token不存在，表示当前没有登录。
    if (
      tokenValue.length === 0 ||
        userIdValue <= 0
    ) {
      return null
    }

    const role: UserRole | null =
      SessionStore.parseRole(roleValue)

    if (role === null) {
      return null
    }

    const session: SessionInfo = {
      token: tokenValue,
      userId: userIdValue,
      account: accountValue,
      realName: realNameValue,
      role: role,
      expiresAt: expiresAtValue
    }

    return session
  }

  /**
   * 判断本地是否保存了有效格式的登录会话。
   *
   * 注意：
   * 这里只检查本地是否存在Token，
   * Token是否真正有效仍然由Flask服务端判断。
   */
  static async hasSession(): Promise<boolean> {
    const token: string =
      await SessionStore.getToken()

    return token.length > 0
  }

  /**
   * 清除全部登录信息。
   *
   * 以下情况会调用：
   * 1. 用户主动退出登录
   * 2. Flask返回401
   * 3. Token失效或被撤销
   */
  static async clear(): Promise<void> {
    const store: preferences.Preferences =
      SessionStore.requireStore()

    await store.clear()
    await store.flush()
  }

  /**
   * 将本地字符串安全转换为UserRole。
   *
   * 不直接使用强制类型转换，
   * 避免存储了非法角色字符串。
   */
  private static parseRole(
    value: string
  ): UserRole | null {
    switch (value) {
      case UserRole.STUDENT:
        return UserRole.STUDENT

      case UserRole.TEACHER:
        return UserRole.TEACHER

      case UserRole.ACADEMIC_STAFF:
        return UserRole.ACADEMIC_STAFF

      case UserRole.ADMIN:
        return UserRole.ADMIN

      default:
        return null
    }
  }
}