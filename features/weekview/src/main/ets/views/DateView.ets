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

import { RootViewModel } from '../viewmodel/RootViewModel';
import { DateViewModel } from '../viewmodel/DateViewModel';
import { DateCellView } from './DateCellView';
import { DateCellViewModel } from '../viewmodel/DateCellViewModel';
import { BigFontSize, CombineAnimateParam, DeviceConfig } from '@app/common';
import { RootModel } from '../model/RootModel';

const TAG: string = 'DateView';

@Component
export struct DateView {
  @Consume rootVM: RootViewModel;

  @ObjectLink dateVM: DateViewModel;

  @ObjectLink dateViewAnimate: CombineAnimateParam;

  @State selectedPosX: number = 0;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private LINE_WIDTH: number = 1;

  aboutToAppear() {
    if (this.needCommerce) {
      this.LINE_WIDTH = 2; // PC圆圈过细，有锯齿感
    }
  }

  //周数
  @Builder
  buildWeekNumber() {
    Flex({direction: FlexDirection.Column, alignItems:ItemAlign.Center, justifyContent:FlexAlign.Center}) {
      Text(this.dateVM.weekIndexOfYear)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_tertiary'))
        .fontSize(this.rootVM.weekIndexFontSize)
        .accessibilityLevel('no')
      Text($r('app.string.week_view'))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_tertiary'))
        .fontSize(this.rootVM.weekTextFontSize)
        .accessibilityLevel('no')
    }
    .width(this.rootVM.weekTitleVM.leftWidth)
    .height(this.rootVM.dateHeight)
    .padding({ top: 2, right: 4 })
    .position({
      x: this.rootVM.isRTL ?
        // 镜像翻转情况下周数显示在最右侧 ，全部宽度减去周数的宽度位置
        this.rootVM.weekTitleVM.rootWidth - this.rootVM.weekTitleVM.leftWidth -
          // 分栏场景下应该再减去分栏边距
          (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0) :
        (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0),
      y: -(this.rootVM.weekIndexFontSize / 2),
    })

    Divider()
      .vertical(true)
      .color($r('sys.color.comp_divider'))
      .height('100%')
      .width('1px')
      .position({
        // 分割线位置应加上分栏场景下的边距
        x: this.rootVM.isRTL ?
          this.rootVM.weekTitleVM.rootWidth -
            (this.rootVM.weekTitleVM.leftWidth + (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0)) :
          this.rootVM.weekTitleVM.leftWidth + (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0)
      })
  }

  build() {
    Row() {
      if (this.rootVM.isShowWeekNumber) {
        this.buildWeekNumber();
      }

      Column()
        .backgroundColor(this.dateVM.selectCircleBgColor)
        .border({ width: this.LINE_WIDTH, color: this.dateVM.selectCirCleBorderColor })
        .size({ width: this.rootVM.selectCircleRadius * 2, height: this.rootVM.selectCircleRadius * 2 })
        .position(this.rootVM.selectCirclePos)
        .markAnchor(this.rootVM.selectCircleAnchor)
        .borderRadius(this.rootVM.selectCircleRadius)
      ForEach(RootModel.instance().WEEK_ARRAY, (vm: DateCellViewModel, index: number) => {
        DateCellView({ dateVM: this.dateVM, cellVM: this.dateVM.cellVMs[index], dateCellIndex: index })
      })
    }
    .size({ width: this.rootVM.weekTitleVM.rootWidth, height: this.rootVM.dateHeight })
    .visibility(this.dateViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.opacity(this.dateViewAnimate.opacity)
          .animation(this.dateViewAnimate.opacityAnimateParam))// 放缩转场
        .combine(TransitionEffect.scale(this.dateViewAnimate.scaleOption)
          .animation(this.dateViewAnimate.scaleAnimateParam))
        .combine(TransitionEffect.translate(this.dateViewAnimate.translateOptions)
          .animation(this.dateViewAnimate.translateAnimateParam)
        )
    )
    .id(this.rootVM.isWeekView() ? 'week_view_root_date_view' : 'day_view_root_date_view')
  }
}