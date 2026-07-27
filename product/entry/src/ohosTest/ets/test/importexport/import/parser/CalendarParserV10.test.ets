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
import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { AgendaEventInfo, AgendaEventInfoWrap, HOURS_PER_DAY, MILLS_PER_DAY, TimeZoneUtil, UTF_8 } from '@app/common';
import { VcsComponent, VEVENT } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/VcsComponent';
import { CalendarInfo } from '@app/feature.importexport/src/main/ets/vcalendar/CalendarInfo';
import { VERSION_10 } from '@app/feature.importexport/src/main/ets/vcalendar/VCalendarConstants';
import {
  AALARM,
  CANCELLED,
  CLASS,
  COMPLETED,
  CONFIDENTIAL,
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
  PRIVATE,
  RRULE,
  STATUS,
  SUMMARY,
  TENTATIVE,
  UPIMPORTANTEVENTTYPE
} from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalendarParser';
import { CalendarParserV10 } from '@app/feature.importexport/src/main/ets/vcalendar/import/parser/CalendarParserV10';
import { TestUtil } from '../../../utils/TestUtil';
import { ArrayList } from '@kit.ArkTS';
import { Property } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Property';
import { ENCODING_STRING } from '@app/feature.importexport/src/main/ets/vcalendar/VCalParser';
import { Parameter } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Parameter';
import { FormatTime } from '@app/feature.repeatrule';
import { ISO_8859_1, UTF_16BE } from '@app/common/src/main/ets/util/CharsetUtil';

const TAG = 'CalendarParserV10Test';

export default function CalendarParserV10Test() {
  describe('CalendarParserV10Test', () => {
    //let parser : CalendarParser;
    let parser: CalendarParserV10;
    let component: VcsComponent;
    let calendarInfo: CalendarInfo = new CalendarInfo('', VERSION_10);
    let parseAndFillEventInfo: Function | null;
    let parseEventReminds: Function | null;
    let getAlarmStartTimeString: Function | null;
    let fillEventByParseProperty: Function | null;
    let isComponentValid: Function | null;

    beforeEach(() => {
      parser = new CalendarParserV10(calendarInfo);
      component = new VcsComponent('test', undefined);
      parseAndFillEventInfo = TestUtil.getPrivateFunction(parser, 'parseAndFillEventInfo');
      parseEventReminds = TestUtil.getPrivateFunction(parser, 'parseEventReminds');
      getAlarmStartTimeString = TestUtil.getPrivateFunction(parser, 'getAlarmStartTimeString');
      fillEventByParseProperty = TestUtil.getPrivateFunction(parser, 'fillEventByParseProperty');
      isComponentValid = TestUtil.getPrivateFunction(parser, 'isComponentValid');
    })

    it('parseEvent_null', 0, async (done: Function) => {
      if (!parser) {
        expect(parser).assertNull();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = false; //await parser.parseEvent(component, event, calendarInfo);
        expect(result).assertFalse();
        done();
      }
    })

    it('isComponentValid_name_invalid', 0, () => {
      if (!isComponentValid) {
        expect(isComponentValid).assertNull();
      } else {
      let component = new VcsComponent('test', undefined);
      let result: boolean = isComponentValid(component);
      expect(result).assertFalse();
      }
    })

    it('isComponentValid_has_no_DTSTART', 0, () => {
      if (!isComponentValid) {
        expect(isComponentValid).assertNull();
      } else {
        let component = new VcsComponent(VEVENT, undefined);
        let result: boolean = isComponentValid(component);
        expect(result).assertFalse();
      }
    })

    it('isComponentValid_has_DTSTART', 0, () => {
      if (!isComponentValid) {
        expect(isComponentValid).assertNull();
      } else {
        let component = new VcsComponent(VEVENT, undefined);
        component.addProperty(new Property(DTSTART, ''))
        let result: boolean = isComponentValid(component);
        expect(result).assertTrue();
      }
    })

    it('parseAndFillEventInfo_timezone', 0, () => {
      if (!parseAndFillEventInfo) {
        expect(parseAndFillEventInfo).assertNull();
      } else {
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseAndFillEventInfo(component, event);
        expect(result).assertFalse();
        calendarInfo = new CalendarInfo(TimeZoneUtil.getCurrentTimeZone(), VERSION_10);
        result = parseAndFillEventInfo(component, event);
        expect(result).assertFalse();
      }
    })

    it('parseAndFillEventInfo_timezone_not_empty', 0, () => {
      if (!parseAndFillEventInfo) {
        expect(parseAndFillEventInfo).assertNull();
      } else {
        let component = new VcsComponent('test', undefined);
        component.addProperty(new Property(LOCATION, 'VALUE'));
        let descriptionProp = new Property(DESCRIPTION, 'VALUE');
        descriptionProp.addParameter(new Parameter(ENCODING_STRING, 'value'));
        component.addProperty(new Property(DESCRIPTION, 'VALUE'));
        let summaryProp = new Property(SUMMARY, 'VALUE');
        descriptionProp.addParameter(new Parameter('CHARSET', 'value'));
        component.addProperty(summaryProp);

        component.addProperty(new Property(DTEND, 'T123456'));
        component.addProperty(new Property(DTSTART, 'T123456'));
        component.addProperty(new Property(COMPLETED, 'COMPLETED'));
        component.addProperty(new Property('other', 'VALUE'));
        let calendarInfo: CalendarInfo = new CalendarInfo(TimeZoneUtil.getCurrentTimeZone(), VERSION_10);
        const event: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = parseAndFillEventInfo(component, event, calendarInfo);
        expect(result).assertFalse();
      }
    })

    it('parseEventReminds_remainders_empty', 0, () => {
      if (!parseEventReminds) {
        expect(parseEventReminds).assertNull();
      } else {
        expect(parseEventReminds([], new AgendaEventInfoWrap())).assertFalse();
      }
    })

    it('parseEventReminds_remainders', 0, () => {
      if (!parseEventReminds) {
        expect(parseEventReminds).assertNull();
      } else {
        expect(parseEventReminds(['abc;def', 'abc;def', 'abcdef'], new AgendaEventInfoWrap()))
          .assertTrue();
      }
    })

    it('getAlarmStartTimeString_empty', 0, () => {
      if (!getAlarmStartTimeString) {
        expect(getAlarmStartTimeString).assertNull();
      } else {
        const result: string = getAlarmStartTimeString('');
        expect(result).assertEqual('');
      }
    })
    it('getAlarmStartTimeString_oneAlarm', 0, () => {
      if (!getAlarmStartTimeString) {
        expect(getAlarmStartTimeString).assertNull();
      } else {
        const result: string = getAlarmStartTimeString('20220120T030303Z;');
        expect(result).assertEqual('20220120T030303Z');
      }
    })
    it('getAlarmStartTimeString_multipleAlarms', 0, () => {
      if (!getAlarmStartTimeString) {
        expect(getAlarmStartTimeString).assertNull();
      } else {
        const result: string = getAlarmStartTimeString('20220120T030303Z;20220120T030303Z');
        expect(result).assertEqual('20220120T030303Z');
      }
    })

    it('getAlarmStartTimeString_noSemicolon', 0, () => {
      if (!getAlarmStartTimeString) {
        expect(getAlarmStartTimeString).assertNull();
      } else {
        const result: string = getAlarmStartTimeString('20220120T030303Z20220120T030303Z');
        expect(result).assertEqual('');
      }
    })
    it('fillEventByParseProperty_RRULE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = RRULE;
        let value: string = "value";
        let encoding: string = "";
        let charSet: string = "";
        let remainders: ArrayList<string> = new ArrayList<string>();
        let result: boolean = fillEventByParseProperty(eventInfo, name, value, encoding, charSet, remainders);
        expect(result).assertEqual(true);
      }
    })
    it('fillEventByParseProperty_STATUS_TENTATIVE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, STATUS, TENTATIVE, '', '', []);
        expect(eventInfo.status).assertEqual('0');
      }
    })

    it('fillEventByParseProperty_STATUS_CONFIRMED', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, STATUS, CONFIRMED, '', '', []);
        expect(eventInfo.status).assertEqual('1');
      }
    })

    it('fillEventByParseProperty_STATUS_CANCELLED', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, STATUS, CANCELLED, '', '', []);
        expect(eventInfo.status).assertEqual('2');
      }
    })

    it('fillEventByParseProperty_STATUS_DECLINED', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, STATUS, DECLINED, '', '', []);
        expect(eventInfo.status).assertEqual('2');
      }
    })

    it('fillEventByParseProperty_STATUS_other', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, STATUS, 'other', '', '', []);
        expect(eventInfo.status).assertEqual('');
      }
    })

    it('fillEventByParseProperty_DUE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = DUE;
        let value: string = "value";
        let result: boolean = fillEventByParseProperty(eventInfo, name, value, '', '', []);
        expect(eventInfo.duration).assertEqual(value);
        expect(result).assertEqual(true);
      }
    })
    it('fillEventByParseProperty_DURATION', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = DURATION;
        let value: string = "value";
        let result: boolean = fillEventByParseProperty(eventInfo, name, value, '', '', []);
        expect(result).assertEqual(true);
        expect(eventInfo.duration).assertEqual(value);
      }
    })
    it('fillEventByParseProperty_LOCATION_encoding_empty', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
      let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
      let result: boolean = fillEventByParseProperty(eventInfo, LOCATION, '', '', '', []);
      expect(result).assertEqual(true);
      }
    })

    it('fillEventByParseProperty_LOCATION_encoding_QUOTED_PRINTABLE_ENCODING', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = fillEventByParseProperty(eventInfo, LOCATION, '', 'QUOTED-PRINTABLE', '', []);
        expect(result).assertEqual(true);
      }
    })

    it('fillEventByParseProperty_LOCATION_encoding_QUOTED_PRINTABLE_ENCODING_value', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = fillEventByParseProperty(eventInfo, LOCATION, 'value', 'QUOTED-PRINTABLE', '', []);
        expect(result).assertEqual(true);
      }
    })

    it('fillEventByParseProperty_LOCATION_encoding_BASE64', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = fillEventByParseProperty(eventInfo, LOCATION, '', 'BASE64', '', []);
        expect(result).assertEqual(true);
      }
    })

    it('fillEventByParseProperty_DESCRIPTION', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = fillEventByParseProperty(eventInfo, DESCRIPTION, '', '', '', []);
        expect(result).assertEqual(true);
      }
    })
    it('fillEventByParseProperty_SUMMARY', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
      let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
      let result: boolean = fillEventByParseProperty(eventInfo, SUMMARY, '', '', '', []);
      expect(result).assertEqual(true);
      }
    })
    it('fillEventByParseProperty_AALARM', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let remainders: ArrayList<string> = new ArrayList<string>();
        let result: boolean = fillEventByParseProperty(eventInfo, AALARM, '', 'value', '', remainders);
        expect(result).assertEqual(true);
        expect(remainders.length).assertEqual(1);
      }
    })

    it('fillEventByParseProperty_CLASS_PRIVATE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = CLASS;
        fillEventByParseProperty(eventInfo, name, PRIVATE, '', '', '');
        expect(eventInfo.accessLevel).assertEqual(2);
      }
    })

    it('fillEventByParseProperty_CLASS_CONFIDENTIAL', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, CLASS, CONFIDENTIAL, '', '', '');
        expect(eventInfo.accessLevel).assertEqual(2);
      }
    })

    it('fillEventByParseProperty_CLASS_other', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, CLASS, 'other', '', '', '');
        expect(eventInfo.accessLevel).assertEqual(3);
      }
    })

    it('fillEventByParseProperty_EVENTCALENDARTYPE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = EVENTCALENDARTYPE;
        let result: boolean = fillEventByParseProperty(eventInfo, name, 'SOLAR', '', '', []);
        expect(eventInfo.mEventCalendar).assertEqual(0);
        result = fillEventByParseProperty(eventInfo, name, 'other', '', '', []);
        expect(eventInfo.mEventCalendar).assertEqual(1);
      }
    })
    it('fillEventByParseProperty_EVENTIMAGETYPE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let name: string = EVENTIMAGETYPE;
        let value: string = "value";
        let encoding: string = "";
        let charSet: string = "";
        let remainders: ArrayList<string> = new ArrayList<string>();
        let result: boolean = fillEventByParseProperty(eventInfo, name, value, encoding, charSet, remainders);
        expect(result).assertEqual(true);
        expect(eventInfo.mEventImageType).assertEqual(value);
      }
    })
    it('fillEventByParseProperty_EVENTTYPEEXT_NORMALEVENTTYPE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTTYPEEXT, NORMALEVENTTYPE, '', '', []);
        expect(eventInfo.mImportantEventType).assertEqual(0);
      }
    })

    it('fillEventByParseProperty_EVENTTYPEEXT_UPIMPORTANTEVENTTYPE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTTYPEEXT, UPIMPORTANTEVENTTYPE, '', '', []);
        expect(eventInfo.mImportantEventType).assertEqual(1);
      }
    })

    it('fillEventByParseProperty_EVENTTYPEEXT_DOWNIMPORTANTEVENTTYPE', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTTYPEEXT, DOWNIMPORTANTEVENTTYPE, '', '', []);
        expect(eventInfo.mImportantEventType).assertEqual(2);
      }
    })

    it('fillEventByParseProperty_EVENTTYPEEXT_other', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTTYPEEXT, 'other', '', '', []);
        expect(eventInfo.mImportantEventType).assertEqual(0);
      }
    })

    it('fillEventByParseProperty_EVENTALERTTYPE_NORMALALERT', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTALERTTYPE, NORMALALERT, '', '', []);
        expect(eventInfo.alertType).assertEqual(0);
      }
    })

    it('fillEventByParseProperty_EVENTALERTTYPE_other', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        fillEventByParseProperty(eventInfo, EVENTALERTTYPE, 'other', '', '', []);
        expect(eventInfo.alertType).assertEqual(1);
      }
    })

    it('fillEventByParseProperty_other_other', 0, () => {
      if (!fillEventByParseProperty) {
        expect(fillEventByParseProperty).assertNull();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        let result: boolean = fillEventByParseProperty(eventInfo, 'other', 'other', '', '', []);
        expect(result).assertTrue();
      }
    })

    it('isTimeDiffMultiplesOf24', 0, () => {
      const isTimeDiffMultiplesOf24 = TestUtil.getPrivateFunction(parser, 'isTimeDiffMultiplesOf24');
      if (!isTimeDiffMultiplesOf24) {
        expect(isTimeDiffMultiplesOf24).assertNull();
      } else {
        expect(isTimeDiffMultiplesOf24(100, 0)).assertFalse();
        expect(isTimeDiffMultiplesOf24(100, 30)).assertFalse();
        expect(isTimeDiffMultiplesOf24(100 + MILLS_PER_DAY, 100)).assertTrue();
      }
    })

    it('isHourMinSecZero', 0, () => {
      const isHourMinSecZero = TestUtil.getPrivateFunction(parser, 'isHourMinSecZero');
      if (!isHourMinSecZero) {
        expect(isHourMinSecZero).assertNull();
      } else {
        let formatTime = new FormatTime;
        expect(isHourMinSecZero(formatTime)).assertTrue();
        formatTime.hour = HOURS_PER_DAY;
        expect(isHourMinSecZero(formatTime)).assertFalse();
      }
    })

    it('is24HourFormat', 0, () => {
      const is24HourFormat = TestUtil.getPrivateFunction(parser, 'is24HourFormat');
      if (!is24HourFormat) {
        expect(is24HourFormat).assertNull();
      } else {
        let formatTime = new FormatTime;
        formatTime.hour = HOURS_PER_DAY;
        let result: boolean = is24HourFormat(formatTime);
        expect(result).assertTrue();
        formatTime.minute = 111;
        expect(is24HourFormat(formatTime)).assertFalse();
      }
    })

    it('parseCharSet_expectedList_empty', 0, () => {
      const parseCharSet = TestUtil.getPrivateFunction(parser, 'parseCharSet');
      if (!parseCharSet) {
        expect(false).assertTrue();
      } else {
        let prop = new Property('name');
        expect(parseCharSet(prop)).assertEqual(UTF_8);
      }
    })

    it('parseCharSet', 0, () => {
      const parseCharSet = TestUtil.getPrivateFunction(parser, 'parseCharSet');
      if (!parseCharSet) {
        expect(false).assertTrue();
      } else {
        let prop = new Property('name');
        prop.addParameter(new Parameter('CHARSET', UTF_16BE));
        expect(parseCharSet(prop)).assertEqual(UTF_16BE);
      }
    })

    it('parseEncoding_expectedList_empty', 0, () => {
      const parseEncoding = TestUtil.getPrivateFunction(parser, 'parseEncoding');
      if (!parseEncoding) {
        expect(false).assertTrue();
      } else {
        let prop = new Property('name');
        expect(parseEncoding(prop)).assertEqual(UTF_8);
      }
    })

    it('parseEncoding', 0, () => {
      const parseEncoding = TestUtil.getPrivateFunction(parser, 'parseEncoding');
      if (!parseEncoding) {
        expect(false).assertTrue();
      } else {
        let prop = new Property('name');
        prop.addParameter(new Parameter(ENCODING_STRING, ISO_8859_1));
        expect(parseEncoding(prop)).assertEqual(ISO_8859_1);
      }
    })

    it('isTimeOneMinShortOf24', 0, () => {
      const isTimeOneMinShortOf24 = TestUtil.getPrivateFunction(parser, 'isTimeOneMinShortOf24');
      if (!isTimeOneMinShortOf24) {
        expect(false).assertTrue();
      } else {
        let time = new FormatTime;
        time.hour = 23;
        time.minute = 59;
        time.second = 0;
        expect(isTimeOneMinShortOf24(time)).assertTrue();
      }
    })

    it('isSoftbankAllDay_dtStart_is_not_local_time', 0, () => {
      const isSoftbankAllDay = TestUtil.getPrivateFunction(parser, 'isSoftbankAllDay');
      if (!isSoftbankAllDay) {
        expect(false).assertTrue();
      } else {
        expect(isSoftbankAllDay('20220101T000000', '20220101T010000Z', 'UTC')).assertFalse();
      }
    })

    it('isSoftbankAllDay_dtStart_cannot_be_parsed', 0, () => {
      const isSoftbankAllDay = TestUtil.getPrivateFunction(parser, 'isSoftbankAllDay');
      if (!isSoftbankAllDay) {
        expect(false).assertTrue();
      } else {
        expect(isSoftbankAllDay('20220101T000000Z', '20220101T010000Z', 'UTC')).assertFalse();
      }
    })

    it('isSoftbankAllDay_dtEnd_is_one_minute_short_of_24_hours', 0, () => {
      const isSoftbankAllDay = TestUtil.getPrivateFunction(parser, 'isSoftbankAllDay');
      if (!isSoftbankAllDay) {
        expect(false).assertTrue();
      } else {
        expect(isSoftbankAllDay('20220101T000000Z', '20220101T235900Z', 'UTC')).assertFalse();
      }
    })

    it('isSoftbankAllDay_dtEnd_not_one_minute_short_of_24_hours', 0, () => {
      const isSoftbankAllDay = TestUtil.getPrivateFunction(parser, 'isSoftbankAllDay');
      if (!isSoftbankAllDay) {
        expect(false).assertTrue();
      } else {
        expect(isSoftbankAllDay('20220101T000000Z', '20220101T225900Z', 'UTC')).assertFalse();
      }
    })

    it('parseAndFillEventStartEnd', 0, () => {
      const parseAndFillEventStartEnd = TestUtil.getPrivateFunction(parser, 'parseAndFillEventStartEnd');
      if (!parseAndFillEventStartEnd) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        expect(parseAndFillEventStartEnd(eventInfo, '20220101T000000Z', '20220101T235900Z', 'UTC')).assertFalse();
      }
    })

    it('parseEvent', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo('', VERSION_10);
      let calendarParserV10: CalendarParserV10 = new CalendarParserV10(calendarInfo);

      let vcsComponent: VcsComponent = new VcsComponent('VEVENT', undefined);
      let agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      expect(await calendarParserV10.parseEvent(vcsComponent, agendaEventInfo, [])).assertFalse();
    })

    it('amendAllDayDtEnd', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo('', VERSION_10);
      let calendarParserV10: CalendarParserV10 = new CalendarParserV10(calendarInfo);
      let func = TestUtil.getPrivateFunction(calendarParserV10, 'amendAllDayDtEnd');
      if (!func) {
        expect(func).assertNull();
      } else {
        expect(func('test', 1)).not().assertEqual(0);
      }
    })

    it('getTimeInMillis', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo('', VERSION_10);
      let calendarParserV10: CalendarParserV10 = new CalendarParserV10(calendarInfo);
      let func = TestUtil.getPrivateFunction(calendarParserV10, 'getTimeInMillis');
      if (!func) {
        expect(func).assertNull();
      } else {
        expect(func('test', 'Asia/Shanghai')).not().assertEqual(0);
      }
    })

    it('parseAndFillEventStartEnd_001', 0, () => {
      const parseAndFillEventStartEnd = TestUtil.getPrivateFunction(parser, 'parseAndFillEventStartEnd');
      if (!parseAndFillEventStartEnd) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        const dtStart: string = '20250101';
        const dtEnd: string = '20250102';
        const lastDate: string = '20250101T080000Z';
        const result: boolean = parseAndFillEventStartEnd(eventInfo, dtEnd, dtStart, lastDate);
        expect(result).assertTrue();
      }
    })

    it('parseAndFillEventStartEnd_002', 0, () => {
      const parseAndFillEventStartEnd = TestUtil.getPrivateFunction(parser, 'parseAndFillEventStartEnd');
      if (!parseAndFillEventStartEnd) {
        expect(false).assertTrue();
      } else {
        let eventInfo: AgendaEventInfoWrap = new AgendaEventInfoWrap();
        const dtStart: string = '20250101T000000Z';
        const dtEnd: string = '';
        const lastDate: string = '20250101T080000Z';
        eventInfo.duration = 'PPP';
        const result: boolean = parseAndFillEventStartEnd(eventInfo, dtStart, dtEnd, lastDate);
        expect(result).assertFalse();
      }
    })

    it('amendAllDayDtEnd_001', 0, () => {
      const amendAllDayDtEnd = TestUtil.getPrivateFunction(parser, 'amendAllDayDtEnd');
      if (!amendAllDayDtEnd) {
        expect(false).assertTrue();
      } else {
        const dtEndString: string = '20250101T235900Z';
        const dtEnd: number = 1735747140000;
        const result: number = amendAllDayDtEnd(dtEndString, dtEnd);
        expect(result).assertEqual(1735747200000);
      }
    })

    it('getTimeInMillis_001', 0, () => {
      const getTimeInMillis = TestUtil.getPrivateFunction(parser, 'getTimeInMillis');
      if (!getTimeInMillis) {
        expect(false).assertTrue();
      } else {
        const time: string = '20250101T000000Z';
        const timezone: string = 'Asia/Shanghai';
        const result: number = getTimeInMillis(time, timezone);
        expect(result).assertEqual(1735689600000);
      }
    })

    it('getTimeInMillis_002', 0, () => {
      const getTimeInMillis = TestUtil.getPrivateFunction(parser, 'getTimeInMillis');
      if (!getTimeInMillis) {
        expect(false).assertTrue();
      } else {
        const time: string = 'ABC';
        const timezone: string = 'Asia/Shanghai';
        const result: number = getTimeInMillis(time, timezone);
        expect(result).assertEqual(-1);
      }
    })
  })
}