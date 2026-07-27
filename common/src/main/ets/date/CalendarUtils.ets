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



import { DateUtil, DAY_PER_WEEK, MILLS_PER_DAY } from '../util/DateUtil';
import { I18nUtil } from '../util/I18nUtil';
import i18n from '@ohos.i18n';
import { CalendarDate } from './CalendarDate';

/*
* Calendar utils
*
* @since 2022-03-01
*/
export class CalendarUtils {
  static readonly OLD_CALENDAR_END_YEAR: number = 1582;
  static isShowLunar: boolean = true;
  static isShowHoliday: boolean = true;
  static isFromMonthView: boolean = true;
  static chineseYear: string;
  private static readonly OLD_CALENDAR_END_MONTH: number = 10;
  private static readonly LOST_DAY_IN_1582: number = 10;
  private static readonly FEBRUARY: number = 2;
  private static readonly ONE_CENTURY: number = 100;
  private static readonly FOUR_CENTURY: number = 400;

  /**
   * 获取指定日期的周数，以year年1月4日所在周为第一周
   *
   * @param date 日期 月份以0开头 一月份为0 输入参数需要是当前周的最后一天
   * @param startOfWeek 一周开始日，若值为-1则默认为星期天开始 调整值为0
   * @return 返回当前日期的周数
   */
  static getWeekNumber(date: CalendarDate, startOfWeek: number): number {
    // 根据页面传入的一周开始日，获取实际的一周开始日
    const _startOfWeek = DateUtil.getStartOfWeek(startOfWeek);

    // 判断当前日期的1月4号 以1月4号所在周为 第一周
    let firstDay: CalendarDate = new CalendarDate();

    // 1月 1 2 3都以前一年的1月4号为准
    const firstDayDates: ReadonlyArray<number> = [1, 2, 3];
    if (firstDayDates.includes(date.getDate()) && date.getMonth() === 0) {
      firstDay = new CalendarDate(date.getFullYear() - 1, 0, 4);
    } else {
      firstDay = new CalendarDate(date.getFullYear(), 0, 4);
    }

    // 距离第一天共有多少天
    let days = Math.ceil((date.getTime() - firstDay.getTime()) / MILLS_PER_DAY);
    let d = days % DAY_PER_WEEK;
    let weekNumber: number = 1;

    // 判断起始日的一月四号当周还余多少天，剩余天数是否可以放到同一周
    if (firstDay.getDay() >= _startOfWeek) {
      if (d + firstDay.getDay() - _startOfWeek <= DAY_PER_WEEK) {
        // 与四号同一周
        weekNumber = Math.floor(days / DAY_PER_WEEK) + 1;
      } else {
        weekNumber = Math.floor(days / DAY_PER_WEEK) + 2;
      }
    } else {
      if (d <= _startOfWeek - firstDay.getDay()) {
        // 与四号同一周
        weekNumber = Math.floor(days / DAY_PER_WEEK) + 1;
      } else {
        weekNumber = Math.floor(days / DAY_PER_WEEK) + 2;
      }
    }
    return weekNumber;
  }

  /**
   * 获取指定日期的所在周的周数
   *
   * @param date 指定日期
   * @param startOfWeek 一周开始日，0标识周日 6标识周六
   * @returns
   */
  static getWeekNumberByI18n(date: CalendarDate, startOfWeek: number): number {
    const locale = I18nUtil.getSystemLocale();
    let calendar: i18n.Calendar = I18nUtil.getCalendar(locale);
    calendar.set(date.getFullYear(), date.getMonth(), date.getDate());
    calendar.setFirstDayOfWeek(startOfWeek + 1);
    return calendar.get("week_of_year");
  }

  /**
   * 获取指定日期的所在周的周数
   *
   * @param date 指定日期
   * @param startOfWeek 一周开始日，0标识周日 6标识周六
   * @returns
   */
  static getWeekNumberByDate(date: CalendarDate, startOfWeek: number): number {
    return CalendarUtils.getWeekNumber(CalendarUtils.getLastDayOfSameWeek(date, startOfWeek), startOfWeek);
  }

  /**
   * 获取指定日期的所在周的最后一天
   *
   * @param date 指定日期
   * @param startOfWeek 一周开始日，0标识周日 6标识周六
   * @returns
   */
  static getLastDayOfSameWeek(date: CalendarDate, startOfWeek: number): CalendarDate {
    const day: number = date.getDay();
    const gapDay: number = (6 + startOfWeek - day) % 7;
    return new CalendarDate(DateUtil.getStartMillsOfDate(date) + gapDay * MILLS_PER_DAY);
  }

  /**
   * 获取 当前输入日期 所在周的最后一天日期
   *
   * @param currentDate 基准年份周数信息，基于此信息进行偏移计算
   * @param startOfWeek 一周开始日，若值为-1则默认为星期天开始 调整值为0
   * @return currentDate 所在周的最后一天日期
   */
  static getLastDayOfWeekByCurrentDate(currentDate: CalendarDate, startOfWeek: number): CalendarDate {
    // 根据页面传入的一周开始日，获取实际的一周开始日
    const _startOfWeek = DateUtil.getStartOfWeek(startOfWeek);
    const dayOfCurrentDate = currentDate.getDay();
    const offset = _startOfWeek > dayOfCurrentDate ?
      ((_startOfWeek + 6) % 7 - dayOfCurrentDate) : (_startOfWeek + 6 - dayOfCurrentDate);
    return new CalendarDate(currentDate.getTime() + offset * MILLS_PER_DAY);
  }

  /**
   * 根据日期毫秒数判断十分同一天
   *
   * @param timeMillisFirst 第一个毫秒数
   * @param timeMillisSecond 第二个毫秒数
   * @return 返回是否同一天
   */
  public static isSameDay(timeMillisFirst: number, timeMillisSecond: number): boolean {
    let date1: CalendarDate = new CalendarDate(timeMillisFirst)
    let date2: CalendarDate = new CalendarDate(timeMillisSecond);
    return date1.getFullYear() === date2.getFullYear() && date1.getMonth() === date2.getMonth() && date1.getDate() === date2.getDate();
  }
}