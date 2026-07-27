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

const TAG: string = 'WeekTitleViewModel';

/**
 * 周题的VM
 */
@Observed
export class WeekTitleViewModel {
  private weekends: number[] = [];
  private startOfWeek: number = 0;
  private defaultWeekTitles: Resource[] = [
    $r('app.string.Card_Sun'),
    $r('app.string.Card_Mon'),
    $r('app.string.Card_Tue'),
    $r('app.string.Card_Wed'),
    $r('app.string.Card_Thu'),
    $r('app.string.Card_Fri'),
    $r('app.string.Card_Sat')
  ]

  // 周题字数
  public weekTitles: Resource[] = [
    $r('app.string.Card_Sun'),
    $r('app.string.Card_Mon'),
    $r('app.string.Card_Tue'),
    $r('app.string.Card_Wed'),
    $r('app.string.Card_Thu'),
    $r('app.string.Card_Fri'),
    $r('app.string.Card_Sat')
  ];
  public isShowWeekends: boolean[] = new Array(7).fill(false);

  constructor(weekends?: number[], startOfWeek?: number) {
    this.weekends = weekends ?? [];
    this.startOfWeek = startOfWeek ?? 0;
  }


  onStartOfWeekChange(startOfWeek: number) {
    this.startOfWeek = startOfWeek;
    this.updateWeekTitles();
  }

  onWeekendsChange(weekends: number[]) {
    this.weekends = weekends;
    this.updateWeekends();
  }

  updateWeekTitles(): void {
    // modify weekTitle
    this.weekTitles =
      [...this.defaultWeekTitles.slice(this.startOfWeek),
        ...this.defaultWeekTitles.slice(0, this.startOfWeek)
      ];
   }

  updateWeekends(): void {
    // modify Weekends
    this.isShowWeekends.forEach((val: boolean, index: number) => {
      this.isShowWeekends[index] = this.weekends?.includes((this.startOfWeek + index) % 7);
    });
  }
}