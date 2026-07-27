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

import { HttpInterceptor, HttpRequestContext, HttpRequestHandler, HttpResponseAdapter } from '../HttpClient';

/**
 * BaseInterceptor — 拦截器抽象基类（使用 HttpClient 类型，替代 rcp.Interceptor）
 */
export abstract class BaseInterceptor implements HttpInterceptor {
  protected readonly prefixTag: string;
  protected readonly logTag: string;

  constructor(prefixTag: string) {
    this.prefixTag = prefixTag;
    this.logTag = prefixTag + '_' + this.getLogTag();
  }

  abstract intercept(context: HttpRequestContext, next: HttpRequestHandler): Promise<HttpResponseAdapter>;

  protected abstract getLogTag(): string;
}