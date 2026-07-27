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

import { afterAll, afterEach, ArgumentMatchers, beforeAll, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { AgendaEventInfo, CalendarContract, CalendarDate, EventService, ReminderService, Result} from '@app/common';
import { ValuesBucket } from '@kit.ArkData';
import { TestUtil } from '../../utils/TestUtil';
import { DataShareResultSetMock } from './DataShareHelperMock';

export default function EventServiceTest() {
  describe('EventServiceTest', () => {
    let mockDataShareResultSet: DataShareResultSetMock | null;
    let mocker: MockKit = new MockKit();
    let eventService: EventService = EventService.INSTANCE;
    beforeAll(() => {
    });

    beforeEach(() => {
      mocker = new MockKit();
      mockDataShareResultSet?.goToFirstRow();
    });

    afterEach(() => {
      mockDataShareResultSet?.close();
      mocker.clearAll();
    });

    afterAll(() => {
      mockDataShareResultSet = null;
    });

    it('queryEventByEventId', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventById: Function = mocker.mockFunc(repo, repo.queryEventById);
      when(queryEventById)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await eventService.queryEventByEventId(1)).assertUndefined(); //执行通过
      done();
    });

    it('queryHolidayEventByTitle', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.queryHolidayEventByTitle);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await eventService.queryHolidayEventByTitle('元旦', 1)).assertUndefined();
      done();
    });

    it('queryEventById_1', 0, async (done: Function) => {
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(eventService, eventService.queryEventByEventId);
      when(mockfunc)(eventId).afterReturnNothing();
      const agenda = await eventService.queryEventById(eventId);
      expect(agenda?.mId).assertEqual(0);
      done();
    });

    it('queryEventById_2', 0, async (done: Function) => {
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(eventService, eventService.queryEventByEventId);
      when(mockfunc)(eventId).afterThrow('这是个主动抛出的错误');

      // 对mock后的函数进行断言，看是否符合预期
      const agenda = await eventService.queryEventById(eventId);
      expect(agenda?.mId).assertEqual(0);
      done();
    });

    it('queryEventById_3', 0, async (done: Function) => {
      const eventId: number = 1;
      let queryEventByEventId: Function = mocker.mockFunc(eventService, eventService.queryEventByEventId);

      const mockDataShareResultSet = new DataShareResultSetMock()
      when(queryEventByEventId)(eventId).afterReturn(mockDataShareResultSet);
      let mockfunc_2: Function = mocker.mockFunc(mockDataShareResultSet, mockDataShareResultSet.goToFirstRow);
      when(mockfunc_2)(eventId).afterThrow('这是个主动抛出的错误');

      // 对mock后的函数进行断言，看是否符合预期
      const agenda = await eventService.queryEventById(eventId);
      expect(agenda?.mId).assertEqual(0);
      mocker.ignoreMock(eventService, queryEventByEventId);
      done();
    });

    it('queryEventById', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.queryEventById);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());

      let eventInfo = await eventService.queryEventById(1) as AgendaEventInfo;
      expect(eventInfo.alertType).not().assertNull();
      expect(eventInfo.alertType).assertEqual(0)
      done();
    });

    it('groupAgendaByDay_empty_originList', 0, async (done: Function) => {
      let groupAgendaByDay = TestUtil.getPrivateFunction(eventService, 'groupAgendaByDay');
      if (groupAgendaByDay) {
        let result: Array<AgendaEventInfo> = await groupAgendaByDay([], 0, 0);
        expect(result.length).assertEqual(0)
      }
      done();
    });

    // should return an array with the same elements when startJulianDay is greater than endJulianDay
    it('groupAgendaByDay_01', 0, async (done: Function) => {
      let info1 = new AgendaEventInfo;
      info1.mStartDay = 3;
      info1.mEndDay = 2;
      info1.mBegin = 1;
      info1.mEnd = 1;
      let groupAgendaByDay = TestUtil.getPrivateFunction(eventService, 'groupAgendaByDay');
      if (groupAgendaByDay) {
        let result: Array<AgendaEventInfo> = await groupAgendaByDay([info1], 2, 1);
        expect(result.length).assertEqual(0)
      }
      done();
    });

    // should return an array with the same elements when startJulianDay is equal to endJulianDay
    it('groupAgendaByDay_02', 0, async (done: Function) => {
      let info1 = new AgendaEventInfo;
      info1.mStartDay = 1;
      info1.mEndDay = 1;
      info1.mBegin = 2;
      info1.mEnd = 1;
      let info2 = new AgendaEventInfo;
      info2.mStartDay = 1;
      info2.mEndDay = 1;
      info1.mBegin = 1;
      info1.mEnd = 2;

      let info3 = new AgendaEventInfo;
      info3.mStartDay = 1;
      info3.mEndDay = 1;
      info3.mBegin = 1;
      info3.mEnd = 3;

      let groupAgendaByDay = TestUtil.getPrivateFunction(eventService, 'groupAgendaByDay');
      if (groupAgendaByDay) {
        let result: Array<AgendaEventInfo> = await groupAgendaByDay([info1, info2, info3], 1, 1);
        expect(result.length).assertEqual(3)
      }
      done();
    });

    // should return an array with the same elements when startJulianDay is equal to endJulianDay
    it('groupAgendaByDay_03', 0, async (done: Function) => {
      let info1 = new AgendaEventInfo;
      info1.mStartDay = 1;
      info1.mEndDay = 2;
      info1.mBegin = 1;
      info1.mEnd = 2;

      let info2 = new AgendaEventInfo;
      info2.mStartDay = 1;
      info2.mEndDay = 1;
      info2.mBegin = 1;
      info2.mEnd = 3;
      let groupAgendaByDay = TestUtil.getPrivateFunction(eventService, 'groupAgendaByDay')!;
      let result: Array<AgendaEventInfo> = await groupAgendaByDay([info1, info2], 1, 2);
      expect(result.length).assertEqual(3)
      done();
    });

    it('groupOneDay_empty', 0, async (done: Function) => {
      let groupOneDay = TestUtil.getPrivateFunction(eventService, 'groupOneDay');
      if (groupOneDay) {
        let originList: Array<AgendaEventInfo> = [];
        let day: number = 1;
        let oneDayList: AgendaEventInfo[] = [];
        oneDayList = groupOneDay(originList, day);
        expect(oneDayList.length).assertEqual(0);
      }
      done();
    });

    it('groupOneDay_01', 0, async (done: Function) => {
      let groupOneDay = TestUtil.getPrivateFunction(eventService, 'groupOneDay');
      if (groupOneDay) {
        const info = new AgendaEventInfo();
        const day = 1;
        info.mStartDay = 2;
        expect(await groupOneDay([info], day).length).assertEqual(0);
      }
      done();
    });

    it('groupOneDay_02', 0, async (done: Function) => {
      let groupOneDay = TestUtil.getPrivateFunction(eventService, 'groupOneDay');
      if (groupOneDay) {
        const info = new AgendaEventInfo();
        const day = 1;
        info.mStartDay = 2;
        expect(await groupOneDay([info], day).length).assertEqual(0);
      }
      done();
    });

    it('updateEventAndReminder_valuesArrayChange_true', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.updateByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(1);
      let isSucceed = await eventService.updateEventAndReminder(-1, [], true, true, 1);
      expect(isSucceed).assertEqual(false);
      done();
    });

    it('updateEventAndReminder_valuesArrayChange_false', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.updateByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(1);
      let isSucceed = await eventService.updateEventAndReminder(1, [], false, true, 1);
      expect(isSucceed).assertEqual(true);
      done();
    });

    it('updateEventAndReminder_updateByEventId_catch_error', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.updateByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterThrow('111');
      let isSucceed = await eventService.updateEventAndReminder(1, [], false, true, 1);
      expect(isSucceed).assertEqual(false);
      done();
    });

    it('deleteEventById', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.deleteEventByEventIds);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(2);
      let isDeleted = await eventService.deleteEventById(1);
      expect(isDeleted).assertEqual(2);
      done();
    });

    it('deleteEventById_catch_error', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.deleteEventByEventIds);
      when(mockFunc)(ArgumentMatchers.any).afterThrow('111');
      let isDeleted = await eventService.deleteEventById(1);
      expect(isDeleted).assertEqual(-1);
      done();
    });

    it('deleteEvents', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.deleteEventByEventIds);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(2);
      let idSet: Set<number> = new Set([1, 2]);
      let isDeleted = await eventService.deleteEvents(idSet);
      expect(isDeleted).assertEqual(2);
      done();
    });

    it('deleteEvents_catch_error', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.deleteEventByEventIds);
      when(mockFunc)(ArgumentMatchers.any).afterThrow('111');
      let idSet: Set<number> = new Set([1, 2]);
      let isDeleted = await eventService.deleteEvents(idSet);
      expect(isDeleted).assertEqual(-1);
      done();
    });

    it('insertEvent', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.insertEvents);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(2);

      const value = {} as ValuesBucket;
      let isDeleted = await eventService.insertEvent(value);
      expect(isDeleted).assertEqual(2);
      done();
    });

    it('insertEvent_catch_error', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.insertEvents);
      when(mockFunc)(ArgumentMatchers.any).afterThrow('111');
      const value = {} as ValuesBucket;
      let isDeleted = await eventService.insertEvent(value);
      expect(isDeleted).assertEqual(-1);
      done();
    });

    it('insertReminder_eventId_less_than_0', 0, async (done: Function) => {
      let reminder = new CalendarContract.Reminders;
      let isDeleted = await eventService.insertReminder(0, [reminder]);
      expect(isDeleted).assertEqual(false);
      done();
    });

    it('insertReminder_checkValuesArray_empty', 0, async (done: Function) => {
      let isDeleted = await eventService.insertReminder(2, []);
      expect(isDeleted).assertEqual(false);
      done();
    });

    it('insertReminder_catch_error', 0, async (done: Function) => {
      let reminderService = ReminderService.INSTANCE;
      let insertReminderArray: Function = mocker.mockFunc(reminderService,
        reminderService.insertReminderArray);
      when(insertReminderArray)(ArgumentMatchers.any).afterThrow('111');
      let reminder = new CalendarContract.Reminders;
      let isDeleted = await eventService.insertReminder(2, [reminder]);
      expect(isDeleted).assertEqual(false);
      mocker.ignoreMock(reminderService, insertReminderArray);
      done();
    });

    it('insertReminder', 0, async (done: Function) => {
      let reminderService = ReminderService.INSTANCE;
      let insertReminderArray: Function = mocker.mockFunc(reminderService,
        reminderService.insertReminderArray);
      when(insertReminderArray)(ArgumentMatchers.any).afterReturn(true);
      let reminder = new CalendarContract.Reminders;
      let isDeleted = await eventService.insertReminder(2, [reminder]);
      expect(isDeleted).assertEqual(true);
      mocker.ignoreMock(reminderService, insertReminderArray);
      done();
    });

    it('queryEvents', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEvents: Function = mocker.mockFunc(repo, repo.queryEvents);
      when(queryEvents)(ArgumentMatchers.any).afterReturn(undefined);
      let events = await eventService.queryEvents();
      expect(events).assertEqual(undefined);
      done();
    });

    it('updateByEventId', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.updateByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(2);

      const value = {} as ValuesBucket;
      let isDeleted = await eventService.updateByEventId(1, value);
      expect(isDeleted).assertEqual(2);
      done();
    });

    it('queryEventByAccountId_undefined', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByAccountId: Function = mocker.mockFunc(repo, repo.queryEventsByAccountId);
      when(queryEventsByAccountId)(ArgumentMatchers.any).afterReturn(undefined);
      let events = await eventService.queryEventByAccountId(1);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventByAccountId_query_empty', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByAccountId: Function = mocker.mockFunc(repo, repo.queryEventsByAccountId);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 0;
      when(queryEventsByAccountId)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventByAccountId(1);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventByAccountId_goToFirstRow_failed', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByAccountId: Function = mocker.mockFunc(repo, repo.queryEventsByAccountId);
      let resultSet = new DataShareResultSetMock();
      resultSet.rowCount = 1;
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(false);
      when(queryEventsByAccountId)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventByAccountId(1);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventByAccountId', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByAccountId: Function = mocker.mockFunc(repo, repo.queryEventsByAccountId);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 1;
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
      when(queryEventsByAccountId)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventByAccountId(1);
      expect(events.length).assertEqual(2);
      done();
    });

    it('queryEventByAccountId_catch', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByAccountId: Function = mocker.mockFunc(repo, repo.queryEventsByAccountId);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 1;
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterThrow('true');
      when(queryEventsByAccountId)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventByAccountId(1);
      expect(events.length).assertEqual(0);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventsByEventIds_empty', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByIds: Function = mocker.mockFunc(repo, repo.queryEventsByIds);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 0;
      when(queryEventsByIds)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventsByEventIds([]);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventsByEventIds_goToFirstRow_failed', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByIds: Function = mocker.mockFunc(repo, repo.queryEventsByIds);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 1;
      when(queryEventsByIds)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventsByEventIds([]);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventsByEventIds_catch', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByIds: Function = mocker.mockFunc(repo, repo.queryEventsByIds);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 1;
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterThrow('true');
      when(queryEventsByIds)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventsByEventIds([]);
      expect(events.length).assertEqual(0);
      done();
    });

    it('queryEventsByEventIds', 0, async (done: Function) => {
      let repo = eventService.repo;
      let queryEventsByIds: Function = mocker.mockFunc(repo, repo.queryEventsByIds);
      let resultSet = new DataShareResultSetMock;
      resultSet.rowCount = 1;
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
      when(queryEventsByIds)(ArgumentMatchers.any).afterReturn(resultSet);
      let events = await eventService.queryEventsByEventIds([]);
      expect(events.length).assertEqual(2);
      done();
    });

    it('deleteEventByEventIds', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(eventService, eventService.deleteEventByEventIds);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(2);

      let isDeleted = await eventService.deleteEventByEventIds([]);
      expect(isDeleted).assertEqual(2);
      done();
    });

    it('deleteEventByEventUuids_01', 0, async (done: Function) => {
      let deleteResult = await eventService.deleteEventByEventUuids([]);
      expect(deleteResult.isSuccess()).assertTrue();
      done();
    });

    it('deleteEventByEventUuids_02', 0, async (done: Function) => {
      let repo = eventService.repo;
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteByUuids);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(2));
      let deleteResult = await eventService.deleteEventByEventUuids(['xxx']);
      expect(deleteResult.data).assertEqual(2);
      done();
    });

    it('queryAllEvents_01', 0, async (done: Function) => {
      const calendarUuid = 'abc';
      let queryEvents: Function = mocker.mockFunc(eventService, eventService.queryAllEvents);
      when(queryEvents)(calendarUuid).afterReturn([1,2,3]);
      const eventIds = await eventService.queryAllEvents(calendarUuid);
      expect(eventIds.length).assertEqual(3);
      done();
    });

    it('queryAllEvents_02', 0, async (done: Function) => {
      const calendarUuid = '';
      let queryEvents: Function = mocker.mockFunc(eventService, eventService.queryAllEvents);
      when(queryEvents)(calendarUuid).afterReturn([]);
      const eventIds = await eventService.queryAllEvents(calendarUuid);
      expect(eventIds.length).assertEqual(0);
      done();
    });

    it('queryNormalEvents_01', 0, async (done: Function) => {
      const calendarUuid = 'abc';
      let queryNormalEvents: Function = mocker.mockFunc(eventService, eventService.queryNormalEvents);
      when(queryNormalEvents)(calendarUuid).afterReturn([1, 2, 3, 4, 5]);
      const eventIds = await eventService.queryNormalEvents(calendarUuid);
      expect(eventIds.length).assertEqual(5);
      done();
    });

    it('queryNormalEvents_02', 0, async (done: Function) => {
      const calendarUuid = '';
      let queryNormalEvents: Function = mocker.mockFunc(eventService, eventService.queryNormalEvents);
      when(queryNormalEvents)(calendarUuid).afterReturn([]);
      const eventIds = await eventService.queryNormalEvents(calendarUuid);
      expect(eventIds.length).assertEqual(0);
      done();
    });
  });
}
