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

import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium'
import { CalendarInfo } from '@app/feature.importexport/src/main/ets/vcalendar/CalendarInfo'
import { CalendarBuilderV10 } from '@app/feature.importexport/src/main/ets/vcalendar/export/builder/CalendarBuilderV10'
import { UTF_16 } from '@app/common/src/main/ets/util/CharsetUtil'
import { TestUtil } from '../../../utils/TestUtil'
import { AgendaEventInfo, AgendaEventInfoWrap, CalendarContract, GlobalThis } from '@app/common'
import { HashMap } from '@kit.ArkTS'
import { WriteSyncStream } from '@app/common/src/main/ets/util/WriteSyncStream'

export default function CalendarBuilderV10Test() {
  describe('CalendarBuilderV10Test', () => {
    let builder: CalendarBuilderV10;
    let filePath = GlobalThis.getInstance().context?.cacheDir + '/calendarv10.vcs';
    let mocker: MockKit;
    beforeEach(() => {
      mocker = new MockKit();
      let calendarInfo = new CalendarInfo;
      builder = new CalendarBuilderV10(calendarInfo);
    });

    it('getVersion', 0, () => {
      expect(builder.getVersion()).assertEqual('VERSION:1.0');
    });

    it('setEncoding', 0, () => {
      builder.setEncoding(UTF_16);
      let mCharsetEncoding: string = TestUtil.getPrivateAttribute(builder, 'mCharsetEncoding')
      expect(mCharsetEncoding).assertEqual(UTF_16);
    });

    it('setOutputFilePath', 0, () => {
      builder.setOutputFilePath('/path/test');
      let outputFilePath: string = TestUtil.getPrivateAttribute(builder, 'outputFilePath')
      expect(outputFilePath).assertEqual('/path/test');
    });

    it('buildExportFile', 0, async (done: Function) => {
      let account: CalendarContract.Accounts | undefined = undefined;
      let info = new AgendaEventInfo();
      info.mId = 1;
      info.status = '0';
      info.mTitle = 'test';
      info.mLocation = 'aaa';
      info.mDescription = 'mDescription';
      info.mRepeatRule = 'aaa';
      let events: Array<AgendaEventInfo> = [info];
      let reminderMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
      reminderMap.set(1, [])
      let stream = new WriteSyncStream;
      when(mocker.mockFunc(stream, stream.writeSync))(ArgumentMatchers.any).afterReturn(1);
      builder.stream = stream;
      const result = await builder.buildExportFile(account, events, reminderMap);
      expect(result).assertTrue();
      done();
    });

    it('writeRule', 0, () => {
      const writeRule = TestUtil.getPrivateFunction(builder, 'writeRule');
      if (!writeRule) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(writeRule(eventInfo)).assertEqual('');
        eventInfo.mRepeatRule = 'FREQ=DAILY;COUNT=10';
        expect(writeRule(eventInfo)).assertEqual('RRULE:FREQ=DAILY;COUNT=10\r\n')
      }
    });

    it('writeStatus', 0, () => {
      const writeStatus = TestUtil.getPrivateFunction(builder, 'writeStatus');
      if (!writeStatus) {
        expect(false).assertTrue();
      } else {
        expect(writeStatus('')).assertEqual('');
        expect(writeStatus('abc')).assertEqual('');
        expect(writeStatus('0')).assertEqual('STATUS:TENTATIVE\r\n');
        expect(writeStatus('1')).assertEqual('STATUS:CONFIRMED\r\n');
        expect(writeStatus('2')).assertEqual('STATUS:DECLINED\r\n');
        expect(writeStatus('3')).assertEqual('STATUS:TENTATIVE\r\n');
      }
    });

    it('writeTitle', 0, () => {
      const writeTitle = TestUtil.getPrivateFunction(builder, 'writeTitle');
      if (!writeTitle) {
        expect(false).assertTrue();
      } else {
        expect(writeTitle('')).assertEqual('');
        expect(writeTitle('Test Title')).not().assertEqual(''); // 待补充具体规格
      }
    });

    it('writeClass', 0, () => {
      const writeClass = TestUtil.getPrivateFunction(builder, 'writeClass');
      if (!writeClass) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.accessLevel = 0;
        expect(writeClass(eventInfo)).assertEqual('CLASS:PUBLIC\r\n');
        eventInfo.accessLevel = 3;
        expect(writeClass(eventInfo)).assertEqual('CLASS:PUBLIC\r\n');
        eventInfo.accessLevel = 2;
        expect(writeClass(eventInfo)).assertEqual('CLASS:PRIVATE\r\n');
        eventInfo.accessLevel = 1;
        expect(writeClass(eventInfo)).assertEqual('');
      }
    });

    it('writeStartAndAlarm_empty', 0, () => {
      const writeStartAndAlarm = TestUtil.getPrivateFunction(builder, 'writeStartAndAlarm');
      if (!writeStartAndAlarm) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(writeStartAndAlarm(eventInfo)).assertEqual('DTSTART:\r\n');
      }
    });

    it('writeStartAndAlarm_mIsAllDay', 0, () => {
      const writeStartAndAlarm = TestUtil.getPrivateFunction(builder, 'writeStartAndAlarm');
      if (!writeStartAndAlarm) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mIsAllDay = true;
        expect(writeStartAndAlarm(eventInfo)).assertEqual('DTSTART:\r\n');
      }
    });

    it('writeDtEndTest', 0, () => {
      const writeDtEnd = TestUtil.getPrivateFunction(builder, 'writeDtEnd');
      if (!writeDtEnd) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mEnd = Date.now();
        const dtEndString: string = writeDtEnd(eventInfo);
        expect(dtEndString.startsWith('DTEND:')).assertTrue();
      }
    });

    it('setDtEndTo235900FormatTest', 0, () => {
      const setDtEndTo235900Format = TestUtil.getPrivateFunction(builder, 'setDtEndTo235900Format');
      if (!setDtEndTo235900Format) {
        expect(setDtEndTo235900Format).assertNull();
      } else {
        const dtEndMills: number = 1735660800000;
        const time: string = setDtEndTo235900Format(dtEndMills);
        expect(time).assertEqual('20241231T235900Z');
      }
    });

    it('getDtEndFromDurationTest', 0, () => {
      const getDtEndFromDuration = TestUtil.getPrivateFunction(builder, 'getDtEndFromDuration');
      if (!getDtEndFromDuration) {
        expect(getDtEndFromDuration).assertNull();
      } else {
        const dtEndMills: number = 1735660800000;
        const durationString: string = 'P1H';
        const time: number = getDtEndFromDuration(dtEndMills, durationString);
        expect(time).assertEqual(1735664400000);
      }
    });

    it('getAlarmStartTimeInUTCTest_001', 0, () => {
      const getAlarmStartTimeInUTC = TestUtil.getPrivateFunction(builder, 'getAlarmStartTimeInUTC');
      if (!getAlarmStartTimeInUTC) {
        expect(getAlarmStartTimeInUTC).assertNull();
      } else {
        const minutesBeforeAlarmStart: string = '1440';
        const dtStartInMillis: number = 1735664400000;
        const time: string = getAlarmStartTimeInUTC(minutesBeforeAlarmStart, dtStartInMillis);
        expect(time).assertEqual('20241230T170000Z');
      }
    });

    it('getAlarmStartTimeInUTCTest_002', 0, () => {
      const getAlarmStartTimeInUTC = TestUtil.getPrivateFunction(builder, 'getAlarmStartTimeInUTC');
      if (!getAlarmStartTimeInUTC) {
        expect(getAlarmStartTimeInUTC).assertNull();
      } else {
        const minutesBeforeAlarmStart: string = 'ABC';
        const dtStartInMillis: number = 1735664400000;
        const time: string = getAlarmStartTimeInUTC(minutesBeforeAlarmStart, dtStartInMillis);
        expect(time).assertEqual('20241231T170000Z');
      }
    });

    it('getFormatLastDateTest_001', 0, () => {
      const getFormatLastDate = TestUtil.getPrivateFunction(builder, 'getFormatLastDate');
      if (!getFormatLastDate) {
        expect(getFormatLastDate).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.lastDate = -1;
        eventInfo.mEnd = 1735664400000;
        eventInfo.mBegin = 1735660800000;
        const result: string = getFormatLastDate(eventInfo);
        expect(result).assertEqual('20241231T170000Z');
      }
    });

    it('getFormatLastDateTest_002', 0, () => {
      const getFormatLastDate = TestUtil.getPrivateFunction(builder, 'getFormatLastDate');
      if (!getFormatLastDate) {
        expect(getFormatLastDate).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.lastDate = -1;
        eventInfo.mEnd = 1735660800000;
        eventInfo.mBegin = 1735664400000;
        const result: string = getFormatLastDate(eventInfo);
        expect(result).assertEqual('20241231T170000Z');
      }
    });

    it('writeServiceDescriptionTest', 0, () => {
      const writeServiceDescription = TestUtil.getPrivateFunction(builder, 'writeServiceDescription');
      if (!writeServiceDescription) {
        expect(writeServiceDescription).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mHwextServiceDescription = 'this is a description!';
        const result: string = writeServiceDescription(eventInfo);
        expect(result !== '').assertTrue();
      }
    });

    it('writeServiceUriTest', 0, () => {
      const writeServiceUri = TestUtil.getPrivateFunction(builder, 'writeServiceUri');
      if (!writeServiceUri) {
        expect(writeServiceUri).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mHwextServiceUri = 'this is a uri!';
        const result: string = writeServiceUri(eventInfo);
        expect(result !== '').assertTrue();
      }
    });

    it('writeStartAndAlarmTest', 0, () => {
      const writeStartAndAlarm = TestUtil.getPrivateFunction(builder, 'writeStartAndAlarm');
      if (!writeStartAndAlarm) {
        expect(writeStartAndAlarm).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mBegin = 1735660800000;
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.remindMinutes = 10;
        const reminders: CalendarContract.Reminders[] = [];
        reminders.push(reminder);
        eventInfo.reminders = reminders;
        const result: string = writeStartAndAlarm(eventInfo);
        expect(result !== null).assertTrue();
      }
    });

    it('trimZFromUTCTimeTest_001', 0, () => {
      const trimZFromUTCTime = TestUtil.getPrivateFunction(builder, 'trimZFromUTCTime');
      if (!trimZFromUTCTime) {
        expect(trimZFromUTCTime).assertNull();
      } else {
        const time: string = '20241231T170000Z';
        const timezoneId: string = 'UTC';
        const result: string = trimZFromUTCTime(time, timezoneId);
        expect(result).assertEqual('20241231T170000');
      }
    });

    it('trimZFromUTCTimeTest_002', 0, () => {
      const trimZFromUTCTime = TestUtil.getPrivateFunction(builder, 'trimZFromUTCTime');
      if (!trimZFromUTCTime) {
        expect(trimZFromUTCTime).assertNull();
      } else {
        const time: string = '20241231T170000Z';
        const timezoneId: string = 'GBK';
        const result: string = trimZFromUTCTime(time, timezoneId);
        expect(result).assertEqual('20241231T170000Z');
      }
    });

    it('writeLocationTest', 0, () => {
      const writeLocation = TestUtil.getPrivateFunction(builder, 'writeLocation');
      if (!writeLocation) {
        expect(writeLocation).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        const result: string = writeLocation(eventInfo);
        expect(result).assertEqual('');
      }
    });

    it('writeDescription_001', 0, () => {
      const writeDescription = TestUtil.getPrivateFunction(builder, 'writeDescription');
      if (!writeDescription) {
        expect(writeDescription).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mDescription = 'This is a description';
        eventInfo.mHwextServiceType = 'Meeting';
        const result: string = writeDescription(eventInfo);
        expect(result !== '').assertTrue();
      }
    });

    it('writeDescription_002', 0, () => {
      const writeLocation = TestUtil.getPrivateFunction(builder, 'writeLocation');
      if (!writeLocation) {
        expect(writeLocation).assertNull();
      } else {
        const eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        const result: string = writeLocation(eventInfo);
        expect(result === '').assertTrue();
      }
    });
  })
}