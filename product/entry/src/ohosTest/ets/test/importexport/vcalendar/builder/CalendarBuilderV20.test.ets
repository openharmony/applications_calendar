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
import { TestUtil } from '../../../utils/TestUtil'
import { AgendaEventInfo, AgendaEventInfoWrap, CalendarContract } from '@app/common'
import { HashMap } from '@kit.ArkTS'
import { CalendarBuilderV20 } from '@app/feature.importexport/src/main/ets/vcalendar/export/builder/CalendarBuilderV20'
import { WriteSyncStream } from '@app/common/src/main/ets/util/WriteSyncStream'


export default function CalendarBuilderV20Test() {
  describe('CalendarBuilderV20Test', () => {
    let builder: CalendarBuilderV20;
    let mocker: MockKit;
    beforeEach(() => {
      mocker = new MockKit();
      let calendarInfo = new CalendarInfo;
      builder = new CalendarBuilderV20(calendarInfo);
    });

    it('getVersion', 0, () => {
      expect(builder.getVersion()).assertEqual('VERSION:2.0');
    });

    it('setOutputFilePath', 0, () => {
      builder.setOutputFilePath('/path/test');
      let outputFilePath: string = TestUtil.getPrivateAttribute(builder, 'outputFilePath')
      expect(outputFilePath).assertEqual('/path/test');
    });

    it('buildExportFile_account_null_and_event_empty', 0, async (done: Function) => {
      let reminderMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
      const result = await builder.buildExportFile(undefined, [], reminderMap);
      expect(result).assertFalse();
      done();
    });

    it('buildExportFile_account_and_event_empty', 0, async (done: Function) => {
      let account: CalendarContract.Accounts | undefined = new CalendarContract.Accounts;
      let reminderMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
      let stream = new WriteSyncStream;
      when(mocker.mockFunc(stream, stream.writeSync))(ArgumentMatchers.any).afterReturn(1);
      builder.stream = stream;
      const result = await builder.buildExportFile(account, [], reminderMap);
      expect(result).assertTrue();
      done();
    });

    it('buildExportFile_no_account', 0, async (done: Function) => {
      let account: CalendarContract.Accounts | undefined = undefined;
      let info = new AgendaEventInfo();
      info.mId = 1;
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

    it('writeStatus', 0, () => {
      const writeStatus = TestUtil.getPrivateFunction(builder, 'writeStatus');
      if (!writeStatus) {
        expect(writeStatus).assertNull();
      } else {
        let info = new AgendaEventInfoWrap();
        expect(writeStatus(info)).assertEqual('');
        info.status = 'abc';
        expect(writeStatus(info)).assertEqual('');
        info.status = '0';
        expect(writeStatus(info)).assertEqual('STATUS:TENTATIVE\r\n');
        info.status = '1';
        expect(writeStatus(info)).assertEqual('STATUS:CONFIRMED\r\n');
        info.status = '2';
        expect(writeStatus(info)).assertEqual('STATUS:DECLINED\r\n');
        info.status = '3';
        expect(writeStatus(info)).assertEqual('STATUS:TENTATIVE\r\n');
      }
    });

    it('writeRule', 0, () => {
      const writeRule = TestUtil.getPrivateFunction(builder, 'writeRule');
      if (!writeRule) {
        expect(writeRule).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(writeRule(eventInfo)).assertEqual('');
        eventInfo.mRepeatRule = 'FREQ=DAILY;COUNT=10';
        expect(writeRule(eventInfo)).assertEqual('RRULE:FREQ=DAILY;COUNT=10\r\n')
      }
    });


    it('writeTitle', 0, () => {
      const writeTitle = TestUtil.getPrivateFunction(builder, 'writeTitle');
      if (!writeTitle) {
        expect(writeTitle).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(writeTitle(eventInfo)).assertEqual('');
        eventInfo.mTitle = 'Test Title';
        expect(writeTitle(eventInfo)).not().assertEqual(''); // 待补充具体规格
      }
    });

    it('writeClass', 0, () => {
      const writeClass = TestUtil.getPrivateFunction(builder, 'writeClass');
      if (!writeClass) {
        expect(writeClass).assertNull();
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

    it('writeDtStartAndEnd_mIsAllDay', 0, () => {
      const writeDtStartAndEnd = TestUtil.getPrivateFunction(builder, 'writeDtStartAndEnd');
      if (!writeDtStartAndEnd) {
        expect(writeDtStartAndEnd).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(writeDtStartAndEnd(eventInfo)).assertEqual('');
        eventInfo.mIsAllDay = true;
        eventInfo.mEnd = 123;
        eventInfo.mBegin = 123;
        expect(writeDtStartAndEnd(eventInfo)).not().assertEqual('');
      }
    });

    it('cancel', 0, () => {
      let calendarInfo = new CalendarInfo;
      const CalendarBuilderV20Test = new CalendarBuilderV20(calendarInfo);
      CalendarBuilderV20Test.cancel();
      const isCanceled: boolean = TestUtil.getPrivateAttribute(CalendarBuilderV20Test, 'isCanceled');
      expect(isCanceled).assertTrue();
    });

    it('getFormatLastDate', 0, () => {
      const getFormatLastDate = TestUtil.getPrivateFunction(builder, 'getFormatLastDate');
      if (!getFormatLastDate) {
        expect(getFormatLastDate).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.lastDate = 1735664400000;
        expect(getFormatLastDate(eventInfo)).assertEqual('20241231T170000Z');
      }
    });

    it('getSuitableCharset', 0, () => {
      const getSuitableCharset = TestUtil.getPrivateFunction(builder, 'getSuitableCharset');
      if (!getSuitableCharset) {
        expect(getSuitableCharset).assertNull();
      } else {
        const inputString: string = 'UTF-8';
        const result: string = getSuitableCharset(inputString);
        expect(result).assertEqual('UTF-8');
      }
    });

    it('encodeQuotedPrintable', 0, () => {
      const encodeQuotedPrintable = TestUtil.getPrivateFunction(builder, 'encodeQuotedPrintable');
      if (!encodeQuotedPrintable) {
        expect(encodeQuotedPrintable).assertNull();
      } else {
        const buffer: string = 'This is a test string';
        const charSet: string = 'UTF-8';
        const result: string = encodeQuotedPrintable(buffer, charSet);
        expect(result).assertEqual('=54=68=69=73=20=69=73=20=61=20=74=65=73=74=20=73=74=72=69=6E=67');
      }
    });

    it('writeDescription', 0, () => {
      const writeDescription = TestUtil.getPrivateFunction(builder, 'writeDescription');
      if (!writeDescription) {
        expect(writeDescription).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mDescription = 'this is a description';
        eventInfo.mHwextServiceType = 'Meeting';
        const result: string = writeDescription(eventInfo);
        expect(result != '').assertTrue();
      }
    });

    it('writeServiceDescription', 0, () => {
      const writeServiceDescription = TestUtil.getPrivateFunction(builder, 'writeServiceDescription');
      if (!writeServiceDescription) {
        expect(writeServiceDescription).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mHwextServiceDescription = 'this is a description';
        const result: string = writeServiceDescription(eventInfo);
        expect(result != '').assertTrue();
      }
    });

    it('writeServiceUri', 0, () => {
      const writeServiceUri = TestUtil.getPrivateFunction(builder, 'writeServiceUri');
      if (!writeServiceUri) {
        expect(writeServiceUri).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mHwextServiceUri = 'this is a uri';
        const result: string = writeServiceUri(eventInfo);
        expect(result != '').assertTrue();
      }
    });

    it('writeAlarm', 0, () => {
      const writeAlarm = TestUtil.getPrivateFunction(builder, 'writeAlarm');
      if (!writeAlarm) {
        expect(writeAlarm).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.remindMinutes = 10;
        const reminders: CalendarContract.Reminders[] = [];
        reminders.push(reminder);
        eventInfo.reminders = reminders;
        const result: string = writeAlarm(eventInfo);
        expect(result !== '').assertTrue();
      }
    });

    it('writeComplete', 0, () => {
      const writeComplete = TestUtil.getPrivateFunction(builder, 'writeComplete');
      if (!writeComplete) {
        expect(writeComplete).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        eventInfo.mEndDay = 1735664400000;
        const result: string = writeComplete(eventInfo);
        expect(result !== '').assertTrue();
      }
    });
  })
}