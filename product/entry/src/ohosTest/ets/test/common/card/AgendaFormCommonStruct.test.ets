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
import { AgendaCardInfo } from "@app/common/src/main/ets/card/AgendaFormCommonStruct";
import { describe, expect, it } from "@ohos/hypium";
import { FormUtils } from "@app/common/src/main/ets/card/AgendaFormCommonStruct";
import { CalendarDate } from "@app/common";

export default function AgendaFormCommonStructTest() {
  describe('agendaListSort', () => {
    // 测试数据
    let agendaInfo1 = new AgendaCardInfo();
    agendaInfo1.mIsAllDay = true;
    agendaInfo1.mTitle = 'A';
    agendaInfo1.mBegin = 1742310000000; // 2025-03-18 08:00
    agendaInfo1.mEnd = 1742396400000; // 2025-03-19 08:00

    let agendaInfo2 = new AgendaCardInfo();
    agendaInfo2.mIsAllDay = true;
    agendaInfo2.mTitle = 'B';
    agendaInfo2.mBegin = 1742310000000; // 2025-03-18 08:00
    agendaInfo2.mEnd = 1742396400000; // 2025-03-19 08:00

    let agendaInfo3 = new AgendaCardInfo();
    agendaInfo3.mIsAllDay = false;
    agendaInfo3.mTitle = 'aaa';
    agendaInfo3.mBegin = 1742308200000; // 2025-03-18 07:30
    agendaInfo3.mEnd = 1742311800000; // 2025-03-18 08:30

    let agendaInfo4 = new AgendaCardInfo();
    agendaInfo4.mIsAllDay = false;
    agendaInfo4.mTitle = 'bbb';
    agendaInfo4.mBegin = 1742308200000; // 2025-03-18 07:30
    agendaInfo4.mEnd = 1742310000000; // 2025-03-18 08:00

    let agendaInfo5 = new AgendaCardInfo();
    agendaInfo5.mIsAllDay = false;
    agendaInfo5.mTitle = 'bbb';
    agendaInfo5.mBegin = 1742344200000; // 2025-03-18 17:30
    agendaInfo5.mEnd = 1742347800000; // 2025-03-18 18:30

    let agendaInfo6 = new AgendaCardInfo();
    agendaInfo6.mIsAllDay = false;
    agendaInfo6.mTitle = 'xyz';
    agendaInfo6.mBegin = 1742344200000; // 2025-03-18 17:30
    agendaInfo6.mEnd = 1742347800000; // 2025-03-18 18:30

    // 1: 全天日程按标题排序
    it('allDay_agenda_sorted_by_title', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo1, agendaInfo2], true);
      expect(result[0]).assertDeepEquals(agendaInfo1);
      expect(result[1]).assertDeepEquals(agendaInfo2);
    });
    // 2: 全天日程在前 测试一个全天日程和一个普通日程，allDayOnTop为true
    it('allDay_agenda_ahead', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo1, agendaInfo3], true);
      expect(result[0]).assertDeepEquals(agendaInfo1);
      expect(result[1]).assertDeepEquals(agendaInfo3);
    });
    // 3: 普通日程在前 测试一个全天日程和一个普通日程，allDayOnTop为false
    it('general_agenda_ahead', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo1, agendaInfo3], false);
      expect(result[0]).assertDeepEquals(agendaInfo3);
      expect(result[1]).assertDeepEquals(agendaInfo1);
    });
    // 4: 按开始时间排序 测试两个普通日程按开始时间排序。
    it('general_agenda_sorted_by_startTime', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo3, agendaInfo5], false);
      expect(result[0]).assertDeepEquals(agendaInfo3);
      expect(result[1]).assertDeepEquals(agendaInfo5);
    });
    // 5: 按结束时间排序 测试两个普通日程开始时间相同，按结束时间排序。
    it('general_agenda_sorted_by_endTime', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo3, agendaInfo4], false);
      expect(result[0]).assertDeepEquals(agendaInfo4);
      expect(result[1]).assertDeepEquals(agendaInfo3);
    });
    // 6: 按标题排序 测试两个普通日程开始和结束时间相同，按标题排序。
    it('general_agenda_sorted_by_title', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo5, agendaInfo6], false);
      expect(result[0]).assertDeepEquals(agendaInfo5);
      expect(result[1]).assertDeepEquals(agendaInfo6);
    });
    // 7: 混合排序 测试包含全天和普通日程的混合排序。全天日程置顶
    it('mix_sorted', 0, () => {
      const result = FormUtils.agendaListSort([agendaInfo1, agendaInfo2, agendaInfo3, agendaInfo4, agendaInfo5, agendaInfo6], true);
      expect(result[0]).assertDeepEquals(agendaInfo1);
      expect(result[1]).assertDeepEquals(agendaInfo2);
      expect(result[2]).assertDeepEquals(agendaInfo4);
      expect(result[3]).assertDeepEquals(agendaInfo3);
      expect(result[4]).assertDeepEquals(agendaInfo5);
      expect(result[5]).assertDeepEquals(agendaInfo6);
    });
  });

  describe('compareDataArray_testSuite', () => {
    it('atc_should_return_false_when_dateOld_is_not_equal_to_dateNew', 0, () => {
      let agendaListOld: AgendaCardInfo[] = [];
      let agendaListNew: AgendaCardInfo[] = [];
      let dateTimeOld: CalendarDate = new CalendarDate('2025-06-02');
      let dateTimeNew: CalendarDate = new CalendarDate('2025-06-03');
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew);
      expect(result).assertEqual(false);
    });

    it('atc_should_return_false_when_agendaListOld_length_is_not_equal_to_agendaListNew', 0, () => {
      let agendaListOld: AgendaCardInfo[] = [new AgendaCardInfo(), new AgendaCardInfo()];
      let agendaListNew: AgendaCardInfo[] = [new AgendaCardInfo()];
      let dateTimeOld: CalendarDate = new CalendarDate();
      let dateTimeNew: CalendarDate = new CalendarDate();
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew);
      expect(result).assertEqual(false);
    });

    it('atc_should_return_false_when_agendaListNew_length_is_0', 0, () => {
      let agendaListOld: AgendaCardInfo[] = [];
      let agendaListNew: AgendaCardInfo[] = [];
      let dateTimeOld: CalendarDate = new CalendarDate();
      let dateTimeNew: CalendarDate = new CalendarDate();
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew);
      expect(result).assertEqual(false);
    });

    it('atc_should_return_false_when_any_agenda_is_not_matched', 0, () => {
      let agendaCardInfo1 = new AgendaCardInfo();
      agendaCardInfo1.mEventId = 1;
      let agendaCardInfo2 = new AgendaCardInfo();
      agendaCardInfo2.mEventId = 2;
      let agendaListOld: AgendaCardInfo[] = [agendaCardInfo1];
      let agendaListNew: AgendaCardInfo[] = [agendaCardInfo2];
      let dateTimeOld: CalendarDate = new CalendarDate();
      let dateTimeNew: CalendarDate = new CalendarDate();
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew);
      expect(result).assertEqual(false);
    });

    it('atc_should_return_false_when_any_agenda_is_meeting_and_compareMeetingAgenda_returns_true', 0, () => {
      let agendaCardInfo = new AgendaCardInfo();
      agendaCardInfo.mBegin = 1748916000000;
      let agendaListOld: AgendaCardInfo[] = [agendaCardInfo];
      let agendaListNew: AgendaCardInfo[] = [agendaCardInfo];
      let dateTimeOld: CalendarDate = new CalendarDate();
      let dateTimeNew: CalendarDate = new CalendarDate();
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew, true);
      expect(result).assertEqual(true);
    });

    it('atc_should_return_true_when_all_conditions_are_met', 0, () => {
      let agendaListOld: AgendaCardInfo[] = [new AgendaCardInfo()];
      let agendaListNew: AgendaCardInfo[] = [new AgendaCardInfo()];
      let dateTimeOld: CalendarDate = new CalendarDate();
      let dateTimeNew: CalendarDate = new CalendarDate();
      const result = FormUtils.compareDataArray(agendaListOld, agendaListNew, dateTimeOld, dateTimeNew, false);
      expect(result).assertEqual(true);
    });
  });
}