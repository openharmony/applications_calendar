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
// @ts-ignore
import call from '@ohos.telephony.call';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { Log } from '../../default/common/Log';

const TAG: string = 'TelephoneCallWrapper';

export class TelephoneCallWrapper {
  static async makeCall(phoneNumber: string, callback: AsyncCallback<void>): Promise<void> {
    Log.info(TAG, 'MakeCall enter');
    if (!call.hasVoiceCapability()) {
      Log.log(TAG, 'not support voice capability, return.');
      return;
    }
    call.makeCall(phoneNumber, callback);
  }

  static hasVoiceCapability(): boolean {
    Log.info(TAG, 'hasVoiceCapability enter');
    return call.hasVoiceCapability();
  }
}
