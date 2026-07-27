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

import { BigFontSize, CombineAnimateParam, CompId, FontSizeScaleUtils, GlobalThis } from '@app/common';
import { RootModel } from '../model/RootModel';
import { NewWeekTitleViewModel } from '../viewmodel/NewWeekTitleViewModel';
import { RootViewModel } from '../viewmodel/RootViewModel';

const TAG: string = 'WeekTitleView';

@Component
export struct WeekTitleView {
  @Consume rootVM: RootViewModel;

  @ObjectLink weekTitleViewAnimate: CombineAnimateParam;

  @ObjectLink viewModel: NewWeekTitleViewModel;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  aboutToAppear() {
  }

  public getFontSize(fontSizeScale: number): string {
    if (fontSizeScale >= 1.75 && fontSizeScale < 2.0) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, this.viewModel.weekTitleFontSize) + 1 + 'vp';
    } else if (fontSizeScale >= 2.0 && fontSizeScale < 3.2) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, this.viewModel.weekTitleFontSize) + 1.2 + 'vp';
    } else if (fontSizeScale >= 3.2) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, this.viewModel.weekTitleFontSize) + 1.4 + 'vp';
    }
    return FontSizeScaleUtils.getLimitFontSizeVp(
      fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_STANDARD, this.viewModel.weekTitleFontSize) as string;
  }

  build() {
    Row() {
      ForEach(RootModel.instance().WEEK_ARRAY, (_: number, index: number) => {
        Column() {
          Text(this.viewModel.staticWeekDayInfoList[index].title)
            .fontSize(this.getFontSize(GlobalThis.getInstance().fontSizeScale))
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Medium)
            .width(this.viewModel.solarDateWidth * this.fontSizeScale)
            .opacity(this.viewModel.staticWeekDayInfoList[index].isWeekend ? 0.4 : 1)
            .markAnchor(this.viewModel.weekTitleAnchor)
            .position(this.viewModel.weekTitlePos)
            .id(this.viewModel.staticWeekDayInfoList[index].compId)
        }
        .size({ width: this.viewModel.dateCellWidth, height: this.viewModel.weekTitleHeight })
      })
    }
    .id(CompId.WEEK_VIEW_TITLE)
    .accessibilityLevel('no-hide-descendants')
    .padding({
      left: this.viewModel.isRTL ? this.viewModel.rightWidth : this.viewModel.leftWidth +
        (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0),
      // 分栏场景下需要额外增加边距
      right: this.viewModel.isRTL ? this.viewModel.leftWidth  +
        (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0) : this.viewModel.rightWidth,
      bottom: RootModel.instance().DATE_MARGIN_TOP,
    })
    .size({
      width: this.viewModel.rootWidth,
      height: this.viewModel.weekTitleHeight + RootModel.instance().DATE_MARGIN_TOP
    })
    .visibility(this.weekTitleViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(TransitionEffect.OPACITY
      .combine(TransitionEffect.opacity(this.weekTitleViewAnimate.opacity)
        .animation(this.weekTitleViewAnimate.opacityAnimateParam))
      .combine(TransitionEffect.translate(this.weekTitleViewAnimate.translateOptions)
        .animation(this.weekTitleViewAnimate.translateAnimateParam))
      .combine(TransitionEffect.scale(this.weekTitleViewAnimate.scaleOption)
        .animation(this.weekTitleViewAnimate.scaleAnimateParam))
    )
  }
}