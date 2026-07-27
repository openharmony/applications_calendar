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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { AgendaEventInfo,
  CalendarContract,
  CalendarDate,
  InstanceService, MILLS_PER_DAY, SubscriptionCalendar, TabType } from '@app/common';
import { GanttLineViewModel, GanttViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/GanttViewModel';
import { RootViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/RootViewModel';
import { GanttBlockViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/GanttBlockViewModel';
import { FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { DayModel } from '@app/feature.weekview/src/main/ets/model/DayModel';
import { TestUtil } from '../../utils/TestUtil';
import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { DateRange } from '@app/common/src/main/ets/date/DateRange';
import { AgendaModel } from '@app/feature.weekview/src/main/ets/model/AgendaModel';

export default function GanttViewModelTest() {
  describe('GanttViewModelTest', () => {
    // GanttLineViewModel start
    it('hideLineInOtherRange', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.hideLineInOtherRange()
      expect(gantLine.hiddenHourIndex).assertEqual(-1);
      done();
    })

    // 小于AFTERNOON_RATIO
    it('updateLinePosition_less', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.updateLinePosition(10);
      expect(gantLine.morningLine).assertEqual(10);
      done();
    })

    // 大于AFTERNOON_RATIO
    it('updateLinePosition_more', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.updateLinePosition(20);
      expect(gantLine.morningLine).assertEqual(gantLine.AFTERNOON_RATIO - 1);
      done();
    })

    it('updateLineHidden', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.updateLineHidden(1, 1, 1);
      expect(gantLine.hiddenHourIndex).assertEqual(-1);
      done();
    })

    it('updateGanttLineScale', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.updateGanttLineScale(0.5);
      expect(gantLine.gridCellHeight).assertEqual(30);
      done();
    })

    it('setOriginalGanttLineScale', 0, async (done: Function) => {
      let gantLine = new GanttLineViewModel();
      gantLine.setOriginalGanttLineScale();
      expect(gantLine.oldGridCellHeight).assertEqual(60);
      done();
    })
    // GanttLineViewModel end

    // GanttViewModel start
    it('constructor_phone', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      expect(ganttViewModel.blockSpace).assertEqual(1.5);
      done();
    })

    it('constructor_not_phone', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      let mock: MockKit = new MockKit();
      let isNeedAdapt: Function = mock.mockFunc(rootVM, rootVM.isNeedAdapt);
      when(isNeedAdapt)(ArgumentMatchers.any).afterReturn(true);
      let ganttViewModel = new GanttViewModel(rootVM);
      expect(ganttViewModel.blockSpace).assertEqual(1.5);
      done();
    })

    it('resetLayout', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const height = 100;
      ganttViewModel.resetLayout(height)
      expect(ganttViewModel.height).assertEqual(height);
      done();
    })

    it('updateDayModels', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      let mock: MockKit = new MockKit();
      mock.mockFunc(ganttViewModel, ganttViewModel.updateTimeLine);
      ganttViewModel.updateDayModels([new DayModel(new CalendarDate(2024, 1, 1))])
      mock.verify('updateTimeLine', []).once();
      done();
    })

    it('updateBlocks', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      ganttViewModel.updateBlocks()
      expect(ganttViewModel.allDayBlocks.length).assertEqual(0);
      done();
    })

    it('getDefaultChosenInfo_01', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      expect(ganttViewModel.getDefaultChosenInfo()).assertUndefined();
      done();
    })

    it('getDefaultChosenInfo_02', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      expect(ganttViewModel.getDefaultChosenInfo()).assertUndefined();
      done();
    })

    it('divideRefreshBlocksFocus', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      expect(ganttViewModel.divideRefreshBlocksFocus()).assertUndefined();
      done();
    })

    it('divideRefreshBlocksFocus_01', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      expect(ganttViewModel.divideRefreshBlocksFocus(1)).assertUndefined();
      done();
    })

    it('updateLineModel', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const height = 100;
      const dayModel = new DayModel(new CalendarDate());
      dayModel.range = {
        start: new CalendarDate().setHours(0, 0, 0, 0), end: new CalendarDate().setHours(0, 0, 0, 0) + MILLS_PER_DAY
      };
      ganttViewModel.updateDayModels([dayModel])
      ganttViewModel.resetLayout(height)
      expect(ganttViewModel.gridCellHeight).assertEqual(ganttViewModel.ganttLineVM.gridCellHeight);
      done();
    })

    it('showAddBlock', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      rootVM.isDivide = false;
      let ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.showAddAgendaBlock(1, 1);
      expect(ganttViewModel.addBlockVM.isAddShow).assertTrue();
      done();
    })

    it('destroy', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.destroy();
      let refreshTimer: number = TestUtil.getPrivateAttribute(ganttViewModel, 'refreshTimer');
      expect(refreshTimer).assertEqual(-1);
      done();
    })

    it('destroy_not_empty', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.destroy();
      let newRefreshTimer = setTimeout(() => {
      }, 1000);
      TestUtil.setPrivateAttribute(ganttViewModel, 'refreshTimer', newRefreshTimer);
      let refreshTimer: number = TestUtil.getPrivateAttribute(ganttViewModel, 'refreshTimer');
      expect(refreshTimer == -1).assertFalse();
      done();
    })

    it('resetLayout_need_adapt', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      TestUtil.setPrivateAttribute(rootViewModel, 'ganttNeedAdapt', 1);
      const height = 100;
      ganttViewModel.resetLayout(height)
      expect(ganttViewModel.height).assertEqual(height);
      done();
    })

    it('resetLayout_day_type', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.DAY);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      TestUtil.setPrivateAttribute(rootViewModel, 'ganttNeedAdapt', 1);
      const height = 100;
      ganttViewModel.resetLayout(height)
      expect(ganttViewModel.height).assertEqual(height);
      done();
    })

    it('updateBlocksExpired', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const block2 = new GanttBlockViewModel();
      allDayBlocks.push(block1);
      normalBlocks.push(block2);
      ganttViewModel.allDayBlocks = allDayBlocks;
      ganttViewModel.normalBlocks = normalBlocks;
      ganttViewModel.updateBlocksExpired()
      expect(ganttViewModel.allDayBlocks.length).assertEqual(1);
      done();
    })

    it('calcNextRefresh_not_range', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      ganttViewModel.calcNextRefresh()
      let refreshTimer: number = TestUtil.getPrivateAttribute(ganttViewModel, 'refreshTimer');
      expect(refreshTimer == -1).assertTrue();
      done();
    })

    it('calcNextRefresh_range', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const block2 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info2.mIsHoliday = true;
      block1.setInfo(info1, 14);
      block2.setInfo(info2, 14);
      allDayBlocks.push(block1);
      normalBlocks.push(block2);
      ganttViewModel.allDayBlocks = allDayBlocks;
      ganttViewModel.normalBlocks = normalBlocks;
      const range: DateRange.Range = {
        start: Date.now() - 1000, end: Date.now() + 1000
      };
      TestUtil.setPrivateAttribute(ganttViewModel, 'range', range);
      ganttViewModel.calcNextRefresh()
      let refreshTimer: number = TestUtil.getPrivateAttribute(ganttViewModel, 'refreshTimer');
      expect(refreshTimer == -1).assertTrue();
      done();
    })

    it('calcNextRefresh_end', 0, async (done: Function) => {
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const block2 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info2.mIsHoliday = true;
      info1.mEnd = Date.now() + 1000;
      info2.mEnd = Date.now() + 1000;
      block1.setInfo(info1, 14);
      block2.setInfo(info2, 14);
      allDayBlocks.push(block1);
      normalBlocks.push(block2);
      ganttViewModel.allDayBlocks = allDayBlocks;
      ganttViewModel.normalBlocks = normalBlocks;
      const range: DateRange.Range = {
        start: Date.now() - 1000, end: Date.now() + 1000
      };
      TestUtil.setPrivateAttribute(ganttViewModel, 'range', range);
      ganttViewModel.calcNextRefresh()
      let refreshTimer: number = TestUtil.getPrivateAttribute(ganttViewModel, 'refreshTimer');
      expect(refreshTimer == -1).assertFalse();
      done();
    })

    it('eventToRefreshDetail', 0, async (done: Function) => {
      let hasError: boolean = true;
      let rootViewModel = new RootViewModel(TabType.WEEK);
      let ganttViewModel = new GanttViewModel(rootViewModel);
      const info1 = new AgendaEventInfo();
      ganttViewModel.eventToRefreshDetail(info1)
      hasError = false;
      expect(hasError).assertFalse()
      done();
    })

    it('getDefaultChosenInfo_is_divide', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      expect(ganttViewModel.getDefaultChosenInfo()).assertUndefined();
      done();
    })

    it('getDefaultChosenInfo_all_day', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info1.mEnd = Date.now() + 1000;
      block1.setInfo(info1, 14);
      allDayBlocks.push(block1);
      ganttViewModel.allDayBlocks = allDayBlocks;
      const demo = !rootVM.isWeekView() && rootVM.isDivide;
      expect(demo).assertTrue()
      expect(ganttViewModel.getDefaultChosenInfo()).assertEqual(info1);
      done();
    })

    it('getDefaultChosenInfo_normal', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block2 = new GanttBlockViewModel();
      const info2 = new AgendaEventInfo();
      info2.mIsHoliday = true;
      info2.mEnd = Date.now() + 1000;
      block2.setInfo(info2, 14);
      normalBlocks.push(block2);
      ganttViewModel.normalBlocks = normalBlocks;
      const demo = !rootVM.isWeekView() && rootVM.isDivide;
      expect(demo).assertTrue()
      expect(ganttViewModel.getDefaultChosenInfo()).assertEqual(info2);
      done();
    })
    it('divideRefreshBlocksFocus_all_day', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info1.mEnd = Date.now() + 1000;
      block1.setInfo(info1, 14);
      allDayBlocks.push(block1);
      ganttViewModel.allDayBlocks = allDayBlocks;
      const demo = !rootVM.isWeekView() && rootVM.isDivide;
      expect(demo).assertTrue();
      expect(ganttViewModel.divideRefreshBlocksFocus(0, '')).assertEqual(info1);
      done();
    })

    it('divideRefreshBlocksFocus_normal', 0, async (done: Function) => {
      let rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      let ganttViewModel = new GanttViewModel(rootVM);
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block2 = new GanttBlockViewModel();
      const info2 = new AgendaEventInfo();
      info2.mIsHoliday = true;
      info2.mEnd = Date.now() + 1000;
      block2.setInfo(info2, 14);
      normalBlocks.push(block2);
      ganttViewModel.normalBlocks = normalBlocks;
      const demo = !rootVM.isWeekView() && rootVM.isDivide;
      expect(demo).assertTrue();
      expect(ganttViewModel.divideRefreshBlocksFocus(0, '')).assertEqual(info2);
      done();
    })

    // 中国节假日
    it('handleFestival_chinese', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      // 设为中国节假日
      TestUtil.setPrivateAttribute(rootVM, 'subscriptionCalendar', SubscriptionCalendar.CHINESE_CALENDAR);
      const ganttViewModel = new GanttViewModel(rootVM);
      const dayModel = new DayModel(new CalendarDate(2024, 1, 1));
      dayModel.festivals = [{
        type: FestivalType.LUNAR_CHINA, name: '春节',
        resource: $r('app.string.spring_festival')
      }];
      ganttViewModel.updateDayModels([dayModel]);
      ganttViewModel.handleFestival();
      const allDayAgendaList: AgendaEventInfo[] = TestUtil.getPrivateAttribute(ganttViewModel, 'allDayAgendaList');
      expect(allDayAgendaList.length > 0).assertTrue();
      done();
    })

    // 非中国节假日
    it('handleFestival_not_chinese', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      // 设为非中国节假日
      TestUtil.setPrivateAttribute(rootVM, 'subscriptionCalendar', SubscriptionCalendar.JAPANESE_CALENDAR);
      const dayModel = new DayModel(new CalendarDate(2024, 1, 1));
      dayModel.festivals = [{
        type: FestivalType.LUNAR_CHINA, name: '春节',
        resource: $r('app.string.spring_festival')
      }];
      const ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.updateDayModels([dayModel])
      ganttViewModel.handleFestival()
      const allDayAgendaList: AgendaEventInfo[] = TestUtil.getPrivateAttribute(ganttViewModel, 'allDayAgendaList');
      expect(allDayAgendaList.length > 0).assertTrue();
      done();
    })

    // 非中国地区
    it('handleFestival_not_chinese_region', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      rootVM.isDivide = true;
      // 设为非中国地区
      TestUtil.setPrivateAttribute(rootVM, 'systemRegion', 1);
      const dayModel = new DayModel(new CalendarDate(2024, 1, 1));
      dayModel.festivals = [{
        type: FestivalType.LUNAR_CHINA, name: '春节',
        resource: $r('app.string.spring_festival')
      }];
      const ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.updateDayModels([dayModel])
      ganttViewModel.handleFestival()
      const allDayAgendaList: AgendaEventInfo[] = TestUtil.getPrivateAttribute(ganttViewModel, 'allDayAgendaList');
      expect(allDayAgendaList.length > 0).assertFalse();
      done();
    })

    // 中国节假日已打开
    it('handleFestival_chinese_festival_open', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(
        InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceAsync
      );
      const info1: AgendaEventInfo = new AgendaEventInfo();
      info1.mId = 1;
      info1.mTitle = '春节';
      info1.mImportantEventType =  CalendarContract.EventImportantType.HOLIDAY;
      const info2: AgendaEventInfo = new AgendaEventInfo();
      info1.mId = 2;
      info2.mTitle = '不是节日';
      const infos: AgendaEventInfo[] = [info1, info2];
      when(mockFunc)(ArgumentMatchers.any).afterReturn(infos);
      const mockRange: DateRange.Range = {start: 100, end: 200};
      await AgendaModel.instance().query(mockRange);
      const dayModel = new DayModel(new CalendarDate(2024, 1, 1));
      dayModel.festivals = [{
        type: FestivalType.LUNAR_CHINA, name: '春节',
        resource: $r('app.string.spring_festival')
      }];
      const ganttViewModel = new GanttViewModel(rootVM);
      ganttViewModel.updateDayModels([dayModel]);
      ganttViewModel.handleFestival();
      const allDayAgendaList: AgendaEventInfo[] = TestUtil.getPrivateAttribute(ganttViewModel, 'allDayAgendaList');
      expect(allDayAgendaList.length > 0).assertFalse();
      done();
    })

    it('transClickPosition_is_all_day', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const eventX: number = 1;
      const eventY: number = 1;
      const isAllDay: boolean = true;
      expect(ganttViewModel.transClickPosition(eventX, eventY, isAllDay).x).assertEqual(eventX + rootVM.weekTitleVM.leftWidth);
      done();
    })

    it('transClickPosition_not_all_day', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const eventX: number = 1;
      const eventY: number = 1;
      const isAllDay: boolean = false;
      expect(ganttViewModel.transClickPosition(eventX, eventY, isAllDay).y)
        .assertEqual(eventY - ganttViewModel.getScrollOffsetY() + ganttViewModel.allDayHeight);
      done();
    })

    it('transPositionToStamp_is_all_day', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const eventX: number = 1;
      const eventY: number = 1;
      const isAllDay: boolean = true;
      expect(ganttViewModel.transPositionToStamp(eventX, eventY, isAllDay) > 0).assertTrue();
      done();
    })

    it('transPositionToStamp_not_all_day', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const eventX: number = 1;
      const eventY: number = 1;
      const isAllDay: boolean = false;
      expect(ganttViewModel.transPositionToStamp(eventX, eventY, isAllDay) > 0).assertTrue();
      done();
    })

    it('getScrollOffsetY_offset', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const scroller: Scroller = ganttViewModel.scroller;
      const mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(scroller, scroller.currentOffset);
      const offset: OffsetResult = {
        xOffset: 1, yOffset: 1
      }
      when(mockFunc)(ArgumentMatchers.any).afterReturn(offset);
      expect(ganttViewModel.getScrollOffsetY()).assertEqual(scroller.currentOffset().yOffset);
      done();
    })

    it('getScrollOffsetY_not_offset', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const range: DateRange.Range = {
        start: Date.now() - 1000, end: Date.now() + 1000
      }
      TestUtil.setPrivateAttribute(ganttViewModel, 'range', range);
      expect(ganttViewModel.getScrollOffsetY()).assertEqual(range.start);
      done();
    })

    it('pushFoldInfoList', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);

      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info1.mEnd = Date.now() + 1000;
      block1.setInfo(info1, 14);
      allDayBlocks.push(block1);
      ganttViewModel.allDayBlocks = allDayBlocks;
      const preDrawnBlocks = new Array([block1]);

      let mocker: MockKit = new MockKit();
      mocker.mockFunc(block1, block1.intersect);
      ganttViewModel.pushFoldInfoList(block1, [info1], preDrawnBlocks, 0);
      mocker.verify('intersect', []).never();
      done();
    })

    it('updateAddAgendaBlock', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      let updateAddAgendaBlock = TestUtil.getPrivateFunction(ganttViewModel, 'updateAddAgendaBlock') !!;
      updateAddAgendaBlock()
      expect(ganttViewModel.addBlockVM.ganttCellWidth).assertEqual(rootVM.ganttCellWidth);
      done();
    })

    it('initAddAgendaBlock', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      let initAddAgendaBlock = TestUtil.getPrivateFunction(ganttViewModel, 'initAddAgendaBlock') !!;
      initAddAgendaBlock()
      expect(ganttViewModel.addBlockVM.ganttCellWidth).assertEqual(rootVM.ganttCellWidth);
      done();
    })

    it('updateGanttViewScale', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      let updateGanttViewScale = TestUtil.getPrivateFunction(ganttViewModel, 'updateGanttViewScale') !!;
      updateGanttViewScale(1, false);
      const updateScale = TestUtil.getPrivateAttribute<number>(ganttViewModel, 'updateScale');
      expect(updateScale).assertEqual(1);
      done();
    })

    it('updateAllDay', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);

      let updateAllDay = TestUtil.getPrivateFunction(ganttViewModel, 'updateAllDay') !!;
      updateAllDay()
      const updateScale = TestUtil.getPrivateAttribute<number>(ganttViewModel, 'updateScale');
      expect(updateScale).assertEqual(1);
      done();
    })

    it('updateNormal', 0, async (done: Function) => {
      const rootVM = new RootViewModel(TabType.DAY);
      const ganttViewModel = new GanttViewModel(rootVM);
      const allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
      const normalBlocks: ObservedArray<GanttBlockViewModel> = [];
      const block1 = new GanttBlockViewModel();
      const block2 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      info1.mIsHoliday = false;
      info2.mIsHoliday = true;
      block1.setInfo(info1, 14);
      block2.setInfo(info2, 14);
      allDayBlocks.push(block1);
      normalBlocks.push(block2);
      ganttViewModel.allDayBlocks = allDayBlocks;
      ganttViewModel.normalBlocks = normalBlocks;
      let updateNormal = TestUtil.getPrivateFunction(ganttViewModel, 'updateNormal') !!;
      updateNormal();
      const updateScale = TestUtil.getPrivateAttribute<number>(ganttViewModel, 'updateScale');
      expect(updateScale).assertEqual(1);
      done();
    })
  });
}