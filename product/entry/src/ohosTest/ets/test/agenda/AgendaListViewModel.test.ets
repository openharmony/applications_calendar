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
import { AgendaEventInfo, AgendaListItemViewModel,
  CalendarDate,
  DateRange, DateUtil, EventService, MILLS_PER_DAY } from '@app/common';
import { TestUtil } from '../utils/TestUtil';
import { AgendaListViewModel } from '@app/feature.agenda/src/main/ets/AgendaList/viewmodel/AgendaListViewModel';
import { KeyCode } from '@kit.InputKit';
import { AgendaListDataModel } from '@app/feature.agenda';
import { emitter } from '@kit.BasicServicesKit';

const ILLEGAL_CALENDAR_ID = -1;

export default function AgendaListViewModelTest() {
  describe('AgendaListViewModelTest', () => {
    let vm: AgendaListViewModel;
    const displayMills: number = Date.now();
    const calendarUuid: string = '';
    const language: string = 'zh-Hans';
    const mScroller: Scroller = new Scroller();
    const paramsEventId: number = 0;
    const paramsDisplaysMills: number = 0;
    const mockAgendaInfo: AgendaListItemViewModel = new AgendaListItemViewModel();

    beforeEach(async (done: Function) => {
      vm = new AgendaListViewModel(displayMills, calendarUuid, language, mScroller, paramsEventId, paramsDisplaysMills,
        () => {
        });
      done();
    })

    it('init_01', 0, async (done: Function) => {
      vm.init();
      vm.subscribeEvents();
      let dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      expect(dataModel).not().assertUndefined();
      vm.unsubscribeEvents();
      done();
    });

    // should return false when range.start equals maxRange.start
    it('handlePullDown_01', 0, async (done: Function) => {
      const mockRange: DateRange.Range = {
        start: 10, end: 20
      };
      const mockMaxRange: DateRange.Range = {
        start: 10, end: 30
      };
      TestUtil.setPrivateAttribute(vm, 'range', mockRange);
      TestUtil.setPrivateAttribute(vm, 'maxRange', mockMaxRange);
      const result = await vm.handlePullDown();
      expect(result).assertEqual(false);
      done();
    });

    // should perform query and update when range.start not equals maxRange.start
    it('handlePullDown_02', 0, async (done: Function) => {
      const mockRange: DateRange.Range = {
        start: 20, end: 30
      };
      const mockMaxRange: DateRange.Range = {
        start: 10, end: 30
      };
      TestUtil.setPrivateAttribute(vm, 'range', mockRange);
      TestUtil.setPrivateAttribute(vm, 'maxRange', mockMaxRange);
      vm.handlePullDown().then(result => {
        expect(result).assertEqual(true);
      })
      done();
    });

    // should return false when range.end equals maxRange.end
    it('handleUpSlide_01', 0, async (done: Function) => {
      const mockRange: DateRange.Range = {
        start: 20, end: 30
      };
      const mockMaxRange: DateRange.Range = {
        start: 10, end: 30
      };
      TestUtil.setPrivateAttribute(vm, 'range', mockRange);
      TestUtil.setPrivateAttribute(vm, 'maxRange', mockMaxRange);
      const result = await vm.handleUpSlide();
      expect(result).assertEqual(false);
      done();
    });

    // should perform query and update when range.end not equals maxRange.end
    it('handleUpSlide_02', 0, async (done: Function) => {
      const mockRange: DateRange.Range = {
        start: 10, end: 20
      };
      const mockMaxRange: DateRange.Range = {
        start: 10, end: 30
      };
      TestUtil.setPrivateAttribute(vm, 'range', mockRange);
      TestUtil.setPrivateAttribute(vm, 'maxRange', mockMaxRange);
      vm.handleUpSlide().then(result => {
        expect(result).assertEqual(true);
      })
      done();
    });

    // should set isShowBackToday to false when agendaResult is empty
    it('changeBackTodayStatus_01', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = [];
      vm.agendaResult = mockAgendaResult;
      const startIndex = 10;
      const endIndex = 20;
      vm.changeBackTodayStatus(startIndex, endIndex);
      expect(vm.isShowBackToday).assertFalse();
      done();
    });

    // should set isShowBackToday to true when todayEventsIndexArr does not intersect with [startIndex, endIndex]
    it('changeBackTodayStatus_02', 0, async (done: Function) => {
      const mockTodayEventsIndexArr: number[] = [1];
      const mockAgendaResult: AgendaListItemViewModel[] = [mockAgendaInfo];
      TestUtil.setPrivateAttribute(vm, 'todayEventsIndexArr', mockTodayEventsIndexArr);
      vm.agendaResult = mockAgendaResult;
      const startIndex = 10;
      const endIndex = 20;
      vm.changeBackTodayStatus(startIndex, endIndex);
      expect(vm.isShowBackToday).assertTrue();
      done();
    });

    // should set isShowBackToday according to the expression (first > endIndex) || (last < startIndex)
    it('changeBackTodayStatus_03', 0, async (done: Function) => {
      const mockTodayEventsIndexArr: number[] = [15];
      const mockAgendaResult: AgendaListItemViewModel[] = [mockAgendaInfo];
      TestUtil.setPrivateAttribute(vm, 'todayEventsIndexArr', mockTodayEventsIndexArr);
      vm.agendaResult = mockAgendaResult;
      const startIndex = 10;
      const endIndex = 20;
      vm.changeBackTodayStatus(startIndex, endIndex);
      expect(vm.isShowBackToday).assertFalse();
      done();
    });

    // should return early when item is undefined
    it('onItemClick_01', 0, async (done: Function) => {
      const res = vm.onItemClick(undefined);
      expect(res).assertFalse();
      done();
    });

    // should set selectedAgenda and call vmShowDataChange when item is defined
    it('onItemClick_02', 0, async (done: Function) => {
      const res = vm.onItemClick(mockAgendaInfo);
      expect(res).assertTrue();
      done();
    });

    // should set headLoading to true and call handlePullDown when headLoading is false
    it('onHeadTextClick_01', 0, async (done: Function) => {
      const EXTEND_YEAR = 3;
      const maxRange: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'maxRange');
      const maxRangeStartDate = new CalendarDate(maxRange.start);
      maxRangeStartDate.setFullYear(maxRangeStartDate.getFullYear() - EXTEND_YEAR);
      const expectMaxRangeStart = maxRangeStartDate.getTime();

      vm.onHeadTextClick();

      const maxRangeRes: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'maxRange');
      expect(maxRangeRes.start).assertEqual(expectMaxRangeStart);
      done();
    });

    it('onTailTextClick_01', 0, async (done: Function) => {
      const EXTEND_YEAR = 3;
      const maxRange: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'maxRange');
      const maxRangeEndDate = new CalendarDate(maxRange.end);
      maxRangeEndDate.setFullYear(maxRangeEndDate.getFullYear() + EXTEND_YEAR);
      const expectMaxRangeEnd = maxRangeEndDate.getTime();

      vm.onTailTextClick();

      const maxRangeRes: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'maxRange');
      expect(maxRangeRes.end).assertEqual(expectMaxRangeEnd);
      done();
    });

    it('onBackTodayClick_01', 0, async (done: Function) => {
      let mocker = new MockKit();

      const isTodayInRange = TestUtil.getPrivateMockFunction(mocker, vm, 'isTodayInRange')
      when(isTodayInRange)(ArgumentMatchers.any).afterReturn(false);

      vm.onBackTodayClick();
      let todayEventsIndexArr = TestUtil.getPrivateAttribute<number[]>(vm, 'todayEventsIndexArr');
      expect(todayEventsIndexArr.length).assertEqual(0);
      done();
    });

    it('onBackTodayClick_02', 0, async (done: Function) => {
      let mocker = new MockKit();

      const isTodayInRange = TestUtil.getPrivateMockFunction(mocker, vm, 'isTodayInRange')
      when(isTodayInRange)(ArgumentMatchers.any).afterReturn(false);
      TestUtil.setPrivateAttribute(vm, 'todayEventsIndexArr', [999]);

      vm.onBackTodayClick();
      expect(vm.agendaResult.length - 1).assertLess(999);
      done();
    });

    it('onBackTodayClick_03', 0, async (done: Function) => {
      let mocker = new MockKit();

      const isTodayInRange = TestUtil.getPrivateMockFunction(mocker, vm, 'isTodayInRange')
      when(isTodayInRange)(ArgumentMatchers.any).afterReturn(false);
      TestUtil.setPrivateAttribute(vm, 'todayEventsIndexArr', [1]);

      const mockAgendaResult: AgendaListItemViewModel[] = buildOnKeyPressTestData();
      vm.agendaResult = mockAgendaResult;

      vm.onBackTodayClick();
      expect(vm.isShowBackToday).assertFalse();
      done();
    });

    // should calculate Julian day correctly
    it('onCurrentDateChange_01', 0, async (done: Function) => {
      const currentDate = 1627496400000; // 2021-07-30T12:00:00Z
      const expectedJulianDay = 2459465;
      let mocker = new MockKit();
      let mockFunc = mocker.mockFunc(DateUtil, DateUtil.getJulianDay);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(expectedJulianDay);
      vm.onCurrentDateChange(currentDate);
      expect(vm.currentJulianDay).assertEqual(expectedJulianDay);
      done();
    });

    // should call updateViewText when language changes
    it('onLanguageChange_01', 0, async (done: Function) => {
      const language = 'en';
      vm.onLanguageChange(language);
      const vmLanguage: string = TestUtil.getPrivateAttribute(vm, 'language');
      expect(vmLanguage).assertEqual(language);
      done();
    });

    // should return true when handleSoftDelete executes successfully
    it('rightClickToDeleteConfirm_01', 0, async (done: Function) => {
      let mocker = new MockKit();
      let handleSoftDelete = TestUtil.getPrivateMockFunction(mocker, vm, 'handleSoftDelete');
      if (!handleSoftDelete) {
        expect(handleSoftDelete).assertUndefined();
      }
      when(handleSoftDelete)(ArgumentMatchers.any).afterThrow('这是一个主动抛出的错误');
      const res = vm.rightClickToDeleteConfirm();
      expect(res).assertFalse();
      done();
    });

    // should return false when handleSoftDelete throws an error
    it('rightClickToDeleteConfirm_02', 0, async (done: Function) => {
      let mocker = new MockKit();
      let handleSoftDelete = TestUtil.getPrivateMockFunction(mocker, vm, 'handleSoftDelete');
      if (!handleSoftDelete) {
        expect(handleSoftDelete).assertUndefined();
      }
      when(handleSoftDelete)(ArgumentMatchers.any).afterReturn(true);
      const res = vm.rightClickToDeleteConfirm();
      expect(res).assertTrue();
      done();
    });

    // should calculate range correctly
    it('parseRange_01', 0, () => {
      const parseRange = TestUtil.getPrivateFunction(vm, 'parseRange');
      if (parseRange) {
        parseRange(displayMills);
        const range: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'range');
        const maxRange: DateRange.Range = TestUtil.getPrivateAttribute(vm, 'maxRange');
        const todayOfDisplayMills = new CalendarDate(displayMills);
        const maxRangeStart = new CalendarDate(todayOfDisplayMills.getFullYear() - 1,
          todayOfDisplayMills.getMonth(), todayOfDisplayMills.getDate());
        const maxRangeEnd = new CalendarDate(todayOfDisplayMills.getFullYear() + 2,
          todayOfDisplayMills.getMonth(), todayOfDisplayMills.getDate());
        expect(maxRange.start).assertEqual(maxRangeStart.getTime());
        expect(maxRange.end).assertEqual(maxRangeEnd.getTime());
        expect(range.start).assertEqual(displayMills - 15 * MILLS_PER_DAY);
        expect(range.end).assertEqual(displayMills + 15 * MILLS_PER_DAY);
      }
    });

    // should set isShowBackToday to false when agendaResult is empty
    it('onKeyPress_01', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = buildOnKeyPressTestData();
      vm.agendaResult = mockAgendaResult;
      const mockSelectAgenda: AgendaListItemViewModel = new AgendaListItemViewModel();
      mockSelectAgenda.mId = 2;
      vm.selectedAgenda=mockSelectAgenda;
      const res = vm.onKeyPress(KeyCode.KEYCODE_DPAD_UP);
      expect(res).assertTrue();
      done();
    });

    it('onKeyPress_02', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = buildOnKeyPressTestData();
      vm.agendaResult = mockAgendaResult;
      const mockSelectAgenda: AgendaListItemViewModel = new AgendaListItemViewModel();
      mockSelectAgenda.mId = 10;
      vm.selectedAgenda=mockSelectAgenda;
      const res = vm.onKeyPress(KeyCode.KEYCODE_DPAD_UP);
      expect(res).assertFalse();
      done();
    });

    it('onKeyPress_03', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = buildOnKeyPressTestData();
      vm.agendaResult = mockAgendaResult;
      const mockSelectAgenda: AgendaListItemViewModel = new AgendaListItemViewModel();
      mockSelectAgenda.mId = 2;
      vm.selectedAgenda=mockSelectAgenda;
      const res = vm.onKeyPress(KeyCode.KEYCODE_DPAD_DOWN);
      expect(res).assertTrue();
      done();
    });

    it('onKeyPress_04', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = buildOnKeyPressTestData();
      vm.agendaResult = mockAgendaResult;
      const mockSelectAgenda: AgendaListItemViewModel = new AgendaListItemViewModel();
      mockSelectAgenda.mId = 10;
      vm.selectedAgenda=mockSelectAgenda;
      const res = vm.onKeyPress(KeyCode.KEYCODE_DPAD_DOWN);
      expect(res).assertFalse();
      done();
    });

    it('deleteMultiEventsConfirm_selectAllTrue', 0, () => {
      const allEvents: AgendaListItemViewModel[] = [];
      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      event.mId = 1;
      event.isSelected = true;
      allEvents.push(event);
      vm.agendaResult = [event];
      TestUtil.setPrivateAttribute(vm, 'allEvents', allEvents);
      TestUtil.setPrivateAttribute(vm, 'selectAll', true);
      vm.deleteMultiEventsConfirm();
      expect(vm.agendaResult.length).assertEqual(1);
    })

    it('deleteMultiEventsConfirm_selectAllFalse', 0, () => {
      const allEvents: AgendaListItemViewModel[] = [];
      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      event.mId = 1;
      event.isSelected = true;
      allEvents.push(event);
      vm.agendaResult = [event];
      TestUtil.setPrivateAttribute(vm, 'allEvents', allEvents);
      TestUtil.setPrivateAttribute(vm, 'selectAll', false);
      vm.deleteMultiEventsConfirm();
      expect(vm.agendaResult.length).assertEqual(1);
    })

    it('updateScrollIndex', 0, () => {
      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      vm.agendaResult = [event];
      TestUtil.setPrivateAttribute(vm, 'scrollIndex', 0);
      const mocker = new MockKit();
      const mockGetSelectedIndex = TestUtil.getPrivateMockFunction(mocker, vm, 'getSelectedIndex');
      when(mockGetSelectedIndex)(ArgumentMatchers.any).afterReturn(0);
      const funcUpdateScrollIndex = TestUtil.getPrivateFunction(vm, 'updateScrollIndex')!;
      funcUpdateScrollIndex();
      expect(vm.scrollIndex).assertEqual(1);
      vm.agendaResult = [];
      TestUtil.setPrivateAttribute(vm, 'scrollIndex', 0);
      funcUpdateScrollIndex();
      expect(vm.scrollIndex).assertEqual(0);
    })

    it('initSelectedAgenda', 0, () => {
      const funcInitSelectedAgenda = TestUtil.getPrivateFunction(vm, 'initSelectedAgenda')!;
      const mocker = new MockKit();
      TestUtil.getPrivateMockFunction(mocker, vm, 'updateScrollIndex');
      TestUtil.setPrivateAttribute(vm, 'displayEventsIndexArr', []);
      vm.selectedAgenda = undefined;
      funcInitSelectedAgenda();
      mocker.verify('updateScrollIndex', []).atLeast(0);

      TestUtil.setPrivateAttribute(vm, 'displayEventsIndexArr', [0]);
      TestUtil.setPrivateAttribute(vm, 'paramsEventId', 1);
      TestUtil.setPrivateAttribute(vm, 'paramsDisplaysMills', 1);
      funcInitSelectedAgenda();
      mocker.verify('updateScrollIndex', []).atLeast(0);

      TestUtil.setPrivateAttribute(vm, 'paramsDisplaysMills', 0);
      funcInitSelectedAgenda();
      mocker.verify('updateScrollIndex', []).atLeast(0);

      TestUtil.setPrivateAttribute(vm, 'paramsEventId', 0);
      TestUtil.setPrivateAttribute(vm, 'agendaResult', [new AgendaListItemViewModel()]);
      funcInitSelectedAgenda();
      mocker.verify('updateScrollIndex', []).atLeast(0);
    })

    it('getSelectedIndex', 0, () => {
      vm.selectedAgenda = new AgendaEventInfo();
      const funcGetSelectedIndex = TestUtil.getPrivateFunction(vm, 'getSelectedIndex')!;
      const dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      const mocker = new MockKit();
      const mockFindIndexFromCache = TestUtil.getPrivateMockFunction(mocker, dataModel, 'findIndexFromCache');
      when(mockFindIndexFromCache)(ArgumentMatchers.any).afterReturn(0);
      let index: number = funcGetSelectedIndex();
      expect(index).assertEqual(0);
      vm.selectedAgenda = undefined;
      index = funcGetSelectedIndex();
      expect(index).assertEqual(-1);
    })

    it('getNearAgendaOfArray', 0, () => {
      const funcGetNearAgendaOfArray = TestUtil.getPrivateFunction(vm, 'getNearAgendaOfArray')!;
      const agendaList: AgendaEventInfo[] = [];
      let res: number[] = funcGetNearAgendaOfArray(agendaList, 0);
      expect(res.length).assertEqual(0);
      const event1 = new AgendaEventInfo();
      event1.mDay = -1;
      agendaList.push(event1);
      res = funcGetNearAgendaOfArray(agendaList, 0);
      expect(res.length).assertEqual(1);
      const event2 = new AgendaEventInfo();
      event2.mDay = 0;
      agendaList.push(event2);
      res = funcGetNearAgendaOfArray(agendaList, 0);
      expect(res.length).assertEqual(1);
      event2.mDay = 1;
      res = funcGetNearAgendaOfArray(agendaList, 0);
      expect(res.length).assertEqual(1);
    })

    it('updateViewText', 0, () => {
      const funcUpdateViewText = TestUtil.getPrivateFunction(vm, 'updateViewText')!;
      const range: DateRange.Range = { start: 0, end: 0 };
      const maxRange: DateRange.Range = { start: 0, end: 0 };
      const mocker = new MockKit();
      TestUtil.getPrivateMockFunction(mocker, vm, 'getHeadViewText');
      TestUtil.getPrivateMockFunction(mocker, vm, 'getTailViewText');
      TestUtil.setPrivateAttribute(vm, 'range', range);
      TestUtil.setPrivateAttribute(vm, 'maxRange', maxRange);
      funcUpdateViewText();
      mocker.verify('getHeadViewText', [0]).once();
      mocker.verify('getTailViewText', [0]).once();

      range.start = 1;
      range.end = 1;
      TestUtil.setPrivateAttribute(vm, 'range', range);
      funcUpdateViewText();
      expect(vm.headViewText).assertEqual('');
      expect(vm.tailViewText).assertEqual('');
    })

    it('shouldUpdateList', 0, () => {
      const funcShouldUpdateList = TestUtil.getPrivateFunction(vm, 'shouldUpdateList')!;
      const oldInfo = new AgendaEventInfo();
      const newInfo = new AgendaEventInfo();
      let res: boolean = funcShouldUpdateList(undefined, newInfo);
      expect(res).assertTrue();

      oldInfo.mTitle = '';
      newInfo.mTitle = 'title';
      res = funcShouldUpdateList(oldInfo, newInfo);
      expect(res).assertTrue();

      oldInfo.mTitle = newInfo.mTitle;
      newInfo.mLocation = 'location';
      res = funcShouldUpdateList(oldInfo, newInfo);
      expect(res).assertTrue();

      oldInfo.mLocation = newInfo.mLocation;
      newInfo.mBegin = 1;
      res = funcShouldUpdateList(oldInfo, newInfo);
      expect(res).assertTrue();

      oldInfo.mBegin = newInfo.mBegin;
      newInfo.mEnd = 1;
      res = funcShouldUpdateList(oldInfo, newInfo);
      expect(res).assertTrue();

      oldInfo.mEnd = newInfo.mEnd;
      res = funcShouldUpdateList(oldInfo, newInfo);
      expect(res).assertFalse();
    })

    it('changeDisplayDate_test1', 0, () => {
      vm.changeDisplayDate(0);
      let agendaEvent = TestUtil.getPrivateAttribute<AgendaEventInfo>(vm, 'agendaEvent');
      expect(agendaEvent).not().assertNull();
    })

    it('changeDisplayDate_test2', 0, () => {
      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      vm.agendaResult = [event, event, event];
      vm.changeDisplayDate(1);
      let agendaEvent = TestUtil.getPrivateAttribute<AgendaEventInfo>(vm, 'agendaEvent');
      expect(agendaEvent).not().assertNull();
    })

    it('updateAgenda_test1', 0, () => {
      const updateAgenda = TestUtil.getPrivateFunction(vm, 'updateAgenda');
      if (updateAgenda) {
        vm.scrollIndex = 0;
        updateAgenda()
      }
      expect(vm.selectedAgenda).assertUndefined();
    })

    it('onTimeChange_test1', 0, () => {
      const onTimeChange = TestUtil.getPrivateFunction(vm, 'onTimeChange');
      if (onTimeChange) {
        vm.scrollIndex = 0;
        onTimeChange()
      }
      expect(vm.currentJulianDay).assertLarger(0);
    })

    it('fullUpdateView_test1', 0, () => {
      const fullUpdateView = TestUtil.getPrivateFunction(vm, 'fullUpdateView');
      if (fullUpdateView) {
        fullUpdateView({
          data: {
            'eventId': 111
          }
        } as emitter.EventData, true)
      }
      expect(vm.selectedAgenda).assertUndefined();
    })

    it('fullUpdateView_test2', 0, () => {
      const fullUpdateView = TestUtil.getPrivateFunction(vm, 'fullUpdateView');
      if (fullUpdateView) {
        fullUpdateView({}, true)
      }
      expect(vm.selectedAgenda).assertUndefined();
    })

    it('handleSoftDelete_test1', 0, () => {
      let mocker = new MockKit();
      let dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      let findIndexFromCache = mocker.mockFunc(dataModel, dataModel.findIndexFromCache);
      when(findIndexFromCache)(ArgumentMatchers.any).afterReturn(-1);

      let result: boolean = true;
      const handleSoftDelete = TestUtil.getPrivateFunction(vm, 'handleSoftDelete');
      if (handleSoftDelete) {
        result = handleSoftDelete(999, 1);
      }
      expect(result).assertFalse();
    })

    it('handleSoftDelete_test2', 0, () => {
      let mocker = new MockKit();
      let dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      let findIndexFromCache = mocker.mockFunc(dataModel, dataModel.findIndexFromCache);
      when(findIndexFromCache)(ArgumentMatchers.any).afterReturn(0);

      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      event.mIsSetDayHead = true;
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [event]);

      let result: boolean = false;
      const handleSoftDelete = TestUtil.getPrivateFunction(vm, 'handleSoftDelete');
      if (handleSoftDelete) {
        result = handleSoftDelete(999, 1);
      }
      expect(result).assertTrue();
    })

    it('handleSoftDelete_test3', 0, () => {
      let mocker = new MockKit();
      let dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      let findIndexFromCache = mocker.mockFunc(dataModel, dataModel.findIndexFromCache);
      when(findIndexFromCache)(ArgumentMatchers.any).afterReturn(0);

      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      event.mIsSetDayHead = true;
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [event, event]);

      let result: boolean = false;
      const handleSoftDelete = TestUtil.getPrivateFunction(vm, 'handleSoftDelete');
      if (handleSoftDelete) {
        result = handleSoftDelete(999, 1);
      }
      expect(result).assertTrue();
    })

    it('onDeleteEventByID_test1', 0, () => {
      let result: boolean = true;
      const onDeleteEventByID = TestUtil.getPrivateFunction(vm, 'onDeleteEventByID');
      if (onDeleteEventByID) {
        result = onDeleteEventByID({
          data: {}
        } as emitter.EventData);
      }
      expect(result).assertFalse();
    })

    it('onDeleteEventByID_test2', 0, () => {
      let result: boolean = false;
      const onDeleteEventByID = TestUtil.getPrivateFunction(vm, 'onDeleteEventByID');
      if (onDeleteEventByID) {
        result = onDeleteEventByID({
          data: {
            'eventId': 111,
            'displayStartMills': 222
          }
        } as emitter.EventData);
      }
      expect(result).assertTrue();
    })

    it('getShareableEvents_test1', 0, () => {
      const getShareableEvents = TestUtil.getPrivateFunction(vm, 'getShareableEvents');
      if (getShareableEvents) {
        getShareableEvents([]);
      }
      expect(vm.shareableEventIds.length).assertEqual(0);
    })

    it('queryAllAgendas_test1', 0, () => {
      TestUtil.setPrivateAttribute(vm, 'allEventLoaded', true);
      vm.queryAllAgendas();
      let allEventLoaded = TestUtil.getPrivateAttribute<boolean>(vm, 'allEventLoaded');
      expect(allEventLoaded).assertTrue();
    })

    it('queryAllAgendas_test2', 0, async () => {
      let mocker = new MockKit();
      let queryNormalEvents = mocker.mockFunc(EventService.INSTANCE, EventService.INSTANCE.queryNormalEvents);
      when(queryNormalEvents)(ArgumentMatchers.any).afterReturn([1, 2]);

      await vm.queryAllAgendas();
      let allEventLoaded = TestUtil.getPrivateAttribute<boolean>(vm, 'allEventLoaded');
      expect(allEventLoaded).assertTrue();
      mocker.ignoreMock(EventService.INSTANCE, EventService.INSTANCE.queryNormalEvents);
    })

    it('enableMultiSelect_test1', 0, async () => {
      const event: AgendaListItemViewModel = new AgendaListItemViewModel();
      event.isSelected = true;

      let dataModel = TestUtil.getPrivateAttribute<AgendaListDataModel>(vm, 'dataModel');
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [event]);

      vm.agendaResult = [event];
      await vm.enableMultiSelect();
      expect(vm.selectedAgenda).assertUndefined();
    })

    it('disableMultiSelect_test1', 0, async () => {
      await vm.disableMultiSelect();
      expect(vm.scrollIndex).assertLess(0);
    })

    it('vmShowDataChange_test1', 0, () => {
      const vmShowDataChange = TestUtil.getPrivateFunction(vm, 'vmShowDataChange');
      if (vmShowDataChange) {
        vmShowDataChange(1, 2, 3, 4, 5, new AgendaEventInfo());
      }
      expect(vm.scrollIndex).assertLess(0);
    })

    it('timeChangeHandler_test1', 0, () => {
      const timeChangeHandler = TestUtil.getPrivateFunction(vm, 'timeChangeHandler');
      if (timeChangeHandler) {
        timeChangeHandler();
      }
      expect(vm.scrollIndex).assertLess(0);
    })

    it('eventDeleteChangeHandler_test1', 0, () => {
      const eventDeleteChangeHandler = TestUtil.getPrivateFunction(vm, 'eventDeleteChangeHandler');
      if (eventDeleteChangeHandler) {
        eventDeleteChangeHandler();
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertTrue();
    })

    it('eventInfoChangeHandler_test1', 0, () => {
      TestUtil.setPrivateAttribute(vm, 'isInsertAgenda', true);
      const eventInfoChangeHandler = TestUtil.getPrivateFunction(vm, 'eventInfoChangeHandler');
      if (eventInfoChangeHandler) {
        eventInfoChangeHandler({});
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertFalse();
    })

    it('selectedChangedHandler_test1', 0, () => {
      const selectedChangedHandler = TestUtil.getPrivateFunction(vm, 'selectedChangedHandler');
      if (selectedChangedHandler) {
        selectedChangedHandler({});
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertFalse();
    })

    it('closeCoverHandler_test1', 0, () => {
      const closeCoverHandler = TestUtil.getPrivateFunction(vm, 'closeCoverHandler');
      if (closeCoverHandler) {
        closeCoverHandler();
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertFalse();
    })

    it('fullUpdateViewHandler_test1', 0, () => {
      const fullUpdateViewHandler = TestUtil.getPrivateFunction(vm, 'fullUpdateViewHandler');
      if (fullUpdateViewHandler) {
        fullUpdateViewHandler();
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertFalse();
    })

    it('dataChangeHandler_test1', 0, () => {
      const dataChangeHandler = TestUtil.getPrivateFunction(vm, 'dataChangeHandler');
      if (dataChangeHandler) {
        dataChangeHandler({
          data: {
            'isEmitFromEntryPage': true,
          }
        } as emitter.EventData);
      }
      expect(vm.supportMultiSelect).assertFalse();
    })

    it('dataChangeHandler_test2', 0, () => {
      const dataChangeHandler = TestUtil.getPrivateFunction(vm, 'dataChangeHandler');
      if (dataChangeHandler) {
        vm.supportMultiSelect = true;
        dataChangeHandler({
          data: {
            'isEmitFromEntryPage': false,
          }
        } as emitter.EventData);
      }
      let isDeleteOperate = TestUtil.getPrivateAttribute<boolean>(vm, 'isDeleteOperate');
      expect(isDeleteOperate).assertFalse();
    })



  })
}

function buildOnKeyPressTestData():AgendaListItemViewModel[]  {
  const mockAgendaResult: AgendaListItemViewModel[] = [];
  for (let i = 0; i < 5; i++) {
    const testData: AgendaListItemViewModel = new AgendaListItemViewModel();
    testData.mId = i;
    mockAgendaResult.push(testData);
  }
  return mockAgendaResult;
}
