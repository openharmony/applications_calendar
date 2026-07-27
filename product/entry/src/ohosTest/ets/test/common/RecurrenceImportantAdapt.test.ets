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

import { beforeEach, describe, expect, it, Level, TestType } from '@ohos/hypium';
import { CalendarDate, getAdaptImportantTime } from '@app/common';
import { afterEach } from '@ohos/hypium/src/main/interface';

export default function RecurrenceImportantAdaptTest() {
  let importantDate: CalendarDate;
  let rrule: string;
  let eventType: number;
  describe("ImportantAdaptTest", () => {

    beforeEach(() => {
      CalendarDate.timeZone = 'UTC';
    })

    afterEach(() => {
      CalendarDate.timeZone = 'Asia/Shanghai';
    })

    it("adaptNormal", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2023, 0, 1, 8, 0, 0, 0).getTime()); // 2023年1月1日
      rrule = '';
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2023, 0, 1, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 3, 1))).assertEqual(new CalendarDate(2023, 0, 1, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 11, 30))).assertEqual(new CalendarDate(2023, 0, 1, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1))).assertEqual(new CalendarDate(2023, 0, 1, 0, 0, 0, 0).getTime());
    })

    it("adaptMonthly_normal", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2023, 0, 10, 8, 0, 0, 0).getTime()); // 2023年1月10日
      rrule = 'FREQ=MONTHLY;WKST=SU;BYMONTHDAY=10'; // 每月10号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2022, 1, 2))).assertEqual(new CalendarDate(2023, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2023, 1, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 3, 15))).assertEqual(new CalendarDate(2023, 4, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 11, 2))).assertEqual(new CalendarDate(2023, 11, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 11, 20))).assertEqual(new CalendarDate(2024, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1))).assertEqual(new CalendarDate(2024, 0, 10, 0, 0, 0, 0).getTime());
    })

    it("adaptMonthly_last_date", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2023, 0, 31, 8, 0, 0, 0).getTime()); // 2023年1月31日
      rrule = 'FREQ=MONTHLY;WKST=SU;BYMONTHDAY=31'; // 每月31号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2023, 2, 31, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 2, 15))).assertEqual(new CalendarDate(2023, 2, 31, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 3, 1))).assertEqual(new CalendarDate(2023, 4, 31, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 10, 20)))
        .assertEqual(new CalendarDate(2023, 11, 31, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 11, 1))).assertEqual(new CalendarDate(2024, 11, 31, 0, 0, 0, 0).getTime());
    })

    it("adaptMonthly_leap", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 1, 29, 8, 0, 0, 0).getTime()); // 测试闰月
      rrule = 'FREQ=MONTHLY;WKST=SU;BYMONTHDAY=29'; // 每月29号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 3, 1))).assertEqual(new CalendarDate(2024, 3, 29, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2025, 1, 1)))
        .assertEqual(new CalendarDate(2025, 2, 29, 0, 0, 0, 0).getTime()); // 2025年2月没有29号
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 1, 1)))
        .assertEqual(new CalendarDate(2026, 2, 29, 0, 0, 0, 0).getTime()); // 2026年2月没有29号
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2028, 1, 1))).assertEqual(new CalendarDate(2028, 1, 29, 0, 0, 0, 0).getTime());
    })

    it("adaptMonthly_force", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 1, 15, 8, 0, 0, 0).getTime());
      rrule = 'FREQ=MONTHLY;WKST=SU;BYMONTHDAY=15';
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 1), false))
        .assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1), false))
        .assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 1), true))
        .assertEqual(new CalendarDate(2023, 0, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1), true))
        .assertEqual(new CalendarDate(2024, 0, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 3, 1), true))
        .assertEqual(new CalendarDate(2024, 3, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 3, 16), true))
        .assertEqual(new CalendarDate(2024, 4, 15, 0, 0, 0, 0).getTime());
    })

    it("adaptYearly_normal", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2023, 0, 10, 8, 0, 0, 0).getTime()); // 2023年1月10日
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=10;BYMONTH=1'; // 每年1月10号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2022, 0, 1))).assertEqual(new CalendarDate(2023, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 1))).assertEqual(new CalendarDate(2023, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 10))).assertEqual(new CalendarDate(2023, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 15))).assertEqual(new CalendarDate(2024, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 9))).assertEqual(new CalendarDate(2024, 0, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 11))).assertEqual(new CalendarDate(2025, 0, 10, 0, 0, 0, 0).getTime());
    })

    it("adaptYearly_last_month", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2023, 11, 10, 8, 0, 0, 0).getTime()); // 2023年12月10日
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=10;BYMONTH=12'; // 每年12月10号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2023, 11, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 11, 2))).assertEqual(new CalendarDate(2023, 11, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 11, 15)))
        .assertEqual(new CalendarDate(2024, 11, 10, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 20))).assertEqual(new CalendarDate(2024, 11, 10, 0, 0, 0, 0).getTime());
    })

    it("adaptYearly_leap", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 1, 29, 8, 0, 0, 0).getTime()); // 测试闰月
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=29;BYMONTH=2'; // 每年29号
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2024, 1, 29, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 1, 1))).assertEqual(new CalendarDate(2024, 1, 29, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 2, 1))).assertEqual(new CalendarDate(2028, 1, 29, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2025, 10, 20))).assertEqual(new CalendarDate(2028, 1, 29, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2028, 0, 1))).assertEqual(new CalendarDate(2028, 1, 29, 0, 0, 0, 0).getTime());
    })

    it("adaptYearly_force", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 1, 15, 8, 0, 0, 0).getTime());
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=15;BYMONTH=2';
      eventType = 0;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 1), false))
        .assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1), false))
        .assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 0, 1), true))
        .assertEqual(new CalendarDate(2023, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 0, 1), true))
        .assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 3, 1), true))
        .assertEqual(new CalendarDate(2025, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 3, 16), true))
        .assertEqual(new CalendarDate(2025, 1, 15, 0, 0, 0, 0).getTime());
    })

    it("adaptLunarYearly_force", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 1, 15, 8, 0, 0, 0).getTime());
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=6;BYMONTH=1';
      eventType = 1;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2023, 1, 2))).assertEqual(new CalendarDate(2024, 1, 15, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2025, 1, 1))).assertEqual(new CalendarDate(2025, 1, 3, 0, 0, 0, 0).getTime());
    })

    it("adaptLunarYearly_leapMonth", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 8, 25, 8, 0, 0, 0).getTime());
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=23;BYMONTH=8';
      eventType = 1;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 6, 7))).assertEqual(new CalendarDate(2026, 9, 3, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2025, 9, 10))).assertEqual(new CalendarDate(2025, 9, 14, 0, 0, 0, 0).getTime());
    })

    it("adaptLunarYearly_lastMonth", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2024, 11, 18, 8, 0, 0, 0).getTime());
      rrule = 'FREQ=YEARLY;WKST=SU;BYMONTHDAY=11;BYMONTH=18';
      eventType = 1;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2024, 9, 15))).assertEqual(new CalendarDate(2024, 11, 18, 0, 0, 0, 0).getTime());
    })

    it("adaptLunarYearly_November", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2027, 0, 2, 8, 0, 0, 0).getTime()); // 2026年冬月二十五
      rrule = 'FREQ=YEARLY;BYMONTHDAY=25;BYMONTH=11';
      eventType = 1;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 11, 27))).assertEqual(new CalendarDate(2027, 0, 2, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2027, 0, 1))).assertEqual(new CalendarDate(2027, 0, 2, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2028, 0, 9))).assertEqual(new CalendarDate(2028, 0, 2, 0, 0, 0, 0).getTime());
    })

    it("adaptLunarYearly_November1", Level.LEVEL1 | TestType.FUNCTION, () => {
      importantDate = new CalendarDate(new Date(2022, 11, 21, 8, 0, 0, 0).getTime()); // 2022年冬月二十八
      rrule = 'FREQ=YEARLY;BYMONTHDAY=28;BYMONTH=11';
      eventType = 1;
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 7, 19))).assertEqual(new CalendarDate(2027, 0, 5, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 4, 13))).assertEqual(new CalendarDate(2027, 0, 5, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 10, 15))).assertEqual(new CalendarDate(2027, 0, 5, 0, 0, 0, 0).getTime());
      expect(getAdaptImportantTime(eventType, importantDate.getTime(), rrule, new CalendarDate(2026, 11, 9))).assertEqual(new CalendarDate(2027, 0, 5, 0, 0, 0, 0).getTime());
    })
  });
}