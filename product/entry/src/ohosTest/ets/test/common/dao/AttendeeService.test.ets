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
import { AttendeeRepository, AttendeeService, CalendarContract, InnerResultSet } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { DataShareResultSetMock } from './DataShareHelperMock';

export default function AttendeeServiceTest() {
  describe('AttendeeServiceTest', () => {
    let service = AttendeeService.INSTANCE;
    let repo: AttendeeRepository;
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
      repo = new AttendeeRepository;
      service.attendeeDao = repo;
    })

    it('queryAttendeeInfoByEventId', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryAttendeeByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
      let result = await service.queryAttendeeInfoByEventId(1);
      expect(result.length).assertEqual(0);
      done();
    });

    it('queryAttendeeInfoByEventId_normal', 0, async (done: Function) => {
      let resultSet = new DataShareResultSetMock()
      let getColumnIndex = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getColumnIndex)(ArgumentMatchers.any).afterReturn(1);
      let getLong = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getLong)(ArgumentMatchers.any).afterReturn(1);
      let getString = mocker.mockFunc(resultSet, resultSet.getColumnIndex);
      when(getString)(ArgumentMatchers.any).afterReturn('');

      resultSet.columnNames = [CalendarContract.AttendeesColumns.ID];
      let mockFunc: Function = mocker.mockFunc(repo, repo.queryAttendeeByEventId);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(new InnerResultSet(resultSet, ''));
      let result = await service.queryAttendeeInfoByEventId(1);
      expect(result.length).assertEqual(1);
      expect(resultSet.isClosed).assertTrue();
      done();
    });
  });
}