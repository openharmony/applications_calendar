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
import { DAY_PER_WEEK } from '@app/common/src/main/ets/util/DateUtil';
import MonthlyDataArray from '../../../common/MonthlyDataArray';
import { MonthViewLayout } from '../../../layout/MonthCardLayout';
import { ComplexMonthViewModel } from '../../../viewModel/components/monthVM/ComplexMonthViewModel';
import { SingleDayView } from '../SingleDayView';

const TAG: string = '[MonthCard][ComplexMonthView]';
const MAX_MONTH_COUNT: number = 3;

/**
 * 可以翻页的月视图，用于处理滑动动作
 */
@Component
export struct SwiperMonthView {
  @ObjectLink viewModel: ComplexMonthViewModel;

  private layoutModel: MonthViewLayout | undefined;

  build() {
    Swiper(this.viewModel.swiperController) {
      ForEach(new Array(MAX_MONTH_COUNT).fill(''), (item: string, index: number) => {
        // 确保数组引用不越界
        if (this.viewModel.cardSingleMonthVMArr.length > index) {
          SingleMonthView({
            monthData: this.viewModel.cardSingleMonthVMArr[index],
            viewModel: this.viewModel
          })
        }
      }, (item: string, index: number) => index.toString())
    }
    .cachedCount(0)
    .index(this.viewModel.curIndex)
    .autoPlay(false)
    .indicator(false) // 默认开启指示点
    .duration(300)
    .vertical(false)
    .focusable(false)
    .layoutWeight(1)
    .disableSwipe(true) // 禁用左右滑动功能
    .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
      this.viewModel.onAnimationStart(index, targetIndex);
    })
    .onChange((index: number) => {
      this.viewModel.onSwiperChange(index);
    })
  }
}

/**
 * 月视图的单月视图
 */
@Component
export struct SingleMonthView {
  @ObjectLink monthData: MonthlyDataArray

  @ObjectLink viewModel: ComplexMonthViewModel

  build() {
    RelativeContainer() {
      ForEach(new Array(this.monthData.length / DAY_PER_WEEK).fill(''), (item: string, weekIndex: number) => {
        this.buildWeek(weekIndex);
      }, (item: string, weekIndex: number) => weekIndex.toString())
    }
    .height('100%')
    .width('100%')
    .padding({
      top: 8,
      left: 12,
      right: 12,
      bottom: 12
    })
    .id('monthViewBase')
  }

  @Builder
  buildWeek(weekIndex: number) {
    ForEach(new Array(DAY_PER_WEEK).fill(''), (item: string, dayIndex: number) => {
      if (this.monthData.length > (weekIndex * DAY_PER_WEEK + dayIndex) &&
      this.monthData[weekIndex * DAY_PER_WEEK + dayIndex]) {
        SingleDayView({
          viewModel: this.monthData[weekIndex * DAY_PER_WEEK + dayIndex],
          displayDate: this.viewModel.displayDate,
          deviceLayout: this.viewModel.deviceLayout,
          formId: this.viewModel.formId,
          index: weekIndex * DAY_PER_WEEK + dayIndex,
          rowNum: this.monthData.length / DAY_PER_WEEK
        })
      }
    }, (item: string, dayIndex: number) => dayIndex.toString())
  }
}