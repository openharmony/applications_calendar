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

import { buildUDC,
  parseDataFromPasteString,
  parseEventInfo2String } from '@app/common/src/main/ets/default/util/ShareUtils';
import { AgendaEventInfo, CalendarDate } from '@app/common/index';
import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
import data from '@ohos.telephony.data';

const TAG: string = `ShareUtilsTest`;
const startTimeStamp: number = Date.now();
const date: Date = new Date(startTimeStamp);
const year: number = date.getFullYear();
const month: number = date.getMonth();
const day: number = date.getDay();


function ShareUtils_parseEventInfo2String_Normal_Agenda_1() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：\n：1970-01-01 08:00\n：1970-01-01 08:00`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_Normal_Agenda_2() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：1970-01-01 08:00\n：1970-01-01 08:00`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_Normal_Agenda_3() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mBegin = new CalendarDate("2024-04-10 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-10 08:00\n：1970-01-01 08:00`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_Normal_Agenda_4() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mBegin = new CalendarDate("2024-04-10 08:00").getTime();
  eventInfo.mEnd = new CalendarDate("2024-04-11 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-10 08:00\n：2024-04-11 08:00`;


  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_Normal_Agenda_5() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：1970-01-01 08:00\n：2024-04-10 08:00`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_Normal_Agenda_6() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
  eventInfo.mBegin = new CalendarDate("2024-04-11 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-11 08:00\n：2024-04-10 08:00`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_1() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mIsAllDay = true;
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：\n：1970-01-01`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_2() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：1970-01-01`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_3() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  eventInfo.mBegin = new CalendarDate("2024-04-10 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-10`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_4() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  eventInfo.mBegin = new CalendarDate("2024-04-10 08:00").getTime();
  eventInfo.mEnd = new CalendarDate("2024-04-11 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-10`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_5() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：1970-01-01`;

  expect(resStr).not().assertNull();
}

function ShareUtils_parseEventInfo2String_All_Day_Agenda_6() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
  eventInfo.mBegin = new CalendarDate("2024-04-11 08:00").getTime();
  const resStr: string = parseEventInfo2String(eventInfo);
  const str: string = `：这是个测试标题\n：2024-04-11`;

  expect(resStr).not().assertNull();
}

function ShareUtils_buildUDC_Error() {
  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = "这是个测试标题";
  eventInfo.mIsAllDay = true;
  eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
  eventInfo.mBegin = new CalendarDate("2024-04-11 08:00").getTime();
  const mock: DragEvent = {} as DragEvent;

  let mocker = new MockKit();
  let mockFuncGetString: Function = mocker.mockFunc(mock, mock.setData);
  when(mockFuncGetString)(ArgumentMatchers.any).afterThrow("这是个手工错误");
  expect(buildUDC(mock, eventInfo)).assertEqual(false);
}

async function ShareUtils_parseDataFromPasteString_Relative_Time() {
  const oriText: string = '明天晚上九点约老王去吃饭'
  const mEventInfo: AgendaEventInfo = await parseDataFromPasteString(oriText, startTimeStamp);
  let dateTime = Date.now();
  let calendarDate = new CalendarDate(dateTime);
  const startTime = Date.UTC(calendarDate.getFullYear(), calendarDate.getMonth() , calendarDate.getDate() + 1, 13);
  expect(mEventInfo.mBegin).assertEqual(startTime);
}

async function ShareUtils_parseDataFromPasteString_Absolute_Time() {
  const oriText: string = '2025年5月20日晚上九点约老王去吃饭'
  const mEventInfo: AgendaEventInfo = await parseDataFromPasteString(oriText, startTimeStamp);
  const startTime: number = Date.UTC(2025, 4, 20, 13);
  expect(mEventInfo.mBegin).assertEqual(startTime);
}

async function ShareUtils_parseDataFromPasteString_No_Time() {
  const oriText: string = '约老王去吃饭'
  const mEventInfo: AgendaEventInfo = await parseDataFromPasteString(oriText, startTimeStamp);

  expect(mEventInfo.mBegin).assertEqual(startTimeStamp);
}


export default function ShareUtilsTest() {
  describe('ShareUtils', () => {
    it('ShareUtils_parseEventInfo2String_Normal_Agenda_1', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_1();
    })

    it('ShareUtils_parseEventInfo2String_Normal_Agenda_2', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_2();
    })

    it('ShareUtils_parseEventInfo2String_Normal_Agenda_3', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_3();
    })

    it('ShareUtils_parseEventInfo2String_Normal_Agenda_4', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_4();
    })

    it('ShareUtils_parseEventInfo2String_Normal_Agenda_5', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_5();
    })

    it('ShareUtils_parseEventInfo2String_Normal_Agenda_6', 0, () => {
      ShareUtils_parseEventInfo2String_Normal_Agenda_6();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_1', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_1();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_2', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_2();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_3', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_3();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_4', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_4();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_5', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_5();
    })

    it('ShareUtils_parseEventInfo2String_All_Day_Agenda_6', 0, () => {
      ShareUtils_parseEventInfo2String_All_Day_Agenda_6();
    })

    it('ShareUtils_parseDataFromPasteString_Relative_Time', 0, async (done: Function) => {
      await ShareUtils_parseDataFromPasteString_Relative_Time();
      done();
    })

    it('ShareUtils_parseDataFromPasteString_Absolute_Time', 0, async (done: Function) => {
      await ShareUtils_parseDataFromPasteString_Absolute_Time();
      done();
    })

    it('ShareUtils_parseDataFromPasteString_No_Time', 0, async (done: Function) => {
      await ShareUtils_parseDataFromPasteString_No_Time();
      done();
    })

    it('ShareUtils_buildUDC', 0, () => {
      const eventInfo: AgendaEventInfo = new AgendaEventInfo();
      eventInfo.mTitle = "这是个测试标题";
      eventInfo.mIsAllDay = true;
      eventInfo.mEnd = new CalendarDate("2024-04-10 08:00").getTime();
      eventInfo.mBegin = new CalendarDate("2024-04-11 08:00").getTime();
      const mockDragEvent: DragEvent = {} as DragEvent;

      let mocker = new MockKit();
      let setData: Function = mocker.mockFunc(mockDragEvent, mockDragEvent.setData);
      when(setData)(ArgumentMatchers.any).afterReturn(undefined);
      expect(buildUDC(mockDragEvent, eventInfo)).assertEqual(false);
    })

    it('ShareUtils_buildUDC_Error', 0, () => {
      ShareUtils_buildUDC_Error();
    })
  })
}