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
import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';
import { Frequency } from '@app/feature.repeatrule';
import { parseNumber, parseNumberList, parsePartByKey } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';
import { Weeks } from '@app/feature.repeatrule/src/main/ets/Constants';
import { CalendarDate, GlobalThis, I18nUtil } from '@app/common';
import { DAY_OF_WEEK_SHORT_MAP } from '@app/feature.repeatrule/src/main/ets/Constants';

export default function RecurrenceParserTest() {
  describe('RecurrenceParseTest', () => {
    let recurrence: Recurrence;

    beforeEach(() => {
      recurrence = new Recurrence();
    });

    it('emptyRule', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = '';
      recurrence.parse(rrule);
      const formatRrule: string = recurrence.format();
      expect(formatRrule).assertEqual(rrule);
    });

    it('secondly', Level.LEVEL3 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=SECONDLY;WKST=SU;BYSECOND=1';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.SECONDLY);
      expect(recurrence.weekStart).assertDeepEquals(Weeks.SUN);
      expect(recurrence.useBySecond()).assertFalse();
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('minutely', Level.LEVEL3 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MINUTELY;WKST=SU;BYMINUTE=1';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MINUTELY);
      expect(recurrence.weekStart).assertDeepEquals(Weeks.SUN);
      expect(recurrence.useByMinute()).assertFalse();
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('hourly', Level.LEVEL3 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=HOURLY;WKST=SU;BYHOUR=1';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.HOURLY);
      expect(recurrence.weekStart).assertDeepEquals(Weeks.SUN);
      expect(recurrence.useByHour()).assertFalse();
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('setpos', Level.LEVEL3 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;WKST=SU;BYSETPOS=1,3,7,10';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.bySetPos).assertDeepEquals([1, 3, 7, 10]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('normal_freq_daily', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=DAILY;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
      expect(recurrence.weekStart).assertDeepEquals(Weeks.SUN);
      expect(recurrence.byWeekNumCount()).assertEqual(0);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('normal_freq_weekly', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=WEEKLY;WKST=SU;BYDAY=TU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.WEEKLY);
      expect(recurrence.byWeekDay).assertDeepEquals([Weeks.TUE]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('normal_freq_monthly', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;WKST=SU;BYMONTHDAY=20';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.byMonthDay).assertDeepEquals([20]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('normal_freq_yearly', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;INTERVAL=1;WKST=SU;BYMONTHDAY=20;BYMONTH=2';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.byMonthDay).assertDeepEquals([20]);
      expect(recurrence.byMonth).assertDeepEquals([2]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_daily_until', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=DAILY;UNTIL=20240320T153000;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
      expect(recurrence.until).assertEqual('20240320T153000');
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_daily_count', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=DAILY;COUNT=5;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_daily_interval', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=DAILY;INTERVAL=2;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
      expect(recurrence.interval).assertEqual(2);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_weekly_until', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=WEEKLY;UNTIL=20240320T153000;WKST=SU;BYDAY=TU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.WEEKLY);
      expect(recurrence.until).assertEqual('20240320T153000');
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_weekly_count', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=WEEKLY;COUNT=5;WKST=SU;BYDAY=MO,TU,WE';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.WEEKLY);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_weekly_interval', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=WEEKLY;INTERVAL=2;WKST=SU;BYDAY=TH,FR,SA,SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.WEEKLY);
      expect(recurrence.interval).assertEqual(2);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_monthly_until', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;UNTIL=20240320T153000;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.until).assertEqual('20240320T153000');
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_monthly_count', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;COUNT=5;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_monthly_interval', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;INTERVAL=2;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.interval).assertEqual(2);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_monthly_byweekday', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=MONTHLY;WKST=SU;BYDAY=3TU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.byWeekNum).assertDeepEquals([3]);
      expect(recurrence.byWeekNumCount()).assertEqual(1);
      expect(recurrence.byWeekDay).assertDeepEquals([Weeks.TUE]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_yearly_until', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;UNTIL=20270220T153000;INTERVAL=1;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.until).assertEqual('20270220T153000');
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_yearly_count', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;COUNT=5;INTERVAL=1;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_yearly_interval', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;INTERVAL=2;WKST=SU';
      recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.interval).assertEqual(2);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_yearly_byweek', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;WKST=SU;BYDAY=TH,FR;BYWEEKNO=1,2';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.byWeek).assertDeepEquals([1, 2]);
      expect(recurrence.byWeekDay).assertDeepEquals([Weeks.THUR, Weeks.FRI]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('customization_yearly_byyearday', Level.LEVEL1 | TestType.FUNCTION, () => {
      const rrule: string = 'FREQ=YEARLY;WKST=SU;BYYEARDAY=10';
      const recurrence: Recurrence = Recurrence.parse(rrule);
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.byYearDay).assertDeepEquals([10]);
      expect(recurrence.format()).assertEqual(rrule);
    });

    it('abnormalBranch_01', Level.LEVEL3 | TestType.FUNCTION, () => {
      let hasError: boolean = true;
      parsePartByKey(undefined!, undefined!, new Recurrence());
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('abnormalBranch_02', Level.LEVEL3 | TestType.FUNCTION, () => {
      expect(Recurrence.parse('FREQ').format()).assertEqual(';WKST=MO');
    });

    it('abnormalBranch_03', Level.LEVEL3 | TestType.FUNCTION, () => {
      expect(Recurrence.parse('FREQ;;=; =; UNTIL').format()).assertEqual(';WKST=MO');
    });

    it('abnormalBranch_04', Level.LEVEL3 | TestType.FUNCTION, () => {
      expect(new Recurrence().byWeekNumCount()).assertEqual(0);
    });

    it('abnormalBranch_05', Level.LEVEL3 | TestType.FUNCTION, () => {
      const num = parseNumber(undefined!, Number.MIN_VALUE, Number.MAX_VALUE);
      expect(num).assertNull();
    });

    it('abnormalBranch_06', Level.LEVEL3 | TestType.FUNCTION, () => {
      const num = parseNumber('+8', Number.MIN_VALUE, Number.MAX_VALUE);
      expect(num).assertEqual(8);
    });

    it('abnormalBranch_07', Level.LEVEL3 | TestType.FUNCTION, () => {
      const num = parseNumber('0', Number.MIN_VALUE, Number.MAX_VALUE, false);
      expect(num).assertNull();
    });

    it('abnormalBranch_08', Level.LEVEL3 | TestType.FUNCTION, () => {
      const num = parseNumber('a', Number.MIN_VALUE, Number.MAX_VALUE, false);
      expect(num).assertNull();
    });

    it('abnormalBranch_09', Level.LEVEL3 | TestType.FUNCTION, () => {
      let numArr = parseNumberList('', Number.MIN_VALUE, Number.MAX_VALUE);
      expect(numArr.length).assertEqual(0);
    });

    it('abnormalBranch_10', Level.LEVEL3 | TestType.FUNCTION, () => {
      const numArr = parseNumberList('2,4,9,a,b', Number.MIN_VALUE, Number.MAX_VALUE);
      expect(numArr).assertDeepEquals([2, 4, 9]);
    });

    it('nullArray', Level.LEVEL3 | TestType.FUNCTION, () => {
      recurrence.bySecond = null!;
      recurrence.byMinute = null!;
      recurrence.byHour = null!;
      recurrence.byWeekDay = null!;
      recurrence.byWeekNum = null!;
      recurrence.byWeek = null!;
      recurrence.byMonth = null!;
      recurrence.byMonthDay = null!;
      recurrence.byYearDay = null!;
      expect(recurrence.bySecondCount()).assertEqual(0);
      expect(recurrence.byMinuteCount()).assertEqual(0);
      expect(recurrence.byHourCount()).assertEqual(0);
      expect(recurrence.byWeekDayCount()).assertEqual(0);
      expect(recurrence.byWeekNumCount()).assertEqual(0);
      expect(recurrence.byMonthDayCount()).assertEqual(0);
      expect(recurrence.byYearDayCount()).assertEqual(0);
      expect(recurrence.byWeekCount()).assertEqual(0);
      expect(recurrence.byMonthCount()).assertEqual(0);
    });

    it('testReliability', Level.LEVEL2 | TestType.RELIABILITY, () => {
      let hasError: boolean = true;
      parsePartByKey('', '', undefined!);
      parsePartByKey('FREQ', '', undefined!);
      parsePartByKey('UNTIL', '', undefined!);
      parsePartByKey('COUNT', '', undefined!);
      parsePartByKey('INTERVAL', '', undefined!);
      parsePartByKey('BYSECOND', '', undefined!);
      parsePartByKey('BYMINUTE', '', undefined!);
      parsePartByKey('BYHOUR', '', undefined!);
      parsePartByKey('BYDAY', 'TEST,55TU,,', undefined!);
      parsePartByKey('BYMONTHDAY', '', undefined!);
      parsePartByKey('BYYEARDAY', '', undefined!);
      parsePartByKey('BYWEEKNO', '', undefined!);
      parsePartByKey('BYMONTH', '', undefined!);
      parsePartByKey('BYSETPOS', '', undefined!);
      parsePartByKey('WKST', '', undefined!);
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('testUntil', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.freq = Frequency.DAILY;
      expect(recurrence.isCustomFreq()).assertFalse();
      let date = new CalendarDate();
      date.setUTCFullYear(2025, 3, 29);
      date.setUTCHours(10, 30, 0, 0);
      let until = date.getTime();
      recurrence.setUntil(until);
      expect(recurrence.hasUntil()).assertTrue();
      expect(recurrence.until).assertEqual('20250429T103000Z');
      expect(recurrence.isCustomFreq()).assertTrue();
      expect(recurrence.getUntilMills()).assertEqual(until);

    });

    it('testCount', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.freq = Frequency.DAILY;
      expect(recurrence.isCustomFreq()).assertFalse();
      recurrence.setCount(5);
      expect(recurrence.hasCount()).assertTrue();
      expect(recurrence.isCustomFreq()).assertTrue();
    });
    it('testSetToDaily', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setToDaily();
      expect(recurrence.isCustomFreq()).assertFalse();
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
    });
    it('testSetToWeekly', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setToWeekly([Weeks.MON, Weeks.FRI]);
      expect(recurrence.freq).assertEqual(Frequency.WEEKLY);
      expect(recurrence.byWeekDay).assertDeepEquals([Weeks.MON, Weeks.FRI]);
    });
    it('testSetToMonthlyByDay', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setToMonthlyByDay(5);
      expect(recurrence.isCustomFreq()).assertFalse();
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.byMonthDay).assertDeepEquals([5]);
      expect(recurrence.byWeekDay).assertDeepEquals([]);
      expect(recurrence.byWeekNum).assertDeepEquals([]);
    });
    it('testSetToMonthlyByWeek', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setToMonthlyByWeek(2, Weeks.MON);
      expect(recurrence.isCustomFreq()).assertTrue();
      expect(recurrence.freq).assertEqual(Frequency.MONTHLY);
      expect(recurrence.byMonthDay).assertDeepEquals([]);
      expect(recurrence.byWeekDay).assertDeepEquals([Weeks.MON]);
      expect(recurrence.byWeekNum).assertDeepEquals([2]);
    });

    it('testSetToYearly', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setToYearly(2, 5);
      expect(recurrence.isCustomFreq()).assertFalse();
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.byMonth).assertDeepEquals([3]);
      expect(recurrence.byMonthDay).assertDeepEquals([5]);
    });

    it('testSetToLunarYearly', Level.LEVEL2 | TestType.RELIABILITY, () => {
      recurrence.setLunarEvent();
      recurrence.setToLunarYearly(new CalendarDate('2024-07-25T03:00:00.000Z'));
      expect(recurrence.isCustomFreq()).assertFalse();
      expect(recurrence.freq).assertEqual(Frequency.YEARLY);
      expect(recurrence.byMonth).assertDeepEquals([6]);
      expect(recurrence.byMonthDay).assertDeepEquals([20]);
    });
    it('testDeepCopy', Level.LEVEL2 | TestType.RELIABILITY, () => {
      let recurrence1 = new Recurrence();
      recurrence1.setToWeekly([Weeks.MON]);
      let recurrence2 = new Recurrence();
      expect(recurrence2.freq).not().assertDeepEquals(recurrence1.freq);
      expect(recurrence2.byWeekDay).not().assertDeepEquals(recurrence1.byWeekDay);
      recurrence2.deepCopyFrom(recurrence1);
      expect(recurrence2.freq).assertDeepEquals(recurrence1.freq);
      expect(recurrence2.byWeekDay).assertDeepEquals(recurrence1.byWeekDay);
    });
    it('testUpdateBy', Level.LEVEL2 | TestType.RELIABILITY, () => {
      let recurrence1 = new Recurrence();
      recurrence1.setToWeekly([Weeks.MON]);
      let recurrence2 = new Recurrence();
      expect(recurrence2.freq).not().assertDeepEquals(recurrence1.freq);
      expect(recurrence2.byWeekDay).not().assertDeepEquals(recurrence1.byWeekDay);
      recurrence2.updateBy(recurrence1);
      expect(recurrence2.freq).assertDeepEquals(recurrence1.freq);
      expect(recurrence2.byWeekDay).assertDeepEquals(recurrence1.byWeekDay);
    });
    it('toString_test_no_repeat', 0, () => {
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(GlobalThis.getResourceStr(resource))
        .assertEqual(GlobalThis.getResourceStr($r('app.string.no_repeat')));
    });
    it('toString_test_daily', 0, () => {
      recurrence.freq = Frequency.DAILY;
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(GlobalThis.getResourceStr(resource))
        .assertEqual(GlobalThis.getResourceStr($r('app.string.every_day_repeat')));
    });
    it('toString_test_weekly', 0, () => {
      recurrence.freq = Frequency.WEEKLY;
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(resource).assertEqual(GlobalThis.getResourceStr($r('app.string.every_week_repeat')));
    });
    it('toString_test_weekly1', 0, () => {
      let recurrence1 = new Recurrence();
      recurrence1.freq = Frequency.WEEKLY;
      recurrence1.byWeekDay = [Weeks.SUN, Weeks.MON];
      let resource: Resource = (recurrence1.toString() as ResourceStr) as Resource;
      const comma = I18nUtil.getSystemLanguage().includes('ar') ? '،' : '、';
      let resultStr: string = '';
      recurrence1.byWeekDay.forEach((week: Weeks, index: number) => {
        if (index > 0) {
          resultStr += comma;
        }
        resultStr += GlobalThis.getResourceStr(DAY_OF_WEEK_SHORT_MAP.get(week), I18nUtil.getSystemLanguage());
      });
      expect(resource).assertEqual(GlobalThis.getResourceStrParms($r('app.string.every_week_repeat_of'), resultStr));
    });
    it('toString_test_monthly', 0, () => {
      recurrence.freq = Frequency.MONTHLY;
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(GlobalThis.getResourceStr(resource))
        .assertEqual(GlobalThis.getResourceStr($r('app.string.every_month_repeat')));
    });
    it('toString_test_yearly', 0, () => {
      recurrence.freq = Frequency.YEARLY;
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(GlobalThis.getResourceStr(resource))
        .assertEqual(GlobalThis.getResourceStr($r('app.string.every_year_repeat')));
    });
    it('toString_test_lunar_yearly', 0, () => {
      recurrence.freq = Frequency.YEARLY;
      recurrence.setLunarEvent();
      let resource: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(GlobalThis.getResourceStr(resource))
        .assertEqual(GlobalThis.getResourceStr($r('app.string.every_lunar_year_repeat')));
    });
    it('toString_test_isCustomFreq', 0, () => {
      recurrence.freq = Frequency.DAILY;
      recurrence.count = 1;
      recurrence.interval = 1;
      let resource7: Resource = (recurrence.toString() as ResourceStr) as Resource;
      expect(resource7).assertEqual('每天(共 1 次)');
    });
    it('isValidRecurrence_test_01', 0, () => {
      recurrence.interval = 0;
      expect(recurrence.isValidRecurrence()).assertFalse();
    });
    it('isValidRecurrence_test_02', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.DAILY;
      expect(recurrence.isValidRecurrence()).assertTrue();
    });
    it('isValidRecurrence_test_03', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.YEARLY;
      expect(recurrence.isValidRecurrence()).assertTrue();
    });
    it('isValidRecurrence_test_04', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.WEEKLY;
      recurrence.byWeekDay = [];
      expect(recurrence.isValidRecurrence()).assertFalse();
    });
    it('isValidRecurrence_test_05', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.WEEKLY;
      recurrence.byWeekDay = [Weeks.SUN];
      expect(recurrence.isValidRecurrence()).assertTrue();
    });
    it('isValidRecurrence_test_06', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.MONTHLY;
      recurrence.byMonthDay = [];
      recurrence.byWeekDay = [];
      expect(recurrence.isValidRecurrence()).assertFalse();
    });
    it('isValidRecurrence_test_07', 0, () => {
      recurrence.interval = 1;
      recurrence.freq = Frequency.MONTHLY;
      recurrence.byMonthDay = [];
      recurrence.byWeekDay = [Weeks.SUN];
      recurrence.byWeekNum = [3]
      expect(recurrence.isValidRecurrence()).assertTrue();
    });
  });
}