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

import { DayData } from '@app/common';

const TAG: string = "[SideBar][SigDayVM]";

@Observed
export class SingleDayViewModelArray extends Array<SingleDayViewModel> {
}

@Observed
export class SingleDayViewModel {
  day: number = -1;
  month: number = -1;
  year: number = -1;
  isToday: boolean = false;
  isSelect: boolean = false;
  lunarLineWidth: number = 0;
  textColor: string = '#000000';
  isOffDay: boolean = false; // 是周末休息或者法定节假日
  isNowMonth: boolean = true; //是否为本月数据
  opacity: number = 0.9;

  constructor() {
    this.isSelect = false;
  }

  update(data?: DayData, showRecess: boolean = false, showLunar: boolean = true, weekends: number[] = [], isNowMonth: boolean = true): void {
    if (!data) {
      this.day = -1;
      this.isToday = false;
      this.isSelect = false;
      this.lunarLineWidth = 0;
      return;
    }
    this.isSelect = false;
    this.isNowMonth = isNowMonth;
    this.day = data.solarDay;
    this.month = data.solarMonth;
    this.year = data.solarYear;
    if (showLunar && data.lunarDay === 1) {
      if (data.lunaMonth === 1) {
        this.lunarLineWidth = 1;
      } else {
        this.lunarLineWidth = 0.5;
      }
    } else {
      this.lunarLineWidth = 0;
    }
    this.isToday = data.isToday;
    this.textColor = this.isToday ? '#FFFFFF' : '#000000';
    const weekDay = data.getWeekDay();
    if (weekends.indexOf(weekDay) !== -1) {
      this.isOffDay = true;
      this.opacity = 0.4;
    } else {
      this.isOffDay = false;
      this.opacity = 0.9;
    }
    if (!this.isNowMonth) {
      this.isOffDay = true;
      this.opacity = 0.16;
    }
  }

  updateToday(isToday: boolean) {
    this.isToday = isToday;
    this.textColor = this.isToday ? '#FFFFFF' : '#000000';
  }
}