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

import {
  AgendaEventInfo,
  AgendaService,
  CalendarContract,
  CalendarDate,
  getAdaptImportantTime,
  GlobalData,
  GlobalDataKeys,
  ServiceEnum
} from '@app/common';
import { AgendaServiceImpl, AgendaOffsetTitle } from '@app/feature.agenda/src/main/ets/service/AgendaServiceImpl';
import { Recurrence } from '@app/feature.repeatrule';

import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';

export default function AgendaServiceImplTest() {
  describe('AgendaServiceImplTest', (done: Function) => {
    let agenda: AgendaEventInfo;
    let agendaService: AgendaService;
    const displayDate: number = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;

    beforeEach(() => {
      agenda = new AgendaEventInfo();
      agendaService = new AgendaServiceImpl(ServiceEnum.AGENDA_SERVICE);
    })

    // 测试非年度重复日程的情况
    it('updateRepeatAgendaTitle_test01', 0, async (done: Function) => {
      const date = Date.now();
      expect(agendaService.updateRepeatAgendaTitle(agenda, date)).assertEqual('');
      done();
    });

    // 测试当前日期小于开始日期的情况
    it('updateRepeatAgendaTitle_test02', 0, async (done: Function) => {
      const recurrence: Recurrence = new Recurrence();
      recurrence.setToYearly(0, 1);
      agenda.mRepeatRule = recurrence.format();
      agenda.mTitle = 'test02';
      agenda.mOriginalBegin = new CalendarDate('2023-01-01').getTime();
      agenda.mBegin = new CalendarDate('2023-01-01').getTime();
      const date = new CalendarDate('2022-01-01').getTime();
      expect(agendaService.updateRepeatAgendaTitle(agenda, date)).assertEqual('test02');
      done();
    });

    // 测试周年数为0的情况
    it('updateRepeatAgendaTitle_test03', 0, async (done: Function) => {
      const recurrence: Recurrence = new Recurrence();
      recurrence.setToYearly(0, 1);
      agenda.mRepeatRule = recurrence.format();
      agenda.mTitle = 'test03';
      agenda.mOriginalBegin = new CalendarDate('2023-01-01').getUTCMilliseconds();
      agenda.mBegin = new CalendarDate('2023-01-01').getUTCMilliseconds();
      const date = new CalendarDate('2023-01-01').getUTCMilliseconds();
      expect(agendaService.updateRepeatAgendaTitle(agenda, date)).assertEqual('test03');
      done();
    });

    // 测试非年度重复日程有标题的情况下
    it('updateRepeatAgendaTitle_test04', 0, async (done: Function) => {
      const date = Date.now();
      agenda.mTitle = '哈哈哈哈哈';
      expect(agendaService.updateRepeatAgendaTitle(agenda, date)).assertEqual('哈哈哈哈哈');
      done();
    });

    // should_return_anniversary_title_when_frequency_is_yearly_and_current_date_is_after_start_date
    it('updateRepeatAgendaTitle_test05', 0, async (done: Function) => {
      agenda.mRepeatRule = "FREQ=YEARLY";
      agenda.mTitle = "My Birthday";
      const now = new Date().getTime();
      agenda.mOriginalBegin = now - 365 * 24 * 60 * 60 * 1000; // Start date is one year ago
      agenda.mBegin = now; // Start date is one year ago
      const result: ESObject = agendaService.updateRepeatAgendaTitle(agenda, agenda.mBegin);
      expect(result).assertContain("My Birthday · 1 周年");
      done();
    });

    // should_handle_lunar_events_correctly
    it('updateRepeatAgendaTitle_test06', 0, async (done: Function) => {
      agenda.mRepeatRule = "FREQ=YEARLY";
      agenda.mTitle = "My Birthday";
      const now = new Date().getTime();
      agenda.mOriginalBegin = now - 365 * 24 * 60 * 60 * 1000; // Start date is year ago
      agenda.mBegin = now; // Start date is year ago
      agenda.mEventCalendar = CalendarContract.AgendaCalendarType.LUNAR;
      const result: ESObject = agendaService.updateRepeatAgendaTitle(agenda, agenda.mBegin);
      expect(result).assertContain("My Birthday · 1 周年");
      done();
    });

    // should_return_the_same_title_when_importantEventType_is_not_ANNIVERSARIES_or_COUNTDOWN_or_title_is_empty
    it('agendaTitleDayOffset_test01', 0, async (done: Function) => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      agenda.mTitle = "My Event";
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, agenda.mBegin, displayDate);
      expect(result).assertEqual("My Event");
      done();
    });

    // should_return_formatted_title_when_importantEventType_is_ANNIVERSARIES_and_title_is_not_empty
    it('agendaTitleDayOffset_test02', 0, async (done: Function) => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      agenda.mTitle = "My Event";
      agenda.mBegin = new Date().getTime();
      let mocker: MockKit = new MockKit();
      let globalDataMock: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(globalDataMock)(GlobalDataKeys.DISPLAY_DATE).afterReturn(new Date().getTime());
      when(globalDataMock)(GlobalDataKeys.LANGUAGE).afterReturn("en");
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, agenda.mBegin, displayDate);
      expect(result).assertContain("My Event");
      expect(result).assertContain("1 天");
      done();
    });

    // should_return_formatted_title_when_importantEventType_is_COUNTDOWN_and_title_is_not_empty
    it('agendaTitleDayOffset_test03', 0, async (done: Function) => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda.mTitle = "My Event";
      agenda.mBegin = new Date().getTime();
      const recurrence: Recurrence = new Recurrence();
      recurrence.setToDaily();
      agenda.mRepeatRule = recurrence.format();
      let mocker: MockKit = new MockKit();
      let globalDataMock: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(globalDataMock)(GlobalDataKeys.DISPLAY_DATE).afterReturn(new Date().getTime());
      when(globalDataMock)(GlobalDataKeys.LANGUAGE).afterReturn("en");
      let getAdaptImportantTimeMock: Function = mocker.mockFunc({}, getAdaptImportantTime);
      when(getAdaptImportantTimeMock)(ArgumentMatchers.any).afterReturn(new Date().getTime() + 86400000);
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, agenda.mBegin, displayDate);
      expect(result).assertContain("My Event");
      done();
    });

    // should_return_formatted_title_when_importantEventType_is_ANNIVERSARIES_and_title_is_not_empty
    it('agendaTitleDayOffset_test04', 0, async (done: Function) => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      agenda.mTitle = "My Event";
      agenda.mBegin = new Date().getTime();
      let mocker: MockKit = new MockKit();
      let globalDataMock: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      let tomorrow = new Date().getTime() + 86400000;
      when(globalDataMock)(GlobalDataKeys.DISPLAY_DATE).afterReturn(tomorrow);
      when(globalDataMock)(GlobalDataKeys.LANGUAGE).afterReturn("en");
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, agenda.mBegin, tomorrow);
      expect(result).assertContain("My Event");
      expect(result).assertContain("2 天");
      done();
    });

    // 非重复倒数日，且倒数日开始时间小于参考时间，直接返回倒数日标题
    it('agendaTitleDayOffset_test05', 0, async (done: Function) => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda.mTitle = "My Event";
      agenda.mBegin = new Date().getTime() - 365 * 24 * 60 * 60 * 1000; // Start date is year ago
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, agenda.mBegin, new Date().getTime());
      expect(result).assertEqual("My Event");
      done();
    });

    // 每年11.30重复的倒数日
    it('agendaTitleDayOffset_test06', 0, () => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      agenda.mTitle = "My Event";
      agenda.mBegin = new CalendarDate('2024-11-30T00:00:00.000Z').getTime();
      agenda.mOriginalBegin = agenda.mBegin;
      const recurrence: Recurrence = new Recurrence();
      recurrence.setToYearly(10, 30);
      agenda.mRepeatRule = recurrence.format();
      const referenceDate = new CalendarDate('2024-12-30T00:00:00.000Z').getTime();
      const instancesStartMills = new CalendarDate('2025-11-30T00:00:00.000Z').getTime(); // 事件尚未发生
      const result: ESObject = agendaService.agendaTitleDayOffset(agenda, instancesStartMills, referenceDate);
      expect(result).assertEqual("My Event · 1 周年 · 335 天后"); // 确保标题中包含天数差
    });


    it('updateNormalAgendaTitle_test01', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = new Date(2024,2,17).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2024,2,16).setHours(8,0,0,0));
      expect(result.title).assertEqual('test');
      expect(result.isFullYear).assertEqual(false);
    });

    it('updateNormalAgendaTitle_test02', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = new Date(2024,2,17).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2024,2,25).setHours(8,0,0,0));
      expect(result.title).assertEqual('test');
      expect(result.isFullYear).assertEqual(false);
    });

    it('updateNormalAgendaTitle_test03', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = new Date(2024,2,17).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2025,2,17).setHours(8,0,0,0));
      expect(result.title).assertEqual('test · 1 周年');
      expect(result.isFullYear).assertEqual(true);
    });

    it('updateNormalAgendaTitle_test04', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = new Date(2024,2,17).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2025,2,18).setHours(8,0,0,0));
      expect(result.title).assertEqual('test');
      expect(result.isFullYear).assertEqual(false);
    });

    it('updateNormalAgendaTitle_test05', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test生日';
      const agendaDate = new Date(2024,2,17).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2025,2,17).setHours(8,0,0,0));
      expect(result.title).assertEqual('test生日 · 1 周岁');
      expect(result.isFullYear).assertEqual(true);
    });

    it('updateNormalAgendaTitle_test06', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = 1711584000000; // 农历二月十九
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      agendaInfo.mEventCalendar = CalendarContract.AgendaCalendarType.LUNAR;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, 1742256000000);
      expect(result.title).assertEqual('test · 1 周年');
      expect(result.isFullYear).assertEqual(true);
    });

    it('updateNormalAgendaTitle_test07', 0, async () => {
      const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaInfo.mTitle = 'test';
      const agendaDate = new Date(2024,2,11).setHours(8,0,0,0);
      agendaInfo.mOriginalBegin = agendaDate;
      agendaInfo.mBegin = agendaDate;
      agendaInfo.mEventCalendar = CalendarContract.AgendaCalendarType.LUNAR;
      const result: AgendaOffsetTitle = agendaService.updateNormalAgendaTitle(agendaInfo, new Date(2025,2,2).setHours(8,0,0,0));
      expect(result.title).assertEqual('test');
      expect(result.isFullYear).assertEqual(false);
    });

  })

}