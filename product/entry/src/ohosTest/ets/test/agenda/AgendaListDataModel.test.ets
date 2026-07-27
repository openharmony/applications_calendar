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

import { AgendaListDataModel, AutoQueryResult } from '@app/feature.agenda';
import { describe, beforeEach, it, expect, MockKit, when, ArgumentMatchers, afterEach } from '@ohos/hypium';
import {
  AgendaEventInfo,
  DateRange,
  InstanceService,
  MILLS_THIRTY_DAYS,
  MINUTES_PER_DAY,
  ShareRole,
  SourceTypeEnum
} from '@app/common';
import { TestUtil } from '../utils/TestUtil';

const TAG = 'AgendaListDataModelTest';
const MAX_AUTO_QUERY_LENGTH = 30;
const ILLEGAL_CALENDAR_ID = -1;

export default function AgendaListDataModelTest() {
  describe('AgendaListDataModelTest', () => {
    let dataModel: AgendaListDataModel;
    const range: DateRange.Range = { start: Date.now() - 15 * MINUTES_PER_DAY, end: Date.now() + 15 * MINUTES_PER_DAY};
    const maxRange: DateRange.Range = { start: Date.now() - 12 * MILLS_THIRTY_DAYS, end: Date.now() + 24 * MILLS_THIRTY_DAYS };
    let calendarUuid: string = '';
    let mocker: MockKit;
    let mockFunc: Function;
    let mocker2: MockKit;
    let mockFunc2: Function;
    let mocker3: MockKit;
    let mockFunc3: Function;
    const mockEventInfo = new AgendaEventInfo();

    beforeEach(async (done: Function) => {

      dataModel = new AgendaListDataModel(range, maxRange, calendarUuid);
      mocker = new MockKit();
      mockFunc = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceGrouped);
      done();
    })

    afterEach(() => {
      mocker.clearAll();
      mocker2.clearAll()
      mocker3.clearAll();
    })

    // Test init with isInit true
    it('init_001', 0, async () => {
      when(mockFunc)(ArgumentMatchers.any).afterReturn([]);
      await dataModel.init();
      const rangeTest: DateRange.Range = TestUtil.getPrivateAttribute(dataModel, 'range');
      const agendaResultTest: AgendaEventInfo[] = TestUtil.getPrivateAttribute(dataModel, 'agendaResult');
      expect(rangeTest).assertDeepEquals(maxRange);
      expect(agendaResultTest.length).assertEqual(0);
    });

    // Test init with isInit false
    it('init_002', 0, async () => {
      when(mockFunc)(ArgumentMatchers.any).afterReturn([]);
      const mockRange: DateRange.Range = {start: 100, end: 200};
      await dataModel.init(false, mockRange);
      const rangeTest: DateRange.Range = TestUtil.getPrivateAttribute(dataModel, 'range');
      const agendaResultTest: AgendaEventInfo[] = TestUtil.getPrivateAttribute(dataModel, 'agendaResult');
      expect(rangeTest).assertDeepEquals(maxRange);
      expect(agendaResultTest.length).assertEqual(0);
    });

    // Test init with query result length less than MAX_AUTO_QUERY_LENGTH
    it('init_003', 0, async () => {
      when(mockFunc)(ArgumentMatchers.any)
        .afterReturn(new Array(MAX_AUTO_QUERY_LENGTH).fill(mockEventInfo));
      const mockRange: DateRange.Range = {start: 100, end: 200};
      await dataModel.init(false, mockRange);
      const rangeTest: DateRange.Range = TestUtil.getPrivateAttribute(dataModel, 'range');
      const agendaResultTest: AgendaEventInfo[] = TestUtil.getPrivateAttribute(dataModel, 'agendaResult');
      expect(rangeTest).assertDeepEquals(mockRange);
      expect(agendaResultTest.length).assertEqual(MAX_AUTO_QUERY_LENGTH);
    });

    it('query_001', 0, async () => {
      TestUtil.setPrivateAttribute(dataModel, 'calendarId', 1);
      let query = TestUtil.getPrivateFunction(dataModel, 'query');
      if (query) {
        when(mockFunc)(ArgumentMatchers.any).afterReturn([]);
        const result: AgendaEventInfo[] = await query(range);
        expect(result.length).assertEqual(0);
      }
    });

    it('query_002', 0, async () => {
      let query = TestUtil.getPrivateFunction(dataModel, 'query');
      if (query) {
        when(mockFunc)(ArgumentMatchers.any).afterThrow('这是一个主动抛出的错误');
        const result: AgendaEventInfo[] = await query(range);
        expect(result.length).assertEqual(0);
      }
    });

    // 测试查询次数超过MAX_AUTO_QUERY_TIMES, isQueryPast = true
    it('autoQueryAgenda_001', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any).afterReturn([]);
        const result: AutoQueryResult = await autoQueryAgenda(range, true);
        expect(result.agendaList.length).assertEqual(0);
        expect(result.range.start).assertEqual(maxRange.start);
      }
    });

    // 测试返回的日程列表长度超过MAX_AUTO_QUERY_LENGTH, isQueryPast = true
    it('autoQueryAgenda_002', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any)
          .afterReturn(new Array(MAX_AUTO_QUERY_LENGTH + 1).fill(mockEventInfo));
        const result: AutoQueryResult = await autoQueryAgenda(range, true);
        expect(result.agendaList.length).assertEqual(MAX_AUTO_QUERY_LENGTH + 1);
      }
    });

    // 测试查询的日程列表长度小于MAX_AUTO_QUERY_LENGTH, isQueryPast true
    it('autoQueryAgenda_003', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any)
          .afterReturn(new Array(MAX_AUTO_QUERY_LENGTH - 1).fill(mockEventInfo));
        const result: AutoQueryResult = await autoQueryAgenda(range, true);
        expect(result.agendaList.length).assertEqual(MAX_AUTO_QUERY_LENGTH * 2 - 2);
      }
    });

    // 测试查询次数超过MAX_AUTO_QUERY_TIMES, isQueryPast = false
    it('autoQueryAgenda_004', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any).afterReturn([]);
        const result: AutoQueryResult = await autoQueryAgenda(range, false);
        expect(result.agendaList.length).assertEqual(0);
        expect(result.range.end).assertEqual(maxRange.end);
      }
    });

    // 测试返回的日程列表长度超过MAX_AUTO_QUERY_LENGTH, isQueryPast = false
    it('autoQueryAgenda_005', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any)
          .afterReturn(new Array(MAX_AUTO_QUERY_LENGTH + 1).fill(mockEventInfo));
        const result: AutoQueryResult = await autoQueryAgenda(range, false);
        expect(result.agendaList.length).assertEqual(MAX_AUTO_QUERY_LENGTH + 1);
      }
    });

    // 测试查询的日程列表长度小于MAX_AUTO_QUERY_LENGTH, isQueryPast = false
    it('autoQueryAgenda_006', 0, async () => {
      let autoQueryAgenda = TestUtil.getPrivateFunction(dataModel, 'autoQueryAgenda');
      if (autoQueryAgenda) {
        when(mockFunc)(ArgumentMatchers.any).afterReturn(new Array(MAX_AUTO_QUERY_LENGTH - 1).fill(mockEventInfo));
        const result: AutoQueryResult = await autoQueryAgenda(range, false);
        expect(result.agendaList.length).assertEqual(MAX_AUTO_QUERY_LENGTH * 2 - 2);
      }
    });

    // should query past agenda and update agendaResult and range.start
    it('queryPastAgenda_001', 0, async () => {
      // Arrange
      const queryRange = range;
      const expectedResult: AutoQueryResult = {
        agendaList: [mockEventInfo, mockEventInfo],
        range: range,
      };
      let autoQueryAgenda = TestUtil.getPrivateMockFunction(mocker, dataModel, 'autoQueryAgenda');
      if (!autoQueryAgenda) {
        expect(autoQueryAgenda).assertUndefined();
      }
      when(autoQueryAgenda)(ArgumentMatchers.any).afterReturn(expectedResult);
      // Act
      const result = await dataModel.queryPastAgenda(queryRange);
      // Assert
      expect(result).assertDeepEquals(expectedResult);
    });

    // should query future agenda and update agendaResult and range.start
    it('queryFutureAgenda_001', 0, async () => {
      // Arrange
      const queryRange = range;
      const expectedResult: AutoQueryResult = {
        agendaList: [mockEventInfo, mockEventInfo],
        range: range,
      };
      let autoQueryAgenda = TestUtil.getPrivateMockFunction(mocker, dataModel, 'autoQueryAgenda');
      if (!autoQueryAgenda) {
        expect(autoQueryAgenda).assertUndefined();
      }
      when(autoQueryAgenda)(ArgumentMatchers.any).afterReturn(expectedResult);
      // Act
      const result = await dataModel.queryFutureAgenda(queryRange);
      // Assert
      expect(result).assertDeepEquals(expectedResult);
    });

    // returns -1 when agendaResult is empty
    it('findIndexFromCache_001', 0, () => {
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', []);
      const targetAgenda = mockEventInfo;
      expect(dataModel.findIndexFromCache(targetAgenda)).assertEqual(-1);
    });

    // returns -1 when no matching agenda is found
    it('findIndexFromCache_002', 0, () => {
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [mockEventInfo]);
      const targetAgenda = new AgendaEventInfo();
      targetAgenda.mId = 1;
      targetAgenda.mBegin = 100;
      expect(dataModel.findIndexFromCache(targetAgenda)).assertEqual(-1);
    });

    // returns index when matching agenda is found
    it('findIndexFromCache_003', 0, () => {
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [mockEventInfo]);
      const targetAgenda = mockEventInfo;
      expect(dataModel.findIndexFromCache(targetAgenda)).assertEqual(0);
    });

    it('setMaxRange_001', 0, () => {
      const mockRange: DateRange.Range = {
        start: 100, end: 200
      };
      dataModel.setMaxRange(mockRange);
      const maxRange: DateRange.Range = TestUtil.getPrivateAttribute(dataModel, 'maxRange');
      expect(maxRange).assertDeepEquals(mockRange);
    });

    it('getAgendaResult_001', 0, () => {
      TestUtil.setPrivateAttribute(dataModel, 'agendaResult', [mockEventInfo]);
      const agendaResult = dataModel.getAgendaResult();
      expect(agendaResult).assertDeepEquals([mockEventInfo]);
    });

    it('getRange_001', 0, () => {
      const mockRange: DateRange.Range = {
        start: 100, end: 200
      };
      TestUtil.setPrivateAttribute(dataModel, 'range', mockRange);
      const range = dataModel.getRange();
      expect(range).assertDeepEquals(mockRange);
    });

    it('filterHoliday', 0, async () => {
      let filtered = await dataModel.filterHoliday();
      expect(filtered.findIndex(event => event.isHoliday())).assertEqual(-1);
    });
  });
}
