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

import { Log } from '@app/common';
import dataShare from '@ohos.data.dataShare';

const TAG: string = 'RegisterDataShareHelperUtils';

const PROXY_URI: string = 'datashareproxy://com.ohos.calendardata';
const PROXY_URI_CALENDAR: string = PROXY_URI + '/Calendars';
const RETRY_INTERVAL_MS: number = 1000; // retry interval
const MAX_RETRY_TIMES: number = 5; // dataShare max retry times
const dsOptions: dataShare.DataShareHelperOptions = {
  isProxy: true
};

/**
 * 卡片在数据代理注册
 */
async function registerDataShareHelper(context: Context, subscriberId: string,
                                       template: dataShare.Template, retryTimes: number): Promise<void> {
  if (retryTimes <= 0) {
    Log.error(TAG, 'no retry times');
    return;
  }
  try {
    dataShare.createDataShareHelper(context, PROXY_URI, dsOptions).then((dataShareHelper) => {
      if (dataShareHelper) {
        Log.info(TAG, 'DataShare createDataShareHelper, subscriberId ' + subscriberId);
        dataShareHelper.addTemplate(PROXY_URI_CALENDAR, subscriberId, template);
        Log.info(TAG, `addTemplate ${subscriberId} success!`);
      } else {
        Log.error(TAG, `addTemplate ${subscriberId} failed, dataShareHelper is null!`);
      }
    }).catch((err: Error) => {
      Log.error(TAG, `addTemplate create DataShare error: ${err?.message}`);
      setTimeout(registerDataShareHelper.bind(null, context, subscriberId,
        template, retryTimes - 1), RETRY_INTERVAL_MS);
    });
  } catch (err) {
    Log.error(TAG, `addTemplate getErr: ${err?.message}`);
    setTimeout(registerDataShareHelper.bind(null, context, subscriberId,
      template, retryTimes - 1), RETRY_INTERVAL_MS);
  }
}

/**
 * 删除卡片数据代理
 */
async function delAndAddDataShareHelper(context: Context, subscriberId: string,
                                        template: dataShare.Template, retryTimes: number): Promise<void> {
  if (retryTimes <= 0) {
    Log.error(TAG, 'no retry times');
    return;
  }
  try {
    dataShare.createDataShareHelper(context, PROXY_URI, dsOptions).then((dataShareHelper) => {
      if (dataShareHelper) {
        Log.info(TAG, `formId: ${subscriberId} createDataShareHelper delDataShareHelper, success!`);
        dataShareHelper.delTemplate(PROXY_URI_CALENDAR, subscriberId);
        Log.info(TAG, 'createDataShareHelper addDataShareHelper, success!');
        dataShareHelper.addTemplate(PROXY_URI_CALENDAR, subscriberId, template);
      } else {
        Log.error(TAG, 'delDataShareHelper  init dataShareHelper failed and dataShareHelper is null!');
      }
    }).catch((err: Error) => {
      Log.error(TAG, `delDataShareHelper  init orientation settings DataShare delTemplate error: ${err?.message}`);
      setTimeout(registerDataShareHelper.bind(null, context, subscriberId,
        template, retryTimes - 1), RETRY_INTERVAL_MS);
    });
  } catch (err) {
    Log.error(TAG, `delDataShareHelper  init orientation settings DataShare delTemplate catch error: ${err?.message}`);
    setTimeout(registerDataShareHelper.bind(null, context, subscriberId,
      template, retryTimes - 1), RETRY_INTERVAL_MS);
  }
}

export { PROXY_URI, PROXY_URI_CALENDAR, MAX_RETRY_TIMES, registerDataShareHelper, delAndAddDataShareHelper, dsOptions }