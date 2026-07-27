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
import { beforeAll, beforeEach, describe, expect, it} from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import { DateInfo, DateManager, DayData, DayMark, Log } from '@app/common/index';
import { SingleDayViewModel } from '@app/feature.monthview';
import { ColorType } from '@app/common/src/main/ets/graphic/PaletteCache';
import { MonthViewLayoutModel } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutModel';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';
import { image } from '@kit.ImageKit';
import { drawing } from '@kit.ArkGraphics2D';
import { DayCellLayout } from '@app/feature.monthview/src/main/ets/layoutmodel/DayCellLayoutRule';

const TAG = 'MonthViewSingleDayViewModelTest';
const driver = Driver.create();

let viewModel: SingleDayViewModel;

export default function MonthViewSingleDayViewModelTest() {

  let crossLineLunarDayData = DateManager.getInstance().getDayData(2111, 1, 1) as DayData;

  describe('MonthViewSingleDayViewModelTest', () => {
    beforeAll(async (done: Function) => {
      Log.info(TAG, `MonthViewSingleDayViewModelTest beforeAll`);
      done();
    })

    it('updateLunarLineProp_crossline', 0, () => {
      viewModel = new SingleDayViewModel(1, crossLineLunarDayData);
      viewModel.updateLunarLineProp(true);
      expect(viewModel.showLunarLine).assertFalse();
    })

    it('updateLunarLineProp_showcalendar', 0, () => {
      viewModel = new SingleDayViewModel(1, crossLineLunarDayData);
      viewModel.updateLunarLineProp(false);
      expect(viewModel.showLunarLine).assertFalse();
    })

    it('getAccessibilityTextTest_1',0,()=>{
      viewModel = new SingleDayViewModel(1, crossLineLunarDayData);
      viewModel.isSelect = true;
      viewModel.isToday = true;
      expect(viewModel.getAccessibilityText()).assertEqual('今天2024年11月30日星期六农历十月三十')
    })
  })

  describe('DayDrawviewModelTest', () => {
    beforeEach(() => {
      viewModel = new SingleDayViewModel(1, crossLineLunarDayData)
    })

    // UX建模规则：非当月
    it('DateColor_isCurrentMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = false;
      viewModel.update();
      expect(viewModel.getDateColor()).assertEqual(ColorType.TERTIARY_OPACITY_40);
    })

    // UX建模规则：当月 非当天 非周末
    it('DateColor_not_today_not_weekend', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.isToday = false;
      viewModel.isWeekends = false;
      viewModel.update();
      expect(viewModel.getDateColor()).assertEqual(ColorType.PRIMARY);
    })

    // UX建模规则：当月 非当天 周末
    it('DateColor_not_today_weekend', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.isToday = false;
      viewModel.isWeekends = true;
      viewModel.update();
      expect(viewModel.getDateColor()).assertEqual(ColorType.TERTIARY);
    })

    // UX建模规则：当月 当天 未选中
    it('DateColor_today_not_select', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.isToday = true;
      viewModel.isSelect = false;
      viewModel.update();
      expect(viewModel.getDateColor()).assertEqual(ColorType.THEME);
    })

    // UX建模规则：当月 当天 选中
    it('DateColor_today_select', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.isToday = true;
      viewModel.isSelect = true;
      viewModel.update()
      expect(viewModel.getDateColor()).assertEqual(ColorType.PRIMARY_CONTRARY);
    })
  })
  describe('RecessColor', () => {
    // UX建模规则：班休 当月 休 蓝色
    it('curMonth_off', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.mark = DayMark.OFF;
      viewModel.update()
      expect(viewModel.getRecessColor()).assertEqual(ColorType.BLUE);
    })

    // UX建模规则：班休 当月 班 主题色
    it('curMonth_work', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = true;
      viewModel.mark = DayMark.WORK;
      viewModel.update()
      expect(viewModel.getRecessColor()).assertEqual(ColorType.THEME);
    })

    // UX建模规则：班休 非当月 休 蓝色 透明度0.4
    it('not_curMonth_off', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = false;
      viewModel.mark = DayMark.OFF;
      viewModel.update()
      expect(viewModel.getRecessColor()).assertEqual(ColorType.BLUE_OPACITY_40);
    })

    // UX建模规则：班休 非当月 班 主题色 透明度0.4
    it('not_curMonth_work', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isCurrentMonth = false;
      viewModel.mark = DayMark.WORK;
      viewModel.update()
      expect(viewModel.getRecessColor()).assertEqual(ColorType.THEME_OPACITY_40);
    })


    // UX建模规则：班休 当天 被选中
    it('today_select', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = true;
      viewModel.isSelect = true;
      viewModel.update()
      expect(viewModel.getRecessColor()).assertEqual(ColorType.THEME_OPACITY_40);
    })
  })

  describe('TagColor', () => {
    // UX建模规则 标记颜色 当天 选中 且 上下布局  一级文本反色
    it('today_select_isVerticalCell', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      MonthViewLayoutModel.getInstance().dayLayout.value.isVerticalCell = true;
      viewModel.isToday = true;
      viewModel.isSelect = true;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.PRIMARY_CONTRARY);
    })

    it('hasFestivals_today_curMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      MonthViewLayoutModel.getInstance().dayLayout.value.isVerticalCell = false;
      viewModel.isToday = true;
      viewModel.hasFestivals = true;
      viewModel.isCurrentMonth = true;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.THEME);
    })

    it('hasFestivals_today_not_curMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = true;
      viewModel.hasFestivals = true;
      viewModel.isCurrentMonth = false;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.THEME_OPACITY_40);
    })

    it('hasNoFestivals_today_not_curMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = true;
      viewModel.hasFestivals = true;
      viewModel.isCurrentMonth = false;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.THEME_OPACITY_40);
    })

    it('hasNoFestivals_today_curMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = true;
      viewModel.hasFestivals = false;
      viewModel.isCurrentMonth = true;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.THEME);
    })

    it('hasNoFestivals_NoToday_curMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = false;
      viewModel.hasFestivals = false;
      viewModel.isCurrentMonth = true;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.TERTIARY);
    })

    it('hasNoFestivals_NoToday_NoCurMonth', 0, () => {
      let viewModel = new SingleDayViewModel(1);
      viewModel.isToday = false;
      viewModel.hasFestivals = false;
      viewModel.isCurrentMonth = false;
      viewModel.update()
      expect(viewModel.getTagColor()).assertEqual(ColorType.TERTIARY_OPACITY_40);
    })
  })

  describe('DrawContentTest', () => {
    // 因canvas绘画目前无验证方法,故只是跑一遍防止异常
    it('drawContent1', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2,dayData, dateInfo);
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.drawCircle(canvas, size);
      viewModel.isSelect = true;
      viewModel.drawCircle(canvas, size);
      viewModel.isToday = true;
      viewModel.drawCircle(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('drawContent2', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2,dayData, dateInfo);
      viewModel.layout = new DayCellLayout();
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.layout.isVerticalCell = false;
      viewModel.drawDate(canvas, size);
      viewModel.layout.isVerticalCell = false;
      viewModel.drawDate(canvas, size);
      viewModel.gridview = true;
      viewModel.drawDate(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('drawContent3', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2,dayData, dateInfo);
      viewModel.layout = new DayCellLayout();
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.showRecessData = false;
      viewModel.drawRecess(canvas, size);
      viewModel.showRecessData = true;
      viewModel.layout.isVerticalCell = false;
      viewModel.drawRecess(canvas, size);
      viewModel.layout.isVerticalCell = true;
      viewModel.drawRecess(canvas, size);
      viewModel.gridview = true;
      viewModel.drawRecess(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('drawContent4', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,1);
      const dateInfo = new DateInfo(2024,10,40,1);
      viewModel = new SingleDayViewModel(1,dayData, dateInfo);
      viewModel.layout = new DayCellLayout();
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.layout.isVerticalCell = true;
      viewModel.showTagText = false;
      viewModel.drawTagText(canvas, size);
      viewModel.showTagText = true;
      viewModel.showRecessData = false;
      viewModel.drawTagText(canvas, size);
      viewModel.showRecessData = true;
      viewModel.drawTagText(canvas, size);
      viewModel.layout.isVerticalCell = true;
      viewModel.drawTagText(canvas, size);
      viewModel.gridview = true;
      viewModel.drawTagText(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('drawContent5', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2,dayData, dateInfo);
      viewModel.layout = new DayCellLayout();
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.isExceptHolidaysInstancesFlags = false;
      MonthViewLayoutModel.getInstance().frameProp.value.isSmall = true;
      MonthlyViewStateManager.getInstance().state.isAgendaRowMini = true;
      viewModel.drawAgendaDot(canvas, size);
      MonthViewLayoutModel.getInstance().frameProp.value.isSmall = false;
      MonthlyViewStateManager.getInstance().state.isAgendaRowMini = false;
      viewModel.drawAgendaDot(canvas, size);
      MonthlyViewStateManager.getInstance().state.isAgendaRowMini = true;
      viewModel.drawAgendaDot(canvas, size);
      viewModel.isExceptHolidaysInstancesFlags = true;
      viewModel.drawAgendaDot(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('drawContent6', 0,() => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2,dayData, dateInfo);
      viewModel.layout = new DayCellLayout();
      const color: ArrayBuffer = new ArrayBuffer(160000);
      const size: Size = {height: 200, width: 200};
      let opts: image.InitializationOptions = { editable: true, pixelFormat: 3, size: size }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let canvas = new drawing.Canvas(pixelMap);
      viewModel.showLunarLine = false;
      viewModel.drawLunarLine(canvas, size);
      viewModel.layout.isVerticalCell = false;
      viewModel.drawLunarLine(canvas, size);
      viewModel.layout.isVerticalCell = true;
      viewModel.drawLunarLine(canvas, size);
      hasError = false;
      expect(hasError).assertFalse();
      pixelMap?.release();
    })

    it('onClickChangeDisplayDate_01', 0, () => {
      let hasError: boolean = true;
      viewModel = new SingleDayViewModel(2, undefined, undefined);
      viewModel.onClickChangeDisplayDate(false, 'test');
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('onClickChangeDisplayDate_02', 0, () => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2, dayData, dateInfo);
      viewModel.onClickChangeDisplayDate(true, 'test');
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('onClickChangeDisplayDate_03', 0, async () => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2, dayData, dateInfo);
      viewModel.onClickChangeDisplayDate(false, 'test');
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('onClickChangeDisplayDate_04', 0, async () => {
      let hasError: boolean = true;
      const dayData = new DayData(2024,10,11);
      const dateInfo = new DateInfo(2024,10,41,11);
      viewModel = new SingleDayViewModel(2, dayData, dateInfo);
      viewModel.isSelect = true;
      viewModel.onClickChangeDisplayDate(false, 'test', true);
      hasError = false;
      expect(hasError).assertFalse();
    });
  })
}