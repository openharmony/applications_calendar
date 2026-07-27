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

import { CompId, DateUtil, DAY_PER_WEEK, I18nUtil, Log } from '@app/common';
import { MonthlyViewState, MonthlyViewStateManager } from './MonthlyViewState';

const TAG: string = '[YearView][WeekTitleViewModel]';

// multi month views use one WeekTitleViewModel
@Observed
export class WeekTitleViewModel {
  private _defaultWeekCompIds: string[] = [CompId.SUNDAY, CompId.MONDAY, CompId.TUESDAY, CompId.WEDNESDAY,
    CompId.THURSDAY, CompId.FRIDAY, CompId.SATURDAY];
  private _defaultWeekTitles: string[] = [];

  constructor() {
    this.getWeekTitle(I18nUtil.getSystemLanguage());
  }

  // 一周开始日
  private _startOfWeek: number = -1;

  get startOfWeek(): number {
    return this._startOfWeek;
  }

  set startOfWeek(startOfWeek: number) {
    if (startOfWeek < 0 || startOfWeek > DAY_PER_WEEK) {
      return;
    }
    this._startOfWeek = startOfWeek;
    this.updateWeekTitles();
  }

  // 周题字数
  private _weekTitles: string[] = [];

  get weekTitles(): string[] {
    return this._weekTitles;
  }

  public _weekCompIds: string[] = [];

  get weekCompIds(): string[] {
    return this._weekCompIds;
  }

  getWeekTitle(language?: string): void {
    this._defaultWeekTitles = DateUtil.getWeekTitle(false, language);
    this._startOfWeek = DateUtil.getDefaultStartOfWeek();
    this.updateWeekTitles();
  }

  updateWeekLanguage(language: string) {
    this._defaultWeekTitles = DateUtil.getWeekTitle(false, language);
    Log.info(TAG, `monthWeek Update Language ${language} ${this._defaultWeekTitles}`);
    this.updateWeekTitles();
  }

  updateWeekTitles(): void {
    // modify weekTitle
    this._weekTitles =
      [...this._defaultWeekTitles.slice(this.startOfWeek),
        ...this._defaultWeekTitles.slice(0, this.startOfWeek)
      ];
    this._weekCompIds = this._defaultWeekCompIds.slice(this.startOfWeek)
      .concat(this._defaultWeekCompIds.slice(0, this.startOfWeek));
    Log.debug(TAG, 'buildWeekTitles: ' + this.weekTitles);
  }
}