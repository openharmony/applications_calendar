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

import { FontId, LayoutIdType } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { BigFontSize } from '@app/common/src/main/ets/constants/BigFontSize';
import lazy { FontManager } from '../../../utils/FontManager';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { CardUiUtils } from '../../util/CardUiUtils';

const TAG: string = 'CardYearDayOffset';

@Component
export struct CardYearDayOffset {
  @Prop title: string | Resource;

  @Prop rrule: string;

  @Prop yearOffset: number;

  @Prop remainingDays: number;

  @Prop dayOffset: number;

  @Prop type: string;

  @Prop @Watch('onFontChange') fontId: FontId;

  @Prop @Watch('onColorChange') color: string;

  @Prop isEdit: boolean;

  @Prop horizontalAlign: HorizontalAlign;

  @Prop cardName: string;

  @Prop layoutType: string = LayoutIdType.DEFAULT;

  @Prop @Watch('onLanguageChange') language: string;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp')isSmallUp: boolean = false;

  @State isChinese: boolean = I18nUtil.isSystemChineseLanguage();

  @Prop sizeRate: number = 1;

  onFontChange() {
    Log.info(TAG, `onFontChange fontId: ${this.fontId}`);
    if (!this.fontId || this.fontId === FontId.DEFAULT) {
      return;
    }
    FontManager.registerFont(this.fontId, $rawfile(`font/${this.fontId}.ttf`));
  }

  onColorChange() {
    Log.info(TAG, `onColorChange: color = ${this.color}`);
  }


  aboutToAppear(): void {
    if (this.fontId && this.fontId !== FontId.DEFAULT) {
      FontManager.registerFont(this.fontId, $rawfile(`font/${this.fontId}.ttf`));
    }

    Log.info(TAG, `aboutToAppear: color = ${this.color}`);
  }

  onLanguageChange() {
    this.isChinese = I18nUtil.isSystemChineseLanguage();
  }

  isCenter() {
    return this.horizontalAlign === HorizontalAlign.Center;
  }

  isCard2x2() {
    return this.cardName === 'card2x2';
  }

  isCard2x4() {
    return this.cardName === 'card2x4';
  }

  getFontSize(offset: number, isSmallUp: boolean): number {
    let rate = this.isEdit ? 0.8 : 1;
    rate = isSmallUp ? rate * 0.8 : rate;

    switch (offset.toString().length) {
      case 1:
      case 2:
        return (this.isCard2x2() ? 44 : 60) * rate;
      case 3:
        // 3位数以上，字体进一步缩小，防止横屏天后换行
        return (this.isCard2x2() ? 40 : 54) * rate * this.sizeRate;
      case 4:
        return (this.isCard2x2() ? 30 : 40) * rate * this.sizeRate;
      case 5:
        return (this.isCard2x2() ? 24 : 32) * rate * this.sizeRate;
      default:
        return 24 * rate;
    }
  }

  // 默认字体偏移量
  getChineseFontIdDefaultOffsetY(offset: number, isSmallUp: boolean): number {
    if (this.fontId !== FontId.DEFAULT) {
      return 0;
    }

    let rate = this.isEdit ? 0.8 : 1;
    rate = isSmallUp ? rate * 0.8 : rate;

    switch (offset.toString().length) {
      case 1:
      case 2:
      case 3:
        return 6 * rate;
      case 4:
        return 3 * rate;
      case 5:
        return 1 * rate;
      default:
        return 0;
    }
  }

  // 默认字体，天数存在向上偏移，周年存在向下偏移
  getChineseFontIdOffsetY(offset: number, isSmallUp: boolean, type = 'dayOffset') {
    const offsetY = this.getChineseFontIdDefaultOffsetY(offset, isSmallUp);

    if (type === 'dayOffset') {
      // 向下偏移
      return this.layoutType !== LayoutIdType.TEXT_IMG ? 0 : offsetY;
    } else {
      // 向上偏移
      return offsetY * -0.6;
    }
  }

  getChineseYearDayOffsetTextOffsetY() {
    if (this.isCard2x4()) {
      // 2x4卡片整体向上偏移7个vp
      return -7;
    } else {
      // 2x2卡片，图文混排整体向上偏移2个vp；上文下图整体向下偏6个
      return this.layoutType !== LayoutIdType.TEXT_IMG ? -2 : 6;
    }
  }

  getFontWeight() {
    // 字体加粗，FONT_2裂纹失效
    return this.fontId === FontId.FONT_2 ? FontWeight.Normal : FontWeight.Bold;
  }

  getOtherDayText() {
    if (this.type === 'days_later') {
      return $r('app.plural.days_later', this.dayOffset, this.dayOffset);
    } else {
      return $r('app.plural.in_days', this.dayOffset, this.dayOffset);
    }
  }

  getChineseYearText() {
    if (CardUiUtils.isNeedShowAsBirthday(this.title)) {
      return '周岁';
    } else {
      return this.language.includes('zh-Hans') ? '周年' : '週年';
    }
  }

  getChineseDayOffset(direction = 'left'): number {
    // ux要求数字居中，“天后”场景有2个字，要偏移14vp，“天”场景有1个字，要偏移7vp
    const offset = this.type === 'days_later' ? 14 : 7;
    return direction === 'left' ? offset : offset * -1;
  }

  getOtherYearText() {
    if (this.type === 'days_later') {
      return $r('app.plural.still_years', this.yearOffset, this.yearOffset);
    } else {
      return $r('app.plural.in_anniversarys', this.yearOffset, this.yearOffset);
    }
  }

  private getNumberFontFamily(): ResourceStr {
    if (!this.fontId || this.fontId === FontId.DEFAULT) {
      return $r('sys.string.ohos_id_text_font_family_medium');
    } else {
      return this.fontId;
    }
  }

  @Builder
  ChineseYearOffsetText() {
    Text() {
      Span(this.yearOffset.toString())
        .fontSize(this.getFontSize(this.yearOffset, this.isSmallUp))
        .fontWeight(this.getFontWeight())
        .fontColor(this.color)
        .fontFamily(this.getNumberFontFamily());
      Span(' ')
        .fontSize(6)
      Span(this.getChineseYearText())
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
    }
    .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
    .offset({
      x: this.isCenter() ? 14 : 0
    })
  }

  @Builder
  OtherLanguageYearOffsetText() {
    Text(this.getOtherYearText())
      .maxFontSize(28)
      .minFontSize(16)
      .maxLines(1)
      .fontWeight(this.getFontWeight())
      .fontColor(this.color)
      .fontFamily(this.getNumberFontFamily())
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
  }

  @Builder
  YearOffsetText() {
    if (this.isChinese) {
      this.ChineseYearOffsetText();
    } else {
      this.OtherLanguageYearOffsetText();
    }
  }

  @Builder
  ChineseDayOffsetText() {
    Text() {
      Span(this.dayOffset.toString())
        .fontSize(this.getFontSize(this.dayOffset, this.isSmallUp))
        .fontWeight(this.getFontWeight())
        .fontColor(this.color)
        .fontFamily(this.getNumberFontFamily());
      Span(' ')
        .fontSize(6)
      Span(this.type === 'days_later' ? '天后' : '天')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(this.color)
    }
    .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
    .offset({
      x: this.isCenter() ? this.getChineseDayOffset('left') : 0,
      y: this.getChineseFontIdOffsetY(this.dayOffset, this.isSmallUp, 'dayOffset')
    })
  }

  @Builder
  OtherLanguageDayOffsetText() {
    Text(this.getOtherDayText())
      .maxFontSize(28)
      .minFontSize(16)
      .maxLines(1)
      .fontWeight(this.getFontWeight())
      .fontColor(this.color)
      .fontFamily(this.getNumberFontFamily())
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
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
  ChineseYearDayOffsetText() {
    Column() {
      Text() {
        Span(this.yearOffset.toString())
          .fontSize(16)
          .fontWeight(this.getFontWeight())
          .fontColor(this.color)
          .fontFamily(this.getNumberFontFamily());
        Span(' ')
          .fontSize(6)
        Span(this.getChineseYearText())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.color)
      }
      .height(16)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)

      Text() {
        Span(this.remainingDays.toString())
          .fontSize(this.getFontSize(this.remainingDays, this.isSmallUp))
          .fontWeight(this.getFontWeight())
          .fontColor(this.color)
          .fontFamily(this.getNumberFontFamily());
        Span(' ')
          .fontSize(6)
        Span(this.type === 'days_later' ? '天后' : '天')
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.color)
      }
      .height(this.getFontSize(this.remainingDays, this.isSmallUp))
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      .offset({
        x: (this.isCenter() || this.isCard2x4()) ? this.getChineseDayOffset() : 0,
        y: this.getChineseFontIdOffsetY(this.dayOffset, this.isSmallUp, 'yearDayOffset')
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(this.horizontalAlign)
    .offset({
      // 大数字居中，整体上移
      y: this.getChineseYearDayOffsetTextOffsetY()
    })
  }

  @Builder
  OtherLanguageYearDayOffsetText() {
    Column() {
      Text($r('app.plural.in_anniversarys', this.yearOffset, this.yearOffset))
        .fontSize(16)
        .fontWeight(this.getFontWeight())
        .fontColor(this.color)
        .fontFamily(this.getNumberFontFamily())
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)

      Text($r('app.plural.in_days', this.remainingDays, this.remainingDays))
        .fontSize(24)
        .fontWeight(this.getFontWeight())
        .fontColor(this.color)
        .fontFamily(this.getNumberFontFamily())
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(this.horizontalAlign)
  }

  @Builder
  YearDayOffsetText() {
    if (this.isChinese) {
      this.ChineseYearDayOffsetText();
    } else {
      this.OtherLanguageYearDayOffsetText();
    }
  }

  /**
   * Tips：因编辑页有字体预览，此处逻辑变动，需要check ${ImportantCardEdit#refreshFontPreviewText()}
   */
  build() {
    Stack() {
      if (this.type === 'days_later') {
        // 倒数日
        if (this.yearOffset > 0 && this.rrule?.includes('FREQ=YEARLY')) {
          if (this.remainingDays === 0) {
            // 倒数日整年
            this.YearOffsetText();
          } else {
            // 倒数日非整年
            this.YearDayOffsetText();
          }
        } else if (this.dayOffset > 0) {
          // 倒数日不足一年或非每年循环
          this.DayOffsetText();
        }
      } else {
        // 纪念日
        if (this.remainingDays === 0 && this.yearOffset > 0) {
          // 纪念日整年
          this.YearOffsetText();
        } else if (this.dayOffset > 0) {
          // 纪念日非整年
          this.DayOffsetText();
        }
      }
    }
  }
}