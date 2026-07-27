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
  AgendaEventInfo,
  BigFontSize,
  DateUtil,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  I18nUtil,
  Log
} from '@app/common';
import { Color } from '@app/common/src/main/ets/card/ImportantCardConfig';

const TAG: string = 'CardDataPanel';

@Component
export struct CardDataPanel {
  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayDate: number = 0;

  @Prop info: AgendaEventInfo = new AgendaEventInfo();

  @State dayOffset: number = 0;

  @State unit: ResourceStr = '';

  /** 用于判断显示天后或者天 */
  @State type: string = '';

  @State isChinese: boolean = I18nUtil.isSystemChineseLanguage();

  @StorageProp('language') @Watch('onLanguageChange') language: string | undefined = AppStorage.get('language');

  aboutToAppear(): void {
    this.calculateDayOffset();
  }

  onDisplayDateChange() {
    this.calculateDayOffset();
  }

  build() {
    if (this.dayOffset) {
      this.DayOffsetText()
    }
  }

  @Builder
  DayOffsetText() {
    if (this.isChinese) {
      this.ChineseDayOffsetText();
    } else {
      this.OtherLanguageDayOffsetText();
    }
  }

  @Builder
  ChineseDayOffsetText() {
    Text() {
      Span(this.dayOffset.toString())
        .fontWeight(FontWeight.Bold)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          24))
        .fontColor(Color.RED)
      Span(this.unit)
        .fontWeight(FontWeight.Regular)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          10))
        .fontColor(Color.RED)
    }.maxLines(1)
  }

  @Builder
  OtherLanguageDayOffsetText() {
    Text(this.type === 'days_later' ? GlobalThis.getPluralStr($r('app.plural.days_later'), this.dayOffset, this.language)
      .toString() :
    GlobalThis.getPluralStr($r('app.plural.in_days'), this.dayOffset, this.language).toString())
      .fontSize(18)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.RED)
      .maxLines(1)
  }

  private calculateDayOffset() {
    const offsetContent = DateUtil.getDayOffset(this.info.mBegin, this.info.mImportantEventType, this.displayDate);
    this.dayOffset = offsetContent.dayOffset;
    this.unit = offsetContent.unit;
    this.type = offsetContent.type;
  }

  onLanguageChange() {
    Log.info(TAG, `onLanguageChange ${this.language}`);
    this.isChinese = I18nUtil.isSystemChineseLanguage();
  }
}