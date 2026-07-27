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

import { PaintCache, TextArg, TextInfo } from '@app/common/src/main/ets/graphic/PaintCache';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { SingleMonthViewModel } from './SingleMonthViewModel';
import { drawing, text } from '@kit.ArkGraphics2D';
import { YearViewLayoutModel } from '../layoutmodel/YearViewLayoutModel';
import { DAY_PER_WEEK, DayData, DateUtil, DayMark, traceEvents, Log, I18nUtil,
  TextParagraphManager,
  NumberFormatManager,
  ARABIC_LANGUAGE} from '@app/common';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { i18n } from '@kit.LocalizationKit';

export enum LunarLineType {
  NONE, // 无
  MONTH_FIRST_DAY, // 除大年初一以外的其他月的初一
  YEAR_FIRST_DAY // 大年初一
}

// 总网格行数 对应Grid的属性rowsTemplate("2fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr")
const ROW_FR: number = 9;
// 总网格列数 对应Grid的属性columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
const COL_FR: number = 7;
// 月标题网格行数
const MONTH_TITLE_FR_COUNT: number = 2;
// 周标题网格行数
const WEEK_TITLE_FR_COUNT: number = 1;
// 当月标题颜色
const CUR_MONTH_TITLE_COLOR: Resource = $r('app.color.red_common');
// 其他月标题颜色
const OTHER_MONTH_TITLE_COLOR: Resource = $r('sys.color.ohos_id_color_text_primary');
// 周末周标题颜色
const WEEKEND_TITLE_COLOR: Resource = $r('sys.color.ohos_id_color_text_tertiary');
// 工作日周标题颜色
const WEEKDAY_TITLE_COLOR: Resource = $r('sys.color.ohos_id_color_text_primary');
// 周末日期颜色
const WEEKEND_DATE_COLOR: Resource = $r('sys.color.ohos_id_color_text_tertiary');
// 工作日日期颜色
const WEEKDAY_DATE_COLOR: Resource = $r('sys.color.ohos_id_color_text_primary');
// 休日期颜色
const RECESS_DATE_COLOR: Resource = $r('app.color.blue_common');
// 班日期颜色
const WORK_DATE_COLOR: Resource = $r('app.color.red_common');
// 今天日期颜色
const TODAY_DATE_COLOR: Resource = $r('sys.color.ohos_id_color_text_primary_contrary');
// 今天背景颜色
const TODAY_BG_COLOR: Resource = $r('app.color.red_common');
// 大年初一下划线颜色
const LUNAR_YEAR_FIRST_DAY_COLOR: Resource = $r('app.color.lunar_year_first_day_line_color');
// 其他月初一下划线颜色
const LUNAR_MONTH_FIRST_DAY_COLOR: Resource = $r('app.color.red_common');
const TAG: string = 'MonthPaint';

export class MonthPaint extends DrawModifier {
  private viewModel: SingleMonthViewModel | undefined = undefined;
  private cellWidth: number = 0;
  private cellHeight: number = 0;
  private cellHalfWidth: number = 0;
  private cellHalfHeight: number = 0;
  private isRTL: boolean = false; // 是否是语言为ar的右向
  private isAR: boolean = false; // 是否为阿拉伯语

  bindViewModel(viewModel: SingleMonthViewModel): void {
    this.viewModel = viewModel;
    const language = I18nUtil.getSystemLanguage();
    this.isRTL = i18n.isRTL(language);
    this.isAR = language.includes(ARABIC_LANGUAGE);
  }

  onLanguageChange(language: string) {
    this.isRTL = i18n.isRTL(language);
    this.isAR = language.includes(ARABIC_LANGUAGE);
    Log.info(TAG,`language = ${language},this.isRTL = ${this.isRTL}`)
  }

  getLunarLineType(showLunarInfo: boolean, day: DayData): LunarLineType {
    if (!showLunarInfo) {
      return LunarLineType.NONE;
    }

    if (!DateUtil.isNeedDisplayLunaMonth(day.solarYear)) {
      return LunarLineType.NONE;
    }

    if (day.isToday) { // 非选中 非今天 才显示
      return LunarLineType.NONE;
    }

    if (day.lunarDay === 1) {
      if (day.lunaMonth === 1) {
        return LunarLineType.YEAR_FIRST_DAY;
      }

      return LunarLineType.MONTH_FIRST_DAY;
    }
    return LunarLineType.NONE;
  }

  drawMonthTitle(canvas: drawing.Canvas, viewModel: SingleMonthViewModel): void {
    Log.info(TAG, 'drawMonthTitle start');
    const resource = viewModel.hasDisplayDay ? CUR_MONTH_TITLE_COLOR : OTHER_MONTH_TITLE_COLOR;
    const color = PaletteCache.instance().getColorV2(resource);
    const maxFontSizePx = YearViewLayoutModel.instance().monthLayout.value.monthFontSize * 7;
    const fontSize = Math.min(fp2px(YearViewLayoutModel.instance().monthLayout.value.monthFontSize), maxFontSizePx);
    const paintCache = PaintCache.instance();

    const textArg: TextArg = {
      text: viewModel.monthTitle,
      fontSize: fontSize,
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const textInfo = paintCache.getText(textArg);
    const x = 0;
    const y = this.cellHeight - textInfo.centerY - fontSize;
    let myTextStyle: text.TextStyle = {
      color: color,
      fontSize: fontSize,
      fontWeight: text.FontWeight.W600,
      baseline: 1,
    };
    Log.info(TAG, 'paragraphGraphBuilder start');
    const paragraphGraphBuilder = paintCache.getGraphBuilder();
    paragraphGraphBuilder.pushStyle(myTextStyle);
    paragraphGraphBuilder.addText(viewModel.monthTitle);
    const paragraph = paragraphGraphBuilder.build();
    // 布局
    paragraph.layoutSync(this.cellWidth * COL_FR);
    paragraph.paint(canvas, x, y);
  }

  drawWeekTitle(canvas: drawing.Canvas, viewModel: SingleMonthViewModel): void {
    Log.info(TAG, 'drawWeekTitle start');
    const startX = this.cellHalfWidth;
    const startY = this.cellHalfHeight + MONTH_TITLE_FR_COUNT * this.cellHeight;
    const maxFontSizePx = YearViewLayoutModel.instance().dayLayout.value.dayFontSize * 5;
    const fontSize = Math.min(fp2px(YearViewLayoutModel.instance().dayLayout.value.dayFontSize), maxFontSizePx);
    const paintCache = PaintCache.instance();
    const textArg: TextArg = {
      text: '',
      fontSize: fontSize,
      bold: false,
      fontFamily: paintCache.getFontFamilyPath(),
    };
    Log.info(TAG, 'weekTitles.forEach start');
    viewModel.weekTitles.forEach((title: string, index: number) => {
      const isWeekend = viewModel.weekends.includes((index + viewModel.startOfWeek) % DAY_PER_WEEK);
      const resource = isWeekend ? WEEKEND_TITLE_COLOR : WEEKDAY_TITLE_COLOR;
      const color = PaletteCache.instance().getColorV2(resource);
      textArg.text = title;
      const textInfo = paintCache.getText(textArg);

      const x = Math.floor(startX - textInfo.centerX + this.cellWidth * index);
      const y = startY - textInfo.centerY - fontSize;
      let myTextStyle: text.TextStyle = {
        color: color,
        fontSize: fontSize,
        fontWeight: text.FontWeight.W400,
        baseline: 1,
      };
      const paragraphGraphBuilder = paintCache.getGraphBuilder();
      paragraphGraphBuilder.pushStyle(myTextStyle);
      paragraphGraphBuilder.addText(title);
      const paragraph = paragraphGraphBuilder.build();
      paragraph.layoutSync(this.cellWidth);
      paragraph.paint(canvas, x, y);
    });
  }

  drawDate(canvas: drawing.Canvas, viewModel: SingleMonthViewModel): void {
    Log.info(TAG, 'drawDate start');
    const days = viewModel.monthInfo?.getDaysInfo();
    if (!days || days.length === 0) {
      Log.info(TAG, 'drawDate return');
      return;
    }

    const startX = this.cellHalfWidth;
    const startY = this.cellHalfHeight + (MONTH_TITLE_FR_COUNT + WEEK_TITLE_FR_COUNT) * this.cellHeight;
    const paintCache = PaintCache.instance();
    const brush = paintCache.getBrush();
    const maxFontSizePx = YearViewLayoutModel.instance().dayLayout.value.dayFontSize * 5;
    const fontSize = Math.min(fp2px(YearViewLayoutModel.instance().dayLayout.value.dayFontSize), maxFontSizePx);
    const textArg: TextArg = {
      text: '',
      fontSize: fontSize,
      bold: true,
      fontFamily: paintCache.getFontFamilyPath(),
    };
    Log.info(TAG, `days.forEach start this.isRTL = ${this.isRTL}` );
    days.forEach((day: DayData, index: number) => {
      textArg.text = NumberFormatManager.instance().numberFormat(day.solarDay);
      const isWeekday: boolean = viewModel.weekends.indexOf(day.getWeekDay()) === -1;
      const resource = this.getDateColor(day, isWeekday);
      const color = PaletteCache.instance().getColorV2(resource);
      const textInfo = paintCache.getText(textArg);
      const plainIndex = index + viewModel.dayItemSpace;
      const rowIndex = Math.floor(plainIndex / DAY_PER_WEEK);
      const colIndex = this.isRTL ? 6 - plainIndex % DAY_PER_WEEK : plainIndex % DAY_PER_WEEK;
      const centerX = startX + this.cellWidth * colIndex;
      const centerY = startY + this.cellHeight * rowIndex;
      const x = centerX - textInfo.centerX;
      const y = centerY - textInfo.centerY;

      if (day.isToday) {
        this.drawTodayBg(canvas, centerX, centerY);
      }
      Log.debug(TAG, `day.solarDay = ${day?.solarDay}, textArg.text = ${textArg?.text}, ` +
        `isAR = ${this.isAR}, x = ${x}, y = ${y}, width = ${textInfo?.width}, ` +
        `height = ${textInfo?.height}, fontSize = ${fontSize}`);
      if (this.isAR) {
        // 计算绘制起始点-相对中心偏移
        let offsetX = day.solarDay > 9 ? textInfo.width /2 - 10 : textInfo.width / 4;
        let offsetY = -textInfo.height;
        const paragraph = TextParagraphManager.instance()
          .getTextParagraph(textArg.text, textInfo.width, color, px2vp(fontSize));
        paragraph.paint(canvas, x + offsetX, y + offsetY);
      } else {
        brush.setColor(color);
        canvas.attachBrush(brush);
        canvas.drawTextBlob(textInfo.blob, x, y);
        canvas.detachBrush();
      }

      const lineType = this.getLunarLineType(viewModel.showLunarInfo, day);
      if (lineType === LunarLineType.NONE) {
        return;
      }

      this.drawLunarLine(canvas, textInfo, centerX, centerY, lineType, day.solarDay);
    });
    Log.info(TAG, 'days.forEach end');
  }

  // 获取日期颜色
  getDateColor(day: DayData, isWeekday: boolean): Resource {
    if (day.isToday) { // 当天反色
      return TODAY_DATE_COLOR;
    }
    if (isWeekday) { // 周末
      return WEEKDAY_DATE_COLOR;
    }
    return WEEKEND_DATE_COLOR;
  }

  drawTodayBg(canvas: drawing.Canvas, centerX: number, centerY: number): void {
    const brush = PaintCache.instance().getBrush();
    brush.setColor(PaletteCache.instance().getColorV2(TODAY_BG_COLOR));
    brush.setAntiAlias(true);
    canvas.attachBrush(brush);
    const selectCircle = YearViewLayoutModel.instance().dayLayout.value.selectCircle;
    const maxRadiusPx = selectCircle * 2.5;
    const radius = Math.ceil(Math.min(fp2px(selectCircle / 2), maxRadiusPx));
    canvas.drawCircle(centerX, centerY, radius);
    brush.setAntiAlias(false);
    canvas.detachBrush();
  }

  drawLunarLine(canvas: drawing.Canvas, textInfo: TextInfo, centerX: number,
                centerY: number, lineType: LunarLineType, day: number): void {
    const radius = vp2px(1);
    const diameter = Math.floor(radius * 2);
    const lunarLine = textInfo.width - (day > 9 ? vp2px(2) : 0);
    const len = Math.floor(lunarLine - diameter - (this.isAR ?  vp2px(10) : 0)); // UTF-8编码策略的阿拉伯语言会有偏差
    const leftX = Math.floor(centerX - len / 2);
    const rightX = leftX + len;
    const topY = Math.floor(centerY + textInfo.height / 2) - 1;
    const bottomY = topY + diameter;
    const paintCache = PaintCache.instance();
    const brush = paintCache.getBrush();

    const resource = lineType === LunarLineType.YEAR_FIRST_DAY ?
      LUNAR_YEAR_FIRST_DAY_COLOR : LUNAR_MONTH_FIRST_DAY_COLOR;
    const color = PaletteCache.instance().getColorV2(resource);
    brush.setColor(color);
    canvas.attachBrush(brush);
    const path = paintCache.getPath();
    path.reset();
    path.moveTo(leftX, topY);
    path.lineTo(rightX, topY);
    path.arcTo(rightX - radius, topY, rightX + radius, bottomY, -90, 180);
    path.lineTo(leftX, bottomY);
    path.arcTo(leftX - radius, topY, leftX + radius, bottomY, -90, -180);
    path.close();
    canvas.drawPath(path);
    canvas.detachBrush();
  }

  drawContent(drawContext: DrawContext): void {
    if (!this.viewModel) {
      return;
    }

    const canvas = drawContext.canvas;
    const size = drawContext.size;
    this.cellHeight = Math.floor(vp2px(size.height) / ROW_FR);
    this.cellWidth = Math.floor(vp2px(size.width) / COL_FR);
    this.cellHalfWidth = Math.floor(this.cellWidth / 2);
    this.cellHalfHeight = Math.floor(this.cellHeight / 2);
    hiTraceMeter.startTrace(traceEvents.drawMonthTitle, 0);
    this.drawMonthTitle(canvas, this.viewModel);
    hiTraceMeter.finishTrace(traceEvents.drawMonthTitle, 0);

    hiTraceMeter.startTrace(traceEvents.drawWeekTitle, 0);
    this.drawWeekTitle(canvas, this.viewModel);
    hiTraceMeter.finishTrace(traceEvents.drawWeekTitle, 0);

    hiTraceMeter.startTrace(traceEvents.drawDate, 0);
    this.drawDate(canvas, this.viewModel);
    hiTraceMeter.finishTrace(traceEvents.drawDate, 0);
  }
}