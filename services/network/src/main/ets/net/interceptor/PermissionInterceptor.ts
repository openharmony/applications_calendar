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
import { BaseInterceptor } from './BaseInterceptor';
import { HttpRequestContext, HttpRequestHandler, HttpResponseAdapter } from '../HttpClient';
import { Log } from '@app/common/src/main/ets/default/common/Log';

/**
 * PermissionChecker
 */
export interface PermissionChecker {
  isEnableExecuteRequest(context: HttpRequestContext): boolean;
}

const TAG = 'RequestEngine_PermissionInterceptor';

/**
 * PermissionInterceptor
 */
export class PermissionInterceptor extends BaseInterceptor {
  private permissionChecker: PermissionChecker;

  constructor(prefixTag: string, permissionChecker: PermissionChecker) {
    super(prefixTag);
    this.permissionChecker = permissionChecker;
  }

  async intercept(context: HttpRequestContext, next: HttpRequestHandler): Promise<HttpResponseAdapter> {
    if (!this.permissionChecker.isEnableExecuteRequest(context)) {
      Log.warn(this.logTag, `request id ${context.request.id} no permission`);
      const error: BusinessError = {
        code: ErrorCode.ILLEGAL_CODE,
        message: `permissionChecker fail,can not execute request`,
        name: 'BusinessError'
      };
      throw error as Error;
    }
    return next.handle(context);
  }

  protected getLogTag(): string {
    return TAG;
  }
}