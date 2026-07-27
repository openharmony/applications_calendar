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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { DAY_PER_WEEK } from '@app/common/src/main/ets/util/DateUtil';
import { CardType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DateManager, DayData, DayMark, MonthInfo } from '@app/common';

const TAG: string = "Form - CardFormMonthViewModel";

/**
 * 卡片表单月视图  -- 因表单目前不支持引用,后支持的话重构删除此类。
 */
export class CardFormMonthViewModel {
  public monthViewModel: SingleMonthViewModel | null = null;

  constructor(time: CalendarDate) {
    this.monthViewModel = new SingleMonthViewModel(time.getFullYear(), time.getMonth() + 1);
  }
}

// 卡片类型映射
export const cardTypes: Map<string, number> = new Map([
  ['AgendaCard2x2', CardType.AGENDA_CARD_2X2],
  ['AgendaCard2x4', CardType.AGENDA_CARD_2X4],
  ['AgendaCard4x4', CardType.AGENDA_CARD_4X4],
  ['AgendaCard4x6', CardType.AGENDA_CARD_4X6],
  ['ImportantCard2x2', CardType.IMPORTANT_CARD_2X2],
  ['ImportantCard2x4', CardType.IMPORTANT_CARD_2X4],
  ['MonthCard2x2', CardType.MONTH_CARD_2X2],
  ['MonthCard4x4', CardType.MONTH_CARD_4X4],
]);

// 月  -- 模型
export class SingleMonthViewModel {
  static readonly dayItemCount: number = 6 * 7; // max number of day show items
  readonly month: number;
  year: number;
  dayViewModels: SingleDayViewModelArray = new SingleDayViewModelArray;
  showRecessData: boolean = false;
  showLunarInfo: boolean = true;
  monthInfo: MonthInfo | undefined = undefined;
  monthTitle: string = '';
  startOfWeek: number = 0;
  weekends: number[] = [-1, 0, 6];
  hasDisplayDay: boolean = false;

  constructor(year: number, month: number) {
    this.month = month;
    this.year = year;

    this.monthInfo = DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month);

    if (!this.monthInfo) {
      Log.error(TAG, `getMonthInfo failed ${this.year}:${this.month}`);
      return;
    }
    this.dayViewModels = new SingleDayViewModelArray();
    for (let index = 0; index < SingleMonthViewModel.dayItemCount; ++index) {
      this.dayViewModels.push(new SingleDayViewModel())
    }
    this.showLunarInfo = true;
    this.updateShowDaysInfo();
    this.onSelectedDateChange();
  }

  // 响应选中日期变化
  public onSelectedDateChange() {
    const selectDay = DateManager.getInstance().selectedDay;
    // 月标题的颜色需要感知年份变化
    this.dayViewModels?.forEach((item) => {
      if ((item.day === selectDay.solarDay) && (selectDay.solarMonth === this.month)) {
        Log.info(TAG, `enable select ${this.year}:${this.month}:${item.day}`);
        item.isSelect = true;
      } else {
        item.isSelect = false;
      }
    })
    this.hasDisplayDay = (selectDay.solarMonth === this.month && selectDay.solarYear === this.year);
  }

  private updateShowDaysInfo() {
    if ((this.startOfWeek < 0) || (this.startOfWeek > 7)) {
      Log.error(TAG, "startOfWeek invalid y:" + this.startOfWeek);
      return;
    }
    // check first day's week
    const days = this.monthInfo?.getDaysInfo();
    if (!days || (days.length === 0)) {
      Log.error(TAG, "updateShowDaysInfo failed y:" + this.year + 'm:' + this.month);
      return;
    }
    const firstDayWeek = days[0].getWeekDay();
    // case 1 : firstDayWeek is 0 and startOfWeek is 1; need 6 space
    // case 2 : firstDayWeek is 1 and startOfWeek is 0; need 1 space
    let space: number = 0;
    if (firstDayWeek >= this.startOfWeek) {
      space = firstDayWeek - this.startOfWeek;
    } else {
      space = DAY_PER_WEEK - this.startOfWeek + firstDayWeek;
    }

    if (!this.dayViewModels) {
      return;
    }
    for (let index = 0; index < space; ++index) {
      this.dayViewModels[index].update();
    }
    // insert cur month info
    days.forEach((element, index) => {
      this.dayViewModels[space + index].update(element, false, this.showLunarInfo, this.weekends);
    });
    for (let index = space + days.length; index < SingleMonthViewModel.dayItemCount; ++index) {
      this.dayViewModels[index].update();
    }
  }
}

// 天 -- 模型
export class SingleDayViewModel {
  day: number = -1;
  isToday: boolean = false;
  isSelect: boolean = false;
  lunarLineWidth: number = 0;
  textColor: string = '#000000';
  isOffDay: boolean = false; // 是周末休息或者法定节假日
  isTodayMonth: boolean = true;

  constructor() {
    this.isSelect = false;
  }

  update(data?: DayData, showRecess: boolean = false, showLunar: boolean = true, weekends: number[] = []): void {
    if (!data) {
      this.day = -1;
      this.isToday = false;
      this.isSelect = false;
      this.lunarLineWidth = 0;
      return;
    }
    this.isSelect = false;
    this.day = data.solarDay;
    if (showLunar && (data.lunarDay === 1)) {
      if (data.lunaMonth === 1) {
        this.lunarLineWidth = 1;
      } else {
        this.lunarLineWidth = 0.5;
      }
    } else {
      this.lunarLineWidth = 0;
    }

    this.isToday = data.isToday;
    const weekDay = data.getWeekDay();
    if (weekends.indexOf(weekDay) !== -1) {
      this.isOffDay = true;
    } else {
      this.isOffDay = false;
    }
  }
}

export class SingleDayViewModelArray extends Array<SingleDayViewModel> {
}