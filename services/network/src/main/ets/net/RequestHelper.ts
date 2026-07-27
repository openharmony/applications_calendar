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

import { HttpClient, HttpRequestOptions, HttpResponseAdapter } from './HttpClient';
import { RequestEngineBuilder } from './RequestEngine';
import { HttpMethod } from './HttpConfig';

/**
 * RequestHelper — HTTP 请求适配层（使用 HttpClient 替代 rcp.Session）
 */
export class RequestHelper {
  private httpClient: HttpClient;
  private builder: RequestEngineBuilder;

  constructor(httpClient: HttpClient, builder: RequestEngineBuilder) {
    this.httpClient = httpClient;
    this.builder = builder;
  }

  /**
   * 通用请求 — 替代 session.fetch(request)
   */
  fetch(options: HttpRequestOptions): Promise<HttpResponseAdapter> {
    return this.httpClient.execute(options);
  }

  /**
   * GET 请求
   */
  get(url: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.httpClient.get(url, headers);
  }

  /**
   * POST 请求
   */
  post(url: string, body?: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.httpClient.post(url, body, headers);
  }

  /**
   * PUT 请求
   */
  put(url: string, body?: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.httpClient.put(url, body, headers);
  }

  /**
   * DELETE 请求
   */
  delete(url: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.httpClient.delete(url, headers);
  }

  /**
   * HEAD 请求
   */
  async head(url: string, headers?: Record<string, string | string[]>): Promise<HttpResponseAdapter> {
    return this.httpClient.execute({ url, method: HttpMethod.HEAD, headers });
  }

  /**
   * 取消进行中的请求
   */
  cancel(): void {
    this.httpClient.destroy();
  }

  /**
   * 关闭会话
   */
  close(): void {
    this.httpClient.destroy();
  }
}
