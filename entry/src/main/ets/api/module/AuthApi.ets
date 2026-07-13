import { ApiClient } from '../core/ApiClient'
import { NoData } from '../core/ApiTypes'
import {
  SessionInfo,
  SessionStore
} from '../core/SessionStore'
import {
  ChangePasswordRequest,
  CurrentUserInfo,
  LoginRequest,
  LoginResult
} from '../model/AuthModel'

/** 认证接口。 */
export class AuthApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async login(
    account: string,
    password: string
  ): Promise<LoginResult> {
    const request: LoginRequest = {
      account: account,
      password: password
    }

    const result = await this.client.post<LoginResult>(
      '/auth/login',
      request,
      false
    )

    const session: SessionInfo = {
      token: result.token,
      userId: result.userId,
      account: result.account,
      realName: result.realName,
      role: result.role,
      expiresAt: result.expiresAt
    }
    await SessionStore.save(session)
    return result
  }

  async me(): Promise<CurrentUserInfo> {
    return this.client.get<CurrentUserInfo>('/auth/me')
  }

  async logout(): Promise<void> {
    try {
      await this.client.post<NoData>('/auth/logout')
    } finally {
      await SessionStore.clear()
    }
  }

  async changePassword(
    request: ChangePasswordRequest
  ): Promise<void> {
    await this.client.put<NoData>(
      '/auth/password',
      request
    )
  }
}
