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

import firstGroup from './firstGroup';
import calendarView from './calendarView';
import timezone from './timezone';
import remind from './remind';
import about from './about';
import network from './network';
import { IsSettingData } from './declare';
import { TimeZoneService } from '@app/service.timezone';
import { ServiceEnum, ServiceManager } from '@app/common';

/**
 * 设置项
 */
export class SettingData {
  private static sSettingData: IsSettingData[] | undefined = undefined;

  /**
   * 获取SettingData 数组
   * @returns
   */
  static async getSettingData(): Promise<IsSettingData[]> {
    if (SettingData.sSettingData !== undefined) {
      return SettingData.sSettingData;
    }
    SettingData.sSettingData = [firstGroup, calendarView,
      remind, about, network];
    return SettingData.sSettingData;
  }

  static async checkLockTimeZoneSettingSupport(mSettingData: IsSettingData[]): Promise<IsSettingData[]> {
    const timeZoneService = await ServiceManager.getInstance().
      getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
    if (timeZoneService?.getIsSupportLockTimeZone()) {
      // 返回新数组，避免重复添加时区项
      return mSettingData.slice(0, 2).concat(timezone).concat(mSettingData.slice(2));
    }
    return mSettingData;
  }
}

