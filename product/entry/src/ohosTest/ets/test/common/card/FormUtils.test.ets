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
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CalendarDate, MILLS_PER_HOUR, MILLS_PER_MINUTE } from '@app/common';

export default function FormUtilsTest() {
  describe('groupAgendaByDayAll',  () => {
    const julianDay = FormUtils.getCurrentJulianDay();
    it('originList_is_empty', 0, async (done : Function) => {
      const originList: Array<AgendaCardInfo> = [];
      const result = FormUtils.groupAgendaByDayAll(originList, julianDay);
      expect(result).assertDeepEquals([]);
      done();
    });

    // mBegin mEnd 在 日程集合起始时间范围内, 标记FLAG_MID
    it('originList_has_one_item', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 1, 11, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item1 = new AgendaCardInfo();
      item1.mStartDay = day1;
      item1.mEndDay = day2;
      item1.mBegin = startDate.getTime();
      item1.mEnd = endDate.getTime();
      const result = FormUtils.groupAgendaByDayAll([item1], day1);
      expect(result.length).assertEqual(1);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_on_different_days', 0, async (done: Function) => {
      const date1 = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const date2 = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = date1.getJulianDay();
      const day2 = date2.getJulianDay();
      const item1 = new AgendaCardInfo();
      item1.mStartDay = day1;
      item1.mEndDay = day1;
      item1.mBegin = date1.getTime();
      item1.mEnd = date1.getTime() + MILLS_PER_HOUR;
      const item2 = new AgendaCardInfo();
      item2.mStartDay = day2;
      item2.mEndDay = day2;
      item2.mBegin = date2.getTime();
      item2.mEnd = date2.getTime() + MILLS_PER_HOUR;
      const result = FormUtils.groupAgendaByDayAll([item1, item2], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day2);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_on_the_same_day', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 1, 12, 0, 0);
      const day1 = startDate.getJulianDay();
      const item1 = new AgendaCardInfo();
      item1.mStartDay = day1;
      item1.mEndDay = day1;
      item1.mBegin = startDate.getTime();
      item1.mEnd = endDate.getTime();
      const item2 = new AgendaCardInfo(item1);
      item2.mEnd = endDate.getTime() + MILLS_PER_MINUTE;
      const result = FormUtils.groupAgendaByDayAll([item1, item2], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day1);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    // 跨天场景
    it('originList_has_multiple_items_spanning_multiple_days', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item = new AgendaCardInfo();
      item.mStartDay = day1;
      item.mEndDay = day2;
      item.mBegin = startDate.getTime();
      item.mEnd = endDate.getTime();
      const originList: Array<AgendaCardInfo> = [item];
      const result = FormUtils.groupAgendaByDayAll(originList, day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_START);
      expect(result[1].mDay).assertEqual(day2);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_END);
      done();
    });

    it('originList_has_multiple_items_with_different_flags', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item1 = new AgendaCardInfo();
      item1.mStartDay = day1;
      item1.mEndDay = day1;
      item1.mBegin = startDate.getTime();
      item1.mEnd = startDate.getTime() + MILLS_PER_HOUR; // 非跨天日程
      const item2 = new AgendaCardInfo();
      item2.mStartDay = day1;
      item2.mEndDay = day2;
      item2.mBegin = startDate.getTime();
      item2.mEnd = endDate.getTime();   // 跨天日程
      const originList: Array<AgendaCardInfo> = [item1, item2];
      const result = FormUtils.groupAgendaByDayAll(originList, day1);
      expect(result.length).assertEqual(3);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day1);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_START);
      expect(result[2].mDay).assertEqual(day2);
      expect(result[2].mFlag).assertEqual(AgendaCardInfo.FLAG_END);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time', 0,  async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const item1 = new AgendaCardInfo();
      item1.mStartDay = day1;
      item1.mEndDay = day1;
      item1.mBegin = startDate.getTime();
      item1.mEnd = startDate.getTime() + MILLS_PER_HOUR;
      const originList: Array<AgendaCardInfo> = [item1, item1];
      const result = FormUtils.groupAgendaByDayAll(originList, day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time_on_different_days', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mEnd = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mTitle = 'Meeting';
      const item6 = new AgendaCardInfo();
      item6.mStartDay = day2;
      item6.mEndDay = day2;
      item6.mBegin = new CalendarDate(2021, 1, 2, 10, 0, 0).getTime();
      item6.mEnd = new CalendarDate(2021, 1, 2, 10, 0, 0).getTime();
      const result = FormUtils.groupAgendaByDayAll([item5, item6], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day2);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time_with_different_flags', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = startDate.getTime();
      item5.mEnd = startDate.getTime();
      const item6 = new AgendaCardInfo();
      item6.mStartDay = day1;
      item6.mEndDay = day2;
      item6.mBegin = startDate.getTime();
      item6.mEnd = endDate.getTime();
      const result = FormUtils.groupAgendaByDayAll([item5, item6], day1);
      expect(result.length).assertEqual(3);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day1);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_START);
      expect(result[2].mDay).assertEqual(day2);
      expect(result[2].mFlag).assertEqual(AgendaCardInfo.FLAG_END);
      done();
    });

    it('when_originList_has_multiple_items_with_same_start_and_end_time_with_same_title', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mEnd = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mTitle = 'Meeting';
      const result = FormUtils.groupAgendaByDayAll([item5, item5], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time_with_different_titles', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mEnd = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mTitle = 'Meeting';
      let tempItem = new AgendaCardInfo(item5);
      tempItem.mTitle = 'Meeting 2';
      const result = FormUtils.groupAgendaByDayAll([item5, tempItem], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day1);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time_with_different_titles_and_different_flags', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mEnd = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      let tempItem = new AgendaCardInfo(item5);
      tempItem.mEndDay = day2;
      tempItem.mEnd = new CalendarDate(2021, 1, 2, 10, 0, 0).getTime();
      const originList: Array<AgendaCardInfo> = [new AgendaCardInfo(item5), tempItem];
      const result = FormUtils.groupAgendaByDayAll(originList, day1);
      expect(result.length).assertEqual(3);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day1);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_START);
      expect(result[2].mDay).assertEqual(day2);
      expect(result[2].mFlag).assertEqual(AgendaCardInfo.FLAG_END);
      done();
    });

    it('originList_has_multiple_items_with_same_start_and_end_time_with_different_titles_and_different_flags_and_different_days', 0, async (done: Function) => {
      const startDate = new CalendarDate(2021, 1, 1, 10, 0, 0);
      const endDate = new CalendarDate(2021, 1, 2, 10, 0, 0);
      const day1 = startDate.getJulianDay();
      const day2 = endDate.getJulianDay();
      const item5 = new AgendaCardInfo();
      item5.mStartDay = day1;
      item5.mEndDay = day1;
      item5.mBegin = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      item5.mEnd = new CalendarDate(2021, 1, 1, 10, 0, 0).getTime();
      const item8 = new AgendaCardInfo();
      item8.mStartDay = day2;
      item8.mEndDay = day2;
      item8.mBegin = new CalendarDate(2021, 1, 2, 10, 0, 0).getTime();
      item8.mEnd = new CalendarDate(2021, 1, 2, 10, 0, 0).getTime();
      item8.mTitle = 'Meeting 2';

      const result = FormUtils.groupAgendaByDayAll([item5, item8], day1);
      expect(result.length).assertEqual(2);
      expect(result[0].mDay).assertEqual(day1);
      expect(result[0].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      expect(result[1].mDay).assertEqual(day2);
      expect(result[1].mFlag).assertEqual(AgendaCardInfo.FLAG_MID);
      done();
    });

  })
}