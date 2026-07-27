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

import { CompId, DateUtil, GlobalData, GlobalDataKeys, MONTH_PER_YEAR } from '@app/common';

export class TitleModel {
  private static _instance: TitleModel = new TitleModel();
  private weekTitles: string[] = [];
  private monthTitles: string[] = [];
  private weekCompIds: string[] = [CompId.SUNDAY, CompId.MONDAY, CompId.TUESDAY, CompId.WEDNESDAY, CompId.THURSDAY,
    CompId.FRIDAY, CompId.SATURDAY];

  static instance(): TitleModel {
    return TitleModel._instance;
  }

  public reset(): void {
    const language = GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string;

    const startOfWeekConf = (GlobalData.instance().get(GlobalDataKeys.START_OF_WEEK) || -1) as number;
    const startOfWeek = DateUtil.getStartOfWeek(startOfWeekConf);
    const defaultWeekTitles = DateUtil.getWeekTitle(true, language);
    this.weekTitles = defaultWeekTitles.slice(startOfWeek).concat(defaultWeekTitles.slice(0, startOfWeek));
    this.weekCompIds = this.weekCompIds.slice(startOfWeek).concat(this.weekCompIds.slice(0, startOfWeek));

    this.monthTitles = [];
    for (let i = 0; i < MONTH_PER_YEAR; i++) {
      const title = DateUtil.getMonthTitle(i, language);
      this.monthTitles.push(title);
    }
  }

  getWeekTitles(): string[] {
    return this.weekTitles;
  }

  getWeekCompIds(): string[] {
    return this.weekCompIds;
  }

  getMonthTitle(monthIndex: number): string {
    return this.monthTitles[monthIndex];
  }
}