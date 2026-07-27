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

import { behaviorEvents, CommonInnerEvent, CompId, GlobalData, GlobalDataKeys, ReportUtil } from '@app/common';
import { eventAction, IsSettingData } from './declare';
import settingKeys from '../settingKeys';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';
import { HiEventParamsConfirm, ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ServiceEnum, ServiceManager } from '@app/common';
import { emitter } from '@kit.BasicServicesKit';

/**
 * 设置 - 日历视图
 * 显示周数
 * 一周开始日
 * 周末
 *
 * @since 2022-07-25
 */
const calendarView: IsSettingData = {
  groupName: $r('app.string.preferences_general_title'),
  compId: CompId.CALENDAR_VIEW_SETTINGS,
  items: [
    {
      compId: CompId.SETTINGS_SHOW_WEEK_NUMBER,
      title: $r('app.string.preferences_show_week_num_title'),
      action: eventAction.SWITCH,
      settingKey: settingKeys.showWeekNumber,
      defaultVal: 1,
      syncState(isOn: boolean) {
        GlobalData.instance().set(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON, !!isOn);
      },
      event(isOn: boolean) {
        GlobalData.instance().set(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON, !!isOn);
        emitter.emit({ eventId: CommonInnerEvent.SETTINGS_SHOW_WEEK_NUMBER });
        let params: ReportHiEventParams = {
          IS_ON: !!isOn ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.settingsWeekSwitch, params);
      },
    },
    {
      compId: CompId.SETTINGS_START_OF_WEEK,
      title: $r('app.string.preferences_week_start_day_title'),
      action: eventAction.DIALOG,
      settingKey: settingKeys.startOfWeek,
      defaultVal: -1,
      syncState(val: boolean) {
        GlobalData.instance().set(GlobalDataKeys.START_OF_WEEK, val);
      },
    },
    {
      compId: CompId.SETTINGS_WEEKENDS,
      title: $r('app.string.preferences_weekend_title'),
      action: eventAction.ROUTER,
      settingKey: settingKeys.weekends,
      defaultVal: '[-1, 0, 6]', // 以字符串数组形式存储
      syncState(val: string) {
        GlobalData.instance().set(GlobalDataKeys.WEEKENDS, JSON.parse(val));
      },
    }
  ]
};

objectFreeze(calendarView);

export default calendarView;
