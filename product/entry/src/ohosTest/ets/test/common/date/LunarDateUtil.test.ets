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
import { LunarDateUtil } from '@app/common/src/main/ets/date/LunarDateUtil';
import { describe, expect, it } from '@ohos/hypium';
import { CalendarDate, DateManager, DayData } from '@app/common/index';

const TAG: string = 'LunarDateUtil';

export default function LunarDateUtilTest() {
  describe('LunarDateUtilTest', () => {
    const YEAR_START_2025 = new CalendarDate('2025-01-29 00:00:00').getTime();
    const YEAR_START_2026 = new CalendarDate('2026-02-17 00:00:00').getTime();

    it('getLunarDate_no_this_year', 0, () => {
      const date = new CalendarDate(2022, 1, 1, 12, 30, 0);
      expect(LunarDateUtil.getLunarDate(date)).assertEqual('2022壬寅虎年正月初一');
    })

    it('getLunarDate_this_year', 0, () => {
      const date = new CalendarDate(2025, 2, 4, 12, 30, 0);
      if (new Date().getTime() < YEAR_START_2025 || new Date().getTime() >= YEAR_START_2026) {
        expect(LunarDateUtil.getLunarDate(date)).assertEqual('2025乙巳蛇年二月初五');
      } else {
        expect(LunarDateUtil.getLunarDate(date)).assertEqual('二月初五');
      }
    })

    it('getLunarDate_leap_month', 0, () => {
      const date = new CalendarDate('2025-07-25T03:00:00.000Z');
      if (new Date().getTime() < YEAR_START_2025 || new Date().getTime() >= YEAR_START_2026) {
        expect(LunarDateUtil.getLunarDate(date)).assertEqual('2025乙巳蛇年闰六月初一');
      } else {
        expect(LunarDateUtil.getLunarDate(date)).assertEqual('闰六月初一');
      }
    })

    it('getChineseYearReal', 0, () => {
      expect(LunarDateUtil.getChineseYearReal(2023)).assertEqual('癸卯兔年');
      expect(LunarDateUtil.getChineseYearReal(2002)).assertEqual('壬午马年');
    })

    it('getChineseYearReal_isCard', 0, () => {
      expect(LunarDateUtil.getChineseYearReal(2023, undefined, true)).assertEqual('癸卯兔年');
      expect(LunarDateUtil.getChineseYearReal(2002, undefined, true)).assertEqual('壬午马年');
    })

    it('getLunarYear1', 0, () => {
      expect(LunarDateUtil.getLunarYear(new CalendarDate('2022-01-01T03:00:00.000Z'))).assertEqual(2021);
      expect(LunarDateUtil.getLunarYear(new CalendarDate('2021-01-01T03:00:00.000Z'))).assertEqual(2020);
      expect(LunarDateUtil.getLunarYear(new CalendarDate('1920-02-19T03:00:00.000Z'))).assertEqual(1919);
      expect(LunarDateUtil.getLunarYear(new CalendarDate('1985-02-19T03:00:00.000Z'))).assertEqual(1984);
    })

    it('getLunarYear2', 0, () => {
      let date: CalendarDate = new CalendarDate();
      date.setFullYear(2015);
      date.setMonth(0);
      date.setDate(11);
      expect(LunarDateUtil.getLunarYear(date)).assertEqual(2014);
      date.setFullYear(2024);
      date.setMonth(1);
      date.setDate(9);
      expect(LunarDateUtil.getLunarYear(date)).assertEqual(2023);
    })

    it('getChineseMonth_01', 0, () => {
      expect(LunarDateUtil.getChineseMonth(1)).assertEqual('正月');
    })

    it('getChineseMonth_02', 0, () => {
      expect(LunarDateUtil.getChineseMonth(2)).assertEqual('二月');
    })

    it('getChineseMonth_03', 0, () => {
      expect(LunarDateUtil.getChineseMonth(3)).assertEqual('三月');
    })

    it('getChineseMonth_04', 0, () => {
      expect(LunarDateUtil.getChineseMonth(4)).assertEqual('四月');
    })

    it('getChineseMonth_05', 0, () => {
      expect(LunarDateUtil.getChineseMonth(5)).assertEqual('五月');
    })

    it('getChineseMonth_06', 0, () => {
      expect(LunarDateUtil.getChineseMonth(6)).assertEqual('六月');
    })

    it('getChineseMonth_07', 0, () => {
      expect(LunarDateUtil.getChineseMonth(7)).assertEqual('七月');
    })

    it('getChineseMonth_08', 0, () => {
      expect(LunarDateUtil.getChineseMonth(8)).assertEqual('八月');
    })

    it('getChineseMonth_09', 0, () => {
      expect(LunarDateUtil.getChineseMonth(9)).assertEqual('九月');
    })

    it('getChineseMonth_10', 0, () => {
      expect(LunarDateUtil.getChineseMonth(10)).assertEqual('十月');
    })

    it('getChineseMonth_11', 0, () => {
      expect(LunarDateUtil.getChineseMonth(11)).assertEqual('冬月');
    })

    it('getChineseMonth_12', 0, () => {
      expect(LunarDateUtil.getChineseMonth(12)).assertEqual('腊月');
    })

    it('getChineseMonth_13', 0, () => {
      expect(LunarDateUtil.getChineseMonth(13)).assertEqual('闰正月');
    })

    it('getChineseMonth_14', 0, () => {
      expect(LunarDateUtil.getChineseMonth(14)).assertEqual('闰二月');
    })

    it('getChineseMonth_15', 0, () => {
      expect(LunarDateUtil.getChineseMonth(15)).assertEqual('闰三月');
    })

    it('getChineseMonth_16', 0, () => {
      expect(LunarDateUtil.getChineseMonth(16)).assertEqual('闰四月');
    })

    it('getChineseMonth_17', 0, () => {
      expect(LunarDateUtil.getChineseMonth(17)).assertEqual('闰五月');
    })

    it('getChineseMonth_18', 0, () => {
      expect(LunarDateUtil.getChineseMonth(18)).assertEqual('闰六月');
    })

    it('getChineseMonth_19', 0, () => {
      expect(LunarDateUtil.getChineseMonth(19)).assertEqual('闰七月');
    })

    it('getChineseMonth_20', 0, () => {
      expect(LunarDateUtil.getChineseMonth(20)).assertEqual('闰八月');
    })

    it('getChineseMonth_21', 0, () => {
      expect(LunarDateUtil.getChineseMonth(21)).assertEqual('闰九月');
    })

    it('getChineseMonth_22', 0, () => {
      expect(LunarDateUtil.getChineseMonth(22)).assertEqual('闰十月');
    })

    it('getChineseMonth_23', 0, () => {
      expect(LunarDateUtil.getChineseMonth(23)).assertEqual('闰冬月');
    })

    it('getChineseMonth_24', 0, () => {
      expect(LunarDateUtil.getChineseMonth(24)).assertEqual('闰腊月');
    })

    it('getChineseMonth_invalid_1', 0, () => {
      expect(LunarDateUtil.getChineseMonth(-1)).assertEqual('');
    })

    it('getChineseMonth_invalid_2', 0, () => {
      expect(LunarDateUtil.getChineseMonth(25)).assertEqual('');
    })

    it('getChineseMonth_isCard_01', 0, () => {
      expect(LunarDateUtil.getChineseMonth(1, undefined, true)).assertEqual('正月');
    })

    it('getChineseMonth_isCard_12', 0, () => {
      expect(LunarDateUtil.getChineseMonth(12, undefined, true)).assertEqual('腊月');
    })

    it('getChineseMonth_isCard_invalid_3', 0, () => {
      expect(LunarDateUtil.getChineseMonth(13, undefined, true)).assertEqual('闰正月');
    })

    it('getChineseMonth_isCard_invalid_4', 0, () => {
      expect(LunarDateUtil.getChineseMonth(24, undefined, true)).assertEqual('闰腊月');
    })

    it('getChineseMonth_isCard_invalid_5', 0, () => {
      expect(LunarDateUtil.getChineseMonth(25, undefined, true)).assertEqual('');
    })

    it('getChineseMonth_invalid_3', 0, () => {
      expect(LunarDateUtil.getChineseMonth(0)).assertEqual('');
    })

    it('getChineseNum_01', 0, () => {
      expect(LunarDateUtil.getChineseNum(1)).assertEqual('一');
    })

    it('getChineseNum_02', 0, () => {
      expect(LunarDateUtil.getChineseNum(12)).assertEqual('十二');
    })

    it('getChineseNum_03', 0, () => {
      expect(LunarDateUtil.getChineseNum(22)).assertEqual('廿二');
    })

    it('getChineseNum_04', 0, () => {
      expect(LunarDateUtil.getChineseNum(30)).assertEqual('三十');
    })

    it('getChineseNum_05', 0, () => {
      expect(LunarDateUtil.getChineseNum(31)).assertEqual('三十一');
    })

    it('getChineseHeavenlyEarthly', 0, () => {
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2020)).assertEqual('庚子');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2021)).assertEqual('辛丑');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2022)).assertEqual('壬寅');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2023)).assertEqual('癸卯');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2024)).assertEqual('甲辰');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2025)).assertEqual('乙巳');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2026)).assertEqual('丙午');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2027)).assertEqual('丁未');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2028)).assertEqual('戊申');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2029)).assertEqual('己酉');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2030)).assertEqual('庚戌');
      expect(LunarDateUtil.getChineseHeavenlyEarthly(2031)).assertEqual('辛亥');
    })

    it('getZodiac_01', 0, () => {
      expect(LunarDateUtil.getZodiac(2020)).assertEqual('鼠');
    })

    it('getZodiac_02', 0, () => {
      expect(LunarDateUtil.getZodiac(2021)).assertEqual('牛');
    })

    it('getZodiac_03', 0, () => {
      expect(LunarDateUtil.getZodiac(2022)).assertEqual('虎');
    })

    it('getZodiac_04', 0, () => {
      expect(LunarDateUtil.getZodiac(2023)).assertEqual('兔');
    })

    it('getZodiac_05', 0, () => {
      expect(LunarDateUtil.getZodiac(2024)).assertEqual('龙');
    })

    it('getZodiac_06', 0, () => {
      expect(LunarDateUtil.getZodiac(2025)).assertEqual('蛇');
    })

    it('getZodiac_07', 0, () => {
      expect(LunarDateUtil.getZodiac(2026)).assertEqual('马');
    })

    it('getZodiac_08', 0, () => {
      expect(LunarDateUtil.getZodiac(2027)).assertEqual('羊');
    })

    it('getZodiac_09', 0, () => {
      expect(LunarDateUtil.getZodiac(2028)).assertEqual('猴');
    })

    it('getZodiac_10', 0, () => {
      expect(LunarDateUtil.getZodiac(2029)).assertEqual('鸡');
    })

    it('getZodiac_11', 0, () => {
      expect(LunarDateUtil.getZodiac(2030)).assertEqual('狗');
    })

    it('getZodiac_12', 0, () => {
      expect(LunarDateUtil.getZodiac(2031)).assertEqual('猪');
    })

    it('toLunarDateString_not_now_year', 0, () => {
      expect(LunarDateUtil.toLunarDateString(new CalendarDate(2022, 3, 1))).assertEqual('2022壬寅虎年三月初一');
    })

    // 此接口受当前年份影响, 可能需要更新
    it('toLunarDateString_now_year', 0, () => {
      let now = new CalendarDate();
      expect(LunarDateUtil.toLunarDateString(new CalendarDate(now.getFullYear(), 3, 1))).assertEqual('三月初四');
    })

    it('toLunarDateString_isCard_not_now_year', 0, () => {
      expect(LunarDateUtil.toLunarDateString(new CalendarDate(2022, 3, 1), undefined, true)).assertEqual('2022壬寅虎年三月初一');
    })

    it('toLunarDateString_isCard_now_year', 0, () => {
      let now = new CalendarDate();
      expect(LunarDateUtil.toLunarDateString(new CalendarDate(now.getFullYear(), 3, 1), undefined, true)).assertEqual('三月初四');
    })

    it('toFullLunarDateString_leap_month', 0, () => {
      expect(LunarDateUtil.toFullLunarDateString(new CalendarDate('2025-07-25T03:00:00.000Z'))).assertEqual('农历闰六月初一');
    })

    it('toFullLunarDateString', 0, () => {
      expect(LunarDateUtil.toFullLunarDateString(new CalendarDate('2024-07-25T03:00:00.000Z'))).assertEqual('农历六月二十');
    })

    it('getChineseDay', 0, () => {
      expect(LunarDateUtil.getChineseDay(4)).assertEqual('初四');
      expect(LunarDateUtil.getChineseDay(14)).assertEqual('十四');
      expect(LunarDateUtil.getChineseDay(24)).assertEqual('廿四');
    })

    it('getChineseDay_isCard', 0, () => {
      expect(LunarDateUtil.getChineseDay(4, undefined, true)).assertEqual('初四');
      expect(LunarDateUtil.getChineseDay(14, undefined, true)).assertEqual('十四');
      expect(LunarDateUtil.getChineseDay(24, undefined, true)).assertEqual('廿四');
    })

    it('parseLeapLunaMonth_leapMonth', 0, () => {
      const date = new CalendarDate('2025-07-25T03:00:00.000Z');
      const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
        date.getMonth() + 1, date.getDate()) as DayData;
      expect(LunarDateUtil.parseLeapLunaMonth(chineseDate)).assertEqual('闰六月');
    })

    it('parseLeapLunaMonth', 0, () => {
      const date = new CalendarDate('2024-07-25T03:00:00.000Z');
      const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
        date.getMonth() + 1, date.getDate()) as DayData;
      expect(LunarDateUtil.parseLeapLunaMonth(chineseDate)).assertEqual('二十');
    })

    it('parseLeapLunaMonth_firstDay', 0, () => {
      const date = new CalendarDate('2024-06-06T03:00:00.000Z');
      const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
        date.getMonth() + 1, date.getDate()) as DayData;
      expect(LunarDateUtil.parseLeapLunaMonth(chineseDate)).assertEqual('五月');
    })
  })
}