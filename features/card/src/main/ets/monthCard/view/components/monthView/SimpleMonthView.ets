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
import { MonthViewLayout } from '../../../layout/MonthCardLayout';
import { CardSingleDayViewModel } from '../../../viewModel/components/CardSingleDayViewModel';
import { SimpleMonthViewModel } from '../../../viewModel/components/monthVM/SimpleMonthViewModel';
import { SimpleDayView } from '../SimpleDayView';

const TAG: string = '[MonthCard][SimpleMonthView]';

/**
 * 简易月视图
 */
@Component
export struct SimpleMonthView {
  @ObjectLink viewModel: SimpleMonthViewModel;

  private layoutModel: MonthViewLayout | undefined;

  @Builder
  buildWeek(index: number) {
    ForEach(this.viewModel.curMonthData.slice(index * 7, index * 7 + 7),
      (item: CardSingleDayViewModel, sub: number) => {
        if (this.viewModel.curMonthData[index * 7 + sub]) {
          SimpleDayView({
            dayViewModel: item,
            layoutModel: this.layoutModel,
            index: index * 7 + sub,
            rowNum: this.viewModel.rowNum
          });
        }
      }, (item: CardSingleDayViewModel, sub: number) => item.toUniqueString() + sub.toString())
  }

  build() {
    RelativeContainer() {
      ForEach(new Array(this.viewModel.rowNum).fill(''), (item: string, index: number) => {
        this.buildWeek(index);
      }, (item: string, index: number) => index.toString())
    }
    .height('100%')
    .width('100%')
    .layoutWeight(1)
    .id('monthViewBase')
  }
}