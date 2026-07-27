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
import { CalendarContract, CalendarService, InnerResultSet, Result } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CalendarRepository } from '@app/common/src/main/ets/dao/repo/CalendarRepository';
import { ValuesBucket } from '@kit.ArkData';
import { DataShareResultSetMock } from './DataShareHelperMock';
import { TestUtil } from '../../utils/TestUtil';


export default function CalendarServiceTest() {
  describe('CalendarServiceTest', () => {
    let service = CalendarService.INSTANCE;
    let repo: CalendarRepository = new CalendarRepository;
    let mocker: MockKit = new MockKit();

    beforeEach(() => {
      mocker = new MockKit();
      service.repo = repo;
    });

    it('queryCalendarList', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryCalendars);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      let result = await service.queryCalendarList();
      expect(result).not().assertUndefined();
      done();
    });

    it('queryCalendarById', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryCalendarById);

      let resultSet = new DataShareResultSetMock()
      let getColumnIndex = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getColumnIndex)(ArgumentMatchers.any).afterReturn(1);
      let getLong = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getLong)(ArgumentMatchers.any).afterReturn(1);
      let getString = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getString)(ArgumentMatchers.any).afterReturn('');

      when(mockFunc)(ArgumentMatchers.any).afterReturn(new InnerResultSet(resultSet, ''));
      let result = await service.queryCalendarById(1);
      expect(result).assertUndefined();
      expect(resultSet.isClosed).assertTrue();
      done();
    });

    it('insertCalendar', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.insertCalendar);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      const valuesBucket: ValuesBucket = {};
      let result = await service.insertCalendar(valuesBucket);
      expect(result).not().assertUndefined();
      done();
    });

    it('deleteCalendarById', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteCalendarById);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      let result = await service.deleteCalendarById(1);
      expect(result).not().assertUndefined();
      done();
    });

    it('updateCalendarById', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.updateCalendarById);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      const valuesBucket: ValuesBucket = {};
      let result = await service.updateCalendarById(1, valuesBucket);
      expect(result).not().assertUndefined();
      done();
    });

    it('deleteCalendarByIds', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteCalendarByIds);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      let result = await service.deleteCalendarByIds([1]);
      expect(result).not().assertUndefined();
      done();
    });

    it('deleteCalendarByUuids', 0, async (done: Function) => {
      let deleteResult = await repo.deleteCalendarByUuids([]);
      expect(deleteResult.data === 0).assertTrue();
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.deleteCalendarByUuids);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(1));
      let result = await service.deleteCalendarByUuids(['']);
      expect(result.data === 1).assertTrue();
      done();
    });

    it('queryCalendarByUuids', 0, async (done: Function) => {
      let result = await service.queryCalendarByUuids([]);
      expect(result.isSuccess()).assertTrue();
      expect(result.data.length === 0).assertTrue();
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryCalendarByCondition);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
      result = await service.queryCalendarByUuids(['xxx']);
      expect(result.data.length === 0).assertTrue();
      done();
    });

    it('parseCalendars', 0, async (done: Function) => {

      let mocker: MockKit = new MockKit();
      const parseCalendars = TestUtil.getPrivateFunction(repo, 'parseCalendars');
      if (parseCalendars) {
        let calendars: CalendarContract.Accounts[] = parseCalendars(undefined);
        expect(calendars.length === 0).assertTrue();
        let resultSet = new DataShareResultSetMock()
        when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(false);
        calendars = parseCalendars(resultSet);
        expect(calendars.length === 0).assertTrue();

        resultSet = new DataShareResultSetMock()
        let getColumnIndex = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
        when(getColumnIndex)(ArgumentMatchers.any).afterReturn(1);
        let getLong = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(getLong)(ArgumentMatchers.any).afterReturn(1);
        let getString = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(getString)(ArgumentMatchers.any).afterReturn('');
        calendars = parseCalendars(resultSet);
        expect(calendars.length === 2).assertTrue();

        resultSet = new DataShareResultSetMock()
        getColumnIndex = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
        when(getColumnIndex)(ArgumentMatchers.any).afterReturn(1);
        getLong = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(getLong)(ArgumentMatchers.any).afterReturn(1);
        getString = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
        when(getString)(ArgumentMatchers.any).afterReturn('xxx');
        let columns = [CalendarContract.BaseColumns.ID, CalendarContract.AccountColumns.UUID];
        calendars = parseCalendars(resultSet, columns);
        expect(calendars[0].uuid === 'xxx').assertTrue();
        expect(calendars[0].id === 1).assertTrue();
        columns = [];
        calendars = parseCalendars(resultSet, columns);
        expect(calendars[0].uuid === 'xxx').assertTrue();
        expect(calendars[0].id === 1).assertTrue();
      }
      done();
    });
  });
}