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
import { CalendarCache } from '../model/CalendarCache';
import { BaseModelConverter } from '../modelconverter/BaseModelConverter';
import { BaseRepository } from './BaseRepository';
import { DBUtils } from '../DBUtils';
import { InnerResultSet } from '../util/InnerResultSet';
import { Log } from '../../default/common/Log';
import { dataSharePredicates, ValuesBucket } from '@kit.ArkData';

const TAG = 'CalendarCacheRepository';

/*
 * CalendarCacheRepository
 */
export class CalendarCacheRepository extends BaseRepository<CalendarCache> {
  constructor() {
    super(CalendarContract.Tables.CALENDAR_CACHE,
      new BaseModelConverter(CalendarContract.Tables.CALENDAR_CACHE, CalendarCache.prototype, 'CalendarCacheParser', CalendarCache));
  }

  public async setCalendarCache(key: string, value: string): Promise<boolean> {
    const tag = 'setCalendarCache';
    const isKeyExists = await this.isHasCalendarCacheKey(key);
    const valueBucket = {} as ValuesBucket;
    valueBucket['key'] = key;
    valueBucket['value'] = value;
    if (isKeyExists) {
      const predicate = new dataSharePredicates.DataSharePredicates();
      predicate.equalTo('key', key);
      const count = await DBUtils.INSTANCE.update(DBUtils.INSTANCE.URI_CALENDAR_CACHE, predicate, valueBucket, tag);
      return count > 0;
    } else {
      const id = await DBUtils.INSTANCE.insert(DBUtils.INSTANCE.URI_CALENDAR_CACHE, valueBucket, tag);
      return id >= 0;
    }
  }

  private async isHasCalendarCacheKey(key: string): Promise<boolean> {
    const tag = 'isHasCalendarCacheKey';
    const predicate = new dataSharePredicates.DataSharePredicates();
    predicate.equalTo('key', key);
    let resultSet: InnerResultSet | undefined = undefined;
    try {
      const table = CalendarContract.Tables.CALENDAR_CACHE;
      // 因存储对CalendarCache配置的权限是READ_CALENDAR，日历静默查询不到数据所以直接走非静默
      resultSet = await DBUtils.INSTANCE.query(table, predicate, ['value'], tag, false);
      if (!resultSet) {
        Log.error(TAG, 'isHasCalendarCacheKey get invalid resultSet');
        return false;
      }
      return resultSet.rowCount > 0;
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryCalendarCache', err);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return false;
  }
}