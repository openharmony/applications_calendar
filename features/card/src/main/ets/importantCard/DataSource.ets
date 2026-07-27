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

import {
  AccountUtils,
  AgendaEventInfo, CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  CalendarDate,
  CalendarService, EventService,
  getAdaptImportantTime,
  InstanceService,
  Log, MILLS_PER_DAY,
  QueryInfo,
  TimeZoneUtil} from '@app/common';
import { calendarManager } from '@kit.CalendarKit';
import { getRecentLocalHolidayEntities, SUPPORT_CHINESE_HOLIDAYS } from './model/ImportantCardModel';
import { ImportantEntity } from './model/ImportantEntity';
import { convertToImportantEntity } from './view/components/importantCardUtils';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'DataSource';

// 限制一下title的长度，避免恶意构造很长的title导致数据超限
const TITLE_LEN_LIMIT: number = 100;

const QUERY_COLUMNS: string[] = [
  CalendarContract.EventsColumns.ID,
  `SUBSTR(${CalendarContract.EventsColumns.TITLE}, 1, ${TITLE_LEN_LIMIT}) AS ${CalendarContract.EventsColumns.TITLE}`,
  CalendarContract.EventsColumns.DTSTART,
  CalendarContract.EventsColumns.DTEND,
  CalendarContract.EventsColumns.RRULE,
  CalendarContract.EventsColumns.DURATION,
  CalendarContract.EventsColumns.EVENT_TIME_STAMP,
  CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
  CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE
];

const IMPORTANT_EVENT_TYPES: number[] = [
  CalendarContract.EventImportantType.ANNIVERSARIES,
  CalendarContract.EventImportantType.COUNTDOWN
];

const HOLIDAY_TYPES: number[] = [
  CalendarContract.EventImportantType.HOLIDAY
];

/**
 * 所有的Columns都需要从该方法获取
 * V1:新增附件字段attachment_count
 * @returns 所有需要查询的字段数组
 */
export async function getQueryColumns(): Promise<string[]> {
  const condition = [...QUERY_COLUMNS];
  if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
    condition.push(`attachment_count`);
  }
  return condition;
}

/**
 * 卡片数据源提供者。
 * 提供卡片数据代理的SQL，和卡片编辑预览页的数据查询。
 */
export class DataSource {
  /**
   * 注意保持逻辑与 ${#queryFixedImportant}一致
   */
  public static getFixedImportantProxy(eventIds: number[], queryColumns: string = QUERY_COLUMNS.join(',')): string {
    const selection: string = `${CalendarContract.EventsColumns.ID} in (${eventIds.join(',')})`;
    const querySql: string = DataSource.getQueryImportantOrHolidaySql(selection, IMPORTANT_EVENT_TYPES, queryColumns);
    return querySql;
  }

  /**
   * 注意保持逻辑与 ${#getFixedImportantProxy}一致
   */
  public static async queryFixedImportant(eventIds: number[]): Promise<ImportantEntity[]> {
    if (!eventIds || eventIds.length === 0) {
      Log.warn(TAG, `queryFixedImportant get invalid ids: ${eventIds}`);
      return [];
    }
    const fixedId: number = eventIds[0] ?? 0;
    if (fixedId <= 0) {
      Log.warn(TAG, `queryFixedImportant get invalid id: ${fixedId}`);
      return [];
    }
    const agendaList = await EventService.INSTANCE.queryImportantEvents(await getQueryColumns(), fixedId);
    return convertToImportantEntity(agendaList, false);
  }

  /**
   * 注意保持逻辑与 ${#queryFixedBirthday}一致
   */
  public static getFixedBirthdayProxy(eventIds: number[], queryColumns?: string[]): string {
    const eventIdColumn: string = `${CalendarContract.Tables.EVENTS}.${CalendarContract.EventsColumns.ID}`;
    const selection: string = `${eventIdColumn} in (${eventIds.join(',')})`;
    const querySql: string = DataSource.getQueryBirthdaySql(selection, queryColumns);
    return querySql;
  }

  /**
   * 注意保持逻辑与 ${#getFixedBirthdayProxy}一致
   */
  public static async queryFixedBirthday(eventIds: number[]): Promise<ImportantEntity[]> {
    if (!eventIds || eventIds.length === 0) {
      Log.warn(TAG, `queryFixedBirthday get invalid ids: ${eventIds}`);
      return [];
    }
    const fixedId: number = eventIds[0] ?? 0;
    if (fixedId <= 0) {
      Log.warn(TAG, `queryFixedBirthday get invalid id: ${fixedId}`);
      return [];
    }
    const agendaList = await EventService.INSTANCE.queryEventsByEventIds([fixedId], await getQueryColumns());
    return convertToImportantEntity(agendaList, true);
  }

  /**
   * 注意保持逻辑与 ${#queryFixedHoliday}一致
   */
  public static getFixedHolidayProxy(eventIds: number[], queryColumns: string = QUERY_COLUMNS.join(',')): string {
    // 指定的日程不按时间过滤
    const titleSelection: string = `SELECT ${CalendarContract.EventsColumns.TITLE} FROM ` +
      `${CalendarContract.Tables.EVENTS} WHERE ${CalendarContract.EventsColumns.ID} IN (${eventIds.join(',')})`;
    const selection: string = `${CalendarContract.EventsColumns.TITLE} in (${titleSelection})`;
    const querySql: string = DataSource.getQueryImportantOrHolidaySql(selection, HOLIDAY_TYPES, queryColumns);
    return querySql;
  }

  /**
   * 注意保持逻辑与 ${#getFixedHolidayProxy}一致
   */
  public static async queryFixedHoliday(eventIds: number[]): Promise<ImportantEntity[]> {
    if (!eventIds || eventIds.length === 0) {
      Log.warn(TAG, 'queryFixedHoliday get invalid param');
      return [];
    }
    const fixedId: number = eventIds[0] ?? 0;
    if (fixedId <= 0) {
      Log.warn(TAG, `queryFixedHoliday get invalid id: ${fixedId}`);
      return [];
    }
    const events: AgendaEventInfo[] =
      await EventService.INSTANCE.queryEventsByEventIds([fixedId], await getQueryColumns());
    const eventTitles: string[] = [];
    events.forEach((item: AgendaEventInfo) => {
      if (!item || !item.isHoliday()) {
        return;
      }
      const holidayName: string = item.mTitle ?? '';
      if (holidayName && holidayName.length > 0 && !eventTitles.includes(holidayName)) {
        eventTitles.push(holidayName);
      }
    });
    if (eventTitles.length === 0) {
      Log.warn(TAG, 'queryFixedHoliday cannot fetch titles');
      return [];
    }
    const agendaList = await EventService.INSTANCE.queryHolidaysByTitles(eventTitles);
    return convertToImportantEntity(agendaList, false);
  }

  public static async queryRecentImportant(): Promise<AgendaEventInfo[]> {
    const importantList: AgendaEventInfo[] = await EventService.INSTANCE.queryImportantEvents(await getQueryColumns());
    if (!importantList || importantList.length === 0) {
      Log.warn(TAG, 'queryRecentImportant no important event');
      return [];
    }
    DataSource.moveRecurrenceImportantToNow(importantList);
    DataSource.sortByImportantAndStart(importantList);
    const nowTime = Date.now();
    // 获取系统时区的偏移量
    const timeStampOffset = TimeZoneUtil.getTimeZoneOffset(TimeZoneUtil.getCurrentTimeZone(), nowTime);
    const nowDate: CalendarDate = new CalendarDate(nowTime + timeStampOffset);
    const agendaList: AgendaEventInfo[] = importantList.filter((item: AgendaEventInfo): boolean => {
      if (!item || !item.isImportantEvent()) {
        return false;
      }
      // 按照与${#getRecentImportantProxy}相同的过滤规则，过滤查询到的重要日
      let retain: boolean = false;
      if (item.isImportantAnniversaries()) {
        retain = item.mBegin < Date.now();
      } else if (item.isImportantCountDown()) {
        if (item.isRepeatEvent()) {
          retain = true;
        } else {
          const eventDate: CalendarDate = new CalendarDate(item.mEnd);
          retain = eventDate.getTime() > nowDate.getTime();
        }
      }
      return retain;
    });
    return agendaList;
  }

  public static async queryRecentBirthday(): Promise<AgendaEventInfo[]> {
    const calendars: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
    let birthdayCalendarId: number = -1;
    calendars?.forEach((item: CalendarContract.Accounts) => {
      if (!item) {
        return;
      }
      if (AccountUtils.isBirthDayAccount(item)) {
        birthdayCalendarId = item.id;
      }
    });
    if (birthdayCalendarId <= 0) {
      Log.warn(TAG, 'queryRecentBirthday no birthday calendar');
      return [];
    }
    Log.info(TAG, `birthday account ids: ${birthdayCalendarId}`);
    const now: number = Date.now();
    // 结束时间固定到当天0点+366天
    const oneYearLater: number = new CalendarDate(now).setHours(0, 0, 0) + 366 * MILLS_PER_DAY;
    const queryInfo: QueryInfo = {
      startTime: now,
      endTime: oneYearLater,
      calendarId: birthdayCalendarId
    };
    const birthdayList: AgendaEventInfo[] = await InstanceService.INSTANCE.queryInstanceAsync(queryInfo);
    if (!birthdayList || birthdayList.length === 0) {
      Log.warn(TAG, 'queryRecentBirthday no birthday event');
      return [];
    }
    DataSource.sortByDtStart(birthdayList);
    Log.info(TAG, `queryRecentBirthday size: ${birthdayList.length}`);
    return birthdayList;
  }

  /**
   * 注意保持逻辑与 ${#queryRecentHoliday}一致
   */
  public static getRecentHolidayProxy(queryColumns: string = QUERY_COLUMNS.join(',')): string {
    const localTimeNow: string = `strftime('%s', 'now', 'localtime') * 1000`;
    const lastDayTime: string = `strftime('%s', 'now', 'localtime', '+1 year', '+60 day') * 1000`;
    // 过滤最近一年左右的节日
    const timeSelection: string = `${CalendarContract.EventsColumns.DTEND} > ${localTimeNow} AND ` +
      `${CalendarContract.EventsColumns.DTSTART} < ${lastDayTime}`;
    // 过滤只支持7个法定节日+2个常用节日，其他不支持，不查询占用卡片缓存大小避免超限
    const titleSelection: string = `${CalendarContract.EventsColumns.TITLE} IN ` +
      `("${SUPPORT_CHINESE_HOLIDAYS.join('","')}")`;
    const selection: string = `(${timeSelection}) AND (${titleSelection})`;
    const querySql: string = DataSource.getQueryImportantOrHolidaySql(selection, HOLIDAY_TYPES, queryColumns);
    return querySql;
  }

  /**
   * 注意保持逻辑与 ${#getRecentHolidayProxy}一致
   */
  public static async queryRecentHoliday(): Promise<ImportantEntity[]> {
    const holidays: AgendaEventInfo[] = await EventService.INSTANCE.queryHolidaysByTitles(SUPPORT_CHINESE_HOLIDAYS,
      await getQueryColumns());
    if (!holidays || holidays.length === 0) {
      Log.warn(TAG, 'queryRecentHoliday no recent holiday');
      return getRecentLocalHolidayEntities();
    }
    const agendaList: AgendaEventInfo[] = holidays.filter((item: AgendaEventInfo): boolean => {
      if (!item || !item.isHoliday()) {
        return false;
      }
      // 按照与${#getRecentHolidayProxy}相同的过滤规则，过滤查询到的节日
      const now: number = Date.now();
      const oneYearTwoMonthDays: number = 366 + 60;
      const lastDayTime: number = now + oneYearTwoMonthDays * MILLS_PER_DAY;
      return item.mEnd > now && item.mBegin < lastDayTime;
    });
    agendaList.sort((holidayA, holidayB) => holidayA.mBegin - holidayB.mBegin);
    return agendaList.length > 0 ? convertToImportantEntity(agendaList, false) : getRecentLocalHolidayEntities();
  }

  private static getQueryImportantOrHolidaySql(where: string, types: number[], queryColumns: string, limit?: number) {
    let sql: string = `SELECT ${queryColumns} FROM ${CalendarContract.Tables.EVENTS} WHERE`;
    if (where && where.length > 0) {
      sql += ` ${where} AND`;
    }
    sql += ` ${CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE} in (${types.join(',')})` +
      ` ORDER BY ${CalendarContract.EventsColumns.DTSTART} ASC`;
    if (limit && limit > 0) {
      sql += ` limit ${limit}`;
    }
    return sql;
  }

  private static getQueryBirthdaySql(where: string, queryColumns: string[] = QUERY_COLUMNS,
    bundleNames?: string[], limit?: number): string {
    // 组装查询的columns，处理多表字段冲突，添加帐户type字段，添加identify字段
    const columns: string[] = [...queryColumns];
    const idIndex: number | undefined = columns.findIndex((column: string) => {
      return column === CalendarContract.EventsColumns.ID;
    });
    if (idIndex !== undefined) {
      columns[idIndex] = `${CalendarContract.Tables.EVENTS}.${CalendarContract.EventsColumns.ID} as ` +
        `${CalendarContract.EventsColumns.ID}`;
    }
    columns.push(`${CalendarContract.Tables.CALENDARS}.${CalendarContract.AccountColumns.ACCOUNT_TYPE} as ` +
      `${CalendarContract.AccountColumns.ACCOUNT_TYPE}`);
    columns.push(`${CalendarContract.EventsColumns.IDENTIFIER}`);

    // 联表Events表+Calendars查询
    const tables: string = `${CalendarContract.Tables.EVENTS} LEFT JOIN ${CalendarContract.Tables.CALENDARS} ON ` +
      `${CalendarContract.Tables.EVENTS}.${CalendarContract.EventsColumns.CALENDAR_ID} = ` +
      `${CalendarContract.Tables.CALENDARS}.${CalendarContract.AccountColumns.ID}`;

    // 拼接查询sql语句
    let sql: string = `SELECT ${columns.join(',')} FROM ${tables} WHERE`;
    if (where && where.length > 0) {
      sql += ` (${where}) AND`;
    }
    if (bundleNames && bundleNames.length > 0) {
      const calendarCreator: string = `${CalendarContract.Tables.CALENDARS}.${CalendarContract.AccountColumns.CREATOR}`;
      sql += ` ${calendarCreator} in ${bundleNames.join(',')} AND`;
    }
    const accountType: string = `${CalendarContract.Tables.CALENDARS}.${CalendarContract.AccountColumns.ACCOUNT_TYPE}`;
    const calendarVisible: string = `${CalendarContract.Tables.CALENDARS}.${CalendarContract.AccountColumns.VISIBLE}`;
    sql += ` ${accountType}='${calendarManager.CalendarType.BIRTHDAY}' AND ${calendarVisible}=1` +
      ` ORDER BY ${CalendarContract.EventsColumns.DTSTART} ASC`;
    if (limit && limit > 0) {
      sql += ` LIMIT ${limit}`;
    }
    return sql;
  }

  private static sortByDtStart(events: AgendaEventInfo[]): void {
    if (!events || events.length === 0) {
      return;
    }
    events.sort((itemA: AgendaEventInfo, itemB: AgendaEventInfo): number => {
      if (!itemA || !itemB) {
        return 0;
      }
      return itemA.mBegin - itemB.mBegin;
    });
  }

  private static moveRecurrenceImportantToNow(events: AgendaEventInfo[]): void {
    if (!events || events.length === 0) {
      return;
    }
    const now = new CalendarDate();
    events.forEach((important: AgendaEventInfo) => {
      if (!important || !important.isRepeatEvent() || !important.isImportantCountDown()) {
        // 非循环重要日，不需要处理
        return;
      }
      important.mBegin = getAdaptImportantTime(important.mEventCalendar, important.mOriginalBegin,
        important.mRepeatRule, now);
      important.mEnd = important.mBegin - important.mOriginalBegin + important.mOriginalEnd;
    });
  }

  private static sortByImportantAndStart(events: AgendaEventInfo[]): void {
    if (!events || events.length === 0) {
      return;
    }
    events.sort((itemA: AgendaEventInfo, itemB: AgendaEventInfo): number => {
      if (!itemA || !itemB) {
        return 0;
      }
      if (!itemA.isImportantEvent() || !itemB.isImportantEvent()) {
        return 0;
      }
      if (itemA.isImportantCountDown() && itemB.isImportantAnniversaries()) {
        // 倒数日比纪念日优先级高，-1表示倒数日要往前排序
        return -1;
      } else if (itemA.isImportantAnniversaries() && itemB.isImportantCountDown()) {
        // 倒数日比纪念日优先级高，1表示纪念日要往后排序
        return 1;
      } else if (itemA.isImportantCountDown() && itemB.isImportantCountDown()) {
        // 都是倒数日，时间小的往前排序
        return itemA.mBegin - itemB.mBegin;
      } else if (itemA.isImportantAnniversaries() && itemB.isImportantAnniversaries()) {
        // 都是纪念日，时间大的往后排序
        return itemB.mBegin - itemA.mBegin;
      }
      return 0;
    });
  }
}
