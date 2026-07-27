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

import { I18nUtil } from '@app/common';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
} from '@ohos/hypium';

export default function CalendarDateTest() {
  const nowTimeZone = I18nUtil.getSystemTimeZone();
  describe('CalendarDateTest', () => {

    beforeEach(() => {
      CalendarDate.timeZone = nowTimeZone;
    });

    afterEach(() => {
      CalendarDate.timeZone = nowTimeZone;
    });

    it('should_handle_undefined_time_parameter', 0, async (done: Function) => {
      const cal = new CalendarDate();
      const date = new Date();
      expect(cal.getFullYear()).assertEqual(date.getFullYear());
      expect(cal.getMonth()).assertEqual(date.getMonth());
      expect(cal.getDate()).assertEqual(date.getDate());
      expect(cal.getHours()).assertEqual(date.getHours());
      expect(cal.getMinutes()).assertEqual(date.getMinutes());
      expect(cal.getSeconds()).assertEqual(date.getSeconds());
      done();
    });

    it('should_handle_string_time_parameter', 0, async (done: Function) => {
      const cal = new CalendarDate('2024-05-29');
      expect(cal.getTime()).assertEqual(new Date('2024-05-29').getTime());
      done();
    });

    it('should_handle_number_time_parameter_with_monthIndex_undefined', 0, async (done: Function) => {
      const cal = new CalendarDate(1234567890);
      expect(cal.getTime()).assertEqual(1234567890);
      done();
    });

    it('should_handle_number_time_parameter_with_monthIndex_defined', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getTime()).assertEqual(new Date(2024, 4, 1).getTime());
      done();
    });

    it('should_handle_date_parameter_with_monthIndex_defined', 0, async (done: Function) => {
      const inDate = new Date('2024-04-01');
      const cal = new CalendarDate(inDate);
      expect(cal.getFullYear()).assertEqual(inDate.getFullYear());
      expect(cal.getMonth()).assertEqual(inDate.getMonth());
      expect(cal.getDate()).assertEqual(inDate.getDate());
      expect(cal.getHours()).assertEqual(inDate.getHours());
      expect(cal.getMinutes()).assertEqual(inDate.getMinutes());
      expect(cal.getSeconds()).assertEqual(inDate.getSeconds());
      done();
    });

    it('should_handle_other_cases', 0, async (done: Function) => {
      const cal = new CalendarDate('invalid', 0);
      const date = new Date();
      expect(cal.getFullYear()).assertEqual(date.getFullYear());
      expect(cal.getMonth()).assertEqual(date.getMonth());
      expect(cal.getDate()).assertEqual(date.getDate());
      expect(cal.getHours()).assertEqual(date.getHours());
      expect(cal.getMinutes()).assertEqual(date.getMinutes());
      expect(cal.getSeconds()).assertEqual(date.getSeconds());
      done();
    });

    it('buildCalendarDate', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let nowMock: Function = mocker.mockFunc(Date, Date.now);
      when(nowMock)().afterReturn(1234567890);
      let calendarDate: CalendarDate = new CalendarDate();
      expect(calendarDate.getTime()).assertEqual(1234567890);
      mocker.verify('now', []).atLeast(1);
      mocker.ignoreMock(Date, Date.now);
      let calendarDate2: CalendarDate = new CalendarDate(9876543210);
      expect(calendarDate2.getTime()).assertEqual(9876543210);
      done();
    });

    it('setByFailYear_1', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(0, 1, 1);
      expect(calendarDate.getFullYear()).assertEqual(new Date().getFullYear());
      done();
    });

    it('setByFailYear_2', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(10000, 1, 1);
      expect(calendarDate.getFullYear()).assertEqual(new Date().getFullYear());
      done();
    });

    it('setByFailMonth_1', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, -1, 1);
      expect(calendarDate.getFullYear()).assertEqual(2019);
      expect(calendarDate.getMonth()).assertEqual(11);
      done();
    });

    it('setByFailMonth_2', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 12, 1);
      expect(calendarDate.getFullYear()).assertEqual(2021);
      expect(calendarDate.getMonth()).assertEqual(0);
      done();
    });

    it('setByFailDate_1', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 0);
      expect(calendarDate.getDate()).assertEqual(new Date(2020, 1, 0).getDate());
      done();
    });

    it('setByFailDate_2', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 32);
      expect(calendarDate.getDate()).assertEqual(new Date(2020, 1, 32).getDate());
      done();
    });

    it('setByFailHour_1', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 2, -1);
      expect(calendarDate.getDate()).assertEqual(1);
      expect(calendarDate.getHours()).assertEqual(23);
      done();
    });

    it('setByFailHour_2', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 1, 24);
      expect(calendarDate.getDate()).assertEqual(2);
      expect(calendarDate.getHours()).assertEqual(0);
      done();
    });

    it('setByFailMinutes_1', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 1, 1, -1);
      expect(calendarDate.getHours()).assertEqual(0);
      expect(calendarDate.getMinutes()).assertEqual(59);
      done();
    });

    it('setByFailMinutes_2', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 1, 0, 60);
      expect(calendarDate.getHours()).assertEqual(1);
      expect(calendarDate.getMinutes()).assertEqual(0);
      done();
    });

    it('setByTrueData', 0, async (done: Function) => {
      let calendarDate = new CalendarDate();
      calendarDate.set(2020, 1, 1, 12, 30, 0);
      expect(calendarDate.getFullYear()).assertEqual(2020);
      expect(calendarDate.getMonth()).assertEqual(1);
      expect(calendarDate.getDate()).assertEqual(1);
      expect(calendarDate.getHours()).assertEqual(12);
      expect(calendarDate.getMinutes()).assertEqual(30);
      done();
    });

    it('getTimeZoneOff', 0, async (done: Function) => {
      CalendarDate.timeZone = 'Asia/Shanghai'; // +8时区,上海
      let calendarDate = new CalendarDate(1609459200000); // 2021-01-01 00:00:00 UTC
      const result = calendarDate.getTimezoneOffset(1609459200000);
      expect(result).assertEqual(28800000);
      CalendarDate.timeZone = 'UTC';
      let calendarDate2 = new CalendarDate(1609459200000); // 2021-01-01 00:00:00 UTC
      const result2 = calendarDate2.getTimezoneOffset(1609459200000);
      expect(result2).assertEqual(0);
      done();
    });

    it('getJulianDay', 0, async (done: Function) => {
      let calendarDate = new CalendarDate(1634227200000); // 2021-10-15 00:00:00 +8
      const result = calendarDate.getJulianDay();
      expect(result).assertEqual(2459503);
      CalendarDate.timeZone = 'UTC';
      let calendarDate2 = new CalendarDate(1634227200000); // 2021-10-15 00:00:00 +8
      const result2 = calendarDate2.getJulianDay();
      expect(result2).assertEqual(2459502);
      done();
    });


    it('getDateString', 0, async (done: Function) => {
      let calendarDate = new CalendarDate(1609459200000); // 2021-01-01 08:00:00
      const result = calendarDate.toDateString();
      expect(result)
        .assertEqual(new Date(1609459200000).toDateString()); // 2021 is the year, 0 is the month (January), 1 is the day, 5 is the day of the week (Friday)
      let calendarDate2 = new CalendarDate();
      const result2 = calendarDate2.toDateString();
      const currentDate = new Date();
      expect(result2)
        .assertEqual(currentDate.toDateString());
      done();
    });


    it('toString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toString()).assertEqual(new Date(2024, 4, 1).toString());
      done();
    });


    it('toTimeString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toTimeString()).assertEqual(new Date(2024, 4, 1).toTimeString());
      done();
    });


    it('toLocaleString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toLocaleString()).assertEqual(new Date(2024, 4, 1).toLocaleString());
      done();
    });


    it('toLocaleDateString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toLocaleDateString()).assertEqual(new Date(2024, 4, 1).toLocaleDateString());
      done();
    });


    it('toLocaleTimeString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toLocaleTimeString()).assertEqual(new Date(2024, 4, 1).toLocaleTimeString());
      done();
    });


    it('valueOf', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.valueOf()).assertEqual(new Date(2024, 4, 1).valueOf());
      done();
    });


    it('getUTCMonth', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getUTCMonth()).assertEqual(new Date(2024, 4, 1).getUTCMonth());
      done();
    });


    it('getUTCDate', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getUTCDate()).assertEqual(new Date(2024, 4, 1).getUTCDate());
      done();
    });


    it('getUTCMinutes', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getUTCMinutes()).assertEqual(new Date(2024, 4, 1).getUTCMinutes());
      done();
    });


    it('getUTCSeconds', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getUTCSeconds()).assertEqual(new Date(2024, 4, 1).getUTCSeconds());
      done();
    });


    it('getUTCMilliseconds', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.getUTCMilliseconds()).assertEqual(new Date(2024, 4, 1).getUTCMilliseconds());
      done();
    });


    it('toUTCString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toUTCString()).assertEqual(new Date(2024, 4, 1).toUTCString());
      done();
    });


    it('toISOString', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toISOString()).assertEqual(new Date(2024, 4, 1).toISOString());
      done();
    });


    it('toJSON', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      expect(cal.toJSON()).assertEqual(new Date(2024, 4, 1).toJSON());
      done();
    });


    it('setUTCYear', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCFullYear(2022);
      cal.setUTCFullYear(2022);
      expect(cal.toDateString()).assertEqual(checkDate.toDateString());
      done();
    });


    it('setUTCMonth', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCMonth(6);
      cal.setUTCMonth(6);
      expect(cal.toDateString()).assertEqual(checkDate.toDateString());
      done();
    });


    it('setUTCDate', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCDate(10);
      cal.setUTCDate(10);
      expect(cal.toDateString()).assertEqual(checkDate.toDateString());
      done();
    });


    it('setUTCHour', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCHours(10);
      cal.setUTCHours(10);
      expect(cal.getHours()).assertEqual(checkDate.getHours());
      done();
    });


    it('setUTCMinutes', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCMinutes(5);
      cal.setUTCMinutes(5);
      expect(cal.getMinutes()).assertEqual(checkDate.getMinutes());
      done();
    });


    it('setUTCSeconds', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCSeconds(20);
      cal.setUTCSeconds(20);
      expect(cal.getSeconds()).assertEqual(checkDate.getSeconds());
      done();
    });


    it('setUTCMill', 0, async (done: Function) => {
      const cal = new CalendarDate(2024, 4, 1);
      const checkDate = new Date(2024, 4, 1);
      checkDate.setUTCMilliseconds(122);
      cal.setUTCMilliseconds(122);
      expect(cal.getUTCMilliseconds()).assertEqual(checkDate.getUTCMilliseconds());
      done();
    });

    it('getDay_01', 0, () => {
      const date = new CalendarDate(2023, 0, 1);
      expect(date.getDay()).assertEqual(0);
    })

    it('getDay_02', 0, () => {
      const date = new CalendarDate(1582, 0, 1);
      expect(date.getDay()).assertEqual(1);
    })

    it('getDay_03', 0, () => {
      const date = new CalendarDate(1582, 7, 1);
      expect(date.getDay()).assertEqual(3);
    })

    it('getDay_04', 0, () => {
      const date = new CalendarDate(1582, 8, 1);
      expect(date.getDay()).assertEqual(6);
    })

    it('getDay_05', 0, () => {
      const date = new CalendarDate(1582, 9, 1);
      expect(date.getDay()).assertEqual(1);
    })

    it('getDay_06', 0, () => {
      const date = new CalendarDate(1582, 10, 1);
      expect(date.getDay()).assertEqual(1);
    })

    it('setHour_01', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(0, 0, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(0, 0, 0, 0));
    })

    it('setHour_02', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(24, 0, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(24, 0, 0, 0));
    })

    it('setHour_03', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(-10, 0, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(-10, 0, 0, 0));
    })

    it('setMinutes_01', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(0, 60, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(0, 60, 0, 0));
    })

    it('setMinutes_02', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(1, -10, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(1, -10, 0, 0));
    })

    it('setMinutes_03', 0, () => {
      const date = new CalendarDate(2024, 4, 1, 5, 0, 0, 0);
      date.setHours(0, 120, 0, 0)
      expect(date.getTime()).assertEqual(new Date(2024, 4, 1, 5).setHours(0, 120, 0, 0));
    })
  });

}