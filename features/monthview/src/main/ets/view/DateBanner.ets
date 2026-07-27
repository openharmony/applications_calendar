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
  BigFontSize,
  CompId,
  DateUtil,
  FontSizeScaleUtils,
  isChineseCalendar,
} from '@app/common';
import { MonthlyModeState, MonthlyViewState, MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import { FrameLayout } from '../layoutmodel/FrameLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { isIslamicCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';
import { LengthMetrics } from '@kit.ArkUI';
import { DateBannerViewModel } from '../viewmodel/DateBannerViewModel';

const TAG: string = '[MonthlyView][DateBanner]';

@Component
export struct DateBanner {
  // 月视图绑定的视图模型
  @ObjectLink viewModel: DateBannerViewModel;
  @StorageLink('language') language: string = '';

  //字体大小
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;

  @StorageProp('windowAvoidAreaNavigationRectHeight') navigationHeight: number = 0;

  // 月视图绑定的布局参数
  @State layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  @StorageProp('themeColor') themeColor: string = '';

  @Consume isMaximizeRecovery: boolean;

  private readonly layoutChangeMinScale: number = BigFontSize.BIG_FONT_SIZE_TWO;


  @Builder
  lunarDateBannerPhone() {
    if (
      isChineseCalendar(this.viewModel.subscriptionCalendar) ||
      isIslamicCalendar(this.viewModel.subscriptionCalendar)
    ) {
      Text(
        DateUtil.getCalendarTime(this.viewModel.selectDate.getDate(),
          this.viewModel.subscriptionCalendar, this.viewModel.systemRegion
        )
      )
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_tertiary'))
        .fontSize($r('sys.float.Body_S'))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
        .padding({
          top: LengthMetrics.vp(4),
          start: this.fontSizeScale > this.layoutChangeMinScale ? LengthMetrics.vp(0) : LengthMetrics.vp(12),
          bottom: this.fontSizeScale > this.layoutChangeMinScale ? LengthMetrics.vp(4) : LengthMetrics.vp(0),
        })
        .flexShrink(1)
    }
  }

  @Builder
  phoneDateBanner() {
    Row() {
      Column() {
        Text(DateUtil.getDateTime(this.viewModel.selectDate.getDate(), this.language, this.viewModel.currentDate))
          .fontColor($r('sys.color.font_primary'))
          .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X, 16))
          .minFontSize('6vp')
          .fontWeight(FontWeight.Bold)
          .id(CompId.MONTH_VIEW_DATE)
        if (this.fontSizeScale > this.layoutChangeMinScale) {
          this.lunarDateBannerPhone();
        }
      }
      .alignItems(HorizontalAlign.Start)

      if (this.fontSizeScale <= this.layoutChangeMinScale) {
        this.lunarDateBannerPhone();
      }
    }
    .accessibilityGroup(true)
    .accessibilityLevel('yes')
    .id(CompId.MONTH_VIEW_DATE_BANNER)
    .width('100%')
    .constraintSize({ minHeight: 26 })
    .margin({ top: this.modeState.isSmallFoldDevice ? 0 : 6 })
    .padding({ bottom: LengthMetrics.vp(3), end: LengthMetrics.vp(2) })
    .clip(true)
    .renderGroup(!this.isMaximizeRecovery)
  }

  @Builder
  pcDateBanner() {
    Row() {
      Column() {
        Text(DateUtil.getDateTime(this.viewModel.selectDate.getDate(), this.language, this.viewModel.currentDate))
          .margin({ top: this.navigationHeight > 0 ? 8 : this.layout.isGrid ? 0 : 16 })
          .fontStyle(FontStyle.Normal)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
          .maxFontSize(24)
          .minFontSize('6vp')
          .maxLines(1)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .id(CompId.MONTH_VIEW_DATE)
          .alignSelf(ItemAlign.Start)
          .textAlign(TextAlign.Center)
          .constraintSize({ minHeight: 40 })

        if (isChineseCalendar(this.viewModel.subscriptionCalendar) ||
          isIslamicCalendar(this.viewModel.subscriptionCalendar)) {
          Text(
            DateUtil.getCalendarTime(
              this.viewModel.selectDate.getDate(),
              this.viewModel.subscriptionCalendar,
              this.viewModel.systemRegion
            )
          )
            .margin({ top: 4, bottom: 2 })
            .fontWeight(FontWeight.Regular)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
            .opacity(0.6)
            .alignSelf(ItemAlign.Start)
            .fontSize($r('sys.float.Body_M'))
        }
      }
      .flexShrink(1)
    }
    .accessibilityLevel('yes')
    .accessibilityGroup(true)
    .id(CompId.MONTH_VIEW_DATE_BANNER)
    .width('100%')
    .constraintSize({ minHeight: 62 })
    .clip(true)
  }

  build() {
    if (!this.layout.isSmall) {
      this.pcDateBanner();
    } else {
      this.phoneDateBanner();
    }
  }
}