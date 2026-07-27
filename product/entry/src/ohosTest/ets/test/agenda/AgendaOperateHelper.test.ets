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

import { AgendaOperateHelper } from '@app/feature.agenda/src/main/ets/helpers/AgendaOperateHelper';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import {
  AgendaEventInfo,
  CalendarContract,
  CalendarService,
  CommonService,
  EventService,
  ReminderService,
  ServiceManager
} from '@app/common';
import { FromType, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ImportExportServiceImpl } from '@app/feature.importexport/src/main/ets/core/ImportExportService';
import { emitter } from '@kit.BasicServicesKit';
import { HashMap } from '@kit.ArkTS';
import { TestUtil } from '../utils/TestUtil';
import { getPopOffsetY } from '@app/feature.agenda';

const TAG = 'AgendaOperateHelperTest';

export default function AgendaOperateHelperTest() {
  describe('AgendaOperateUtilTest', () => {
    let agenda: AgendaEventInfo;
    let agendaOperateHelperTest: AgendaOperateHelper;
    let mocker: MockKit;

    beforeEach(() => {
      agenda = new AgendaEventInfo();
      agendaOperateHelperTest = new AgendaOperateHelper();
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('share_agenda', 0, async (done: Function) => {
      agenda.mId = 123;
      expect(await agendaOperateHelperTest.shareAgenda(agenda, FromType.UNKNOWN, 'shareAnchorViewId')).assertTrue();
      done()
    });

    it('editAgenda01', 0, async (done: Function) => {
      let mockFunc1: Function = mocker.mockFunc(ReportUtil, ReportUtil.reportStatisticEvent);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(true);
      let mockFunc2: Function = mocker.mockFunc(emitter.emit, emitter.emit);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(true);
      expect(agendaOperateHelperTest.editAgenda(agenda)).assertTrue();
      done();
    });

    it('editThisAgenda01', 0, async (done: Function) => {
      let mockFunc1: Function = mocker.mockFunc(ReportUtil, ReportUtil.reportStatisticEvent);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(true);
      let mockFunc2: Function = mocker.mockFunc(emitter.emit, emitter.emit);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(true);
      expect(agendaOperateHelperTest.editThisAgenda(agenda, 1715761775321, 1715761775321)).assertTrue();
      done();
    });

    it('editThisAgendaAndBeyond01', 0, async (done: Function) => {
      let mockFunc1: Function = mocker.mockFunc(ReportUtil, ReportUtil.reportStatisticEvent);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(true);
      let mockFunc2: Function = mocker.mockFunc(emitter.emit, emitter.emit);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(true);
      expect(agendaOperateHelperTest.editThisAgendaAndBeyond(agenda, 1715761775321, 1715761775321)).assertTrue();
      done();
    });

    it('eventToSoftDelete01', 0, async (done: Function) => {
      let mockFunc: Function = mocker.mockFunc(emitter.emit, emitter.emit);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      expect(agendaOperateHelperTest.eventToSoftDelete(agenda.mId, agenda.mBegin)).assertTrue();
      done();
    });

    // should_return_empty_array_when_events_is_empty
    it('getShareableEvents_test01', 0, (done: Function) => {
      const result = AgendaOperateHelper.getShareableEvents([]);
      expect(result).assertDeepEquals([]);
      done();
    });

    it('getShareableEvents_test03', 0, async (done: Function) => {
      let agendas = await EventService.INSTANCE.queryImportantEvents();
      let accounts: CalendarContract.Accounts[] =
        await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
      const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
      let actualShareableCount = 0; // 自己遍历一遍 查询 非 email 的event
      for (let i = 0; i< agendas.length; i++){
        let accountType = accountMap.get(agendas[i].mCalendarId).accountType;
        actualShareableCount += accountType == 'email' ? 0 : 1;
      }
      let shareableIds = AgendaOperateHelper.getShareableEvents(agendas);
      expect(shareableIds.length).assertEqual(actualShareableCount);
      done();
    });

    // should_return_sorted_reminders_when_queryReminderInfo_succeeds
    it('notifyEditEventWithReminder_test01', 0, async (done: Function) => {
      const mockReminders: CalendarContract.Reminders[] = [
        { id: 1, eventId: 1, remindMinutes: 15, remindType: 1, syncId: '1', eventUuid: ''},
        { id: 1, eventId: 1, remindMinutes: 30, remindType: 1, syncId: '1', eventUuid: ''},
      ];
      let notifyEditEventWithReminder = TestUtil.getPrivateFunction(agendaOperateHelperTest, 'notifyEditEventWithReminder');
      if (notifyEditEventWithReminder) {
        let mockFunc = mocker.mockFunc(ReminderService.INSTANCE, ReminderService.INSTANCE.queryReminderInfo);
        when(mockFunc)(ArgumentMatchers.any).afterReturn(mockReminders);
        notifyEditEventWithReminder(agenda).then(() => {
          expect(agenda.checkValuesArray).assertDeepEquals(mockReminders);
        })
      }
      done();
    });

    // should_return_empty_array_when_queryReminderInfo_returns_null
    it('notifyEditEventWithReminder_test02', 0, async (done: Function) => {
      const notifyEditEventWithReminder = TestUtil.getPrivateFunction(agendaOperateHelperTest, 'notifyEditEventWithReminder');
      if (notifyEditEventWithReminder) {
        let mockFunc = mocker.mockFunc(ReminderService.INSTANCE, ReminderService.INSTANCE.queryReminderInfo);
        when(mockFunc)(ArgumentMatchers.any).afterReturn(Promise.resolve([]));
        notifyEditEventWithReminder(agenda).then(() => {
          expect(agenda.checkValuesArray).assertDeepEquals([]);
        })
      }
      done();
    });

    // should_return_empty_array_when_queryReminderInfo_throws_error
    it('notifyEditEventWithReminder_test03', 0, async (done: Function) => {
      const notifyEditEventWithReminder = TestUtil.getPrivateFunction(agendaOperateHelperTest, 'notifyEditEventWithReminder');
      if (notifyEditEventWithReminder) {
        let mockFunc = mocker.mockFunc(ReminderService.INSTANCE, ReminderService.INSTANCE.queryReminderInfo);
        when(mockFunc)(ArgumentMatchers.any).afterReturn(Promise.reject(new Error('Mocked error')));
        notifyEditEventWithReminder(agenda).then(() => {
          expect(agenda.checkValuesArray).assertDeepEquals([]);
        })
      }
      done();
    });

    // getPopOffsetY
    it('getPopOffsetY_test', 0, () => {
        expect(getPopOffsetY(20, 560)).assertEqual(48);
        expect(getPopOffsetY(120, 560)).assertEqual(48);
        expect(getPopOffsetY(560, 1080)).assertEqual(0);
    });

    // getCheckValueForEdit
    it('getCheckValueForEdit_test', 0, async (done: Function) => {
      let checkValuesArray: CalendarContract.Reminders[] = [new CalendarContract.Reminders];
      let mockFunc = mocker.mockFunc(ReminderService.INSTANCE, ReminderService.INSTANCE.queryReminderInfo);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(Promise.resolve(checkValuesArray));
      await AgendaOperateHelper.getCheckValueForEdit(agenda);
      expect(agenda.checkValuesArray.length).assertEqual(1);
      done();
    });

    // getCheckValueForEdit fail
    it('getCheckValueForEdit_test_fail', 0, async (done: Function) => {
      let checkValuesArray: CalendarContract.Reminders[] = [new CalendarContract.Reminders];
      let mockFunc = mocker.mockFunc(ReminderService.INSTANCE, ReminderService.INSTANCE.queryReminderInfo);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(Promise.resolve(new Error('Mocked error')));
      await AgendaOperateHelper.getCheckValueForEdit(agenda);
      expect(agenda.checkValuesArray.length).assertEqual(0);
      done();
    });
  });
}