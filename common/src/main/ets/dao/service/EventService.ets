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

import { EventRepository } from '../repo/EventRepository';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { AgendaEventInfo } from '../../agenda/AgendaEventInfo';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Log } from '../../default/common/Log';
import { ReminderService } from './ReminderService';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '../../default/common/TraceEvents';
import { CornerType } from '../../agenda/CornerType';
import { reInitGlobalContextInTaskPool, runTaskAsync } from '../../util/TaskPool';
import { common } from '@kit.AbilityKit';
import { Result } from '../../templates/Result';
import { AccountUtils } from '../../account/AccountUtils';
import { InnerResultSet } from '../util/InnerResultSet';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';
import { GlobalThis } from '../../data/GlobalThis';
import { EmptyUtils } from '../../util/EmptyUtils';
import { I18nUtil } from '../../util/I18nUtil';
import { DeduplicateProcessor } from '../../event/DeduplicateProcessor';
import { CalendarDataFeature, CalendarDataFeatureHelper } from '../../util/CalendarDataFeatureHelper';
import { maskString } from '../../util/SensitiveStrUtils';
import { CalendarService } from './CalendarService';

const TAG = 'EventService';

export class EventService {
  static readonly INSTANCE: EventService = new EventService();
  public repo: EventRepository;

  private constructor() {
    this.repo = new EventRepository;
  }

  /**
   * 通过id获取日程信息
   *
   * @param id
   */
  async queryEventById(id: number): Promise<AgendaEventInfo> {
    let info: AgendaEventInfo = new AgendaEventInfo();
    const columns: Array<string> = [
      CalendarContract.EventsColumns.UUID,
      CalendarContract.EventsColumns.ID as string,
      CalendarContract.EventsColumns.TITLE as string,
      CalendarContract.EventsColumns.DTSTART as string,
      CalendarContract.EventsColumns.DTEND as string,
      CalendarContract.EventsColumns.DESCRIPTION as string,
      CalendarContract.EventsColumns.SERVICE_DESCRIPTION as string,
      CalendarContract.EventsColumns.EVENT_LOCATION as string,
      CalendarContract.EventsColumns.CALENDAR_ID as string,
      CalendarContract.EventsColumns.CALENDAR_UUID as string,
      CalendarContract.EventsColumns.ALL_DAY as string,
      CalendarContract.EventsColumns.SERVICE_VERIFIED as string,
      CalendarContract.EventsColumns.SERVICE_TYPE as string,
      CalendarContract.EventsColumns.SERVICE_CP_BZ_URI as string,
      CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE as string,
      CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
      CalendarContract.EventsColumns.RRULE,
      CalendarContract.EventsColumns.RDATE,
      CalendarContract.EventsColumns.EXRULE,
      CalendarContract.EventsColumns.EXDATE,
      CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
      CalendarContract.EventsColumns.IDENTIFIER,
      CalendarContract.EventsColumns.LOCATION_LONGITUDE,
      CalendarContract.EventsColumns.LOCATION_LATITUDE,
      CalendarContract.EventsColumns.START_TIMEZONE,
      CalendarContract.EventsColumns.CREATOR
    ];
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      columns.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      columns.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    let resultSet: InnerResultSet | undefined;
    try {
      resultSet = await this.queryEventByEventId(id, columns);
    } catch (err) {
      Log.warn(TAG, `queryEventByEventId err.message: ${err?.message}, err.code: ${err?.code}`);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    }
    if (!resultSet) {
      return info;
    }
    try {
      resultSet.goToFirstRow();
      info = AgendaEventInfo.buildEventInfo(resultSet);
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryEventById', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      resultSet.close();
    }
    info.mTitle = this.setBirthDayTitleByCalendarId(info.mTitle, info.mCalendarId);
    return info;
  }

  // 查询所有日程，排除节假日
  async queryAllEvents(calendarUuid: string = ''): Promise<number[]> {
    Log.info(TAG, `queryAllEvents start`);
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `queryAllEvents get invalid context`);
      return [];
    }
    let start = Date.now();
    let eventIds = await runTaskAsync(queryAllEventsTask, calendarUuid, context) as number[];
    Log.info(TAG, `queryAllEvents ${eventIds.length} queried, cost: ${Date.now() - start}`);
    return eventIds;
  }

  // 查询所有日程，排除节假日和联系人生日
  async queryNormalEvents(calendarUuid: string = ''): Promise<number[]> {
    Log.info(TAG, `queryNormalEvents start`);
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `queryNormalEvents get invalid context`);
      return [];
    }
    let start = Date.now();
    let eventIds = await runTaskAsync(queryNormalEventsTask, calendarUuid, context) as number[];
    Log.info(TAG, `queryNormalEvents ${eventIds.length} queried, cost: ${Date.now() - start}`);
    return eventIds;
  }

  // 查询所有节假日日程
  async queryAllHolidayEvents(calendarIds?: number[]): Promise<AgendaEventInfo[]> {
    let events: AgendaEventInfo[] = [];
    let resultSet = await this.repo.queryAllHolidayEvents(calendarIds);
    try {
      if (!resultSet) {
        Log.warn(TAG, `queryAllHolidayEvents resultSet is null`);
        return [];
      }
      Log.info(TAG, `queryAllHolidayEvents count is ${resultSet?.rowCount}`);
      if (resultSet.rowCount <= 0) {
        return [];
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, 'queryAllHolidayEvents goToFirstRow false');
        return events;
      }
      do {
        events.push(AgendaEventInfo.buildEventInfo(resultSet));
      } while (resultSet.goToNextRow())
      return events;
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryAllHolidayEvents', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 更新日程
   *
   * @param eventId 日程Id
   * @param checkValuesArray 提醒时间
   * @param valuesArrayChange 提醒时间是否改变
   * @param value 日程内容
   * @param initReminders 初始日程提醒时间数量
   */
  async updateEventAndReminder(eventId: number, checkValuesArray: CalendarContract.Reminders[],valuesArrayChange: boolean, value: Object, initReminders: number): Promise<boolean> {
    try {
      hiTraceMeter.startTrace(traceEvents.updateByEventId, 0);
      const rowsUpdated = await this.updateByEventId(eventId, value as ValuesBucket);
      hiTraceMeter.finishTrace(traceEvents.updateByEventId, 0);
      if (rowsUpdated >= 0 && !valuesArrayChange) {
        // 提醒列表未改变时直接返回
        return true;
      } else if (rowsUpdated >= 0 && valuesArrayChange) {
        hiTraceMeter.startTrace(traceEvents.updateReminderByReplace, 0);
        let updateReminder = await ReminderService.INSTANCE.updateReminderByReplace(eventId, checkValuesArray, initReminders);
        hiTraceMeter.finishTrace(traceEvents.updateReminderByReplace, 0);
        return updateReminder;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'updateEventAndReminder', err);
      SqlFaultHandle.updateSqlFail(err?.message, TAG)
    }
    return false;
  }

  /**
   * 根据日程id，删除日程
   *
   * @param eventId 日程Id
   * @return 删除日程的总数
   */
  async deleteEventById(eventId: number): Promise<number> {
    try {
      hiTraceMeter.startTrace(traceEvents.deleteEventById, 0);
      let rowsDeleted = await this.deleteEventByEventIds([eventId]);
      hiTraceMeter.finishTrace(traceEvents.deleteEventById, 0);
      Log.info(TAG, 'Event rowsDeleted: ' + rowsDeleted);
      return rowsDeleted;
    } catch (err) {
      Log.logErrorMsg(TAG, 'deleteEventById', err);
      hiTraceMeter.finishTrace(traceEvents.deleteEventById, 0);
      SqlFaultHandle.deleteSqlFail(err?.message, TAG)
    }
    return -1;
  }

  /**
   * 批量删除日程
   *
   * @param idSet
   * @return 删除日程的总数
   */
  async deleteEvents(idSet: Set<number>): Promise<number> {
    try {
      hiTraceMeter.startTrace(traceEvents.deleteEvents, 0);
      let rowsDeleted = await this.deleteEventByEventIds(Array.from(idSet));
      hiTraceMeter.finishTrace(traceEvents.deleteEvents, 0);
      Log.info(TAG, 'Event rowsDeleted: ' + rowsDeleted);
      return rowsDeleted;
    } catch (err) {
      Log.logErrorMsg(TAG, 'Delete Reminder', err);
      hiTraceMeter.finishTrace(traceEvents.deleteEvents, 0);
      SqlFaultHandle.deleteSqlFail(err?.message, TAG)
    }
    return -1;
  }

  /**
   * 插入日程和提醒
   *
   * @param value 插入对象
   */
  async insertEvent(value: Object, uri?: string): Promise<number> {
    let eventId: number = -1;
    try {
      // 插入日程
      hiTraceMeter.startTrace(traceEvents.insertEvent, 0);
      eventId = await this.insertEvents(value as ValuesBucket, uri);
      hiTraceMeter.finishTrace(traceEvents.insertEvent, 0);
    } catch (err) {
      Log.logErrorMsg(TAG, 'Insert insertEvent', err);
      hiTraceMeter.finishTrace(traceEvents.insertEvent, 0);
      SqlFaultHandle.insertSqlFail(err?.message, TAG)
    }
    return eventId;
  }

  /**
   * 插入日程和提醒
   *
   * @param eventId 插入日程id
   * @param checkValuesArray 提醒
   */
  async insertReminder(eventId: number, checkValuesArray: CalendarContract.Reminders[]): Promise<boolean> {
    try {
      if (eventId > 0 && checkValuesArray?.length > 0) {
        // 插入提醒列表
        hiTraceMeter.startTrace(traceEvents.insertReminder, 0);
        let insertReminder = await ReminderService.INSTANCE.insertReminderArray(eventId, checkValuesArray);
        hiTraceMeter.finishTrace(traceEvents.insertReminder, 0);
        return insertReminder;
      }
    } catch (err) {
      hiTraceMeter.finishTrace(traceEvents.insertReminder, 0);
      Log.error(TAG, 'Insert insertEventAndReminder err: ' + err?.message);
      SqlFaultHandle.insertSqlFail(err?.message, TAG)
    }
    return false;
  }

  /**
   * 查询所有日程 Events 信息
   *
   * @return 查询的日程结果集合
   */
  async queryEvents(): Promise<InnerResultSet | undefined> {
    let events = await this.repo.queryEvents();
    return events;
  }

  async queryEventByEventId(id: number, columns?: Array<string>): Promise<InnerResultSet | undefined> {
    let events = await this.repo.queryEventById(id, columns);
    return events;
  }

  async queryEventByUUID(uuid: string): Promise<AgendaEventInfo | undefined> {
    const columns: Array<string> = [
      CalendarContract.EventsColumns.UUID,
      CalendarContract.EventsColumns.ID as string,
      CalendarContract.EventsColumns.TITLE as string,
      CalendarContract.EventsColumns.DTSTART as string,
      CalendarContract.EventsColumns.DTEND as string,
      CalendarContract.EventsColumns.DESCRIPTION as string,
      CalendarContract.EventsColumns.SERVICE_DESCRIPTION as string,
      CalendarContract.EventsColumns.EVENT_LOCATION as string,
      CalendarContract.EventsColumns.CALENDAR_ID as string,
      CalendarContract.EventsColumns.CALENDAR_UUID as string,
      CalendarContract.EventsColumns.ALL_DAY as string,
      CalendarContract.EventsColumns.SERVICE_VERIFIED as string,
      CalendarContract.EventsColumns.SERVICE_TYPE as string,
      CalendarContract.EventsColumns.SERVICE_CP_BZ_URI as string,
      CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE as string,
      CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
      CalendarContract.EventsColumns.RRULE,
      CalendarContract.EventsColumns.RDATE,
      CalendarContract.EventsColumns.EXRULE,
      CalendarContract.EventsColumns.EXDATE,
      CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
      CalendarContract.EventsColumns.IDENTIFIER,
      CalendarContract.EventsColumns.LOCATION_LONGITUDE,
      CalendarContract.EventsColumns.LOCATION_LATITUDE,
      CalendarContract.EventsColumns.START_TIMEZONE,
      CalendarContract.EventsColumns.CREATOR
    ];
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      columns.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      columns.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    let resultSet: InnerResultSet | undefined;
    try {
      resultSet = await this.repo.queryEventByUUID(uuid, columns);
      if (!resultSet || resultSet.rowCount <= 0) {
        resultSet?.close();
        resultSet = await this.repo.queryEventByUUID(uuid, columns, false);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryEventByEventId', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    }
    if (!resultSet || resultSet.rowCount <= 0) {
      Log.warn(TAG, `event uuid: ${maskString(uuid)} is not exist`);
      resultSet?.close();
      return undefined;
    }
    try {
      resultSet.goToFirstRow();
      let event = AgendaEventInfo.buildEventInfo(resultSet);
      return event;
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryEventById', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG);
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  async queryEventByAccountId(accountId: number): Promise<Array<AgendaEventInfo>> {
    const columns: Array<string> = [
      CalendarContract.EventsColumns.ID as string,
      CalendarContract.EventsColumns.TITLE as string,
      CalendarContract.EventsColumns.DTSTART as string,
      CalendarContract.EventsColumns.DTEND as string,
      CalendarContract.EventsColumns.DESCRIPTION as string,
      CalendarContract.EventsColumns.SERVICE_DESCRIPTION as string,
      CalendarContract.EventsColumns.EVENT_LOCATION as string,
      CalendarContract.EventsColumns.CALENDAR_ID as string,
      CalendarContract.EventsColumns.ALL_DAY as string,
      CalendarContract.EventsColumns.SERVICE_VERIFIED as string,
      CalendarContract.EventsColumns.SERVICE_TYPE as string,
      CalendarContract.EventsColumns.SERVICE_CP_BZ_URI as string,
      CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE as string,
      CalendarContract.EventsColumns.RRULE,
      CalendarContract.EventsColumns.RDATE,
      CalendarContract.EventsColumns.EXRULE,
      CalendarContract.EventsColumns.EXDATE,

      CalendarContract.EventsColumns.PERMISSION_LEVEL,
      CalendarContract.EventsColumns.START_TIMEZONE,
      CalendarContract.EventsColumns.HAS_ALARM,
      CalendarContract.EventsColumns.DURATION,
      CalendarContract.EventsColumns.LAST_DATE,
      CalendarContract.EventsColumns.EVENT_IMAGE_TYPE,
      CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
      CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
      CalendarContract.EventsColumns.CREATOR
    ];
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      columns.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      columns.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    const events: Array<AgendaEventInfo> = new Array();
    const resultSet = await this.repo.queryEventsByAccountId([accountId], columns);
    if (!resultSet) {
      Log.warn(TAG, 'queryEventByAccountId resultSet is null');
      return events;
    }
    try {
      Log.info(TAG, `queryEventByAccountId count is ${resultSet.rowCount}`);
      if (resultSet.rowCount <= 0) {
        return events;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, 'queryEventByAccountId goToFirstRow false');
        return events;
      }
      do {
        events.push(this.buildEventByResultSet(resultSet))
      } while (resultSet.goToNextRow())
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryEventByAccountId', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG);
    } finally {
      resultSet.close();
    }
    return events;
  }

  async queryEventsByAccountIds(accountIds: number[], columns?: string[]): Promise<AgendaEventInfo[]> {
    let resultSet: InnerResultSet | undefined = undefined;
    try {
      resultSet = await this.repo.queryEventsByAccountId(accountIds, columns);
      return this.parseEventsFromResultSet('queryEventsByAccountIds', resultSet);
    } catch (err) {
      Log.warn(TAG, `queryEventsByAccountIds getErr ${err?.code}, ${err?.message}`);
    } finally {
      resultSet?.close();
    }
    return [];
  }

  async queryEventsByOldEventIds(oldEventIds: number[]): Promise<AgendaEventInfo[]> {
    const events: AgendaEventInfo[] = [];
    const columns: string[] = [
      CalendarContract.EventsColumns.ID,
      CalendarContract.EventsColumns.OLD_EVENT_ID
    ];
    try {
      const resultSet = await this.repo.queryEventsByOldEventIds(oldEventIds, columns);
      if (!resultSet) {
        Log.warn(TAG, 'queryEventsByOldEventIds resultSet is null');
        return events;
      }
      try {
        Log.info(TAG, `queryEventsByOldEventIds count is ${resultSet.rowCount}`);
        if (resultSet.rowCount <= 0) {
          return events;
        }
        if (!resultSet.goToFirstRow()) {
          Log.warn(TAG, 'queryEventsByOldEventIds goToFirstRow false');
          return events;
        }
        do {
          events.push(this.buildEventByResultSet(resultSet));
        } while (resultSet.goToNextRow())
      } catch (error) {
        Log.logErrorMsg(TAG, 'queryEventsByOldEventIds error buildEventByResultSet', error);
      } finally {
        resultSet.close();
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'queryEventsByOldEventIds error', error);
    }
    return events;
  }

  //通过节假日名称查询指定账户的节假日日程
  async queryHolidayEventByTitle(eventTitle: string, calendarId: number): Promise<AgendaEventInfo[]> {
    const columns: string[] = [
      CalendarContract.EventsColumns.ID,
      CalendarContract.EventsColumns.TITLE,
      CalendarContract.EventsColumns.DTSTART
    ];
    let events: AgendaEventInfo[] = [];
    //进行查询操作
    const resultSet = await this.repo.queryHolidayEventByTitle(eventTitle, calendarId, columns);
    if (!resultSet) {
      Log.warn(TAG, 'queryEventByTitle resultSet is null');
      return events;
    }
    try {
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, 'queryEventByTitle goToFirstRow false');
        return events;
      }
      do {
        const event = this.buildEventByResultSet(resultSet);
        events.push(event);
      } while (resultSet.goToNextRow())
    } catch (error) {
      Log.logErrorMsg(TAG, 'queryEventByTitle error', error);
    } finally {
      resultSet.close();
    }
    return events;
  }

  /**
   * 根据日程 ids 查询日程
   * @param ids
   * @returns
   */
  async queryEventsByEventUuids(
    uuids: Array<string>,
    columns?: Array<string>,
    searchText?: string
  ): Promise<Array<AgendaEventInfo>> {
    const events: Array<AgendaEventInfo> = new Array();
    if (!columns || columns.length === 0) {
      columns = [
        CalendarContract.EventsColumns.ID as string,
        CalendarContract.EventsColumns.TITLE as string,
        CalendarContract.EventsColumns.DTSTART as string,
        CalendarContract.EventsColumns.DTEND as string,
        CalendarContract.EventsColumns.DESCRIPTION as string,
        CalendarContract.EventsColumns.SERVICE_DESCRIPTION as string,
        CalendarContract.EventsColumns.EVENT_LOCATION as string,
        CalendarContract.EventsColumns.CALENDAR_ID as string,
        CalendarContract.EventsColumns.CALENDAR_UUID as string,
        CalendarContract.EventsColumns.ALL_DAY as string,
        CalendarContract.EventsColumns.SERVICE_VERIFIED as string,
        CalendarContract.EventsColumns.SERVICE_TYPE as string,
        CalendarContract.EventsColumns.SERVICE_CP_BZ_URI as string,
        CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE as string,
        CalendarContract.EventsColumns.RRULE,
        CalendarContract.EventsColumns.RDATE,
        CalendarContract.EventsColumns.EXRULE,
        CalendarContract.EventsColumns.EXDATE,

        CalendarContract.EventsColumns.PERMISSION_LEVEL,
        CalendarContract.EventsColumns.START_TIMEZONE,
        CalendarContract.EventsColumns.HAS_ALARM,
        CalendarContract.EventsColumns.DURATION,
        CalendarContract.EventsColumns.LAST_DATE,
        CalendarContract.EventsColumns.EVENT_IMAGE_TYPE,
        CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
        CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
        CalendarContract.EventsColumns.IDENTIFIER,
        CalendarContract.EventsColumns.LOCATION_LONGITUDE,
        CalendarContract.EventsColumns.LOCATION_LATITUDE,
        CalendarContract.EventsColumns.CREATOR,
        CalendarContract.EventsColumns.UUID
      ];
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      columns.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      columns.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    const resultSet = await this.repo.queryEventsByUuids(uuids, columns, searchText);

    if (!resultSet) {
      Log.warn(TAG, 'queryEventsByEventUuids resultSet is null');
      return events;
    }
    try {
      Log.info(TAG, `queryEventsByEventUuids count is ${resultSet.rowCount}`);
      if (resultSet.rowCount <= 0) {
        return events;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, 'queryEventsByEventUuids goToFirstRow false');
        return events;
      }
      do {
        events.push(this.buildEventByResultSet(resultSet));
      } while (resultSet.goToNextRow())
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryEventsByEventUuids', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      resultSet.close();
    }
    return events;
  }

  /**
   * 根据日程 ids 查询日程
   * @param ids
   * @returns
   */
  async queryEventsByEventIds(
          ids: Array<number>,
          columns?: Array<string>,
          searchText?: string
  ): Promise<Array<AgendaEventInfo>> {
    const events: Array<AgendaEventInfo> = new Array();
    if (!columns || columns.length === 0) {
      columns = [
        CalendarContract.EventsColumns.ID as string,
        CalendarContract.EventsColumns.TITLE as string,
        CalendarContract.EventsColumns.DTSTART as string,
        CalendarContract.EventsColumns.DTEND as string,
        CalendarContract.EventsColumns.DESCRIPTION as string,
        CalendarContract.EventsColumns.SERVICE_DESCRIPTION as string,
        CalendarContract.EventsColumns.EVENT_LOCATION as string,
        CalendarContract.EventsColumns.CALENDAR_ID as string,
        CalendarContract.EventsColumns.ALL_DAY as string,
        CalendarContract.EventsColumns.SERVICE_VERIFIED as string,
        CalendarContract.EventsColumns.SERVICE_TYPE as string,
        CalendarContract.EventsColumns.SERVICE_CP_BZ_URI as string,
        CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE as string,
        CalendarContract.EventsColumns.RRULE,
        CalendarContract.EventsColumns.RDATE,
        CalendarContract.EventsColumns.EXRULE,
        CalendarContract.EventsColumns.EXDATE,

        CalendarContract.EventsColumns.PERMISSION_LEVEL,
        CalendarContract.EventsColumns.START_TIMEZONE,
        CalendarContract.EventsColumns.HAS_ALARM,
        CalendarContract.EventsColumns.DURATION,
        CalendarContract.EventsColumns.LAST_DATE,
        CalendarContract.EventsColumns.EVENT_IMAGE_TYPE,
        CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
        CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
        CalendarContract.EventsColumns.IDENTIFIER,
        CalendarContract.EventsColumns.LOCATION_LONGITUDE,
        CalendarContract.EventsColumns.LOCATION_LATITUDE,
        CalendarContract.EventsColumns.CREATOR
      ];
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      columns.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      columns.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    const resultSet = await this.repo.queryEventsByIds(ids, columns, searchText);

    if (!resultSet) {
      Log.warn(TAG, 'queryEventsByEventIds resultSet is null');
      return events;
    }
    try {
      Log.info(TAG, `queryEventsByEventIds count is ${resultSet.rowCount}`);
      if (resultSet.rowCount <= 0) {
        return events;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, 'queryEventsByEventIds goToFirstRow false');
        return events;
      }
      do {
        events.push(this.buildEventByResultSet(resultSet));
      } while (resultSet.goToNextRow())
    } catch (err) {
      Log.warn(TAG, `queryEventsByEventIds err ${err?.code} ${err?.message}`);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      resultSet.close();
    }
    return events;
  }

  async queryHolidaysByTitles(titles: Array<string>, columns?: string[]): Promise<AgendaEventInfo[]> {
    let resultSet: InnerResultSet | undefined = undefined;
    try {
      if (columns && columns.length > 0) {
        resultSet = await this.repo.queryHolidayByTitles(titles, columns);
      } else {
        resultSet = await this.repo.queryHolidayByTitles(titles);
      }
      return this.parseEventsFromResultSet('queryHolidaysByTitles', resultSet);
    } catch (err) {
      Log.warn(TAG, `queryEventsByTitles getErr ${err?.code}, ${err?.message}`);
    } finally {
      resultSet?.close();
    }
    return [];
  }

  async insertEvents(value: ValuesBucket, uri?: string): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.insertEvents, 0);
    let events = await this.repo.insert(value, uri);
    hiTraceMeter.finishTrace(traceEvents.insertEvents, 0);
    return events;
  }

  async updateByEventId(id: number, value: ValuesBucket): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.updateByEventId, 0);
    let updateQuantity = await this.repo.updateById(id, value);
    const eventDeduplicateIds = await DeduplicateProcessor.INSTANCE.getAllReduceEventIds([id]);
    if (eventDeduplicateIds && eventDeduplicateIds.length > 0) {
      for (const eventId of eventDeduplicateIds) {
        await this.repo.updateById(eventId, value);
      }
      Log.warn(TAG, `update repeat associated event ids:${eventDeduplicateIds}, original:${id} success`);
    }
    hiTraceMeter.finishTrace(traceEvents.updateByEventId, 0);
    return updateQuantity;
  }

  async deleteEventByEventIds(eventIds: Array<number>): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.deleteEventByEventIds, 0);
    let deleteQuantity = await this.repo.deleteByIds(eventIds);
    const eventDeduplicateIds = await DeduplicateProcessor.INSTANCE.getAllReduceEventIds(eventIds);
    if (eventDeduplicateIds && eventDeduplicateIds.length > 0) {
      await this.repo.deleteByIds(eventDeduplicateIds);
      Log.warn(TAG, `delete repeat associated event id:${eventDeduplicateIds}, original:${eventIds} success`);
    }
    hiTraceMeter.finishTrace(traceEvents.deleteEventByEventIds, 0);
    return deleteQuantity;
  }

  async deleteEventByEventUuids(eventUuids: string[]): Promise<Result<number>> {
    if (EmptyUtils.isEmptyArray(eventUuids)) {
      return Result.buildSuccessResult(0);
    }
    hiTraceMeter.startTrace(traceEvents.deleteEventByEventIds, 0);
    const deleteResult = await this.repo.deleteByUuids(eventUuids);
    hiTraceMeter.finishTrace(traceEvents.deleteEventByEventIds, 0);
    return deleteResult;
  }

  async queryImportantEvents(columns?: string[], id?: number): Promise<Array<AgendaEventInfo>> {
    let events = await this.repo.queryImportantEvents(columns, id);
    return events;
  }

  private setBirthDayTitle(title: string): string {
    if (!title || title === '') {
      return GlobalThis.getResourceStr($r('app.string.no_name_birthday'));
    }
    const language = I18nUtil.getSystemLanguage();
    const birthDay: string = GlobalThis.getResourceStr($r('app.string.somebody_birthday'), language);
    const place: string = '%s';
    return (birthDay ?? '').replace(place, title);
  }

  public setBirthDayTitleByCalendarId(title: string, id: number): string {
    const isBirthDay = AccountUtils.isBirthDayAccountById(id);
    let mTitle = title;
    if (isBirthDay) {
      mTitle = this.setBirthDayTitle(mTitle);
    }
    return mTitle;
  }

  /**
   * 按天对日程分组
   *
   * @param originList 待分组日程项
   * @param julianDayBegin 分组的范围开始儒略日
   * @param julianDayBegin 分组的范围结束儒略日
   */
  private async groupAgendaByDay(
    originList: Array<AgendaEventInfo>,
    julianDayBegin: number,
    julianDayEnd: number): Promise<Array<AgendaEventInfo>> {
    if (originList.length === 0) {
      return [];
    }
    const res: Array<AgendaEventInfo> = [];
    const startDay: number = Math.min(...originList.map((item: AgendaEventInfo) => item.mStartDay));
    const startJulianDay: number = Math.max(startDay, julianDayBegin);
    const endDay: number = Math.max(...originList.map((item: AgendaEventInfo) => item.mEndDay));
    const endJulianDay: number = Math.min(endDay, julianDayEnd);
    let setCorner: (oneDayList: AgendaEventInfo[]) => void = (oneDayList: AgendaEventInfo[]): void => {
      if (oneDayList.length > 0) {
        oneDayList[0].mIsSetDayHead = true;
        if (oneDayList.length === 1) {
          oneDayList[0].mCornerType = CornerType.CORNER_ALL;
        } else {
          oneDayList[0].mCornerType = CornerType.CORNER_UP;
          oneDayList[oneDayList.length - 1].mCornerType = CornerType.CORNER_DOWN;
        }
      }
    }
    let sortList: (
      a: AgendaEventInfo,
      b: AgendaEventInfo) => number = (a: AgendaEventInfo, b: AgendaEventInfo): number => {
      if (a.mBegin !== b.mBegin) {
        return a.mBegin - b.mBegin;
      }

      if (a.mEnd !== b.mEnd) {
        return a.mEnd - b.mEnd;
      }
      const getTitle = (item: AgendaEventInfo): string => {
        return item.mTitle ?? '';
      };
      return getTitle(a).localeCompare(getTitle(b));
    }
    for (let day = startJulianDay; day <= endJulianDay; day++) {
      const oneDayList: AgendaEventInfo[] = this.groupOneDay(originList, day);
      Log.debug(TAG, `oneDayList length is ${oneDayList?.length}`);
      oneDayList.sort((a: AgendaEventInfo, b: AgendaEventInfo) => sortList(a, b));
      setCorner(oneDayList);
      for (const item of oneDayList) {
        item.mTitle = this.setBirthDayTitleByCalendarId(item.mTitle, item.mCalendarId);
        res.push(item);
      }
    }
    return res.map(item => new AgendaEventInfo(item));
  }

  /**
   * 按天对日程分组
   *
   * @param originList 待分组日程项
   * @param day 儒略日
   * @return Array<AgendaEventInfo> 某一天的日程列表
   */
  private groupOneDay(originList: Array<AgendaEventInfo>, day: number): AgendaEventInfo[] {
    const oneDayList: AgendaEventInfo[] = [];
    for (let item of originList) {
      if (item.mStartDay > day || item.mEndDay < day) {
        continue;
      }
      // 过滤全天日程导致的重复
      if (item.mStartDay < day && (item.mEndDay === day && item.mIsAllDay)) {
        continue;
      }
      const info: AgendaEventInfo = new AgendaEventInfo(item);
      info.setFlag(day);
      info.mTitle = this.setBirthDayTitleByCalendarId(info.mTitle, info.mCalendarId);
      oneDayList.push(info);
    }
    return oneDayList;
  }

  private parseEventsFromResultSet(sceneTag: string, resultSet: InnerResultSet | undefined): AgendaEventInfo[] {
    const resultList: AgendaEventInfo[] = [];
    if (!resultSet) {
      Log.warn(TAG, `${sceneTag} get invalid resultSet`);
      return resultList;
    }
    if (resultSet.rowCount <= 0) {
      Log.warn(TAG, `${sceneTag} wrong rowCount: ${resultSet.rowCount}`);
      return resultList;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, `${sceneTag} goToFirstRow false`);
      return resultList;
    }
    do {
      resultList.push(this.buildEventByResultSet(resultSet));
    } while (resultSet.goToNextRow());
    return resultList;
  }

  private buildEventByResultSet(resultSet: InnerResultSet): AgendaEventInfo {
    const event: AgendaEventInfo = AgendaEventInfo.buildEventInfo(resultSet);
    return event;
  }
}

@Concurrent
async function queryAllEventsTask(calendarUuid: string, context: common.UIAbilityContext): Promise<Array<number>> {
  reInitGlobalContextInTaskPool(context);
  const TAG: string = 'queryAllEventsTask';
  let eventIds: number[] = [];
  Log.info(TAG, `queryAllEventsTask start`);
  const start = Date.now();
  const resultSet = await new EventRepository().queryAllEvents();
  Log.info(TAG, `queryAllEventsTask cost ${Date.now() - start}ms, length: ${resultSet?.rowCount}`);
  if (!resultSet) {
    Log.error(TAG, 'queryAllEventsTask no result set');
    return eventIds;
  }
  try {
    Log.info(TAG, `queryAllEvents count is ${resultSet.rowCount}`);
    if (resultSet.rowCount <= 0) {
      return eventIds;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, 'queryAllEvents goToFirstRow false');
      return eventIds;
    }
    // 三方应用创建的日程可能 calendar_uuid 为空，此时通过 calendar_id 回退匹配
    let accountId: number | undefined = undefined;
    if (!EmptyUtils.isEmptyString(calendarUuid, true)) {
      const accounts = await CalendarService.INSTANCE.queryCalendarList();
      accountId = accounts.find(acc => acc.uuid === calendarUuid)?.id;
    }
    do {
      const id = DataShareResultUtil.getColumnLongData(resultSet, CalendarContract.EventsColumns.ID, 0);
      const accountUuid =
        DataShareResultUtil.getColumnStringData(resultSet, CalendarContract.EventsColumns.CALENDAR_UUID, '');
      if (!EmptyUtils.isEmptyString(calendarUuid, true) && accountUuid !== calendarUuid) {
        // calendar_uuid 为空且 calendar_id 匹配时，仍保留该日程
        if (EmptyUtils.isEmptyString(accountUuid, true) && accountId !== undefined) {
          const calendarId = DataShareResultUtil.getColumnLongData(resultSet, CalendarContract.EventsColumns.CALENDAR_ID, 0);
          if (calendarId === accountId) {
            eventIds.push(id);
          }
        }
        continue;
      }
      eventIds.push(id);
    } while (resultSet.goToNextRow())
    Log.info(TAG, `queryAllEventsTask build event cost ${Date.now() - start}ms`);
    return eventIds;
  } catch (err) {
    Log.logErrorMsg(TAG, 'queryAllEvents', err);
    SqlFaultHandle.querySqlFail(err?.message, TAG)
    return [];
  } finally {
    Log.info(TAG, `queryAllEventsTask end`);
    if (resultSet) {
      resultSet.close();
    }
  }
}

@Concurrent
async function queryNormalEventsTask(calendarUuid: string, context: common.UIAbilityContext): Promise<Array<number>> {
  reInitGlobalContextInTaskPool(context);
  const TAG: string = 'queryNormalEventsTask';
  let eventIds: number[] = [];
  Log.info(TAG, `queryNormalEventsTask start`);
  const start = Date.now();
  const resultSet = await new EventRepository().queryNormalEvents();
  Log.info(TAG, `queryNormalEventsTask cost ${Date.now() - start}ms, length: ${resultSet?.rowCount}`);
  if (!resultSet) {
    Log.error(TAG, 'queryNormalEventsTask no result set');
    return eventIds;
  }
  try {
    Log.info(TAG, `queryNormalEventsTask count is ${resultSet.rowCount}`);
    if (resultSet.rowCount <= 0) {
      return eventIds;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, 'queryNormalEvents goToFirstRow false');
      return eventIds;
    }
    // 三方应用创建的日程可能 calendar_uuid 为空，此时通过 calendar_id 回退匹配
    let accountId: number | undefined = undefined;
    if (!EmptyUtils.isEmptyString(calendarUuid, true)) {
      const accounts = await CalendarService.INSTANCE.queryCalendarList();
      accountId = accounts.find(acc => acc.uuid === calendarUuid)?.id;
    }
    do {
      const id = DataShareResultUtil.getColumnLongData(resultSet, CalendarContract.EventsColumns.ID, 0);
      const accountUuid =
        DataShareResultUtil.getColumnStringData(resultSet, CalendarContract.EventsColumns.CALENDAR_UUID, '');
      if (!EmptyUtils.isEmptyString(calendarUuid, true) && accountUuid !== calendarUuid) {
        // calendar_uuid 为空且 calendar_id 匹配时，仍保留该日程
        if (EmptyUtils.isEmptyString(accountUuid, true) && accountId !== undefined) {
          const calendarId = DataShareResultUtil.getColumnLongData(resultSet, CalendarContract.EventsColumns.CALENDAR_ID, 0);
          if (calendarId === accountId) {
            eventIds.push(id);
          }
        }
        continue;
      }
      eventIds.push(id);
    } while (resultSet.goToNextRow())
    Log.info(TAG, `queryNormalEventsTask build event cost ${Date.now() - start}ms`);
    return eventIds;
  } catch (err) {
    Log.logErrorMsg(TAG, 'queryNormalEventsTask', err);
    SqlFaultHandle.querySqlFail(err?.message, TAG)
    return [];
  } finally {
    Log.info(TAG, `queryNormalEventsTask end`);
    if (resultSet) {
      resultSet.close();
    }
  }
}