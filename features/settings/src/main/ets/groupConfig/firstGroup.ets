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

import { eventAction, ISettingItem, IsSettingData } from './declare';
import {
  CompId,
  CommonInnerEvent,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  FeatureType,
  I18nUtil,
  Log,
  ServiceEnum,
  ServiceManager
} from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import settingKeys from '../settingKeys';
import { Calendars } from '../data/calendar/CalendarConfig';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';

const TAG = 'firstGroup';
const IMPORTANT_DAY_SWITCH_REFRESH_DELAY: number = 200;
let importantDayRefreshTimer: number = -1;

/**
 * 设置
 * 其他历法
 * 国家（地区）节日
 * 天气预报
 * 同步代办
 * 重要日
 * 订阅服务
 *
 * @since 2022-07-25
 */

function firstGroupISettingItemConfig(): ISettingItem[] {
  let isSupportSubscription: boolean = DeviceConfig.instance().isSupport(FeatureType.SUBSCRIPTION);
  let iSettingItemTemp: ISettingItem[] = [
    {
      compId: CompId.SETTINGS_CALENDAR,
      title: $r('app.string.subscription_calendar'),
      action: eventAction.DIALOG,
      settingKey: settingKeys.subscriptionCalendar,
      defaultVal: Calendars.CALENDAR_CHINESE_LUNAR
    },
    {
      compId: CompId.SETTINGS_IMPORTANT_DAYS,
      title: $r('app.string.important_day'),
      description: $r('app.string.important_day_switch_details'),
      action: eventAction.SWITCH,
      settingKey: 'SHOW_IMPORTANT_DAY',
      defaultVal: 1,
      syncState(isOn: boolean) {
        GlobalData.instance().set(GlobalDataKeys.IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW, !!isOn);
      },
      event(isOn: boolean) {
        GlobalData.instance().set(GlobalDataKeys.IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW, !!isOn);
        if (importantDayRefreshTimer >= 0) {
          clearTimeout(importantDayRefreshTimer);
        }
        const eventData: emitter.EventData = {
          data: {
            'updateData': true,
            'showImportantDay': !!isOn,
          }
        };
        importantDayRefreshTimer = setTimeout(() => {
          emitter.emit({ eventId: CommonInnerEvent.EVENT_MAIN_PAGE_UPDATE_DATA }, eventData);
          importantDayRefreshTimer = -1;
        }, IMPORTANT_DAY_SWITCH_REFRESH_DELAY);
      },
    }
  ]
  return iSettingItemTemp;
}

const firstGroup: IsSettingData = {
  groupName: $r('app.string.menu_preferences'),
  compId: CompId.SETTING_FIRST_GROUP,
  items: firstGroupISettingItemConfig()
};

objectFreeze(firstGroup);

export default firstGroup;
