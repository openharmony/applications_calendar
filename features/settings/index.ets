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

/* instrument ignore file */

import { Log, NavPathName } from '@app/common';

import settingKeys from './src/main/ets/settingKeys';

export { settingKeys };

export { SettingStore } from './src/main/ets/Storage';

export { SettingRootViewModel } from './src/main/ets/SettingRoot'

export { currentSupportCalendars, Calendars, CalendarsArray } from './src/main/ets/data/calendar/CalendarConfig';

export { TimeZonePage } from './src/main/ets/routerPages/TimeZonePage';

// Note: Switch 优化为表驱动，会导致import失效！
export function harInit(builderName: string): boolean {
  Log.info('setting', `harInit ${builderName}`);
  switch (builderName) {
    case NavPathName.SETTING_MAIN:
      import('./src/main/ets/SettingRoot');
      break;
    case NavPathName.SETTING_ABOUT:
      import('./src/main/ets/routerPages/AboutPage');
      break;
    case NavPathName.APP_DISPLAY_RECORD_DETAIL:
      import('./src/main/ets/routerPages/RecordDetail');
      break;
    case NavPathName.SETTINGS_TIME_ZONE:
      import('./src/main/ets/routerPages/TimeZonePage');
      break;
    default:
      return false;
  }
  return true;
}