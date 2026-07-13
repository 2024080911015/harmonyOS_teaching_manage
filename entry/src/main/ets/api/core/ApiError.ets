export class ApiError extends Error{
  readonly code:number
  readonly httpStatus:number


  //构造函数
  constructor(
    code: number,
    message: string,
    httpStatus: number = 0
  ) {
    super(message)

    this.name = 'ApiError'
    this.code = code
    this.httpStatus = httpStatus
  }

  //是否网络连接错误
  isNetworkError(): boolean {
    return this.httpStatus === 0
  }

  //是否是请求参数错误
  isBadRequest(): boolean {
    return this.httpStatus === 400 ||
      (this.code >= 40000 && this.code < 40100)
  }

  //是否未登录或者token失效
  isUnauthorized(): boolean {
    return this.httpStatus === 401 ||
      (this.code >= 40100 && this.code < 40200)
  }

  //是否为没有权限
  isForbidden(): boolean {
    return this.httpStatus === 403 ||
      (this.code >= 40300 && this.code < 40400)
  }

  //是否为数据不存在
  isNotFound(): boolean {
    return this.httpStatus === 404 ||
      (this.code >= 40400 && this.code < 40500)
  }

  /**
   * 是否为业务冲突。
   *
   * 例如：
   * 重复选课
   * 教室时间冲突
   * 课程时间冲突
   * 重复审批
   */
  isConflict(): boolean {
    return this.httpStatus === 409 ||
      (this.code >= 40900 && this.code < 41000)
  }

  /**
   * 是否为服务器内部错误。
   */
  isServerError(): boolean {
    return this.httpStatus >= 500 ||
      (this.code >= 50000 && this.code < 60000)
  }
}



