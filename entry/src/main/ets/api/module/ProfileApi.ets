import { ApiClient } from '../core/ApiClient'
import {
  HomeInfo,
  UpdateProfileRequest,
  UserProfileInfo
} from '../model/ProfileModel'

/** 个人中心接口。 */
export class ProfileApi {
  private client: ApiClient

  constructor(client: ApiClient) {
    this.client = client
  }

  async getMyProfile(): Promise<UserProfileInfo> {
    return this.client.get<UserProfileInfo>('/profile/me')
  }

  async updateMyProfile(
    request: UpdateProfileRequest
  ): Promise<UserProfileInfo> {
    return this.client.put<UserProfileInfo>(
      '/profile/me',
      request
    )
  }

  async getHome(): Promise<HomeInfo> {
    return this.client.get<HomeInfo>('/home')
  }
}
