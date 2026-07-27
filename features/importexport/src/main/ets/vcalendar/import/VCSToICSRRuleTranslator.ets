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

import { EmptyUtils, Log } from '@app/common';
import { BusinessError } from '@ohos.base';

const TAG = 'VCSToICSRRuleTranslator'

const DEFAULT_VALUE = -1;

const DEFAULT_OFFSET = 2;

const DEFAULT_DURATION = '2';

const PARSE_ERROR = -1;

const DAILY = 0;

const WEEKLY = 1;

const MONTHLY_BY_DATE = 2;

const MONTHLY_BY_POS = 3;

const YEARLY_BY_DAY = 4;

const YEARLY_BY_POS = 5;

const DAY_NUMBER_MAX_LEN = 3;

const MAX_DIGITS_IN_MONTH = 2;

const YEAR_DAY_MAX_LEN = 3;

const COMMA = ',';

const RULE_TYPE_MAP: Map<string, number> = new Map<string, number>([['D', DAILY], ['W', WEEKLY],
  ['MD', MONTHLY_BY_DATE], ['MP', MONTHLY_BY_POS], ['YD', YEARLY_BY_DAY], ['YM', YEARLY_BY_POS]]);


const S_WEEK_DAYS: Map<string, string> = new Map<string, string>([['MO', ''], ['TU', ''], ['WE', ''],
  ['TH', ''], ['FR', ''], ['SA', ''], ['SU', '']]);

/**
 * VCSToICSRRuleTranslator
 *
 */
export class VCSToICSRRuleTranslator {
  private mFreq: string = '';
  private mInterval: number = 0;
  private mByDay: string = '';
  private mByWeekday: string = '';
  private mByMonthDay: string = '';
  private mByMonth: string = '';
  private mByYearDay: string = '';
  private mDuration: string = '';
  private mUntil: string = '';
  private mOccuranceList: string[] = [];
  private mWeekdayList: string[] = [];

  /**
   * parse
   *
   * @param vcsRrule vcs rule
   * @return b
   * @throws Exception e
   */
  public parse(vcsRrule: string): boolean {
    Log.info(TAG, `Enter parse vcsRrule is ${vcsRrule}`);
    this.reset();
    if (EmptyUtils.isEmptyString(vcsRrule)) {
      return false;
    }
    let offset: number = 0;
    vcsRrule = this.getFormatVcsRuleString(vcsRrule.trim());
    offset = this.parseFreq(vcsRrule, offset);
    offset = this.parseInterval(vcsRrule, offset);
    offset = this.parseWs(vcsRrule, offset);

    switch (RULE_TYPE_MAP.get(this.mFreq)) {
      case DAILY: {
        break;
      }
      case WEEKLY: {
        offset = this.parseWeekdayList(vcsRrule, offset);
        break;
      }
      case MONTHLY_BY_DATE: {
        offset = this.parseDayNumberList(vcsRrule, offset);
        break;
      }
      case MONTHLY_BY_POS: {
        offset = this.parseOccuranceWeekdayList(vcsRrule, offset);
        break;
      }
      case YEARLY_BY_DAY: {
        offset = this.parseYearDayList(vcsRrule, offset);
        break;
      }
      case YEARLY_BY_POS: {
        offset = this.parseMonthList(vcsRrule, offset);
        break;
      }
      default: {
        return false;
      }
    }
    let len = vcsRrule.length;
    this.parseRrule(vcsRrule, offset, len);
    return true;
  }

  /**
   * parse Week day
   *
   * @param vcsRrule vcs rule
   * @param offset offset
   * @return week day
   */
  public parseWeekday(vcsRrule: string, offset: number): number {
    if (vcsRrule.length > (offset + 1)) {
      if (S_WEEK_DAYS.has(vcsRrule.substring(offset, offset + DEFAULT_OFFSET))) {
        offset += DEFAULT_OFFSET;
      }
    }
    return offset;
  }

  /**
   * parse Month
   *
   * @param vcsRrule vcs rule
   * @param offset offset
   * @return parse Month
   */
  public parseMonth(vcsRrule: string, offset: number): number {
    let len: number = vcsRrule.length;
    let index = 0;
    while (len > (offset + index)) {
      if (this.isDigitChar(vcsRrule, offset + index)) {
        index++;
      } else {
        break;
      }
    }
    if (index <= MAX_DIGITS_IN_MONTH) {
      offset += index;
    }
    return offset;
  }

  /**
   * toString
   *
   * @return ics rule
   */
  public buildRepeatRuleString(): string {
    let icsRrule: string = '';
    icsRrule = 'FREQ=';
    switch (RULE_TYPE_MAP.get(this.mFreq)) {
      case DAILY: {
        icsRrule += 'DAILY';
        break;
      }
      case WEEKLY: {
        icsRrule += 'WEEKLY';
        break;
      }
      case MONTHLY_BY_DATE:
      case MONTHLY_BY_POS: {
        icsRrule += 'MONTHLY';
        break;
      }
      case YEARLY_BY_DAY:
      case YEARLY_BY_POS: {
        icsRrule += 'YEARLY';
        break;
      }
      default: {
        Log.warn(TAG, `buildRepeatRuleString Unsupported freq ${this.mFreq}}=`);
        return '';
      }
    }

    Log.info(TAG, `buildRepeatRuleString Ics rrule mFreq is ${icsRrule}`);

    icsRrule = this.appendDetail(icsRrule);

    icsRrule += ';'; // append ';' in the end.
    Log.debug(TAG, `buildRepeatRuleString Ics rrule after conversion is ${icsRrule}`);
    return icsRrule;
  }

  private getFormatVcsRuleString(srcPath: string): string {
    if (EmptyUtils.isEmptyString(srcPath, true)) {
      return '';
    }
    const regex = new RegExp('LD', 'g');
    return srcPath.replace(regex, '1-');
  }

  private parseRrule(vcsRrule: string, offset: number, len: number): void {
    if (offset < len) {
      let offsetTemp: number = offset;
      offsetTemp = this.parseWs(vcsRrule, offsetTemp);
      let length: number = vcsRrule.length;
      if (vcsRrule.charAt(offsetTemp) === '#') {
        let tmp: string = vcsRrule.substring(offsetTemp + 1, length);
        let indexSplit: number = tmp.indexOf(' ');
        if (indexSplit !== DEFAULT_VALUE) {
          this.mDuration = tmp.substring(0, indexSplit);
        } else {
          this.mDuration = tmp;
        }
      } else {
        this.mUntil = vcsRrule.substring(offsetTemp, length);
      }
    }

    // Set COUNT to 2 as per vcalendar1.0 specification if both duration and until are missing.
    if (EmptyUtils.isEmptyString(this.mDuration) && EmptyUtils.isEmptyString(this.mUntil)) {
      this.mDuration = DEFAULT_DURATION;
    }
  }

  private parseFreq(vcsRrule: string, offset: number): number {
    Log.info(TAG, `Enter parseFreq a VCSRrule is ${vcsRrule} offset is ${offset}`);
    let charAt: string = '';
    let freq: string = '';
    const len = vcsRrule.length;
    while (offset < len) {
      charAt = vcsRrule.charAt(offset);
      if (this.isLetter(charAt)) {
        freq = freq + charAt;
        offset++;
      } else {
        break;
      }
    }
    if ('' !== freq) {
      this.mFreq = freq;
    } else {
      offset = PARSE_ERROR;
    }
    return offset;
  }

  private isLetter(char: string): boolean {
    if (EmptyUtils.isEmptyString(char) || char.length !== 1) {
      return false;
    }
    const charCode = char.codePointAt(0);
    if (!charCode) {
      return false;
    }
    return (charCode >= 97 && charCode <= 122) || (charCode > 64 && charCode < 91);
  }

  /**
   * Parse Interval
   *
   * @param vcstRule String
   * @param offset int
   * @return currentOffset int
   */
  private parseInterval(vcsRrule: string, offset: number): number {
    let currentOffset = offset;
    if (vcsRrule.length > currentOffset) {
      let intervalString: string = '';
      while ((vcsRrule.length > currentOffset) && (this.isDigitChar(vcsRrule, currentOffset))) {
        intervalString = intervalString + vcsRrule.charAt(currentOffset);
        currentOffset++;
      }
      try {
        const intervalValue = Number(intervalString);
        if (isNaN(intervalValue)) {
          Log.warn(TAG, `parseInterval parseInt error intervalString is ${intervalString}`);
        } else {
          this.mInterval = intervalValue.valueOf();
        }
      } catch (error) {
        const err = error as BusinessError;
        Log.error(TAG, `parseInterval error ${err?.message}  ${err?.code}`);
      }
    }
    return currentOffset;
  }

  private isDigitChar(vcsRrule: string, currentOffset: number): boolean {
    const char = vcsRrule.charAt(currentOffset);
    if (EmptyUtils.isEmptyString(char)) {
      return false;
    }
    const charCode = char.codePointAt(0);
    if (!charCode) {
      return false;
    }
    return (charCode > 47 && charCode < 58);
  }

  private parseOccuranceWeekdayList(vcsRrule: string, offset: number): number {
    const len: number = vcsRrule.length;
    let offsetEnd = offset;
    let offsetStart = 0;
    let isParsedSomeOccurence: boolean = false;
    let isEndOfOccurence = false;
    while (offset < len) {
      let occurenceList: string = '';
      let weekdayList: string = '';
      do {
        offsetStart = offsetEnd;
        offsetEnd = this.parseOccurence(vcsRrule, offsetEnd);
        if (offsetEnd != offsetStart) {
          occurenceList = occurenceList + this.getOccurence(vcsRrule, offsetStart, offsetEnd) + COMMA;
          offsetEnd = this.parseWs(vcsRrule, offsetEnd);
          isParsedSomeOccurence = true;
        } else {
          if (!isParsedSomeOccurence) {
            isEndOfOccurence = true;
          }
          break;
        }
      } while (offsetEnd < len);

      if (!isEndOfOccurence) {
        do {
          offsetStart = offsetEnd;
          offsetEnd = this.parseWeekday(vcsRrule, offsetEnd);
          if (offsetEnd != offsetStart) {
            weekdayList = weekdayList + this.getSubString(vcsRrule, offsetStart, offsetEnd) + COMMA;
            offsetEnd = this.parseWs(vcsRrule, offsetEnd);
          } else {
            isParsedSomeOccurence = false;
            break;
          }
        } while (offsetEnd < len);
      } else {
        break; // Break from the outermost while().
      }
      // store the occurence and weekday list temporarily.It will be used by getByDay() to construct BYDAY value.
      if (occurenceList.length > 0) {
        this.mOccuranceList.push(occurenceList);
      }
      if (weekdayList.length > 0) {
        this.mWeekdayList.push(weekdayList);
      }
      offset = offsetEnd;
    }
    this.getByDay(); // get the mByDay value.
    return offset;
  }

  private parseOccurence(vcsRrule: string, offset: number): number {
    if (this.isDigitChar(vcsRrule, offset)) {
      if (('+' == vcsRrule.charAt(offset + 1)) || ('-' == vcsRrule.charAt(offset + 1))) {
        offset += DEFAULT_OFFSET;
      }
    }
    return offset;
  }

  /**
   * 翻转Occurence 最后一个字符,最后一个字符是符号
   * @param vcsRrule
   * @param startOffset
   * @param endOffset
   * @returns
   */
  private getOccurence(vcsRrule: string, startOffset: number, endOffset: number): string {
    // Swap the digit and sign
    let occurence: string = '';
    let isLengthValid: boolean = (startOffset >= 0) && (endOffset > 0);
    if (isLengthValid && (vcsRrule.length > startOffset) && (vcsRrule.length >= endOffset)) {
      occurence = vcsRrule.substring(startOffset, endOffset);
    }
    if ((occurence != null) && (occurence.length > 0)) {
      occurence = occurence.substring(occurence.length - 1) + occurence.substring(0, occurence.length - 1);
    }
    return occurence;
  }

  private getByDay(): void {
    const occurenceCount: number = this.mOccuranceList.length;
    const weekDayCount: number = this.mWeekdayList.length;
    if ((weekDayCount > 0) && (occurenceCount == weekDayCount)) {
      let byDay: string = '';
      for (let index = 0; index < occurenceCount; index++) {
        const occurenceLists: string[] = this.mOccuranceList[index].split(COMMA);
        const weekdayLists: string[] = this.mWeekdayList[index].split(COMMA);
        this.getByDayAppend(occurenceLists, weekdayLists, byDay);
      }
    }
  }

  private getByDayAppend(occurenceLists: string[], weekdayLists: string[], byDay: string): void {
    if (EmptyUtils.isEmptyArray(occurenceLists) || EmptyUtils.isEmptyArray(weekdayLists) ||
      byDay === undefined || byDay === null) {
      return;
    }
    for (let occurence of occurenceLists) {
      for (let weekday of weekdayLists) {
        byDay = byDay + occurence + weekday + COMMA;
      }
    }
    this.mByDay = byDay;
  }

  private parseWeekdayList(vcsRrule: string, offset: number): number {
    let len: number = vcsRrule.length;
    let offsetStart: number = 0;
    let offsetEnd: number = offset;
    let weekdayList: string = '';
    if (len > offset) {
      do {
        offsetStart = offsetEnd;
        offsetEnd = this.parseWeekday(vcsRrule, offsetEnd);
        if (offsetEnd != offsetStart) {
          weekdayList = weekdayList + this.getSubString(vcsRrule, offsetStart, offsetEnd);
          weekdayList = weekdayList + COMMA;
          offsetEnd = this.parseWs(vcsRrule, offsetEnd);
        } else {
          break;
        }
      } while (len > offsetEnd);
    }
    offset = offsetEnd;
    if (EmptyUtils.isNotEmptyString(weekdayList)) {
      this.mByWeekday = weekdayList;
    }
    return offset;
  }

  private parseYearDayList(vcsRrule: string, offset: number): number {
    let len = vcsRrule.length;
    let offsetStart: number = 0;
    let offsetEnd: number = offset;
    let yearDayList: string = '';
    if (len > offset) {
      do {
        offsetStart = offsetEnd;
        offsetEnd = this.parseYearDay(vcsRrule, offsetEnd);
        if (offsetEnd != offsetStart) {
          yearDayList = yearDayList + this.getSubString(vcsRrule, offsetStart, offsetEnd);
          yearDayList = yearDayList + COMMA;
          offsetEnd = this.parseWs(vcsRrule, offsetEnd);
        } else {
          break;
        }
      } while (len > offsetEnd);
    }
    offset = offsetEnd;
    this.mByYearDay = yearDayList;
    return offset;
  }

  /**
   * parse Year Day
   *
   * @param vcsRrule vcs rule
   * @param offset offset
   * @return year Day
   */
  private parseYearDay(vcsRrule: string, offset: number): number {
    let len: number = vcsRrule.length;
    let digitsInYearDay: number = 0;
    while (len > (offset + digitsInYearDay)) {
      if (this.isDigitChar(vcsRrule, offset + digitsInYearDay)) {
        digitsInYearDay++;
      } else {
        break;
      }
    }

    if (digitsInYearDay <= YEAR_DAY_MAX_LEN) {
      offset += digitsInYearDay;
    }
    return offset;
  }

  /**
   * parse Day Number List
   *
   * @param vcsRrule vcs rule
   * @param offset offset
   * @return day Number
   */
  private parseDayNumberList(vcsRrule: string, offset: number): number {
    let offsetStart: number = 0;
    let offsetEnd: number = offset;
    let dayNumberList: string = '';
    let len: number = vcsRrule.length;
    if (len > offset) {
      do {
        offsetStart = offsetEnd;
        offsetEnd = this.parseDayNumber(vcsRrule, offsetEnd);
        if (offsetEnd != offsetStart) {
          dayNumberList = dayNumberList + this.getDayNumber(vcsRrule, offsetStart, offsetEnd);
          dayNumberList = dayNumberList + COMMA;
          offsetEnd = this.parseWs(vcsRrule, offsetEnd);
        } else {
          break;
        }
      } while (len > offsetEnd);
    }
    this.mByMonthDay = dayNumberList.toString();
    offset = offsetEnd;
    return offset;
  }

  /**
   * parse Day Number
   *
   * @param vcsRrule vcs rule
   * @param offset offset
   * @return day Number
   */
  private parseDayNumber(vcsRrule: string, offset: number): number {
    const len: number = vcsRrule.length;
    let dayNumber: number = offset;
    while (len > dayNumber) {
      if (this.isDigitChar(vcsRrule, dayNumber) || ('+' === vcsRrule.charAt(dayNumber)) ||
        ('-' === vcsRrule.charAt(dayNumber))) {
        dayNumber++;
      } else {
        break;
      }
    }
    if ((dayNumber - offset) <= DAY_NUMBER_MAX_LEN) {
      offset += (dayNumber - offset);
    }
    return offset;
  }

  /**
   * Get day number from 1 to 31
   *
   * @param vcsRrule vcs rule
   * @param offsetStart offset start
   * @param offsetEnd offset end
   * @return day number
   */
  private getDayNumber(vcsRrule: string, offsetStart: number, offsetEnd: number): string {
    let dayNumber: string = '';
    let isLengthValid: boolean = (offsetStart >= 0) && (offsetEnd > 0);
    if (isLengthValid && (vcsRrule.length > offsetStart) && (vcsRrule.length >= offsetEnd)) {
      dayNumber = vcsRrule.substring(offsetStart, offsetEnd);
    }
    let isDayNumberLengthValid: boolean = EmptyUtils.isNotEmptyString(dayNumber);
    if (isDayNumberLengthValid &&
      ((dayNumber.indexOf('+') != DEFAULT_VALUE) || (dayNumber.indexOf('-') != DEFAULT_VALUE))) {
      dayNumber = dayNumber.substring(dayNumber.length - 1) + dayNumber.substring(0, dayNumber.length - 1);
    }
    return dayNumber;
  }

  private parseMonthList(vcsRrule: string, offset: number): number {
    let offsetStart: number = 0;
    let offsetEnd: number = offset;
    let monthList: string = '';
    let len: number = vcsRrule.length;
    if (len > offset) {
      do {
        offsetStart = offsetEnd;
        offsetEnd = this.parseMonth(vcsRrule, offsetEnd);
        if (offsetEnd != offsetStart) {
          monthList = monthList + this.getSubString(vcsRrule, offsetStart, offsetEnd);
          monthList = monthList + COMMA;
          offsetEnd = this.parseWs(vcsRrule, offsetEnd);
        } else {
          break;
        }
      } while (len > offsetEnd);
    }
    this.mByMonth = monthList;
    return offsetEnd;
  }

  /**
   * Get sub string
   *
   * @param vcsRrule vcs rule
   * @param startOffset start offset
   * @param endOffset end offset
   * @return sub string
   */
  private getSubString(vcsRrule: string, startOffset: number, endOffset: number): string {
    let subString: string = '';
    let isLengthValid = (startOffset >= 0) && (endOffset > 0);
    if (isLengthValid && (vcsRrule.length > startOffset) && (vcsRrule.length >= endOffset)) {
      subString = vcsRrule.substring(startOffset, endOffset);
    }
    return subString;
  }

  private parseWs(vcsRrule: string, offset: number): number {
    let len: number = vcsRrule.length;
    while (len > offset) {
      let charAt: string = vcsRrule.charAt(offset);
      if ((charAt == ' ') || (charAt == '\t')) {
        offset++;
      } else {
        break;
      }
    }
    return offset;
  }

  private appendDetail(icsRrule: string): string {
    if (EmptyUtils.isNotEmptyString(this.mUntil)) {
      icsRrule += ';UNTIL=';
      icsRrule += this.mUntil;
    }

    if (EmptyUtils.isNotEmptyString(this.mDuration)) {
      icsRrule += ';COUNT=';
      icsRrule += this.mDuration;
    }

    if (this.mInterval != 0) {
      icsRrule += ';INTERVAL=';
      icsRrule += this.mInterval;
    }

    // append byday
    if (EmptyUtils.isNotEmptyString(this.mByDay)) {
      icsRrule += ';BYDAY=';
      icsRrule += this.trimLastComma(this.mByDay);
    }

    // append monthdays
    if (EmptyUtils.isNotEmptyString(this.mByMonthDay)) {
      icsRrule += ';BYMONTHDAY=';
      icsRrule += this.trimLastComma(this.mByMonthDay);
    }

    // append months
    if (EmptyUtils.isNotEmptyString(this.mByMonth)) {
      icsRrule += ';BYMONTH=';
      icsRrule += this.trimLastComma(this.mByMonth);
    }

    // append weedays
    if (EmptyUtils.isNotEmptyString(this.mByWeekday)) {
      icsRrule += ';BYDAY=';
      icsRrule += this.trimLastComma(this.mByWeekday);
    }

    // append yeardays
    if (EmptyUtils.isNotEmptyString(this.mByYearDay)) {
      icsRrule += ';BYYEARDAY=';
      icsRrule += this.trimLastComma(this.mByYearDay);
    }
    return icsRrule;
  }

  /**
   * Method to remove the extra comma from the comma separated value.
   *
   * @param commaSeparatedValue - to store the comma separated value.(eg:'+1SA,-2FR,+4TH,')
   * @return - value with extra comma removed.
   */
  private trimLastComma(commaSeparatedValue: string): string {
    if (EmptyUtils.isNotEmptyString(commaSeparatedValue)) {
      if (commaSeparatedValue.charAt(commaSeparatedValue.length - 1) === ',') {
        return commaSeparatedValue.substring(0, commaSeparatedValue.length - 1);
      }
    }
    return commaSeparatedValue;
  }

  /**
   * Method to clear all the member variables.
   */
  private reset(): void {
    this.mFreq = '';
    this.mInterval = 0;
    this.mByDay = '';
    this.mByWeekday = '';
    this.mByMonthDay = '';
    this.mByMonth = '';
    this.mByYearDay = '';
    this.mDuration = '';
    this.mUntil = '';
    this.mOccuranceList = [];
    this.mWeekdayList = [];
  }
}
