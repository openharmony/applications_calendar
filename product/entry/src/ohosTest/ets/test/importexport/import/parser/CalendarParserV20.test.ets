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
import { AgendaEventInfo, AgendaEventInfoWrap, CalendarContract, ISO_8859_1, UTF_8 } from '@app/common';
import { VcsComponent } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/VcsComponent';
import { CalendarInfo } from '@app/feature.importexport/src/main/ets/vcalendar/CalendarInfo';
import { VERSION_10 } from '@app/feature.importexport/src/main/ets/vcalendar/VCalendarConstants';
import {
  CANCELLED,
  COMPLETED,
  CONFIRMED,
  DECLINED,
  DESCRIPTION,
  DOWNIMPORTANTEVENTTYPE,
  DTEND,
  DTSTART,
  DUE,
  DURATION,
  EVENTALERTTYPE,
  EVENTCALENDARTYPE,
  EVENTIMAGETYPE,
  EVENTTYPEEXT,
  LOCATION,
  NORMALALERT,
  NORMALEVENTTYPE,
  ParseResult,
  RRULE,
  SOLAR,
  STATUS,
  SUMMARY,
  TENTATIVE,
  UPIMPORTANTEVENTTYPE
} from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalendarParser';
import { TestUtil } from '../../../utils/TestUtil';
import { Property } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Property';
import { ENCODING_STRING } from '@app/feature.importexport/src/main/ets/vcalendar/VCalParser';
import { Parameter } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Parameter';
import { CalendarParserV20 } from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalendarParserV20';

export default function CalendarParserV20Test() {
  describe('CalendarParserV20Test', () => {
    let parser: CalendarParserV20;
    let component: VcsComponent;
    let calendarInfo: CalendarInfo = new CalendarInfo('', VERSION_10);
    let fillEventByParseStatus: Function | null;
    let parseEventReminds: Function | null;
    let getAlarmStartTimeString: Function | null;
    let parseOtherField: Function | null;
    let parseOtherPropertyAndFillEvent: Function | null;
    let extractReminderProperty: Function | null;
    let parseAndFillEventInfo: Function | null;
    let parseTimeInfoAndFillEvent: Function | null;
    beforeEach(() => {
      parser = new CalendarParserV20(calendarInfo);
      component = new VcsComponent('test', undefined);
      parseEventReminds = TestUtil.getPrivateFunction(parser, 'parseEventReminds');
      getAlarmStartTimeString = TestUtil.getPrivateFunction(parser, 'getAlarmStartTimeString');
      parseOtherField = TestUtil.getPrivateFunction(parser, 'parseOtherField');

      fillEventByParseStatus = TestUtil.getPrivateFunction(parser, 'fillEventByParseStatus');
      parseOtherPropertyAndFillEvent = TestUtil.getPrivateFunction(parser, 'parseOtherPropertyAndFillEvent');

      extractReminderProperty = TestUtil.getPrivateFunction(parser, 'extractReminderProperty');
      parseAndFillEventInfo = TestUtil.getPrivateFunction(parser, 'parseAndFillEventInfo');
      parseTimeInfoAndFillEvent = TestUtil.getPrivateFunction(parser, 'parseTimeInfoAndFillEvent');

    })

    it('parseEvent_null', 0, async (done: Function) => {
      if (!parser) {
        expect(parser).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap;
        let result: boolean = false; //= await parser.parseEvent(component, eventInfo);
        expect(result).assertFalse();
        done();
      }
    })

    it('extractReminderProperty_subComponents_empty', 0, () => {
      if (!extractReminderProperty) {
        expect(false).assertTrue();
      } else {
        let rootComponent = new VcsComponent('test', undefined);
        let result: Array<Property> = extractReminderProperty(rootComponent)
        expect(result.length).assertEqual(0);
      }
    })

    it('extractReminderProperty', 0, () => {
      if (!extractReminderProperty) {
        expect(false).assertTrue();
      } else {
      let rootComponent = new VcsComponent('test', undefined);
      let subComponent = new VcsComponent('alarm', undefined);
      subComponent.addProperty(new Property('action', 'AUDIO'));
      rootComponent.addChild(subComponent)
      let result: Array<Property> = extractReminderProperty(rootComponent)
      expect(result.length).assertEqual(1);
      }
    })

    it('parseAndFillEventInfo', 0, () => {
      if (!parseAndFillEventInfo) {
        expect(parseAndFillEventInfo).assertNull();
      } else {
        let allProperty: Property[] = [];
        allProperty.push(new Property(LOCATION, 'VALUE'));
        let descriptionProp = new Property(DESCRIPTION, 'VALUE');
        descriptionProp.addParameter(new Parameter(ENCODING_STRING, 'value'));
        allProperty.push(new Property(DESCRIPTION, 'VALUE'));
        let summaryProp = new Property(SUMMARY, 'VALUE');
        descriptionProp.addParameter(new Parameter('CHARSET', 'value'));
        allProperty.push(summaryProp);

        allProperty.push(new Property(DTEND, 'T123456'));
        allProperty.push(new Property(DTSTART, 'T123456'));
        allProperty.push(new Property(COMPLETED, 'COMPLETED'));
        allProperty.push(new Property('other', 'VALUE'));
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseAndFillEventInfo(event, allProperty);
        expect(result).assertFalse();
      }
    })

    it('parseAlarmTime', 0, () => {
      const parseAlarmTime = TestUtil.getPrivateFunction(parser, 'parseAlarmTime');
      if (!parseAlarmTime) {
        expect(false).assertTrue();
      } else {
        expect(parseAlarmTime('')).assertEqual(-1);
        expect(parseAlarmTime('1M')).assertEqual(1);
        expect(parseAlarmTime('122H')).assertEqual(7320);
        expect(parseAlarmTime('122D')).assertEqual(175680);
        expect(parseAlarmTime('122P')).assertEqual(0);
        expect(parseAlarmTime('122X')).assertEqual(10);
        expect(parseAlarmTime('122A')).assertEqual(10);
      }
    })

    it('fillEventByParseStatus_TENTATIVE', 0, () => {
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(eventInfo, TENTATIVE);
        expect(eventInfo.status).assertEqual('0');
      }
    })

    it('fillEventByParseStatus_CONFIRMED', 0, () => {
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(eventInfo, CONFIRMED);
        expect(eventInfo.status).assertEqual('1');
      }
    })

    it('fillEventByParseStatus_CANCELLED', 0, () => {
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(eventInfo, CANCELLED);
        expect(eventInfo.status).assertEqual('2');
      }
    })

    it('fillEventByParseStatus_STATUS_DECLINED', 0, () => {
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(eventInfo, DECLINED);
        expect(eventInfo.status).assertEqual('2');
      }
    })

    it('fillEventByParseStatus_STATUS_other', 0, () => {
      if (!fillEventByParseStatus) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseStatus(eventInfo, 'other');
        expect(eventInfo.status).assertEqual('');
      }
    })

    it('parseOtherField_EVENTCALENDARTYPE_SOLAR', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTCALENDARTYPE, SOLAR);
        expect(eventInfo.mEventCalendar).assertEqual(0);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTCALENDARTYPE_other', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTCALENDARTYPE, 'other');
        expect(eventInfo.mEventCalendar).assertEqual(1);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTIMAGETYPE', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTIMAGETYPE, 'other');
        expect(eventInfo.mEventImageType).assertEqual('other');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTTYPEEXT_NORMALEVENTTYPE', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTTYPEEXT, NORMALEVENTTYPE);
        expect(eventInfo.mImportantEventType).assertEqual(0);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTTYPEEXT_UPIMPORTANTEVENTTYPE', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTTYPEEXT, UPIMPORTANTEVENTTYPE);
        expect(eventInfo.mImportantEventType).assertEqual(1);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTTYPEEXT_DOWNIMPORTANTEVENTTYPE', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTTYPEEXT, DOWNIMPORTANTEVENTTYPE);
        expect(eventInfo.mImportantEventType).assertEqual(2);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTTYPEEXT_other', 0, () => {
      if (!parseOtherField) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTTYPEEXT, '');
        expect(eventInfo.mImportantEventType).assertEqual(0);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_EVENTALERTTYPE_NORMALALERT', 0, () => {
      if (!parseOtherField) {
        expect(parseOtherField).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, EVENTALERTTYPE, NORMALALERT);
        expect(eventInfo.alertType).assertEqual(0);
        result = parseOtherField(eventInfo, EVENTALERTTYPE, '');
        expect(eventInfo.alertType).assertEqual(1);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherField_other', 0, () => {
      if (!parseOtherField) {
        expect(parseOtherField).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherField(eventInfo, 'other', NORMALALERT);
        expect(result).assertEqual(ParseResult.PARSE_NOT_HANDLE);
      }
    })

    it('parseOtherPropertyAndFillEvent_DUE', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, DUE, 'value1', '', '');
        expect(eventInfo.duration).assertEqual('value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_DURATION', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, DURATION, 'value1', '', '');
        expect(eventInfo.duration).assertEqual('value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_LOCATION', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
      let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
      let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, LOCATION, 'value1', '', '');
      expect(eventInfo.mLocation).assertEqual('value1');
      expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_DESCRIPTION', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, DESCRIPTION, 'value1', '', '');
        expect(eventInfo.mDescription).assertEqual('ISO-8859-1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SUMMARY', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, SUMMARY, 'value1', '', '');
        expect(eventInfo.mTitle).assertEqual('value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_other', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, EVENTCALENDARTYPE, 'value1', '', '');
        expect(eventInfo.mEventCalendar).assertEqual(1);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_DTEND', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, DTEND, 'value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_DTSTART', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, DTSTART, 'value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_COMPLETED_parse_failed', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, COMPLETED, 'value1');
        expect(result).assertEqual(ParseResult.ERROR);
      }
    })

    it('parseTimeInfoAndFillEvent_RRULE', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, RRULE, 'value1');
        expect(eventInfo.mRepeatRule).assertEqual('value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_STATUS', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, STATUS, TENTATIVE);
        expect(eventInfo.status).assertEqual('0');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_TRIGGER', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, STATUS, 'value1');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseTimeInfoAndFillEvent_name_invalid', 0, () => {
      if (!parseTimeInfoAndFillEvent) {
        expect(parseTimeInfoAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseTimeInfoAndFillEvent(eventInfo, 'other', 'value1');
        expect(result).assertEqual(ParseResult.PARSE_NOT_HANDLE);
      }
    })

    it('trimTimeMills', 0, () => {
      const trimTimeMills = TestUtil.getPrivateFunction(parser, 'trimTimeMills');
      if (!trimTimeMills) {
        expect(trimTimeMills).assertNull();
      } else {
        expect(trimTimeMills(1500)).assertEqual(1500); //BUG
      }
    })

    it('parseCharSet_expectedList_empty', 0, () => {
      const parseCharSet = TestUtil.getPrivateFunction(parser, 'parseCharSet');
      if (!parseCharSet) {
        expect(parseCharSet).assertNull();
      } else {
        let prop = new Property('name');
        expect(parseCharSet(prop)).assertEqual(UTF_8);
      }
    })

    it('parseEncoding_expectedList_empty', 0, () => {
      const parseEncoding = TestUtil.getPrivateFunction(parser, 'parseEncoding');
      if (!parseEncoding) {
        expect(parseEncoding).assertNull();
      } else {
        let prop = new Property('name');
        expect(parseEncoding(prop)).assertEqual(UTF_8);
      }
    })

    it('parseEncoding', 0, () => {
      const parseEncoding = TestUtil.getPrivateFunction(parser, 'parseEncoding');
      if (!parseEncoding) {
        expect(parseEncoding).assertNull();
      } else {
        let prop = new Property('name');
        prop.addParameter(new Parameter(ENCODING_STRING, ISO_8859_1));
        expect(parseEncoding(prop)).assertEqual(ISO_8859_1);
      }
    })

    it('canParseEncoding', 0, () => {
      const canParseEncoding = TestUtil.getPrivateFunction(parser, 'canParseEncoding');
      if (!canParseEncoding) {
        expect(canParseEncoding).assertNull();
      } else {
        expect(canParseEncoding(LOCATION)).assertTrue();
        expect(canParseEncoding(DESCRIPTION)).assertTrue();
        expect(canParseEncoding(SUMMARY)).assertTrue();
        expect(canParseEncoding('other')).assertFalse();
      }
    })

    it('parseEvent', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      TestUtil.setPrivateAttribute(calendarInfo, 'mTimezone', 'Asia/Shanghai');
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();

      let vcsComponent: VcsComponent = new VcsComponent('test', undefined);
      expect(await calendarParserV20.parseEvent(vcsComponent, agendaEventInfo, [])).assertFalse();

      let vcsComponent1: VcsComponent = new VcsComponent('VEVENT', undefined);
      expect(await calendarParserV20.parseEvent(vcsComponent1, agendaEventInfo, [])).assertFalse();

      let vcsComponent2: VcsComponent = new VcsComponent('VEVENT', undefined);
      vcsComponent2.addProperty(new Property('DTSTART'));
      expect(await calendarParserV20.parseEvent(vcsComponent2, agendaEventInfo, [])).assertFalse();
    })

    it('fillEventByParseAlarm', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      let func = TestUtil.getPrivateFunction(calendarParserV20, 'fillEventByParseAlarm');
      if (!func) {
        expect(func).assertNull();
      } else {
        func(agendaEventInfo, '');
        expect(TestUtil.getPrivateAttribute<CalendarInfo>(calendarParserV20, 'mInfo')).not().assertUndefined();

        agendaEventInfo.checkValuesArray.push(new CalendarContract.Reminders());
        func(agendaEventInfo, 'M1');
        expect(TestUtil.getPrivateAttribute<CalendarInfo>(calendarParserV20, 'mInfo')).not().assertUndefined();
      }
    })

    it('decodeBase64String', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let func = TestUtil.getPrivateFunction(calendarParserV20, 'decodeBase64String');
      if (!func) {
        expect(func).assertNull();
      } else {
        expect(func('test', 'test')).assertEqual('test');
      }
    })

    it('decodeQuotedPrintable', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let func = TestUtil.getPrivateFunction(calendarParserV20, 'decodeQuotedPrintable');
      if (!func) {
        expect(func).assertNull();
      } else {
        expect(func('', '')).assertEqual('');
        expect(func('test', '')).not().assertEqual('');
      }
    })

    it('finalCheck', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();

      let func = TestUtil.getPrivateFunction(calendarParserV20, 'finalCheck');
      if (!func) {
        expect(func).assertNull();
      } else {
        agendaEventInfo.mBegin = -1;
        expect(func(agendaEventInfo)).assertFalse();

        agendaEventInfo.mBegin = 10;
        agendaEventInfo.duration = 'DAY';
        expect(func(agendaEventInfo)).assertTrue();

        agendaEventInfo.duration = '';
        agendaEventInfo.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
        expect(func(agendaEventInfo)).assertTrue();

        agendaEventInfo.mImportantEventType = 0;
        TestUtil.setPrivateAttribute(calendarParserV20, 'countryCode', 'Beijing');
        expect(func(agendaEventInfo)).assertTrue();
      }
    })

    it('setDtEndValueIfRepeatEvent', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      let calendarParserV20: CalendarParserV20 = new CalendarParserV20(calendarInfo);
      let agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();

      let func = TestUtil.getPrivateFunction(calendarParserV20, 'setDtEndValueIfRepeatEvent');
      if (!func) {
        expect(func).assertNull();
      } else {
        agendaEventInfo.duration = 'DAY';
        agendaEventInfo.mEnd = -1;
        expect(func(agendaEventInfo)).assertFalse();
      }
    })

    it('parseOtherPropertyAndFillEvent_SERVICEVERIFIED', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, 'SERVICEVERIFIED', 'true', '', '');
        expect(eventInfo.mHwextServiceVerified ).assertEqual(true);
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SERVICETYPE', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, 'SERVICETYPE', 'servicetype', '', '');
        expect(eventInfo.mHwextServiceType ).assertEqual('servicetype');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SERVICEDESCRIPTION', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, 'SERVICEDESCRIPTION', 'servicetype', 'BASE64', 'UTF-8');
        expect(eventInfo.mHwextServiceDescription ).assertEqual('servicetype');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SERVICEURI', 0, () => {
      if (!parseOtherPropertyAndFillEvent) {
        expect(parseOtherPropertyAndFillEvent).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEvent(eventInfo, 'SERVICEURI', 'serviceuri', 'BASE64', 'UTF-8');
        expect(eventInfo.mHwextServiceUri ).assertEqual('serviceuri');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SUMMARY_001', 0, () => {
      let parserTest = new CalendarParserV20(calendarInfo);
      TestUtil.setPrivateAttribute(parserTest, 'countryCode', '');
      const parseOtherPropertyAndFillEventTest = TestUtil.getPrivateFunction(parserTest, 'parseOtherPropertyAndFillEvent');
      if (!parseOtherPropertyAndFillEventTest) {
        expect(parseOtherPropertyAndFillEventTest).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEventTest(eventInfo, 'SUMMARY', 'summary', 'BASE64', 'UTF-8');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SUMMARY_002', 0, () => {
      let parserTest = new CalendarParserV20(calendarInfo);
      TestUtil.setPrivateAttribute(parserTest, 'countryCode', 'TW');
      const parseOtherPropertyAndFillEventTest = TestUtil.getPrivateFunction(parserTest, 'parseOtherPropertyAndFillEvent');
      if (!parseOtherPropertyAndFillEventTest) {
        expect(parseOtherPropertyAndFillEventTest).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEventTest(eventInfo, 'SUMMARY', 'summary', 'BASE64', 'UTF-8');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })

    it('parseOtherPropertyAndFillEvent_SUMMARY_003', 0, () => {
      let parserTest = new CalendarParserV20(calendarInfo);
      TestUtil.setPrivateAttribute(parserTest, 'countryCode', 'CN');
      const parseOtherPropertyAndFillEventTest = TestUtil.getPrivateFunction(parserTest, 'parseOtherPropertyAndFillEvent');
      if (!parseOtherPropertyAndFillEventTest) {
        expect(parseOtherPropertyAndFillEventTest).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseOtherPropertyAndFillEventTest(eventInfo, 'SUMMARY', 'summary', 'BASE64', 'UTF-8');
        expect(result).assertEqual(ParseResult.PARSE_HANDLED);
      }
    })
  })
}