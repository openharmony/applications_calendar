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
import { BigFontSize, CalendarDate, CompId, isChineseCalendar, Log, LunarDateUtil } from '@app/common';
import { CommonProp } from '../layoutmodel/YearViewLayoutProp';
import { YearViewLayoutModel } from '../layoutmodel/YearViewLayoutModel';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = "[YearView][YearLegend]";

/**
 * Year Legend
 *
 * @since 2022-03-01
 */

@Component
export struct YearLegend {
  @Watch('onDisplayDateChange') @Prop displayDate: number = 0;

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  @Consume commonProp: CommonProp;

  // 其它历法
  @Prop subscriptionCalendar: number = -1;

  @State lunarYearText: string = "";

  // 显示/隐藏班休信息
  @StorageProp('isRecessToggleOn') isRecessToggleOn: boolean = false;

  // 系统地区
  @StorageProp('systemRegion') systemRegion: string = 'CN';

  aboutToAppear() {
    this.onDisplayDateChange()
  }

  onLanguageChange(): void {
    const yearNum: number = new CalendarDate(this.displayDate).getFullYear();
    this.lunarYearText = LunarDateUtil.getChineseYearReal(yearNum, this.language);
    Log.info(TAG, `onLanguageChange: ${this.language} ${this.lunarYearText}`);
  }

  onDisplayDateChange() {
    const yearNum: number = new CalendarDate(this.displayDate).getFullYear();
    this.lunarYearText = LunarDateUtil.getChineseYearReal(yearNum, this.language);
    Log.info(TAG, `onDisplayDateChange: ${yearNum} ${this.lunarYearText}`);
  }

  /**
   * 根据年份判断是否显示天干地支和农历图例
   */
  showLunarLegend(displayDate: number): boolean {
    const displayYear = new CalendarDate(displayDate).getFullYear();
    return displayYear >= 1900 && displayYear <= 2100;
  }

  public showLegend(systemRegion: string, isRecessToggleOn: boolean, hasRecess: boolean, displayDate: number): boolean {
    if (systemRegion !== 'CN') {
      Log.info(TAG, 'systemRegion not CN');
      return false;
    }
    if (!isRecessToggleOn) {
      Log.info(TAG, 'recessToggle not On');
      return false;
    }
    if (!hasRecess) {
      const displayYear = new CalendarDate(displayDate).getFullYear();
      Log.info(TAG, `nowYear has No Recess ${displayYear}`);
      return false;
    }
    return true;
  }

  build() {
    Row() {
      if (this.showLunarLegend(this.displayDate)) {
        Line()
          .strokeWidth(6)
          .height(2)
          .backgroundColor($r('app.color.lunar_year_first_day_line_color'))// 大年初一标签颜色固定值
          .borderRadius(1)
          .margin({ end: LengthMetrics.vp(4) })
        Text(this.lunarYearText)
          .fontWeight(FontWeight.Regular)
          .fontSize(YearViewLayoutModel.instance().monthLayout.value.legendFontSize)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
          .opacity(0.6)
          .margin({ end: LengthMetrics.vp(8) })
          .id(CompId.CHINESE_ZODIAC_LEGEND)
        Line()
          .strokeWidth(6)
          .height(2)
          .backgroundColor(this.commonProp.themeColor)
          .borderRadius(1)
          .margin({ end: LengthMetrics.vp(4) })
        Text('农历初一')
          .fontSize(YearViewLayoutModel.instance().monthLayout.value.legendFontSize)
          .fontWeight(FontWeight.Regular)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
          .opacity(0.6)
          .id(CompId.LUNAR_LEGEND)
        // 班休,在开关关闭或者地区不是CN时关闭班休显示
        if (this.showLegend(this.systemRegion, this.isRecessToggleOn, this.commonProp.hasRecess, this.displayDate)) {
          Text($r('app.string.off'))
            .fontSize(YearViewLayoutModel.instance().monthLayout.value.legendFontSize)
            .fontWeight(FontWeight.Regular)
            .fontColor($r('app.color.blue_common'))
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
            .margin({ start: LengthMetrics.vp(8) })
          Text($r('app.string.work'))
            .fontSize(YearViewLayoutModel.instance().monthLayout.value.legendFontSize)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.commonProp.themeColor)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
            .margin({ start: LengthMetrics.vp(8) })
        }
      }
    }
    .id(CompId.YEAR_LEGEND)
    .height(26)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .visibility(isChineseCalendar(this.subscriptionCalendar) ? Visibility.Visible : Visibility.None)
    .margin({ start: LengthMetrics.vp(2), end: LengthMetrics.vp(16) })
  }
}
