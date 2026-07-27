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

import { ArkTSUtils } from '@kit.ArkTS';

// 共享模块
'use shared'

@Sendable
export class CommonStatusHelper {
  private tag: string = 'CommonStatusHelper';
  public static readonly INSTANCE: CommonStatusHelper = new CommonStatusHelper();
  private isFirstCheckExceptionAccount: boolean = true;
  private lock_: ArkTSUtils.locks.AsyncLock = new ArkTSUtils.locks.AsyncLock();

  public getIsFirstCheckExceptionAccount() {
    return this.isFirstCheckExceptionAccount;
  }

  public setIsFirstCheckExceptionAccount(status: boolean) {
    this.isFirstCheckExceptionAccount = status;
  }
}