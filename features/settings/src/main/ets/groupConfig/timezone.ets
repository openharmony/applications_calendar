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

import { CompId, GlobalData, I18nUtil, Log, ServiceEnum, ServiceManager, ThrottleFunction } from '@app/common';
import { eventAction, IsSettingData } from './declare';
import settingKeys from '../settingKeys';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';
import { TimeZoneService } from '@app/service.timezone'

const TAG = 'timezone';

/**
 * 设置 - 时区
 * 锁定时区
 * 时区
 *
 * @since 2022-07-25
 */
const timezone: IsSettingData = {
  groupName: $r('app.string.edit_event_timezone_label'),
  compId: CompId.SETTING_TIMEZONE,
  hide: false,
  items: [
    {
      compId: CompId.SETTINGS_LOCK_TIME_ZONE,
      title: $r('app.string.preferences_lock_time_zone'),
      description: $r('app.string.preferences_lock_time_zone_description'),
      action: eventAction.SWITCH,
      settingKey: settingKeys.isTimeZoneLocked,
      defaultVal: 0,
      onMounted() {
        const isOn: boolean = this.isToggleOn;
        setTimeZoneVisibleState(isOn);
      },
      event(isOn: boolean) {
        setTimeZoneVisibleState(isOn);
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(() => {
          updateLockTimeZoneSwitch(isOn);
          updateTimeZone(isOn);
        }, 400);
      }
    },
    {
      compId: CompId.SETTINGS_TIME_ZONE,
      title: $r('app.string.edit_event_timezone_label'),
      action: eventAction.ROUTER,
      settingKey: settingKeys.lockedTimeZone,
      defaultVal: '',
      event() {
      }
    }
  ],
};


/**
 * 设置时区设置项的显示隐藏状态
 *
 * @param isOn 锁定时区的开关状态
 */
function setTimeZoneVisibleState(isOn: boolean) {
  isOn ? GlobalData.instance().removeHiddenItem(settingKeys.lockedTimeZone) : GlobalData.instance()
    .addHiddenItem(settingKeys.lockedTimeZone);
}

async function updateLockTimeZoneSwitch(inOn: boolean) {
  const service = await ServiceManager.getInstance()
    .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
  if (!service) {
    Log.warn(TAG, `updateLockTimeZoneSwitch server is null`);
    return;
  }
  await service.updateLockTimeZoneSwitch(inOn);
}

async function updateTimeZone(isOn: boolean): Promise<boolean> {
  const service = await ServiceManager.getInstance()
    .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
  if (!service) {
    Log.warn(TAG, `updateTimeZone server is null`);
    return false;
  }
  const lockTimeZone = await service.getLockedTimeZone();
  let isSaveTimeZone: boolean = false;
  if (isOn && !lockTimeZone) {
    const timeZoneId = I18nUtil.getSystemTimeZone();
    isSaveTimeZone = await service.updateLockedTimeZone(timeZoneId);
  }
  return isSaveTimeZone;
}

objectFreeze(timezone);

export default timezone;
