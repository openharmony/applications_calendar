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
import { beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import { DAY_PER_WEEK, DayData, Log, CalendarDate } from '@app/common';
import { MonthlyInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';

const TAG = 'MonthlyInfoTest';

export default function MonthlyInfoTest() {
  describe('MonthlyInfoTest', () => {
    let monthlyInfo: MonthlyInfo;
    const defaultMonth: number = 1;
    const defaultYear: number = 2024;

    beforeAll(async (done: Function) => {
      Log.info(TAG, `MonthlyInfoTest beforeAll`);
      done();
    })

    beforeEach(async (done: Function) => {
      // 点击进入月视图
      Log.info(TAG, `${TAG}click month tab begin`);
      monthlyInfo = new MonthlyInfo(defaultYear, defaultMonth);
      done();
    })

    it('MonthlyInfo_getDisplayDays_01', 0, () => {
      expect(new MonthlyInfo(2023, 2).getDisplayDays().length).assertEqual(5 * 7); // 2月
      expect(new MonthlyInfo(2023, 3).getDisplayDays().length).assertEqual(5 * 7); // 3月
      expect(new MonthlyInfo(2023, 4).getDisplayDays().length).assertEqual(6 * 7); // 4月
    })

    it('MonthlyInfo_getDisplayDays_02', 0, () => {
      let result: MonthlyInfo = new MonthlyInfo(2023, 8, 0);
      expect(result).not().assertUndefined();
      const expectLength = 5 * DAY_PER_WEEK; // 5行
      const displayDays = result.getDisplayDays();
      expect(displayDays.length).assertEqual(expectLength); // 23年8月
      expect(displayDays[0].getDate().toString()).assertEqual(new CalendarDate('2023-7-30').toString()); // 月视图上,8月最前一天是7.30
      expect(displayDays[expectLength - 1].getDate().toString()).assertEqual(new CalendarDate('2023-9-2').toString()); // 月视图上,8月最后一天是9.2
    })

    it('MonthlyInfo_getDisplayDays_03', 0, () => {
      let result: MonthlyInfo = new MonthlyInfo(2024, 9, 0);
      expect(result).not().assertUndefined();
      const expectLength = 5 * DAY_PER_WEEK; // 5行
      const displayDays = result.getDisplayDays();
      expect(displayDays.length).assertEqual(expectLength); // 24年9月
      expect(displayDays[0].getDate().toString()).assertEqual(new CalendarDate('2024-9-1').toString()); // 月视图上,9月最前一天是9.1
      expect(displayDays[expectLength - 1].getDate().toString()).assertEqual(new CalendarDate('2024-10-5').toString()); // 月视图上,9月最后一天是10.5

    })

    it('MonthlyInfo_getDisplayDays_04', 0, () => {
      let result: MonthlyInfo = new MonthlyInfo(2023, 8, 4);
      expect(result).not().assertUndefined();
      const expectLength = 6 * DAY_PER_WEEK; // 5行
      const displayDays = result.getDisplayDays();
      expect(displayDays.length).assertEqual(expectLength); // 23年8月 一周开始日：周四
      expect(displayDays[0].getDate().toString()).assertEqual(new CalendarDate('2023-7-27').toString()); // 月视图上,8月最前一天是7.27
      expect(displayDays[expectLength - 1].getDate().toString()).assertEqual(new CalendarDate('2023-9-6').toString()); // 月视图上,8月最后一天是9.6
    })

    it('MonthlyInfo_getLast', 0, () => {
      let result = new MonthlyInfo(2023, 1).getLast()
      expect(result).not().assertUndefined();
      expect(result.solarMonth).assertEqual(12);
      expect(result.solarYear).assertEqual(2022);

      result = new MonthlyInfo(2023, 2).getLast();
      expect(result).not().assertUndefined();
      expect(result.getDisplayDays().length).assertEqual(35);
      expect(result.solarMonth).assertEqual(1);
      expect(result.solarYear).assertEqual(2023);
    })

    it('MonthlyInfo_getNext', 0, () => {
      let result = new MonthlyInfo(2023, 12).getNext()
      expect(result).not().assertUndefined();
      expect(result.solarMonth).assertEqual(1);
      expect(result.solarYear).assertEqual(2024);

      result = new MonthlyInfo(2023, 1).getNext();
      expect(result).not().assertUndefined();
      expect(result.solarMonth).assertEqual(2);
      expect(result.solarYear).assertEqual(2023);
    })

    it('MonthlyInfoTest_Construct_Normal_1', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 2);
      expect(monthlyInfo.solarYear).assertEqual(2024);
      expect(monthlyInfo.solarMonth).assertEqual(2);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('29');
      expect(monthlyInfo.getMouthInfo()).not().assertNull();
      done();
    })

    it('MonthlyInfoTest_Construct_Normal_2', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(1967, 1);
      expect(monthlyInfo.solarYear).assertEqual(1967);
      expect(monthlyInfo.solarMonth).assertEqual(1);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('31');
      expect(monthlyInfo.getMouthInfo()).not().assertNull();
      done();
    })

    it('MonthlyInfoTest_Construct_Normal_3', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(1967, 13);
      expect(monthlyInfo.solarYear).assertEqual(0);
      expect(monthlyInfo.solarMonth).assertEqual(0);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]))).assertEqual('[]');
      expect(monthlyInfo.getMouthInfo()).assertUndefined();
      done();
    })

    it('MonthlyInfoTest_Construct_Normal_4', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(1967, 0);
      expect(monthlyInfo.solarYear).assertEqual(0);
      expect(monthlyInfo.solarMonth).assertEqual(0);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]))).assertEqual('[]');
      expect(monthlyInfo.getMouthInfo()).assertUndefined();
      done();
    })

    it('MonthlyInfoTest_Construct_Normal_5', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(-300, 0);
      expect(monthlyInfo.solarYear).assertEqual(0);
      expect(monthlyInfo.solarMonth).assertEqual(0);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]))).assertEqual('[]');
      expect(monthlyInfo.getMouthInfo()).assertUndefined();
      done();
    })

    it('MonthlyInfoTest_GetNext_1', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 1);
      monthlyInfo = monthlyInfo.getNext();
      expect(monthlyInfo.solarYear).assertEqual(2024);
      expect(monthlyInfo.solarMonth).assertEqual(2);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('29');
      done();
    })

    it('MonthlyInfoTest_GetNext_2', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 12);
      monthlyInfo = monthlyInfo.getNext();
      expect(monthlyInfo.solarYear).assertEqual(2025);
      expect(monthlyInfo.solarMonth).assertEqual(1);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('31');
      done();
    })

    it('MonthlyInfoTest_GetNext_3', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2025, 7);
      monthlyInfo = monthlyInfo.getNext();
      expect(monthlyInfo.solarYear).assertEqual(2025);
      expect(monthlyInfo.solarMonth).assertEqual(8);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('31');
      done();
    })

    it('MonthlyInfoTest_GetLast_1', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 3);
      monthlyInfo = monthlyInfo.getLast();
      expect(monthlyInfo.solarYear).assertEqual(2024);
      expect(monthlyInfo.solarMonth).assertEqual(2);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('29');
      done();
    })

    it('MonthlyInfoTest_GetLast_2', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 2);
      monthlyInfo = monthlyInfo.getLast();
      expect(monthlyInfo.solarYear).assertEqual(2024);
      expect(monthlyInfo.solarMonth).assertEqual(1);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('31');
      done();
    })

    it('MonthlyInfoTest_GetLast_3', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 1);
      monthlyInfo = monthlyInfo.getLast();
      expect(monthlyInfo.solarYear).assertEqual(2023);
      expect(monthlyInfo.solarMonth).assertEqual(12);
      expect(JSON.stringify((monthlyInfo.getDaysInfo() as DayData[]).length)).assertEqual('31');
      done();
    })

    it('MonthlyInfoTest_getDaysInfo_1', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 3);
      const daysInfo: DayData[] = monthlyInfo.getDaysInfo() as DayData[];
      expect(daysInfo.length).assertEqual(31);
      done();
    })

    it('MonthlyInfoTest_getDaysInfo_2', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2015, 2, 0);
      const daysInfo: DayData[] = monthlyInfo.getDaysInfo() as DayData[];
      expect(daysInfo.length).assertEqual(28);
      done();
    })

    it('MonthlyInfoTest_getDaysInfo_1582_10', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(1582, 10, 0);
      const daysInfo: DayData[] = monthlyInfo.getDaysInfo() as DayData[];
      expect(daysInfo.length).assertEqual(21);
      done();
    })

    it('MonthlyInfoTest_getDisplayDays_1', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2024, 3);
      const daysInfo: DayData[] = monthlyInfo.getDisplayDays() as DayData[];
      expect(daysInfo.length).assertEqual(42);
      done();
    })

    it('MonthlyInfoTest_getDisplayDays_2', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(2015, 2, 0);
      const daysInfo: DayData[] = monthlyInfo.getDisplayDays() as DayData[];
      expect(daysInfo.length).assertEqual(28);
      done();
    })

    it('MonthlyInfoTest_getDayData_1582_10', 0, async (done: Function) => {
      monthlyInfo = new MonthlyInfo(1582, 10, 0);
      monthlyInfo.getDaysInfo();
      expect(monthlyInfo.getMouthInfo()?.getDayData(31)?.solarDay).assertEqual(31);
      done();
    })
  })
}