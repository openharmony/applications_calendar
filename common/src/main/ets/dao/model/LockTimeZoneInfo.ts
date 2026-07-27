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

import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Table } from '../annotation/Table';

import { CalendarCache } from './CalendarCache';

enum LockSwitchValue {
  // 锁定时区
  HOME = 'home',
  // 非锁定时区
  AUTO = 'auto'
}

/**
 * LockTimeZoneInfo
 */
@Table(CalendarContract.Tables.CALENDAR_CACHE)
export class LockTimeZoneInfo extends CalendarCache {
  static buildLockedTimeZoneInfo(lockedTimeZone: string): LockTimeZoneInfo {
    const model = new LockTimeZoneInfo();
    model.key = CalendarContract.LockTimeZoneKeys.CURRENT_LOCKED_TIME_ZONE;
    model.value = lockedTimeZone;
    return model;
  }

  static buildLockTimeZoneSwitchInfo(lockedTimeZoneSwitch: boolean): LockTimeZoneInfo {
    const model = new LockTimeZoneInfo();
    model.key = CalendarContract.LockTimeZoneKeys.TIMEZONE_TYPE;
    model.value = lockedTimeZoneSwitch ? LockSwitchValue.HOME : LockSwitchValue.AUTO;
    return model;
  }

  public isTimeZoneLocked(): boolean {
    return this.value === LockSwitchValue.HOME;
  }
}