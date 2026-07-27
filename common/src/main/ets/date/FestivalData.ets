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

import { DAY_PER_WEEK } from '../util/DateUtil';
import { YearData } from './Date';
import { CalendarDate } from './CalendarDate';

export enum FestivalType {
  SOLAR_TERM, // 节气
  INTER, // 国际节日
  LUNAR_CHINA, // 中国农历节日
  // 地区官方节假日
  OFFICIAL_CHINA,
  OFFICIAL_TAIWAN,
  OFFICIAL_HONGKONG,
}

export interface FestivalDay {
  type: FestivalType,
  name: string, // 节日名称
  resource ?: Resource, // 节日资源符
}

class RuleBySolarMonthDay {
  solarMonth: number;

  solarDay: number;

  startYear ?: number; // 起始年份

  constructor(solarMonth: number, solarDay: number, startYear ?: number) {
    this.solarMonth = solarMonth;
    this.solarDay = solarDay;
    this.startYear = startYear;
  }
}

class RuleBySolarMonthWeek {
  solarMonth: number;

  weekIndex: number;

  weekDay: number;

  startYear ?: number; // 起始年份

  constructor(solarMonth: number, weekIndex: number, weekDay: number, startYear ?: number) {
    this.solarMonth = solarMonth;
    this.weekIndex = weekIndex;
    this.weekDay = weekDay;
    this.startYear = startYear;
  }
}

interface ruleByLunarMonthDay {
  lunarMonth: number,
  lunarDay: number,
}

export interface SolarFestival {
  rule: RuleBySolarMonthDay | RuleBySolarMonthWeek;
  info: FestivalDay
}

export const allFestivalData: SolarFestival[] = [
  {
    info: { type: FestivalType.INTER, name: '元旦', resource: $r('app.string.new_years_day') },
    rule: new RuleBySolarMonthDay(1, 1, 1950)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '中国人民警察节', resource: $r('app.string.chinese_peoples_police_day') },
    rule: new RuleBySolarMonthDay(1, 10, 2021)
  },
  {
    info: { type: FestivalType.INTER, name: '情人节', resource: $r('app.string.valentines_day') },
    rule: new RuleBySolarMonthDay(2, 14, 269)
  },
  {
    info: { type: FestivalType.INTER, name: '妇女节', resource: $r('app.string.womens_day') },
    rule: new RuleBySolarMonthDay(3, 8, 1922)
  },
  {
    info: { type: FestivalType.INTER, name: '植树节', resource: $r('app.string.arbor_day') },
    rule: new RuleBySolarMonthDay(3, 12, 1979)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '消费者权益日', resource: $r('app.string.consumers_rights_day') },
    rule: new RuleBySolarMonthDay(3, 15, 1983)
  },
  {
    info: { type: FestivalType.INTER, name: '愚人节', resource: $r('app.string.april_fools_day') },
    rule: new RuleBySolarMonthDay(4, 1, 1564)
  },
  {
    info: { type: FestivalType.INTER, name: '劳动节', resource: $r('app.string.labor_day') },
    rule: new RuleBySolarMonthDay(5, 1, 1890)
  },
  {
    info: { type: FestivalType.INTER, name: '青年节', resource: $r('app.string.youth_day') },
    rule: new RuleBySolarMonthDay(5, 4, 1949)
  },
  {
    info: { type: FestivalType.INTER, name: '母亲节', resource: $r('app.string.mothers_day') },
    rule: new RuleBySolarMonthWeek(5, 2, 0, 1914)
  }, // 5月的第2个星期日
  {
    info: { type: FestivalType.INTER, name: '儿童节', resource: $r('app.string.childrens_day') },
    rule: new RuleBySolarMonthDay(6, 1, 1949)
  },
  {
    info: { type: FestivalType.INTER, name: '父亲节', resource: $r('app.string.fathers_day') },
    rule: new RuleBySolarMonthWeek(6, 3, 0, 1910)
  }, // 6月份的第3个星期日
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '建党节', resource: $r('app.string.ccp_founding_day') },
    rule: new RuleBySolarMonthDay(7, 1, 1938)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '七七事变', resource: $r('app.string.july_seventh_incident') },
    rule: new RuleBySolarMonthDay(7, 7, 1937)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '建军节', resource: $r('app.string.pla_day') },
    rule: new RuleBySolarMonthDay(8, 1, 1933)
  },
  {
    info: { type: FestivalType.INTER, name: '教师节', resource: $r('app.string.teachers_day') },
    rule: new RuleBySolarMonthDay(9, 10, 1985)
  },
  {
    info: {
      type: FestivalType.OFFICIAL_CHINA,
      name: '九一八事变',
      resource: $r('app.string.september_eighteenth_incident')
    },
    rule: new RuleBySolarMonthDay(9, 18, 1931)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '国庆节', resource: $r('app.string.national_day') },
    rule: new RuleBySolarMonthDay(10, 1, 1949)
  },
  {
    info: { type: FestivalType.INTER, name: '万圣夜', resource: $r('app.string.halloween') },
    rule: new RuleBySolarMonthDay(10, 31)
  },
  {
    info: { type: FestivalType.INTER, name: '感恩节', resource: $r('app.string.thanksgiving') },
    rule: new RuleBySolarMonthWeek(11, 4, 4, 1941)
  }, // 11月第4个星期四
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '国家公祭日', resource: $r('app.string.national_memorial_day') },
    rule: new RuleBySolarMonthDay(12, 13, 2014)
  },
  {
    info: { type: FestivalType.INTER, name: '平安夜', resource: $r('app.string.christmas_eve') },
    rule: new RuleBySolarMonthDay(12, 24, 440)
  },
  {
    info: { type: FestivalType.INTER, name: '圣诞节', resource: $r('app.string.christmas') },
    rule: new RuleBySolarMonthDay(12, 25, 336)
  },
  {
    info: { type: FestivalType.INTER, name: '护士节', resource: $r('app.string.nurses_festival') },
    rule: new RuleBySolarMonthDay(5, 12, 1912)
  },
  {
    info: { type: FestivalType.INTER, name: '中国人民抗日战争胜利纪念日', resource: $r('app.string.victory_day_of_the_Chinese_People_war_of_resistance_against_japan') },
    rule: new RuleBySolarMonthDay(9, 3, 2014)
  },
  {
    info: { type: FestivalType.INTER, name: '中国烈士纪念日', resource: $r('app.string.martyrs_memorial') },
    rule: new RuleBySolarMonthDay(9, 30, 2014)
  },
  {
    info: { type: FestivalType.INTER, name: '澳门回归纪念日', resource: $r('app.string.macao_reunification_day') },
    rule: new RuleBySolarMonthDay(12, 20, 1999)
  },
  {
    info: { type: FestivalType.INTER, name: '记者节', resource: $r('app.string.journalist_day') },
    rule: new RuleBySolarMonthDay(11, 8, 2000)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '香港回归纪念日', resource: $r('app.string.hong_kong_reunion_day') },
    rule: new RuleBySolarMonthDay(7, 1, 1997)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '日本投降日' },
    rule: new RuleBySolarMonthDay(8, 15, 1945)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '辛亥革命纪念日' },
    rule: new RuleBySolarMonthDay(10, 10, 1911)
  },
  {
    info: { type: FestivalType.OFFICIAL_CHINA, name: '抗美援朝纪念日' },
    rule: new RuleBySolarMonthDay(10, 25, 1950)
  },
]

export interface LunarFestival {
  rule: ruleByLunarMonthDay;
  info: FestivalDay
}

export const allLunarFestivalData: LunarFestival[] = [
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '除夕', resource: $r('app.string.chinese_new_years_eve') },
    rule: { lunarMonth: 12, lunarDay: -1 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '春节', resource: $r('app.string.spring_festival') },
    rule: { lunarMonth: 1, lunarDay: 1 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '元宵节', resource: $r('app.string.lantern_festival') },
    rule: { lunarMonth: 1, lunarDay: 15 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '端午节', resource: $r('app.string.dragon_boat_festival') },
    rule: { lunarMonth: 5, lunarDay: 5 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '七夕节', resource: $r('app.string.qixi_festival') },
    rule: { lunarMonth: 7, lunarDay: 7 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '中元节', resource: $r('app.string.ghost_festival') },
    rule: { lunarMonth: 7, lunarDay: 15 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '中秋节', resource: $r('app.string.mid_autumn_festival') },
    rule: { lunarMonth: 8, lunarDay: 15 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '重阳节', resource: $r('app.string.double_ninth_festival') },
    rule: { lunarMonth: 9, lunarDay: 9 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '腊八节', resource: $r('app.string.labas_festival') },
    rule: { lunarMonth: 12, lunarDay: 8 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '北方小年', resource: $r('app.string.northern_little_new_year') },
    rule: { lunarMonth: 12, lunarDay: 23 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '南方小年', resource: $r('app.string.southern_little_new_year') },
    rule: { lunarMonth: 12, lunarDay: 24 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '寒衣节' },
    rule: { lunarMonth: 10, lunarDay: 1 }
  },
  {
    info: { type: FestivalType.LUNAR_CHINA, name: '龙抬头' },
    rule: { lunarMonth: 2, lunarDay: 2 }
  },
]


export function setYearFestivalData(yearData: YearData): void {
  allFestivalData.forEach(data => {
    if (data.rule instanceof RuleBySolarMonthDay) {
      // 有明确天数, 直接赋值
      const ruleData = data.rule as RuleBySolarMonthDay;
      if (ruleData.startYear && ruleData.startYear > yearData.solarYear) {
        return;
      }
      let dayData = yearData.getMonthInfo(ruleData.solarMonth)?.getDayData(ruleData.solarDay);
      dayData?.festivals.push(data.info);
    } else if (data.rule instanceof RuleBySolarMonthWeek) {
      const ruleData = data.rule as RuleBySolarMonthWeek;
      if (ruleData.startYear && ruleData.startYear > yearData.solarYear) {
        return;
      }
      const day = getParticularDay(ruleData.solarMonth, ruleData.weekDay, ruleData.weekIndex, yearData.solarYear);
      let dayData = yearData.getMonthInfo(ruleData.solarMonth)?.getDayData(day);
      dayData?.festivals.push(data.info);
    }
  })
}

// 获取每月天数
function getParticularDay(month: number, dayInWeek: number, count: number, year: number): number {
  // 当月第一天的星期数
  let curDate = new CalendarDate(year, month - 1, 1);
  let week = curDate.getDay(); // get the month first day‘s weekday
  let tempDay = 0;
  if (week <= dayInWeek) {
    tempDay = dayInWeek - week + 1 + (count - 1) * DAY_PER_WEEK;
  } else {
    tempDay = DAY_PER_WEEK - week + dayInWeek + 1 + (count - 1) * DAY_PER_WEEK;
  }
  return tempDay;
}