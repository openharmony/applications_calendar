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

import { describe, expect, it } from '@ohos/hypium';
import { AccountUtils, AgendaEventInfo, CalendarAccountType, CalendarContract } from '@app/common';
import { DeduplicateProcessor } from '@app/common/src/main/ets/event/DeduplicateProcessor';
import { HashMap } from '@kit.ArkTS';

export default function DeduplicateProcessorTest() {


  describe('DeduplicateUtilsTest', () => {
    let accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap<number, CalendarContract.Accounts>();
    const account = new CalendarContract.Accounts;
    account.id = 1;
    account.accountType = CalendarAccountType.EMAIL_ACCOUNT_TYPE;
    accountMap.set(account.id, account);

    let accountUuidMap: HashMap<string, CalendarContract.Accounts> = new HashMap<string, CalendarContract.Accounts>();
    const account1 = new CalendarContract.Accounts;
    account1.id = 1;
    account1.uuid = '111';
    account1.accountType = CalendarAccountType.EMAIL_ACCOUNT_TYPE;
    accountUuidMap.set(account1.uuid, account1);

    it('reduceAgendaEventInfos_weLink', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test1';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      let eventInfo3 =  new AgendaEventInfo();
      eventInfo3.mCalendarId = 1;
      eventInfo3.mTitle = 'test1';
      eventInfo3.mBegin = 125000021;
      eventInfo3.mBegin = 135667781;
      eventInfo3.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);
      eventList.push(eventInfo3);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfos(eventList, accountMap);

      expect(eventListNew.length).assertEqual(2);
      done();
    });

    it('reduceAgendaEventInfos_weLink_uuid', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;
      eventInfo1.mCalendarUuid = '111';

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test1';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;
      eventInfo2.mCalendarUuid = '111';

      let eventInfo3 =  new AgendaEventInfo();
      eventInfo3.mCalendarId = 1;
      eventInfo3.mTitle = 'test1';
      eventInfo3.mBegin = 125000021;
      eventInfo3.mBegin = 135667781;
      eventInfo3.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;
      eventInfo3.mCalendarUuid = '111';

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);
      eventList.push(eventInfo3);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfosByCalendarUuid(eventList, accountUuidMap);

      expect(eventListNew.length).assertEqual(2);
      done();
    });

    it('getAllReduceEventIds', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mId = 2;
      eventInfo1.mTitle = 'test16';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo1.mId = 3;
      eventInfo2.mTitle = 'test16';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfos(eventList, accountMap);
      const eventIds = await DeduplicateProcessor.INSTANCE.getAllReduceEventIds([3]);

      expect(eventListNew.length).assertEqual(1);
      expect(eventIds.length).assertEqual(1);
      done();
    });

    it('reduceAgendaEventInfos_other', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mId = 2;
      eventInfo1.mTitle = 'test666';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mId = 2;
      eventInfo2.mTitle = 'test666';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfos(eventList, accountMap);


      expect(eventListNew.length).assertEqual(2);
      done();
    });

    it('reduceAgendaEventInfos_calendar', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mId = 2;
      eventInfo1.mTitle = 'test666';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.CALENDAR_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mId = 2;
      eventInfo2.mTitle = 'test666';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.CALENDAR_ACCOUNT_CREATOR;

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfos(eventList, accountMap);


      expect(eventListNew.length).assertEqual(2);
      done();
    });

    it('reduceAgendaEventInfos_calendarData', 0, async (done: Function) => {
      let eventInfo1 =  new AgendaEventInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mId = 2;
      eventInfo1.mTitle = 'test666';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaEventInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mId = 2;
      eventInfo2.mTitle = 'test666';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR;

      const eventList: AgendaEventInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = await DeduplicateProcessor.INSTANCE.reduceAgendaEventInfos(eventList, accountMap);


      expect(eventListNew.length).assertEqual(2);
      done();
    });
  })
}