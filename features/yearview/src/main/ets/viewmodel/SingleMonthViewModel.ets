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
  CalendarDate,
  DateManager, DateUtil, DAY_PER_WEEK, GlobalData, GlobalDataKeys, Log, MonthInfo,
  NumberFormatManager,
  TextParagraphManager} from '@app/common';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { TitleModel } from '../model/TitleModel';
import { MonthPaint } from './MonthPaint';

const TAG: string = "[YearView][SigMonthVM]";

@Observed
export class SingleMonthViewModelArray extends Array<SingleMonthViewModel> {
}

@Observed
export class SingleMonthViewModel {
  readonly month: number;
  year: number;
  dayItemSpace: number = 0; // 需要占位的Item数量
  showLunarInfo: boolean = true;
  monthInfo: MonthInfo | undefined = undefined;
  monthTitle: string = '';
  startOfWeek: number = 0;
  public weekTitles: string[] = [];
  public weekCompIds: string[] = [];
  weekends: number[] = [];
  hasDisplayDay: boolean = false;
  public darkMode: boolean = false;
  public monthPaint: MonthPaint = new MonthPaint();

  constructor(year: number, month: number, showLunarInfo: boolean = true) {
    this.month = month;
    this.year = year;
    const startOfWeek = (GlobalData.instance().get(GlobalDataKeys.START_OF_WEEK) || -1) as number;
    this.startOfWeek = DateUtil.getStartOfWeek(startOfWeek);
    this.weekTitles = TitleModel.instance().getWeekTitles();
    this.weekCompIds = TitleModel.instance().getWeekCompIds();
    this.monthInfo = DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month);
    this.darkMode = GlobalData.instance().get(GlobalDataKeys.IS_DARKMODE) as boolean;
    if (!this.monthInfo) {
      Log.error(TAG, `getMonthInfo failed ${this.year}:${this.month}`);
      return;
    }

    PaletteCache.instance().setDarkMode(this.darkMode);
    this.monthPaint.bindViewModel(this);
    this.showLunarInfo = showLunarInfo;
    this.weekends = GlobalData.instance().get(GlobalDataKeys.WEEKENDS) as number[];
    this.monthTitle = TitleModel.instance().getMonthTitle(this.month - 1);
    this.updateShowDaysInfo();

    const today = DateManager.getInstance().today;
    this.hasDisplayDay = (today.solarMonth === this.month && today.solarYear === this.year);
  }

  public onStartOfWeekChange(startOfWeek: number) {
    Log.debug(TAG, `${this.year}:${this.month} onStartOfWeekChange: ${this.startOfWeek} => ${startOfWeek}`);
    if (this.startOfWeek == startOfWeek) {
      return;
    }

    this.startOfWeek = startOfWeek;
    this.weekTitles = TitleModel.instance().getWeekTitles();
    this.weekCompIds = TitleModel.instance().getWeekCompIds();
    this.updateShowDaysInfo();
  }

  public updateByYear(newYear: number) {
    if (this.year != newYear) {
      Log.info(TAG, `month ${this.month} update form ${this.year} to ${newYear}`);
      this.year = newYear;
      this.monthInfo = DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month);
      this.updateShowDaysInfo();
      const today = DateManager.getInstance().today;
      this.hasDisplayDay = (today.solarMonth === this.month && today.solarYear === this.year);
    }
  }

  public updateShowDaysInfo() {
    if (this.startOfWeek < 0 || this.startOfWeek > DAY_PER_WEEK) {
      Log.error(TAG, "startOfWeek invalid y:" + this.startOfWeek);
      return;
    }
    // check first day's week
    const days = this.monthInfo?.getDaysInfo();
    if (!days || days.length === 0) {
      Log.error(TAG, "updateShowDaysInfo failed y:" + this.year + 'm:' + this.month);
      return;
    }
    const firstDayWeek = days[0].getWeekDay();
    // case 1 : firstDayWeek is 0 and startOfWeek is 1; need 6 space
    // case 2 : firstDayWeek is 1 and startOfWeek is 0; need 1 space
    if (firstDayWeek >= this.startOfWeek) {
      this.dayItemSpace = firstDayWeek - this.startOfWeek;
    } else {
      this.dayItemSpace = DAY_PER_WEEK - this.startOfWeek + firstDayWeek;
    }
    this.monthPaint.invalidate();
  }

  onSubCalendarChange(showLunar: boolean) {
    this.showLunarInfo = showLunar;
    this.updateShowDaysInfo();
  }

  onWeekendsChange(weekends: number[]) {
    this.weekends = weekends;
    this.updateShowDaysInfo();
  }

  onLanguageChange(language: string) {
    this.weekTitles = TitleModel.instance().getWeekTitles();
    this.monthTitle = TitleModel.instance().getMonthTitle(this.month - 1);

    // 语言切换强制刷新dataFormat
    NumberFormatManager.instance().onLanguageChange(language);
    TextParagraphManager.instance().onLanguageChange(language);
    // 处理镜像语言，VM按周翻转
    this.monthPaint.onLanguageChange(language);
    this.monthPaint.invalidate();
  }

  // 12.31-->1.1
  // 1.31-->2.1
  onSystemDateChange(): void {
    // 系统日期变化,直接遍历刷新,后期可以根据月份进行过滤
    const today = DateManager.getInstance().today;
    Log.info(TAG, `onSystemDateChange ${this.year}:${this.month}`);

    this.hasDisplayDay = (today.solarMonth === this.month && today.solarYear === this.year);
    this.updateShowDaysInfo();
  }

  onDarkModeChange(isDarkMode: boolean): void {
    PaletteCache.instance().setDarkMode(isDarkMode);
    // drawModifier绘制错误临时方案,深色模式切换一定概率会刷新失败,添加延时保障再次刷新成功
    const timeOut = setTimeout(() => {
      this.monthPaint.invalidate();
      clearTimeout(timeOut);
    }, 50);
  }

  onSelectedDayChange() {
    this.monthPaint.invalidate();
  }

  getYearMonth(): string {
    let date = new CalendarDate();
    date.setFullYear(this.year, this.month - 1);
    let option: Record<string, string> = { 'year': 'numeric', 'month': 'long' }
    return DateUtil.intlDateFormat(date, option)
  }

  getUpdatePropStr(): string {
    const year = this.year;
    const month = this.month;
    const hasDisplayDay = this.hasDisplayDay;
    return `${year}-${month}-${hasDisplayDay}`;
  }
}
