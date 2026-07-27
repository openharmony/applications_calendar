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

import { SingleMonthViewModel, SingleMonthViewModelArray } from './SingleMonthViewModel';
import {
  DateManager,
  isChineseCalendar,
  Log,
  ServiceEnum,
  ServiceManager,
  SingleSwipeViewModel,
  YearData
} from '@app/common';
import { SwipeInfo } from '@app/common/src/main/ets/templates/SwipeDataSource';

const TAG: string = "[YearView][SigYearVM]";

/*
 * */
@Observed
export class SingleYearViewModelArray extends Array<SingleYearViewModel> {
}

// 年份数据
export class YearInfo extends SwipeInfo {
  public year : number = 0;
  public increase(): SwipeInfo {
    return new YearInfo(this.year + 1);
  }

  public decrease(): SwipeInfo {
    return new YearInfo(this.year - 1);
  }

  constructor(year : number) {
    super();
    this.year = year;
  }
}

@Observed
export class SingleYearViewModel extends SingleSwipeViewModel {
  public monthViewModels: SingleMonthViewModelArray = [];


  constructor(index: number, info : SwipeInfo) {
    super(index, info);
    this.monthViewModels = [];
    const subCalendar = AppStorage.get<number>(`subscriptionCalendar`);
    let showLunar: boolean = false;
    if (typeof subCalendar === 'number' && !isNaN(subCalendar)) {
      showLunar = isChineseCalendar(subCalendar);
    }
    const yearInfo = this.info as YearInfo;
    for (let month = 1; month <= YearData.MONTH_OF_YEAR; ++month) {
      this.monthViewModels.push(new SingleMonthViewModel(yearInfo.year, month, showLunar))
    }
  }

  public innerOnShowNext(info : SwipeInfo): void {
    const year = this.info as YearInfo;
    Log.info(TAG, `innerOnShowNext: ${year}`);
    this.monthViewModels.forEach((item) => {
      item.updateByYear(year.year);
    })
  }

  public innerOnShowPrevious(info : SwipeInfo): void {
    const year = this.info as YearInfo;
    Log.info(TAG, `innerOnShowPrevious: ${year}`);
    this.monthViewModels.forEach((item) => {
      item.updateByYear(year.year);
    })
  }

  public innerUpdate(info: SwipeInfo) {
    Log.info(TAG, `update index: ${this.index} year: ${(info as YearInfo).year}`);
    this.monthViewModels.forEach((item) => {
      item.updateByYear((info as YearInfo).year);
    })
  }

  onStartOfWeekChange(startOfWeek: number) {
    Log.info(TAG, "onStartOfWeekChange: " + startOfWeek);
    this.monthViewModels.forEach((item) => {
      item.onStartOfWeekChange(startOfWeek);
    })
  }

  onSubCalendarChange(showLunar: boolean) {
    Log.info(TAG, "onSubCalendarChange: " + showLunar);
    this.monthViewModels.forEach((item) => {
      item.onSubCalendarChange(showLunar);
    })
  }

  onWeekendsChange(weekends: number[]) {
    this.monthViewModels.forEach((item) => {
      item.onWeekendsChange(weekends);
    })
  }

  onLanguageChange(language: string) {
    this.monthViewModels.forEach((item) => {
      item.onLanguageChange(language);
    })
  }

  onSystemDateChange(): void {
    this.monthViewModels.forEach((item) => {
      item.onSystemDateChange();
    })
  };

  onSelectedDayChange() {
    this.monthViewModels.forEach((item) => {
      item.onSelectedDayChange();
    });
  }
}