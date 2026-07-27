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

import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { DateCellViewModel } from './DateCellViewModel';
import { DAY_PER_WEEK, GlobalData, GlobalDataKeys, Log, ServiceEnum, ServiceManager } from '@app/common';
import { RootViewModel, StaticWeekDayInfo } from './RootViewModel';
import { DayModel } from '../model/DayModel';
import { DateRange } from '@app/common/src/main/ets/date/DateRange';

@Observed
export class DateViewModel {
  public index: number = 0;
  public weekIndexOfYear: string = '18周';
  public cellVMs: ObservedArray<DateCellViewModel> = new ObservedArray<DateCellViewModel>();
  public dividerColor: ResourceColor = '#000000';
  public range: DateRange.Range = { start: 0, end: 0 };
  private readonly SELECT_CIRCLE_COLOR_VISIBLE: ResourceColor = GlobalData.instance().get(GlobalDataKeys.THEME_COLOR) as string;
  public selectCirCleBorderColor: ResourceColor = this.SELECT_CIRCLE_COLOR_VISIBLE;
  private readonly SELECT_CIRCLE_COLOR_INVISIBLE: ResourceColor = '#00' + (GlobalData.instance().get(GlobalDataKeys.THEME_COLOR) as string).substring(1);
  public selectCircleBgColor: ResourceColor = this.SELECT_CIRCLE_COLOR_INVISIBLE;
  private rootVM: RootViewModel = new RootViewModel(0);

  constructor(index: number, rootVM: RootViewModel) {
    this.index = index;
    this.rootVM = rootVM;

    for (let i = 0; i < DAY_PER_WEEK; i++) {
      this.cellVMs.push(new DateCellViewModel(i, this.rootVM));
    }
  }

  resetLayout(): void {
    this.cellVMs.forEach((vm: DateCellViewModel) => {
      vm.resetLayout();
    });
  }

  isNowInRange(): boolean {
    return DateRange.isDateInRange(Date.now(), this.range);
  }

  updateDayModels(list: DayModel[]): void {
    this.range = { start: list[0].range.start, end: list[list.length - 1].range.end };
    list.forEach((data: DayModel, index: number) => {
      this.cellVMs[index].updateDayModel(data);
    });
  }

  updateWeekends(infoList: StaticWeekDayInfo[]): void {
    infoList.forEach((info: StaticWeekDayInfo, index: number) => {
      this.cellVMs[index].updateWeekend(info.isWeekend);
    });
  }

  updateAgendaDot(): void {
    this.cellVMs.forEach((cellVM: DateCellViewModel) => {
      cellVM.updateAgendaDot();
    });
  }

  updateExtraInfo(): void {
    this.cellVMs.forEach((cellVM: DateCellViewModel) => {
      cellVM.updateExtraInfo();
      cellVM.updateColor();
    });
  }

  setSelect(cellIndex: number): void {
    if (cellIndex < 0 || cellIndex >= this.cellVMs.length) {
      return;
    }
    this.cellVMs.forEach((cellVM: DateCellViewModel, index: number) => cellVM.setSelect(cellIndex === index));
    const isCellToday = this.cellVMs[cellIndex]?.isToday() ?? false;
    this.selectCircleBgColor = isCellToday ? this.SELECT_CIRCLE_COLOR_VISIBLE : this.SELECT_CIRCLE_COLOR_INVISIBLE;
    this.selectCirCleBorderColor = isCellToday ? this.SELECT_CIRCLE_COLOR_INVISIBLE : this.SELECT_CIRCLE_COLOR_VISIBLE;
  }

  updateCalendar(): void {
    this.cellVMs.forEach((vm: DateCellViewModel) => vm.updateExtra());
  }

  onChineseHolidayStateChange(): void {
    this.cellVMs.forEach((vm: DateCellViewModel) => vm.onChineseHolidayStateChange());
  }

  updateLanguage(language: string): void {
    this.cellVMs.forEach((vm: DateCellViewModel) => vm.updateLanguage(language));
  }
}