

//转换url格式用

import {
  QueryParams,
  QueryValue
} from './ApiTypes'

export class QueryBuilder{
  static  build(query?:QueryParams) :string{
    if(query==undefined){
      return ''
    }
    const parts: Array<string> = []
    query.forEach((value: QueryValue, key: string) => {
      const encodedKey: string =
        encodeURIComponent(key)
      const encodedValue: string =
        encodeURIComponent(String(value))
      parts.push(
        `${encodedKey}=${encodedValue}`
      )
    })
    if(parts.length==0){
      return ''
    }
    return `?${parts.join('&')}`
  }
}
