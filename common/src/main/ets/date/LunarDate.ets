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

const LUNAR_DEFAULT_LOCALE: string = 'zh-Hans';

const CALENDAR_LUNAR_TYPE: string = 'chinese';

// 每个农历纪元60年，即常说的一甲子
const YEARS_PRE_ERA: number = 60;

const FIELD_ERA: string = 'era'; // 年
const FIELD_YEAR: string = 'year'; // 年
const FIELD_MONTH: string = 'month'; // 月
const FIELD_DATE: string = 'date'; // 日
const FIELD_DAY_OF_YEAR: string = 'day_of_year'; // 一年中的第几天
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

export class LunarDate {
  private mCalendar: i18n.Calendar = i18n.getCalendar(LUNAR_DEFAULT_LOCALE, CALENDAR_LUNAR_TYPE);

  constructor(locale: string = LUNAR_DEFAULT_LOCALE) {
    if (locale !== LUNAR_DEFAULT_LOCALE) {
      this.mCalendar = i18n.getCalendar(locale, CALENDAR_LUNAR_TYPE);
    }
  }

  setTime(timeInMills: number): void {
    this.mCalendar.setTime(timeInMills);
  }

  getTimeInMills(): number {
    return this.mCalendar.getTimeInMillis();
  }

  set(year: number, month: number, date: number, hour?: number, minute?: number, second?: number) {
    this.mCalendar.set(year, month, date, hour, minute, second);
  }

  getEra(): number {
    return this.mCalendar.get(FIELD_ERA);
  }

  setYear(year: number): void {
    this.mCalendar.set(year, this.mCalendar.get(FIELD_MONTH), this.mCalendar.get(FIELD_DATE));
  }

  getYear(): number {
    return this.mCalendar.get(FIELD_YEAR);
  }

  addYear(year: number): void {
    this.mCalendar.add(FIELD_YEAR, year);
  }

  getFullYear(): number {
    return this.getEra() * YEARS_PRE_ERA + this.getYear();
  }

  setMonth(month: number): void {
    this.mCalendar.set(this.mCalendar.get(FIELD_YEAR), month, this.mCalendar.get(FIELD_DATE));
  }

  getMonth(): number {
    return this.mCalendar.get(FIELD_MONTH);
  }

  setDate(date: number): void {
    this.mCalendar.set(this.mCalendar.get(FIELD_YEAR), this.mCalendar.get(FIELD_MONTH), date);
  }

  getDate(): number {
    return this.mCalendar.get(FIELD_DATE);
  }

  getDayOfYear(): number {
    return this.mCalendar.get(FIELD_DAY_OF_YEAR);
  }

  getJulianDay(): number {
    return this.mCalendar.get(FIELD_JULIAN_DAY);
  }
}