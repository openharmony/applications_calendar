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

import { AgendaEventInfo, AgendaEventInfoWrap, CalendarContract,
  CalendarDate,
  EmptyUtils, MILLS_PER_MINUTE, UTC } from '@app/common';
import { CalendarBuilder } from './CalendarBuilder';
import { CalendarInfo } from '../../CalendarInfo';
import { VCalUtils } from '../../VCalUtils';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { END_V_CALENDAR, NEW_LINE } from '../../VCalendarConstants';
import {
  DOWNIMPORTANTEVENTTYPE,
  EVENTIMAGETYPE,
  EX_DATE,
  IMPORTANTALERT,
  LUNAR,
  NORMALALERT,
  NORMALEVENTTYPE,
  RRULE,
  SOLAR,
  STATUS,
  UPIMPORTANTEVENTTYPE
} from '../../import/parser/CalendarParser';
import { canEncodeInThisCharset, GBK, isOperatorSoftbank, SHIFT_JIS, US_ASCII, UTF_8 } from '@app/common/src/main/ets/util/CharsetUtil';
import { CustomTime, Duration, FormatBit, FormatTime } from '@app/feature.repeatrule';
import HashMap from '@ohos.util.HashMap';
import { QuotedPrintableHelper } from '../../QuotedPrintableHelper';
import { WriteSyncStream } from '@app/common/src/main/ets/util/WriteSyncStream';

const TAG = 'CalendarBuilder_V10';

const ENCODING_QUOTED_PRINTABLE = ';ENCODING=QUOTED-PRINTABLE:';

const DTEND = 'DTEND:';

const SPACE = ' ';

const COLON = ':';

const TENTATIVE = 'TENTATIVE';

const CONFIRMED = 'CONFIRMED';

const DECLINED = 'DECLINED';

const ONE_NAVIGATE = -1;

const ZERO = 0;

const ONE = 1;

const TWO = 2;

const THREE = 3;

const EIGHT = 8;

/**
 * 版本1.0的构建者 单个日程导出vcs文件
 *
 */
export class CalendarBuilderV10 extends CalendarBuilder {
  public stream = new WriteSyncStream;
  private date: CalendarDate;
  private mCharsetEncoding: string;

  public constructor(calendarInfo: CalendarInfo) {
    super(calendarInfo)
    this.mCharsetEncoding = GBK;
    this.date = new CalendarDate();
  }

  public getVersion(): string {
    return 'VERSION:1.0';
  }

  async buildExportFile(account: CalendarContract.Accounts | undefined,
                        events: Array<AgendaEventInfo>,
                        reminderMap: HashMap<number, Array<CalendarContract.Reminders>>): Promise<boolean> {
    try {
      this.stream.create(this.outputFilePath, 'w+');
      this.writeHeader(this.calendarInfo.getTimezone());
      if (events.length == 0) {
        return false;
      }
      const agendaEventInfoWrap: AgendaEventInfoWrap = events[0] as AgendaEventInfoWrap;
      if (reminderMap.hasKey(agendaEventInfoWrap.mId)) {
        agendaEventInfoWrap.reminders = reminderMap.get(agendaEventInfoWrap.mId);
      }
      this.writeEvent(agendaEventInfoWrap);
      this.writeFooter();
    } catch (err) {
      Log.logErrorMsg(TAG, 'buildExportFile', err);
      return false;
    } finally {
      this.stream.closeSync();
      Log.debug(TAG, 'buildExportFile close sync');
    }
    return true;
  }


  public setEncoding(encoding: string) {
    this.mCharsetEncoding = encoding;
  }


  public setOutputFilePath(outputFilePath: string) {
    this.outputFilePath = outputFilePath;
  }

  public writeFooter() {
    let number: number = this.stream.writeSync(END_V_CALENDAR);
  }

  public writeHeader(timeZoneId: string) {
    const timezoneLabel: string = VCalUtils.getTimezoneLabel(timeZoneId);
    Log.info(TAG, `writeHeader timeZoneId is ${timeZoneId} timezoneLabel is ${timezoneLabel}`);
    let header: string = 'BEGIN:VCALENDAR' + NEW_LINE;
    header = header + ('VERSION:1.0' + NEW_LINE);
    header = header + ('TZ:' + timezoneLabel + NEW_LINE);
    // todo 写入文件GBK编码不支持
    let number: number = this.stream.writeSync(header);
    Log.info(TAG, 'writeHeader success');
  }

  public encodeQuotedPrintable(buffer: string, charSet: string): string {
    return QuotedPrintableHelper.getInstance().encodeQuotedPrintable(buffer, charSet);
  }

  /**
   * (non-Javadoc)
   *
   * BEGIN:VCALENDAR
   * VERSION:1.0
   * TZ:+08:00
   * BEGIN:VEVENT
   * COMPLETED:20231207T130000
   * DTSTART:20231207T120000
   * AALARM:20231207T035000;;;
   * CLASS:PUBLIC
   * DTEND:20231207T130000
   * SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E5=8F=91=E5=A4=AA=E5=A4=AA=E5=A4=AA
   * STATUS:CONFIRMED
   * EVENTTYPEEXT:NORMALEVENTTYPE
   * EVENTALERTTYPE:NORMALALERT
   * EVENTCALENDARTYPE:SOLAR
   * END:VEVENT
   * END:VCALENDAR
   */
  private writeEvent(eventInfo: AgendaEventInfoWrap) {
    let eventString: string = 'BEGIN:VEVENT' + NEW_LINE;
    eventString += this.writeComplete(eventInfo);
    eventString += this.writeStartAndAlarm(eventInfo);
    eventString += this.writeClass(eventInfo);
    eventString += this.writeDtEnd(eventInfo);
    eventString += this.writeDescription(eventInfo);
    eventString += this.writeServiceDescription(eventInfo);
    eventString += this.writeServiceVerified(eventInfo);
    eventString += this.writeServiceType(eventInfo);
    eventString += this.writeServiceUri(eventInfo);
    eventString += this.writeLocation(eventInfo);
    eventString += this.writeTitle(eventInfo);
    eventString += this.writeRule(eventInfo);
    eventString += this.writeExData(eventInfo);
    eventString += this.writeStatus(eventInfo.status);
    eventString += this.writeEventType(eventInfo);
    eventString += this.writeAlertType(eventInfo);
    eventString += this.writeEventImageType(eventInfo);
    eventString += 'END:VEVENT' + NEW_LINE;
    let number: number = this.stream.writeSync(eventString);
  }

  private writeComplete(eventInfo: AgendaEventInfoWrap): string {
    return 'COMPLETED:' + this.getFormatLastDate(eventInfo) + NEW_LINE;
  }

  // todo 单框架新建日程时没有插入lastdate字段
  private getFormatLastDate(eventInfo: AgendaEventInfoWrap): string {
    let lastDate: number = eventInfo.lastDate;
    Log.info(TAG, `getFormatLastDate ${lastDate}`);
    if (eventInfo.isRepeatEvent()) {
      return '';
    }
    if (lastDate <= 0) {
      lastDate = eventInfo.mEnd;
      if (lastDate < eventInfo.mBegin) {
        lastDate = eventInfo.mBegin;
      }
      Log.info(TAG, `getFormatLastDate after amend ${lastDate}`);
    }
    /**
     * Format this time like 'yyyyMMddThhmmssZ'
     */
    if (isOperatorSoftbank() && eventInfo.mIsAllDay) {
      return new FormatTime().getTimeInFormat2445(lastDate, eventInfo.eventTimeZone);
    } else {
      return this.formatIso8601(lastDate);
    }
  }

  /**
   * 转化为 Iso8601格式的 时间格式字符串
   * yyyyMMdd'T'HHmmss 20231207T130000
   * 单框架所有的日程都是UTC 时区,导致转化为时间格式字符串时相比上海会少8个小时,不过使用Parse解析的时间解析出来的时间毫秒值不会有偏差
   * 单框架的date类,格式化字符串默认会使用currentTimeZone做偏移
   * @param timeInMills
   */
  private formatIso8601(timeInMills: number): string {
    const customTime: CustomTime = new CustomTime(this.iso8601FormatPara.tzId);
    customTime.setTime(timeInMills);
    return new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS);
  }

  private writeEventType(eventInfo: AgendaEventInfoWrap): string {
    const eventTypeString: string = eventInfo.mImportantEventType == 0 ?
      NORMALEVENTTYPE : (eventInfo.mImportantEventType == 1 ? UPIMPORTANTEVENTTYPE : DOWNIMPORTANTEVENTTYPE);
    return 'EVENTTYPEEXT:' + eventTypeString + NEW_LINE;
  }

  private writeAlertType(eventInfo: AgendaEventInfoWrap): string {
    const eventAlertType: string = eventInfo.alertType == CalendarContract.AgendaAlertType.NORMAL ?
      NORMALALERT : IMPORTANTALERT;
    const eventCalendarType: string = eventInfo.mEventCalendar == CalendarContract.AgendaCalendarType.LUNAR ?
      LUNAR : SOLAR;
    return 'EVENTALERTTYPE:' + eventAlertType + NEW_LINE + 'EVENTCALENDARTYPE:' + eventCalendarType + NEW_LINE;
  }

  private writeEventImageType(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mEventImageType, true)) {
      return EVENTIMAGETYPE + COLON + eventInfo.mEventImageType + NEW_LINE;
    }
    return '';
  }

  /**
   * todo 写入重复规则
   * 写入重复规则
   * @param eventInfo
   * @returns
   */
  private writeRule(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mRepeatRule, true)) {
      return RRULE + COLON + eventInfo.mRepeatRule + NEW_LINE;
    }
    return ''
  }

  private writeExData(eventInfo: AgendaEventInfoWrap) {
    if (EmptyUtils.isNotEmptyString(eventInfo.exDate, true)) {
      return EX_DATE + COLON + eventInfo.exDate + NEW_LINE;
    }
    return ''
  }

  private writeStatus(status: string): string {
    if (EmptyUtils.isEmptyString(status, true)) {
      return '';
    }
    const statusValue: Number = Number(status);
    let statusString: string = '';
    if (Number.isNaN(statusValue)) {
      Log.warn(TAG, `writeStatus eventInfo.status is ${status} dirty`);
      return ''
    }
    switch (statusValue.valueOf()) {
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
    return STATUS + COLON + statusString + NEW_LINE;
  }

  private writeTitle(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mTitle, true)) {
      return 'SUMMARY:' + eventInfo.mTitle + NEW_LINE;
    }
    return '';
  }

  private writeLocation(eventInfo: AgendaEventInfoWrap): string {
    if (EmptyUtils.isNotEmptyString(eventInfo.mLocation, true)) {
      return 'LOCATION:' + eventInfo.mLocation + NEW_LINE;
    }
    return '';
  }

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

  private writeClass(eventInfo: AgendaEventInfoWrap): string {
    Log.info(TAG, `writeClass eventInfo.accessLevel is ${eventInfo.accessLevel}`)
    if (ZERO == eventInfo.accessLevel || THREE == eventInfo.accessLevel) {
      return 'CLASS:PUBLIC' + NEW_LINE;
    }
    if (TWO == eventInfo.accessLevel) {
      return 'CLASS:PRIVATE' + NEW_LINE;
    }
    return ''
  }

  private writeDtEnd(eventInfo: AgendaEventInfoWrap): string {
    Log.info(TAG, `writeDtEnd`);
    return DTEND + this.getFormatDtEnd(eventInfo) + NEW_LINE;
  }

  /**
   * 版本1的时间戳格式和版本2的不同
   * @param eventInfo
   * @returns
   */
  private writeStartAndAlarm(eventInfo: AgendaEventInfoWrap): string {
    Log.info(TAG, `writeStartAndAlarm `);
    let utcDtStart: number = 0;
    let dtStartAlarmString = 'DTSTART:';
    if (isOperatorSoftbank() && eventInfo.mIsAllDay) {
      utcDtStart = eventInfo.mBegin;
      let dtStart: string = new FormatTime().getTimeInFormat2445(eventInfo.mBegin, eventInfo.eventTimeZone);
      dtStart = this.trimZFromUTCTime(dtStart, eventInfo.eventTimeZone);
      dtStartAlarmString = dtStartAlarmString + dtStart + NEW_LINE;
    } else {
      utcDtStart = eventInfo.mBegin;
      dtStartAlarmString = dtStartAlarmString + this.formatIso8601(eventInfo.mBegin) + NEW_LINE;
    }
    if (EmptyUtils.isEmptyArray(eventInfo.reminders)) {
      Log.info(TAG, `writeAlarm eventInfo id is ${eventInfo.mId} not has reminder`);
      return dtStartAlarmString;
    }
    for (let reminder of eventInfo.reminders) {
      const alarmString: string = this.getAlarmStartTimeInUTC(reminder.remindMinutes.toString(), utcDtStart);
      if (EmptyUtils.isEmptyString(alarmString)) {
        Log.warn(TAG, `writeStartAndAlarm getAlarmStartTimeInUTC error ${reminder.remindMinutes.toString()}}`);
        continue
      }
      dtStartAlarmString += 'AALARM' + COLON + alarmString + ';;;' + NEW_LINE;
    }
    return dtStartAlarmString;
  };

  private trimZFromUTCTime(time: string, timezoneId: string) {
    if (UTC == timezoneId) {
      return time.replace('Z', '');
    }
    return time;
  }

  // todo
  private getFormatDtEnd(eventInfo: AgendaEventInfoWrap) {
    const isAllDay: boolean = eventInfo.mIsAllDay;
    const dtStart: number = eventInfo.mBegin;
    let dtEnd: number = eventInfo.mEnd;
    const tzId: string = eventInfo.eventTimeZone;
    const duration: string = eventInfo.duration;
    let dtEndString: string = '';
    if (isOperatorSoftbank() && isAllDay) {
      dtEndString = this.setDtEndTo235900Format(dtEnd - MILLS_PER_MINUTE);
      dtEndString = this.trimZFromUTCTime(dtEndString, tzId);
    } else if (EmptyUtils.isNotEmptyString(duration, true)) {
      dtEnd = this.getDtEndFromDuration(dtStart, duration);
      dtEndString = this.formatIso8601(dtEnd);
    } else {
      dtEndString = this.formatIso8601(dtEnd);
    }
    return dtEndString;
  }

  private setDtEndTo235900Format(dtEndMills: number): string {
    const customTime: CustomTime = new CustomTime(UTC);
    customTime.setTime(dtEndMills);
    customTime.set(customTime.getYear(), customTime.getMonth(), customTime.getDate(), 23, 59, 0);
    return new FormatTime().getTimeInFormat2445(customTime.getTimeInMills(), customTime.getTimeZone());
  }

  private getDtEndFromDuration(dtStart: number, durationString: string): number {
    let durationMills: number = 0;
    const duration: Duration = new Duration();
    try {
      duration.parse(durationString);
      durationMills = duration.getMills();
      Log.info(TAG, `getDtEndFromDuration durationString is ${durationString} durationMills is ${durationMills}`);
    } catch (err) {
      Log.logErrorMsg(TAG, 'getDtEndFromDuration', err);
    }
    return dtStart + durationMills;
  }

  /**
   * 需要将提醒的时间戳转化为UTC格式的,中国区域一般比startTime 少8个小时
   * @param minutesBeforeAlarmStart
   * @param dtStartInMillis
   * @returns
   */
  private getAlarmStartTimeInUTC(minutesBeforeAlarmStart: string, dtStartInMillis: number): string {
    let alarmStartTimeInMillis: number = dtStartInMillis;
    try {
      if (Number.isNaN(Number(minutesBeforeAlarmStart))) {
        Log.warn(TAG, `getAlarmStartTimeInUTC : minutesBeforeAlarmStart  ${minutesBeforeAlarmStart}`);
      } else {
        const milliSecondsBeforeAlarmStart: number = Number(minutesBeforeAlarmStart).valueOf() * MILLS_PER_MINUTE;
        alarmStartTimeInMillis = dtStartInMillis - milliSecondsBeforeAlarmStart;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'getAlarmStartTimeInUTC : happened error', err);
    }
    const alarmString: string = new FormatTime().getTimeInFormat2445(alarmStartTimeInMillis, UTC);
    return alarmString;
  }

  // todo 获取合适的编码
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
}
