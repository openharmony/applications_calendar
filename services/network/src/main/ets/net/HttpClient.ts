/*
 * Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * HttpClient — 替代 rcp.Session 的 HTTP 核心类
 *
 * 使用 @kit.NetworkKit 的 http.createHttp() 实现 HTTP 请求，
 * 自行维护拦截器链，对外暴露与 rcp.Session 兼容的接口。
 *
 * SDK 参考: @ohos.net.http.d.ts (API 20)
 *   - createHttp(): HttpRequest
 *   - HttpRequest.request(url, options?): Promise<HttpResponse>
 *   - HttpRequestOptions.method: RequestMethod (string enum)
 *   - HttpRequestOptions.serverAuthentication: ServerAuthentication (原生支持 basic/digest/ntlm)
 *   - HttpRequestOptions.usingProtocol: HttpProtocol (HTTP1_1 | HTTP2 | HTTP3)
 *   - HttpResponse.result: string | Object | ArrayBuffer
 *   - HttpResponse.responseCode: ResponseCode | number
 *   - HttpResponse.header: Object
 */

import lazy { http } from '@kit.NetworkKit';
import { BusinessError } from '@ohos.base';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { HttpMethod } from './HttpConfig';

const TAG = 'HttpClient';

// ======================== 类型定义 ========================

/**
 * 请求标识信息类型
 */
export interface RequestInfo {
  id: string;
  method: string;
  url: string;
  headers: Record<string, string | string[]>;
}

/**
 * 服务器认证配置类型
 */
export interface ServerAuthConfig {
  username: string;
  password: string;
  type: 'basic' | 'digest';
}

/**
 * 拦截器上下文 —— 替代 rcp.RequestContext
 */
export interface HttpRequestContext {
  /** 当前请求信息 */
  request: RequestInfo;
  /** 内部使用的请求选项 */
  options: HttpRequestOptions;
}

/**
 * 拦截器 next 处理器 —— 替代 rcp.RequestHandler
 */
export interface HttpRequestHandler {
  handle(context: HttpRequestContext): Promise<HttpResponseAdapter>;
}

/**
 * 拦截器接口 —— 替代 rcp.Interceptor
 */
export interface HttpInterceptor {
  intercept(context: HttpRequestContext, next: HttpRequestHandler): Promise<HttpResponseAdapter>;
}

/**
 * HTTP 请求选项（适配 rcp.Request 的属性）
 */
export interface HttpRequestOptions {
  url: string;
  method: string;
  headers?: Record<string, string | string[]>;
  body?: string;
  /** 基础 URL 前缀，会自动拼接到 url 前面 */
  baseAddress?: string;
}

/**
 * HTTP 响应适配器 —— 替代 rcp.Response
 */
export class HttpResponseAdapter {
  public readonly statusCode: number;
  public readonly headers: Record<string, string | string[]>;

  private responseBody: string;

  constructor(statusCode: number, headers: Record<string, string | string[]>, body: string) {
    this.statusCode = statusCode;
    this.headers = headers;
    this.responseBody = body;
  }

  /**
   * 获取响应体字符串 —— 替代 rcp.Response.toString()
   */
  toString(): string {
    return this.responseBody;
  }

  /**
   * 获取原始 body（用于 JSON 解析等场景）
   */
  getBody(): string {
    return this.responseBody;
  }
}

/**
 * HttpClient 配置
 */
export interface HttpClientConfig {
  /** 拦截器链（按顺序执行） */
  interceptors?: HttpInterceptor[];
  /** 基础 URL，所有请求都会拼接到此 URL 前面 */
  baseAddress?: string;
  /** 公共请求头 */
  headers?: Record<string, string | string[]>;
  /** 超时配置（毫秒） */
  connectTimeout?: number;
  transferTimeout?: number;
  /** 服务器认证配置（映射到 http.ServerAuthentication，原生支持 basic/digest/ntlm） */
  serverAuthentication?: ServerAuthConfig;
}

// ======================== HttpClient 主类 ========================

export class HttpClient {
  private interceptors: HttpInterceptor[] = [];
  private baseAddress: string = '';
  private commonHeaders: Record<string, string | string[]> = {};
  private connectTimeout: number = 20000;
  private transferTimeout: number = 60000;
  private serverAuth?: ServerAuthConfig;
  private requestIdCounter: number = 0;

  constructor(config?: HttpClientConfig) {
    if (config) {
      this.interceptors = config.interceptors ?? [];
      this.baseAddress = config.baseAddress ?? '';
      this.commonHeaders = config.headers ?? {};
      this.connectTimeout = config.connectTimeout ?? 20000;
      this.transferTimeout = config.transferTimeout ?? 60000;
      this.serverAuth = config.serverAuthentication;
    }
  }

  /**
   * 执行 HTTP 请求 — 替代 rcp.Session.fetch()
   */
  async execute(request: HttpRequestOptions): Promise<HttpResponseAdapter> {
    const url = this.resolveUrl(request.url, request.baseAddress ?? this.baseAddress);
    const requestId = `req_${++this.requestIdCounter}_${Date.now()}`;

    const context: HttpRequestContext = {
      request: {
        id: requestId,
        method: request.method,
        url: url,
        headers: { ...this.commonHeaders, ...request.headers }
      },
      options: {
        url: url,
        method: request.method,
        headers: { ...this.commonHeaders, ...request.headers },
        body: request.body
      }
    };

    // 构建拦截器链
    let index = 0;
    const interceptors = this.interceptors;

    const next: HttpRequestHandler = {
      handle: async (ctx: HttpRequestContext): Promise<HttpResponseAdapter> => {
        if (index < interceptors.length) {
          const interceptor = interceptors[index++];
          return interceptor.intercept(ctx, next);
        }
        // 所有拦截器执行完毕，发起实际 HTTP 请求
        return HttpClient.doHttpRequest(ctx, this.connectTimeout, this.transferTimeout, this.serverAuth);
      }
    };

    return next.handle(context);
  }

  /**
   * 销毁（取消进行中的请求）
   */
  destroy(): void {
    // 单次请求在 doHttpRequest 的 finally 中自动销毁
    // 此处保留接口兼容性
  }

  /**
   * 便捷方法：GET
   */
  async get(url: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.execute({ url, method: HttpMethod.GET, headers });
  }

  /**
   * 便捷方法：POST
   */
  async post(url: string, body?: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.execute({ url, method: HttpMethod.POST, headers, body });
  }

  /**
   * 便捷方法：PUT
   */
  async put(url: string, body?: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.execute({ url, method: HttpMethod.PUT, headers, body });
  }

  /**
   * 便捷方法：DELETE
   */
  async delete(url: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.execute({ url, method: HttpMethod.DELETE, headers });
  }

  /**
   * 拼接 URL
   */
  private resolveUrl(url: string, baseAddress: string): string {
    if (!baseAddress || baseAddress.length === 0) {
      return url;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const separator = baseAddress.endsWith('/') || url.startsWith('/') ? '' : '/';
    return baseAddress + separator + url;
  }

  /**
   * 执行实际的 HTTP 请求（使用 @kit.NetworkKit）
   *
   * 使用 Promise 风格的 request() API:
   *   request(url: string, options?: HttpRequestOptions): Promise<HttpResponse>
   */
  private static async doHttpRequest(
    ctx: HttpRequestContext,
    connectTimeout: number,
    transferTimeout: number,
    serverAuth?: ServerAuthConfig
  ): Promise<HttpResponseAdapter> {
    const httpRequest = http.createHttp();
    const options = ctx.options;

    // 构建请求头（兼容 rcp.RequestHeaders 的 string | string[] 类型）
    const requestHeaders: Record<string, string> = {};
    if (options.headers) {
      for (const key of Object.keys(options.headers)) {
        const val = options.headers[key];
        requestHeaders[key] = Array.isArray(val) ? val.join(', ') : val;
      }
    }

    // 构建 ServerAuthentication（SDK 原生支持 basic/digest/ntlm）
    let serverAuthentication: http.ServerAuthentication | undefined = undefined;
    if (serverAuth) {
      serverAuthentication = {
        credential: {
          username: serverAuth.username,
          password: serverAuth.password
        },
        authenticationType: serverAuth.type as http.AuthenticationType
      };
    }

    try {
      // SDK Promise 风格 API
      const response: http.HttpResponse = await httpRequest.request(
        options.url,
        {
          method: options.method as http.RequestMethod, // 支持自定义 HTTP 方法(PROPFIND/REPORT等)
          header: requestHeaders,
          extraData: options.body ?? '',
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: connectTimeout,
          readTimeout: transferTimeout,
          serverAuthentication: serverAuthentication
        }
      );

      // 转换响应头（http.HttpResponse.header 类型为 Object，需转为 Record）
      const respHeaders: Record<string, string | string[]> = {};
      if (response.header) {
        const headerObj = response.header as Record<string, Object>;
        for (const key of Object.keys(headerObj)) {
          const val = headerObj[key];
          if (typeof val === 'string') {
            respHeaders[key.toLowerCase()] = val;
          } else if (Array.isArray(val)) {
            respHeaders[key.toLowerCase()] = val as string[];
          } else if (val !== null && val !== undefined) {
            respHeaders[key.toLowerCase()] = String(val);
          }
        }
      }

      const responseBody: string = (response.result as string) ?? '';

      return new HttpResponseAdapter(
        response.responseCode as number,
        respHeaders,
        responseBody
      );
    } catch (error) {
      const err = error as BusinessError;
      Log.warn(TAG, `HTTP request failed: url=${options.url}, method=${options.method}, ` +
        `error=${err?.message}, code=${err?.code}`);
      throw error as Error;
    } finally {
      httpRequest.destroy();
    }
  }
}
