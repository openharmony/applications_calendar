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


import { DateUtil, Log, SingleInstanceHelper } from '@app/common';

const TAG: string = "[SideBar][WeekTitleViewModel]";

@Observed
export class WeekTitlesArray extends Array<string> {
}

// multi month views use one WeekTitleViewModel
@Observed
export class WeekTitleViewModel {
  startOfWeek: number = -1;
  weekTitles: WeekTitlesArray = [];
  private _defaultWeekTitles: string[] = [];

  constructor() {
    this.getWeekTitle('')
  }

  static getInstance(): WeekTitleViewModel {
    return SingleInstanceHelper.createOrGet(WeekTitleViewModel, 'WeekTitleViewModel');
  }

  getWeekTitle(language: string): WeekTitlesArray {
    this._defaultWeekTitles = DateUtil.getWeekTitle(true, language);
    let oriStartOfWeek = AppStorage.get<number>(`startOfWeek`);
    if (!oriStartOfWeek) {
      oriStartOfWeek = -1;
    }
    this.startOfWeek = DateUtil.getStartOfWeek(oriStartOfWeek);
    this.updateWeekTitles();
    return this.weekTitles;
  }

  updateWeekTitles() {
    this.weekTitles = new WeekTitlesArray;
    for (let index = this.startOfWeek; index < this._defaultWeekTitles.length; ++index) {
      this.weekTitles.push(this._defaultWeekTitles[index])
    }
    for (let index = 0; index < this.startOfWeek; ++index) {
      this.weekTitles.push(this._defaultWeekTitles[index])
    }
    Log.debug(TAG, "buildWeekTitles: " + this.weekTitles);
  }

  onStartOfWeekChange(startOfWeek: number) {
    Log.info(TAG, "onStartOfWeekChange: " + startOfWeek);
    this.startOfWeek = startOfWeek;
    this.updateWeekTitles();
  }
}