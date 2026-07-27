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

import { DayMark } from '../constants/Constants';
import { DateUtil, DAY_PER_WEEK, MILLS_PER_MINUTE } from '../util/DateUtil';
import { CalendarDate } from './CalendarDate';
import { DateManager } from './DateManager';
import { FestivalDay } from './FestivalData';

/*
 * 单年信息数据
 * */
export class YearData {
  public static readonly MONTH_OF_YEAR: number = 12;
  private _lunaYear: string = '';
  private months: MonthInfo[] = [];

  constructor(solarYear: number) {
    this._solarYear = solarYear;
    this.months = new Array(YearData.MONTH_OF_YEAR);
    for (let i = 1; i <= YearData.MONTH_OF_YEAR; ++i) {
      this.months[i - 1] = new MonthInfo(this.solarYear, i);
    }
  }

  private _isRecessLoad: boolean = false;

  public set isRecessLoad(value: boolean) {
    this._isRecessLoad = value;
  }

  public get isRecessLoad(): boolean {
    return this._isRecessLoad;
  }

  // 公历年份
  private _solarYear: number;

  public get solarYear() {
    return this._solarYear;
  }

  public get lunarYear() {
    return this._lunaYear;
  }

  public set lunarYear(lunarYear: string) {
    this._lunaYear = lunarYear;
  }

  getAllMonthInfo(): MonthInfo[] {
    return this.months;
  }

  getMonthInfo(solarMonth: number): MonthInfo | undefined {
    if (solarMonth < 1 || solarMonth > YearData.MONTH_OF_YEAR) {
      return undefined;
    }
    return this.months[solarMonth - 1];
  }
}

const LUNAR_CHINESE_TEXT: string = '农历';

export {
  LUNAR_CHINESE_TEXT
}

/*
 * 单月信息数据
 * */
export class MonthInfo {
  // 阳历月份
  private month: number;
  private year: number;
  private date: CalendarDate;
  private days: DayData[] = []

  constructor(solarYear: number, solarMonth: number) {
    this.month = solarMonth;
    this.year = solarYear;
    // Init with real month number
    this.date = new CalendarDate(solarYear, solarMonth, 0);
    this.getDaysInfo();
  }

  getNext(): MonthInfo | undefined {
    if (this.month == YearData.MONTH_OF_YEAR) {
      return DateManager.getInstance().getYearData(this.year + 1)?.getMonthInfo(1);
    }
    return DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month + 1);
  }

  getLast(): MonthInfo | undefined {
    if (this.month === 1) {
      return DateManager.getInstance().getYearData(this.year - 1)?.getMonthInfo(YearData.MONTH_OF_YEAR);
    } else {
      return DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month - 1);
    }
  }

  getDaysInfo(): DayData[] {
    if (this.days.length != 0) {
      return this.days;
    }
    this.days = [];
    let dayNum = this.date.getDate();

    for (let i = 1; i <= dayNum; ++i) {
      // 针对1582年10月消失的10天做的特殊处理,将这10天跳过
      if (this.year === 1582 && this.month === 10 && (i >= 5 && i < 15)) {
        continue;
      }
      this.days.push(new DayData(this.year, this.month, i))
    }
    return this.days;
  }

  getDayData(day: number): DayData | undefined {
    // 1582年10月4-14号为消失的10天,故取索引时需要减去这10天
    const index = this.year === 1582 && this.month === 10 && day >= 15 ? day - 10 : day;
    if (index <= 0 || index > this.days.length) {
      return undefined;
    }
    return this.days[index - 1];
  }

  getSolarYear(): number {
    return this.year;
  }

  getMonth(): number {
    return this.month;
  }

  // 根据一周起始日获取按周分割的日期信息, 不包含前后月份数据
  public getWeeks(startOfWeek: number = 0, supportLockTimeZone: boolean = true): DayData[][] {
    let weeks: DayData[][] = [];
    let week: DayData[] = [];
    for (let i = 0; i < this.days.length; ++i) {
      if (this.days[i].getWeekDay(supportLockTimeZone) === startOfWeek) {
        if (week.length !== 0) {
          weeks.push(week);
        }
        week = [];
      }
      week.push(this.days[i]);
      if (i === this.days.length - 1) {
        weeks.push(week);
      }
    }
    return weeks;
  }

  // 根据一周起始日获取按周分割的日期信息 包括上个月或者下个月的数据
  public getFullWeeks(startOfWeek: number = 0, supportLockTimeZone: boolean = true): DayData[][] {
    let weeks: DayData[][] = this.getWeeks(startOfWeek, supportLockTimeZone);
    let lastMonthInfo: MonthInfo | undefined = this.getLast();
    let nextMonthInfo: MonthInfo | undefined = this.getNext();
    let lastMonthDays: DayData[] = lastMonthInfo?.getDaysInfo() ?? [];
    let nextMonthDays: DayData[] = nextMonthInfo?.getDaysInfo() ?? [];
    // 补充前一个月数据
    let dayItemSpace = 0;
    const firstDayWeek = this.days[0].getWeekDay(supportLockTimeZone);
    if (firstDayWeek >= startOfWeek) {
      dayItemSpace = firstDayWeek - startOfWeek;
    } else {
      dayItemSpace = DAY_PER_WEEK + firstDayWeek - startOfWeek;
    }
    if (dayItemSpace !== 0) {
      weeks[0] = lastMonthDays.slice(-dayItemSpace).concat(weeks[0]);
    }
    // 补充后一个月数据
    const lastDayWeek = nextMonthDays[0].getWeekDay(supportLockTimeZone);
    if (lastDayWeek > startOfWeek) {
      dayItemSpace = DAY_PER_WEEK - lastDayWeek + startOfWeek;
    } else {
      dayItemSpace = startOfWeek - lastDayWeek;
    }
    weeks[weeks.length - 1] = weeks[weeks.length - 1].concat(
      nextMonthDays.slice(0, dayItemSpace));
    return weeks;
  }
}

/*
 * 单周信息数据,此数据不固定，受一周起始日变化而变化,因此无法进行
 * */
export class WeekData {
  public days: DayData[] = [];
  public solarYear: number = -1;
  public solarMonth: number = -1;

  // 使用本地时间初始化
  constructor(solarYear: number, solarMonth: number, solarDay: number) {
    this.solarYear = solarYear
    this.solarMonth = solarMonth;
  }
}

/*
 * 单天信息数据
 * */
export class DayData {
  public dayMarkValue: string = '';
  public isToday: boolean = false;
  // 节日 暂时用数组，待后期分类标准化之后切换为map
  public festivals: FestivalDay[] = []; // 节假日信息，包括节气
  // 星期
  private _lunaDay: number = -1; // 农历索引
  public festivalName?: string = ''; // 月周日视图节假日信息，包括节气

  // 使用本地时间初始化
  constructor(solarYear: number, solarMonth: number, solarDay: number) {
    this._solarYear = solarYear;
    this._solarMonth = solarMonth;
    this._solarDay = solarDay;
  }

  private _isSelected?: boolean;

  public get isSelected(): boolean {
    return this._isSelected ? this._isSelected : false;
  }

  public set isSelected(isSelected: boolean) {
    this._isSelected = isSelected;
  }

  // 公历天
  private _solarYear: number;

  public get solarYear() {
    return this._solarYear
  }

  public set solarYear(solarYear: number) {
    this._solarYear = solarYear;
  }

  private _solarMonth: number;

  public get solarMonth() {
    return this._solarMonth
  }

  public set solarMonth(solarMonth: number) {
    this._solarMonth = solarMonth;
  }

  private _solarDay: number;

  public get solarDay() {
    return this._solarDay
  }

  public set solarDay(solarDay: number) {
    this._solarDay = solarDay;
  }

  public _dayMark: DayMark = DayMark.NORMAL;

  public get dayMark() {
    return this._dayMark;
  }

  public set dayMark(dayMark: DayMark) {
    this._dayMark = dayMark;
  }

  public get lunarDay() {
    return this._lunaDay;
  }

  public set lunarDay(lunarDay: number) {
    this._lunaDay = lunarDay;
  }

  private _lunaMonth: number = -1; // 农历索引

  public get lunaMonth() {
    return this._lunaMonth;
  }

  public set lunaMonth(lunaMonth: number) {
    this._lunaMonth = lunaMonth;
  }

  static buildByDate(date: CalendarDate | Date): DayData {
    const dayData = new DayData(date.getFullYear(), date.getMonth() + 1, date.getDate());
    return dayData;
  }

  getDate(): CalendarDate {
    return new CalendarDate(this._solarYear, this._solarMonth - 1, this._solarDay);
  }

  /**
   * 获取系统时区的日期对象
   *
   * @returns 系统时区日期对象
   */
  getOriDate(): Date {
    return new Date(this._solarYear, this._solarMonth - 1, this._solarDay);
  }

  /**
   * 根据系统时区的日期，将年月日转化为时间戳
   * @returns
   */
  getTimeStamp(): number {
    return DateUtil.dateToStamp(this._solarYear, this._solarMonth - 1, this._solarDay);
  }


  isValid(): boolean {
    return this._solarYear >= 1 &&
      (this._solarMonth >= 1 && this._solarMonth <= YearData.MONTH_OF_YEAR) &&
      this._solarDay >= 1;
  }

  getWeekDay(supportLockTimeZone: boolean = true) {
    if (supportLockTimeZone) {
      return DateUtil.getLockTimeZoneDate(this.getTimeStamp()).getDay();
    }
    return new Date(this._solarYear, this._solarMonth - 1, this._solarDay).getDay();
  }

  toString(): string {
    return this.toSolarString() + ` ${LUNAR_CHINESE_TEXT}:${this._lunaMonth}.${this._lunaDay}`;
  }

  toSolarString(): string {
    return `${this._solarYear}.${this._solarMonth}.${this._solarDay}`;
  }

  // 获取单天信息的无障碍播报内容
  getAccessibilityDateText() {
    const dateText = DateUtil.getDateText(this.getDate());
    return dateText;
  }
}