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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium'
import {
  CalendarContract,
  CalendarDate,
  DateUtil, GlobalThis, I18nUtil, IMonthInfo,
  Log,
  MILLS_PER_DAY, MILLS_PER_WEEK,
  SubscriptionCalendar
} from '@app/common/index'
import { i18n } from '@kit.LocalizationKit'
import { timeStringForDisplay } from '@app/common/src/main/ets/util/DateUtil'
import intl from '@ohos.intl';

export default function DateUtilTest() {
  describe('DateUtilTest', () => {
    it('transDateFormatToChineseStyle_01', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 1)).assertEqual('凌晨');
    })

    it('transDateFormatToChineseStyle_02', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 2)).assertEqual('凌晨');
    })

    it('transDateFormatToChineseStyle_03', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 3)).assertEqual('凌晨');
    })

    it('transDateFormatToChineseStyle_04', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 4)).assertEqual('凌晨');
    })

    it('transDateFormatToChineseStyle_05', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 5)).assertEqual('清晨');
    })

    it('transDateFormatToChineseStyle_06', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 6)).assertEqual('清晨');
    })

    it('transDateFormatToChineseStyle_07', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 7)).assertEqual('早上');
    })

    it('transDateFormatToChineseStyle_08', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 8)).assertEqual('早上');
    })

    it('transDateFormatToChineseStyle_09', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 9)).assertEqual('上午');
    })

    it('transDateFormatToChineseStyle_10', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 10)).assertEqual('上午');
    })

    it('transDateFormatToChineseStyle_11', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 11)).assertEqual('中午');
    })

    it('transDateFormatToChineseStyle_12', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 12)).assertEqual('半夜');
    })

    it('transDateFormatToChineseStyle_13', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 1)).assertEqual('下午');
    })

    it('transDateFormatToChineseStyle_14', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 2)).assertEqual('下午');
    })

    it('transDateFormatToChineseStyle_15', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 3)).assertEqual('下午');
    })

    it('transDateFormatToChineseStyle_16', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 4)).assertEqual('下午');
    })

    it('transDateFormatToChineseStyle_17', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 5)).assertEqual('傍晚');
    })

    it('transDateFormatToChineseStyle_18', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 6)).assertEqual('傍晚');
    })

    it('transDateFormatToChineseStyle_19', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 7)).assertEqual('晚上');
    })

    it('transDateFormatToChineseStyle_20', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 8)).assertEqual('晚上');
    })

    it('transDateFormatToChineseStyle_21', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 9)).assertEqual('晚上');
    })

    it('transDateFormatToChineseStyle_22', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 10)).assertEqual('晚上');
    })

    it('transDateFormatToChineseStyle_23', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 11)).assertEqual('半夜');
    })

    it('transDateFormatToChineseStyle_24', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 12)).assertEqual('中午')
    })

    it('transDateFormatToChineseStyle_invalid_01', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('Abc', 1)).assertEqual('');
    })

    it('transDateFormatToChineseStyle_invalid_02', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('上午', 0)).assertEqual('');
    })

    it('transDateFormatToChineseStyle_invalid_03', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', -1)).assertEqual('');
    })

    it('transDateFormatToChineseStyle_invalid_04', 0, () => {
      expect(DateUtil.transDateFormatToChineseStyle('下午', 13)).assertEqual('');
    })

    it('isLeapYear', 0, () => {
      expect(DateUtil.isLeapYear(2000)).assertTrue();
    })

    it('isLeapYear_01', 0, () => {
      expect(DateUtil.isLeapYear(2020)).assertTrue();
    })

    it('isLeapYear_02', 0, () => {
      expect(DateUtil.isLeapYear(2400)).assertTrue();
    })

    it('isLeapYear_03', 0, () => {
      expect(DateUtil.isLeapYear(1900)).assertFalse();
    })

    it('isLeapYear_04', 0, () => {
      expect(DateUtil.isLeapYear(2100)).assertFalse();
    })

    it('isLeapYear_05', 0, () => {
      expect(DateUtil.isLeapYear(2300)).assertFalse();
    })

    it('getMaxDayInMonth_1', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 1)).assertEqual(31);
    })

    it('getMaxDayInMonth_2', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 2)).assertEqual(28);
    })

    it('getMaxDayInMonth_3', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 3)).assertEqual(31);
    })

    it('getMaxDayInMonth_4', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 4)).assertEqual(30);
    })

    it('getMaxDayInMonth_5', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 5)).assertEqual(31);
    })

    it('getMaxDayInMonth_6', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 6)).assertEqual(30);
    })

    it('getMaxDayInMonth_7', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 7)).assertEqual(31);
    })

    it('getMaxDayInMonth_8', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 8)).assertEqual(31);
    })

    it('getMaxDayInMonth_9', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 9)).assertEqual(30);
    })

    it('getMaxDayInMonth_10', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 10)).assertEqual(31);
    })

    it('getMaxDayInMonth_11', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 11)).assertEqual(30);
    })

    it('getMaxDayInMonth_12', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 12)).assertEqual(31);
    })

    it('getMaxDayInMonth_leapYear', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2020, 2)).assertEqual(29);
    })

    it('getMaxDayInMonth_invalidMonth', 0, () => {
      expect(DateUtil.getMaxDayInMonth(2022, 1)).assertEqual(31);
      expect(DateUtil.getMaxDayInMonth(2022, 2)).assertEqual(28);
    })

    it('getEndMillsOfDate_valid', 0, () => {
      const date = new CalendarDate(2022, 1, 1);
      const expected = new CalendarDate(2022, 1, 2).getTime() - 1;
      expect(DateUtil.getEndMillsOfDate(date)).assertEqual(expected);
    })

    it('getStartMillsOfDate_valid', 0, () => {
      const date = new CalendarDate(2022, 1, 1, 12, 30, 0);
      const expected = new CalendarDate(2022, 1, 1).getTime();
      expect(DateUtil.getStartMillsOfDate(date)).assertEqual(expected);
    })

    // 获取某一天的年、月、日组成的 Date 对象，即某一天的开始时间
    it('getStartOfDay', 0, () => {
      const date = new CalendarDate(2024, 3, 17, 15, 28, 59, 0); // 2024/4/17 15:28:59
      const result = DateUtil.getStartOfDay(date);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getMonth()).assertEqual(3);
      expect(result.getDate()).assertEqual(17);
      expect(result.getHours()).assertEqual(0);
      expect(result.getMinutes()).assertEqual(0);
      expect(result.getSeconds()).assertEqual(0);
    })

    it('lunarDateString_no_this_year', 0, () => {
      const date = new CalendarDate(2022, 1, 1, 12, 30, 0);
      expect(DateUtil.lunarDateString(date)).assertEqual('2022壬寅虎年正月初一 星期二');
    })

    it('lunarDateString_this_year', 0, () => {
      const date = new CalendarDate(2025, 1, 1, 12, 30, 0);
      expect(DateUtil.lunarDateString(date)).assertEqual('正月初四 星期六');
    })

    it('getStartOfDayTimeStamp_no_param', 0, () => {
      let result = DateUtil.getStartOfDayTimeStamp();
      let date = new CalendarDate();
      let expected = new CalendarDate(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
      expect(result).assertEqual(expected);
    });

    it('getStartOfDayTimeStamp_with_param', 0, () => {
      let date = new CalendarDate();
      let dateStamp = new CalendarDate().getTime();
      let result = DateUtil.getStartOfDayTimeStamp(dateStamp);
      let expected = new CalendarDate(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
      expect(result).assertEqual(expected);
    });

    it('isSameDay_01', 0, () => {
      let date1 = new CalendarDate();
      let date2 = new CalendarDate();
      expect(DateUtil.isSameDay(date1, date2)).assertTrue()
    });

    it('isSameDay_02', 0, () => {
      let date1 = new CalendarDate(2024, 1, 1);
      let date2 = new CalendarDate(2024, 1, 2);
      expect(DateUtil.isSameDay(date1, date2)).assertFalse()
    });

    it('isSameDay_03', 0, () => {
      let date1 = new CalendarDate(2024, 1, 1, 12);
      let date2 = new CalendarDate(2024, 1, 1, 13);
      expect(DateUtil.isSameDay(date1, date2)).assertTrue()
    });

    it('isSameDayTimeStamp_01', 0, () => {
      CalendarDate.timeZone='Australia/Adelaide';
      expect(DateUtil.isSameDayTimeStamp(1742999400000, 1743003000000)).assertTrue();
    });

    it('isSameDayTimeStamp_02', 0, () => {
      CalendarDate.timeZone='Australia/Adelaide';
      expect(DateUtil.isSameDayTimeStamp(1743077300000, 1743187400000)).assertFalse();
    });

    it('dateToStamp', 0, () => {
      CalendarDate.timeZone = I18nUtil.getSystemTimeZone();
      let date = new CalendarDate();
      let dateStamp = date.getTime();
      let result = DateUtil.dateToStamp(date.getFullYear(), date.getMonth(), date.getDate());
      let expected = DateUtil.getStartOfDayTimeStamp(dateStamp);
      expect(result).assertEqual(expected);
    });

    it('dateToStamp2', 0, () => {
      let date = new CalendarDate(1582, 9, 4);
      let date2 = new CalendarDate(1582, 9, 15);
      let result1 = DateUtil.dateToStamp(date.getFullYear(), date.getMonth(), date.getDate());
      let result2 = DateUtil.dateToStamp(date2.getFullYear(), date2.getMonth(), date2.getDate());
      expect(result1 + MILLS_PER_DAY).assertEqual(result2);
    });

    it('dateToStampByDaylightSaving', 0, () => {
      let date1 = new CalendarDate(1990, 4, 15);
      let result1 = DateUtil.dateToStamp(date1.getFullYear(), date1.getMonth(), date1.getDate());
      expect(result1).assertEqual(date1.setHours(0, 0, 0, 0));
    });

    it('dateToStampByDaylightSaving1', 0, () => {
      let date2 = new CalendarDate(1991, 5, 15);
      let result2 = DateUtil.dateToStamp(date2.getFullYear(), date2.getMonth(), date2.getDate());
      expect(result2).assertEqual(date2.setHours(0, 0, 0, 0));
    });

    it('dateToStampByDaylightSaving2', 0, () => {
      let date3 = new CalendarDate(1992, 7, 15);
      let result3 = DateUtil.dateToStamp(date3.getFullYear(), date3.getMonth(), date3.getDate());
      expect(result3).assertEqual(date3.setHours(0, 0, 0, 0));
    });

    it('date2julianDay', 0, () => {
      const julianDay = DateUtil.date2julianDay(2021, 10, 15);
      let date = DateUtil.julianDay2Date(julianDay);
      expect(date.getFullYear()).assertEqual(2021);
      expect(date.getMonth()).assertEqual(9); // 需要 -1
      expect(date.getDate()).assertEqual(15);
    });

    it('date2julianDay_01', 0, () => {
      const julianDay = DateUtil.date2julianDay(2021, 2, 15);
      let date = DateUtil.julianDay2Date(julianDay);
      expect(date.getFullYear()).assertEqual(2021);
      expect(date.getMonth()).assertEqual(1);
      expect(date.getDate()).assertEqual(15);
    });

    it('julianDay2Date', 0, () => {
      let tempDate = new CalendarDate(2021, 10, 15);
      const julianDay = tempDate.getJulianDay();
      let date = DateUtil.julianDay2Date(julianDay);
      expect(date.getFullYear()).assertEqual(tempDate.getFullYear());
      expect(date.getMonth()).assertEqual(tempDate.getMonth());
      expect(date.getDate()).assertEqual(tempDate.getDate());
    });

    it('GetDateTime_Test', 0, () => {
      const currentTime = new CalendarDate(2024,5,29).getTime();
      const nowDate = new CalendarDate(2024,5,29);
      expect(DateUtil.getDateTime(nowDate, 'zh-CN', currentTime)).assertEqual('今天');
      expect(DateUtil.getDateTime(nowDate, 'en-Test', currentTime)).assertEqual('今天');
      const nowDate2 = new CalendarDate(2024,5,28);
      expect(DateUtil.getDateTime(nowDate2, 'zh-CN', currentTime)).assertEqual('昨天');
      expect(DateUtil.getDateTime(nowDate2, 'en-Test', currentTime)).assertEqual('昨天');
      const nowDate3 = new CalendarDate(2024,5,30);
      expect(DateUtil.getDateTime(nowDate3, 'zh-CN', currentTime)).assertEqual('明天');
      expect(DateUtil.getDateTime(nowDate3, 'en-Test', currentTime)).assertEqual('明天');
      const nowDate4 = new CalendarDate(2024,5,27);
      expect(DateUtil.getDateTime(nowDate4, 'zh-CN', currentTime)).assertEqual('前天');
      expect(DateUtil.getDateTime(nowDate4, 'en-Test', currentTime)).assertEqual('2 天前');
      const nowDate5 = new CalendarDate(2024,6,1);
      expect(DateUtil.getDateTime(nowDate5, 'zh-CN', currentTime)).assertEqual('后天');
      expect(DateUtil.getDateTime(nowDate5, 'en-Test', currentTime)).assertEqual('2 天后');
    });

    it('GetCalendarTime_Test', 0, () => {
      const nowDate = new CalendarDate(2024,5,29);
      expect(DateUtil.getCalendarTime(nowDate, SubscriptionCalendar.NO_CALENDAR, 'CN')).assertEqual('');
      expect(DateUtil.getCalendarTime(nowDate, SubscriptionCalendar.CHINESE_CALENDAR, 'CN'))
        .assertEqual('农历五月廿四');
      expect(DateUtil.getCalendarTime(nowDate, SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR, 'CN'))
        .assertEqual('伊斯兰希吉来日历1445年12月22日');
      const nowDate2 = new CalendarDate(1890,5,28);
      expect(DateUtil.getCalendarTime(nowDate2, SubscriptionCalendar.CHINESE_CALENDAR, 'CN'))
        .assertEqual('');
    });

    it('CheckEnglishForStr_Test', 0, () => {
      expect(DateUtil.checkEnglishForStr('zh-CN', $r('app.plural.days_ago'), $r('app.string.yesterday'), 1)).assertEqual('昨天');
      expect(DateUtil.checkEnglishForStr('en-Test', $r('app.plural.days_ago'), $r('app.string.yesterday'), 1)).assertEqual('1 天前');
    });


    it('getDefaultStartOfWeek_should_return_the_correct_start_of_week_for_a_locale_with_Sunday_as_the_first_day_of_the_week', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockI18nUtil: ESObject = mocker.mockFunc(I18nUtil, I18nUtil.getCalendar);
      let mockIntlCalendar: ESObject = { getFirstDayOfWeek: () => 1 };
      when(mockI18nUtil)(ArgumentMatchers.any).afterReturn(mockIntlCalendar);
      const result: ESObject = DateUtil.getDefaultStartOfWeek();
      expect(result).assertEqual(0);
      mocker.ignoreMock(I18nUtil, I18nUtil.getCalendar);
      done();
    });

    it('getDefaultStartOfWeek_should_return_the_correct_start_of_week_for_a_locale_with_Monday_as_the_first_day_of_the_week', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockI18nUtil: ESObject = mocker.mockFunc(I18nUtil, I18nUtil.getCalendar);
      let mockIntlCalendar: ESObject = { getFirstDayOfWeek: () => 2 };
      when(mockI18nUtil)(ArgumentMatchers.any).afterReturn(mockIntlCalendar);
      const result: ESObject = DateUtil.getDefaultStartOfWeek();
      expect(result).assertEqual(1);
      mocker.ignoreMock(I18nUtil, I18nUtil.getCalendar);
      done();
    });

  })

  describe('Get_Offset_MonthInfo_Test', () => {
    it('Get_Offset_MonthInfo_1', 0, () => {
      let curMonth: IMonthInfo = {
        year: 2100,
        month: 11
      }
      const nextMonth = DateUtil.getOffsetMonthInfo(curMonth, 1);
      expect(nextMonth.year).assertEqual(2101);
      expect(nextMonth.month).assertEqual(0);
    })

    it('Get_Offset_MonthInfo_2', 0, () => {
      let curMonth: IMonthInfo = {
        year: 2100,
        month: 0
      }
      const lastMonth = DateUtil.getOffsetMonthInfo(curMonth, -1);
      expect(lastMonth.year).assertEqual(2099);
      expect(lastMonth.month).assertEqual(11);
    })

    it('Get_Offset_MonthInfo_3', 0, () => {
      let curMonth: IMonthInfo = {
        year: 1900,
        month: 11
      }
      const nextMonth = DateUtil.getOffsetMonthInfo(curMonth, 1);
      expect(nextMonth.year).assertEqual(1901);
      expect(nextMonth.month).assertEqual(0);
    })

    it('Get_Offset_MonthInfo_4', 0, () => {
      let curMonth: IMonthInfo = {
        year: 1900,
        month: 0
      }
      const lastMonth = DateUtil.getOffsetMonthInfo(curMonth, -1);
      expect(lastMonth.year).assertEqual(1899);
      expect(lastMonth.month).assertEqual(11);
    })

    it('Get_Offset_MonthInfo_5', 0, () => {
      let curMonth: IMonthInfo = {
        year: 2100,
        month: 12
      }
      const nextMonth = DateUtil.getOffsetMonthInfo(curMonth, 1);
      expect(nextMonth.year).assertEqual(2101);
      expect(nextMonth.month).assertEqual(1);
    })

    it('Get_Offset_MonthInfo_6', 0, () => {
      let curMonth: IMonthInfo = {
        year: 1900,
        month: -1
      }
      const lastMonth = DateUtil.getOffsetMonthInfo(curMonth, -1);
      expect(lastMonth.year).assertEqual(1899);
      expect(lastMonth.month).assertEqual(10);
    })
  })


  describe('formatTimeDistanceFromNow', () => {
    const date = new CalendarDate();
    it('in_24hour', 0, () => {
      const inputTime = new CalendarDate(date.getTime());
      const result = DateUtil.formatTimeDistanceFromNow(inputTime);
      expect(result).assertEqual(
        inputTime.toLocaleTimeString('en-GB', {
          hour: '2-digit', minute: '2-digit'
        }));
    });

    it('in_24_48hour', 0, () => {
      const inputTime = new CalendarDate(date.getTime() - MILLS_PER_DAY);
      const result = DateUtil.formatTimeDistanceFromNow(inputTime);
      expect(result).assertEqual('昨天');
    });

    it('over_48hour', 0, () => {
      const inputTime = new CalendarDate(date.getTime() - MILLS_PER_DAY * 3);
      const result = DateUtil.formatTimeDistanceFromNow(inputTime);
      const week = inputTime.getDay();
      let expectStr = GlobalThis.getResourceStr(timeStringForDisplay[week]);
      expect(result).assertEqual(expectStr);
    });

    // 超过一周，但在当年内，显示xx月xx日
    it('over_one_week', 0, () => {
      const inputTime = new CalendarDate(date.getTime() - MILLS_PER_WEEK * 2);
      const lang: string = i18n.System.getSystemLanguage();
      const result = DateUtil.formatTimeDistanceFromNow(inputTime);
      let locale: string = 'zh-CN';
      let locale_month: "numeric" | "2-digit" | "long" | "short" | "narrow" | undefined = 'long';
      if (lang === 'en-Latn-US') {
        locale = 'en-US';
        locale_month = 'numeric';
      }
      if (inputTime.getFullYear() !== date.getFullYear()) {
        expect(result).assertEqual(inputTime.toLocaleDateString(locale, {
          year: 'numeric', month: locale_month, day: 'numeric'
        }));
      } else { // 不在当年内
        expect(result).assertEqual(inputTime.toLocaleDateString(locale, {
          month: locale_month, day: 'numeric'
        }));
      }
    });

    // 超过当年，显示xx年xx月xx日
    it('over_one_year', 0, () => {
      const inputTime = new CalendarDate(date.getTime() - 2 * 365 * MILLS_PER_DAY);
      const result = DateUtil.formatTimeDistanceFromNow(inputTime);
      expect(result).assertEqual(inputTime.toLocaleDateString('zh-CN', {
        year: 'numeric', month: 'long', day: 'numeric'
      }));
    })
  })
  describe('GetStartDateByCombine', () => {
    it('Get_Start_Date_1', 0, () => {
      const inputTime = new CalendarDate('2024-04-28 17:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 1);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getHours()).assertEqual(17);
      expect(result.getMinutes()).assertEqual(30);
    });
    it('Get_Start_Date_2', 0, () => {
      const inputTime = new CalendarDate('2024-04-28 17:22').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 1);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getHours()).assertEqual(17);
      expect(result.getMinutes()).assertEqual(0);
    });
    it('Get_Start_Date_3', 0, () => {
      const inputTime = new CalendarDate('2024-04-28 00:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 1);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getHours()).assertEqual(0);
      expect(result.getMinutes()).assertEqual(30);
    });
    it('Get_Start_Date_4', 0, () => {
      const inputTime = new CalendarDate('2024-04-28 23:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 1);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getHours()).assertEqual(23);
      expect(result.getMinutes()).assertEqual(30);
    });
    it('Get_Start_Date_5', 0, () => {
      const inputTime = new CalendarDate('2024-04-28 11:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 1);
      expect(result.getFullYear()).assertEqual(2024);
      expect(result.getHours()).assertEqual(11);
      expect(result.getMinutes()).assertEqual(30);
    });

    it('Get_Start_Date_Off_1', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 17:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 0);
      const curDate = new CalendarDate();
      expect(result.getFullYear()).assertEqual(curDate.getFullYear());
      expect(result.getMonth()).assertEqual(11);
      expect(result.getHours()).assertEqual(curDate.getMinutes() > 30 ? curDate.getHours() + 1 : curDate.getHours());
      expect(result.getMinutes()).assertEqual(curDate.getMinutes() > 30 ? 0 : 30);
    });
    it('Get_Start_Date_Off_2', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 17:22').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 0);
      const curDate = new CalendarDate();
      expect(result.getFullYear()).assertEqual(curDate.getFullYear());
      expect(result.getMonth()).assertEqual(11);
      expect(result.getHours()).assertEqual(curDate.getMinutes() > 30 ? curDate.getHours() + 1 : curDate.getHours());
      expect(result.getMinutes()).assertEqual(curDate.getMinutes() > 30 ? 0 : 30);
    });
    it('Get_Start_Date_Off_3', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 00:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 0);
      const curDate = new CalendarDate();
      expect(result.getFullYear()).assertEqual(curDate.getFullYear());
      expect(result.getMonth()).assertEqual(11);
      expect(result.getHours()).assertEqual(curDate.getMinutes() > 30 ? curDate.getHours() + 1 : curDate.getHours());
      expect(result.getMinutes()).assertEqual(curDate.getMinutes() > 30 ? 0 : 30);
    });
    it('Get_Start_Date_Off_4', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 23:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 0);
      const curDate = new CalendarDate();
      expect(result.getFullYear()).assertEqual(curDate.getFullYear());
      expect(result.getMonth()).assertEqual(11);
      expect(result.getHours()).assertEqual(curDate.getMinutes() > 30 ? curDate.getHours() + 1 : curDate.getHours());
      expect(result.getMinutes()).assertEqual(curDate.getMinutes() > 30 ? 0 : 30);
    });
    it('Get_Start_Date_Off_5', 0, () => {
      const inputTime = new CalendarDate('2025-12-31 11:42').getTime();
      const result = DateUtil.getStartDateByCombine(inputTime, 0);
      const curDate = new CalendarDate();
      expect(result.getFullYear()).assertEqual(curDate.getFullYear());
      expect(result.getMonth()).assertEqual(11);
      expect(result.getHours()).assertEqual(curDate.getMinutes() > 30 ? curDate.getHours() + 1 : curDate.getHours());
      expect(result.getMinutes()).assertEqual(curDate.getMinutes() > 30 ? 0 : 30);
    });

    it('getDayOffsetFromToday', 0, () => {
      let current = new CalendarDate().setHours(0, 0, 0, 0);
      for (let offset = -30; offset < 30; offset++) {
        expect(DateUtil.getDayOffsetFromToday(current + offset * (MILLS_PER_DAY))).assertEqual(Math.abs(offset) - 1);
      }
    });

    it('dateFormatUTC', 0, () => {
      expect(DateUtil.dateFormatUTC(new Date(2025,5,2), 'YYYY-MM-dd')).assertEqual('2025-06-01');
      expect(DateUtil.dateFormatUTC(new Date(2026,10,1), 'YYYY-MM-dd')).assertEqual('2026-10-31');
      expect(DateUtil.dateFormatUTC(new Date(2025,5,1), 'YYYY-MM')).assertEqual('2025-05');
    });
  })

  describe('judgmentDateDisplay', () => {
    it('over_a_year', 0, () => {
      const obj1: intl.DateTimeOptions = DateUtil.judgmentDateDisplay(new CalendarDate(2024, 0, 1)); // 2024年1月1日
      expect(JSON.stringify(obj1)).assertEqual(JSON.stringify({
        year: 'numeric', month: 'short', day: 'numeric'
      }))
    })
    it('less_than_year', 0, () => {
      const obj1: intl.DateTimeOptions = DateUtil.judgmentDateDisplay(new CalendarDate()); // 今天
      expect(JSON.stringify(obj1)).assertEqual(JSON.stringify({
        month: 'short', day: 'numeric'
      }))
    })

    it('date_format_range_test1', 0, () => {
      const startTimeStamp = new CalendarDate(2025, 8, 8).getTime(); // 1757260800000
      const endTimeStamp = new CalendarDate(2026, 0, 25).getTime(); // 1769270400000
      expect(DateUtil.formatRange(startTimeStamp, endTimeStamp)).assertEqual('2025/9/8 – 2026/1/25');
    });
  })
}