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

import { EmptyUtils, Log, UTC } from '@app/common';
import { CustomTime } from './CustTime';

const TAG: string = 'FormatTime';

// yyyyMMddTHHmmssZ 20200413T170000Z UTC Format
const utcRegExp: RegExp = new RegExp("\\d{8}[T]\\d{6}[Z]", "g");

// yyyyMMddTHHmmss 20200413T170000 iso8601Format
const iso8601RegExp: RegExp = new RegExp("\\d{8}[T]\\d{6}", "g");

// yyyyMMdd
const yyyyMMddRegExp: RegExp = new RegExp("\\d{8}", "g");

enum DateElementType {
  YEAR,
  MONTH,
  DAY,
  HOUR,
  MINUTES,
  SECOND
}

export enum TimeFormatType {
  UTC,
  ISO8601,
  YYYY_MM_DD
}

export enum FormatBit {
  //只显示年
  YEAR,
  //只显示年月
  MONTH,
  //只显示年月日
  DAY,
  //只显示年月日时
  HOUR,
  //只显示年月日时分
  MINUTE,
  //只显示年月日时分秒
  SECONDS,
}


/**
 * 格式化的时间处理，包含解析和格式化，兼容的时间格式如下：
 * 20231108、20231108T172800、20231108T172800Z
 */
export class FormatTime {
  year: number = 0;
  month: number = 0;
  day: number = 0;
  hour: number = 0;
  minute: number = 0;
  second: number = 0;
  isUTC: boolean = false;
  timeStamp: number = 0;
  private isSet = false;

  /**
   *
   * @param timeStr 时间格式字符串
   * @param customTime 携带timeStr 时区的 customTime
   * @returns 是否解析成功
   */
  public parseByTimeString(timeStr: string, customTime: CustomTime): boolean {
    this.reset();
    if (EmptyUtils.isEmptyString(timeStr, true)) {
      Log.warn(TAG, `parseByTimeString timeStr is Empty`);
      return false;
    }
    let parseResult: boolean = false;
    let parseType: string = 'YYYYMMDD';
    if (this.isUTCTimeString(timeStr)) {
      parseResult = this.parseByUtc(timeStr, customTime);
      parseType = 'yyyyMMddTHHmmssZ';
    } else if (this.isIso8601TimeString(timeStr)) {
      parseResult = this.parseByIso8601(timeStr, customTime);
      parseType = 'yyyyMMddTHHmmss';
    } else if (this.isYyyyMMddTimeString(timeStr)) {
      parseResult = this.parseByYyyyMMdd(timeStr, customTime);
    } else {
      parseType = 'illegal format';
      Log.warn(TAG, `parseByTimeString timeStr is ${timeStr} not support format`);
    }
    this.isSet = parseResult;
    return parseResult;
  }

  /**
   *
   * @param customTime
   * @param forceToUtc
   * @returns
   */
  public setByCustomTime(customTime: CustomTime, forceToUtc: boolean = true): FormatTime {
    this.reset();
    if (!customTime) {
      Log.warn(TAG, `setByCustomTime is null`);
      return this;
    }
    const originalTimeZone: string = customTime.getTimeZone();
    if (forceToUtc) {
      customTime.setTimeZone(UTC);
      this.isUTC = true;
    } else {
      this.isUTC = customTime.getTimeZone() === UTC;
    }
    this.year = customTime.getYear();
    this.month = customTime.getMonth();
    this.day = customTime.getDate();
    this.hour = customTime.getHourOfDay();
    this.minute = customTime.getMinute();
    this.second = customTime.getSecond();
    this.timeStamp = customTime.getTimeInMills();
    this.isSet = this.checkAllDateElement();
    if (!this.isSet) {
      Log.warn(TAG, `setByCustomTime result is false`);
    }
    if (forceToUtc) {
      customTime.setTimeZone(originalTimeZone);
    }
    return this;
  }

  public isHasSet(): boolean {
    return this.isSet;
  }

  /**
   * 将时间转化为格式化的字符串,如果内部状态异常返回 ''
   * @param isIso8601Format
   * @returns
   */
  public format(formatBit: FormatBit, splitOption?: SplitOption): string {
    if (!this.isSet) {
      Log.warn(TAG, `format formatBit ${formatBit} not set yet`);
      return '';
    }
    if (this.timeStamp === 0) {
      Log.warn(TAG, `format formatBit timeStamp is 0 illeagl`);
      return '';
    }
    if (formatBit < FormatBit.YEAR || formatBit > FormatBit.SECONDS) {
      Log.warn(TAG, `format formatBit is ${formatBit} illeagl`);
      return '';
    }
    const yearSplit: string = this.getYearSplit(splitOption);
    const monthSplit: string = this.getMonthSplit(splitOption);
    const daySplit: string = this.getDaySplit(splitOption);
    const hourSplit: string = this.getHourSplit(splitOption);
    const minuteSplit: string = this.getMinuteSplit(splitOption);
    const secondSplit: string = this.getSecondSplit(splitOption);
    const temMonth: number = this.month + 1;
    let formatTimeString: string = '';
    for (let i = 0; i <= formatBit; i++) {
      if (i == FormatBit.YEAR) {
        formatTimeString += `${this.year}${yearSplit}`;
        continue;
      }
      if (i == FormatBit.MONTH) {
        formatTimeString += `${temMonth < 10 ? '0' : ''}${temMonth}${monthSplit}`;
        continue;
      }
      if (i == FormatBit.DAY) {
        formatTimeString += `${this.day < 10 ? '0' : ''}${this.day}${daySplit}`;
        continue;
      }
      if (i == FormatBit.HOUR) {
        formatTimeString += `${this.hour < 10 ? '0' : ''}${this.hour}${hourSplit}`;
        continue;
      }
      if (i == FormatBit.MINUTE) {
        formatTimeString += `${this.minute < 10 ? '0' : ''}${this.minute}${minuteSplit}`;
        continue;
      }
      if (i == FormatBit.SECONDS) {
        formatTimeString += `${this.second < 10 ? '0' : ''}${this.second}${secondSplit}`;
        break;
      }
    }
    return formatTimeString;
  }

  /**
   * Format this time like 'yyyyMMddThhmmssZ'
   * 如果tzId 是UTC的,尾部拼接'Z',否则是yyyyMMddThhmmss格式
   *
   * @return Time string formatted
   */
  public getTimeInFormat2445(millis: number, tzId: string): string {
    const customTime: CustomTime = new CustomTime(tzId);
    customTime.setTime(millis);
    this.setByCustomTime(customTime, false);
    return this.format(FormatBit.SECONDS);
  }

  private reset() {
    this.year = 0;
    this.month = 0;
    this.day = 0;
    this.hour = 0;
    this.minute = 0;
    this.second = 0;
    this.isUTC = false;
    this.timeStamp = 0;
    this.isSet = false;
  }

  private parseByYyyyMMdd(timeStr: string, customTime: CustomTime): boolean {
    this.extractYyyyMmDd(timeStr);
    if (!this.checkAllDateElement()) {
      return false;
    }
    customTime.set(this.year, this.month, this.day, this.hour, this.minute, this.second);
    this.timeStamp = customTime.getTimeInMills();
    return true;
  }

  private extractYyyyMmDd(timeStr: string) {
    this.year = Number.parseInt(timeStr.substring(0, 4));
    this.month = (Number.parseInt(timeStr.substring(4, 6)) + 11) % 12;
    this.day = Number.parseInt(timeStr.substring(6, 8));
  }

  private checkAllDateElement(): boolean {
    return this.checkDateElement(this.year, DateElementType.YEAR)
      && this.checkDateElement(this.month, DateElementType.MONTH)
      && this.checkDateElement(this.day, DateElementType.DAY)
      && this.checkDateElement(this.hour, DateElementType.HOUR)
      && this.checkDateElement(this.minute, DateElementType.MINUTES)
      && this.checkDateElement(this.second, DateElementType.SECOND);
  }

  private checkDateElement(dateElement: number, dateElementType: DateElementType): boolean {
    if (dateElementType == DateElementType.YEAR && (dateElement < 1970 || dateElement > 2100)) {
      Log.warn(TAG, `checkDateElement year ${dateElement} false`);
      return false;
    }
    if (dateElementType == DateElementType.MONTH && (dateElement > 11 || dateElement < 0)) {
      Log.warn(TAG, `checkDateElement month ${dateElement} false`);
      return false;
    }
    if (dateElementType == DateElementType.DAY && (dateElement > 31 || dateElement < 1)) {
      Log.warn(TAG, `checkDateElement day ${dateElement} false`);
      return false;
    }
    if (dateElementType == DateElementType.HOUR && (dateElement > 23 || dateElement < 0)) {
      Log.warn(TAG, `checkDateElement honur ${dateElement} false`);
      return false;
    }
    if (dateElementType == DateElementType.MINUTES && (dateElement > 59 || dateElement < 0)) {
      Log.warn(TAG, `checkDateElement minute ${dateElement} false`);
      return false;
    }
    if (dateElementType == DateElementType.SECOND && (dateElement > 59 || dateElement < 0)) {
      Log.warn(TAG, `checkDateElement second ${dateElement} false`);
      return false;
    }
    return true;
  }

  private parseByIso8601(timeStr: string, customTime: CustomTime): boolean {
    this.extractYyyyMmDd(timeStr);
    this.extractHhMmSs(timeStr);
    if (!this.checkAllDateElement()) {
      return false;
    }
    customTime.set(this.year, this.month, this.day, this.hour, this.minute, this.second);
    this.timeStamp = customTime.getTimeInMills();
    return true;
  }

  /**
   * 抽取时分秒
   * @param timeStr
   * @param customTime
   */
  private extractHhMmSs(timeStr: string) {
    this.hour = Number.parseInt(timeStr.substring(9, 11));
    this.minute = Number.parseInt(timeStr.substring(11, 13));
    this.second = Number.parseInt(timeStr.substring(13, 15));
  }

  private parseByUtc(timeStr: string, customTime: CustomTime): boolean {
    this.extractYyyyMmDd(timeStr);
    this.extractHhMmSs(timeStr);
    if (!this.checkAllDateElement()) {
      return false;
    }
    const originalTimeZone: string = customTime.getTimeZone();
    this.isUTC = true;
    customTime.setTimeZone(UTC);
    customTime.set(this.year, this.month, this.day, this.hour, this.minute, this.second);
    this.timeStamp = customTime.getTimeInMills();
    customTime.setTimeZone(originalTimeZone);
    return true;
  }

  private isUTCTimeString(timeStr: string): boolean {
    utcRegExp.lastIndex = 0;
    if (EmptyUtils.isNotEmptyString(timeStr) && timeStr.length == 16 && utcRegExp.test(timeStr)) {
      return true;
    }
    return false;
  }

  private isIso8601TimeString(timeStr: string): boolean {
    iso8601RegExp.lastIndex = 0;
    if (EmptyUtils.isNotEmptyString(timeStr) && timeStr.length == 15 && iso8601RegExp.test(timeStr)) {
      return true;
    }
    return false;
  }

  /**
   * 同一个正则对象重复调用会出现下一次的匹配位置从上一次的结束位置开始,需要lastIndex 置0
   * @param timeStr
   * @returns
   */
  private isYyyyMMddTimeString(timeStr: string): boolean {
    yyyyMMddRegExp.lastIndex = 0;
    if (EmptyUtils.isNotEmptyString(timeStr) && timeStr.length == 8 && yyyyMMddRegExp.test(timeStr)) {
      return true;
    }
    return false;
  }

  /**
   * 20240106T193000 iso8601RegExp 和 yyyyMMddRegExp 都能匹配 ,需要用字符长度做强校验
   * @param timeStr
   * @returns
   */
  private isSupportTimeString(timeStr: string): boolean {
    if (EmptyUtils.isEmptyString(timeStr) || timeStr.length < 8 || timeStr.length > 16) {
      Log.warn(TAG, `isSupportTimeString timeStr ${timeStr} length illegal`);
      return false;
    }
    if (this.isUTCTimeString(timeStr)) {
      return true;
    }
    if (this.isIso8601TimeString(timeStr)) {
      return true;
    }
    if (this.isYyyyMMddTimeString(timeStr)) {
      return true;
    }
    return false;
  }

  private getYearSplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return '';
    }
    return splitOption.yearSplit;
  }

  private getMonthSplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return '';
    }
    return splitOption.monthSplit;
  }

  private getDaySplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return 'T';
    }
    return splitOption.daySplit;
  }

  private getHourSplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return '';
    }
    return splitOption.hourSplit;
  }

  private getMinuteSplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return '';
    }
    return splitOption.minuteSplit;
  }

  private getSecondSplit(splitOption: SplitOption | undefined): string {
    if (!splitOption) {
      return this.isUTC ? 'Z' : '';
    }
    return splitOption.secondSplit;
  }
}

/**
 * 时间戳的分割符
 * yyyyMMddThhmmssZ '' '' T '' '' Z
 *
 * yyyyMMddThhmmss '' '' T '' '' ''
 *
 * yyyyMMdd '' '' T '' '' ''
 *
 * 全天日程 yyyy-MM-dd '-' '-' '' '' '' ''
 * 非全天 yyyy-MM-dd HH:mm '-' '-' ' ' ':' '' ''
 */
export interface SplitOption {
  yearSplit: string;
  monthSplit: string;
  daySplit: string;
  hourSplit: string;
  minuteSplit: string;
  secondSplit: string;
}