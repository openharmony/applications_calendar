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

import { CompId, Log } from '@app/common';
import { eventAction, IsSettingData } from './declare';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';
import { AsyncCallback } from '@kit.BasicServicesKit';

const TAG: string = 'Help and Customer Service';

/**
 * 设置 - 帮助与客服
 * 客服电话
 *
 * @since 2022-07-25
 */
const help: IsSettingData = {
  groupName: $r('app.string.preferences_help_title_upper'),
  compId: CompId.HELP,
  items: [
    {
      compId: CompId.SETTINGS_CUSTOMER_SERVICE_HOTLINE,
      title: $r('app.string.preferences_customer_service_title'),
      description: '950800',
      action: eventAction.ROUTER,
      event() {
        dynamicMakeCall(this.description, (err) => {
          if (!err) {
            Log.error(TAG, 'make call success.');
          } else {
            Log.logErrorMsg(TAG, 'make call fail', err);
          }
        });
      }
    }
  ],
};

async function dynamicMakeCall(phoneNumber: string, callback: AsyncCallback<void>): Promise<void> {
  let ns = await import('@app/common/src/main/ets/util/contact/telephoneCallWrapper');
  if (!ns) {
    return undefined;
  }
  let wrapper = ns.TelephoneCallWrapper;
  if (!wrapper) {
    return undefined;
  }
  return await wrapper.makeCall(phoneNumber, callback);
}

objectFreeze(help);

export default help;
