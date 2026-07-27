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
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { DateManager, DayData, GlobalThis, DayMark } from '@app/common';
import { LunarLineType, MonthPaint } from '@app/feature.yearview/src/main/ets/viewmodel/MonthPaint';
import { image } from '@kit.ImageKit';
import { drawing } from '@kit.ArkGraphics2D';
import { SingleMonthViewModel } from '@app/feature.yearview/src/main/ets/viewmodel/SingleMonthViewModel';
import { ColorType, PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { afterEach } from '@ohos/hypium/src/main/interface';

export default function MonthPaintTest() {
  let lunarYearDayData = DateManager.getInstance().getDayData(2023, 1, 22) as DayData;
  let lunarDayData = DateManager.getInstance().getDayData(2023, 2, 20) as DayData;
  let commonDayData = DateManager.getInstance().getDayData(2023, 1, 1) as DayData;
  let crossLineLunarDayData = DateManager.getInstance().getDayData(2111, 1, 1) as DayData;
  const color = new ArrayBuffer(96);
  let opts : image.InitializationOptions = {
    editable: true,
    pixelFormat: 3,
    size: {
      height: 4,
      width: 6
    }
  }
  const pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
  const canvas: drawing.Canvas = new drawing.Canvas(pixelMap)

  describe('getLunarType', () => {
    let monthPaint: MonthPaint;

    // 班休颜色
    const DATE_COLOR_1 = 4294967295;
    const DATE_COLOR_2 = 4278868471;
    const DATE_COLOR_3 = 4294402117;
    const DATE_COLOR_4 = 3841982464;
    const DATE_COLOR_5 = 1711276032;

    beforeEach(() => {
      monthPaint = new MonthPaint();
      lunarYearDayData.isSelected = false;
      lunarYearDayData.isToday = false;
      lunarDayData.isSelected = false;
      lunarDayData.isToday = false;
    })

    afterEach(() => {
      pixelMap?.release();
    })

    // 非1900 1.1 - 2100 12.31
    it('cross_line_lunar', 0, () => {
      const type = monthPaint.getLunarLineType(false, crossLineLunarDayData);
      expect(type).assertEqual(LunarLineType.NONE);
    })

    // 非选中 非今天 非初一 非周末
    it('not_show_lunar', 0, () => {
      const type = monthPaint.getLunarLineType(false, commonDayData);
      expect(type).assertEqual(LunarLineType.NONE);
    })

    // 非选中 非今天 非初一 非周末
    it('common_day', 0, () => {
      const type = monthPaint.getLunarLineType(true, commonDayData);
      expect(type).assertEqual(LunarLineType.NONE);
    })

    // 大年初一
    it('lunar_new_year_day', 0, () => {
      const type = monthPaint.getLunarLineType(true, lunarYearDayData);
      expect(type).assertEqual(LunarLineType.YEAR_FIRST_DAY);
    })

    // 二月初一
    it('lunar_first_day', 0, () => {
      const type = monthPaint.getLunarLineType(true, lunarDayData);
      expect(type).assertEqual(LunarLineType.MONTH_FIRST_DAY);
    })

    // 初一 今天  不显示农历
    it('lunar_first_day_today', 0, () => {
      lunarDayData.isToday = true;
      const type = monthPaint.getLunarLineType(true, lunarDayData);
      expect(type).assertEqual(LunarLineType.NONE);
    })

    // 测试绘制,由于绘制无法获取结果故只是执行防止报错
    it('test_drawing', 0, () => {
      let hasError: boolean = true;
      let mocker: MockKit = new MockKit();
      const paletteCache = PaletteCache.instance();
      // resourceId无法获取,故进行mock返回固定值
      let mockFunc1: Function = mocker.mockFunc(paletteCache, paletteCache.getColorV2);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(paletteCache.getColor(ColorType.BLUE));
      const viewModel = new SingleMonthViewModel(2025, 1);
      monthPaint.drawMonthTitle(canvas, viewModel);
      monthPaint.drawWeekTitle(canvas, viewModel);
      monthPaint.drawDate(canvas, viewModel);
      hasError = false;
      expect(hasError).assertFalse()
    })

    // 当天反色
    it('getDateColor_1', 0, () => {
      lunarDayData.isToday = true;
      expect(GlobalThis.getResourceColor(monthPaint.getDateColor(lunarDayData, false)))
        .assertEqual(DATE_COLOR_1);
    });

    it('getDateColor_2', 0, () => {
      lunarDayData.isToday = false;
      lunarDayData.dayMark = DayMark.OFF;
      expect(GlobalThis.getResourceColor(monthPaint.getDateColor(lunarDayData, true)))
        .assertEqual(DATE_COLOR_2);
    });

    // 班休
    it('getDateColor_3', 0, () => {
      lunarDayData.isToday = false;
      lunarDayData.dayMark = DayMark.WORK;
      expect(GlobalThis.getResourceColor(monthPaint.getDateColor(lunarDayData, true)))
        .assertEqual(DATE_COLOR_3);
    });

    it('getDateColor_4', 0, () => {
      lunarDayData.isToday = false;
      expect(GlobalThis.getResourceColor(monthPaint.getDateColor(lunarDayData, false)))
        .assertEqual(DATE_COLOR_4);
    });

    // 周末
    it('getDateColor_5', 0, () => {
      lunarDayData.isToday = false;
      expect(GlobalThis.getResourceColor(monthPaint.getDateColor(lunarDayData, false)))
        .assertEqual(DATE_COLOR_5);
    });
  })
}