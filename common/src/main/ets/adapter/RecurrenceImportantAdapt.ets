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

import { DayData } from '../date/Date';
import { DateManager, YearLunarStaticData } from '../date/DateManager';
import { allYearLunarStaticData } from '../date/LunarStaicData';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { Log } from '../default/common/Log';
import { LunarDateUtil } from '../date/LunarDateUtil';

import { DateUtil } from '../util/DateUtil';
import { CalendarDate } from '../date/CalendarDate';

const FREQ_YEARLY: string = 'FREQ=YEARLY';

const FREQ_MONTHLY: string = 'FREQ=MONTHLY';

const LAST_MONTH_OF_YEAR: number = 11;

const MAX_RETRY_YEARLY: number = 4;

const MAX_RETRY_MONTHLY: number = 2;

const MAX_RETRY_LUNAR_YEAR: number = 20;

const MONTH_SIZE: number = 12;
// 十月
const OCTOBER: number = 10;
// 三月
const MARCH: number = 3;
//十二月
const DECEMBER: number = 12;
//三十号
const LAST_DAY_OF_LUNAR_MONTH: number = 30;

const TAG = 'RecurrenceImportantAdapt';
/**
 * 将循环倒数日日期适配到目标日期
 *
 * @param inputTime 倒数日日程的dtstart
 * @param rrule 倒数日日程的rrule循环规则
 * @param toDate 待适配的目标日期
 * @param forceAdapt 是否强制适配，强制适配是指忽略目标日期小于源数据日期的情况，主要用于月视图来回选中日期后刷新倒计时天数
 * @returns 适配后的时间戳
 */
export function getAdaptImportantTime(eventType: number, inputTime: number,
                                      rrule: string, toDate: CalendarDate, forceAdapt: boolean = false): number {
  if (!toDate) {
    return inputTime;
  }
  const resultDate = new CalendarDate(inputTime);
  if (rrule?.indexOf(FREQ_YEARLY) >= 0) {
    if (eventType === CalendarContract.AgendaCalendarType.LUNAR) {
      const realToDate: CalendarDate = new CalendarDate(toDate.getTime());
      realToDate.setHours(resultDate.getHours(), resultDate.getMinutes(), resultDate.getSeconds(),
        resultDate.getMilliseconds());
      moveImportantByLunarYearly(resultDate, realToDate, forceAdapt);
      return resultDate.getTime();
    } else {
      moveImportantBySolarYearly(resultDate, toDate, forceAdapt);
      return resultDate.getTime();
    }
  } else if (rrule?.indexOf(FREQ_MONTHLY) >= 0) {
    moveImportantBySolarMonthly(resultDate, toDate, forceAdapt);
    return resultDate.getTime();
  } else {
    return resultDate.getTime();
  }
}

function moveImportantBySolarYearly(importantDate: CalendarDate, toDate: CalendarDate, forceAdapt: boolean) {
  if (!forceAdapt && toDate.getFullYear() < importantDate.getFullYear()) {
    // 目标日期早于重要日日期，不处理
    return;
  }
  const originalMonth: number = importantDate.getMonth();
  const originalDate: number = importantDate.getDate();
  let toYear: number = importantDate.getFullYear();
  // 目标日期与重要日在同一年，或者大于重要日年份
  if (toDate.getMonth() < importantDate.getMonth()) {
    // 每年循环，选中月份小于重要日月份，将重要日挪移到选中日期的当年
    toYear = toDate.getFullYear();
  } else if (toDate.getMonth() > importantDate.getMonth()) {
    // 每年循环，选中月份大于重要日月份，将重要日挪移到选中日期的下一年
    toYear = toDate.getFullYear() + 1;
  } else {
    // 每年循环，选中月份与重要日月份相同，比较日期，判断将重要日挪移到选中日期的当年还是下一年
    if (toDate.getDate() <= importantDate.getDate()) {
      toYear = toDate.getFullYear();
    } else {
      toYear = toDate.getFullYear() + 1;
    }
  }
  for (let index = 0; index < MAX_RETRY_YEARLY; index++) {
    if (isValidSolarDate(toYear, originalMonth, originalDate)) {
      break;
    }
    // 无效日期，尝试往后顺延一年，最多顺延4次
    toYear++;
  }
  if (isValidSolarDate(toYear, originalMonth, originalDate)) {
    importantDate.setFullYear(toYear, originalMonth, originalDate);
  }
}

function moveImportantByLunarYearly(importantDate: CalendarDate, toDate: CalendarDate, forceAdapt: boolean) {
  const chineseDate: DayData = DateManager.getInstance().getDayData(importantDate.getFullYear(),
    importantDate.getMonth() + 1, importantDate.getDate()) as DayData;
  const lunarToDate: DayData = DateManager.getInstance().getDayData(toDate.getFullYear(),
    toDate.getMonth() + 1, toDate.getDate()) as DayData;
  if (!forceAdapt && toDate.getFullYear() < importantDate.getFullYear()) {
    // 目标日期早于重要日日期，不处理
    return;
  }
  let lunarYear = LunarDateUtil.getLunarYear(toDate);
  let originalMonth: number = importantDate.getMonth();
  let originalDate: number = importantDate.getDate();
  let toLunarYear: number = LunarDateUtil.getLunarYear(importantDate);
  let toYear: number = importantDate.getFullYear();

  // 农历月份取模12，去除闰月对月份大小判断的影响
  const originalLunarMonth = chineseDate.lunaMonth % MONTH_SIZE;
  const toDateLunarMonth = lunarToDate.lunaMonth % MONTH_SIZE;

  // 目标日期与重要日在同一年，或者大于重要日年份
  if (toDateLunarMonth < originalLunarMonth) {
    // 农历每年循环，选中农历月份小于重要日v月份，将重要日挪移到选中日期的当年
    toLunarYear = lunarYear;
  } else if (toDateLunarMonth > originalLunarMonth) {
    // 农历每年循环，选中农历月份大于重要日农历月份，将重要日挪移到选中日期的下一年
    toLunarYear = lunarYear + 1;
  } else {
    // 农历每年循环，选中农历月份与重要日农历月份相同，比较日期，判断将重要日挪移到选中日期的当年还是下一年
    if (lunarToDate.lunaMonth === (chineseDate.lunaMonth - MONTH_SIZE)) {
      // 选中日期为非闰月，目标日期为闰月，且月份相同，则下一个实例就在当年，无需往后挪移一年
      toLunarYear = lunarYear;
    } else if (lunarToDate.lunarDay <= chineseDate.lunarDay) {
      // 月份相等的情况下，选中日期比目标日期小，则下一个实例就在当年，无需往后挪移一年
      toLunarYear = lunarYear;
    } else {
      // 选中日期比目标日期大，下一个实例在下一年，需要往后挪移一年
      toLunarYear = lunarYear + 1;
    }
  }
  for (let i = 0; i < MAX_RETRY_LUNAR_YEAR; i++) {
    let lunar = toLunarYear + i;
    if (originalLunarMonth === DECEMBER && chineseDate.lunarDay === LAST_DAY_OF_LUNAR_MONTH) {
      lunar = lunar + 1;
    }
    if (hasSameLunarDate(lunar, chineseDate)) {
      if (toYear < lunar) {
        toYear = lunar;
      }
      break;
    }
  }
  if (hasSameLunarDate(toYear, chineseDate)) {
    getImportantDateByLunar(chineseDate, toYear, originalMonth, originalDate, importantDate, toDate);
    // 如果对应重要日时间戳小于目标日期时间戳，说明该日程对应农历年份小于阳历年份，需要toYear+1才能的到正确的对应日期
    if (importantDate.getTime() < toDate.getTime()) {
      getImportantDateByLunar(chineseDate, toYear + 1, originalMonth, originalDate, importantDate, toDate);
    }
  }
}

function getImportantDateByLunar(chineseDate: DayData, toYear: number, originalMonth: number,
                                 originalDate: number, importantDate: CalendarDate, toDate: CalendarDate) {
  const staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) => data.year === toYear);
  if (staticYearData.length === 0) {
    Log.warn(TAG, `getImportantDateByLunar staticYearData empty toYear:${toYear}`);
    return;
  }
  // 根据农历日期获取对应阳历日期
  let yearData = DateManager.getInstance().getYearData(toYear);
  if (!yearData) {
    Log.warn(TAG, `getImportantDateByLunar getYearData empty toYear:${toYear}`);
    return;
  }
  let allMonthInfo = yearData.getAllMonthInfo();
  for (let i = 0; i < allMonthInfo.length; i++) {
    let lunarMonthInfo = allMonthInfo[i].getDaysInfo();
    for (let index = 0; index < lunarMonthInfo.length; index++) {
      // 判断是否为对应农历月份和日期
      if (lunarMonthInfo[index].lunarDay === chineseDate.lunarDay &&
        isSameLunarMonth(chineseDate.lunaMonth, lunarMonthInfo[index].lunaMonth)) {
        let solarDay = lunarMonthInfo[index].solarDay;
        let solarMonth = lunarMonthInfo[index].solarMonth;
        originalMonth = solarMonth - 1;
        originalDate = solarDay;
        if (toDate.getFullYear() < toYear ||
          (toDate.getFullYear() === toYear &&
            (toDate.getMonth() + 1 < solarMonth ||
              (toDate.getMonth() + 1 === solarMonth && toDate.getDate() <= solarDay)))) {
          importantDate.setFullYear(toYear, originalMonth, originalDate);
          return;
        }
      }
    }
  }
  importantDate.setFullYear(toYear, originalMonth, originalDate);
  Log.info(TAG, `getImportantDateByLunar importantDate:${importantDate}`);
}

function moveImportantBySolarMonthly(importantDate: CalendarDate, toDate: CalendarDate, forceAdapt: boolean) {
  if (!forceAdapt) {
    if (toDate.getFullYear() < importantDate.getFullYear()) {
      // 目标日期早于重要日日期，不处理
      return;
    }
    if (toDate.getFullYear() === importantDate.getFullYear() && toDate.getMonth() < importantDate.getMonth()) {
      // 目标日期早于重要日日期，不处理
      return;
    }
  }
  const originalDate: number = importantDate.getDate();
  let toYear: number = importantDate.getFullYear();
  let toMonth: number = importantDate.getMonth();

  // 目标日期与重要日在同一年月，或者大于重要日年月
  if (toDate.getDate() <= importantDate.getDate()) {
    // 每月循环，选中日期小于或等于重要日日期，将重要日挪移到选中日期的当月
    toYear = toDate.getFullYear();
    toMonth = toDate.getMonth();
  } else if (toDate.getMonth() < LAST_MONTH_OF_YEAR) {
    // 每月循环，选中日期大于重要日日期，且选中月非12月，将重要日挪移到选中日期的下一月
    toYear = toDate.getFullYear();
    toMonth = toDate.getMonth() + 1;
  } else {
    // 每月循环，选中日期大于重要日日期，且选中月为12月，将重要日挪移到选中日期的下一年1月
    toYear = toDate.getFullYear() + 1;
    toMonth = 0;
  }
  for (let index = 0; index < MAX_RETRY_MONTHLY; index++) {
    if (isValidSolarDate(toYear, toMonth, originalDate)) {
      break;
    }
    // 无效日期，尝试往后顺延一月，最多顺延2次
    if (toMonth === LAST_MONTH_OF_YEAR) {
      toYear++;
      toMonth = 0;
    } else {
      toMonth++;
    }
  }
  if (isValidSolarDate(toYear, toMonth, originalDate)) {
    importantDate.setFullYear(toYear, toMonth, originalDate);
  }
}

function isValidSolarDate(year: number, month: number, date: number): boolean {
  const maxDateForMonth: number = DateUtil.getMaxDayInMonth(year, month + 1);
  return date <= maxDateForMonth;
}

function hasSameLunarDate(year: number, chineseDate: DayData): boolean {
  let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) => data.year === year);
  if (!staticYearData || staticYearData.length === 0) {
    Log.warn(TAG, `hasSameLunarDate staticYearData empty year:${year}`);
    return false;
  }
  let yearData = DateManager.getInstance().getYearData(year);
  if (!yearData) {
    return false;
  }
  let allMonthInfo = yearData.getAllMonthInfo();
  for (let i = 0; i < allMonthInfo.length; i++) {
    let lunarMonthInfo = allMonthInfo[i].getDaysInfo();
    for (let index = 0; index < lunarMonthInfo.length; index++) {
      // 判断是否为对应农历月份和日期
      if (lunarMonthInfo[index].lunarDay === chineseDate.lunarDay &&
        isSameLunarMonth(chineseDate.lunaMonth, lunarMonthInfo[index].lunaMonth)) {
        return true;
      }
    }
  }
  return false;
}

function isSameLunarMonth(baseLunarMonth: number, compareLunarMonth: number): boolean {
  if (baseLunarMonth === compareLunarMonth) {
    // 月份数值相同，分同为非闰月和同为闰月两种情况
    return true;
  }
  if (baseLunarMonth > MONTH_SIZE) {
    // 按产品规格，基准月份为闰月、比较月份为非闰月时，月份相同可认为是同一个月
    return (baseLunarMonth - MONTH_SIZE) === compareLunarMonth;
  }
  // 1、月份直接不同；2、按产品规格，基准月份为非闰月的，比较月份为闰月，视为不同
  return false;
}