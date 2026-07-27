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
import { Result } from '../../templates/Result';
import { LockTimeZoneInfo } from '../model/LockTimeZoneInfo';
import { CalendarCacheRepository } from '../repo/CalendarCacheRepository';
import { LockTimeZoneRepository } from '../repo/LockTimeZoneRepository';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Log } from '../../default/common/Log';
import { EmptyUtils } from '../../util/EmptyUtils';
import { PreferencesUtil } from '../../default/util/preferences_util/PreferencesUtil';
import { CalendarCache } from '../model/CalendarCache';

const TAG = 'CalendarCacheService';

const CALENDAR_CACHE_KEY_DB_REPAIR_SWITCH: string = 'db_repair_feature_switch';

// sp缓存文件名
const SP_FILE: string = 'CalendarCacheService';

// sp中的key名，上次的开关值，用于控制开关值变化时重新init
const KEY_LAST_DB_REPAIR_SWITCH: string = 'last_db_repair_switch_value';

// 数据库db对账特性开关，主干默认开启
const DB_REPAIR_SWITCH: boolean = true;

/*
 * CalendarCacheService
 */
export class CalendarCacheService {
  private static sInstance: CalendarCacheService;
  private readonly repo: CalendarCacheRepository;
  private readonly timeZoneRepository: LockTimeZoneRepository;

  private constructor() {
    this.repo = new CalendarCacheRepository();
    this.timeZoneRepository = new LockTimeZoneRepository();
  }

  static getInstance(): CalendarCacheService {
    if (!CalendarCacheService.sInstance) {
      CalendarCacheService.sInstance = new CalendarCacheService();
    }
    return CalendarCacheService.sInstance;
  }

  /**
   * 查询锁定时区开关信息
   * @returns
   */
  async queryLockTimeZoneSwitchInfo(): Promise<Result<LockTimeZoneInfo | undefined>> {
    const columns = [CalendarContract.CalendarCacheColumns.KEY, CalendarContract.CalendarCacheColumns.VALUE];
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.CalendarCacheColumns.KEY, CalendarContract.LockTimeZoneKeys.TIMEZONE_TYPE)
    const result: Result<LockTimeZoneInfo[]> = await this.timeZoneRepository
      .queryByCondition(predicates, false, columns);
    if (!result.isSuccess()) {
      Log.warn(TAG, `queryLockTimeZoneInfo error ${result.toString()}`);
      return Result.copyResult(result, undefined);
    }
    const lockTimeZoneInfos = result.data;
    if (lockTimeZoneInfos.length > 1) {
      Log.warn(TAG, `queryLockTimeZoneInfo error LockTimeZoneInfo length is ${lockTimeZoneInfos.length} illegal`);
    }
    if (EmptyUtils.isEmptyArray(lockTimeZoneInfos)) {
      Log.info(TAG, `queryLockTimeZoneInfo no LockTimeZoneInfo`);
    }
    return Result.buildSuccessResult(EmptyUtils.isEmptyArray(lockTimeZoneInfos) ? undefined : lockTimeZoneInfos[0]);
  }

  /**
   * 查询当前锁定的时区
   * @returns
   */
  async queryLockedTimeZone(): Promise<Result<LockTimeZoneInfo[]>> {
    const columns = [CalendarContract.CalendarCacheColumns.KEY, CalendarContract.CalendarCacheColumns.VALUE];
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.CalendarCacheColumns.KEY,
      CalendarContract.LockTimeZoneKeys.CURRENT_LOCKED_TIME_ZONE);
    const result: Result<LockTimeZoneInfo[]> = await this.timeZoneRepository
      .queryByCondition(predicates, false, columns);
    return result;
  }

  async insertLockedTimeZone(model: LockTimeZoneInfo): Promise<Result<number>> {
    const result = await this.timeZoneRepository.insertItem(model);
    if (!result.isSuccess()) {
      Log.warn(TAG, `insertLockedTimeZone error ${result.toString()}`);
    }
    Log.info(TAG, `insertLockedTimeZone success id is ${result.data}`);
    return result;
  }

  /**
   * 通过key查询CalendarCache
   * @returns { Result<CalendarCache | undefined> }
   */
  async queryCacheItem(key: string): Promise<Result<CalendarCache | undefined>> {
    const columns = [CalendarContract.CalendarCacheColumns.KEY, CalendarContract.CalendarCacheColumns.VALUE];
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.CalendarCacheColumns.KEY, key);
    const result = await this.repo.queryOneByCondition(predicates, false, columns);
    return result;
  }

  async insertLockTimeZoneSwitchInfo(model: LockTimeZoneInfo): Promise<Result<number>> {
    const result = await this.timeZoneRepository.insertItem(model);
    if (!result.isSuccess()) {
      Log.error(TAG, `insertLockTimeZoneSwitchInfo error ${result.toString()}`);
    }
    Log.info(TAG, `insertLockTimeZoneSwitchInfo success id is ${result.data}`);
    return result;
  }


  async updateLockedTimeZone(model: LockTimeZoneInfo, includeColumns?: string[], excludeColumns?: string[])
    : Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.CalendarCacheColumns.KEY,
      CalendarContract.LockTimeZoneKeys.CURRENT_LOCKED_TIME_ZONE);
    const result = await this.timeZoneRepository
      .updateByCondition(predicates, model, includeColumns, excludeColumns);
    if (!result.isSuccess()) {
      Log.error(TAG, `updateLockedTimeZone error ${result.toString()}`);
    }
    Log.info(TAG, `updateLockedTimeZone success count is ${result.data}`);
    return result;
  }

  async updateLockTimeZoneSwitchInfo(model: LockTimeZoneInfo,
                                     includeColumns?: string[],
                                     excludeColumns?: string[]): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.CalendarCacheColumns.KEY, CalendarContract.LockTimeZoneKeys.TIMEZONE_TYPE);
    const result = await this.timeZoneRepository
      .updateByCondition(predicates, model, includeColumns, excludeColumns);
    if (!result.isSuccess()) {
      Log.error(TAG, `updateLockTimeZoneSwitchInfo error ${result.toString()}`);
    }
    Log.info(TAG, `updateLockTimeZoneSwitchInfo success count is ${result.data}`);
    return result;
  }

  async tryInitDbRepairSwitch(): Promise<void> {
    if (!this.isNeedInit()) {
      return;
    }
    Log.warn(TAG, 'initDbRepairSwitch called');
    const isSuccess = await this.repo.setCalendarCache(CALENDAR_CACHE_KEY_DB_REPAIR_SWITCH, `${DB_REPAIR_SWITCH}`);

    if (isSuccess) {
      // 记录上次init设置的值
      PreferencesUtil.putBooleanValueSync(SP_FILE, KEY_LAST_DB_REPAIR_SWITCH, DB_REPAIR_SWITCH);
    }
  }

  private isNeedInit(): boolean {
    const lastValue = PreferencesUtil.getBooleanValueSync(SP_FILE, KEY_LAST_DB_REPAIR_SWITCH, false);
    return lastValue !== DB_REPAIR_SWITCH;
  }
}