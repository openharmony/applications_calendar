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

import { CityTimeZone } from '@app/common';
import { Service } from '@app/common/src/main/ets/service/framework/Service';

/**
 * TimeZoneService
 */
export abstract class TimeZoneService extends Service {
  public abstract isTimeZoneLocked(): boolean;

  public abstract getLockedTimeZone(): string;

  public abstract getTimeZoneList(): CityTimeZone[];

  public abstract updateLockTimeZoneSwitch(lockTimeZoneSwitch: boolean): Promise<boolean>;

  public abstract updateLockedTimeZone(timeZone: string): Promise<boolean>;

  public abstract updateTimeZoneList(language: string): Promise<boolean>;

  public abstract refreshSpLockTimeZoneToRemoteDb(): Promise<boolean>;

  public abstract getIsSupportLockTimeZone(): boolean;
}