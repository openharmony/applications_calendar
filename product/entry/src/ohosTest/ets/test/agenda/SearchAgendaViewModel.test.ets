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
import { beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import {
  AgendaEventInfo,
  AgendaListDataSource,
  AgendaListItemViewModel,
  CalendarDate,
  DateUtil,
  EventService,
  InstanceService,
  Log,
  QueryInfo
} from '@app/common';
import SearchAgendaViewModel from '@app/feature.agenda/src/main/ets/SearchAgenda/viewmodel/SearchAgendaViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { AGENDA_SEARCH_DATE_BEGIN } from '@app/common/src/main/ets/agenda/Constants';
import { KeyCode } from '@kit.InputKit';
import { TestUtil } from '../utils/TestUtil';

const TAG = 'searchAgendaViewModelTest';

export default function SearchAgendaModelTest() {
  describe('searchAgendaViewModel', () => {
    let searchAgendaViewModel: SearchAgendaViewModel;
    const defaultDisplayDate: number = Date.now();
    const defaultCheckEventId: number = 1;
    const defaultCurrentDate: number = Date.now();
    const defaultChangeValue: string = '';
    const defaultShowResult: boolean = false;
    const defaultCalendarUuid: string = '';
    const defaultShowEventId: number = -1;
    const defaultCurrentDisplayStartMills: number = 0;
    const defaultCurrentDisplayEndMills: number = 0;
    const defaultIsInPop: boolean = false;
    const mScroller: Scroller = new Scroller();
    const mockAgendaInfo: AgendaListItemViewModel = new AgendaListItemViewModel();

    beforeEach(async (done: Function) => {
      searchAgendaViewModel = new SearchAgendaViewModel(
        defaultDisplayDate,
        defaultCheckEventId,
        defaultCurrentDate,
        defaultChangeValue,
        defaultShowResult,
        defaultCalendarUuid,
        (firstEventId: number, isContainCheckId: boolean) => {
          Log.info(TAG, `firstEventId = ${firstEventId}, isContainCheckId = ${isContainCheckId}`);
        },
        () => {
        },
        defaultShowEventId,
        defaultCurrentDisplayStartMills,
        defaultCurrentDisplayEndMills,
        () => {
        },
        defaultIsInPop,
        mScroller
      );
      done();
    })

    // 测试系统事件的监听是否生效
    it('searchAgendaViewModel_builder', 0, async (done: Function) => {
      Log.info(TAG, `${TAG}searchAgendaViewModel_builder begin`);
      expect(searchAgendaViewModel).not().assertNull();
      expect(searchAgendaViewModel?.subscribeEvents()).assertEqual(true);
      expect(searchAgendaViewModel?.unsubscribeEvents()).assertEqual(true);
      done()
    })

    it('searchAgendaViewModel_onChangeValueChange', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onChangeValueChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onTimeChange()).assertEqual(true);
      done()
    })

    it('searchAgendaViewModel_onTimeChange', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} SearchAgendaModel_onTimeChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      expect(await searchAgendaViewModel?.onTimeChange()).assertEqual(false);
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onTimeChange()).assertEqual(true);
      done()
    })

    it('searchAgendaViewModel_onDataChange_Events', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onDataChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      const eventData: emitter.EventData = {
        data: {
          table: 'Events'
        }
      }

      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(false);
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(true);
      done();
    })

    it('searchAgendaViewModel_onDataChange_Calendars', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onDataChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      const eventData: emitter.EventData = {
        data: {
          table: 'Calendars'
        }
      }

      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(false);
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(true);
      done();
    })

    it('searchAgendaViewModel_onDataChange_Instance', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onDataChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      const eventData: emitter.EventData = {
        data: {
          table: 'Instances'
        }
      }

      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(false);
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onDataChange(eventData)).assertEqual(false);
      done();
    })

    it('searchAgendaViewModel_onCurrentDateChange', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onCurrentDateChange begin`);
      expect(searchAgendaViewModel).not().assertNull();
      expect(await searchAgendaViewModel?.onCurrentDateChange(Date.now())).assertEqual(false);
      await searchAgendaViewModel?.onChangeValueChange('dad');
      expect(await searchAgendaViewModel?.onTimeChange()).assertEqual(true);
      done()
    })

    it('searchAgendaViewModel_deleteEventById_Normal', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_deleteEventById_Normal begin`);

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();
      let eventService: EventService = EventService.INSTANCE;

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(EventService.INSTANCE, EventService.INSTANCE.deleteEventById);
      when(mockfunc)(eventId).afterReturn(1);
      (searchAgendaViewModel as SearchAgendaViewModel).clickId = eventId;
      expect(await searchAgendaViewModel?.deleteEventById()).assertEqual(true);
      done();
    })

    it('searchAgendaViewModel_deleteEventById_Error', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_deleteEventById_Normal begin`);

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();
      let eventService: EventService = EventService.INSTANCE;

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(eventService, eventService.deleteEventById);
      when(mockfunc)(eventId).afterThrow('这是一个主动抛出的错误');
      (searchAgendaViewModel as SearchAgendaViewModel).clickId = eventId;
      expect(await searchAgendaViewModel?.deleteEventById()).assertEqual(false);
      done();
    })

    it('searchAgendaViewModel_deleteEventById_Undefined', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_deleteEventById_Normal begin`);

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();
      let eventService: EventService = EventService.INSTANCE;

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(eventService, eventService.deleteEventById);
      when(mockfunc)(eventId).afterReturnNothing();
      (searchAgendaViewModel as SearchAgendaViewModel).clickId = eventId;
      expect(await searchAgendaViewModel?.deleteEventById()).assertEqual(false);
      done();
    })

    it('searchAgendaViewModel_searchPastAgenda', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const temp: QueryInfo = {} as QueryInfo;
      temp.startTime = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime();
      temp.endTime = defaultDisplayDate;
      temp.searchText = '';
      temp.currentPage = 1;

      let mockfunc: Function = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      const mockAgendaEventInfo = new AgendaEventInfo();
      when(mockfunc)(temp).afterReturn([mockAgendaEventInfo, mockAgendaEventInfo]);

      expect((await searchAgendaViewModel?.searchPastAgenda() as AgendaEventInfo[])?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_searchFutureAgenda', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const temp: QueryInfo = {} as QueryInfo;
      temp.startTime = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime();
      temp.endTime = defaultDisplayDate;
      temp.searchText = '';
      temp.currentPage = 1;

      let mockfunc: Function = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      const mockAgendaEventInfo = new AgendaEventInfo();
      when(mockfunc)(temp).afterReturn([mockAgendaEventInfo, mockAgendaEventInfo]);

      expect((await searchAgendaViewModel?.searchFutureAgenda() as AgendaEventInfo[])?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_searchPastAgenda_searchTextNull', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const temp: QueryInfo = {} as QueryInfo;
      temp.startTime = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime();
      temp.endTime = defaultDisplayDate;
      temp.currentPage = 1;

      let mockfunc: Function = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      const mockAgendaEventInfo = new AgendaEventInfo();
      when(mockfunc)(temp).afterReturn([mockAgendaEventInfo, mockAgendaEventInfo]);

      expect((await searchAgendaViewModel?.searchPastAgenda() as AgendaEventInfo[])?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_searchFutureAgenda_searchTextNull', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const temp: QueryInfo = {} as QueryInfo;
      temp.startTime = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime();
      temp.endTime = defaultDisplayDate;
      temp.currentPage = 1;

      let mockfunc: Function = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      const mockAgendaEventInfo = new AgendaEventInfo();
      when(mockfunc)(temp).afterReturn([mockAgendaEventInfo, mockAgendaEventInfo]);

      expect((await searchAgendaViewModel?.searchFutureAgenda() as AgendaEventInfo[])?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_searchCalendarAgenda', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();

      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();

      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const temp: QueryInfo = {} as QueryInfo;
      temp.startTime = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime();
      temp.endTime = defaultDisplayDate;
      temp.searchText = '';
      temp.currentPage = 1;
      temp.calendarId = 1;

      let mockfunc: Function = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      const mockAgendaEventInfo = new AgendaEventInfo();
      when(mockfunc)(temp).afterReturn([mockAgendaEventInfo, mockAgendaEventInfo]);

      expect((await searchAgendaViewModel?.searchFutureAgenda() as AgendaEventInfo[])?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_NothingInput', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      expect(searchAgendaViewModel?.getNearAgendaOfArray([], 0)?.length).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_SimpleInput_1', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 1;
      const datas = [mockAgendaEventInfo_1];
      const julianDay = 1;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)[0]).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_SimpleInput_2', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 1;
      const datas = [mockAgendaEventInfo_1];
      const julianDay = 78;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)[0]).assertEqual(0);
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_ComplexInput_1', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 1782144;
      const mockAgendaEventInfo_2 = new AgendaEventInfo();
      mockAgendaEventInfo_2.mDay = 166;
      const mockAgendaEventInfo_3 = new AgendaEventInfo();
      mockAgendaEventInfo_3.mDay = 1645645;
      const datas = [mockAgendaEventInfo_1, mockAgendaEventInfo_2, mockAgendaEventInfo_3];
      const julianDay = 1645645;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(JSON.stringify(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay))).assertEqual('[0]');
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_ComplexInput_2', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 1782144;
      const mockAgendaEventInfo_2 = new AgendaEventInfo();
      mockAgendaEventInfo_2.mDay = 166;
      const mockAgendaEventInfo_3 = new AgendaEventInfo();
      mockAgendaEventInfo_3.mDay = 1645645;
      const datas = [mockAgendaEventInfo_1, mockAgendaEventInfo_2, mockAgendaEventInfo_3];
      const julianDay = 78;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(JSON.stringify(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay))).assertEqual('[0]');
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_ComplexInput_3', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 66;
      const mockAgendaEventInfo_2 = new AgendaEventInfo();
      mockAgendaEventInfo_2.mDay = 1782144;
      const mockAgendaEventInfo_3 = new AgendaEventInfo();
      mockAgendaEventInfo_3.mDay = 1645645;
      const datas = [mockAgendaEventInfo_1, mockAgendaEventInfo_2, mockAgendaEventInfo_3];
      const julianDay = 78;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(JSON.stringify(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay))).assertEqual('[1]');
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_ComplexInput_4', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 166;
      const mockAgendaEventInfo_2 = new AgendaEventInfo();
      mockAgendaEventInfo_2.mDay = 1782144;
      const mockAgendaEventInfo_3 = new AgendaEventInfo();
      mockAgendaEventInfo_3.mDay = 1782144;
      const mockAgendaEventInfo_4 = new AgendaEventInfo();
      mockAgendaEventInfo_4.mDay = 1645645;
      const datas = [mockAgendaEventInfo_1, mockAgendaEventInfo_2, mockAgendaEventInfo_3, mockAgendaEventInfo_4];
      const julianDay = 1782144;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(2);
      expect(JSON.stringify(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay))).assertEqual('[1,2]');
      done();
    })

    it('searchAgendaViewModel_getNearAgendaOfArray_ComplexInput_5', 0, async (done: Function) => {
      expect(searchAgendaViewModel).not().assertNull();
      const mockAgendaEventInfo_1 = new AgendaEventInfo();
      mockAgendaEventInfo_1.mDay = 166;
      const mockAgendaEventInfo_2 = new AgendaEventInfo();
      mockAgendaEventInfo_2.mDay = 1782144;
      const mockAgendaEventInfo_3 = new AgendaEventInfo();
      mockAgendaEventInfo_3.mDay = 1782144;
      const mockAgendaEventInfo_4 = new AgendaEventInfo();
      mockAgendaEventInfo_4.mDay = 1645645;
      const datas = [mockAgendaEventInfo_1, mockAgendaEventInfo_2, mockAgendaEventInfo_3, mockAgendaEventInfo_4];
      const julianDay = 1645645;
      expect(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay)?.length).assertEqual(1);
      expect(JSON.stringify(searchAgendaViewModel?.getNearAgendaOfArray(datas, julianDay))).assertEqual('[1]');
      done();
    })

    it('searchAgendaViewModel_onDeleteEventByID_Normal', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onDeleteEventByID_Normal begin`);
      const eventData: emitter.EventData = {
        data: {
          'eventId': 1
        }
      }
      expect(searchAgendaViewModel?.onDeleteEventByID(eventData)).assertEqual(true);
      done();
    })

    it('searchAgendaViewModel_onDeleteEventByID_Error', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} searchAgendaViewModel_onDeleteEventByID_Error begin`);
      const eventData: emitter.EventData = {}
      expect(searchAgendaViewModel?.onDeleteEventByID(eventData)).assertEqual(false);
      done();
    })

    it('searchAgendaViewModel_getCheckedIdentity', 0, async (done: Function) => {
      const eventInfo: AgendaEventInfo = new AgendaEventInfo();
      eventInfo.mId = 1;
      eventInfo.mBegin = 2;
      eventInfo.mDay = 3;
      expect(searchAgendaViewModel?.getCheckedIdentity(eventInfo)).assertEqual('1_2_3');
      done();
    })

    it('onKeyPress_1', 0, async (done: Function) => {
      const eventInfo_1: AgendaEventInfo = new AgendaEventInfo();
      eventInfo_1.mId = 1;
      eventInfo_1.mBegin = 2;
      eventInfo_1.mDay = 3;
      const eventInfo_2: AgendaEventInfo = new AgendaEventInfo();
      eventInfo_2.mId = 11;
      eventInfo_2.mBegin = 22;
      eventInfo_2.mDay = 33;

      searchAgendaViewModel?.onItemClick(eventInfo_1);
      const agendaListItemViewModel_1: AgendaListItemViewModel = new AgendaListItemViewModel(eventInfo_1);
      const agendaListItemViewModel_2: AgendaListItemViewModel = new AgendaListItemViewModel(eventInfo_1);
      const datas: AgendaListItemViewModel[] = [agendaListItemViewModel_1, agendaListItemViewModel_2];
      searchAgendaViewModel!.dataSources = new AgendaListDataSource(datas);
      expect(searchAgendaViewModel?.onKeyPress(KeyCode.KEYCODE_DPAD_DOWN)).assertTrue();
      done();
    })

    it('onKeyPress_2', 0, async (done: Function) => {
      const eventInfo: AgendaEventInfo = new AgendaEventInfo();
      eventInfo.mId = 1;
      eventInfo.mBegin = 2;
      eventInfo.mDay = 3;
      searchAgendaViewModel?.onItemClick(eventInfo);
      const datas: AgendaListItemViewModel[] = [];
      searchAgendaViewModel!.dataSources = new AgendaListDataSource(datas);
      expect(searchAgendaViewModel?.onKeyPress(KeyCode.KEYCODE_DPAD_DOWN)).assertFalse();
      done();
    })


    it('onFirstSearch', 0, async (done: Function) => {
      let success = await searchAgendaViewModel?.onFirstSearch();
      if (success) {
        let eventJulianDayMap = new Map<number, number>();
        searchAgendaViewModel?.datas.forEach(e=>{
          let julianDay = eventJulianDayMap.get(e.mId);
          if (julianDay == undefined) {
            eventJulianDayMap.set(e.mId, e.mDay);
            expect(julianDay).assertUndefined();
          } else {
            expect(e.mDay != julianDay).assertFalse();
          }
        })
      }
      done();
    })

    // should set isShowBackToday to false when agendaResult is empty
    it('changeBackTodayStatus_01', 0, async (done: Function) => {
      const mockAgendaResult: AgendaListItemViewModel[] = [];
      searchAgendaViewModel.datas = mockAgendaResult;
      const startIndex = 10;
      const endIndex = 20;
      searchAgendaViewModel.changeBackTodayStatus(startIndex, endIndex);
      expect(searchAgendaViewModel.isShowBackToday).assertFalse();
      done();
    });

    // should set isShowBackToday according to the expression (first > endIndex) || (last < startIndex)
    it('changeBackTodayStatus_03', 0, async (done: Function) => {
      const mockTodayEventsIndexArr: number[] = [15];
      const mockAgendaResult: AgendaListItemViewModel[] = [mockAgendaInfo];
      TestUtil.setPrivateAttribute(searchAgendaViewModel, 'todayEventsIndexArr', mockTodayEventsIndexArr);
      searchAgendaViewModel.datas = mockAgendaResult;
      const startIndex = 10;
      const endIndex = 20;
      searchAgendaViewModel.changeBackTodayStatus(startIndex, endIndex);
      expect(searchAgendaViewModel.isShowBackToday).assertFalse();
      done();
    });

    it('isTodayInRange_returnFalse_when_datasIsEmpty', 0, () => {
      searchAgendaViewModel.datas = [];
      const isTodayInRange = TestUtil.getPrivateFunction(searchAgendaViewModel, 'isTodayInRange');
      if (isTodayInRange) {
        expect(isTodayInRange()).assertFalse();
      }
    });

    it('isTodayInRange_returnFalse_when_todayIsNotInRange', 0, () => {
      const today = new CalendarDate();
      const nextDay = new CalendarDate(today.setDate(today.getDate() + 1));
      const nextDayJulianDay = nextDay.getJulianDay();
      const mockInfo1 = new AgendaListItemViewModel();
      const mockInfo2 = new AgendaListItemViewModel();
      mockInfo1.mBegin = today.setHours(0, 0, 0, 0) / 1000;
      mockInfo2.mBegin = today.setHours(23, 59, 59, 999) / 1000;
      searchAgendaViewModel.datas = [mockInfo1, mockInfo2];
      searchAgendaViewModel.currentJulianDay = nextDayJulianDay;
      const isTodayInRange = TestUtil.getPrivateFunction(searchAgendaViewModel, 'isTodayInRange');
      if (isTodayInRange) {
        expect(isTodayInRange()).assertFalse();
      }
    });
  })
}