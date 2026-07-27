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

import { GlobalThis } from '../data/GlobalThis';

import { DayData, LUNAR_CHINESE_TEXT } from './Date';
import { DateManager } from './DateManager';
import { Log } from '../default/common/Log';
import { CalendarDate } from './CalendarDate';

/* Chinese zodiac */
const ZODIAC_RES: Resource[] = // 十二生肖
  [$r('app.string.rat'), $r('app.string.ox'), $r('app.string.tiger'), $r('app.string.rabbit'), $r('app.string.dragon'),
    $r('app.string.snake'), $r('app.string.horse'), $r('app.string.goat'), $r('app.string.monkey'),
    $r('app.string.rooster'), $r('app.string.dog'), $r('app.string.pig')];
const HEAVENLY_STEMS_RES: Resource[] = // 甲乙丙丁
  [$r('app.string.jia'), $r('app.string.yi'), $r('app.string.bing'), $r('app.string.ding'), $r('app.string.wu_1'),
    $r('app.string.ji'), $r('app.string.geng'), $r('app.string.xin'), $r('app.string.ren'),
    $r('app.string.gui')];
const JIAN_ZHI_RES: Resource[] = // 子丑寅卯
  [$r('app.string.zi'), $r('app.string.chou'), $r('app.string.yin'), $r('app.string.mao'), $r('app.string.chen'),
    $r('app.string.si'), $r('app.string.wu'), $r('app.string.wei'), $r('app.string.shen'),
    $r('app.string.you'), $r('app.string.xu'), $r('app.string.hai')];
const LUNAR_STRING_RES: Resource[] = // 中文数字
  [$r('app.string.ten'), $r('app.string.one'), $r('app.string.two'), $r('app.string.three'), $r('app.string.four'),
    $r('app.string.five'), $r('app.string.six'), $r('app.string.seven'), $r('app.string.eight'),
    $r('app.string.nine'), $r('app.string.ten')];

const ZODIAC: string[] =
  ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
const HEAVENLY_STEMS: string[] =
  ['甲', '乙', '丙', '丁', '戊', '己',
    '庚', '辛', '壬', '癸'];
const JIAN_ZHI: string[] =
  ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

const LUNAR_STRING: string[] = ['零', '一', '二', '三', '四',
  '五', '六', '七', '八', '九', '十'];
/**
 * 12生肖计算时的偏移值
 */
const OFFSET_OF_ZODIAC: number = 4;
/**
 * 12生肖
 */
const SIZE_OF_ZODIAC: number = 12;
const BEGIN_CHINESE_ERA: number = 33;
const OFFSET_OF_TEN = 10;
const OFFSET_OF_TWENTY: number = 20;
const RUN: string = '闰';
const MONTH_SIZE: number = 12;
const VALID_START_YEAR = 1900;
const VALID_END_YEAR = 2100;

const LUNAR_LEAP_MONTH_MASK: number = 0xf;
const LUNAR_MONTH_NORMAL_SIZE: number = 30;
const LUNAR_MONTH_LEAP_SIZE: number = 29;
const MONTH_START: number = 1;
/**
 * 农历冬月是11月
 */
const MONTH_OF_DONG_YUE: number = 11;
/**
 * 农历腊月是12月
 */
const MONTH_OF_LA_YUE: number = 12;
/**
 * 农历正月是1月
 */
const MONTH_OF_ZHENG_YUE: number = 1;
//农历月份
const WINTERMONTH: string = '冬月';
const LASTMONTH: string = '腊月';
const FIRSTMONTH: string = '正月';

const YEAR_START: number = 1897;

const TAG: string = 'LunarDateUtil';

export class LunarDateUtil {
  /**
   * 农历具体日期
   * @param date
   * @returns
   */
  static getLunarDate(date: CalendarDate | Date, language?: string): string {
    let chineseMonth = ''
    const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate());
    if (!chineseDate) {
      Log.error(TAG, `chineseDate is null`);
      return '';
    }
    if (chineseDate.lunaMonth > MONTH_SIZE) {
      chineseMonth =
        LunarDateUtil.getRun(language) + LunarDateUtil.getChineseMonth(chineseDate.lunaMonth - MONTH_SIZE, language);
    } else {
      chineseMonth = LunarDateUtil.getChineseMonth(chineseDate.lunaMonth, language);
    }
    const lunarYear: number = LunarDateUtil.getLunarYear(date);
    const chineseYear = LunarDateUtil.getChineseYearReal(lunarYear, language);
    let lunarDate = '';
    const chineseDay = LunarDateUtil.getChineseDay(chineseDate.lunarDay);
    const now: CalendarDate = new CalendarDate();
    const currentLunarYear: number = LunarDateUtil.getLunarYear(now);
    if (lunarYear === currentLunarYear) {
      lunarDate = chineseMonth + chineseDay;
    } else {
      lunarDate = lunarYear + chineseYear + chineseMonth + chineseDay;
    }
    return lunarDate;
  }

  /**
   * 判断农历日期对应年份是否与阳历年份一致
   * @param date 阳历日期
   * @returns 农历日期对应年份
   */
  static getLunarYear(date: CalendarDate | Date): number {
    // 十月
    const OCTOBER: number = 10;
    // 三月
    const MARCH: number = 3;
    const solarYear = date.getFullYear();
    const solarMonth = date.getMonth();
    let lunarYear = 0;
    const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate()) as DayData;
    let lunarMonth = chineseDate.lunaMonth;
    if (lunarMonth > MONTH_SIZE) {
      lunarMonth = lunarMonth - MONTH_SIZE;
    }
    // 如果阳历月份（一月，二月，三月）对应农历月份（腊月，冬月，十月），对应农历年份-1
    if (lunarMonth >= OCTOBER && solarMonth <= MARCH) {
      lunarYear = solarYear - 1;
    } else {
      lunarYear = solarYear;
    }
    return lunarYear;
  }

  /**
   * 获取农历年份，如：庚子鼠年
   * @return 农历年份
   */
  static getChineseYearReal(mLunarYear: number, language?: string, isCard?: boolean): string {
    const yearText = '年';
    return LunarDateUtil.getChineseHeavenlyEarthly(mLunarYear, language, isCard) +
    LunarDateUtil.getZodiac(mLunarYear, language, isCard) + yearText;
  }

  /**
   * 农历形式展示月份
   * @param mLunarMonth
   * @returns
   */
  static getChineseMonth(mLunarMonth: number, language?: string, isCard?: boolean): string {
    if (mLunarMonth <= 0 || mLunarMonth > MONTH_SIZE * 2) { // 适配闰月超12月份的情况
      return '';
    }
    let chineseMonth = '';
    let month = mLunarMonth;
    if (mLunarMonth > MONTH_SIZE) {
      chineseMonth = isCard ? RUN : LunarDateUtil.getString($r('app.string.leap'), language);
      month = month - 12; // 闰月为原月份数据+12,故需要减去该月份
    }
    let normalMonthStr: string;
    switch (month) {
      case MONTH_OF_ZHENG_YUE:
        return chineseMonth + FIRSTMONTH;
      case MONTH_OF_DONG_YUE:
        return chineseMonth + WINTERMONTH;
      case MONTH_OF_LA_YUE:
        return chineseMonth + (isCard ? LASTMONTH : LunarDateUtil.getString($r('app.string.twelfth_month'), language));
      default:
        break;
    }
    normalMonthStr = LunarDateUtil.getChineseNum(month, language, isCard) + '月';
    chineseMonth = chineseMonth + normalMonthStr;
    return chineseMonth;
  }

  /**
   * 农历形式展示数字
   * @param num
   * @returns
   */

  static getChineseNum(num: number, language?: string, isCard?: boolean): string {
    if (num < 0) {
      return '';
    }
    let convertNum = '';

    switch (Math.floor(num / OFFSET_OF_TEN)) {
      case 1: // 大于十小于十九，农历前缀为‘十’
        convertNum = isCard ? '十' : LunarDateUtil.getString($r('app.string.ten'), language);
        break;
      case 2: // 大于二十小于二十九，农历前缀为‘二十’
        if ((num % OFFSET_OF_TWENTY) === 0) {
          if (isCard) {
            convertNum = '二十';
          } else {
            convertNum = LunarDateUtil.getString($r('app.string.two'), language) +
            LunarDateUtil.getString($r('app.string.ten'), language);
          }
        } else {
          convertNum = '廿';
        }
        break;
      case 3: // 农历三十
        if (isCard) {
          convertNum = '三十';
        } else {
          convertNum = LunarDateUtil.getString($r('app.string.three'), language) +
          LunarDateUtil.getString($r('app.string.ten'), language);
        }
        break;
      default:
        break;
    }
    let offset = Math.floor(num % OFFSET_OF_TEN);
    if (offset !== 0) {
      if (isCard) {
        convertNum = convertNum + LUNAR_STRING[offset];
      } else {
        convertNum = convertNum + LunarDateUtil.getString(LUNAR_STRING_RES[offset], language);
      }
    }
    return convertNum;
  }

  static getChineseHeavenlyEarthly(solarYear: number, language?: string, isCard?: boolean): string {
    let ganNum = (solarYear - YEAR_START + BEGIN_CHINESE_ERA) % 10;
    let zhiNum = (solarYear - YEAR_START + BEGIN_CHINESE_ERA) % 12;
    let result = '';
    let isGanNumValid = ganNum >= 0 && ganNum < HEAVENLY_STEMS_RES.length;
    if (!isGanNumValid || zhiNum < 0 || zhiNum >= JIAN_ZHI_RES.length) {
      return result;
    }

    if (isCard) {
      result = HEAVENLY_STEMS[ganNum] + JIAN_ZHI[zhiNum];
    } else {
      result = LunarDateUtil.getString(HEAVENLY_STEMS_RES[ganNum], language) +
      LunarDateUtil.getString(JIAN_ZHI_RES[zhiNum], language);
    }
    return result;
  }

  static getZodiac(mLunarYear: number, language?: string, isCard?: boolean): string {
    if (isCard) {
      return ZODIAC[(mLunarYear - OFFSET_OF_ZODIAC) % SIZE_OF_ZODIAC];
    } else {
      return LunarDateUtil.getString(ZODIAC_RES[(mLunarYear - OFFSET_OF_ZODIAC) % SIZE_OF_ZODIAC], language);
    }
  }

  /**
   * 获取中国农历日期
   *
   * @param date js Date日期
   * @returns 返回中国农历日期
   */
  static toLunarDateString(date: CalendarDate | Date, language?: string, isCard?: boolean): string {
    const dayData = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate()) as DayData;
    const lunarYear: number = LunarDateUtil.getLunarYear(date);
    let now: CalendarDate | Date | null = null;
    if (date instanceof Date) {
      now = new Date();
    } else {
      now = new CalendarDate();
    }
    const currentLunarYear: number = LunarDateUtil.getLunarYear(now);
    if (lunarYear !== currentLunarYear) {
      return LunarDateUtil.getLunarYear(date) + LunarDateUtil.getChineseYearReal(lunarYear, language, isCard) +
      LunarDateUtil.getChineseMonth(dayData.lunaMonth, language, isCard) +
      LunarDateUtil.getChineseDay(dayData.lunarDay, language, isCard);
    }
    return LunarDateUtil.getChineseMonth(dayData.lunaMonth, language, isCard) +
    LunarDateUtil.getChineseDay(dayData.lunarDay, language, isCard);
  }

  /**
   * 获取全量的中国农历日期
   *
   * @param date js Date日期
   * @returns 农历闰十一月二十
   */
  static toFullLunarDateString(date: CalendarDate, language?: string): string {
    const dayData = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate()) as DayData;
    if (dayData.lunaMonth > MONTH_SIZE) {
      return GlobalThis.getResourceStr($r('app.string.lunar_calendar_text'), language) +
        LunarDateUtil.getRun(language) + LunarDateUtil.getChineseMonth(dayData.lunaMonth - MONTH_SIZE, language) +
          LunarDateUtil.getChineseDay(dayData.lunarDay, language);
    } else {
      return GlobalThis.getResourceStr($r('app.string.lunar_calendar_text'), language) +
        LunarDateUtil.getChineseMonth(dayData.lunaMonth, language) +
          LunarDateUtil.getChineseDay(dayData.lunarDay, language);
    }
  }

  static getChineseDay(lunarDay: number, language?: string, isCard?: boolean): string {
    let chineseDay = '';
    if (lunarDay <= OFFSET_OF_TEN) {
      chineseDay = chineseDay + '初';
    }
    return chineseDay + LunarDateUtil.getChineseNum(lunarDay, language, isCard);
  }

  /**
   * 处理农历月份
   */
  public static parseLeapLunaMonth(dayData: DayData, language?: string): string {
    if (!dayData) {
      Log.error(TAG, 'dayData is null');
      return '';
    }
    let calendarMonth = ''
    if (dayData.lunarDay === MONTH_START) {
      if (dayData.lunaMonth > MONTH_SIZE) {
        calendarMonth =
          LunarDateUtil.getRun(language) + LunarDateUtil.getChineseMonth(dayData.lunaMonth - MONTH_SIZE, language);
      } else {
        calendarMonth = LunarDateUtil.getChineseMonth(dayData.lunaMonth, language);
      }
    } else {
      calendarMonth = LunarDateUtil.getChineseDay(dayData.lunarDay, language);
    }
    return calendarMonth;
  }

  static getRun(language?: string) { // 获取闰
    return GlobalThis.getResourceStr($r('app.string.leap'), language);
  }

  static getString(resource: Resource, language?: string) {
    return GlobalThis.getResourceStr(resource, language);
  }

  getLunarTime(time: number) {
    const dateTime = new CalendarDate(time);
    return LunarDateUtil.toLunarDateString(dateTime);
  }
}