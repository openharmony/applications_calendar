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

import { BigFontSize, CombineAnimateParam, DAY_PER_WEEK } from '@app/common';
import { MonthlyModeState, MonthlyViewState, MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import { WeekTitleViewModel } from '../viewmodel/WeekTitleViewModel';
import { FrameLayout, MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { WeekTitleLayout } from '../layoutmodel/WeekTitleLayoutRule';
import { WeekNumLayout } from '../layoutmodel/WeekNumLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = '[MonthlyView][WeekTitle]';

@Preview
@Component
export struct WeekTitle {
  // 周题 绑定的 周题数据模型
  @ObjectLink viewModel: WeekTitleViewModel;

  // 周题 绑定的 月视图状态机
  @State state: MonthlyViewState = MonthlyViewStateManager.getInstance().state;

  @State startOfWeek: number = MonthlyViewStateManager.getInstance().state.startOfWeek;

  // 月视图绑定的布局参数
  @State layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  // 月视图绑定的布局参数
  @Consume weekTitleLayout: WeekTitleLayout;

  @Consume weekNumLayout: WeekNumLayout;

  @Consume monthDateViewAnimate: CombineAnimateParam;

  private index: number = 1;

  build() {
    Row() {
      ForEach(new Array(this.viewModel.weekTitles.length).fill(''), (item: string, index: number) => {
        Text(this.viewModel.weekTitles[index])
          .fontSize((this.weekTitleLayout.fontSize + (this.fontSizeScale > 1.5 ? 2 : 0)) + 'vp')
          .fontColor(this.state.isWeekendByStartOfWeek(index)
            ? $r('sys.color.font_tertiary') : $r('sys.color.font_primary')
          )
          .fontWeight(FontWeight.Medium)
          .id(this.viewModel.weekCompIds[index])
          .width('14.2857%')// 各占屏幕的1/7
          .textAlign(this.layout.isVerticalCell && !this.layout.isGrid ? TextAlign.Center : TextAlign.Start)
          .padding({
            start: LengthMetrics.vp(this.layout.isGrid && !this.layout.isSmall ? this.weekTitleLayout.leftPadding : 0)
          })
      }, (item: string, index: number) => index.toString())
    }
    .justifyContent(FlexAlign.SpaceAround)
    .margin({
      top: this.modeState.isInSmallFold ? 4 : 0,
      left: this.layout.isGrid && !this.layout.isSmall ? 0 : 16,
      right: this.layout.isGrid && !this.layout.isSmall ? 0 : 16,
      bottom: MonthStaticLayout.weekTitlePaddingBottom + WeekTitleLayout.marginDownGap,
    })
    .constraintSize({ minHeight: MonthStaticLayout.weekTitleHeight })
    .visibility(this.monthDateViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.IDENTITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
      )
    )
    .accessibilityGroup(true)
    .accessibilityLevel('no')
    .id(`monthWeekTitle_${this.index}`)
  }
}