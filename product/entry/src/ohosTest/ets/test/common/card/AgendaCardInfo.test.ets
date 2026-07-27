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

import { describe, expect, it, Level } from '@ohos/hypium';
import {
  AgendaCardInfo,
  EventObjectParam,
  FormUtils
} from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { beforeEach } from '@ohos/hypium/src/main/interface';
import { AccountUtils, MILLS_PER_MINUTE } from '@app/common';

export default function AgendaCardInfoTest() {
  let eventObj: EventObjectParam;
  describe('AgendaCardInfoTest', () => {
    beforeEach(() => {
      eventObj = {
        id: 1,
        event_id: 2,
        calendar_id: 3,
        calendar_color: 4,
        title: 'Test Title',
        eventLocation: 'Test Location',
        description: 'Test Description',
        startDay: new Date('2024-1-1').getTime(),
        endDay: new Date('2024-1-2').getTime(),
        begin: new Date().getTime(),
        end: new Date().getTime(),
        allDay: 1,
        service_type: 'Meeting',
        service_verified: 2,
        service_cp_bz_uri: 'Test URI',
        account_type: 'Test Account Type',
        creator: AccountUtils.WELINK_ACCOUNT_CREATOR,
        attachment_count: 0,
        mCalendarUuid: ''
      };
    })
    it('constructor_by_no_input', 0, () => {
      const info = new AgendaCardInfo();
      expect(info.mId).assertEqual(0);
      expect(info.mEventId).assertEqual(0);
      expect(info.mCalendarId).assertEqual(0);
      expect(info.mStartDay).assertEqual(0);
      expect(info.mTitle).assertEqual('');
      expect(info.mLocation).assertEqual('');
      expect(info.mDescription).assertEqual('');
      expect(info.mBegin).assertEqual(0);
      expect(info.mEnd).assertEqual(0);
      expect(info.mDisplayColor).assertEqual(0);
      expect(info.mEndDay).assertEqual(0);
      expect(info.mIsAllDay).assertFalse();
      expect(info.mFlag).assertEqual(0);
      expect(info.mDay).assertEqual(0);
      expect(info.mIsMultiDayEvent).assertFalse();
      expect(info.mHwextServiceType).assertEqual('');
      expect(info.mHwextServiceUri).assertEqual('');
      expect(info.mHwextServiceVerified).assertFalse();
      expect(info.mCalendarType).assertEqual('');
    });

    it('constructor_by_other', 0, () => {
      const info = new AgendaCardInfo();
      info.mId = 100;
      info.mCalendarType = 'test';
      const info1 = new AgendaCardInfo(info);
      expect(info1).assertDeepEquals(info)
    });

    it('eventObj_common', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mId).assertEqual(eventObj.id);
      expect(agendaCardInfo.mEventId).assertEqual(eventObj.event_id);
      expect(agendaCardInfo.mCalendarId).assertEqual(eventObj.calendar_id);
      expect(agendaCardInfo.mDisplayColor).assertEqual(eventObj.calendar_color);
      expect(agendaCardInfo.mTitle).assertEqual(eventObj.title);
      expect(agendaCardInfo.mLocation).assertEqual(eventObj.eventLocation);
      expect(agendaCardInfo.mDescription).assertEqual(eventObj.description);
      expect(agendaCardInfo.mStartDay).assertEqual(eventObj.startDay);
      expect(agendaCardInfo.mEndDay).assertEqual(eventObj.endDay);
      expect(agendaCardInfo.mBegin).assertEqual(eventObj.begin);
      expect(agendaCardInfo.mEnd).assertEqual(eventObj.end);
      expect(agendaCardInfo.mIsAllDay).assertTrue();
      expect(agendaCardInfo.mHwextServiceType).assertEqual(eventObj.service_type);
      expect(agendaCardInfo.mHwextServiceVerified).assertTrue();
      expect(agendaCardInfo.mHwextServiceUri).assertEqual(eventObj.service_cp_bz_uri);
      expect(agendaCardInfo.mCalendarType).assertEqual(eventObj.account_type);
    });

    it('eventObj_allDay', 0, () => {
      eventObj.allDay = 1;
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mIsAllDay).assertTrue();
      eventObj.allDay = 0;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mIsAllDay).assertFalse();
    });

    it('eventObj_mIsMultiDayEvent', 0, () => {
      eventObj.startDay = eventObj.endDay;
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mIsMultiDayEvent).assertFalse();
      eventObj.startDay = eventObj.endDay + 1;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mIsMultiDayEvent).assertTrue();
    });

    it('eventObj_mHwextServiceVerified', 0, () => {
      eventObj.service_verified = 2;
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mHwextServiceVerified).assertTrue();
      eventObj.service_verified = 3;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mHwextServiceVerified).assertFalse();
      eventObj.service_verified = 1;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mHwextServiceVerified).assertFalse();
      eventObj.service_verified = -1;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mHwextServiceVerified).assertFalse();
      eventObj.service_verified = 0;
      agendaCardInfo.parseFromObj(eventObj);
      expect(agendaCardInfo.mHwextServiceVerified).assertFalse();
    });

    it('isOnlineMeeting_invalid', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceType = '';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'aaa';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
    });

    it('isOnlineMeeting_inServiceTypeMap', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceType = 'Meeting';
      expect(agendaCardInfo.isOnlineMeeting()).assertTrue();
      agendaCardInfo.mHwextServiceType = 'Watching';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'Repayment';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'Live';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'Shopping';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'Trip';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'Class';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'SportsEvents';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
      agendaCardInfo.mHwextServiceType = 'SportsExercise';
      expect(agendaCardInfo.isOnlineMeeting()).assertFalse();
    });

    it('canShowOneKeyService_notVerified', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceVerified = false;
      expect(agendaCardInfo.canShowOneKeyService('1234')).assertFalse();
    });

    it('canShowOneKeyService_mHwextServiceType_notMatch', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceVerified = true;
      agendaCardInfo.mHwextServiceType = 'aaa';
      expect(agendaCardInfo.canShowOneKeyService('1234')).assertFalse();
    });

    it('canShowOneKeyService_notOutDate', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceVerified = true;
      agendaCardInfo.mHwextServiceType = 'Meeting';
      agendaCardInfo.mBegin = Date.now() - MILLS_PER_MINUTE * AgendaCardInfo.MINUTES_BEFORE_MEETING;
      agendaCardInfo.mEnd = Date.now() + MILLS_PER_MINUTE * AgendaCardInfo.MINUTES_BEFORE_MEETING;
      expect(agendaCardInfo.canShowOneKeyService('1234')).assertTrue();
    });

    it('canShowOneKeyService_isOutDate', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mHwextServiceVerified = true;
      agendaCardInfo.mHwextServiceType = 'Meeting';
      agendaCardInfo.mBegin = Date.now() - MILLS_PER_MINUTE * AgendaCardInfo.MINUTES_BEFORE_MEETING;
      agendaCardInfo.mEnd = Date.now() - MILLS_PER_MINUTE * 12;
      expect(agendaCardInfo.canShowOneKeyService('1234')).assertFalse();
    });

    it('isBirthDay', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mCalendarType  = AgendaCardInfo.BIRTHDAY_ACCOUNT_CORE_TYPE;
      expect(agendaCardInfo.isBirthDay()).assertTrue();
      agendaCardInfo.mCalendarType  = AgendaCardInfo.DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE;
      expect(agendaCardInfo.isBirthDay()).assertTrue();
      agendaCardInfo.mCalendarType  = 'test';
      expect(agendaCardInfo.isBirthDay()).assertFalse();
      agendaCardInfo.mCalendarType  = '';
      expect(agendaCardInfo.isBirthDay()).assertFalse();
    });
  })
}