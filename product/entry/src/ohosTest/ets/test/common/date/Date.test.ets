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

import { describe, expect, it } from '@ohos/hypium'
import { CalendarDate, DateManager, DayData, DAY_PER_WEEK, MonthInfo, YearData } from '@app/common/index'

export default function DateTest() {
  describe('DateTest', () => {
    it('YearData_SysDate', 0, () => {
      let date = new Date(2023, 2, 0) // month as input should be Natural Month
      expect(date.getDate()).assertEqual(28);
      expect(date.getMonth()).assertEqual(1);
    })
    it('YearData_solarYear', 0, () => {
      expect(new YearData(2023).solarYear).assertEqual(2023); // 1月
    })

    it('YearData_getMonthInfo_01', 0, () => {
      expect(new YearData(2023).getMonthInfo(-1)).assertUndefined();
    })

    it('YearData_getMonthInfo_02', 0, () => {
      expect(new YearData(2023).getMonthInfo(0)).assertUndefined();
    })

    it('YearData_getMonthInfo_03', 0, () => {
      expect(new YearData(2023).getMonthInfo(13)).assertUndefined();
    })
  })
  
  describe('MonthInfo', () => {
    it('getDaysInfo_01', 0, () => {
      expect(new MonthInfo(2023, 1).getDaysInfo().length).assertEqual(31); // 1月
    })

    it('getDaysInfo_02', 0, () => {
      expect(new MonthInfo(2023, 2).getDaysInfo().length).assertEqual(28); // 2月
    })

    it('getDaysInfo_03', 0, () => {
      expect(new MonthInfo(2023, 3).getDaysInfo().length).assertEqual(31); // 3月
    })

    it('getLast_01', 0, () => {
      let result = new MonthInfo(2023, 1).getLast()
      expect(result).not().assertUndefined();
      if (result) {
        expect(result.getMonth()).assertEqual(12);
        expect(result.getSolarYear()).assertEqual(2022);
      }
    })

    it('getLast_02', 0, () => {
      let result = new MonthInfo(2023, 2).getLast()
      expect(result).not().assertUndefined();
      if (result) {
        expect(result.getMonth()).assertEqual(1);
        expect(result.getSolarYear()).assertEqual(2023);
      }
    })

    it('getNext_01', 0, () => {
      let result = new MonthInfo(2023, 12).getNext()
      expect(result).not().assertUndefined();
      if (result) {
        expect(result.getMonth()).assertEqual(1);
        expect(result.getSolarYear()).assertEqual(2024);
      }
    })

    it('getNext_02', 0, () => {
      let result = new MonthInfo(2023, 1).getNext();
      expect(result).not().assertUndefined();
      if (result) {
        expect(result.getMonth()).assertEqual(2);
        expect(result.getSolarYear()).assertEqual(2023);
      }
    })

    // 2024年3月份 起始日为周天有6周
    it('getWeeks_defaultStartWeek', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(3);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        let weekDays = monthInfo.getWeeks();
        expect(weekDays.length).assertEqual(6);
        expect(weekDays[0].length).assertEqual(2); // 3.1 3.2
        expect(weekDays[5].length).assertEqual(1); // 3.31
      }
    })

    // 2024年3月份 起始日为周1有5周
    it('getWeeks_StartWeek_change', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(3);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        let weekDays = monthInfo.getWeeks(1);
        expect(weekDays.length).assertEqual(5);
        expect(weekDays[0].length).assertEqual(3);
        expect(weekDays[4].length).assertEqual(7);
      }
    })

    // 2024年3月份 起始日为周1有5周
    it('getWeeks_call_duplicate', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(3);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        let weekDays = monthInfo.getWeeks(0);
        weekDays = monthInfo.getWeeks(1);
        expect(weekDays.length).assertEqual(5);
        expect(weekDays[0].length).assertEqual(3);
        expect(weekDays[4].length).assertEqual(7);
      }
    })

    // 2024年3月份 起始日为周1有6周
    it('getFullWeeks_01', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(3);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        let weekDays = monthInfo.getFullWeeks();
        expect(weekDays.length).assertEqual(6);
        expect(weekDays[0].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[0][0]).assertDeepEquals(DateManager.getInstance().getDayData(2024, 2, 25));
        expect(weekDays[5].length).assertEqual(DAY_PER_WEEK); // 3.31
        expect(weekDays[5][0]).assertDeepEquals(DateManager.getInstance().getDayData(2024, 3, 31));
        expect(weekDays[5][DAY_PER_WEEK -1])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 4, 6));
      }
    })

    it('getFullWeeks_02', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(1);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        const expectWeekNum = 5;
        let weekDays = monthInfo.getFullWeeks();
        expect(weekDays.length).assertEqual(expectWeekNum);
        expect(weekDays[0].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[0][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2023, 12, 31));
        expect(weekDays[expectWeekNum-1].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[expectWeekNum-1][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 1, 28));
        expect(weekDays[expectWeekNum-1][DAY_PER_WEEK -1])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 2, 3));
      }
    })

    it('getFullWeeks_cross3month', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2024)?.getMonthInfo(9);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        const expectWeekNum = 6;
        let weekDays = monthInfo.getFullWeeks(1);
        expect(weekDays.length).assertEqual(expectWeekNum);
        expect(weekDays[0].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[0][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 8, 26));
        expect(weekDays[expectWeekNum-1].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[expectWeekNum-1][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 9, 30));
        expect(weekDays[expectWeekNum-1][DAY_PER_WEEK -1])
          .assertDeepEquals(DateManager.getInstance().getDayData(2024, 10, 6));
      }
    })

    it('getFullWeeks_cross4month', 0, () => {
      let monthInfo = DateManager.getInstance().getYearData(2000)?.getMonthInfo(10);
      expect(monthInfo).not().assertUndefined();
      if (monthInfo) {
        const expectWeekNum = 5;
        let weekDays = monthInfo.getFullWeeks();
        expect(weekDays.length).assertEqual(expectWeekNum);
        expect(weekDays[0].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[0][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2000, 10, 1));
        expect(weekDays[expectWeekNum-1].length).assertEqual(DAY_PER_WEEK);
        expect(weekDays[expectWeekNum-1][0])
          .assertDeepEquals(DateManager.getInstance().getDayData(2000, 10, 29));
        expect(weekDays[expectWeekNum-1][DAY_PER_WEEK -1])
          .assertDeepEquals(DateManager.getInstance().getDayData(2000, 11, 4));
      }
    })
  })

  describe('DayData', () => {
    it('getSolarYear', 0, () => {
      let a = new DayData(2023, 1, 1);
      let b = a.getDate();
      expect(b.getFullYear()).assertEqual(a.solarYear);
    })

    it('getSolarMonth', 0, () => {
      let a = new DayData(2023, 1, 1);
      let b = a.getDate();
      expect(a.solarMonth).assertEqual(1);
      a = new DayData(2023, 2, 1);
      expect(a.solarMonth).assertEqual(2);
    })

    it('isValid_year_01', 0, () => {
      const day = new DayData(-1, 1, 1);
      expect(day.isValid()).assertFalse();
    })

    it('isValid_year_02', 0, () => {
      const day = new DayData(0, 1, 1);
      expect(day.isValid()).assertFalse();
    })

    it('isValid_month_01', 0, () => {
      expect(new DayData(1, -1, 1).isValid()).assertFalse();
    })

    it('isValid_month_02', 0, () => {
      expect(new DayData(1, 0, 1).isValid()).assertFalse();
    })

    it('isValid_month_03', 0, () => {
      expect(new DayData(1, 1, 1).isValid()).assertTrue();
    })

    it('isValid_month_04', 0, () => {
      expect(new DayData(1, 12, 1).isValid()).assertTrue()
    })

    it('isValid_day', 0, () => {
      expect(new DayData(1, 1, -1).isValid()).assertFalse()
      expect(new DayData(1, 1, 0).isValid()).assertFalse()
      expect(new DayData(1, 1, 1).isValid()).assertTrue()
      expect(new DayData(1, 1, 32).isValid()).assertTrue()
    })

    it('getWeekDay', 0, () => {
      let a = new DayData(2023, 1, 1);
      expect(a.solarYear).assertEqual(2023)
      expect(a.solarMonth).assertEqual(1)
      expect(a.solarDay).assertEqual(1)
      expect(a.getWeekDay()).assertEqual(0) // 周天
    })

    it('setSolarYear', 0, () => {
      let a = new DayData(2023, 1, 1);
      a.solarYear = 2024;
      expect(a.getDate().getFullYear()).assertEqual(2024);
    })

    it('setSolarMonth', 0, () => {
      let a = new DayData(2023, 1, 1);
      a.solarMonth = 12;
      expect(a.getDate().getMonth()).assertEqual(11);
    })

    it('setSolarDay', 0, () => {
      let a = new DayData(2023, 1, 1);
      a.solarDay = 12;
      expect(a.getDate().getDate()).assertEqual(12);
    })

    it('testGetTimeStamp', 0, () => {
      let a = new DayData(2025, 4, 18);
      CalendarDate.timeZone = 'Australia/Adelaide';
      expect(a.getTimeStamp()).assertEqual(1744900200000);
    })

    it('testGetOriDate', 0, () => {
      let a = new DayData(2025, 9, 1);
      a.solarDay = 18;
      expect(a.getOriDate().getFullYear()).assertEqual(2025);
      expect(a.getOriDate().getMonth()).assertEqual(8);
      expect(a.getOriDate().getDate()).assertEqual(18);
    });

  })
}