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

import {
  CompId,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPathManager,
  NavPathName,
  RouterName
} from '@app/common';
import { eventAction, IsSettingData } from './declare';
import settingKeys from '../settingKeys';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';
import { notificationManager } from '@kit.NotificationKit';

const TAG: string = 'ReminderSetting';

/**
 * 设置 - 提醒
 * 通知
 * 默认提醒时间
 * 全天事件默认提醒时间
 *
 * @since 2022-07-25
 */
const remind: IsSettingData = {
  groupName: $r('app.string.preferences_reminder_title'),
  compId: CompId.REMINDER_SETTINGS,
  items: [
    {
      compId: CompId.SETTINGS_NOTIFICATION,
      title: $r('app.string.preferences_alerts_title'),
      action: eventAction.ROUTER,
      hide: shouldHideAlertsSetting(),
      event: () => {
        popAlertSettingsDialog();
      }
    },
    
    {
      compId: CompId.SETTINGS_DEFAULT_REMINDER_TIME,
      title: $r('app.string.preferences_default_reminder_title'),
      action: eventAction.DIALOG,
      settingKey: settingKeys.defaultRemindTime,
      defaultVal: 10,
      syncState(val: number) {
        GlobalData.instance().set(GlobalDataKeys.DEFAULT_REMIND_TIME, val);
      }
    },
    {
      compId: CompId.SETTINGS_REMINDER_TIME_FOR_ALLDAY_EVENT,
      title: $r('app.string.eu3_cl_ab_settings_alldayeventremindertime'),
      action: eventAction.DIALOG,
      settingKey: settingKeys.allDayEventsDefaultRemindTime,
      defaultVal: 0,
      syncState(val: number) {
        GlobalData.instance().set(GlobalDataKeys.ALL_DAY_EVENTS_DEFAULT_REMIND_TIME, val);
      }
    }
  ],
};

function shouldHideAlertsSetting(): boolean {
  return !canIUse('SystemCapability.Notification.NotificationSettings');
}

function popAlertSettingsDialog() {
  const context = GlobalThis.getInstance().mainAbilityContext;
  if (context) {
    notificationManager.openNotificationSettings(context);
  } else {
    Log.warn(TAG, 'popAlertSettingsDialog get invalid context');
  }
}

objectFreeze(remind);

export default remind;
