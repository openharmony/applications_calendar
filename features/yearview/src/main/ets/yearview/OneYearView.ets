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

import { CompId, GlobalDataKeys, Log, YearData } from '@app/common';
import { SingleMonthView } from './SingleMonthView';
import { SingleYearViewModel } from '../viewmodel/SingleYearViewModel';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { YearViewLayoutModel } from '../layoutmodel/YearViewLayoutModel';
import { GridProp } from '../layoutmodel/YearViewLayoutProp';

const TAG: string = '[YearView][OneYearView]';

/**
 * YearView for one year
 *
 * @since 2022-03-01
 */
@Component
export struct OneYearView {
  @ObjectLink viewModel: SingleYearViewModel;

  @State yearLayout: GridProp = YearViewLayoutModel.instance().gridProp.value;

  // 深色模式：@StorageProp 用于 ForEach key 中，确保组件重建时读取最新值
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 当前年视图在swiper中的index
  swipeIndex: number = -1;

  private monthArray: number[] = [];

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.singleYearViewAppear, 0);
    Log.log(TAG, `aboutToAppear info:${JSON.stringify(this.viewModel.info)}`);
    this.viewModel.init();
    for (let index = 0; index < YearData.MONTH_OF_YEAR; ++index) {
      this.monthArray.push(index);
    }
    hiTraceMeter.finishTrace(traceEvents.singleYearViewAppear, 0);
  }

  build() {
    Grid() {
      ForEach(this.monthArray, (monthIndex: number) => {
        SingleMonthView({
          viewModel: this.viewModel.monthViewModels[monthIndex],
          displayMonth: monthIndex + 1,
          swipeIndex: this.swipeIndex,
          monthIndex: monthIndex,
          year: this.viewModel.monthViewModels[monthIndex].year,
        })
      }, (monthIndex: number) => {
        const updatePropStr = this.viewModel.monthViewModels[monthIndex].getUpdatePropStr();
        const updateStr = `${monthIndex}-${updatePropStr}-${this.isDarkMode}`;
        return updateStr;
      })
    }
    .id(CompId.ONE_YEAR_VIEW)
    .accessibilityLevel('no')
    .columnsTemplate(this.yearLayout.colsTemplateStr)
    .columnsGap('4%')
    .rowsGap('4%')
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .padding({ left: '4%', right: '4%', bottom: YearViewLayoutModel.instance().gridProp.value.paddingBottom })
    .onAppear(() => {
      Log.log(TAG, `onAppear`);
    })
    .onDisAppear(() => {
      Log.log(TAG, `onDisAppear`);
    })
  }
}