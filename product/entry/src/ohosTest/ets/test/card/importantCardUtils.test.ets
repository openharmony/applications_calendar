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
import { CalendarAccountType, CalendarContract, CalendarService, AgendaEventInfo } from '@app/common/';
import {
  loadBirthDayAccountId,
  loadChineseHolidayAccountId,
  importantTypePrecedence,
  sortImportantAgenda,
  getValidImportantList,
} from '@app/feature.card/src/main/ets/importantCard/view/components/importantCardUtils';

export default function importantCardUtilsTest() {
  describe('importantCardUtilsTest', () => {
    // 华为账号下的item排序 1.'local' 2.'birthday'  2.'custom' 3.'others'
    it('loadBirthDayAccountId', 0, async () => {
      const mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CalendarService.INSTANCE, CalendarService.INSTANCE.queryCalendarList);

      const account1 = new CalendarContract.Accounts;
      const account2 = new CalendarContract.Accounts;
      account1.id = 1;
      account1.accountType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      account2.id = 2;
      account2.accountType = CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE;
      const infos: CalendarContract.Accounts[] = [account1, account2]
      when(mockFunc)(ArgumentMatchers.any).afterReturn(infos);
      const accountId = await loadBirthDayAccountId();
      expect(accountId).assertEqual(2);
    });

    it('loadChineseHolidayAccountId', 0, async () => {
      const mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CalendarService.INSTANCE, CalendarService.INSTANCE.queryCalendarList);
      const account1 = new CalendarContract.Accounts;
      const account2 = new CalendarContract.Accounts;
      const account3 = new CalendarContract.Accounts;
      const account4 = new CalendarContract.Accounts;
      account1.id = 1;
      account1.accountType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      account1.accountName = '111';
      account2.id = 2;
      account2.accountType = CalendarAccountType.HOLIDAY_ACCOUNT_TYPE;
      account2.accountName = '222';
      account3.id = 3;
      account3.accountType = CalendarAccountType.HOLIDAY_ACCOUNT_TYPE;
      account3.accountName = 'CN';
      account4.id = 4;
      account4.accountType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      account4.accountName = 'CN';
      const infos: CalendarContract.Accounts[] = [account1, account2, account3, account4]
      when(mockFunc)(ArgumentMatchers.any).afterReturn(infos);
      const accountId = await loadChineseHolidayAccountId();
      expect(accountId).assertEqual(3);
    });

    it('importantTypePrecedence', 0, async (done: Function) => {
      let anniversary_type = 'days_later';
      let countdown_type = 'in_days';
      const anniversary_precedence = importantTypePrecedence(anniversary_type);
      const countdown_precedence = importantTypePrecedence(countdown_type);

      expect(countdown_precedence).assertLarger(anniversary_precedence);
      done();
    });

    it('sortImportantAgenda', 0, async (done: Function) => {
      let countdown_agenda1 = new AgendaEventInfo();
      countdown_agenda1.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      countdown_agenda1.mBegin = Date.now() + 25 * 3600 * 1000;

      let countdown_agenda2 = new AgendaEventInfo();
      countdown_agenda2.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      countdown_agenda2.mBegin = Date.now() + 50 * 3600 * 1000;

      let res = sortImportantAgenda(countdown_agenda1, countdown_agenda2);
      expect(res).assertLess(0);

      let anniversary_agenda1 = new AgendaEventInfo();
      anniversary_agenda1.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      anniversary_agenda1.mBegin = Date.now() - 25 * 3600 * 1000;

      let anniversary_agenda2 = new AgendaEventInfo();
      anniversary_agenda2.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      anniversary_agenda2.mBegin = Date.now() - 50 * 3600 * 1000;
      res = sortImportantAgenda(anniversary_agenda1, anniversary_agenda2);
      expect(res).assertLess(0);

      res = sortImportantAgenda(countdown_agenda1, anniversary_agenda1);
      expect(res).assertLess(0);

      done();

    });

    it('atc_should_return_valid_important_list_when_valid_is_true', 0, () => {
      let agenda1 = new AgendaEventInfo();
      agenda1.mTitle = 'valid event';
      agenda1.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda1.mBegin = new Date().getTime();
      agenda1.mEnd = new Date().getTime() + 1000;

      let agenda2 = new AgendaEventInfo();
      agenda1.mTitle = 'invalid event';
      agenda2.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda2.mBegin = new Date().getTime() - 1000;
      agenda2.mEnd = new Date().getTime();
      let list: AgendaEventInfo[] = [agenda1, agenda2]
      let result: ESObject = getValidImportantList(list, true);
      expect(result.length).assertEqual(0);
    });

    it('atc_should_return_valid_important_list_when_valid_is_false', 0, () => {
      let agenda1 = new AgendaEventInfo();
      agenda1.mTitle = 'valid event';
      agenda1.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda1.mBegin = new Date().getTime();
      agenda1.mEnd = new Date().getTime() + 1000;

      let agenda2 = new AgendaEventInfo();
      agenda1.mTitle = 'invalid event';
      agenda2.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda2.mBegin = new Date().getTime() - 1000;
      agenda2.mEnd = new Date().getTime();
      let list: AgendaEventInfo[] = [agenda1, agenda2]
      let result: ESObject = getValidImportantList(list, false);
      expect(result.length).assertEqual(2);
    });

    it('atc_should_return_empty_list_when_all_events_are_invalid', 0, () => {
      let agenda1 = new AgendaEventInfo();
      agenda1.mTitle = 'invalid event';
      agenda1.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda1.mBegin = new Date().getTime() - 1000;
      agenda1.mEnd = new Date().getTime();

      let agenda2 = new AgendaEventInfo();
      agenda1.mTitle = 'invalid event';
      agenda2.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda2.mBegin = new Date().getTime() - 2000;
      agenda2.mEnd = new Date().getTime() - 1000;
      let list: AgendaEventInfo[] = [agenda1, agenda2]
      let result: ESObject = getValidImportantList(list, true);
      expect(result.length).assertEqual(0);
    });
  });
}