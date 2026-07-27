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

import { CalendarDate, DateManager, DayData, Log, ServiceEnum, ServiceManager } from '@app/common';
import { SingleMonthViewModel, SingleMonthViewModelArray } from './SingleMonthViewModel';

const TAG: string = "[Sidebar][MonthVM]";

@Observed
export class SideBarMonthViewModel {
  readonly MAX_YEAR: number = 5000;
  readonly MIN_YEAR: number = 1;
  singleMonthVMs: SingleMonthViewModelArray = new SingleMonthViewModelArray();

  public constructor(displayDate: CalendarDate) {
    Log.info(TAG, "constructor:" + displayDate.toLocaleDateString());
    this._curDisplayDay = DayData.buildByDate(displayDate);
    this.init();
  }

  private _curDisplayDay: DayData;

  get curDisplayDay(): DayData {
    return this._curDisplayDay;
  }

  set curDisplayDay(data: DayData) {
    Log.info(TAG, `set curDisplayDay: ${data.solarMonth} ${data.solarDay}`);
    this._curDisplayDay = data;
  }

  init() {
    const subCalendar = AppStorage.get<number>(`subscriptionCalendar`);
    this.singleMonthVMs = new SingleMonthViewModelArray();
    //月份12循环
    if (this.curDisplayDay.solarMonth == 1) {
      this.singleMonthVMs.push(new SingleMonthViewModel(this.curDisplayDay.solarYear - 1, 12));
    } else {
      this.singleMonthVMs.push(new SingleMonthViewModel(this.curDisplayDay.solarYear, this.curDisplayDay.solarMonth - 1));
    }

    this.singleMonthVMs.push(new SingleMonthViewModel(this.curDisplayDay.solarYear, this.curDisplayDay.solarMonth));

    if (this.curDisplayDay.solarMonth == 12) {
      this.singleMonthVMs.push(new SingleMonthViewModel(this.curDisplayDay.solarYear + 1, 1));
    } else {
      this.singleMonthVMs.push(new SingleMonthViewModel(this.curDisplayDay.solarYear, this.curDisplayDay.solarMonth + 1));
    }
    Log.log(TAG, "init sideBarMonthVMs = " + this.singleMonthVMs[0].month + this.singleMonthVMs[1].month + this.singleMonthVMs[2].month);
  }

  public updateByYearMonth(newDisplayYear: number, newDisplayMonth: number) {
    this.singleMonthVMs[0].updateByYearMonth(newDisplayYear, newDisplayMonth - 1);
    this.singleMonthVMs[1].updateByYearMonth(newDisplayYear, newDisplayMonth);
    this.singleMonthVMs[2].updateByYearMonth(newDisplayYear, newDisplayMonth + 1);
    Log.log(TAG, `updateByYear singleMonthVMs curDisplayDay: ${this.curDisplayDay}`);
  }

  /*
  return swiper index
   */
  updateBySelectedDate(): number {
    let selectDay = DateManager.getInstance().selectedDay;
    Log.info(TAG, "updateBySelectedDate: " + selectDay);
    const newYear = selectDay.solarYear;
    const newMonth = selectDay.solarMonth;
    this.curDisplayDay.solarYear = newYear; // 不能直接赋值selectedDay, 否则是引用
    this.curDisplayDay.solarMonth = newMonth;
    this.curDisplayDay.solarDay = selectDay.solarDay;
    // 如果显示的日期对应的年份不在缓存中, 进行全量刷新
    const index = this.isNeedReInit(newYear, newMonth);
    if (index === -1) {
      Log.info(TAG, "full reInit: " + newYear + newMonth);
      this.updateByYearMonth(newYear, newMonth);
      return 1; // center index
    }
    // 在缓存里面, 可能月份发生变化, 每个视图都需要对应变化
    this.singleMonthVMs.forEach((item) => {
      item.onSelectedDateChange();
    })
    return index;
  }

  updateBySwipe(lastIndex: number, index: number): void {
    if (lastIndex < 0 || lastIndex >= this.singleMonthVMs.length || index < 0 || index >= this.singleMonthVMs.length) {
      Log.error(TAG, `invalid lastIndex : ${lastIndex}, index : ${index}`);
      return;
    }
    let curYear = this.singleMonthVMs[index].year;
    let curMonth = this.singleMonthVMs[index].month;
    // 到达缓冲区右侧边界,需要更新数据源,为后续滑动准备好数据
    if (index === this.singleMonthVMs.length - 1) {
      // 继续往右侧滑动index会重置为0
      if (lastIndex === 0) {
        // from 0 to 2
        this.singleMonthVMs[index - 1].updateByYearMonth(curYear, curMonth - 1);
      } else {
        // from 1 to 2
        this.singleMonthVMs[0].updateByYearMonth(curYear, curMonth + 1);
      }
    } else if (index === 0) {
      if (lastIndex === this.singleMonthVMs.length - 1) {
        // from 2 to 0
        this.singleMonthVMs[index + 1].updateByYearMonth(curYear, curMonth + 1);
      } else {
        // from 1 to 0
        this.singleMonthVMs[this.singleMonthVMs.length - 1].updateByYearMonth(curYear, curMonth - 1);
      }
    } else {
      // 在区间中滑动, 只需要更新滑动方向上的下一个数据即可
      if (index > lastIndex) {
        // from 0 to 1
        this.singleMonthVMs[index + 1].updateByYearMonth(curYear, curMonth + 1);
      } else {
        // from 2 to 1
        this.singleMonthVMs[index - 1].updateByYearMonth(curYear, curMonth - 1);
      }
    }
    this.curDisplayDay.solarYear = this.singleMonthVMs[index].year;
    this.curDisplayDay.solarMonth = this.singleMonthVMs[index].month;
    Log.log(TAG, `updateBySwipe singleMonthVMs curDisplayDay: ${this.curDisplayDay}`);
  }

  onStartOfWeekChange(startOfWeek: number) {
    Log.info(TAG, "onStartOfWeekChange: " + startOfWeek);
    this.singleMonthVMs.forEach((item) => {
      item.onStartOfWeekChange(startOfWeek);
    })
  }

  onLanguageChange(language: string) {
    this.singleMonthVMs.forEach((item) => {
      item.onLanguageChange(language);
    })
  }

  private isNeedReInit(newYear: number, newMonth: number): number {
    Log.debug(TAG, `isNeedReInit sideBarMonthVMs newYearMonth: ${newYear} + ${newMonth}`);
    for (let index = 0; index < this.singleMonthVMs.length; ++index) {
      if (this.singleMonthVMs[index].year === newYear && this.singleMonthVMs[index].month === newMonth) {
        return index;
      }
    }
    return -1;
  }
}
