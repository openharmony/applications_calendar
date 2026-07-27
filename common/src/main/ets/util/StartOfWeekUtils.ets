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

import { settings } from '@kit.BasicServicesKit';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';

const TAG = 'StartOfWeekUtils';

// 一周开始日写入settingData的domain名称
const SETTING_DATA_START_OF_WEEK_DOMAIN: string = 'settingDataStartOfWeekDomain';

export class StartOfWeekUtils {
  public static async setSettingsStartOfWeek(startOfWeek: number) {
    try {
      const context = GlobalThis.getInstance().context;
      if (!context) {
        Log.error(TAG, 'set settings startOfWeek context is empty');
        return;
      }
      let result: boolean = await settings.setValue(context, SETTING_DATA_START_OF_WEEK_DOMAIN, startOfWeek.toString(),
        settings.domainName.USER_PROPERTY);
      if (!result) {
        Log.error(TAG, 'set settings startOfWeek data failed');
      } else {
        Log.info(TAG, `set settings startOfWeek success ${startOfWeek}`);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'set settings startOfWeek data failed', err);
    }
  }
}