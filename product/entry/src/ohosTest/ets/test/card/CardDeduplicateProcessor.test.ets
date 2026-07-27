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
import { AgendaCardInfo } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardDeduplicateProcessor } from '@app/feature.card/src/main/ets/agendaCard/common/CardDeduplicateProcessor';
import { AccountUtils, CalendarAccountType } from '@app/common';


export default function CardDeduplicateProcessorTest() {
  describe('CardDeduplicateProcessorTest', () => {
    it('reduceAgendaCardInfos_weLink', 0, () => {
      let eventInfo1 =  new AgendaCardInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaCardInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test1';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      let eventInfo3 =  new AgendaCardInfo();
      eventInfo3.mCalendarId = 1;
      eventInfo3.mTitle = 'test1';
      eventInfo3.mBegin = 125000021;
      eventInfo3.mBegin = 135667781;
      eventInfo3.mCreator = AccountUtils.WELINK_ACCOUNT_CREATOR;

      const eventList: AgendaCardInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);
      eventList.push(eventInfo3);

      const eventListNew = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(eventList);

      expect(eventListNew.length).assertEqual(2);
    });

    it('reduceAgendaCardInfos_calendarData', 0, () => {
      let eventInfo1 =  new AgendaCardInfo();
      eventInfo1.mCalendarType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaCardInfo();
      eventInfo2.mCalendarType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test1';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR;

      const eventList: AgendaCardInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(eventList);

      expect(eventListNew.length).assertEqual(1);
    });

    it('reduceAgendaCardInfos_calendar', 0, () => {
      let eventInfo1 =  new AgendaCardInfo();
      eventInfo1.mCalendarType =CalendarAccountType.CUSTOM_ACCOUNT_TYPE;
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;
      eventInfo1.mCreator = AccountUtils.CALENDAR_ACCOUNT_CREATOR;

      let eventInfo2 =  new AgendaCardInfo();
      eventInfo2.mCalendarType =CalendarAccountType.CUSTOM_ACCOUNT_TYPE;
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test1';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;
      eventInfo2.mCreator = AccountUtils.CALENDAR_ACCOUNT_CREATOR;

      const eventList: AgendaCardInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(eventList);

      expect(eventListNew.length).assertEqual(1);
    });

    it('reduceAgendaCardInfos_normal', 0, () => {
      let eventInfo1 =  new AgendaCardInfo();
      eventInfo1.mCalendarId = 1;
      eventInfo1.mTitle = 'test1';
      eventInfo1.mBegin = 12500002;
      eventInfo1.mBegin = 13566778;

      let eventInfo2 =  new AgendaCardInfo();
      eventInfo2.mCalendarId = 1;
      eventInfo2.mTitle = 'test12';
      eventInfo2.mBegin = 12500002;
      eventInfo2.mBegin = 13566778;

      const eventList: AgendaCardInfo[]  = [];
      eventList.push(eventInfo1);
      eventList.push(eventInfo2);

      const eventListNew = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(eventList);

      expect(eventListNew.length).assertEqual(2);
    });
  })
}