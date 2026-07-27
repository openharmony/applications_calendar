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

import { i18n } from '@kit.LocalizationKit';
import { I18nUtil } from '../util/I18nUtil';
import { TimeZoneUtil } from '../util/TimeZoneUtil';

const FIELD_YEAR: string = 'year'; // 年
const FIELD_WEEK_OF_YEAR: string = 'week_of_year'; // 一年中的第几周，按照星期计算周，注意：第一周的归属算法各地有区别
const FIELD_MONTH: string = 'month'; // 月
const FIELD_WEEK_OF_MONTH: string = 'week_of_month'; // 一个月中的第几周，按照星期计算周
const FIELD_DATE: string = 'date'; // 日
const FIELD_DAY_OF_YEAR: string = 'day_of_year'; // 一年中的第几天
const FIELD_DAY_OF_WEEK: string = 'day_of_week'; // 一周中的第几天(星期)
const FIELD_WEEK: string = 'dow_local'; // 本地星期
const FIELD_HOUR: string = 'hour'; // 挂钟小时数,可能为12小时
const FIELD_HOUR_OF_DAY: string = 'hour_of_day'; // 一天中的第几小时
const FIELD_MINUTE: string = 'minute'; // 分
const FIELD_SECOND: string = 'second'; // 秒
const FIELD_MILLI_SECOND: string = 'millisecond'; // 毫秒
const FIELD_ZONE_OFFSET: string = 'zone_offset'; // 以毫秒计时的时区固定偏移量(不含夏令时)
const FIELD_DST_OFFSET: string = 'dst_offset'; // 以毫秒计时的夏令时偏移量
const FIELD_JULIAN_DAY: string = 'julian_day'; // 儒略日,与当前时区相关
const FIELD_IS_LEAP_MONTH: string = 'is_leap_month'; // 是否为闰月
const TIME_ZONE_UTC: string = 'UTC'; // UTC时区

// 用于时区管理的Date类
export class CalendarDate {
  // 当前日历存储的时区
  public static timeZone: string = I18nUtil.getSystemTimeZone();
  // calendar日期类 固定公历，时区偏移
  private mCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale(), 'gregory');
  private mDate: Date = new Date();

  constructor(time?: number | string | Date, monthIndex?: number, date?: number, hours?: number, minutes?: number,
    seconds?: number, ms?: number) {
    this.mCalendar.setTimeZone(CalendarDate.timeZone);
    this.mCalendar.setTime(Date.now());
    if (time === undefined) { // 对应new Date()
      this.mDate.setTime(this.getTime());
    } else if ((typeof time === 'string' || time instanceof Date) && monthIndex === undefined) { // 对应new Date('2024-05-29')
      this.mDate = new Date(time);
      this.set(this.mDate.getFullYear(), this.mDate.getMonth(), this.mDate.getDate(), this.mDate.getHours(),
        this.mDate.getMinutes(), this.mDate.getSeconds(), this.mDate.getMilliseconds());
      this.mDate.setTime(this.getTime());
    } else if (typeof time === 'number' && monthIndex === undefined) { // 对应new Date(1234567890)
      this.mCalendar.setTime(time);
      this.mDate.setTime(this.getTime());
    } else if (typeof time === 'number' && monthIndex !== undefined) { // 对应new Date(2024,4,1)
      const inDate = date ?? 0;
      const inHours = hours ?? 0;
      const inMinutes = minutes ?? 0;
      const inSeconds = seconds ?? 0;
      const inMs = ms ?? 0;
      this.set(time, monthIndex, inDate, inHours,
        inMinutes, inSeconds, inMs);
      this.mDate.setTime(this.getTime());
    } else { // 其他异常情况
      this.mCalendar.setTime(Date.now());
      this.mDate.setTime(this.getTime());
    }
  }

  /**
   * 更新当前时区
   */
  public static updateTimeZone(): void {
    CalendarDate.timeZone = I18nUtil.getSystemTimeZone();
  }
  /**
   * 获取当前时区对应的年月日时分秒对应的日期,用于转换字符串
   * @returns 当前时区的年月日时分秒对应的日期对象
   */
  public getDateInfoByCalendar(): Date {
    return new Date(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), this.getMinutes(),
      this.getSeconds(), this.getMilliseconds());
  }

  public getDateInfo(): Date {
    return this.mDate;
  }

  public getTimeOffset(): number {
    return this.getTime() - this.getDateInfoByCalendar().getTime();
  }

  /**
   * Set the time
   *
   * @param { number } year - The year field of the calendar, ranges from 0 to 9999.
   * @param { number } month - The month field of the calendar, ranges from 0 to 11.
   * @param { number } date - The day field of the calendar, ranges from 1 to 31.
   * @param { number } hour - The hour field of the calendar, ranges from 0 to 23.
   * @param { number } minute - The minute field of the calendar, ranges from 0 to 59.
   * @param { number } second - the second field of the calendar, ranges from 0 to 59.
   */
  public set(year: number, month: number, day: number, hour?: number, minute?: number, second?: number,
    milliseconds?: number) {
    let setYear = this.getFullYear();
    let setMonth = month;
    let setDay = day;
    let setHour = this.getHours();
    let setMinute = this.getMinutes();
    let setSecond = this.getSeconds();
    let setMilliseconds = this.getMilliseconds();
    if (year > 0 && year < 9999) {
      setYear = year;
    }
    if (hour !== undefined) {
      setHour = hour;
    }
    if (minute !== undefined) {
      setMinute = minute;
    }
    if (second !== undefined) {
      setSecond = second;
    }
    if (milliseconds !== undefined) {
      setMilliseconds = milliseconds;
    }
    this.mCalendar.set(setYear, setMonth, setDay, setHour, setMinute, setSecond);
    this.setMilliseconds(setMilliseconds);
  }

  public getFullYear(): number {
    return this.mCalendar.get(FIELD_YEAR);
  }

  public setFullYear(year: number, month?: number, date?: number): number {
    const newMonth = month ?? this.getMonth();
    const newDate = date ?? this.getDate();
    this.set(year, newMonth, newDate, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }

  public getMonth(): number {
    return this.mCalendar.get(FIELD_MONTH);
  }

  public setMonth(month: number, date?: number): number {
    const newDate = date ?? this.getDate();
    this.set(this.getFullYear(), month, newDate, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }

  public getDate(): number {
    return this.mCalendar.get(FIELD_DATE);
  }

  public getDayOfYear(): number {
    return this.mCalendar.get(FIELD_DAY_OF_YEAR);
  }

  public setDate(date: number): number {
    this.set(this.getFullYear(), this.getMonth(), date, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }

  public getHours(): number {
    return this.mCalendar.get(FIELD_HOUR_OF_DAY);
  }

  public setHours(hours: number, minutes?: number, seconds?: number, milliseconds?: number): number {
    const newMinutes = minutes ?? this.getMinutes();
    const newSeconds = seconds ?? this.getSeconds();
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), hours, newMinutes, newSeconds, milliseconds);
    return this.getTime();
  }

  public getMinutes(): number {
    return this.mCalendar.get(FIELD_MINUTE);
  }

  public setMinutes(minutes: number): number {
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), minutes, this.getSeconds());
    return this.getTime();
  }

  public getSeconds(): number {
    return this.mCalendar.get(FIELD_SECOND);
  }

  public setSeconds(seconds: number): number {
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), this.getMinutes(), seconds);
    return this.getTime();
  }

  public getTime(): number {
    return this.mCalendar.getTimeInMillis();
  }

  public setTime(timeStamp: number): number {
    this.mCalendar.setTime(timeStamp);
    this.mDate.setTime(timeStamp);
    return this.getTime();
  }

  public getMilliseconds(): number {
    return this.mCalendar.get(FIELD_MILLI_SECOND);
  }

  public setMilliseconds(mills: number): number {
    const nowTime = this.getTime();
    const setTime = Math.trunc(nowTime / 1000) * 1000 + mills;
    return this.setTime(setTime);
  }

  /**
   * 获取某个时间点的时区偏移量，适配中国夏令时1986-1991年,GMT+9（非GMT+8）
   *
   * @param timeStamp
   * @returns
   */
  public getTimezoneOffset(timeStamp: number): number {
    return TimeZoneUtil.getTimeZoneOffset(CalendarDate.timeZone, timeStamp);

  }

  public getDay(): number {
    return this.mCalendar.get(FIELD_DAY_OF_WEEK) - 1;
  }

  public getJulianDay(): number {
    return this.mCalendar.get(FIELD_JULIAN_DAY);
  }

  public toDateString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toDateString();
  }

  public toString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toString();
  }

  public toTimeString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toTimeString();
  }

  public toLocaleString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleString(locales, options);
  }

  public toLocaleDateString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleDateString(locales, options);
  }

  public toLocaleTimeString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleTimeString(locales, options);
  }

  public valueOf(): number {
    return this.mDate.valueOf();
  }

  public getUTCFullYear(): number {
    return this.mDate.getUTCFullYear();
  }

  getUTCMonth(): number {
    return this.mDate.getUTCMonth();
  }

  getUTCDate(): number {
    return this.mDate.getUTCDate();
  }

  getUTCDay(): number {
    return this.mDate.getUTCDay();
  }

  getUTCHours(): number {
    return this.mDate.getUTCHours();
  }

  getUTCMinutes(): number {
    return this.mDate.getUTCMinutes();
  }

  getUTCSeconds(): number {
    return this.mDate.getUTCSeconds();
  }

  getUTCMilliseconds(): number {
    return this.mDate.getUTCMilliseconds();
  }

  setUTCMilliseconds(ms: number): number {
    this.mDate.setUTCMilliseconds(ms);
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCSeconds(sec: number, ms?: number | undefined): number {
    this.mDate.setUTCSeconds(sec, ms ?? this.mDate.getUTCMinutes());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCMinutes(min: number, sec?: number | undefined, ms?: number | undefined): number {
    this.mDate.setUTCMinutes(min, sec ?? this.mDate.getUTCSeconds(), ms ?? this.mDate.getUTCMinutes())
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCHours(hours: number, min?: number | undefined, sec?: number | undefined, ms?: number | undefined): number {
    this.mDate.setUTCHours(hours, min ?? this.mDate.getUTCMinutes(), sec ?? this.mDate.getUTCSeconds(),
      ms ?? this.mDate.getUTCMinutes());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCDate(date: number): number {
    this.mDate.setUTCDate(date);
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCMonth(month: number, date?: number | undefined): number {
    this.mDate.setUTCMonth(month, date ?? this.mDate.getUTCDate());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  setUTCFullYear(year: number, month?: number | undefined, date?: number | undefined): number {
    this.mDate.setUTCFullYear(year, month ?? this.mDate.getUTCMonth(), date ?? this.mDate.getUTCDate());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }

  toUTCString(): string {
    return this.getDateInfoByCalendar().toUTCString();
  }

  toISOString(): string {
    return this.getDateInfoByCalendar().toISOString();
  }

  toJSON(key?: string | number | boolean): string {
    return this.getDateInfoByCalendar().toJSON(key);
  }
  
  /**
   * 设置单个对象时区
   * @param timeZone
   */
  setTimeZone(timeZone: string) {
    this.mCalendar.setTimeZone(timeZone);
  }

  getTimeZone(): string {
    return this.mCalendar.getTimeZone();
  }
}