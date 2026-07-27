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

import {
  CommonInnerEvent,
  DayData,
  Log,
  ServiceEnum,
  ServiceManager,
  SingleSwipeViewModel,
  SwipeDataSource
} from '@app/common';
import { SingleYearViewModel, YearInfo } from './SingleYearViewModel';
import emitter from '@ohos.events.emitter';
import { Callback } from '@ohos.base';
import { TitleModel } from '../model/TitleModel';

const TAG: string = "[YearView][YearVM]";

@Observed
export class YearViewModel extends SwipeDataSource {
  readonly MAX_YEAR: number = 5000;
  readonly MIN_YEAR: number = 1;
  swipeCount: number = 3;

  public solarYear : number = -1;

  //  2    [0]   1
  // 2023 2024  2025
  public constructor(solarYear: number) {
    super(0);
    this.solarYear = solarYear;
    // 系统时间的实时时间戳, 后台通过系统定时器每分钟触发一次刷新
    this.systemDateChangeHandler = () => this.onSystemDateChange();
    TitleModel.instance().reset();
    emitter.on({ eventId: CommonInnerEvent.INNER_DATE_CHANGED }, this.systemDateChangeHandler);
  }

  init() {
    Log.log(TAG, `init curIndex:${this.curIndex}` );
    TitleModel.instance().reset();
    const yearInfo = new YearInfo(this.solarYear);
    this.initData([
      new SingleYearViewModel(0, yearInfo),
      new SingleYearViewModel(1, yearInfo.increase()),
      new SingleYearViewModel(2, yearInfo.decrease())
    ])
    Log.log(TAG, `init singleYearVMs =` );
  }

  destroy(): void {
    Log.log(TAG, "destroy");
    this.unSubscribeEvents();
  }

  unSubscribeEvents(): void {
    emitter.off(CommonInnerEvent.INNER_DATE_CHANGED, this.systemDateChangeHandler);
  }

  // 响应选中天触发, 年视图滑动触发, 其它视图操作触发
  // 只有在PC 年视图时 上点击回到今天 才进行处理
  onSelectedDayChange(selectedDay: DayData, inYearView: boolean): void {
    const selectedYear = selectedDay.solarYear;
    const curInfo = this.curData?.info as YearInfo;
    if (curInfo.year === selectedYear) {
      return;
    }
    this.solarYear = selectedYear;
    if (inYearView) {
      this.updateByInfo(new YearInfo(selectedYear));
      Log.info(TAG, `onSelectedDayChange inYearView`);
      this.singleVMs.forEach((sigYearVM: SingleSwipeViewModel) => {
        const singleYearViewModel: SingleYearViewModel = sigYearVM as SingleYearViewModel;
        singleYearViewModel.onSelectedDayChange();
      });
    }
  }

  onStartOfWeekChange(startOfWeek: number) {
    Log.info(TAG, "onStartOfWeekChange: " + startOfWeek);
    TitleModel.instance().reset();
    this.singleVMs.forEach((item) => {
      const it = item as SingleYearViewModel;
      it.onStartOfWeekChange(startOfWeek);
    })
  }

  onSubCalendarChange(showLunar: boolean) {
    Log.info(TAG, "onSubCalendarChange: " + showLunar);
    this.singleVMs.forEach((item) => {
      const it = item as SingleYearViewModel;
      it.onSubCalendarChange(showLunar);
    })
  }

  onWeekendsChange(weekends: number[]) {
    this.singleVMs.forEach((item) => {
      const it = item as SingleYearViewModel;
      it.onWeekendsChange(weekends);
    })
  }

  onLanguageChange(language: string) {
    TitleModel.instance().reset();
    this.singleVMs.forEach((item) => {
      const it = item as SingleYearViewModel;
      it.onLanguageChange(language);
    })
  }

  private systemDateChangeHandler: Callback<emitter.EventData> = () => {
  };

  // 系统日期跨天
  private onSystemDateChange(): void {
    Log.log(TAG, "onSystemDateChange");
    this.singleVMs.forEach((item) => {
      const it = item as SingleYearViewModel;
      it.onSystemDateChange();
    })
  };


  hasRecess(): boolean {
    return false;
  }
}
