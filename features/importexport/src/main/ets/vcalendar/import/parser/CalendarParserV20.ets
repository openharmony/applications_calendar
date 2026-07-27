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
  AgendaEventInfo,
  CalendarContract,
  convertStringCharset,
  EmptyUtils,
  isOperatorSoftbank,
  ISO_8859_1,
  TimeZoneUtil,
  Log,
  MINUTES_PER_DAY,
  MINUTES_PER_HOUR,
  Pair,
  SHIFT_JIS,
  UTC,
  UTF_8,
  DateUtil,
  MILLS_PER_DAY
} from '@app/common';
import { VcsComponent, VEVENT } from '../model/VcsComponent';
import {
  CalendarParser,
  CANCELLED,
  COMPLETED,
  CONFIRMED,
  D,
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
  H,
  LOCATION,
  M,
  NORMALALERT,
  NORMALEVENTTYPE,
  P,
  ParseResult,
  RESOURCES,
  ABBREVIATION,
  RRULE,
  SERVICEDESCRIPTION,
  SERVICETYPE,
  SERVICEURI,
  SERVICEVERIFIED,
  SOLAR,
  STATUS,
  SUMMARY,
  TENTATIVE,
  TRIGGER,
  UPIMPORTANTEVENTTYPE
} from './CalendarParser';
import ArrayList from '@ohos.util.ArrayList';
import { Property } from '../model/Property';
import { Parameter } from '../model/Parameter';
import { ENCODING_STRING } from '../../VCalParser';
import { equalsIgnoreCase } from '@app/common/src/main/ets/util/CommonUtils';
import { CustomTime, FormatTime } from '@app/feature.repeatrule';
import LinkedList from '@ohos.util.LinkedList';
import { VCalUtils } from '../../VCalUtils';
import { CalendarInfo } from '../../CalendarInfo';
import { QuotedPrintableHelper } from '../../QuotedPrintableHelper';

const TAG = "CalendarParserV20";

const NORMAL_SIZE = 4;

const NUM_2 = 2;

const QUOTED_PRINTABLE_ENCODING = "QUOTED-PRINTABLE";

const BASE64_ENCODING = "BASE64";

const NO_NEED_ELSE_CASE = "no need else case";

const COLON = ':';

const CHINESE_CODE = 'ZH';

/**
 * 导入多日程或日历账户的解析器
 */
export class CalendarParserV20 extends CalendarParser {
  private mTime: CustomTime;
  private mInfo: CalendarInfo;
  private countryCode: string;

  constructor(calendarInfo: CalendarInfo, countryCode: string = '') {
    super();
    this.mInfo = calendarInfo;
    this.mTime = new CustomTime();
    this.countryCode = countryCode;
    if (TimeZoneUtil.isValidTimezone(this.mInfo.getTimezone())) {
      this.mTime.setTimeZone(this.mInfo.getTimezone());
    }
  }

  /**
   * 通过 eventComponent 解析填充 AgendaEventInfo
   * @param eventComponent
   * @param eventInfo
   * @param calendarInfo
   * @returns
   */
  async parseEvent(eventComponent: VcsComponent,
    eventInfo: AgendaEventInfo, holidayAbbreviationArray: string[]): Promise<boolean> {
    if (VEVENT != eventComponent.getName()) {
      Log.warn(TAG, `parseEvent component name is ${eventComponent.getName()} not ${VEVENT}`);
      return false;
    }
    if (!eventComponent.getPropertyNames().has(DTSTART)) {
      Log.warn(TAG, `parseEvent component not has ${DTSTART} Property`);
      return false;
    }
    const allProperty: Array<Property> = this.extractAllPropertyFirst(eventComponent);
    return this.parseAndFillEventInfo(eventInfo, allProperty, holidayAbbreviationArray);
  }

  /**
   * 解析完一个event后,对event做最终的检查
   * @param eventInfo
   * @returns
   */
  protected finalCheck(eventInfo: AgendaEventInfo): boolean {
    if (eventInfo.mBegin <= 0) {
      Log.warn(TAG, `finalCheck false mBegin is ${eventInfo.mBegin} illegal`);
      return false;
    }
    if (EmptyUtils.isNotEmptyString(eventInfo.duration)) {
      return true;
    }
    // 纪念日 和倒数日 mEnd可能和mStart一样
    if (eventInfo.isImportantAnniversaries() || eventInfo.isImportantCountDown()) {
      return true;
    }
    if (!EmptyUtils.isEmptyString(this.countryCode)) {
      eventInfo.mEnd = eventInfo.mEnd + MILLS_PER_DAY;
      eventInfo.mImportantEventType = CalendarContract.EventImportantType.HOLIDAY;
      return true;
    }
    const checkResult: boolean = eventInfo.mEnd >= eventInfo.mBegin;
    if (!checkResult) {
      Log.warn(TAG, `finalCheck false mEnd is ${eventInfo.mEnd} mBegin is ${eventInfo.mBegin}`);
    }
    return checkResult;
  }

  private extractAllPropertyFirst(component: VcsComponent): Property[] {
    const allProperty: Array<Property> = new Array();
    const reminders: Array<Property> = this.extractReminderProperty(component);
    if (EmptyUtils.isEmptyArray(reminders)) {
      Log.warn(TAG, `extractAllPropertyFirst reminders is empty`);
    } else {
      allProperty.push(...reminders);
    }
    for (let propertyName of component.getPropertyNames()) {
      const properties = component.getProperties(propertyName);
      if (!properties || EmptyUtils.isEmptyArray(properties)) {
        Log.warn(TAG, `extractAllPropertyFirst properties is empty propertyName is ${propertyName}`);
      } else {
        allProperty.push(...properties);
      }
    }
    return allProperty;
  }

  /**
   * 提醒的属性在component的一个子component里，需要单独添加
   *
   * @param component 一整个VEVENT
   * @param allProperties VEVENT里的所有属性
   */
  private extractReminderProperty(rootComponent: VcsComponent): Array<Property> {
    const reminders: Array<Property> = new Array();
    const subComponents = rootComponent.getComponents();
    if (EmptyUtils.isEmptyArray(subComponents)) {
      Log.warn(TAG, `extractReminderProperty subComponents is empty`);
      return reminders;
    }
    for (let i = 0; i < subComponents.length; i++) {
      const subComponent: VcsComponent = subComponents[i];
      if (!subComponent) {
        continue;
      }
      const propertyNames: Set<string> = subComponent.getPropertyNames();
      for (let propertyName of propertyNames) {
        const alarmProperties = subComponent.getProperties(propertyName);
        ;
        if (EmptyUtils.isNotEmptyArray(alarmProperties)) {
          reminders.push(...alarmProperties);
        }
      }
    }
    return reminders;
  }

  private parseAndFillEventInfo(eventInfo: AgendaEventInfo,
    allProperty: Array<Property>, holidayAbbreviationArray: string[]): boolean {
    for (let property of allProperty) {
      let name: string = property.getName();
      let value: string = property.getValue();
      let encoding: string = '';
      let charSet: string = '';
      if (this.canParseEncoding(name)) {
        encoding = this.parseEncoding(property, name);
        charSet = this.parseCharSet(property);
      }
      const parseResult: ParseResult = this.parseTimeInfoAndFillEvent(eventInfo, name, value);
      if (parseResult == ParseResult.PARSE_HANDLED || parseResult == ParseResult.ERROR) {
        // 这里不停的设置时区
        eventInfo.eventTimeZone = this.mTime.getTimeZone();
        continue;
      }
      if (parseResult == ParseResult.FATAL_ERROR) {
        Log.warn(TAG, `parseAndFillEventInfo name is ${name} fatalError`);
        return false;
      }
      const parseOtherResult =
        this.parseOtherPropertyAndFillEvent(eventInfo, name, value, encoding, charSet, holidayAbbreviationArray);
      // 其他属性不会出现这个case,其他属性没那么重要
      if (parseOtherResult == ParseResult.FATAL_ERROR) {
        Log.warn(TAG, `parseAndFillEventInfo name is ${name} fatalError`);
        return false;
      }
    }
    if (eventInfo.mEnd <= 0) {
      if (!this.setDtEndValueIfRepeatEvent(eventInfo)) {
        return false;
      }
    }
    if (eventInfo.mIsAllDay) {
      eventInfo.eventTimeZone = UTC;
    }
    return this.finalCheck(eventInfo);
  }

  /**
   * 重复日程没有dtEnd字段,有duration字段和RRULE字段
   */
  private setDtEndValueIfRepeatEvent(eventInfo: AgendaEventInfo): boolean {
    if (EmptyUtils.isNotEmptyString(eventInfo.duration)) {
      eventInfo.mEnd = VCalUtils.getDtEndFromDuration(eventInfo.mBegin, eventInfo.duration);
      if (eventInfo.mEnd == -1) {
        Log.warn(TAG, `parseAndFillEventStartEnd getDtEndFromDuration error`);
        return false;
      }
      Log.info(TAG, `setDtEndValueIfRepeatEvent eventInfo.mEnd is ${eventInfo.mEnd}`);
    } else {
      Log.warn(TAG, `setDtEndValueIfRepeatEvent eventInfo dTend and duration both not exsit`);
      eventInfo.mEnd = eventInfo.mBegin;
    }
    return true;
  }

  private parseOtherPropertyAndFillEvent(eventInfo: AgendaEventInfo, name: string, value: string,
    encoding: string, charSet: string, holidayAbbreviationArray: string[]): ParseResult {
    value = convertStringCharset(value, encoding, charSet);
    if (DUE == name || DURATION == name) {
      eventInfo.duration = value;
      return ParseResult.PARSE_HANDLED;
    } else if (LOCATION == name) {
      eventInfo.mLocation = value;
      return ParseResult.PARSE_HANDLED;
    } else if (DESCRIPTION == name) {
      eventInfo.mDescription = this.parseTextParam(name, value, encoding, charSet);
      return ParseResult.PARSE_HANDLED;
    } else if (SERVICEDESCRIPTION == name) {
      eventInfo.mHwextServiceDescription = this.parseTextParam(name, value, encoding, charSet);
      return ParseResult.PARSE_HANDLED;
    } else if (SERVICEVERIFIED == name) {
      eventInfo.mHwextServiceVerified = Boolean(value);
      return ParseResult.PARSE_HANDLED;
    } else if (SERVICETYPE == name) {
      eventInfo.mHwextServiceType = value;
      return ParseResult.PARSE_HANDLED;
    } else if (SERVICEURI == name) {
      eventInfo.mHwextServiceUri = this.parseTextParam(name, value, encoding, charSet);
      return ParseResult.PARSE_HANDLED;
    } else if (SUMMARY == name) {
      if (!EmptyUtils.isEmptyString(this.countryCode)) {
        if (eventInfo.mTitle === '') {
          eventInfo.mTitle = value;
        }
        if (this.isChinaRegion()) {
          eventInfo.mLanguageRecord['EN'] = eventInfo.mTitle;
        } else {
          eventInfo.mLanguageRecord['default'] = eventInfo.mTitle;
        }
      } else {
        eventInfo.mTitle = value;
      }
      return ParseResult.PARSE_HANDLED;
    } else if (RESOURCES === name) {
      if (!EmptyUtils.isEmptyString(this.countryCode)) {
        const values = value.split(COLON);
        if (this.isChinaRegion() && values[0] === CHINESE_CODE) {
          eventInfo.mTitle = values[1];
          eventInfo.mLanguageRecord['default'] = eventInfo.mTitle;
        } else {
          eventInfo.mLanguageRecord[values[0]] = values[1];
        }
      }
      return ParseResult.PARSE_HANDLED;
    } else if (ABBREVIATION === name) {
      holidayAbbreviationArray.push(eventInfo.mTitle + ':' + value);
      return ParseResult.PARSE_HANDLED;
    } else {
      return this.parseOtherField(eventInfo, name, value);
    }
  }

  private parseOtherField(eventInfo: AgendaEventInfo, name: string, value: string): ParseResult {
    if (EVENTCALENDARTYPE == name) {
      if (SOLAR == value) {
        eventInfo.mEventCalendar = 0;
      } else {
        eventInfo.mEventCalendar = 1;
      }
    } else if (EVENTIMAGETYPE == name) {
      eventInfo.mEventImageType = value;
    } else if (EVENTTYPEEXT == name) {
      if (NORMALEVENTTYPE == value) {
        eventInfo.mImportantEventType = 0;
      } else if (UPIMPORTANTEVENTTYPE == value) {
        eventInfo.mImportantEventType = 1;
      } else if (DOWNIMPORTANTEVENTTYPE == value) {
        eventInfo.mImportantEventType = 2;
      } else {
        eventInfo.mImportantEventType = 0;
        Log.warn(TAG, `event type value is error!`);
      }
    } else if (EVENTALERTTYPE == name) {
      eventInfo.alertType = NORMALALERT == value ? 0 : 1
    } else {
      // 解析文件来自外部，字段必须匹配才能赋值，不需有else分支 比如 ACTION:AUDIO
      Log.info(TAG, `parseOtherField name is ${name} no need deal`);
      return ParseResult.PARSE_NOT_HANDLE;
    }
    return ParseResult.PARSE_HANDLED;
  }

  /**
   * 版本2.0写文件时是DTEND，DTSTART，DUE，RRULE COMPLETED 的排序
   * @param eventInfo
   * @param calendarInfo
   * @param name
   * @param value
   * @returns
   */
  private parseTimeInfoAndFillEvent(eventInfo: AgendaEventInfo, name: string, value: string): ParseResult {
    if (DTEND == name) {
      this.parseStartOrEnd(value, eventInfo);
      eventInfo.mEnd = this.trimTimeMills(this.mTime.getTimeInMills());
      return ParseResult.PARSE_HANDLED;
    } else if (DTSTART == name) {
      this.parseStartOrEnd(value, eventInfo);
      eventInfo.mBegin = this.trimTimeMills(this.mTime.getTimeInMills());
      return ParseResult.PARSE_HANDLED;
    } else if (COMPLETED == name) {
      // COMPLETED 不是UTC格式化的,所以优先使用calendarInfo.getTimezone()时区,一般该时区是currentTimeZone
      if (TimeZoneUtil.isValidTimezone(this.mInfo.getTimezone())) {
        if (!new FormatTime().parseByTimeString(value, this.mTime)) {
          return ParseResult.ERROR;
        }
      } else {
        // 如果calendarInfo.getTimezone()时异常, eventInfo.eventTimeZone 就会是parseTime里解析出的时区,全天日程就是UTC
        if (!this.parseStartAndEndTime(value, this.mTime, eventInfo.eventTimeZone).first) {
          return ParseResult.ERROR;
        }
      }
      eventInfo.lastDate = this.trimTimeMills(this.mTime.getTimeInMills());
      return ParseResult.PARSE_HANDLED;
    } else if (RRULE == name) {
      eventInfo.mRepeatRule = value;
      return ParseResult.PARSE_HANDLED;
    } else if (EX_DATE === name) {
      eventInfo.exDate = value;
      return ParseResult.PARSE_HANDLED;
    } else if (STATUS == name) {
      this.fillEventByParseStatus(eventInfo, value);
      return ParseResult.PARSE_HANDLED;
    } else if (name.match(TRIGGER)) {
      this.fillEventByParseAlarm(eventInfo, value);
      return ParseResult.PARSE_HANDLED;
    }
    Log.info(TAG, `parseTimeInfoAndFillEvent name is ${name}`);
    return ParseResult.PARSE_NOT_HANDLE;
  }

  private trimTimeMills(timeMills: number) {
    return timeMills / 1000 * 1000;
  }

  private isChinaRegion(): boolean {
    return this.countryCode === 'TW' || this.countryCode === 'HK' || this.countryCode === 'MO';
  }

  /**
   * 将timeString解析封装到CustomTime中,这一过程会改成CustomTime的时区
   * @param calendarInfo
   * @param timeString
   * @param eventInfo
   * @returns
   */
  private parseStartOrEnd(timeString: string, eventInfo: AgendaEventInfo): Pair<boolean, CustomTime> {
    const isAllDay: boolean = this.isAllDayEvent(timeString);
    eventInfo.mIsAllDay = isAllDay;
    let valueTemp: string = timeString;
    if (isAllDay && VCalUtils.isTimeParamMissing(valueTemp)) {
      // 全天日程匹配到正则表达式"\\d{8}"，将其拼接成"\\d{8}[T]\\d{6}[Z]"
      valueTemp = VCalUtils.appendTimeParameter(valueTemp);
    }
    if (TimeZoneUtil.isValidTimezone(this.mInfo.getTimezone())) {
      if (!isAllDay) {
        this.mTime.setTimeZone(this.mInfo.getTimezone());
      }
      const parseTimeStringResult: boolean = new FormatTime().parseByTimeString(valueTemp, this.mTime);
      if (!parseTimeStringResult) {
        Log.warn(TAG, `parseTime parseTimeStringResult is ${parseTimeStringResult} timeString is ${timeString}`);
        return new Pair(false, this.mTime);
      }
      return new Pair(true, this.mTime);
    } else {
      return this.parseStartAndEndTime(valueTemp, this.mTime, eventInfo.eventTimeZone);
    }
  }

  private isAllDayEvent(timeString: string): boolean {
    return this.isValidYYYYMMDDString(timeString);
  }

  /**
   * timeString.match(/^\d{4}\d{2}\d{2}$/) 这种正则不让用
   * @param timeString
   * @returns
   */
  private isValidYYYYMMDDString(timeString: string): boolean {
    const yyyyMMddRegExp: RegExp = new RegExp("\\d{8}", "g");
    return EmptyUtils.isNotEmptyString(timeString) && timeString.length == 8 && yyyyMMddRegExp.test(timeString);
  }


  private fillEventByParseAlarm(eventInfo: AgendaEventInfo, alarmValue: string) {
    const remindMinute: number = this.parseAlarmTime(alarmValue);
    if (remindMinute < 0) {
      return;
    }
    if (!eventInfo.checkValuesArray) {
      eventInfo.checkValuesArray = [];
    }
    const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
    reminder.remindMinutes = remindMinute;
    reminder.remindType = eventInfo.alertType;
    eventInfo.checkValuesArray.push(reminder);
  }

  /**
   * 从文件里获取提醒的分钟数，比如文件里的Trigger的value为-PT30M，要得到30
   *
   * @param alarmValue 待解析的字符串
   * @return 提醒的分钟数
   */
  private parseAlarmTime(alarmValue: string): number {
    if (EmptyUtils.isEmptyString(alarmValue, true)) {
      Log.warn(TAG, `parseAlarmTime alarmValue is empty`);
      return -1;
    }
    const unitIndex = alarmValue.length - 1;
    const unit: string = alarmValue.charAt(unitIndex);
    let multiple: number = 1;
    if (M == unit) {
      multiple = 1;
    } else if (H == unit) {
      multiple = MINUTES_PER_HOUR;
    } else if (D == unit) {
      multiple = MINUTES_PER_DAY;
    } else if (P == unit) { // 全天事件的默认提醒
      return 0;
    } else {
      return 10;
    }
    let alarmNumValue: string = '';
    for (let i = unitIndex - 1; i >= 0; i--) {
      const alarmNumber: Number = Number(alarmValue.charAt(i));
      if (Number.isNaN(alarmNumber)) {
        break;
      }
      alarmNumValue = alarmNumber.valueOf().toString() + alarmNumValue;
    }
    if (EmptyUtils.isEmptyString(alarmNumValue)) {
      Log.warn(TAG, `parseAlarmTime no vaild alarmValue`);
      return -1;
    }
    const alarmFinalNumber: Number = Number(alarmNumValue);
    if (Number.isNaN(alarmFinalNumber)) {
      Log.warn(TAG, `parseAlarmTime alarmFinalNumber no vaild alarmValue`);
      return -1;
    }
    return alarmFinalNumber.valueOf() * multiple;
  }


  private fillEventByParseStatus(eventInfo: AgendaEventInfo, value: string) {
    if (equalsIgnoreCase(TENTATIVE, value)) {
      eventInfo.status = '0';
    } else if (equalsIgnoreCase(CONFIRMED, value)) {
      eventInfo.status = '1';
    } else if (equalsIgnoreCase(CANCELLED, value) || equalsIgnoreCase(DECLINED, value)) {
      eventInfo.status = '2';
    } else {
      Log.info(TAG, "no need set state");
    }
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
      const parameter: Parameter = expectedList[0]
      return parameter.value;
    } else {
      return UTF_8;
    }
  }

  private canParseEncoding(name: String): boolean {
    return (LOCATION == name || SERVICEDESCRIPTION == name ||
      SERVICEURI == name || DESCRIPTION == name || SUMMARY == name);
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
    } else if (equalsIgnoreCase('BASE64', encoding)) {
      decodedValue = this.decodeBase64String(value, charSet);
    } else {
      decodedValue = this.unfoldContentLineFolding(value);
    }
    Log.info(TAG, `decodeParameterValue Exit`);
    return decodedValue;
  }

  private decodeBase64String(value: string, charSet: string): string {
    return value;
  }

  private decodeQuotedPrintable(value: string, charSet: string): string {
    if (EmptyUtils.isEmptyString(value)) {
      return '';
    }
    return QuotedPrintableHelper.getInstance().decodeQuotedPrintable(value, charSet);
  }
}