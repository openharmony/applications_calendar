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

import { DateManager } from '../../date/DateManager';
import { DayData, MonthInfo, YearData } from '../../date/Date';
import { Log } from '../../default/common/Log';
import { CalendarDate } from '../../date/CalendarDate';

const TAG: string = '[MonthlyView][MonthlyInfo]';

/*
 * 单个月份的所有信息数据
 */
export class MonthlyInfo {
  // 一周开始日
  private startOfWeek: number = 0;
  // 基于 一周开始日 扩展的 当月展示日
  private displayDays: DayData[] = [];
  // 扩展月中，在上一个月的天数
  private daysInLastMonth: number = 0;
  // 扩展月中，在下一个月的天数
  private daysInNextMonth: number = 0;

  constructor(solarYear: number, solarMonth: number, startOfWeek: number = 0) {
    if (solarMonth < 1 || solarMonth > YearData.MONTH_OF_YEAR) {
      return;
    }
    this._solarYear = solarYear;
    this._solarMonth = solarMonth;
    this.setStartOfWeek(startOfWeek);
    this.buildDisplayDays();
  }

  // 年
  private _solarYear: number = 0;

  get solarYear(): number {
    return this._solarYear;
  }

  // 月份 (1-12)
  private _solarMonth: number = 0;

  get solarMonth(): number {
    return this._solarMonth;
  }

  getMouthInfo() {
    let yearData = DateManager.getInstance().getYearData(this.solarYear);
    if (yearData == undefined) {
      Log.error(TAG, 'YearData is undefined');
      return;
    }
    let mouthInfo = yearData.getMonthInfo(this.solarMonth);
    if (mouthInfo == undefined) {
      Log.error(TAG, 'MouthInfo is Undefined');
      return;
    }
    return mouthInfo;
  }

  getDaysInfo(): DayData[] {
    let mouthInfo = this.getMouthInfo() as MonthInfo;
    if (mouthInfo == undefined) {
      Log.error(TAG, 'MouthInfo is Undefined In getDaysInfo');
      return [];
    }
    return mouthInfo?.getDaysInfo();
  }

  getNext(): MonthlyInfo {
    if (this.solarMonth == YearData.MONTH_OF_YEAR) {
      return new MonthlyInfo(this.solarYear + 1, 1, this.startOfWeek);
    }
    return new MonthlyInfo(this.solarYear, this.solarMonth + 1, this.startOfWeek);
  }

  getLast(): MonthlyInfo {
    if (this.solarMonth === 1) {
      return new MonthlyInfo(this.solarYear - 1, YearData.MONTH_OF_YEAR, this.startOfWeek);
    } else {
      return new MonthlyInfo(this.solarYear, this.solarMonth - 1, this.startOfWeek);
    }
  }

  getDisplayDays(): DayData[] {
    if (this.displayDays !== null && this.displayDays !== undefined) {
      return this.displayDays;
    }
    this.buildDisplayDays();
    return this.displayDays;
  }

  getStartOfWeek(): number {
    return this.startOfWeek;
  }

  setStartOfWeek(startOfWeek: number): void {
    this.startOfWeek = startOfWeek >= 0 ? startOfWeek : 0;
  }

  toString(): string {
    return 'Monthly Info year = ' + this.solarYear + ', month = ' + this.solarMonth + ', startOfWeek = ' + this.startOfWeek;
  }

  private buildDisplayDays(): void {
    this.getPreviousDays();
    this.getCurrentDays();
    this.getFollowingDays();
  }

  private getPreviousDays(): void {
    this.setDaysInLastMonth();
    let mouthInfo = this.getMouthInfo() as MonthInfo;
    const lastMonthDays: DayData[] | undefined = mouthInfo?.getLast()?.getDaysInfo();
    if (lastMonthDays === null || lastMonthDays === undefined) {
      Log.error(TAG, 'NO VALID LAST MONTH DAYS');
      return;
    }
    if (this.daysInLastMonth === 0) {
      return;
    }
    // 天数 x 不为0，则截取上一个月的倒数 x 天
    this.buildDaysArr(lastMonthDays.slice(-this.daysInLastMonth));
  }

  // 计算当前展示月份在上一个的天数
  private setDaysInLastMonth(): void {
    const curDays: DayData[] = this.getDaysInfo();
    const firstDayWeek = curDays[0]?.getWeekDay() || 0;
    if (firstDayWeek >= this.startOfWeek) {
      this.daysInLastMonth = firstDayWeek - this.startOfWeek;
    } else {
      this.daysInLastMonth = 7 - (this.startOfWeek - firstDayWeek);
    }
  }

  private getCurrentDays(): void {
    const curDays: DayData[] = this.getDaysInfo();
    this.buildDaysArr(curDays);
  }

  // 计算当前展示月份在下一个月的天数
  private setDaysInNextMonth(): void {
    const curDays: DayData[] = this.getDaysInfo();
    const lastDayWeek = curDays[curDays.length - 1]?.getWeekDay() || 0;
    if (lastDayWeek < this.startOfWeek) {
      this.daysInNextMonth = this.startOfWeek - lastDayWeek - 1;
    } else {
      this.daysInNextMonth = 6 - (lastDayWeek - this.startOfWeek);
    }
  }

  private getFollowingDays(): void {
    this.setDaysInNextMonth();
    let mouthInfo = this.getMouthInfo() as MonthInfo;
    const nextMonthDays: DayData[] | undefined = mouthInfo?.getNext()?.getDaysInfo();
    if (nextMonthDays === null || nextMonthDays === undefined) {
      Log.error(TAG, 'NO NEXT VALID DAYS');
      return;
    }
    this.buildDaysArr(nextMonthDays.slice(0, this.daysInNextMonth));
  }

  private buildDaysArr(daysArr: DayData[]): void {
    if (daysArr === null || daysArr === undefined) {
      Log.error(TAG, 'NO VALID DAYS');
      return;
    }
    daysArr.forEach((dayData: DayData) => {
      if (this.displayDays !== null && this.displayDays !== undefined) {
        this.displayDays.push(dayData);
      }
    });
  }
}

/**
 * 用于标识当前日期的接口，公历月份month:（1-12）day:(1-31)
 */
export class DateInfo {
  public year: number;
  public month: number;
  public weekNum: number;
  public day: number;

  constructor(year?: number, month?: number, weekNum?: number, day?: number) {
    this.year = year as number;
    this.month = month as number;
    this.weekNum = weekNum as number;
    this.day = day as number;
  }

  getDate(): CalendarDate {
    return (this.day === null || this.day === undefined) ? new CalendarDate(this.year, this.month - 1, 1) :
      new CalendarDate(this.year, this.month - 1, this.day);
  }

  toString(): string {
    return 'DateInfo year = ' + this.year + ', month = ' + this.month +
      ', weekNum = ' + this.weekNum + ', day = ' + this.day;
  }
}
