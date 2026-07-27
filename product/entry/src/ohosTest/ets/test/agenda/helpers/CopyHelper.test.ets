/*
 *  Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 */

import { CopyHelper } from '@app/feature.agenda';
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
import { AgendaEventInfo, CalendarContract, EventService, GlobalData, GlobalDataKeys, Log, ReminderService } from '@app/common';
const TAG = 'CopyHelperTest';

export default function CopyHelperTest() {
  describe('CopyHelperTest', () => {
    it('instance_not_null', 0, async (done: Function) => {
      expect(CopyHelper.instance() != null).assertTrue();
      done();
    })

    it('stashEventInfo', 0, async (done: Function) => {
      let event: AgendaEventInfo = new AgendaEventInfo();
      CopyHelper.instance().stashEventInfo(event);
      expect(CopyHelper.instance().getStashEventInfo()).assertEqual(event);
      done();
    })

    it('clear', 0, async (done: Function) => {
      let event: AgendaEventInfo = new AgendaEventInfo();
      CopyHelper.instance().stashEventInfo(event);
      CopyHelper.instance().clear();
      expect(CopyHelper.instance().getStashEventInfo()).assertEqual(undefined);
      done();
    })

    it('getStashEventInfo', 0, async (done: Function) => {
      let event: AgendaEventInfo = new AgendaEventInfo();
      expect(CopyHelper.instance().getStashEventInfo()).assertEqual(undefined);
      CopyHelper.instance().stashEventInfo(event);
      expect(CopyHelper.instance().getStashEventInfo()).assertEqual(event);
      done();
    })

    it('pasteEventInfo_should_return_false_when_tempEventInfo_or_pasteDay_is_null', 0, async () => {
      let copyhelper: CopyHelper = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(copyhelper, copyhelper.getPostValue);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());

      const result = await copyhelper.pasteEventInfo(1, undefined);
      expect(result).assertEqual(false);
      mocker.ignoreMock(copyhelper, copyhelper.getPostValue);
    });

    it('pasteEventInfo_should_return_false_when_insertEvent_returns_false', 0, async () => {
      let copyhelper: CopyHelper = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(copyhelper, copyhelper.getPostValue);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());

      let mockfunc2: Function = mocker.mockFunc(EventService, EventService.INSTANCE.insertEvent);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn(Promise.resolve(0));

      const result = await copyhelper.pasteEventInfo(1, undefined);
      expect(result).assertEqual(false);
      mocker.ignoreMock(copyhelper, copyhelper.getPostValue);
      mocker.ignoreMock(EventService, EventService.INSTANCE.insertEvent);
    });

    it('pasteEventInfo_should_return_false_when_insertEvent_fails', 0, async () => {
      let copyhelper: CopyHelper = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(copyhelper, copyhelper.getPostValue);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());

      let mockfunc2: Function = mocker.mockFunc(EventService, EventService.INSTANCE.insertEvent);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn(Promise.resolve(null));

      const result = await copyhelper.pasteEventInfo(1, undefined);
      expect(result).assertEqual(false);
      mocker.ignoreMock(copyhelper, copyhelper.getPostValue);
      mocker.ignoreMock(EventService, EventService.INSTANCE.insertEvent);
    });

    it('pasteEventInfo_should_return_false_when_insertReminder_fails', 0, async () => {
      let copyhelper: CopyHelper = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(copyhelper, copyhelper.getPostValue);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());

      let mockfunc2: Function = mocker.mockFunc(EventService, EventService.INSTANCE.insertEvent);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn(Promise.resolve(1));

      let mockfunc3: Function = mocker.mockFunc(ReminderService, ReminderService.INSTANCE.insertReminder);
      when(mockfunc3)(ArgumentMatchers.any).afterReturn(Promise.resolve(false));

      const result = await copyhelper.pasteEventInfo(1, undefined);
      expect(result).assertEqual(false);
      mocker.ignoreMock(copyhelper, copyhelper.getPostValue);
      mocker.ignoreMock(EventService, EventService.INSTANCE.insertEvent);
      mocker.ignoreMock(ReminderService, ReminderService.INSTANCE.insertReminder);
    });

    it('getPostValue', 0, async (done: Function) => {
      let event: AgendaEventInfo = new AgendaEventInfo();
      let result = CopyHelper.instance().getPostValue(event);
      expect(result != null).assertTrue();
      event.mIsAllDay = true;
      result = CopyHelper.instance().getPostValue(event);
      expect(result != null).assertTrue();
      event.mEventCalendar = CalendarContract.AgendaCalendarType.LUNAR;
      result = CopyHelper.instance().getPostValue(event);
      expect(result != null).assertTrue();
      done();
    })

    it('copyEventInfo_should_return_false_when_eventId_smaller_zero', 0, async (done: Function) => {
      expect(await CopyHelper.instance().copyEventInfo(-1)).assertFalse();
      done();
    });

    it('copyEventInfo_should_return_false_when_eventId_is_zero', 0, async (done: Function) => {
      expect(await CopyHelper.instance().copyEventInfo(0)).assertFalse();
      done();
    });

    it('copyEventInfo_should_return_false_when_event_is_holiday', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockQueryEventById: ESObject = mocker.mockFunc(EventService.INSTANCE, EventService.INSTANCE.queryEventById);
      const event = new AgendaEventInfo();
      event.mImportantEventType = CalendarContract.EventImportantType.HOLIDAY;
      event.mTitle = 'holiday';
      when(mockQueryEventById)(ArgumentMatchers.any).afterReturn(event);
      const result: ESObject = await copyHelper.copyEventInfo(1);
      expect(result).assertFalse();
      mocker.ignoreMock(EventService.INSTANCE, EventService.INSTANCE.queryEventById);
      done();
    });

    it('copyEventInfo_should_return_true_and_copy_event_info_when_event_is_not_holiday', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockQueryEventById: ESObject = mocker.mockFunc(EventService.INSTANCE, EventService.INSTANCE.queryEventById);
      let mockStashEventInfo: ESObject = mocker.mockFunc(copyHelper, copyHelper.stashEventInfo);
      const event = new AgendaEventInfo();
      event.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      event.mTitle = '111';
      when(mockQueryEventById)(ArgumentMatchers.any).afterReturn(event);
      const result: ESObject = await copyHelper.copyEventInfo(1);
      expect(result).assertTrue();
      mocker.verify('stashEventInfo', [event]).atLeast(1);
      mocker.ignoreMock(EventService.INSTANCE, EventService.INSTANCE.queryEventById);
      mocker.ignoreMock(copyHelper, copyHelper.stashEventInfo);
      done();
    });

    it('pasteEventInfoHighLight_should_call_pasteEventInfo_with_the_correct_day_from_GlobalData', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let getMock: ESObject = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(getMock)(GlobalDataKeys.DISPLAY_DATE).afterReturn(1234567890);
      let pasteEventInfoMock: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      await copyHelper.pasteEventInfoHighLight();
      mocker.verify('pasteEventInfo', [1234567890]).atLeast(1);
      mocker.ignoreMock(GlobalData, GlobalData.instance);
      mocker.ignoreMock(GlobalData.instance(), GlobalData.instance().get);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoSelf_should_return_false_when_tempEventInfo_is_undefined', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      copyHelper.tempEventInfo = undefined;
      const result: ESObject = await copyHelper.pasteEventInfoSelf();
      expect(result).assertFalse();
      done();
    });

    it('pasteEventInfoSelf_should_return_true_when_tempEventInfo_is_defined_and_pasteEventInfo_returns_true', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      copyHelper.tempEventInfo = { mBegin: 1234567890 };
      let mocker: ESObject = new MockKit();
      let mockFunc: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      const result: ESObject = await copyHelper.pasteEventInfoSelf();
      expect(result).assertTrue();
      mocker.verify('pasteEventInfo', [1234567890]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoSelf_should_return_false_when_tempEventInfo_is_defined_and_pasteEventInfo_returns_false', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      copyHelper.tempEventInfo = { mBegin: 1234567890 };
      let mocker: ESObject = new MockKit();
      let mockFunc: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      const result: ESObject = await copyHelper.pasteEventInfoSelf();
      expect(result).assertFalse();
      mocker.verify('pasteEventInfo', [1234567890]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoWithStartTime_should_call_pasteEventInfo_with_correct_arguments_when_pasteTime_is_provided', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockPasteEventInfo: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockPasteEventInfo)([ArgumentMatchers.any, ArgumentMatchers.any]).afterReturn(Promise.resolve());

      await copyHelper.pasteEventInfoWithStartTime(123456789);

      mocker.verify('pasteEventInfo', [123456789, 123456789]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoWithStartTime_should_handle_negative_pasteTime_values', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockPasteEventInfo: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockPasteEventInfo)([ArgumentMatchers.any, ArgumentMatchers.any]).afterReturn(Promise.resolve());

      await copyHelper.pasteEventInfoWithStartTime(-123456789);

      mocker.verify('pasteEventInfo', [-123456789, -123456789]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoWithStartTime_should_handle_zero_pasteTime_values', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockPasteEventInfo: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockPasteEventInfo)([ArgumentMatchers.any, ArgumentMatchers.any]).afterReturn(Promise.resolve());

      await copyHelper.pasteEventInfoWithStartTime(0);

      mocker.verify('pasteEventInfo', [0, 0]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });

    it('pasteEventInfoWithStartTime_should_handle_large_pasteTime_values', 0, async (done: Function) => {
      let copyHelper: ESObject = new CopyHelper();
      let mocker: MockKit = new MockKit();
      let mockPasteEventInfo: ESObject = mocker.mockFunc(copyHelper, copyHelper.pasteEventInfo);
      when(mockPasteEventInfo)([ArgumentMatchers.any, ArgumentMatchers.any]).afterReturn(Promise.resolve());

      await copyHelper.pasteEventInfoWithStartTime(Number.MAX_SAFE_INTEGER);

      mocker.verify('pasteEventInfo', [Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER]).atLeast(1);
      mocker.ignoreMock(copyHelper, copyHelper.pasteEventInfo);
      done();
    });
  })
}