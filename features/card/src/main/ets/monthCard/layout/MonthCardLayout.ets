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

import { FormName } from '../../utils/FormName';

/**
 * 月视图的布局类
 */
export class MonthCardLayout {
  public cardName: FormName
  public weekTitleLayout: WeekTitleLayout; // 月视图卡片周题的布局类
  public monthViewLayout: MonthViewLayout; // 月视图卡片周题的布局类
  constructor(
    cardName: FormName,
    weekTitleLayout: WeekTitleLayout,
    monthViewLayout: MonthViewLayout
  ) {
    this.cardName = cardName;
    this.weekTitleLayout = weekTitleLayout;
    this.monthViewLayout = monthViewLayout;
  }
}

export default class MonthCardLayoutBuilder {
  static createLayout(cardName: FormName): MonthCardLayout {
    if (cardName === FormName.MONTH_CARD_2X2) {
      return new MonthCardLayout(
        FormName.MONTH_CARD_2X2,
        new WeekTitleLayout2x2(),
        new MonthViewLayout2x2(),
      );
    } else if (cardName === FormName.MONTH_CARD_4X4) {
      return new MonthCardLayout(
        FormName.MONTH_CARD_4X4,
        new WeekTitleLayout4x4(),
        new MonthViewLayout4x4(),
      );
    } else {
      return new MonthCardLayout(
        FormName.DEFAULT,
        new WeekTitleLayout2x2(),
        new MonthViewLayout2x2(),
      );
    }
  }
}


export interface MonthViewLayout {
  // 月视图日期字体 大小
  minFontSize: number; // 月视图文字的最小字体尺寸
  maxFontSize: number; // 月视图文字的最大字体尺寸
  // 月视图日期字体 透明度
  isTodayOpacity: number, // 单日宫格字体，透明度，是今天
  isRecessOpacity: number, // 单日宫格字体，透明度，是班休
  isWeekendsOpacity: Resource, // 单日宫格字体，透明度，是周末
  notCurrentMonthOpacity: Resource, // 单日宫格字体，透明度，非当月
  // 月视图日期文字 颜色
  isTodayColor: Resource, // 单日宫格字体，颜色，是今天
  defaultColor: Resource | Color, // 单日宫格字体，颜色，当月非今天默认颜色
  workDayColor: Resource, // 单日宫格字体，颜色，"班"
  restDayColor: Resource, // 单日宫格字体，颜色，"休"
  notCurrentMonthColor: Resource, // 单日宫格字体，颜色，非当月
}

export interface WeekTitleLayout {
  weekTitleFontSize: number; // 卡片周题字体大小
  weekTitleMargin: Margin; // 卡片字体的边距
  titleHeight: Length; // 卡片宫格的高度
  titleWidth: Length; // 卡片宫格的宽度
  titleFontSize: number; // 卡片宫格的宽度
  titleFontColor: ResourceColor; // 卡片宫格的宽度
}

export class MonthViewLayout2x2 implements MonthViewLayout {
  public minFontSize: number = 10; // 月视图文字的最小字体尺寸
  public maxFontSize: number = 10; // 月视图文字的最大字体尺寸
  public isTodayOpacity: number = 1; // 单日宫格字体，透明度，是今天
  public isRecessOpacity: number = 1; // 单日宫格字体，透明度，是班休
  public isWeekendsOpacity: Resource = $r('sys.float.alpha_tertiary'); // 单日宫格字体，透明度，是周末
  public notCurrentMonthOpacity: Resource = $r('sys.float.alpha_tertiary'); // 单日宫格字体，透明度，非当月

  public isTodayColor: Resource = $r('sys.color.ohos_fa_text_contrary'); // 单日宫格字体，颜色，是今天
  public defaultColor: Resource = $r('sys.color.font_primary'); // 单日宫格字体，颜色，当月非今天默认颜色
  public workDayColor: Resource = $r('app.color.red_common'); // 单日宫格字体，颜色，"班"
  public restDayColor: Resource = $r('app.color.blue_common'); // 单日宫格字体，颜色，"休"
  public notCurrentMonthColor: Resource = $r('sys.color.font_tertiary'); // 单日宫格字体，颜色，非当月
}

export class MonthViewLayout4x4 implements MonthViewLayout {
  public minFontSize: number = 10; // 月视图文字的最小字体尺寸
  public maxFontSize: number = 10; // 月视图文字的最大字体尺寸
  public isTodayOpacity: number = 1; // 单日宫格字体，透明度，是今天
  public isRecessOpacity: number = 1; // 单日宫格字体，透明度，是班休
  public isWeekendsOpacity: Resource = $r('sys.float.alpha_tertiary'); // 单日宫格字体，透明度，是周末
  public notCurrentMonthOpacity: Resource = $r('sys.float.alpha_tertiary'); // 单日宫格字体，透明度，非当月

  public isTodayColor: Resource = $r('sys.color.ohos_fa_text_contrary'); // 单日宫格字体，颜色，是今天
  public defaultColor: Resource = $r('sys.color.font_primary'); // 单日宫格字体，颜色，当月非今天默认颜色
  public workDayColor: Resource = $r('app.color.red_common'); // 单日宫格字体，颜色，"班"
  public restDayColor: Resource = $r('app.color.blue_common'); // 单日宫格字体，颜色，"休"
  public notCurrentMonthColor: Resource = $r('sys.color.font_tertiary'); // 单日宫格字体，颜色，非当月
}

export class MonthViewLayoutExt implements MonthViewLayout {
  public minFontSize: number = 4; // 月视图文字的最小字体尺寸
  public maxFontSize: number = 7; // 月视图文字的最大字体尺寸
  public isTodayOpacity: number = 1; // 单日宫格字体，透明度，是今天
  public isRecessOpacity: number = 1; // 单日宫格字体，透明度，是班休
  public isWeekendsOpacity: Resource = $r('sys.float.alpha_secondary'); // 单日宫格字体，透明度，是周末
  public notCurrentMonthOpacity: Resource = $r('sys.float.alpha_tertiary'); // 单日宫格字体，透明度，非当月

  public isTodayColor: Resource = $r('sys.color.ohos_fa_text_contrary'); // 单日宫格字体，颜色，是今天
  public defaultColor: Resource | Color = Color.White; // 单日宫格字体，颜色，当月非今天默认颜色
  public workDayColor: Resource = $r('app.color.red_common'); // 单日宫格字体，颜色，"班"
  public restDayColor: Resource = $r('app.color.blue_common'); // 单日宫格字体，颜色，"休"
  public notCurrentMonthColor: Resource = $r('sys.color.font_tertiary'); // 单日宫格字体，颜色，非当月
}

export class WeekTitleLayout2x2 implements WeekTitleLayout {
  public weekTitleFontSize: number = 12;
  public weekTitleMargin: Margin = { top: 2, bottom: 8 };
  public titleHeight: Length = '12vp';
  public titleWidth: Length = '14%';
  public titleFontSize: number = 10;
  public titleFontColor: ResourceColor = $r('sys.color.font_primary');
}

export class WeekTitleLayout4x4 implements WeekTitleLayout {
  public weekTitleFontSize: number = 12;
  public weekTitleMargin: Margin = {
    left: 12,
    right: 12,
    top: 12,
  };
  public titleHeight: Length = 14;
  public titleWidth: Length = '14%';
  public titleFontSize: number = 10;
  public titleFontColor: ResourceColor = $r('sys.color.font_primary');
}

export class WeekTitleLayoutExt implements WeekTitleLayout {
  public weekTitleFontSize: number = 12;
  public weekTitleMargin: Margin = { bottom: '2%' };
  public titleHeight: Length = '14%';
  public titleWidth: Length = '14%';
  public titleFontSize: number = 4;
  public titleFontColor: ResourceColor = Color.White;
}