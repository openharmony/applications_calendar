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

import i18n from '@ohos.i18n';
import { CalendarDate, DateUtil, HOURS_PER_DAY, MINUTES_PER_HOUR, SECONDS_PER_MINUTE } from '@app/common';

const FIELD_YEAR: string = 'year';
const FIELD_WEEK_OF_YEAR: string = 'week_of_year';
const FIELD_MONTH: string = 'month';
const FIELD_WEEK_OF_MONTH: string = 'week_of_month';
const FIELD_DATE: string = 'date';
const FIELD_DAY_OF_YEAR: string = 'day_of_year';
const FIELD_DAY_OF_WEEK: string = 'day_of_week';
const FIELD_HOUR: string = 'hour';
const FIELD_HOUR_OF_DAY: string = 'hour_of_day';
const FIELD_MINUTE: string = 'minute';
const FIELD_SECOND: string = 'second';
const FIELD_MILLISECOND: string = 'millisecond';
const FIELD_ZONE_OFFSET: string = 'zone_offset';
const FIELD_DST_OFFSET: string = 'dst_offset';
const FIELD_JULIAN_DAY: string = 'julian_day';
const FIELD_IS_LEAP_MONTH: string = 'is_leap_month';
const TIME_ZONE_UTC: string = 'UTC';

const TAG: string = 'CustomTime';

/**
 * 自定义的时间类，用于处理不同时区之间的差异，内含i18n的Calendar对象
 */
class CustomTime {
  private mCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale());

  private mDate?: CalendarDate;

  constructor(timeZone?: string) {
    if (timeZone) {
      this.mCalendar.setTimeZone(timeZone);
    }
  }

  public setTimeZone(timeZoneId: string) {
    if (!timeZoneId) {
      timeZoneId = TIME_ZONE_UTC;
    }
    this.mCalendar.setTimeZone(timeZoneId);
  }

  public getTimeZone(): string {
    return this.mCalendar.getTimeZone();
  }

  public setTime(mills: number): CustomTime {
    this.mCalendar.setTime(mills);
    return this;
  }

  public getYear(): number {
    this.mCalendar.getFirstDayOfWeek();
    return this.mCalendar.get(FIELD_YEAR);
  }

  /**
   * 获取当前月份
   *
   * @returns 取值0-11,0表示1月，11表示12月
   */
  public getMonth(): number {
    return this.mCalendar.get(FIELD_MONTH);
  }

  public getDate(): number {
    return this.mCalendar.get(FIELD_DATE);
  }

  /**
   * 周日：1、周一：2、周二：3、周三：4、周四：5、周五：6、周六：7
   *
   * @returns 当前日周几对应的数字
   */
  public getDayOfWeek(): number {
    return this.mCalendar.get(FIELD_DAY_OF_WEEK);
  }

  /**
   * @returns 当前日在当前月的第几周
   */
  public getWeekOfMonth(): number {
    return this.mCalendar.get(FIELD_WEEK_OF_MONTH);
  }

  public getDayOfYear(): number {
    return this.mCalendar.get(FIELD_DAY_OF_YEAR);
  }

  public getWeekOfYear(): number {
    return this.mCalendar.get(FIELD_WEEK_OF_YEAR);
  }

  public getHour(): number {
    return this.mCalendar.get(FIELD_HOUR);
  }

  public getHourOfDay(): number {
    return this.mCalendar.get(FIELD_HOUR_OF_DAY);
  }

  public getMinute(): number {
    return this.mCalendar.get(FIELD_MINUTE);
  }

  public getSecond(): number {
    return this.mCalendar.get(FIELD_SECOND);
  }

  public getJulianDay(): number {
    return this.mCalendar.get(FIELD_JULIAN_DAY);
  }

  public getTimeZoneOffset(): number {
    return this.mCalendar.get(FIELD_ZONE_OFFSET) + this.mCalendar.get(FIELD_DST_OFFSET);
  }

  public getTimeInMills(): number {
    if (this.mDate === null || this.mDate === undefined) {
      this.mDate = new CalendarDate();
    }
    this.mDate.setUTCFullYear(this.getYear(), this.getMonth(), this.getDate());
    this.mDate.setUTCHours(this.getHourOfDay(), this.getMinute(), this.getSecond(), 0);
    return this.mDate.getTime() - this.getTimeZoneOffset();
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
  public set(year: number, month: number, day: number, hour?: number, minute?: number, second?: number) : boolean {
    if (year <= 0 || year > 9999) {
      return false;
    }
    if (month < 0 || month > 11) {
      return false;
    }
    if (day <= 0 || day > 31) {
      return false;
    }
    if (hour && (hour < 0 || hour > 23)) {
      return false;
    }
    if (minute && (minute < 0 || minute > 59)) {
      return false;
    }
    if (second && (second < 0 || second > 59)) {
      return false;
    }
    this.mCalendar.set(year, month, day, hour, minute, second);
    return true;
  }

  public clone(customTime: CustomTime) {
    this.mCalendar.setTimeZone(customTime.getTimeZone());
    this.setTime(customTime.getTimeInMills());
  }

  public addMonth(value: number) {
    if (value <= 0) {
      return;
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    while (value > 0) {
      month++;
      value--;
      if (month > 11) {
        month = 0;
        year++;
      }
    }
    const maxDayInMonth: number = DateUtil.getMaxDayInMonth(year, month + 1);
    if (day > maxDayInMonth) {
      day = maxDayInMonth;
    }
    this.set(year, month, day);
  }

  public addDate(value: number) {
    if (value <= 0) {
      return;
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    let maxDatesInMonth: number = DateUtil.getMaxDayInMonth(year, month + 1);
    while (value > 0) {
      if (day + value > maxDatesInMonth) {
        // 若加上value后大于本月最大天数，则月份+1
        month++;
        if (month > 11) {
          month = 0;
          year++;
        }
        value = value - (maxDatesInMonth - day + 1);
        day = 1;
        maxDatesInMonth = DateUtil.getMaxDayInMonth(year, month + 1);
      } else {
        day += value;
        break;
      }
    }
    this.set(year, month, day);
  }

  public addHour(value: number) {
    if (value <= 0) {
      return;
    }
    let hour: number = this.getHourOfDay();
    hour += value;
    if (hour >= HOURS_PER_DAY) {
      let addDay: number = Math.trunc(hour / HOURS_PER_DAY);
      this.addDate(addDay);
      hour %= HOURS_PER_DAY;
      this.setHour(hour);
    } else {
      this.setHour(hour);
    }
  }

  public addMinute(value: number) {
    if (value <= 0) {
      return;
    }
    let minute: number = this.getHourOfDay();
    minute += value;
    if (minute >= MINUTES_PER_HOUR) {
      let addHour: number = Math.trunc(minute / MINUTES_PER_HOUR);
      this.addHour(addHour);
      minute %= MINUTES_PER_HOUR;
      this.setMinute(minute);
    } else {
      this.setMinute(minute);
    }
  }

  public addSecond(value: number) {
    if (value <= 0) {
      return;
    }
    let second: number = this.getHourOfDay();
    second += value;
    if (second >= SECONDS_PER_MINUTE) {
      let addMinute: number = Math.trunc(second / SECONDS_PER_MINUTE);
      this.addMinute(addMinute);
      second %= SECONDS_PER_MINUTE;
      this.setSecond(second);
    } else {
      this.setSecond(second);
    }
  }

  private setHour(hour: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), hour, this.getMinute(), this.getSecond());
  }

  private setMinute(minute: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), this.getHourOfDay(), minute, this.getSecond());
  }

  private setSecond(second: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), this.getHourOfDay(), this.getMinute(), second);
  }
}

export {
  CustomTime, TIME_ZONE_UTC
}