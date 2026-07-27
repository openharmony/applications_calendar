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
import { AgendaEventInfo, CalendarContract, DateUtil, GlobalThis, InnerResultSet, MILLS_PER_DAY, MILLS_PER_MINUTE, NotifyHandlerEnum } from '@app/common';
import { DataShareResultSetMock } from './dao/DataShareHelperMock';

export default function AgendaEventInfoTest() {
  describe('AgendaEventInfoTest', () => {
    it('constructor', 0, () => {
      let info = new AgendaEventInfo();
      info.mId = 2;
      info.mCalendarId = 1;
      info.mTitle = '1';
      info.mLocation = '1';
      info.mDescription = '1';
      info.mStartDay = 1;
      info.mEndDay = 1;
      info.rDate = '1';
      info.exRule = '1';
      info.exDate = '1';
      info.lastDate = 1;
      info.eventTimeZone = '1'
      info.accessLevel = 1;
      info.hasAlarm = '1';
      info.status = '1';
      info.alertType = 1;
      info.duration = '1';
      info.imageType = '1';
      info.mFlag = 1;
      info.mDisplayColor = 1;
      info.mDay = 1;
      info.mEventType = 1;
      info.mBegin = 1;
      info.mEnd = 1;
      info.mOriginalBegin = 1;
      info.mOriginalEnd = 1;
      info.mIsAllDay = true;
      info.mIsMultiDayEvent = true;
      info.mIsSetDayHead = true;
      info.mEventCalendar = 1;
      info.mEventImageType = '1';
      info.mIsCanceled = true;
      info.mSelfAttendeeStatus = true;
      info.mIsMeetingEvent = true;
      info.mPosition = 1;
      info.mRepeatRule = '1';
      info.mEventTimeStamp = 1;
      info.mImportantEventType = 1;
      info.mHwextServiceType = '1';
      info.mHwextServiceVerified = true;
      info.mHwextServiceUri = '1';
      info.mHwextServicePkgName = '1';
      info.mHwextServiceMinVersion = '1';
      info.mHwextServiceDescription = '1';
      info.mCornerType = 1;
      info.checkValuesArray = [{
        'id': 1,
        'eventId': 1,
        'remindMinutes': 1,
        'remindType': 1,
        'syncId': '1',
        'eventUuid': ''
      }];
      info.mAttendeeList = [{
        'id': 1,
        'eventId': 1,
        'attendeeName': '1',
        'attendeeEmail': '1',
        'attendeeStatus': 1,
        'attendeeRelationship': 1,
        'attendeeType': 1,
        'attendeeIdentity': '1',
        'attendeeIdNamespace': '1'
      }];
      info.mIsHoliday = true;
      // 是否为 共享日程
      info.isShareAgenda = true;
      // 是否是来自消息的资源
      info.isMessageResource = true;
      // 是否是发起者
      info.isShareAgendaInitiator = true;
      info.uuid = '1';
      // 日程唯一标识，三方写入可指定
      info.identifier = '1';
      // 是否冲突
      info.isConflict = true;
      // 迁移旧的eventId
      info.oldEventId = 1;
      // event表的dtStart
      info.eventStart = 1;
      // 用户操作状态(共享日程当前用户为受邀者时)，0拒绝 1待定 2接受
      info.userHandler = NotifyHandlerEnum.UNDETERMINED;
      // 复制
      let info2 = new AgendaEventInfo(info);
      expect(info2.mId).assertEqual(info.mId);
      expect(info2.mCalendarId).assertEqual(info.mCalendarId);
      expect(info2.mTitle).assertEqual(info.mTitle);
      expect(info2.mLocation).assertEqual(info.mLocation);
      expect(info2.mDescription).assertEqual(info.mDescription);
      expect(info2.mStartDay).assertEqual(info.mStartDay);
      expect(info2.mEndDay).assertEqual(info.mEndDay);
      expect(info2.rDate).assertEqual(info.rDate);
      expect(info2.exRule).assertEqual(info.exRule);
      expect(info2.exDate).assertEqual(info.exDate);
      expect(info2.lastDate).assertEqual(info.lastDate);
      expect(info2.eventTimeZone).assertEqual(info.eventTimeZone);
      expect(info2.accessLevel).assertEqual(info.accessLevel);
      expect(info2.hasAlarm).assertEqual(info.hasAlarm);
      expect(info2.status).assertEqual(info.status);
      expect(info2.alertType).assertEqual(info.alertType);
      expect(info2.duration).assertEqual(info.duration);
      expect(info2.imageType).assertEqual(info.imageType);
      expect(info2.mFlag).assertEqual(info.mFlag);
      expect(info2.mDisplayColor).assertEqual(info.mDisplayColor);
      expect(info2.mDay).assertEqual(info.mDay);
      expect(info2.mEventType).assertEqual(info.mEventType);
      expect(info2.mBegin).assertEqual(info.mBegin);
      expect(info2.mEnd).assertEqual(info.mEnd);
      expect(info2.mOriginalBegin).assertEqual(info.mOriginalBegin);
      expect(info2.mOriginalEnd).assertEqual(info.mOriginalEnd);
      expect(info2.mIsAllDay).assertEqual(info.mIsAllDay);
      expect(info2.mIsMultiDayEvent).assertEqual(info.mIsMultiDayEvent);
      expect(info2.mIsSetDayHead).assertEqual(info.mIsSetDayHead);
      expect(info2.mEventCalendar).assertEqual(info.mEventCalendar);
      expect(info2.mEventImageType).assertEqual(info.mEventImageType);
      expect(info2.mIsCanceled).assertEqual(info.mIsCanceled);
      expect(info2.mSelfAttendeeStatus).assertEqual(info.mSelfAttendeeStatus);
      expect(info2.mIsMeetingEvent).assertEqual(info.mIsMeetingEvent);
      expect(info2.mPosition).assertEqual(info.mPosition);
      expect(info2.mRepeatRule).assertEqual(info.mRepeatRule);
      expect(info2.mEventTimeStamp).assertEqual(info.mEventTimeStamp);
      expect(info2.mImportantEventType).assertEqual(info.mImportantEventType);
      expect(info2.mHwextServiceType).assertEqual(info.mHwextServiceType);
      expect(info2.mHwextServiceVerified).assertEqual(info.mHwextServiceVerified);
      expect(info2.mHwextServiceUri).assertEqual(info.mHwextServiceUri);
      expect(info2.mHwextServicePkgName).assertEqual(info.mHwextServicePkgName);
      expect(info2.mHwextServiceMinVersion).assertEqual(info.mHwextServiceMinVersion);
      expect(info2.mHwextServiceDescription).assertEqual(info.mHwextServiceDescription);
      expect(info2.mCornerType).assertEqual(info.mCornerType);
      expect(info2.checkValuesArray).assertEqual(info.checkValuesArray);
      expect(info2.mAttendeeList).assertEqual(info.mAttendeeList);
      expect(info2.mIsHoliday).assertEqual(info.mIsHoliday);
      expect(info2.isShareAgenda).assertEqual(info.isShareAgenda);
      expect(info2.isMessageResource).assertEqual(info.isMessageResource);
      expect(info2.isShareAgendaInitiator).assertEqual(info.isShareAgendaInitiator);
      expect(info2.uuid).assertEqual(info.uuid);
      expect(info2.identifier).assertEqual(info.identifier);
      expect(info2.isConflict).assertEqual(info.isConflict);
      expect(info2.oldEventId).assertEqual(info.oldEventId);
      expect(info2.eventStart).assertEqual(info.eventStart);
      expect(info2.userHandler).assertEqual(info.userHandler);
    })

    it('parseFromCursor', 0, () => {
      let cursor = new DataShareResultSetMock();
      let info = new AgendaEventInfo();
      info.parseFromCursor(new InnerResultSet(cursor, ''));
      expect(info.mId).assertEqual(0);
      expect(info.eventTimeZone).assertEqual('');
      expect(info.accessLevel).assertEqual(0);
      expect(info.hasAlarm).assertEqual('');
    })

    it('parseFromEvent', 0, () => {
      let cursor = new DataShareResultSetMock();
      const info: AgendaEventInfo = AgendaEventInfo.buildEventInfo(new InnerResultSet(cursor, ''));
      expect(info.mId).assertEqual(0);
      expect(info.eventTimeZone).assertEqual('');
      expect(info.mHwextServiceVerified).assertFalse();
    })

    it('parseFromEvent_undefined', 0, () => {
      let mocker = new MockKit();
      let cursor = new DataShareResultSetMock();
      let mockFuncGetString: Function = mocker.mockFunc(cursor, cursor.getString);
      when(mockFuncGetString)(ArgumentMatchers.any).afterReturn(undefined);
      let mockFuncGetLong: Function = mocker.mockFunc(cursor, cursor.getLong);
      when(mockFuncGetLong)(ArgumentMatchers.any).afterReturn(undefined);
      const info: AgendaEventInfo = AgendaEventInfo.buildEventInfo(new InnerResultSet(cursor, ''));
      expect(info.mIsAllDay).assertEqual(false);
      expect(info.mEventCalendar).assertEqual(0);
      expect(info.hasAlarm).assertEqual('');
    })

    const julianDay = 2459455; // 2021.10.15
    const time = DateUtil.julianDay2Date(julianDay).getTime();
    it('setFlag_FLAG_MID', 0, () => {
      let info = new AgendaEventInfo();
      info.mBegin = time + 100;
      info.mEnd = time + 300;
      info.setFlag(julianDay);
      expect(info.mFlag).assertEqual(AgendaEventInfo.FLAG_MID);
    });

    it('setFlag_FLAG_START', 0, () => {
      let info = new AgendaEventInfo();
      info.mBegin = time + 100;
      info.mEnd = time + MILLS_PER_DAY * 2;
      info.setFlag(julianDay);
      expect(info.mFlag).assertEqual(AgendaEventInfo.FLAG_START);
    });

    it('setFlag_FLAG_END', 0, () => {
      let info = new AgendaEventInfo();
      info.mBegin = time - MILLS_PER_DAY;
      info.mEnd = time + MILLS_PER_DAY * 0.5;
      info.setFlag(julianDay);
      expect(info.mFlag).assertEqual(AgendaEventInfo.FLAG_END);
    })

    it('isOnlineMeeting', 0, () => {
      let info = new AgendaEventInfo();
      info.mHwextServiceVerified = false;
      expect(info.isOnlineMeeting()).assertFalse();
      info.mHwextServiceVerified = true;
      GlobalThis.getInstance().serviceType = ['test'];
      info.mHwextServiceType = 'test';
      expect(info.isOnlineMeeting()).assertTrue();
    })

    it('isOutDate', 0, () => {
      let info = new AgendaEventInfo();
      info.mEnd = Date.now() - MILLS_PER_DAY;
      expect(info.isOutDate()).assertTrue()
    })

    it('isOneKeyService', 0, () => {
      let info = new AgendaEventInfo();
      info.mHwextServiceVerified = false;
      expect(info.isOneKeyService()).assertFalse();
      info.mHwextServiceVerified = true;
      info.mHwextServiceType = 'Meeting';
      expect(info.isOneKeyService()).assertTrue();
      info.mHwextServiceType = '';
      expect(info.isOneKeyService()).assertFalse();
    })

    it('canShowOneKeyService', 0, () => {
      let info = new AgendaEventInfo();
      info.mHwextServiceVerified = false;
      expect(info.canShowOneKeyService()).assertFalse();
      info.mHwextServiceVerified = true;
      info.mHwextServiceType = 'Meeting';
      info.mIsAllDay = false;
      const nowTime = Date.now();
      info.mBegin = nowTime + MILLS_PER_MINUTE * 10;
      info.mEnd = nowTime + MILLS_PER_MINUTE * 60;
      expect(info.canShowOneKeyService()).assertTrue();
      info.mBegin = nowTime + MILLS_PER_MINUTE * 11;
      expect(info.canShowOneKeyService()).assertTrue();
      info.mBegin = nowTime + MILLS_PER_MINUTE * 20;
      info.mEnd = nowTime + MILLS_PER_MINUTE * 80;
      expect(info.canShowOneKeyService()).assertFalse();
      info.mIsAllDay = true;
      const nowDay = DateUtil.getJulianDay();
      info.mStartDay = nowDay;
      info.mEndDay = nowDay;
      expect(info.canShowOneKeyService()).assertTrue();
    })

    it('isRepeatEvent', 0, () => {
      let info = new AgendaEventInfo();
      expect(info.isRepeatEvent()).assertFalse();
      info.mRepeatRule = '111';
      expect(info.isRepeatEvent()).assertTrue();
    })

    it('isImportantAnniversaries', 0, () => {
      let info = new AgendaEventInfo();
      info.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      expect(info.isImportantAnniversaries()).assertTrue();
      info.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      expect(info.isImportantAnniversaries()).assertFalse();
    })

    it('isImportantCountDown', 0, () => {
      let info = new AgendaEventInfo();
      info.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      expect(info.isImportantCountDown()).assertTrue();
      info.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      expect(info.isImportantCountDown()).assertFalse();
    })

    it('isImportantEvent', 0, () => {
      let info = new AgendaEventInfo();
      info.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      expect(info.isImportantEvent()).assertFalse();
      info.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      expect(info.isImportantEvent()).assertTrue();
      info.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      expect(info.isImportantEvent()).assertTrue();
    })

    it('isHoliday', 0, () => {
      let info = new AgendaEventInfo();
      info.mTitle = '';
      info.mImportantEventType = CalendarContract.EventImportantType.HOLIDAY;
      expect(info.isHoliday()).assertFalse();
      info.mTitle = 'title';
      expect(info.isHoliday()).assertTrue();
      info.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      info.mIsHoliday = true;
      expect(info.isHoliday()).assertTrue();
    })

    it('isFirstRepeatedAgenda', 0, () => {
      let info = new AgendaEventInfo();
      info.mRepeatRule = 'repeat';
      let startTime = new Date().getTime();
      info.mBegin = startTime;
      info.eventStart = startTime;
      info.mOriginalBegin = startTime;
      expect(info.isFirstRepeatAgenda()).assertTrue();
    })

    it('isNotFirstRepeatedAgenda', 0, () => {
      let info = new AgendaEventInfo();
      info.mRepeatRule = 'repeat';
      let startTime = new Date().getTime();
      info.mBegin = startTime;
      info.eventStart = 0;
      info.mOriginalBegin = 0;
      expect(info.isFirstRepeatAgenda()).assertFalse();
    })

    it('deepCloneAgendaEventInfo_with_basicInfo', 0, async (done: Function) => {
      let oldAgendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      oldAgendaEventInfo.mId = 1;
      oldAgendaEventInfo.mCalendarId = 2;
      oldAgendaEventInfo.mTitle = "Meeting";
      oldAgendaEventInfo.mLocation = "Conference Room";
      oldAgendaEventInfo.mDescription = "Discuss the project";
      oldAgendaEventInfo.mStartDay = 1627840000000;
      oldAgendaEventInfo.mEndDay = 1627840000000;
      oldAgendaEventInfo.mIsHoliday = true;


      let newAgendaEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(oldAgendaEventInfo);
      expect(newAgendaEventInfo).assertDeepEquals(oldAgendaEventInfo);
      done();
    });

    it('deepCloneAgendaEventInfo_checkValuesArray', 0, async (done: Function) => {
      let oldAgendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      oldAgendaEventInfo.checkValuesArray = [
        {
          id: 3,
          eventId: 1,
          syncId: 'haha',
          remindType: 1,
          remindMinutes: 10,
          eventUuid: ''
        },
        {
          id: 4,
          eventId: 1,
          syncId: 'haha',
          remindType: 1,
          remindMinutes: 30,
          eventUuid: ''
        }
      ];
      let newAgendaEventInfo: AgendaEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(oldAgendaEventInfo);
      for (let i = 0; i < newAgendaEventInfo.checkValuesArray.length; i++) {
        expect(newAgendaEventInfo.checkValuesArray[i].eventId).assertEqual(oldAgendaEventInfo.checkValuesArray[i].eventId);
        expect(newAgendaEventInfo.checkValuesArray[i].remindMinutes).assertEqual(oldAgendaEventInfo.checkValuesArray[i].remindMinutes);
        expect(newAgendaEventInfo.checkValuesArray[i].remindType).assertEqual(oldAgendaEventInfo.checkValuesArray[i].remindType);
        expect(newAgendaEventInfo.checkValuesArray[i].syncId).assertEqual(oldAgendaEventInfo.checkValuesArray[i].syncId);
      }
      done();
    });

    it('deepCloneAgendaEventInfo_mAttendeeList', 0, async (done: Function) => {
      let oldAgendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      oldAgendaEventInfo.mAttendeeList = [{
        id: 2,
        eventId: 0,
        attendeeName: 'bbb',
        attendeeEmail: 'hello@126.com',
        attendeeStatus: 0,
        attendeeRelationship: 0,
        attendeeType: 0,
        attendeeIdentity: '',
        attendeeIdNamespace: '',
      },
        {
          id: 2,
          eventId: 0,
          attendeeName: 'aaa',
          attendeeEmail: 'hello1@126.com',
          attendeeStatus: 0,
          attendeeRelationship: 0,
          attendeeType: 0,
          attendeeIdentity: '',
          attendeeIdNamespace: '',
        }];
      ;
      let newAgendaEventInfo: AgendaEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(oldAgendaEventInfo);
      for (let i = 0; i < newAgendaEventInfo.mAttendeeList.length; i++) {
        expect(newAgendaEventInfo.mAttendeeList[i].eventId).assertEqual(oldAgendaEventInfo.mAttendeeList[i].eventId);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeName).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeName);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeStatus).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeStatus);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeRelationship).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeRelationship);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeType).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeType);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeIdentity).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeIdentity);
        expect(newAgendaEventInfo.mAttendeeList[i].attendeeIdNamespace).assertEqual(oldAgendaEventInfo.mAttendeeList[i].attendeeIdNamespace);
      }
      done();
    });

    it('getLocation', 0, () => {
      expect(AgendaEventInfo.getLocation('')).assertEqual(-1);
      expect(AgendaEventInfo.getLocation(' ')).assertEqual(-1);
      expect(AgendaEventInfo.getLocation('null')).assertEqual(-1);
      expect(AgendaEventInfo.getLocation('0')).assertEqual(0);
      expect(AgendaEventInfo.getLocation('2as25ADWE14SDW2114FEFE')).assertEqual(-1);
      expect(AgendaEventInfo.getLocation('31.156425')).assertEqual(31.156425);
    });
  })
}