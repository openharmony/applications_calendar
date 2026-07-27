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
  AALARM,
  CalendarParser,
  CANCELLED,
  CLASS,
  COMPLETED,
  CONFIDENTIAL,
  CONFIRMED,
  DECLINED,
  DESCRIPTION,
  DOWNIMPORTANTEVENTTYPE,
  DTEND,
  DTSTART,
  DUE,
  DURATION,
  EVENTALERTTYPE,
  EVENTCALENDARTYPE,
  EVENTIMAGETYPE,
  EVENTTYPEEXT,
  EX_DATE,
  LOCATION,
  NORMALALERT,
  NORMALEVENTTYPE,
  PRIVATE,
  RRULE,
  SERVICEDESCRIPTION,
  SERVICETYPE,
  SERVICEURI,
  SERVICEVERIFIED,
  SOLAR,
  STATUS,
  SUMMARY,
  TENTATIVE,
  UPIMPORTANTEVENTTYPE
} from './CalendarParser';
import { VcsComponent, VEVENT } from '../model/VcsComponent';
import {
  AgendaEventInfo,
  CalendarContract,
  convertStringCharset,
  EmptyUtils,
  TimeZoneUtil,
  HOURS_PER_DAY,
  ISO_8859_1,
  isOperatorSoftbank,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_MINUTE,
  SHIFT_JIS,
  UTC,
  UTF_8
} from '@app/common';
import ArrayList from '@ohos.util.ArrayList';
import { Property } from '../model/Property';
import { Parameter } from '../model/Parameter';
import { ENCODING_STRING } from '../../VCalParser';
import { equalsIgnoreCase } from '@app/common/src/main/ets/util/CommonUtils';
import { VCalUtils } from '../../VCalUtils';
import { CustomTime, FormatTime } from '@app/feature.repeatrule';
import { CalendarInfo } from '../../CalendarInfo';
import { QuotedPrintableHelper } from '../../QuotedPrintableHelper';
import { VCSToICSRRuleTranslator } from '../VCSToICSRRuleTranslator';


const TAG = "CalendarParserV10";

/**
 * 闹钟默认的分钟数
 */
const DEFAULT_ALARM_MINUTES = 10;

const isSupportIcs = false;

const QUOTED_PRINTABLE_ENCODING = "QUOTED-PRINTABLE";

/**
 * CalendarParserV10 1.0文件的解析
 *
 */
export class CalendarParserV10 extends CalendarParser {
  private mInfo: CalendarInfo;

  constructor(calendarInfo: CalendarInfo) {
    super();
    this.mInfo = calendarInfo;
  }

  async parseEvent(component: VcsComponent,
    eventInfo: AgendaEventInfo, holidayAbbreviationArray: string[]): Promise<boolean> {
    if (!this.isComponentValid(component)) {
      return false;
    }
    if (!this.parseAndFillEventInfo(component, eventInfo)) {
      return false;
    }
    // If after all above handing still dtend is less than dtstart then set dtend to dtstart
    if (eventInfo.mEnd < eventInfo.mBegin) {
      eventInfo.mEnd = eventInfo.mBegin;
    }
    return true;
  }

  private isComponentValid(component: VcsComponent): boolean {
    Log.info(TAG, `parseEvent component is ${component.toString()}`);
    if (VEVENT != component.getName()) {
      Log.warn(TAG, `parseEvent component name is ${component.getName()} not ${VEVENT}`);
      return false;
    }
    if (!component.getPropertyNames().has(DTSTART)) {
      Log.warn(TAG, `parseEvent component not has ${DTSTART} Property`);
      return false;
    }
    return true;
  }

  private parseAndFillEventInfo(component: VcsComponent, eventInfo: AgendaEventInfo): boolean {
    // Set the time zone id using the offset value(eg:TZ:+5:30).
    const timezone: string = this.mInfo.getTimezone();
    if (EmptyUtils.isEmptyString(timezone)) {
      eventInfo.eventTimeZone = TimeZoneUtil.getCurrentTimeZone();
    } else {
      eventInfo.eventTimeZone = timezone;
    }
    let dtStart: string = '';
    let dtEnd: string = '';
    let lastDate: string = '';
    let remainders: ArrayList<string> = new ArrayList<string>();
    const allProperties = component.getAllProperties();
    if (EmptyUtils.isEmptyArray(allProperties)) {
      Log.warn(TAG, `parseAndFillEventInfo allProperties is empty`);
      return false;
    }
    for (let i = 0; i < allProperties.length; i++) {
      const property: Property = allProperties[i];
      if (!property) {
        Log.warn(TAG, `parseAndFillEventInfo property is null`);
        continue;
      }
      let name: string = property.getName();
      let value: string = property.getValue();
      let encoding: string = '';
      let charSet: string = '';
      if (this.canParseEncoding(name)) {
        encoding = this.parseEncoding(property, name);
        charSet = this.parseCharSet(property);
      }
      if (DTEND == name) {
        dtEnd = value;
      } else if (DTSTART == name) {
        dtStart = value;
        if (EmptyUtils.isEmptyString(dtStart, true)) {
          Log.warn(TAG, 'parseAndSetEventInfo dTStart is empty');
          return false;
        }
      } else if (COMPLETED == name) {
        lastDate = value;
      } else {
        // 解析文件来自外部，字段必须匹配才能赋值，不需有else分支
        // Log.info(TAG, "parseEvent no need else case");
      }
      if (!this.fillEventByParseProperty(eventInfo, name, value, encoding, charSet, remainders)) {
        return false;
      }
    }
    if (!this.parseAndFillEventStartEnd(eventInfo, dtEnd, dtStart, lastDate)) {
      return false;
    }
    this.parseEventReminds(remainders, eventInfo);
    return true;
  }

  /**
   * 1.0版本分享出去的日程是UTC时间的
   * @param remainders
   * @param eventInfo
   */
  private parseEventReminds(remainders: ArrayList<string>, eventInfo: AgendaEventInfo): boolean {
    if (EmptyUtils.isEmptyArray(remainders)) {
      Log.info(TAG, `parseEventReminds no reminds`);
      return false;
    }

    for (let remaindersString of remainders) {
      const reminderValueString: string = this.getAlarmStartTimeString(remaindersString);
      if (EmptyUtils.isEmptyString(reminderValueString)) {
        Log.warn(TAG, `parseEventReminds remaindersString is ${remaindersString} illeagl`);
        continue;
      }
      try {
        const alarmMinString: number = this.getMinutesBeforeAlarmStart(reminderValueString, eventInfo.mBegin);
        if (alarmMinString <= -1) {
          Log.warn(TAG, `parseEventReminds `);
          continue;
        }
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.remindMinutes = alarmMinString;
        eventInfo.checkValuesArray.push(reminder);
      } catch (err) {
        Log.error(TAG, `parseEventReminds error ${err?.message} remaindersString is ${remaindersString}`);
      }
    }
    return true;
  }

  /**
   * 版本一构建reminder时,格式化的提醒时间串是UTC的
   * @param alarmStartTimeInUtc
   * @param eventStartTimeInMills
   * @returns
   */
  private getMinutesBeforeAlarmStart(alarmStartTimeInUtc: string, eventStartTimeInMills: number): number {
    const alarmStartTime: CustomTime = new CustomTime(UTC);
    new FormatTime().parseByTimeString(alarmStartTimeInUtc, alarmStartTime);
    const eventStartTime: CustomTime = new CustomTime(UTC);
    eventStartTime.setTime(eventStartTimeInMills);
    let minutes: number = (eventStartTime.getTimeInMills() - alarmStartTime.getTimeInMills()) / MILLS_PER_MINUTE
    if (minutes < 0) {
      Log.warn(TAG, `getMinutesBeforeAlarmStart minutes is ${minutes} illeagl`);
      minutes = 10;
    }
    Log.info(TAG, `getMinutesBeforeAlarmStart minutes is ${minutes}`);
    return minutes;
  }


  /**
   * Method to extract alarm start time from the property list.the list will be in 20111209T100011Z;;;
   *
   * @param alarmPropertyValue - to store the aalarm property value.
   * @return parse alarm start time in string format.We assume it to be in UTC.
   */
  private getAlarmStartTimeString(remaindersString: string) {
    if (EmptyUtils.isEmptyString(remaindersString, true)) {
      return '';
    }
    const index: number = remaindersString.indexOf(';');
    if (index < 1) {
      return ''
    }
    return remaindersString.substring(0, index);
  }

  private fillEventByParseProperty(eventInfo: AgendaEventInfo, name: string, value: string,
                                   encoding: string, charSet: string, remainders: ArrayList<string>): boolean {
    if (RRULE == name) {
      this.fillEventByParsePropertyRrule(eventInfo, value);
    } else if (STATUS == name) {
      this.fillEventByParseStatus(eventInfo, value);
    } else if (DUE == name || DURATION == name) {
      eventInfo.duration = value;
    } else if (LOCATION == name) {
      eventInfo.mLocation = this.parseTextParam(name, value, encoding, charSet);
    } else if (DESCRIPTION == name) {
      eventInfo.mDescription = this.parseTextParam(name, value, encoding, charSet);
    } else if (SERVICEDESCRIPTION == name) {
      eventInfo.mHwextServiceDescription = this.parseTextParam(name, value, encoding, charSet);
    } else if (SERVICEVERIFIED == name) {
      eventInfo.mHwextServiceVerified = Boolean(value);
    } else if (SERVICETYPE == name) {
      eventInfo.mHwextServiceType = value;
    } else if (SERVICEURI == name) {
      eventInfo.mHwextServiceUri = this.parseTextParam(name, value, encoding, charSet);
    } else if (SUMMARY == name) {
      eventInfo.mTitle = this.parseTextParam(name, value, encoding, charSet);
    } else if (AALARM == name) {
      remainders.add(value);
    } else if (CLASS == name) {
      this.parsePropertyClassAndFillEvent(eventInfo, value);
    } else if (EVENTCALENDARTYPE == name) {
      this.parsePropertyCalendarTypeAndFillEvent(eventInfo, value)
    } else if (EVENTIMAGETYPE == name) {
      eventInfo.mEventImageType = value;
    } else if (EX_DATE === name) {
      eventInfo.exDate = value;
    } else {
      this.parseOtherField(eventInfo, name, value);
    }
    return true;
  }

  private parseOtherField(eventInfo: AgendaEventInfo, name: string, value: string) {
    if (EVENTTYPEEXT == name) {
      if (NORMALEVENTTYPE == value) {
        eventInfo.mImportantEventType = 0;
      } else if (UPIMPORTANTEVENTTYPE == value) {
        eventInfo.mImportantEventType = 1;
      } else if (DOWNIMPORTANTEVENTTYPE == value) {
        eventInfo.mImportantEventType = 2;
      } else {
        eventInfo.mImportantEventType = 0;
        Log.error(TAG, `event type value is error! value is ${value}`);
      }
    } else if (EVENTALERTTYPE == name) { // 提醒类型
      eventInfo.alertType = NORMALALERT == value ? 0 : 1;
    } else if ((EVENTCALENDARTYPE == name)) {
      eventInfo.mEventCalendar = SOLAR === value ?
      CalendarContract.AgendaCalendarType.SOLAR : CalendarContract.AgendaCalendarType.LUNAR;
    } else {
      // 解析文件来自外部，字段必须匹配才能赋值，不需有else分支
      Log.info(TAG, `parseOtherField no need else case name is ${name}`);
    }
  }

  private parsePropertyCalendarTypeAndFillEvent(eventInfo: AgendaEventInfo, value: string) {
    if (SOLAR == value) {
      eventInfo.mEventCalendar = 0;
    } else {
      eventInfo.mEventCalendar = 1;
    }
  }

  private parsePropertyClassAndFillEvent(eventInfo: AgendaEventInfo, value: string) {
    if (PRIVATE == value || CONFIDENTIAL == value) {
      eventInfo.accessLevel = 2;
    } else {
      eventInfo.accessLevel = 3;
    }
  }


  private fillEventByParseStatus(eventInfo: AgendaEventInfo, value: string) {
    if (equalsIgnoreCase(TENTATIVE, value)) {
      eventInfo.status = '0';
    } else if (equalsIgnoreCase(CONFIRMED, value)) {
      eventInfo.status = '1';
    } else if (equalsIgnoreCase(CANCELLED, value) || equalsIgnoreCase(DECLINED, value)) {
      eventInfo.status = '2';
    } else {
      Log.debug(TAG, "no need set state");
    }
  }

  private fillEventByParsePropertyRrule(eventInfo: AgendaEventInfo, value: string) {
    eventInfo.mRepeatRule = value;
    // Addition for Import Export Rrule changes
    try {
      const vcsIcsTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      if (vcsIcsTranslator.parse(value)) {
        eventInfo.mRepeatRule = vcsIcsTranslator.buildRepeatRuleString();
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'fillEventByParsePropertyRrule', error);
    }
  }

  private parseTextParam(name: string, value: string, encoding: string, charSet: string): string {
    let parsedText: string = value;
    try {
      if (EmptyUtils.isEmptyString(encoding)) {
        const propValueInTargetCharset: string = convertStringCharset(ISO_8859_1, charSet, value);
        // Only line folding will be done
        parsedText = this.decodeParameterValue(propValueInTargetCharset, encoding, charSet);
      } else {
        // No charset decoding for QOP
        parsedText = this.decodeParameterValue(value, encoding, charSet);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `parseTextParam name is ${name} encoding is ${encoding} charSet is ${charSet} error`, err);
    }
    return parsedText;
  }


  private decodeParameterValue(value: string, encoding: string, charSet: string) {
    Log.info(TAG, `decodeParameterValue enter value encoding is ${encoding} charSet is ${charSet}`);
    let decodedValue: string = value;
    if (equalsIgnoreCase(QUOTED_PRINTABLE_ENCODING, encoding)) {
      decodedValue = this.decodeQuotedPrintable(value, charSet);
    } else if (equalsIgnoreCase("BASE64", encoding)) {
      decodedValue = this.decodeBase64String(value, charSet);
    } else {
      decodedValue = this.unfoldContentLineFolding(value);
    }
    Log.info(TAG, `decodeParameterValue Exit`);
    return decodedValue;
  }

  // todo base64 解码字符串
  private decodeBase64String(value: string, charSet: string): string {
    return value;
  }

  /**
   * Method to decode QOP encoding followed by charset decoding.
   *
   *
   * @param qp - bytes encoded in QOP
   * @param charset - charset  to be used in decoding
   * @return - returns string after QOP and charset decoding
   */
  private decodeQuotedPrintable(value: string, charSet: string): string {
    if (EmptyUtils.isEmptyString(value)) {
      return '';
    }
    return QuotedPrintableHelper.getInstance().decodeQuotedPrintable(value, charSet);
  }

  private parseCharSet(property: Property): string {
    let expectedList = property.getParameters('CHARSET');
    if (EmptyUtils.isNotEmptyArray(expectedList)) {
      const parameter: Parameter = expectedList[0];
      return parameter.value;
    }
    if (isOperatorSoftbank()) {
      return SHIFT_JIS;
    } else {
      return UTF_8;
    }
  }

  private parseEncoding(property: Property, name: string): string {
    let expectedList = property.getParameters(ENCODING_STRING);
    if (EmptyUtils.isNotEmptyArray(expectedList)) {
      const parameter: Parameter = expectedList[0];
      return parameter.value;
    } else {
      return UTF_8;
    }
  }

  private canParseEncoding(name: String): boolean {
    if (LOCATION == name || SERVICEDESCRIPTION == name ||
      SERVICEURI == name || DESCRIPTION == name || SUMMARY == name) {
      return true;
    }
    return false;
  }

  /**
   * 普通全天日程,dtStart 和 dtEnd 都不会为空
   * 重复全天日程,db 里的dtEnd为空,有duration 和repeat字段,但是在CalendarBuilderV10构建时,会通过duration构建dtEnd
   * @param eventInfo
   * @param dtEnd
   * @param dtStart
   * @param lastDate
   * @param calendarInfo
   * @returns
   */
  private parseAndFillEventStartEnd(eventInfo: AgendaEventInfo,
                                    dtEnd: string, dtStart: string, lastDate: string): boolean {
    // Set allDay column for this event to 1 if it is an allday event
    try {
      if (EmptyUtils.isNotEmptyString(dtStart) && EmptyUtils.isNotEmptyString(dtEnd)) {
        eventInfo.mIsAllDay = this.isAllDayEvent(dtStart, dtEnd, this.mInfo.getTimezone());
      }
      // 这里是普通全天日程
      if (eventInfo.mIsAllDay) {
        eventInfo.mBegin = this.getTimeInMillis(dtStart, UTC);
        if (eventInfo.mBegin == -1) {
          return false;
        }
        eventInfo.mEnd = this.getTimeInMillis(dtEnd, UTC);
        if (eventInfo.mEnd == -1) {
          return false;
        }
        eventInfo.mEnd = this.amendAllDayDtEnd(dtEnd, eventInfo.mEnd);
        if (EmptyUtils.isNotEmptyString(lastDate)) {
          eventInfo.lastDate = this.getTimeInMillis(lastDate, UTC);
        }
        eventInfo.eventTimeZone = UTC;
      }

      // Handle DTSTART inconsistency for non all day events with rrule.
      this.setEventInfoTimeZone(eventInfo, dtStart, dtEnd, lastDate);

      /*
       * If dtend is missing compute it from duration and dtstart
       * or if both dtend and duration not present then set it to dtstart
       * 重复日程的dTend是空,duration 不为空
      */
      if (EmptyUtils.isEmptyString(dtEnd)) {
        if (EmptyUtils.isNotEmptyString(eventInfo.duration)) {
          eventInfo.mEnd = VCalUtils.getDtEndFromDuration(eventInfo.mBegin, eventInfo.duration);
          if (eventInfo.mEnd == -1) {
            Log.warn(TAG, `parseAndFillEventStartEnd getDtEndFromDuration error`);
            return false;
          }
        } else {
          // 这个分支理论上是不可能进入的
          eventInfo.mEnd = eventInfo.mBegin;
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseAndFillEventStartEnd', err);
      return false;
    }
    return this.finalCheck(eventInfo);
  }

  /**
   * 修正全体日程的时间毫秒值,23：59：00的需要加一分钟的毫秒值
   * @param dtEndString
   * @param dtEnd
   * @returns
   */
  private amendAllDayDtEnd(dtEndString: string, dtEnd: number): number {
    const customTime: CustomTime = new CustomTime(UTC);
    const formatTime: FormatTime = new FormatTime();
    formatTime.parseByTimeString(dtEndString, customTime);
    if (this.isTimeOneMinShortOf24(formatTime)) {
      dtEnd += MILLS_PER_MINUTE;
    }
    return dtEnd;
  }

  private isTimeOneMinShortOf24(dtEndFormatTime: FormatTime) {
    return dtEndFormatTime.hour == 23 && dtEndFormatTime.minute == 59 && dtEndFormatTime.second == 0;
  }

  /**
   * todo 获取时间戳
   * @param time
   * @param timezone
   * @returns -1 表明解析异常
   */
  private getTimeInMillis(time: string, timezone: string): number {
    if (VCalUtils.isTimeParamMissing(time)) {
      time = VCalUtils.appendTimeParameter(time);
    }
    const customTime: CustomTime = new CustomTime(timezone);
    const formatTime: FormatTime = new FormatTime();
    if (formatTime.parseByTimeString(time, customTime)) {
      return customTime.getTimeInMills();
    } else {
      return -1;
    }
  }

  private setEventInfoTimeZone(eventInfo: AgendaEventInfo, dtStart: string, dtEnd: string, lastDate: string): boolean {
    const timeZone: string = this.mInfo.getTimezone();
    eventInfo.eventTimeZone = EmptyUtils.isEmptyString(timeZone) ? TimeZoneUtil.getCurrentTimeZone() : timeZone;
    const customTime: CustomTime = new CustomTime();
    const startTimeResult = this.parseStartAndEndTime(dtStart, customTime, eventInfo.eventTimeZone);
    if (!startTimeResult.first) {
      return false;
    }
    const startTime: CustomTime = startTimeResult.second;
    eventInfo.mBegin = startTime.getTimeInMills();
    if (EmptyUtils.isNotEmptyString(dtEnd)) {
      const customTime: CustomTime = new CustomTime();
      const endTimeResult = this.parseStartAndEndTime(dtEnd, customTime, eventInfo.eventTimeZone);
      if (!endTimeResult.first) {
        Log.warn(TAG, `setEventInfoTimeZone dtEnd is ${dtEnd} timeZone is ${eventInfo.eventTimeZone} parse false`);
        return true;
      }
      const endTime: CustomTime = endTimeResult.second;
      eventInfo.mEnd = endTime.getTimeInMills();
    }
    if (EmptyUtils.isNotEmptyString(lastDate)) {
      const customTime: CustomTime = new CustomTime();
      const lastDateTimeResult = this.parseStartAndEndTime(lastDate, customTime, eventInfo.eventTimeZone);
      if (!lastDateTimeResult.first) {
        Log.warn(TAG, `setEventInfoTimeZone lastDate is ${lastDate} timeZone is ${eventInfo.eventTimeZone} parse false`);
        return true;
      }
      const lastDateTime: CustomTime = lastDateTimeResult.second;
      eventInfo.lastDate = lastDateTime.getTimeInMills();
    }
    return true;
  }

  // todo 计算这个日程是不是全天日程
  private isAllDayEvent(dtStart: string, dtEnd: string, targetTimeZone: string): boolean {
    if (VCalUtils.isTimeParamMissing(dtStart)) {
      dtStart = VCalUtils.appendTimeParameter(dtStart);
    }
    if (VCalUtils.isTimeParamMissing(dtEnd)) {
      dtEnd = VCalUtils.appendTimeParameter(dtEnd);
    }
    const dtStartFormatTime: FormatTime = new FormatTime();
    if (!dtStartFormatTime.parseByTimeString(dtStart, new CustomTime(targetTimeZone))) {
      Log.warn(TAG, `isAllDayEvent parse dtStart ${dtStart} result false`);
      return false;
    }
    const dtEndFormatTime: FormatTime = new FormatTime();
    if (!dtEndFormatTime.parseByTimeString(dtEnd, new CustomTime(targetTimeZone))) {
      Log.warn(TAG, `isAllDayEvent parse dtEnd ${dtEnd} result false`);
      return false;
    }
    let isAllDay = false;
    const dtStartMillis: number = dtStartFormatTime.timeStamp;
    const dtEndMillis: number = dtEndFormatTime.timeStamp;
    isAllDay = this.isHourMinSecZero(dtEndFormatTime) && this.isTimeDiffMultiplesOf24(dtEndMillis, dtStartMillis);
    Log.info(TAG, `isAllDayEvent ${isAllDay} dtStart is ${dtStart} dtEnd is ${dtEnd} targetTimeZone is ${targetTimeZone}`);
    if (isAllDay) {
      return isAllDay;
    }
    if (isOperatorSoftbank()) {
      isAllDay = this.isSoftbankAllDay(dtStart, dtEnd, targetTimeZone);
    }
    return isAllDay;
  }


  private isSoftbankAllDay(dtStart: string, dtEnd: string, targetTimeZone: string): boolean {
    if (!VCalUtils.isLocalTime(dtStart)) {
      return false;
    }
    const dtStartFormatTime: FormatTime = new FormatTime();
    if (!dtStartFormatTime.parseByTimeString(dtStart, new CustomTime(targetTimeZone))) {
      Log.warn(TAG, `isSoftbankAllDay parse dtStart ${dtStart} result false`);
      return false;
    }
    const dtEndFormatTime: FormatTime = new FormatTime();
    if (!dtEndFormatTime.parseByTimeString(dtEnd, new CustomTime(targetTimeZone))) {
      Log.warn(TAG, `isSoftbankAllDay parse dtEnd ${dtEnd} result false`);
      return false;
    }
    let isAllDay = false;
    const dtStartMillis: number = dtStartFormatTime.timeStamp;
    let dtEndMillis: number = dtEndFormatTime.timeStamp;
    if (this.isTimeOneMinShortOf24(dtEndFormatTime)) {
      dtEndMillis += MILLS_PER_MINUTE;
      isAllDay = this.isTimeDiffMultiplesOf24(dtEndMillis, dtStartMillis);
    }
    Log.info(TAG, `isSoftbankAllDay ${isAllDay} dtStart is ${dtStart} dtEnd is ${dtEnd} targetTimeZone is ${targetTimeZone}`);
    if (isAllDay) {
      return isAllDay;
    }
    isAllDay = this.is24HourFormat(dtEndFormatTime) && this.isTimeDiffMultiplesOf24(dtEndMillis, dtStartMillis);
    return isAllDay;
  }

  private isTimeDiffMultiplesOf24(dtEndMillis: number, dtStartMillis: number): boolean {
    const endStartDiff: number = (dtEndMillis - dtStartMillis) / 1000 * 1000;
    return endStartDiff % MILLS_PER_DAY == 0 && endStartDiff / MILLS_PER_DAY >= 1;
  }

  /**
   * Method to check if hour, minute and second is zero for FormatTime object.
   *
   * @param formatTime: FormatTime
   * @return boolean
   */
  private isHourMinSecZero(formatTime: FormatTime): boolean {
    return (formatTime.hour == 0) && (formatTime.minute == 0) && (formatTime.second == 0);
  }


  /**
   * Method to check whether time is in 240000 format.
   *
   * @param formatTime - to store the time object
   * @return - true if time is in 240000 format otherwise false
   */
  private is24HourFormat(formatTime: FormatTime): boolean {
    return (formatTime.hour == HOURS_PER_DAY) && (formatTime.minute == 0) && (formatTime.second == 0);
  }
}


