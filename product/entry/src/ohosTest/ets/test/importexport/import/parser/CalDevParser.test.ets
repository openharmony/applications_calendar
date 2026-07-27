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

import { beforeEach, describe, expect, it } from '@ohos/hypium';
import { CalDevParser } from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalDevParser';
import { VcsComponent } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/VcsComponent';
import { TestUtil } from '../../../utils/TestUtil';
import { CustomTime } from '@app/feature.repeatrule';
import { AgendaEventInfoWrap, CalendarContract, EmptyUtils, Pair, TimeZoneUtil } from '@app/common';
import { CANCELLED, CONFIRMED, DECLINED, DTSTART, TENTATIVE } from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalendarParser';
import { Property } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Property';
import { Parameter } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Parameter';
import { TIMEZONE_ID } from '@app/feature.importexport/src/main/ets/vcalendar/VCalendarConstants';

export default function CalDevParserTest() {
  describe('CalDevParserTest', () => {
    let parser: CalDevParser;

    beforeEach(() => {
      parser = new CalDevParser();
    })

    it('fillEventByParseAlarm_remindMinute_invalid', 0, () => {
      const fillEventByParseAlarm = TestUtil.getPrivateFunction(parser, 'fillEventByParseAlarm');
      if (!fillEventByParseAlarm) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(fillEventByParseAlarm(event, '')).assertFalse();
      }
    })

    it('parseStartAndEndTime_timeString_empty', 0, () => {
      const parseStartAndEndTime = TestUtil.getPrivateFunction(parser, 'parseStartAndEndTime');
      if (!parseStartAndEndTime) {
        expect(false).assertTrue();
      } else {
        const time = new CustomTime();
        const result: Pair<boolean, CustomTime> = parseStartAndEndTime('', time, 'UTC');
        expect(result.first).assertFalse();
        expect(result.second).assertEqual(time);
      }
    })

    it('parseStartAndEndTime_timeString_parsing_fails', 0, () => {
      const parseStartAndEndTime = TestUtil.getPrivateFunction(parser, 'parseStartAndEndTime');
      if (!parseStartAndEndTime) {
        expect(false).assertTrue();
      } else {
        const time = new CustomTime();
        const result: Pair<boolean, CustomTime> = parseStartAndEndTime('timeString', time, 'UTC');
        expect(result.first).assertFalse();
        expect(result.second).assertEqual(time);
      }
    })

    it('parseStartAndEndTime', 0, () => {
      const parseStartAndEndTime = TestUtil.getPrivateFunction(parser, 'parseStartAndEndTime');
      if (!parseStartAndEndTime) {
        expect(false).assertTrue();
      } else {
        const time = new CustomTime();
        const result: Pair<boolean, CustomTime> =
          parseStartAndEndTime('20220101T000000Z', time, 'UTC');
        expect(result.first).assertTrue();
        expect(result.second).assertEqual(time);
      }
    })

    it('fillEventByParseAlarm', 0, () => {
      const fillEventByParseAlarm = TestUtil.getPrivateFunction(parser, 'fillEventByParseAlarm');
      if (!fillEventByParseAlarm) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.reminders = [new CalendarContract.Reminders];
        expect(fillEventByParseAlarm(event, '122H')).assertTrue();
      }
    })

    it('parseAlarmTime', 0, () => {
      const parseAlarmTime = TestUtil.getPrivateFunction(parser, 'parseAlarmTime');
      if (!parseAlarmTime) {
        expect(false).assertTrue();
      } else {
        expect(parseAlarmTime('')).assertEqual(-1);
        expect(parseAlarmTime('-PT0S')).assertEqual(0);
        expect(parseAlarmTime('1M')).assertEqual(1);
        expect(parseAlarmTime('122H')).assertEqual(7320);
        expect(parseAlarmTime('122D')).assertEqual(175680);
        expect(parseAlarmTime('122P')).assertEqual(0);
        expect(parseAlarmTime('122X')).assertEqual(10);
        expect(parseAlarmTime('122A')).assertEqual(10);
      }
    })

    it('fillEventByParseStatus', 0, () => {
      const fillEventByParseStatus = TestUtil.getPrivateFunction(parser, 'fillEventByParseStatus');
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(event, TENTATIVE)
        expect(event.status).assertEqual(
          CalendarContract.EventsEventStatus.EVENT_STATUS_TENTATIVE.toString());
        fillEventByParseStatus(event, CONFIRMED)
        expect(event.status).assertEqual(
          CalendarContract.EventsEventStatus.EVENT_STATUS_CONFIRMED.toString());
        fillEventByParseStatus(event, CANCELLED)
        expect(event.status).assertEqual(
          CalendarContract.EventsEventStatus.EVENT_STATUS_CANCELED.toString());
        fillEventByParseStatus(event, DECLINED)
        expect(event.status).assertEqual(
          CalendarContract.EventsEventStatus.EVENT_STATUS_CANCELED.toString());
      }
    })

    it('finalCheck_mBegin', 0, () => {
      const finalCheck = TestUtil.getPrivateFunction(parser, 'finalCheck');
      if (!finalCheck) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.mBegin = 0;
        expect(finalCheck(event)).assertFalse()
      }
    })

    it('finalCheck_duration', 0, () => {
      const finalCheck = TestUtil.getPrivateFunction(parser, 'finalCheck');
      if (!finalCheck) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.mBegin = 1234;
        event.duration = '11';
        expect(finalCheck(event)).assertTrue();
      }
    })

    it('finalCheck_mImportantEventType_ANNIVERSARIES', 0, () => {
      const finalCheck = TestUtil.getPrivateFunction(parser, 'finalCheck');
      if (!finalCheck) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.mBegin = 1234;
        event.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
        expect(finalCheck(event)).assertTrue();
      }
    })

    it('finalCheck_mImportantEventType_COUNTDOWN', 0, () => {
      const finalCheck = TestUtil.getPrivateFunction(parser, 'finalCheck');
      if (!finalCheck) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.mBegin = 1234;
        event.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
        expect(finalCheck(event)).assertTrue();
      }
    })

    it('finalCheck_mBegin_over_mEnd', 0, () => {
      const finalCheck = TestUtil.getPrivateFunction(parser, 'finalCheck');
      if (!finalCheck) {
        expect(false).assertTrue();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        event.mBegin = 1234;
        event.mEnd = 123;
        event.duration = '';
        event.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
        expect(finalCheck(event)).assertFalse();
      }
    })

    it('parseAndFillEventInfoTest', 0, () => {
      const parseAndFillEventInfo = TestUtil.getPrivateFunction(parser, 'parseAndFillEventInfo');
      if (!parseAndFillEventInfo) {
        expect(false).assertTrue();
      } else {
        const DING_TALK_ONLINE_MEETING_URL = 'X-DINGTALK-ONLINE-MEETING-URL';
        const eventComponent: VcsComponent = new VcsComponent('', undefined);
        let allProperty: Property[] = [];
        let event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(parseAndFillEventInfo(eventComponent, event, allProperty)).assertFalse();
        event = new AgendaEventInfoWrap();
        allProperty.push(new Property(DING_TALK_ONLINE_MEETING_URL, ''));
        parseAndFillEventInfo(eventComponent, event, allProperty);
        expect(EmptyUtils.isEmptyString(event.mHwextServiceUri)).assertTrue();
        allProperty = [];
        allProperty.push(new Property(DING_TALK_ONLINE_MEETING_URL, 'xxxx'));
        event = new AgendaEventInfoWrap();
        parseAndFillEventInfo(eventComponent, event, allProperty);
        expect(EmptyUtils.isEmptyString(event.mHwextServiceUri)).assertTrue();
        allProperty = [];
        allProperty.push(new Property(DING_TALK_ONLINE_MEETING_URL, 'dingtalk://dingtalkclient/page/xxx'));
        event = new AgendaEventInfoWrap();
        parseAndFillEventInfo(eventComponent, event, allProperty);
        expect(EmptyUtils.isEmptyString(event.mHwextServiceUri)).assertFalse();
      }
    })

    it('extractTimeZoneTest', 0, () => {
      const extractTimeZone = TestUtil.getPrivateFunction(parser, 'extractTimeZone');
      if (!extractTimeZone) {
        expect(false).assertTrue();
      } else {
        const eventComponent: VcsComponent = new VcsComponent('event', undefined);
        expect(extractTimeZone(eventComponent) === TimeZoneUtil.getCurrentTimeZone()).assertTrue();
        eventComponent.addProperty(new Property('xx', 'xx'));
        expect(extractTimeZone(eventComponent) === TimeZoneUtil.getCurrentTimeZone()).assertTrue();
        const dtStart = new Property(DTSTART, 'xx');
        eventComponent.addProperty(dtStart);
        expect(extractTimeZone(eventComponent) === TimeZoneUtil.getCurrentTimeZone()).assertTrue();
        dtStart.addParameter(new Parameter('xxx', 'xxx'));
        expect(extractTimeZone(eventComponent) === TimeZoneUtil.getCurrentTimeZone()).assertTrue();
        const tzIdPar = new Parameter(TIMEZONE_ID, 'xxx');
        dtStart.addParameter(tzIdPar);
        expect(extractTimeZone(eventComponent) === TimeZoneUtil.getCurrentTimeZone()).assertTrue();
        tzIdPar.value = 'Pacific/Kosrae';
        expect(extractTimeZone(eventComponent) === 'Pacific/Kosrae').assertTrue();
      }
    })

    it('parseStartOrEndTest', 0, () => {
      const parseStartOrEnd = TestUtil.getPrivateFunction(parser, 'parseStartOrEnd');
      if (!parseStartOrEnd) {
        expect(false).assertTrue();
      } else {
        let timeString = '20240618';
        let timeZone = 'Pacific/Kosrae';
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(parseStartOrEnd(timeString, event, timeZone).second.getTimeInMills() === 1718668800000).assertTrue();
        timeZone = 'Asia/Shanghai';
        timeString = '20240618T080000';
        expect(parseStartOrEnd(timeString, event, timeZone).second.getTimeInMills() === 1718668800000).assertTrue();
      }
    })

    it('extractAllPropertyFirstTest', 0, () => {
      const extractAllPropertyFirst = TestUtil.getPrivateFunction(parser, 'extractAllPropertyFirst');
      if (!extractAllPropertyFirst) {
        expect(false).assertTrue();
      } else {
        const vcsComponent: VcsComponent = new VcsComponent('', undefined);
        expect((extractAllPropertyFirst(vcsComponent) as Property[])?.length).assertLargerOrEqual(0);
      }
    })

    it('setDtEndValueIfRepeatEventTest_001', 0, () => {
      const setDtEndValueIfRepeatEvent = TestUtil.getPrivateFunction(parser, 'setDtEndValueIfRepeatEvent');
      if (!setDtEndValueIfRepeatEvent) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mBegin = 1735660800000;
        eventInfo.duration = 'P1H';
        const result: boolean = setDtEndValueIfRepeatEvent(eventInfo);
        expect(result).assertTrue();
      }
    })

    it('setDtEndValueIfRepeatEventTest_002', 0, () => {
      const setDtEndValueIfRepeatEvent = TestUtil.getPrivateFunction(parser, 'setDtEndValueIfRepeatEvent');
      if (!setDtEndValueIfRepeatEvent) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mBegin = 1735660800000;
        eventInfo.duration = 'PPP';
        const result: boolean = setDtEndValueIfRepeatEvent(eventInfo);
        expect(result).assertFalse();
      }
    })
  })
}