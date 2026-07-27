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
import { DBUtils } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CalendarRepository } from '@app/common/src/main/ets/dao/repo/CalendarRepository';
import { DataShareResultSetMock } from '../DataShareHelperMock';

export default function CalendarRepositoryTest() {
  describe('CalendarRepositoryTest', () => {
    let db = DBUtils.INSTANCE;
    let repo: CalendarRepository;
    let mocker: MockKit;
    let data: DataShareResultSetMock;
    let query: Function;
    let deleteFunc: Function;
    let insert: Function;
    let update: Function;

    beforeEach(() => {
      repo = new CalendarRepository;
      mocker = new MockKit();
      query = mocker.mockFunc(db, db.query);
      insert = mocker.mockFunc(db, db.insert);
      update = mocker.mockFunc(db, db.update);
      deleteFunc = mocker.mockFunc(db, db.delete);
      data = new DataShareResultSetMock();
    });

    it('queryCalendarById', 0, async (done: Function) => {
      let calendarId: number = 0;
      expect(await repo.queryCalendarById(calendarId)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.queryCalendarById(calendarId)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow(undefined);
      expect(await repo.queryCalendarById(calendarId)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterReturn(data);
      let result = await repo.queryCalendarById(calendarId);
      expect(result).assertDeepEquals(data);
      done();
    });

    it('queryCalendarByCalendarName', 0, async (done: Function) => {
      let calendarName: string[] = ['CN'];
      expect(await repo.queryCalendarByName(calendarName)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.queryCalendarByName(calendarName)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow(undefined);
      expect(await repo.queryCalendarByName(calendarName)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterReturn(data);
      let result = await repo.queryCalendarByName(calendarName);
      expect(result).assertDeepEquals(data);
      done();
    });

    it('queryCalendars', 0, async (done: Function) => {
      expect(await repo.queryCalendars()).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.queryCalendars()).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow(undefined);
      expect(await repo.queryCalendars()).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterReturn(data);
      let result = await repo.queryCalendars();
      expect(result).assertDeepEquals(data);
      done();
    });

    it('insertCalendar', 0, async (done: Function) => {
      when(insert)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.insertCalendar(undefined)).assertEqual(1);
      done();
    });

    it('deleteCalendarById_input_undefined', 0, async (done: Function) => {
      expect(await repo.deleteCalendarById(undefined)).assertEqual(undefined);
      done()
    })

    it('deleteCalendarById_delete_throw', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.deleteCalendarById(undefined)).assertEqual(-1);
      done()
    })

    it('deleteCalendarById', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteCalendarById(1)).assertEqual(1);
      done();
    });

    it('updateCalendarById_input_undefined', 0, async (done: Function) => {
      expect(await repo.updateCalendarById(undefined, undefined)).assertEqual(undefined);
      done()
    })

    it('updateCalendarById_throw', 0, async (done: Function) => {
      when(update)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.updateCalendarById(1, {})).assertEqual(1);
      done();
    });

    it('deleteCalendarByIds_input_empty', 0, async (done: Function) => {
      expect(await repo.deleteCalendarByIds([])).assertEqual(-1);
      done();
    })

    it('deleteCalendarByIds_throw_error', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.deleteCalendarByIds([0])).assertEqual(-1);
      done();
    })

    it('deleteCalendarByIds', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteCalendarByIds([1])).assertEqual(1);
      done();
    });
  });
}