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

import { Log } from '../../default/common/Log';
import { DBUtils } from '../DBUtils';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Result } from '../../templates/Result';
import { EmptyUtils } from '../../util/EmptyUtils';
import { InnerResultSet } from '../util/InnerResultSet';
import { CalendarAccountType } from '../../account/AccountConst';

const TAG = 'CalendarRepository';

export class CalendarRepository {
  private readonly QUERY_CALENDAR_PROJECTIONS: Array<string> = [
    CalendarContract.BaseColumns.ID,
    CalendarContract.SyncColumns.ACCOUNT_NAME,
    CalendarContract.SyncColumns.ACCOUNT_TYPE,
    CalendarContract.AccountColumns.NAME,
    CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME,
    CalendarContract.AccountColumns.CALENDAR_COLOR,
    CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL,
    CalendarContract.AccountColumns.VISIBLE,
    CalendarContract.AccountColumns.CAN_REMINDER,
    CalendarContract.AccountColumns.CREATOR,
    CalendarContract.AccountSyncColumns.CAL_SYNC1,
    CalendarContract.AccountSyncColumns.CAL_SYNC2,
    CalendarContract.AccountSyncColumns.CAL_SYNC3,
    CalendarContract.AccountSyncColumns.CAL_SYNC4,
    CalendarContract.AccountSyncColumns.CAL_SYNC5,
    CalendarContract.AccountSyncColumns.CAL_SYNC6,
    CalendarContract.AccountSyncColumns.CAL_SYNC7,
    CalendarContract.AccountSyncColumns.CAL_SYNC8,
    CalendarContract.AccountColumns.UUID
  ];

  /**
   * 查询calendarId 对应的日历账户
   *
   * @return 对应的日历账户
   */
  async queryCalendarById(calendarId: number): Promise<InnerResultSet | undefined> {
    const tag = 'queryCalendarById';
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.BaseColumns.ID, calendarId);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.CALENDARS,
      predicates, this.QUERY_CALENDAR_PROJECTIONS, tag);
  }

  /**
   * 根据AccountName查询日历账户id
   * @param accountName 账户名称
   * @returns 账户id
   */
  async queryCalendarByName(accountName: string[]): Promise<InnerResultSet | undefined> {
    const tag = 'queryCalendarIDByName';
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.AccountColumns.ACCOUNT_NAME, accountName);
    predicates.and().equalTo(CalendarContract.AccountColumns.ACCOUNT_TYPE, CalendarAccountType.HOLIDAY_ACCOUNT_TYPE);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.CALENDARS,
      predicates, this.QUERY_CALENDAR_PROJECTIONS, tag);
  }

  /**
   * 查询所有Calendars 信息
   *
   * @return 查询的日程结果集合
   */
  async queryCalendars(): Promise<InnerResultSet | undefined> {
    const tag = 'queryCalendars';
    const predicates = new dataSharePredicates.DataSharePredicates();
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.CALENDARS,
      predicates, this.QUERY_CALENDAR_PROJECTIONS, tag);
  }

  /**
   * add Calendar
   *
   * @param calendar 入参
   * @returns 结果
   */
  async insertCalendar(calendar: ValuesBucket, uri?: string): Promise<number> {
    return DBUtils.INSTANCE.insert(uri ?? DBUtils.INSTANCE.URI_CALENDAR, calendar, TAG)
  }

  /**
   * delete by id
   *
   * @param calendarId id
   * @returns result
   */
  async deleteCalendarById(calendarId: number): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.BaseColumns.ID, calendarId);
    return DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_CALENDAR, predicates, TAG);
  }

  /**
   * update by id
   *
   * @param calendarId id
   * @param calendarUpdate information
   * @returns result
   */
  async updateCalendarById(calendarId: number, calendarUpdate: ValuesBucket, uri?: string): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.BaseColumns.ID, calendarId);
    return DBUtils.INSTANCE.update(uri ?? DBUtils.INSTANCE.URI_CALENDAR, predicates, calendarUpdate, TAG);
  }


  async deleteCalendarByIds(calendarIds: number[]): Promise<number> {
    if (EmptyUtils.isEmptyArray(calendarIds)) {
      Log.error(TAG, 'deleteCalendarByIds ids is empty');
      return -1;
    }
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.BaseColumns.ID, calendarIds);
    return DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_CALENDAR, predicates, TAG);
  }

  async deleteCalendarByUuids(calendarUuids: string[]): Promise<Result<number>> {
    if (EmptyUtils.isEmptyArray(calendarUuids)) {
      Log.warn(TAG, 'deleteCalendarByUuids ids is empty');
      return Result.buildSuccessResult(0);
    }
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.AccountColumns.UUID, calendarUuids);
    return DBUtils.INSTANCE.deleteData(DBUtils.INSTANCE.URI_CALENDAR, predicates, TAG);
  }

  /**
   * queryCalendarByCondition
   *
   * @return 对应的日历账户
   */
  async queryCalendarByCondition(predicates: dataSharePredicates.DataSharePredicates, columns?: string[])
    : Promise<InnerResultSet | undefined> {
    const oriResultSet = await DBUtils.INSTANCE
      .query(CalendarContract.Tables.CALENDARS, predicates, columns ?? this.QUERY_CALENDAR_PROJECTIONS, TAG);
    if (!oriResultSet) {
      return undefined;
    }
    return new InnerResultSet(oriResultSet, 'queryCalendarByCondition');
  }
}