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

import { ARABIC_LANGUAGE, CompId, DAY_PER_WEEK, GlobalData, GlobalDataKeys, Log, TabType } from '@app/common';
import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { StaticWeekDayInfo } from './RootViewModel';
import { DateViewModel } from './DateViewModel';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = '[WeekView/DayView][WeekTitleViewModel]';
const _defaultWeekCompIds: string[] = [CompId.SUNDAY, CompId.MONDAY, CompId.TUESDAY, CompId.WEDNESDAY,
  CompId.THURSDAY, CompId.FRIDAY, CompId.SATURDAY];

@Observed
export class NewWeekTitleViewModel {
  public _weekTitleFontSize: number = 12;
  // 一周开始日
  private _startOfWeek: number = -1;
  private _weekends: number[] = [];
  private _weekTitle: string[] = [];
  public staticWeekDayInfoList: ObservedArray<StaticWeekDayInfo> = new ObservedArray<StaticWeekDayInfo>();
  // 日期单元布局信息
  public solarDateWidth: number = 30;
  public weekTitlePos: Position = { x: 0, y: 0 };
  public weekTitleAnchor: Position = { x: 0, y: 0 };
  public dateCellWidth: number = 0;
  public weekTitleHeight: number = 16;
  public leftWidth: number = 25;
  public rightWidth: number = 15;
  public rootWidth: number = 0;
  public isRTL: boolean = false; // 是否是语言为ar的右向
  public isAR: boolean = false; // 是否为阿拉伯语

  constructor() {
  }

  init() {
    for (let i = 0; i < DAY_PER_WEEK; i++) {
      this.staticWeekDayInfoList.push(new StaticWeekDayInfo(i));
    }
  }


  get startOfWeek(): number {
    return this._startOfWeek;
  }

  set startOfWeek(startOfWeek: number) {
    this._startOfWeek = startOfWeek;
  }

  get weekTitle(): string[] {
    return this._weekTitle;
  }

  set weekTitle(weekTitle: string[]) {
    this._weekTitle = weekTitle;
  }

  get weekends(): number[] {
    return this._weekends;
  }

  set weekends(weekend: number[]) {
    this._weekends = weekend;
  }

  get weekTitleFontSize(): number {
    return this._weekTitleFontSize;
  }

  set weekTitleFontSize(weekTitleFontSize: number) {
    this._weekTitleFontSize = weekTitleFontSize;
  }

  resetWeekTitles(tabType: TabType): void {
    this.staticWeekDayInfoList.forEach((item: StaticWeekDayInfo, index: number) => {
      const tIndex: number = (index + this.startOfWeek) % DAY_PER_WEEK;
      item.title = this.weekTitle[tIndex];
      item.compId = (tabType === TabType.WEEK ? CompId.WEEK_VIEW_ROOT :
        CompId.DAY_VIEW_ROOT) + '_' + _defaultWeekCompIds[tIndex];
      item.dayOfWeek = tIndex;
    });
  }

  resetWeekends(dateVMs: ObservedArray<DateViewModel>): void {
    this.weekends = GlobalData.instance().get(GlobalDataKeys.WEEKENDS) as number[];
    this.staticWeekDayInfoList.forEach((item: StaticWeekDayInfo, index: number) =>{
      item.isWeekend = this.weekends.includes(item.dayOfWeek);
    })
    dateVMs.forEach((vm: DateViewModel, index: number) => vm.updateWeekends(this.staticWeekDayInfoList));
  }

  onLanguageChange(language:string){
    this.isRTL = i18n.isRTL(language);
    this.isAR = language.includes(ARABIC_LANGUAGE);
  }
}