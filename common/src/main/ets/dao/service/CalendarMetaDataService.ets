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
import { Log } from '../../default/common/Log';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import { CalendarMetaDataRepository } from '../repo/CalendarMetaDataRepository';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';

const TAG = 'CalendarMetaDataService';

export class CalendarMetaDataService {
  public static readonly INSTANCE: CalendarMetaDataService = new CalendarMetaDataService();
  private readonly dao: CalendarMetaDataRepository = CalendarMetaDataRepository.INSTANCE;

  private constructor() {
  }

  /**
   * 查询某一个日程对应的与会人 Attendee 详情
   *
   * @param eventId 日程id
   */
  async query(): Promise<CalendarContract.CalendarMetaData> {
    Log.info(TAG, `query CalendarMetaData`);
    let metaData = new CalendarContract.CalendarMetaData;
    const columnArray = [
      CalendarContract.CalendarMetaDataColumns.MIN_INSTANCE,
      CalendarContract.CalendarMetaDataColumns.MAX_INSTANCE,
    ];
    const resultSet = await this.dao.query(columnArray);

    if (!resultSet) {
      Log.warn(TAG, `resultSet is unll`);
      return metaData;
    }
    try {
      if (resultSet.rowCount <= 0) {
        Log.warn(TAG, `resultSet is empty`);
        return metaData;
      }
      if (!resultSet.goToFirstRow()) {
        return metaData;
      }
      metaData.minInstance = DataShareResultUtil.getColumnLongData(
        resultSet, CalendarContract.CalendarMetaDataColumns.MIN_INSTANCE, 0);
      metaData.maxInstance = DataShareResultUtil.getColumnLongData(
        resultSet, CalendarContract.CalendarMetaDataColumns.MAX_INSTANCE, 0);
    } catch (err) {
      Log.logErrorMsg(TAG, 'query CalendarMetaData error', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return metaData;
  }
}