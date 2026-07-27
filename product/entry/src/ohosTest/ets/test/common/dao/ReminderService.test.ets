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
import { CalendarContract, ReminderService } from '@app/common/index';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ReminderRepository } from '@app/common/src/main/ets/dao/repo/ReminderRepository';
import { DataShareResultSetMock } from './DataShareHelperMock';

const TAG = 'ReminderServiceTest';
const errMsg = "这是一个主动抛出的错误";

export default function ReminderServiceTest() {
  describe('ReminderServiceTest', () => {
    let service = ReminderService.INSTANCE;
    let repo: ReminderRepository;
    let mocker: MockKit;
    const eventId: number = 0;
    let reminder: CalendarContract.Reminders;

    beforeEach(() => {
      mocker = new MockKit();
      repo = new ReminderRepository;
      service.repo = repo;
      reminder = new CalendarContract.Reminders();
    })

    afterEach(() => {
      mocker.clearAll()
    })

    it('insertReminder', 0, async (done: Function) => {
      when(mocker.mockFunc(repo, repo.insertReminder))(ArgumentMatchers.any).afterReturn(0);
      expect(await service.insertReminder(reminder)).assertEqual(0);
      done();
    });

    it('updateReminderByReplace_rowsDeleted_less_0', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteReminderByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(-1);
      expect(await service.updateReminderByReplace(eventId, [], 1)).assertEqual(false);
      done()
    })

    it('updateReminderByReplace_rowsDeleted_0', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteReminderByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(0);
      expect(await service.updateReminderByReplace(eventId, [], 1)).assertEqual(true);
      done()
    })

    it('updateReminderByReplace_1', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteReminderByEventId);
      let checkValuesArray: CalendarContract.Reminders[] = [new CalendarContract.Reminders];
      expect(await service.updateReminderByReplace(eventId, checkValuesArray, 1)).assertEqual(false);
      when(mockFunc)(ArgumentMatchers.any).afterThrow(errMsg);
      expect(await service.updateReminderByReplace(eventId, checkValuesArray, 1)).assertEqual(false);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(-1);
      expect(await service.updateReminderByReplace(eventId, checkValuesArray, 1)).assertEqual(false);
      done();
    });

    it('insertReminderArray_input_invalid', 0, async (done: Function) => {
      expect(await service.insertReminderArray(eventId, undefined)).assertFalse();
      done()
    })

    it('insertReminderArray_insert_01', 0, async (done: Function) => {
      let checkValuesArray: CalendarContract.Reminders[] =
        [new CalendarContract.Reminders, new CalendarContract.Reminders];
      let mockFunc: Function = mocker.mockFunc(service, service.insertReminder);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(0);
      expect(await service.insertReminderArray(eventId, checkValuesArray)).assertFalse();
      done()
    })

    it('insertReminderArray_insert_02', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(service, service.insertReminder);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(1);
      let checkValuesArray: CalendarContract.Reminders[] =
        [new CalendarContract.Reminders, new CalendarContract.Reminders];
      expect(await service.insertReminderArray(eventId, checkValuesArray)).assertTrue();
      done()
    })

    it('insertReminderArray_insert_03', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(service, service.insertReminder);
      when(mockFunc)(ArgumentMatchers.any).afterThrow(errMsg);
      let checkValuesArray: CalendarContract.Reminders[] =
        [new CalendarContract.Reminders, new CalendarContract.Reminders];
      expect(await service.insertReminderArray(eventId, checkValuesArray)).assertFalse();
      done();
    });

    it('queryReminderInfoByEventIds_01', 0, async (done: Function) => {
      const result = await service.queryReminderInfoByEventIds([]);
      expect(result.length).assertEqual(0);
      done();
    });

    it('queryReminderInfoByEventIds_02', 0, async (done: Function) => {
      let eventIds: Array<number> = [0];
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryReminderByEventIds);
      const resultSet = new DataShareResultSetMock();
      when(mockFunc)(ArgumentMatchers.any).afterReturn(resultSet);
      let result = await service.queryReminderInfoByEventIds(eventIds);
      expect(result.length).assertEqual(0);
      resultSet.rowCount = 1;
      when(mockFunc)(ArgumentMatchers.any).afterReturn(resultSet);
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(false);
      result = await service.queryReminderInfoByEventIds(eventIds);
      expect(result.length).assertEqual(0);
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
      result = await service.queryReminderInfoByEventIds(eventIds);
      expect(result.length).assertEqual(1);
      done();
    });

    it('queryReminderInfo_01', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryReminderByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
      let result = await service.queryReminderInfo(1);
      expect(result.length).assertEqual(0);
      mocker.ignoreMock(service, mockFunc);
      done();
    });

    it('queryReminderInfo_02', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryReminderByEventId);
      const resultSet = new DataShareResultSetMock();
      when(mockFunc)(ArgumentMatchers.any).afterReturn(resultSet);
      when(mocker.mockFunc(resultSet, resultSet.goToNextRow))(ArgumentMatchers.any).afterReturn(false);
      expect((await service.queryReminderInfo(eventId) as Array<CalendarContract.Reminders>)?.length).assertLargerOrEqual(0);
      mocker.ignoreMock(service, mockFunc);
      done();
    });

    it('deleteReminderById', 0, async (done: Function) => {
      when(mocker.mockFunc(repo, repo.deleteReminderById))(ArgumentMatchers.any)
        .afterReturn(1);
      expect(await service.deleteReminderById(0)).assertEqual(1);
      done();
    });

    it('deleteReminderByEventId', 0, async (done: Function) => {
      when(mocker.mockFunc(repo, repo.deleteReminderByEventId))(ArgumentMatchers.any)
        .afterReturn(1);
      expect(await service.deleteReminderByEventId(0)).assertEqual(1);
      done();
    });

    it('updateReminderById', 0, async (done: Function) => {
      when(mocker.mockFunc(repo, repo.updateReminderById))(ArgumentMatchers.any).afterReturn(1);
      expect(await service.updateReminderById(0, reminder)).assertEqual(1);
      done();
    });

    it('queryReminderByEventId', 0, async (done: Function) => {
      when(mocker.mockFunc(repo, repo.queryReminderByEventId))(ArgumentMatchers.any)
        .afterReturn(new DataShareResultSetMock());
      const result = await service.queryReminderInfo(eventId);
      expect(result).not().assertUndefined();
      done();
    });
  });
}