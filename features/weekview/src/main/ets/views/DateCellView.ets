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

import { DateCellViewModel } from '../viewmodel/DateCellViewModel';
import { DateViewModel } from '../viewmodel/DateViewModel';
import { RootViewModel } from '../viewmodel/RootViewModel';
import { BigFontSize, CommonInnerEvent, FontSizeScaleUtils, GlobalThis } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { broadcastContent, focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'DateCellView';

@Component
export struct DateCellView {
  @Consume rootVM: RootViewModel;

  @ObjectLink dateVM: DateViewModel;

  @ObjectLink cellVM: DateCellViewModel;

  private dateCellIndex: number = 0;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @Consume keyCtrlState: boolean;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  public getFontSize(fontSizeScale: number, def: number): string {
    if (fontSizeScale >= 1.75 && fontSizeScale < 2.0) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, def) + 1 + 'vp';
    } else if (fontSizeScale >= 2.0 && fontSizeScale < 3.2) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, def) + 1.2 + 'vp';
    } else if (fontSizeScale >= 3.2) {
      return FontSizeScaleUtils.getLimitFontSizeNum(
        fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD, def + 4) + 1.4 + 'vp';
    }
    return FontSizeScaleUtils.getLimitFontSizeVp(
      fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_STANDARD, def) as string;
  }

  private isTodayAndSelected(): boolean {
    return (this.cellVM.isToday() && this.cellVM.isSelect);
  }

  // 农历信息和日期是否是垂直对齐的
  private isVerticallyAligned(): boolean {
    return !this.cellVM.isExtraInfoOnRight();
  }

  private backtodayHandler :() => void =() => {
  if (this.isTodayAndSelected()) {
  focusComponentById(this.cellVM.compId, 500);
}
}
  @Builder
  solarTextBuilder() {

    if (this.cellVM.extraInfoStr) {

    }
    if (this.cellVM.showLunarMonthUnderline) {

    }
  }

  @Builder
  buildSolarDate() {
    Text(this.cellVM.solarDateStr)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE)
      .fontSize(this.rootVM.solarDateFontSize)
      .fontColor(this.isTodayAndSelected() ? Color.White : this.cellVM.solarDateColor)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .size({
        width: this.rootVM.weekTitleVM.solarDateWidth, height: FontSizeScaleUtils.getLimitHeightNum(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.rootVM.solarDateHeight)
      })
      .markAnchor(this.cellVM.solarDateMarkAnchor)
      .position(this.cellVM.solarDatePosition)
      .opacity(this.cellVM.solarOpacity)
      .accessibilityLevel('no')
  }

  @Builder
  buildExtraInfo() {
    Column() {
      Text(this.cellVM.extraInfoStr)
        .fontColor((this.isTodayAndSelected() && this.isVerticallyAligned()) ? Color.White : this.cellVM.extraInfoColor)
        .fontSize(this.rootVM.extraInfoFontSize)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .size({
          width: this.rootVM.extraInfoWidth, height: FontSizeScaleUtils.getLimitHeightNum(
            GlobalThis.getInstance().fontSizeScale,
            BigFontSize.BIG_FONT_SIZE_STANDARD,
            this.rootVM.extraInfoHeight)
        })
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .opacity(this.cellVM.extraInfoOpacity)
        .accessibilityLevel('no')
        .margin({ top: this.isVerticallyAligned() ? 1 : 0 })

      if (this.cellVM.showLunarMonthUnderline) {
        Column()
          .size({
            width: FontSizeScaleUtils.getLimitFontSizeVp(
              GlobalThis.getInstance().fontSizeScale,
              BigFontSize.BIG_FONT_SIZE_STANDARD,
              this.rootVM.extraInfoWidth < this.cellVM.lunarUnderlineWidth ?
              this.rootVM.extraInfoWidth : this.cellVM.lunarUnderlineWidth),
            height: 1
          })
          .backgroundColor(this.themeColor)
          .opacity((this.cellVM.isToday() && this.cellVM.isSelect) ? 1 : $r('sys.float.alpha_secondary'))
      }
    }.markAnchor(this.cellVM.extraInfoMarkAnchor)
    .position(this.cellVM.extraInfoPosition)
  }

  @Builder
  buildLunarLine() {
    Column()
      .markAnchor(this.cellVM.lunarUnderlineMarkAnchor)
      .position(this.cellVM.lunarUnderlinePosition)
      .size({
        width: FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.cellVM.lunarUnderlineWidth),
        height: 1
      })
      .backgroundColor(this.themeColor)
  }

  @Builder
  buildAgendaDot() {
    Column()
      .backgroundColor(this.isTodayAndSelected() ? Color.White : this.cellVM.agendaDotColor)
      .opacity((this.cellVM.isToday() && this.cellVM.isSelect) ? 1 : $r('sys.float.alpha_tertiary'))
      .size({
        width: this.rootVM.agendaDotRadius * 2, height:
        FontSizeScaleUtils.getLimitHeightNum(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.rootVM.agendaDotRadius * 2)
      })
      .borderRadius(this.rootVM.agendaDotRadius)
      .markAnchor(this.cellVM.agendaDotMarkAnchor)
      .position(this.cellVM.agendaDotPosition)
  }

  aboutToAppear(): void {
    emitter.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, this.backtodayHandler);
  }

  aboutToDisappear(): void {
    emitter.off(CommonInnerEvent.BACK_TO_TODAY,this.backtodayHandler)
  }
  build() {
    Row() {
      this.buildSolarDate();
      if (this.cellVM.extraInfoStr) {
        this.buildExtraInfo();
      }
      if (this.cellVM.hasAgenda) {
        this.buildAgendaDot();
      }
    }
    .id(this.cellVM.compId)
    .position({
      x: this.rootVM.isRTL ?
        this.rootVM.weekTitleVM.rootWidth -
          (this.rootVM.weekTitleVM.leftWidth + this.rootVM.weekTitleVM.dateCellWidth * (this.dateCellIndex + 1)) -
          (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0) :
        // 分栏场景下应考虑分栏边距
        (this.rootVM.weekTitleVM.leftWidth + this.rootVM.weekTitleVM.dateCellWidth * this.dateCellIndex +
          (this.rootVM.inDivideWindow ? this.rootVM.ganttMargin : 0))
    })
    .size({
      width: this.rootVM.weekTitleVM.dateCellWidth,
      height: FontSizeScaleUtils.getLimitHeightNum(
        GlobalThis.getInstance().fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD,
        this.rootVM.dateHeight)
    })
    .onClick(() => this.handleClickCell())
    .accessibilityGroup(true)
    .accessibilityText(this.cellVM.accessibilityTextStr)
    .accessibilityDescription(' ')
    .accessibilitySelected(this.cellVM?.isSelect)
    .focusable(true)
    .focusOnTouch(true)
    .focusBox({ margin: LengthMetrics.vp(-2) })
  }

  handleClickCell() {
    this.rootVM.changeDayByClickDateCell(this.dateVM.index, this.cellVM.index);
    broadcastContent(this.cellVM.getAccessibilityText());
  }
}