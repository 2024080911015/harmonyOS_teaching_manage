import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

import { ApiConfig } from './ApiConfig'
import { ApiError } from './ApiError'
import {
  ApiResponse,
  QueryParams
} from './ApiTypes'
import { QueryBuilder } from './QueryBuilder'
import { SessionStore } from './SessionStore'

/**
 * 登录失效回调类型。
 *
 * API层只通知外部“登录已失效”，
 * 不负责页面跳转。
 */
export type UnauthorizedHandler = () => void

/**
 * 全项目统一HTTP请求客户端。
 *
 * 主要负责：
 * 1. 拼接服务器地址
 * 2. 拼接GET查询参数
 * 3. 自动添加Token
 * 4. 将请求体转换成JSON
 * 5. 解析Flask统一响应
 * 6. 将所有错误转换成ApiError
 * 7. Token失效时清除本地会话
 */
export class ApiClient {
  /**
   * 登录失效时调用的回调。
   *
   * 后面可以由Api.ets设置。
   */
  private unauthorizedHandler:
  UnauthorizedHandler | null = null

  /**
   * 设置登录失效回调。
   */
  setUnauthorizedHandler(
    handler: UnauthorizedHandler | null
  ): void {
    this.unauthorizedHandler = handler
  }

  /**
   * 发送GET请求。
   *
   * @param path 相对路径，例如 /courses
   * @param query URL查询参数
   * @param auth 是否需要Token，默认需要
   */
  async get<T>(
    path: string,
    query?: QueryParams,
    auth: boolean = true
  ): Promise<T> {
    return this.request<T>(
      path,
      http.RequestMethod.GET,
      query,
      undefined,
      auth
    )
  }

  /**
   * 发送POST请求。
   *
   * @param path 相对路径
   * @param body JSON请求体
   * @param auth 是否需要Token，默认需要
   */
  async post<T>(
    path: string,
    body?: Object,
    auth: boolean = true
  ): Promise<T> {
    return this.request<T>(
      path,
      http.RequestMethod.POST,
      undefined,
      body,
      auth
    )
  }

  /**
   * 发送PUT请求。
   */
  async put<T>(
    path: string,
    body?: Object,
    auth: boolean = true
  ): Promise<T> {
    return this.request<T>(
      path,
      http.RequestMethod.PUT,
      undefined,
      body,
      auth
    )
  }

  /**
   * 发送DELETE请求。
   */
  async delete<T>(
    path: string,
    body?: Object,
    auth: boolean = true
  ): Promise<T> {
    return this.request<T>(
      path,
      http.RequestMethod.DELETE,
      undefined,
      body,
      auth
    )
  }

  /**
   * 所有请求最终都会进入该方法。
   */
  private async request<T>(
    path: string,
    method: http.RequestMethod,
    query: QueryParams | undefined,
    body: Object | undefined,
    auth: boolean
  ): Promise<T> {
    const httpRequest: http.HttpRequest =
      http.createHttp()

    try {
      /*
       * 1. 创建请求头。
       */
      const headers: Record<string, string> = {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }

      /*
       * 2. 需要鉴权的接口自动添加Token。
       */
      if (auth) {
        const token: string =
          await SessionStore.getToken()

        if (token.length === 0) {
          throw new ApiError(
            40101,
            '当前用户尚未登录',
            401
          )
        }

        headers['Authorization'] =
          `Bearer ${token}`
      }

      /*
       * 3. 拼接完整请求地址。
       *
       * ApiConfig.BASE_URL：
       * http://192.168.1.100:8080/api
       *
       * path：
       * /courses
       *
       * query：
       * ?page=1&pageSize=20
       */
      const url: string =
        `${ApiConfig.BASE_URL}${path}` +
          QueryBuilder.build(query)

      /*
       * 4. 创建HTTP请求配置。
       */
      const options: http.HttpRequestOptions = {
        method: method,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: ApiConfig.CONNECT_TIMEOUT,
        readTimeout: ApiConfig.READ_TIMEOUT
      }

      /*
       * GET通常没有请求体。
       * POST、PUT、DELETE可以携带JSON请求体。
       */
      if (body !== undefined) {
        options.extraData =
          JSON.stringify(body)
      }

      /*
       * 5. 发送请求。
       */
      const response =
        await httpRequest.request(
          url,
          options
        )

      const httpStatus: number =
        response.responseCode

      /*
       * 6. 获取服务器返回的字符串。
       */
      if (typeof response.result !== 'string') {
        throw new ApiError(
          50001,
          '服务器返回的数据不是字符串',
          httpStatus
        )
      }

      const responseText: string =
        response.result

      if (responseText.length === 0) {
        throw new ApiError(
          50001,
          '服务器返回了空数据',
          httpStatus
        )
      }

      /*
       * 7. 将JSON字符串解析成统一响应结构。
       */
      let result: ApiResponse<T>

      try {
        result = JSON.parse(
          responseText
        ) as ApiResponse<T>
      } catch (_error) {
        /*
         * 服务器出现异常时，可能返回HTML而不是JSON。
         */
        if (
          httpStatus < 200 ||
            httpStatus >= 300
        ) {
          throw new ApiError(
            50001,
            `HTTP请求失败：${httpStatus}`,
            httpStatus
          )
        }

        throw new ApiError(
          50001,
          '服务器返回的JSON格式不正确',
          httpStatus
        )
      }

      /*
       * 8. 处理Token失效。
       *
       * 只有本来需要Token的请求，才清除本地会话。
       * 登录接口密码错误时虽然可能返回401，
       * 但不会触发登录失效回调。
       */
      const unauthorized: boolean =
        httpStatus === 401 ||
          (
            result.code >= 40100 &&
              result.code < 40200
          )

      if (auth && unauthorized) {
        await SessionStore.clear()

        if (this.unauthorizedHandler !== null) {
          try {
            this.unauthorizedHandler()
          } catch (_error) {
            // 回调异常不能影响原始API错误。
          }
        }

        throw new ApiError(
          result.code,
          result.message.length > 0
            ? result.message
            : '登录状态已失效',
          httpStatus
        )
      }

      /*
       * 9. 处理HTTP状态码错误。
       *
       * 例如：
       * 400 参数错误
       * 403 没有权限
       * 404 数据不存在
       * 409 业务冲突
       * 500 服务器错误
       */
      if (
        httpStatus < 200 ||
          httpStatus >= 300
      ) {
        throw new ApiError(
          result.code,
          result.message.length > 0
            ? result.message
            : `HTTP请求失败：${httpStatus}`,
          httpStatus
        )
      }

      /*
       * 10. 处理Flask业务错误码。
       *
       * 即使HTTP状态码为200，只要code不是0，
       * 也认为业务操作失败。
       */
      if (result.code !== 0) {
        throw new ApiError(
          result.code,
          result.message,
          httpStatus
        )
      }

      /*
       * 11. 请求成功，只返回data。
       *
       * 页面和业务API不需要再处理：
       * code、message、data。
       */
      return result.data as T

    } catch (error) {
      /*
       * 已经是ApiError时直接继续抛出，
       * 防止重复包装。
       */
      if (error instanceof ApiError) {
        throw error
      }

      /*
       * 网络断开、地址错误、连接超时等底层错误，
       * 统一转换成ApiError。
       */
      const businessError =
        error as BusinessError

      const message: string =
        businessError.message !== undefined &&
          businessError.message.length > 0
          ? businessError.message
          : '网络请求失败，请检查网络和服务器地址'

      throw new ApiError(
        50000,
        message,
        0
      )
    } finally {
      /*
       * 无论成功还是失败，都销毁请求对象。
       */
      httpRequest.destroy()
    }
  }
}