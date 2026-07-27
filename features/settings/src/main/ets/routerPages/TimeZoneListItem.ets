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
import { BigFontSize, FontSizeScaleUtils } from '@app/common';
import { IRichText, AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { LengthMetrics } from '@ohos.arkui.node';

const TAG: string = 'TimeZoneListItem';

@Component
export struct TimeZoneListItem {
  @Prop cityName: string = '';

  @Prop timeZoneOffset: string = '';

  @Link searchText: string;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State citySpanStrList: Array<IRichText> = [];

  @State offsetSpanStrList: Array<IRichText> = [];

  aboutToAppear(): void {
    this.citySpanStrList = AgendaUtil.transTitleMessage(this.cityName, this.searchText);
    this.offsetSpanStrList = AgendaUtil.transTitleMessage(this.timeZoneOffset, this.searchText);
  }

  getFontColor(item: IRichText, isOffsetText: boolean) {
    if (item.isHighLight) {
      return this.themeColor;
    } else {
      return isOffsetText ? $r('sys.color.font_secondary') : $r('sys.color.font_primary');
    }
  }

  @Builder
  buildCityName() {
    Text() {
      ForEach(this.citySpanStrList, (item: IRichText) => {
        Span(item.text)
          .fontColor(this.getFontColor(item, false))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            16
          ))
      }, (item: IRichText, index: number | undefined): string => `${index}-${item}-${this.cityName}`)
    }
    .fontColor($r('sys.color.font_primary'))
    .fontWeight(FontWeight.Medium)
  }

  @Builder
  buildCityOffset() {
    Text() {
      ForEach(this.offsetSpanStrList, (item: IRichText) => {
        Span(item.text)
          .fontColor(this.getFontColor(item, true))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            14
          ))
      }, (item: IRichText, index: number | undefined): string => `${index}-${item}-${this.timeZoneOffset}`)
    }
    .margin({ top: $r('sys.float.padding_level1') })
    .fontColor($r('sys.color.font_secondary'))
    .fontWeight(FontWeight.Regular)
  }

  build() {
    Column() {
      this.buildCityName()
      this.buildCityOffset()
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      start: LengthMetrics.vp(8),
      end: LengthMetrics.vp(8)
    })
  }
}