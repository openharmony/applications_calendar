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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { BaseInterceptor } from './BaseInterceptor';
import { HttpRequestContext, HttpRequestHandler, HttpResponseAdapter } from '../HttpClient';

const TAG = 'RequestEngine_LogInterceptor';

/**
 * LogInterceptor
 */
export class LogInterceptor extends BaseInterceptor {
  constructor(prefixTag: string) {
    super(prefixTag);
  }

  async intercept(context: HttpRequestContext, next: HttpRequestHandler): Promise<HttpResponseAdapter> {
    const request = context.request;
    Log.info(this.logTag, `request id is ${request.id} method is ${request.method}`);
    try {
      const response = await next.handle(context);
      Log.info(this.logTag, `response id is ${request.id} resultCode is ${response.statusCode}`);
      return response;
    } catch (error) {
      Log.logErrorMsg(this.logTag, `request id is ${request.id}`, error);
      throw error as Error;
    }
  }

  protected getLogTag(): string {
    return TAG;
  }
}