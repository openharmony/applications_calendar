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

import { BusinessError } from '@ohos.base';
import { ErrorCode } from '@app/common/src/main/ets/commoncapability/error/ErrorCode';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import lazy { http } from '@kit.NetworkKit';
import { BaseInterceptor } from './BaseInterceptor';
import { HttpRequestContext, HttpRequestHandler, HttpResponseAdapter } from '../HttpClient';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG = 'RequestEngine_ResponseInterceptor';

/**
 * ResponseInterceptor
 */
export class ResponseInterceptor extends BaseInterceptor {
  constructor(prefixTag: string) {
    super(prefixTag);
  }

  private isResponseCodeOK(response: HttpResponseAdapter): boolean {
    return response.statusCode >= http.ResponseCode.OK && response.statusCode < http.ResponseCode.BAD_REQUEST;
  }

  protected getLogTag(): string {
    return TAG;
  }

  async intercept(context: HttpRequestContext, next: HttpRequestHandler): Promise<HttpResponseAdapter> {
    let response: HttpResponseAdapter = await next.handle(context);
    if (EmptyUtils.isUndefinedOrNull(response)) {
      Log.warn(this.logTag, `request id ${context.request.id} response is null`);
      const error: BusinessError = {
        code: ErrorCode.ILLEGAL_CODE,
        message: `response is null`,
        name: 'BusinessError'
      };
      throw error as Error;
    }
    if (!this.isResponseCodeOK(response)) {
      Log.warn(this.logTag, `request id ${context.request.id} response code not ok`);
      const error: BusinessError = {
        code: response.statusCode,
        message: `response code not ok`,
        name: 'BusinessError'
      };
      throw error as Error;
    }
    return response;
  }
}