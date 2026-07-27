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
import { AgendaEventInfo } from '../../agenda/AgendaEventInfo';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import { EmptyUtils } from '../../util/EmptyUtils';
import { Result } from '../../templates/Result';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';
import { InnerResultSet } from '../util/InnerResultSet';
import { GlobalThis } from '../../data/GlobalThis';
import { I18nUtil } from '../../util/I18nUtil';
import { maskString } from '../../util/SensitiveStrUtils';
import { CalendarService } from '../service/CalendarService';
import { CalendarAccountType } from '../../account/AccountConst';
import { CalendarDataFeature, CalendarDataFeatureHelper } from '../../util/CalendarDataFeatureHelper';

const TAG = 'EventRepository';

const CONTACT_BIRTHDAY_ABILITY_NAME = 'com.ohos.contactsdataability';

export class EventRepository {
  private readonly QUERY_EVENT_PROJECTION: Array<string> = [
    CalendarContract.BaseColumns.ID,
    CalendarContract.EventsColumns.TITLE,
    CalendarContract.EventsColumns.EVENT_START_TIME,
    CalendarContract.EventsColumns.EVENT_END_TIME,
    CalendarContract.EventsColumns.EVENT_LOCATION,
    CalendarContract.EventsColumns.CALENDAR_ID,
    CalendarContract.EventsColumns.ALL_DAY,
    CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
    CalendarContract.EventsColumns.EVENT_TIME_STAMP,
    CalendarContract.EventsColumns.RRULE,
    CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
    CalendarContract.EventsColumns.IDENTIFIER,
    CalendarContract.EventsColumns.START_TIMEZONE,
    CalendarContract.EventsColumns.CREATOR,
    CalendarContract.EventsColumns.CALENDAR_UUID
  ];

  // 查询所有 event， 除了节假日
  public async queryAllEvents(): Promise<InnerResultSet | undefined> {
    const tag = 'queryAllEvents';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.notEqualTo(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      CalendarContract.EventImportantType.HOLIDAY);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTSTART);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTEND);
    predicates.orderByAsc(CalendarContract.EventsColumns.ID);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates, await this.getQueryEventProjection(), tag);
  }

  // 查询所有 event， 除了节假日和联系人生日
  public async queryNormalEvents(): Promise<InnerResultSet | undefined> {
    const tag = 'queryNormalEvents';
    let predicates = new dataSharePredicates.DataSharePredicates();
    let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
    accounts = accounts.filter((item: CalendarContract.Accounts) => {
      return CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE == item.accountType ||
        CalendarAccountType.DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE == item.accountType;
    });
    accounts.forEach((item) => {
      predicates.notEqualTo(CalendarContract.EventsColumns.CALENDAR_ID,
        item.id);
    });
    predicates.notEqualTo(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      CalendarContract.EventImportantType.HOLIDAY);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTSTART);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTEND);
    predicates.orderByAsc(CalendarContract.EventsColumns.ID);
    const result: InnerResultSet | undefined = await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates, await this.getQueryEventProjection(), tag);
    return result;
  }


  // 查询所有 event
  async queryAllHolidayEvents(calendarIds?: number[]): Promise<InnerResultSet | undefined> {
    const tag = 'queryAllHolidayEvents';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      CalendarContract.EventImportantType.HOLIDAY);
    if (calendarIds && calendarIds?.length > 0) {
      predicates.in(CalendarContract.EventsColumns.CALENDAR_ID, calendarIds)
    }
    predicates.orderByAsc(CalendarContract.EventsColumns.DTSTART);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTEND);
    predicates.orderByAsc(CalendarContract.EventsColumns.ID);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates, await this.getQueryEventProjection(), tag);
  }

  async queryHolidayByTitles(titles: string[], columns?: string[]):
    Promise<InnerResultSet | undefined> {
    if (!columns) {
      columns = await this.getQueryEventProjection();
    }
    const tag = 'queryHolidayByTitles';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      CalendarContract.EventImportantType.HOLIDAY);
    predicates.and().in(CalendarContract.EventsColumns.TITLE, titles);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTSTART);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTEND);
    predicates.orderByAsc(CalendarContract.EventsColumns.ID);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates, columns, tag);
  }

  /**
   * 查询所有日程 Events 信息
   *
   * @return 查询的日程结果集合
   */
  public async queryEvents(): Promise<InnerResultSet | undefined> {
    const tag = 'queryEvents';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.orderByAsc(CalendarContract.EventsColumns.DTSTART);
    predicates.orderByAsc(CalendarContract.EventsColumns.DTEND);
    predicates.orderByAsc(CalendarContract.EventsColumns.ID);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates, await this.getQueryEventProjection(), tag);
  }

  /**
   * 根据id查询日程 Event 信息
   *
   * @return 查询的日程结果集合
   */
  async queryEventById(id: number, columns?: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventById';
    Log.info(TAG, `queryEventsByEventIds id is ${id}`);
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.ID, id);
    if (columns) {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
    } else {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
        predicates, await this.getQueryEventProjection(), tag);
    }
  }

  /**
   * 根据title查找指定节假日账户的节假日日程
   * @param title 日程title
   * @param calendarId 账户id
   * @param columns 需要返回的数据列
   * @returns title对应的节假日日程
   */
  async queryHolidayEventByTitle(title: string, calendarId: number, columns: Array<string>)
    : Promise<InnerResultSet | undefined> {
    const tag = 'queryEventByTitle';
    Log.info(TAG, `queryEventByTitle title is ${maskString(title)}`);
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      CalendarContract.EventImportantType.HOLIDAY);
    predicates.equalTo(CalendarContract.EventsColumns.CALENDAR_ID, calendarId); //限制为指定的账户
    predicates.equalTo(CalendarContract.EventsColumns.TITLE, title);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
  }

  /**
   * 根据 uuid 查询日程 Event 信息
   *
   * @return 查询的日程结果集合
   */
  async queryEventByUUID(uuid: string, columns?: Array<string>,
                         proxy: boolean = true): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventByUUID';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.UUID, uuid);
    if (columns) {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag, proxy);
    } else {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
        predicates, await this.getQueryEventProjection(), tag, proxy);
    }
  }

  /**
   * 根据ids查询多个日程 Event 信息
   *
   * @return 查询的日程结果集合
   */
  async queryEventsByUuids(
    uuids: Array<string>,
    columns?: Array<string>,
    searchText?: string
  ): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventsByIds';
    if (EmptyUtils.isEmptyArray(uuids)) {
      Log.warn(tag, 'ids is empty');
      return undefined;
    }
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates
      .in(CalendarContract.EventsColumns.UUID, uuids);
    if (searchText) {
      predicates
        .and()
        .beginWrap()
        .contains(CalendarContract.EventsColumns.TITLE, searchText)
        .or()
        .contains(CalendarContract.EventsColumns.EVENT_LOCATION, searchText)
        .or()
        .contains(CalendarContract.EventsColumns.DESCRIPTION, searchText);
      this.getContactPredicates(searchText, predicates);
      predicates.endWrap();
    }

    if (columns) {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
    } else {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
        predicates, await this.getQueryEventProjection(), tag);
    }
  }

  /**
   * 根据ids查询多个日程 Event 信息
   *
   * @return 查询的日程结果集合
   */
  async queryEventsByIds(
          ids: Array<number>,
          columns?: Array<string>,
          searchText?: string
  ): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventsByIds';
    if (EmptyUtils.isEmptyArray(ids)) {
      Log.warn(tag, 'ids is empty');
      return undefined;
    }
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates
      .in(CalendarContract.EventsColumns.ID, ids);
    if (searchText) {
      predicates
        .and()
        .beginWrap()
        .contains(CalendarContract.EventsColumns.TITLE, searchText)
        .or()
        .contains(CalendarContract.EventsColumns.EVENT_LOCATION, searchText)
        .or()
        .contains(CalendarContract.EventsColumns.DESCRIPTION, searchText);
      this.getContactPredicates(searchText, predicates);
      predicates.endWrap();
    }

    if (columns) {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
    } else {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
        predicates, await this.getQueryEventProjection(), tag);
    }
  }

  /*
   * 拼接联系人生日日程查询
   *
   * */
  private getContactPredicates(
          searchText: string,
          predicates: dataSharePredicates.DataSharePredicates
  ): dataSharePredicates.DataSharePredicates {
    // 联系人生日日程查询处理
    const unknownBirthday = GlobalThis.getResourceStr($r('app.string.no_name_birthday'));
    const language = I18nUtil.getSystemLanguage();
    const birthday = GlobalThis.getResourceStr($r('app.string.somebody_birthday'), language);

    const splitChar = '%s';
    const birthdaySuffix = birthday.substring(splitChar.length);
    let searchTextPrefix = '';
    let searchTextSuffix = '';
    let len = searchText.length;
    while (len > 0) {
      if (searchText.length - len >= 0 && birthdaySuffix.startsWith(searchText.substring(searchText.length - len))) {
        searchTextSuffix = searchText.substring(searchText.length - len);
        len = 0;
      }
      len--;
    }
    searchTextPrefix = searchText.substring(0, searchText.length - searchTextSuffix.length);

    if (birthday.includes(searchTextPrefix)) {
      // 查询所有生日日程
      predicates
        .or()
        .beginWrap()
        .equalTo(CalendarContract.EventsColumns.CREATOR, CONTACT_BIRTHDAY_ABILITY_NAME)
        .endWrap();
    } else {
      // 查询未知联系人生日
      if (unknownBirthday.includes(searchTextPrefix)) {
        predicates
          .or()
          .beginWrap()
          .equalTo(CalendarContract.EventsColumns.CREATOR, CONTACT_BIRTHDAY_ABILITY_NAME)
          .and()
          .equalTo(CalendarContract.EventsColumns.TITLE, '')
          .endWrap();
      }

      // 查询正常联系人生日
      predicates
        .or()
        .beginWrap()
        .equalTo(CalendarContract.EventsColumns.CREATOR, CONTACT_BIRTHDAY_ABILITY_NAME)
        .and()
        .contains(CalendarContract.EventsColumns.TITLE, searchTextPrefix)
        .endWrap();
    }

    return predicates;
  }


  async queryEventsByOldEventIds(oldEventIds: number[], columns: string[]): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventsByOldEventIds';
    if (EmptyUtils.isEmptyArray(oldEventIds)) {
      Log.warn(tag, 'oldEventIds is empty');
      return undefined;
    }
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.EventsColumns.OLD_EVENT_ID, oldEventIds);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
      predicates,
      columns,
      tag);
  }

  /**
   * 查询账户对应的日程
   *
   * @return 查询的日程结果集合
   */
  async queryEventsByAccountId(accountIds: number[], columns?: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryEventsByAccountId';
    if (!accountIds || accountIds.length === 0) {
      Log.warn(tag, `accountId is illegal`);
      return undefined;
    }
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.EventsColumns.CALENDAR_ID, accountIds);
    if (columns) {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
    } else {
      return await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS,
        predicates, await this.getQueryEventProjection(), tag);
    }
  }

  private async getQueryEventProjection(): Promise<Array<string>> {
    const projectionArray: string[] = this.QUERY_EVENT_PROJECTION;
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      projectionArray.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      projectionArray.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    return projectionArray;
  }

  async queryImportantEvents(columns?: string[], id?: number)
    : Promise<AgendaEventInfo[]> {
    const tag = 'queryImportantEvents';
    if (!columns) {
      columns = await this.getQueryEventProjection();
    }
    let result: AgendaEventInfo[] = [];
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
      [CalendarContract.EventImportantType.ANNIVERSARIES, CalendarContract.EventImportantType.COUNTDOWN]);
    if (id) {
      predicates.in(CalendarContract.EventsColumns.ID, [id]);
    }
    let resultSet = await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENTS, predicates, columns, tag);
    if (!resultSet) {
      Log.warn(tag, 'resultSet null');
      return result;
    }
    try {
      if (resultSet.rowCount <= 0 || !resultSet.goToFirstRow()) {
        Log.warn(tag, 'resultSet error');
        return result;
      }
      do {
        const eventInfo: AgendaEventInfo = AgendaEventInfo.buildEventInfo(resultSet);
        result.push(eventInfo);
      } while (resultSet.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryImportantEvents', err);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return result;
  }


  async insert(value: ValuesBucket, uri?: string): Promise<number> {
    return await DBUtils.INSTANCE.insert(uri ?? DBUtils.INSTANCE.URI_EVENT, value, TAG);
  }


  async updateById(id: number, value: ValuesBucket): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.EventsColumns.ID, id);
    return DBUtils.INSTANCE.update(DBUtils.INSTANCE.URI_EVENT, predicates, value, TAG);
  }

  async deleteByIds(ids: Array<number>): Promise<number> {
    /*数据分批，删除3W条数据时会报错 fail to Marshalling predicates
    多批次删除数据库可能报错，重试5次*/
    const idsBatch = getArrayBatch(ids, 10000);
    let deleteQuantity: number = 0;
    for (let batch = 0, retry = 0; batch < idsBatch.length; ) {
      let batchNumber: number = 0;
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.in(CalendarContract.EventsColumns.ID, idsBatch[batch]);
      try {
        batchNumber += await DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_EVENT, predicates, TAG);
        deleteQuantity += batchNumber;
        Log.info(TAG, `deleteById batch: ${batch} success number: ${batchNumber}`);
        batch++;
        retry = 0;
      } catch (err) {
        if (retry++ === 5) {
          retry = 0;
          batch++;
          Log.error(TAG, `deleteById batch: ${batch} err: msg ${err?.message} code ${err?.code} retry failed`);
          continue;
        }
        Log.error(TAG, `deleteById batch: ${batch} msg ${err?.message} code ${err?.code} retry: ${retry}`);
        SqlFaultHandle.deleteSqlFail(err?.message, TAG)
      }
    }
    return deleteQuantity;
  }

  async deleteByUuids(eventUuids: string[]): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.EventsColumns.UUID, eventUuids);
    try {
      const deleteCount = await DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_EVENT, predicates, TAG);
      if (deleteCount < 0) {
        return new Result(ErrorCode.NO_DB, 'illegal delete count', -1);
      }
      return Result.buildSuccessResult(deleteCount);
    } catch (err) {
      Log.logErrorMsg(TAG, `deleteByUuids  err:`, err);
      SqlFaultHandle.deleteSqlFail(err?.message, TAG)
      return Result.buildByErrorWithData(err, -1);
    }
  }
}

function getArrayBatch<T>(array: T[], size: number): T[][] {
  let result: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size));
  }
  return result;
}