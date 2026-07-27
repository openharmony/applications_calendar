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

import { CalendarDate, CalendarUtils, DayData, Log, MonthlyInfo } from '@app/common';

const TAG: string = '[MonthlyView][WeekNumVM]';

@Observed
export class WeekNumViewModel {
  private _monthlyInfo: MonthlyInfo | undefined;

  constructor(startOfWeek: number = 0, monthlyInfo?: MonthlyInfo) {
    this._startOfWeek = startOfWeek;
    if (!monthlyInfo) {
      Log.error(TAG, 'MonthlyInfo is NULL!');
      return;
    }
    this._monthlyInfo = monthlyInfo;
    this.updateWeekNumbers();
  }

  private _startOfWeek: number = -1;

  get startOfWeek(): number {
    return this._startOfWeek;
  }

  set startOfWeek(startOfWeek: number) {
    if (startOfWeek < 0 || startOfWeek > 7) {
      Log.error(TAG, `startOfWeek out range:${startOfWeek}`);
      return;
    }
    this._startOfWeek = startOfWeek;
    this.updateWeekNumbers();
  }

  public weekNumbers: number[] = [];

  private _showNumber: number = 0; // 当前显示周

  get showNumber(): number {
    return this._showNumber;
  }

  set showNumber(showNumber: number) {
    this._showNumber = showNumber;
  }

  updateWeekNumbers() {
    // 根据每周的最后一天 计算周数 更新周数信息
    const displayDays: DayData[] = this._monthlyInfo?.getDisplayDays() as DayData[];
    this.weekNumbers = new Array<number>(Math.floor(displayDays?.length / 7)).fill(0);
    for (let index = 0; index < this.weekNumbers.length; index++) {
      const lastDayDate: CalendarDate = displayDays[7 * index + 6].getDate();
      this.weekNumbers[index] = CalendarUtils.getWeekNumber(lastDayDate, this.startOfWeek);
    }
  }
}
