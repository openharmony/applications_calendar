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

import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import i18n from '@ohos.i18n';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { TimeZoneUtil } from '@app/common';

// 重要日，最高优先级
const SORT_PRIORITY_IMPORTANT: number = 1;

// 生日，次等优先级
const SORT_PRIORITY_BIRTHDAY: number = 2;

// 节假日，中等优先级
const SORT_PRIORITY_HOLIDAY: number = 5;

// 默认优先级，最低优先级
const SORT_PRIORITY_DEFAULT: number = 9;

const TAG = 'ImportantEntity';

/**
 * 重要日卡片数据代理返回的数据model，字段名与数据库字段名对应(query sql)
 */
class ImportantEntity {
  public eventId: number = 0;

  public title: string = '';

  public originalBegin: number = 0;

  public begin: number = 0;

  public end: number = 0;

  public rrule: string = '';

  public duration: string = '';

  public eventTimeStamp: number = 0;

  public importantEventType: number = 0;

  public eventCalendarType: number = 0;

  public accountType: string = '';

  public identifier: string = '';

  public mAttachmentCount: number = 0;

  constructor(dbData?: object) {
    if (!dbData) {
      Log.error(TAG, 'dbData is null');
      return;
    }
    this.eventId = dbData[CalendarContract.EventsColumns.ID] ?? 0;
    this.title = dbData[CalendarContract.EventsColumns.TITLE] ?? '';
    this.begin = dbData[CalendarContract.EventsColumns.DTSTART] ?? 0;
    this.originalBegin = this.begin;
    this.end = dbData[CalendarContract.EventsColumns.DTEND] ?? 0;
    this.rrule = dbData[CalendarContract.EventsColumns.RRULE] ?? '';
    this.duration = dbData[CalendarContract.EventsColumns.DURATION] ?? '';
    this.eventTimeStamp = dbData[CalendarContract.EventsColumns.EVENT_TIME_STAMP] ?? 0;
    this.importantEventType = dbData[CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE] ?? 0;
    this.eventCalendarType = dbData[CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE] ?? 0;
    this.accountType = dbData[CalendarContract.SyncColumns.ACCOUNT_TYPE] ?? '';
    this.identifier = dbData[CalendarContract.EventsColumns.IDENTIFIER] ?? '';
    this.mAttachmentCount = dbData[CalendarContract.EventsColumns.ATTACHMENT_COUNT] ?? 0;
  }

  public isValid(): boolean {
    return (this.eventId > 0 || (this.eventId === 0 &&
      this.importantEventType === CalendarContract.EventImportantType.HOLIDAY && this.title !== '')) &&
      (this.importantEventType !== 0 || this.isBirthday());
  }

  public isBirthday(): boolean {
    return this.accountType === CalendarContract.CalendarType.BIRTHDAY;
  }

  public isExpired(): boolean {
    if (this.importantEventType === CalendarContract.EventImportantType.ANNIVERSARIES) {
      // 1.纪念日，不存在过期
      return false;
    }
    // 2.倒数日、节假日、生日，按是否周期日程做不同处理
    if (this.rrule) {
      // 周期性，不会过期
      return false;
    }
    const eventDate: CalendarDate = new CalendarDate(this.end);
    const nowTime = Date.now();
    // 获取系统时区的偏移量
    const timeStampOffset = TimeZoneUtil.getTimeZoneOffset(TimeZoneUtil.getCurrentTimeZone(), nowTime);
    const nowDate: CalendarDate = new CalendarDate(nowTime + timeStampOffset);
    // 非周期性日程，检查日期是否过期
    return eventDate.getTime() < nowDate.getTime();
  }

  /**
   * 获取数据的排序优先级等级
   *
   * @returns 优先级
   */
  public getSortPriority(): number {
    if (this.importantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
      this.importantEventType === CalendarContract.EventImportantType.COUNTDOWN) {
      return SORT_PRIORITY_IMPORTANT;
    }
    if (this.isBirthday()) {
      return SORT_PRIORITY_BIRTHDAY;
    }
    if (this.importantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return SORT_PRIORITY_HOLIDAY;
    }
    return SORT_PRIORITY_DEFAULT;
  }
}

// 判断是倒数日或者节假日
export function isCountdownOrHoliday(type: number) {
  return type === CalendarContract.EventImportantType.COUNTDOWN || type === CalendarContract.EventImportantType.HOLIDAY;
}

export {
  ImportantEntity
}
