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

import { CalendarBuilder } from './CalendarBuilder';
import { CalendarInfo } from '../../CalendarInfo';
import {
  BEGIN_V_CALENDAR,
  BEGIN_V_EVENT,
  END_V_CALENDAR,
  NEW_LINE,
  V_SPLIT,
  VACCOUNT_COLOR,
  VACCOUNT_DISPLAYNAME,
  VEVENT_COUNT
} from '../../VCalendarConstants';
import { AgendaEventInfo, AgendaEventInfoWrap, CalendarContract, EmptyUtils,
  isOperatorSoftbank,
  Log,
  wait} from '@app/common';
import { DOWNIMPORTANTEVENTTYPE, EVENTTYPEEXT, EX_DATE, LUNAR, NORMALEVENTTYPE, SOLAR, UPIMPORTANTEVENTTYPE } from '../../import/parser/CalendarParser';
import { VCalUtils } from '../../VCalUtils';
import HashMap from '@ohos.util.HashMap';
import { CustomTime, FormatBit, FormatTime, SplitOption } from '@app/feature.repeatrule';
import { WriteSyncStream } from '@app/common/src/main/ets/util/WriteSyncStream';
import { canEncodeInThisCharset } from '@app/common/src/main/ets/util/CharsetUtil';
import { QuotedPrintableHelper } from '../../QuotedPrintableHelper';
import { ExportProgressListener } from '../../../ExportProgressListener';
import { taskpool } from '@kit.ArkTS';

const TAG = 'CalendarBuilder_V20';

/**
 * Calendar.Calendars.STATUS_TENTATIVE
 */
const STATUS_TENTATIVE = 0;

/**
 * Calendar.Calendars.STATUS_CONFIRMED
 */
const STATUS_CONFIRMED = 1;

/**
 * Calendar.Calendars.STATUS_CANCELED
 */
const STATUS_CANCELED = 2;

const COLON = ':';

const TENTATIVE = 'TENTATIVE';

const CONFIRMED = 'CONFIRMED';

const DECLINED = 'DECLINED';

const ONE_NAVIGATE = -1;

const ZERO = 0;

const ONE = 1;

const TWO = 2;

const THREE = 3;

export const US_ASCII: string = 'US-ASCII';

export const ISO_8859_1: string = 'ISO-8859-1';

export const UTF_8: string = 'UTF-8';

export const UTF_16BE: string = 'UTF-16BE';

export const UTF_16LE: string = 'UTF-16LE';

export const UTF_16: string = 'UTF-16';

export const GBK: string = 'GBK';

//日本的编码
export const SHIFT_JIS: string = 'SHIFT_JIS';

const ENCODING_QUOTED_PRINTABLE = ';ENCODING=QUOTED-PRINTABLE:';

/**
 * 版本2的 构建者 ,多日程和账户导出
 */
export class CalendarBuilderV20 extends CalendarBuilder {
  public stream = new WriteSyncStream;

  private mCharsetEncoding: string = GBK;
  private isCanceled: boolean = false;

  /**
   * 2.0版本builder
   *
   * @param calendarInfo 日历信息
   */
  public constructor(calendarInfo: CalendarInfo) {
    super(calendarInfo)
  }

  /**
   *
   * @param account
   * @param events
   * @param reminderMap
   * @returns
   */
  async buildExportFile(account: CalendarContract.Accounts | undefined, events: Array<AgendaEventInfo>,
                        reminderMap: HashMap<number, Array<CalendarContract.Reminders>>): Promise<boolean> {
    if (!account && EmptyUtils.isEmptyArray(events)) {
      Log.error(TAG, `buildExportFile account is null and events is Empty`);
      return false;
    }
    try {
      if (account && EmptyUtils.isNotEmptyString(account.calendarDisplayName)) {
        return await this.buildExportFileByAccount(account as CalendarContract.Accounts, events, reminderMap);
      } else {
        return await this.buildExportFileByEvents(events, reminderMap);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'buildExportFile error', err);
    }
    return false;
  }

  public setOutputFilePath(outputFilePath: string) {
    this.outputFilePath = outputFilePath;
  }

  private writeHeader(timeZoneId: string) {
    const timezoneLabel: string = VCalUtils.getTimezoneLabel(timeZoneId);
    const headerString: string = BEGIN_V_CALENDAR + NEW_LINE + this.getVersion() + NEW_LINE +
      'BEGIN:VTIMEZONE' + NEW_LINE +
      'TZID:' + timeZoneId + NEW_LINE +
      'BEGIN:STANDARD' + NEW_LINE +
      'DTSTART:16010101T000000' + NEW_LINE +
      'TZOFFSETFROM:' + timezoneLabel + NEW_LINE +
      'TZOFFSETTO:' + timezoneLabel + NEW_LINE +
      'END:STANDARD' + NEW_LINE +
      'END:VTIMEZONE' + NEW_LINE;
    let number: number = this.stream.writeSync(headerString);
  }

  private writeCalendarAccount(account: CalendarContract.Accounts | undefined, events: Array<AgendaEventInfo>) {
    if (!account) {
      return;
    }
    const eventCount: number = EmptyUtils.isEmptyArray(events) ? 0 : events.length;
    const calendarAccountString: string = VEVENT_COUNT + V_SPLIT + (eventCount + '') + NEW_LINE +
      VACCOUNT_COLOR + V_SPLIT + account.calendarColor + NEW_LINE +
      VACCOUNT_DISPLAYNAME + V_SPLIT + account.calendarDisplayName + NEW_LINE;
    let number: number = this.stream.writeSync(calendarAccountString);
  }

  private writeEventsCount(eventCount: number) {
    const eventCountString: string = VEVENT_COUNT + V_SPLIT + eventCount + NEW_LINE;
    let number: number = this.stream.writeSync(eventCountString);
  }

  private writeFooter() {
    const footer: string = END_V_CALENDAR;
    let number: number = this.stream.writeSync(footer);
  }

  /**
   * 获取版本信息
   *
   * @return version
   */
  public getVersion(): string {
    return 'VERSION:2.0';
  }

  cancel(): void {
    this.isCanceled = true;
  }

  private async buildExportFileByEvents(events: AgendaEventInfo[],
                                        reminderMap: HashMap<number,
                                        CalendarContract.Reminders[]>): Promise<boolean> {
    try {
      this.stream.create(this.outputFilePath, 'w+');
      this.writeHeader(this.calendarInfo.getTimezone());
      this.writeEventsCount(events.length)
      await this.writeEventsToFile(events, reminderMap);
      this.writeFooter();
    } catch (err) {
      Log.logErrorMsg(TAG, 'buildExportFileByEvents', err);
      return false;
    } finally {
      this.stream.closeSync();
      Log.debug(TAG, 'buildExportFileByEvents close sync');
    }
    return true;
  }

  private async buildExportFileByAccount(account: CalendarContract.Accounts,
                                   events: AgendaEventInfo[],
                                   reminderMap: HashMap<number, Array<CalendarContract.Reminders>>): Promise<boolean> {
    try {
      this.stream.create(this.outputFilePath, 'w+');
      this.writeHeader(this.calendarInfo.getTimezone());
      this.writeCalendarAccount(account, events);
      await this.writeEventsToFile(events, reminderMap);
      this.writeFooter();
    } catch (err) {
      Log.logErrorMsg(TAG, 'buildExportFileByEvents', err);
      return false;
    } finally {
      this.stream.closeSync();
      Log.debug(TAG, 'buildExportFileByEvents close sync');
    }
    return true;
  }

  private async writeEventsToFile(events: AgendaEventInfo[],
                                  reminderMap: HashMap<number, CalendarContract.Reminders[]>): Promise<void> {
    const totalCount = events.length;
    let handledCount = 0;
    const step = 10;
    for (let event of events) {
      if (this.isCanceled) {
        return;
      }
      const agendaEventInfoWrap: AgendaEventInfoWrap = event as AgendaEventInfoWrap;
      if (reminderMap.hasKey(agendaEventInfoWrap.mId)) {
        agendaEventInfoWrap.reminders = reminderMap.get(agendaEventInfoWrap.mId);
      }
      this.writeEvent(agendaEventInfoWrap);
      if (handledCount % step === 0 || (handledCount === totalCount - 1)) {
        handledCount++;
        try {
          taskpool.Task.sendData(totalCount, handledCount);
        } catch (err) {
          Log.logErrorMsg(TAG, 'callParseFinished error:', err)
        }
        await wait(1);
      } else {
        handledCount++;
      }
    }
  }

  private writeEvent(eventInfo: AgendaEventInfoWrap) {
    let eventString: string = BEGIN_V_EVENT + NEW_LINE;
    eventString += this.writeDescription(eventInfo);
    eventString += this.writeServiceDescription(eventInfo);
    eventString += this.writeServiceVerified(eventInfo);
    eventString += this.writeServiceType(eventInfo);
    eventString += this.writeServiceUri(eventInfo);
    eventString += this.writeDtStartAndEnd(eventInfo);
    eventString += this.writeDuration(eventInfo);
    eventString += this.writeLocation(eventInfo);
    eventString += this.writeComplete(eventInfo);
    eventString += this.writeRule(eventInfo);
    eventString += this.writeExData(eventInfo);
    eventString += this.writeTitle(eventInfo);
    eventString += this.writeStatus(eventInfo);
    eventString += this.writeAlarm(eventInfo);
    eventString += this.writeClass(eventInfo);
    eventString += this.writeEventType(eventInfo);
    eventString += this.writeAlertType(eventInfo);
    eventString += this.writeEventImageType(eventInfo);
    eventString += 'END:VEVENT' + NEW_LINE;
    let number: number = this.stream.writeSync(eventString);
  }

  private writeComplete(eventInfo: AgendaEventInfoWrap): string {
    if (eventInfo.mEndDay > 0) {
      return 'COMPLETED:' + this.getFormatLastDate(eventInfo) + NEW_LINE;
    }
    return '';
  }

  private getFormatLastDate(eventInfo: AgendaEventInfoWrap): string {
    return this.getIso8601Format(eventInfo.lastDate);
  }

  private writeEventType(eventInfo: AgendaEventInfoWrap): string {
    const eventTypeString: string = eventInfo.mImportantEventType == 0 ?
      NORMALEVENTTYPE : (eventInfo.mImportantEventType == 1 ? UPIMPORTANTEVENTTYPE : DOWNIMPORTANTEVENTTYPE);
    return EVENTTYPEEXT + COLON + eventTypeString + NEW_LINE;
  }

  private writeRule(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mRepeatRule, true)) {
      return 'RRULE:' + eventInfo.mRepeatRule + NEW_LINE;
    }
    return '';
  }

  private writeExData(eventInfo: AgendaEventInfoWrap) {
    if (EmptyUtils.isNotEmptyString(eventInfo.exDate, true)) {
      return EX_DATE + COLON + eventInfo.exDate + NEW_LINE;
    }
    return ''
  }

  // for iCal 2.0 no char set parameter is required , only for vCal 1.0
  // only its necessary. FOr iCal 2.0 the char set property is defined at

  private writeStatus(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isEmptyString(eventInfo.status, true)) {
      return '';
    }
    const statusValue: Number = Number(eventInfo.status);
    let statusString: string = '';
    if (Number.isNaN(statusValue)) {
      return statusString;
    }
    switch (statusValue) {
      case ZERO:
        statusString = TENTATIVE;
        break;
      case ONE:
        statusString = CONFIRMED;
        break;
      case TWO:
        statusString = DECLINED;
        break;
      default:
        statusString = TENTATIVE;
        break;
    }
    return 'STATUS:' + statusString + NEW_LINE;
  }

  private writeTitle(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mTitle, true)) {
      return 'SUMMARY:' + eventInfo.mTitle + NEW_LINE;
    }
    return '';
  }

  // the content type level not at property level
  private writeLocation(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mLocation, true)) {
      return 'LOCATION:' + eventInfo.mLocation + NEW_LINE;
    }
    return '';
  }

  /**
   * for iCal 2.0 no char set parameter is required , only for vCal 1.0
   * only its necessary. For iCal 2.0 the char set property is defined at
   * the content type level not at property level
   * @param eventInfo
   * @returns
   */
  private writeDescription(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mDescription, true)) {
      // 去掉空白行
      if (eventInfo.mHwextServiceType === 'Meeting') {
        eventInfo.mDescription = this.removeLinebreaks(eventInfo.mDescription);
      }
      return 'DESCRIPTION:' + this.foldString(eventInfo.mDescription) + NEW_LINE;
    }
    return '';
  }

  private writeServiceDescription(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mHwextServiceDescription, true)) {
      return 'SERVICEDESCRIPTION;CHARSET=' + this.getSuitableCharset(eventInfo.mHwextServiceDescription) +
        ENCODING_QUOTED_PRINTABLE +
        this.encodeQuotedPrintable(eventInfo.mHwextServiceDescription, this.mCharsetEncoding) +
        NEW_LINE;
    }
    return '';
  }

  private writeServiceVerified(eventInfo: AgendaEventInfoWrap): string {
    return 'SERVICEVERIFIED:' + eventInfo.mHwextServiceVerified + NEW_LINE;
  }

  private writeServiceType(eventInfo: AgendaEventInfoWrap): string {
    return 'SERVICETYPE:' + eventInfo.mHwextServiceType + NEW_LINE;
  }

  private writeServiceUri(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mHwextServiceUri, true)) {
      return 'SERVICEURI;CHARSET=' + this.getSuitableCharset(eventInfo.mHwextServiceUri) +
        ENCODING_QUOTED_PRINTABLE + this.encodeQuotedPrintable(eventInfo.mHwextServiceUri, this.mCharsetEncoding) +
        NEW_LINE;
    }
    return '';
  }

  /**
   * 写入的时候都是使用的calendarInfo里的时区,单个日程的eventTimeZone被忽略了,如果之前都是上海的时区,
   * 现在把时区修改为+6,是不是格式化的字符串小时少2 双框架就是这样的(保证时间毫秒值正确就行)
   * @param eventInfo
   * @returns
   */
  private writeDtStartAndEnd(eventInfo: AgendaEventInfoWrap): string {
    let dtStartString: string = '';
    let dtEndString: string = '';
    if (eventInfo.mEnd > 0) {
      if (eventInfo.mIsAllDay) { // 普通全体日程
        dtEndString = 'DTEND;VALUE=DATE:' + this.getAllDayFormat(eventInfo.mEnd);
      } else { // 普通日程
        dtEndString = 'DTEND:' + this.getIso8601Format(eventInfo.mEnd);
      }
      dtEndString += NEW_LINE;
    }
    if (eventInfo.mBegin > 0) {
      if (eventInfo.mIsAllDay) {
        dtStartString = 'DTSTART;VALUE=DATE:' + this.getAllDayFormat(eventInfo.mBegin);
      } else {
        dtStartString = 'DTSTART:' + this.getIso8601Format(eventInfo.mBegin);
      }
      dtStartString += NEW_LINE;
    }
    return dtEndString + dtStartString;
  }

  private getIso8601Format(timeMills: number) {
    const customTime: CustomTime = new CustomTime(this.iso8601FormatPara.tzId);
    customTime.setTime(timeMills);
    return new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS);
  }

  /**
   * 版本二全天日程需要是yyyyMMdd格式
   * @param timeMills
   * @returns
   */
  private getAllDayFormat(timeMills: number) {
    const customTime: CustomTime = new CustomTime(this.mAllDayEventFormatPara.tzId);
    customTime.setTime(timeMills);
    const splitOption: SplitOption = {
      yearSplit: '',
      monthSplit: '',
      daySplit: '',
      hourSplit: '',
      minuteSplit: '',
      secondSplit: '',
    };
    return new FormatTime().setByCustomTime(customTime).format(FormatBit.DAY, splitOption);
  }

  /**
   * @param eventInfo
   * @returns
   */
  private writeDuration(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.duration)) {
      return 'DUE:' + eventInfo.duration + NEW_LINE;
    }
    return '';
  }

  private writeClass(eventInfo: AgendaEventInfoWrap): string {
    if (ZERO == eventInfo.accessLevel || THREE == eventInfo.accessLevel) {
      return 'CLASS:PUBLIC' + NEW_LINE;
    }
    if (TWO == eventInfo.accessLevel) {
      return 'CLASS:PRIVATE' + NEW_LINE;
    }
    return '';
  }

  private writeAlarm(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isEmptyArray(eventInfo.reminders)) {
      Log.info(TAG, `writeAlarm eventId is ${eventInfo.mId} reminders is empty`);
      return '';
    }
    let reminderString = '';
    for (let reminder of eventInfo.reminders) {
      reminderString += 'BEGIN:VALARM' + NEW_LINE +
        'ACTION:AUDIO' + NEW_LINE +
        'TRIGGER:-PT' + reminder.remindMinutes + 'M' + NEW_LINE +
        'END:VALARM' + NEW_LINE;
    }
    return reminderString;
  }

  private writeAlertType(eventInfo: AgendaEventInfoWrap): string {
    return 'EVENTALERTTYPE:' + (eventInfo.alertType == CalendarContract.AgendaAlertType.NORMAL ? 'NORMALALERT' : 'IMPORTANTALERT') + NEW_LINE +
      'EVENTCALENDARTYPE:' + (eventInfo.mEventCalendar == CalendarContract.AgendaCalendarType.LUNAR ? LUNAR : SOLAR) + NEW_LINE;
  }

  private writeEventImageType(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mEventImageType, true)) {
      return 'EVENTIMAGETYPE:' + eventInfo.mEventImageType + NEW_LINE;
    }
    return '';
  }

  private getSuitableCharset(inputString: string): string {
    if (!isOperatorSoftbank()) {
      this.mCharsetEncoding = UTF_8;
    } else {
      if (canEncodeInThisCharset(inputString, US_ASCII)) {
        this.mCharsetEncoding = US_ASCII;
      } else if (canEncodeInThisCharset(inputString, SHIFT_JIS)) {
        this.mCharsetEncoding = SHIFT_JIS;
      }
      this.mCharsetEncoding = GBK;
    }
    return this.mCharsetEncoding
  }

  private encodeQuotedPrintable(buffer: string, charSet: string): string {
    return QuotedPrintableHelper.getInstance().encodeQuotedPrintable(buffer, charSet);
  }

}
