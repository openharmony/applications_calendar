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

import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { AgendaEventInfo, CalendarContract, DateRange, I18nUtil, InstanceService} from '@app/common';
import { AgendaModel } from '@app/feature.weekview/src/main/ets/model/AgendaModel';
import { TestUtil } from '../../utils/TestUtil';

export default function AgendaModelTest() {
  describe('AgendaModelTest', () => {
    let instance: AgendaModel;
    let mocker: MockKit;
    let range: DateRange.Range;
    let mockFunc: Function;

    beforeEach(() => {
      // 单例可能被其他用例污染mock的数据
      instance = new AgendaModel();
      mocker = new MockKit();
      range = {} as DateRange.Range;
    })

    afterEach(() => {
      mocker.clearAll();
    })
    
    it('getAgendaByRangeTest', 0, async (done: Function) => {
      expect((instance.getAgendaByRange(range) as AgendaEventInfo[])?.length).assertLargerOrEqual(0);
      done();
    });

    it('getAgendaByRangeTest_1', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 100;
      info.mIsAllDay = true;
      info.mImportantEventType = CalendarContract.EventImportantType.NORMAL
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(0);
      info.mIsAllDay = false;
      res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })

    it('getAgendaByRangeTest_2', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 100;
      info.mIsAllDay = true;
      info.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(0);
      info.mIsAllDay = false;
      res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })

    it('getAgendaByRangeTest_3', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 100;
      info.mIsAllDay = true;
      info.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(0);
      info.mIsAllDay = false;
      res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })

    it('getAgendaByRangeTest_4', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 100;
      info.mIsAllDay = true;
      info.mImportantEventType = CalendarContract.EventImportantType.HOLIDAY
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(0);
      info.mIsAllDay = false;
      res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })

    it('getAgendaByRangeTest_5', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 100;
      info.mIsAllDay = false;
      info.mCalendarId = 1;
      info.mImportantEventType = CalendarContract.EventImportantType.HOLIDAY
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range, true, 1);
      expect(res.length).assertEqual(0);
      info.mCalendarId = -1;
      res = instance.getAgendaByRange(range, true, 1);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })

    it('checkHolidayCache', 0, async (done: Function) => {
      mockFunc = mocker.mockFunc(
        InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceAsync
      );
      const info1: AgendaEventInfo = new AgendaEventInfo();
      info1.mId = 1;
      info1.mTitle = '中秋节';
      info1.mImportantEventType =  CalendarContract.EventImportantType.HOLIDAY;
      const info2: AgendaEventInfo = new AgendaEventInfo();
      info1.mId = 2;
      info2.mTitle = '不是节日';
      const infos: AgendaEventInfo[] = [info1, info2];
      when(mockFunc)(ArgumentMatchers.any).afterReturn(infos);
      const mockRange: DateRange.Range = {start: 100, end: 200};
      await instance.query(mockRange);
      expect(instance.checkHasSameHoliday('中秋节')).assertTrue();
      expect(instance.checkHasSameHoliday('不是节日')).assertFalse();
      done();
    });

    it('query', 0, async (done: Function) => {
      const mockQueryInstance = mocker.mockFunc(InstanceService.INSTANCE, InstanceService.INSTANCE.queryInstanceAsync);
      when(mockQueryInstance)(ArgumentMatchers.any).afterReturn([]);
      const range: DateRange.Range = { start: Date.now(), end: Date.now() };
      TestUtil.setPrivateAttribute(instance, 'range', range);
      TestUtil.setPrivateAttribute(instance, 'hasUpdate', false);
      TestUtil.setPrivateAttribute(instance, 'cache', [new AgendaEventInfo()]);
      await instance.query(range);
      let cache: AgendaEventInfo[] = TestUtil.getPrivateAttribute(instance, 'cache')!;
      expect(cache.length).assertEqual(1);
      const range1: DateRange.Range = { start: Date.now() + 100, end: Date.now() + 100 };
      TestUtil.setPrivateAttribute(instance, 'hasUpdate', true);
      await instance.query(range1);
      cache = TestUtil.getPrivateAttribute(instance, 'cache')!;
      expect(cache.length).assertEqual(0);
      done();
    })

    it('getAgendaByRange', 0, async (done: Function) => {
      const info = new AgendaEventInfo();
      info.mBegin = 10;
      info.mEnd = 90;
      info.mIsAllDay = true;
      TestUtil.setPrivateAttribute(instance, 'cache', [info]);
      const range: DateRange.Range = { start: 0, end: 100 };
      const mockTimeZone = mocker.mockFunc(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      when(mockTimeZone)(ArgumentMatchers.any).afterReturn(100);
      let res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(0);
      info.mIsAllDay = false;
      res = instance.getAgendaByRange(range);
      expect(res.length).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getTimeZoneOffsetById);
      done();
    })
  });
}