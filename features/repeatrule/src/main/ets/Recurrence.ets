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

import { DAY_OF_WEEK_MAP, DAY_OF_WEEK_SHORT_MAP, Frequency, WEEK_OF_MONTH_MAP, Weeks } from './Constants';
import { FLAG_WEEK_START, parsePartByKey } from './RecurrenceParser';
import { FormatTime } from './time/FormatTime';
import {
  CalendarContract,
  CalendarDate,
  DateManager,
  DayData,
  EmptyUtils,
  GlobalThis,
  I18nUtil,
  Log,
  UTC
} from '@app/common';
import { CustomTime } from './time/CustTime';

const MONTH_SIZE: number = 12;
const PART_SEPARATOR: string = ';';
const PART_CONNECTOR: string = '=';
const TAG: string = 'Recurrence';
const DEFAULT_NUM: number = 1;

/**
 * 循环规则解析后实体
 */
export class Recurrence {
  public freq: Frequency = Frequency.NONE;
  public until: string = '';
  public count: number = 0;
  public interval: number = 0;
  public parseFlag: number = 0;
  public weekStart: Weeks = Weeks.UNDEFINED;
  public bySecond: number[] = [];
  public byMinute: number[] = [];
  public byHour: number[] = [];
  // 循环规则之周几
  public byWeekDay: Weeks[] = [];
  // 循环规则之第几周
  public byWeekNum: number[] = [];
  // 循环规则之几号
  public byMonthDay: number[] = [];
  public byYearDay: number[] = [];
  public byWeek: number[] = [];
  public byMonth: number[] = [];
  public bySetPos: number[] = [];

  public static parse(recurrenceRule: string): Recurrence {
    const recurrence: Recurrence = new Recurrence();
    recurrence.parse(recurrenceRule);
    return recurrence;
  }

  private eventCalendarType: number = 0;

  /**
   * 解析循环规则
   *
   * @param recurrenceRule 循环规则字符串
   */
  public parse(recurrenceRule: string) {
    if (recurrenceRule === null || recurrenceRule === undefined || recurrenceRule.length === 0) {
      return;
    }
    const parts: string[] = recurrenceRule.split(PART_SEPARATOR);
    if (!parts || parts.length <= 0) {
      return;
    }
    parts.forEach((part: string) => {
      this.parsePart(part);
    });
    if ((this.parseFlag & FLAG_WEEK_START) === 0) {
      this.weekStart = Weeks.MON;
    }
  }

  /**
   * 封装循环规则为字符串
   *
   * @returns 封装的循环规则字符串
   */
  public format(): string {
    let resultStr: string = '';
    // 以下顺序是固定的，改动需考虑历史兼容场景
    resultStr += this.formatFreq();
    resultStr += this.formatUntil();
    resultStr += this.formatCount();
    resultStr += this.formatInterval();
    resultStr += this.formatWeekStart();
    resultStr += this.formatBySecond();
    resultStr += this.formatByMinute();
    resultStr += this.formatByHour();
    resultStr += this.formatByDay();
    resultStr += this.formatByMonthDay();
    resultStr += this.formatByYearDay();
    resultStr += this.formatByWeek();
    resultStr += this.formatByMonth();
    resultStr += this.formatBySetPos();
    return resultStr;
  }

  public isLunarEvent(): boolean {
    return this.eventCalendarType === CalendarContract.AgendaCalendarType.LUNAR;
  }

  public bySecondCount(): number {
    return this.bySecond ? this.bySecond.length : 0;
  }

  public byMinuteCount(): number {
    return this.byMinute ? this.byMinute.length : 0;
  }

  public byHourCount(): number {
    return this.byHour ? this.byHour.length : 0;
  }

  public byWeekDayCount(): number {
    return this.byWeekDay ? this.byWeekDay.length : 0;
  }

  public byWeekNumCount(): number {
    return this.byWeekNum ? this.byWeekNum.length : 0;
  }

  public getWeekNum(index: number): number {
    if (index >= 0 && index <= this.byWeekNum.length) {
      return this.byWeekNum[index];
    }
    return 0;
  }

  public byMonthDayCount(): number {
    return this.byMonthDay ? this.byMonthDay.length : 0;
  }

  public byYearDayCount(): number {
    return this.byYearDay ? this.byYearDay.length : 0;
  }

  public byWeekCount(): number {
    return this.byWeek ? this.byWeek.length : 0;
  }

  public byMonthCount(): number {
    return this.byMonth ? this.byMonth.length : 0;
  }

  public useBySecond(): boolean {
    return this.bySecondCount() > 0 && this.freq > Frequency.SECONDLY;
  }

  public useByMinute(): boolean {
    return this.byMinuteCount() > 0 && this.freq > Frequency.MINUTELY;
  }

  public useByHour(): boolean {
    return this.byHourCount() > 0 && this.freq > Frequency.HOURLY;
  }

  public useByDay(): boolean {
    return this.freq >= Frequency.WEEKLY && (this.byWeekDayCount() > 0 || this.byMonthDayCount() > 0);
  }

  public useByMonth(): boolean {
    return this.byMonthCount() > 0 && this.freq > Frequency.MONTHLY;
  }

  public isCustomFreq(): boolean {
    if (this.freq !== Frequency.DAILY && this.freq !== Frequency.WEEKLY && this.freq !== Frequency.MONTHLY &&
      this.freq !== Frequency.YEARLY) {
      return false;
    }
    if (this.byWeekDay && this.byWeekDay.length > 1) {
      return true;
    }
    // 排除：每月（第几个星期几）
    if (this.freq === Frequency.MONTHLY && this.byWeekDay.length > 0 &&
      (this.byWeekDay.length === this.byWeekNum.length) && this.byWeekNum[0] !== 0
    ) {
      return true;
    }
    if (this.interval > 1) {
      return true;
    }
    return false;
  }

  public setLunarEvent() {
    return this.eventCalendarType = CalendarContract.AgendaCalendarType.LUNAR;
  }

  public setSolarEvent() {
    return this.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
  }

  public setUntil(untilMills: number): void {
    this.until = new FormatTime().getTimeInFormat2445(untilMills, UTC);
  }

  public getUntilMills(timeZone?: string): number {
    const customTime: CustomTime = new CustomTime(timeZone);
    new FormatTime().parseByTimeString(this.until, customTime);
    return customTime.getTimeInMills();
  }

  public hasUntil(): boolean {
    return this.until !== null && this.until !== undefined && this.until.length > 0;
  }

  public setCount(toCount: number): void {
    this.count = toCount;
  }

  public hasCount(): boolean {
    return this.count > 0;
  }

  public setInterval(interval: number): void {
    this.interval = interval;
  }

  public resetAll() {
    this.until = '';
    this.count = 0;
    this.resetAllExceptUntilAndCount();
  }

  public resetAllExceptUntilAndCount() {
    this.freq = Frequency.NONE;
    this.interval = 0;
    this.parseFlag = 0;
    this.weekStart = Weeks.UNDEFINED;
    this.bySecond = [];
    this.byMinute = [];
    this.byHour = [];
    this.byWeekDay = [];
    this.byWeekNum = [];
    this.byMonthDay = [];
    this.byYearDay = [];
    this.byWeek = [];
    this.byMonth = [];
    this.bySetPos = [];
  }

  public setToNoneRepeat(): void {
    this.resetAll();
  }

  public setToDaily(): void {
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.DAILY;
  }

  public setToWeekly(frequencyWeeks: Weeks[]): void {
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.WEEKLY;
    this.byWeekDay = frequencyWeeks;
  }

  public setToMonthlyByDay(monthDay: number): void {
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.MONTHLY;
    this.byMonthDay = [monthDay];
  }

  public setToMonthlyByWeek(weekIndex: number, byWeek: Weeks): void {
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.MONTHLY;
    this.byWeekDay = [byWeek];
    this.byWeekNum = [weekIndex];
  }

  public setToYearly(month: number, monthDay: number): void {
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.YEARLY;
    this.byMonth = [month + 1];
    this.byMonthDay = [monthDay];
  }

  public setToLunarYearly(date: CalendarDate): void {
    if (!this.isLunarEvent()) {
      return;
    }
    this.resetAllExceptUntilAndCount();
    this.freq = Frequency.YEARLY;
    const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate()) as DayData;
    let month = 0;
    if (chineseDate.lunaMonth > MONTH_SIZE) {
      month = chineseDate.lunaMonth - MONTH_SIZE;
    } else {
      month = chineseDate.lunaMonth;
    }
    this.byMonth = [month];
    this.byMonthDay = [chineseDate.lunarDay];
  }

  public toString(language?: string): ResourceStr {
    if (this.isCustomFreq()) {
      return this.toCustomString(language);
    }
    const newLanguage = I18nUtil.getSystemLanguage();
    const isEnglish = I18nUtil.isEnglishLanguage(newLanguage);
    const separator = isEnglish ? ' ' : ''; // 英文情况下使用空格分隔
    switch (this.freq) {
      case Frequency.DAILY:
        return $r('app.string.every_day_repeat');
      case Frequency.WEEKLY:
        return GlobalThis.getResourceStr($r('app.string.every_week_repeat'), language) +
        separator + this.formatByDayToString(language);
      case Frequency.MONTHLY:
        return $r('app.string.every_month_repeat');
      case Frequency.YEARLY:
        return this.isLunarEvent() ? $r('app.string.every_lunar_year_repeat') : $r('app.string.every_year_repeat');
      default:
        return $r('app.string.no_repeat');
    }
  }

  public deepCopyFrom(newRule: Recurrence): void {
    this.freq = newRule.freq;
    this.until = newRule.until;
    this.count = newRule.count;
    this.interval = newRule.interval;
    this.parseFlag = newRule.parseFlag;
    this.weekStart = newRule.weekStart;
    this.bySecond.push(...newRule.bySecond);
    this.byMinute.push(...newRule.byMinute);
    this.byHour.push(...newRule.byHour);
    this.byWeekDay.push(...newRule.byWeekDay);
    this.byWeekNum.push(...newRule.byWeekNum);
    this.byMonthDay.push(...newRule.byMonthDay);
    this.byYearDay.push(...newRule.byYearDay);
    this.byWeek.push(...newRule.byWeek);
    this.byMonth.push(...newRule.byMonth);
    this.bySetPos.push(...newRule.bySetPos);
  }

  public updateBy(newRule: Recurrence): void {
    if (!newRule) {
      Log.error(TAG, 'updateBy with invalid data')
      return;
    }
    this.resetAll();
    this.freq = newRule.freq;
    this.interval = newRule.interval;
    this.count = newRule.count;
    this.until = newRule.until;
    if (newRule.freq === Frequency.WEEKLY) {
      this.byWeekDay.push(...newRule.byWeekDay);
    } else if (newRule.freq === Frequency.MONTHLY) {
      this.byMonthDay.push(...newRule.byMonthDay);
      this.byWeekDay.push(...newRule.byWeekDay);
      this.byWeekNum.push(...newRule.byWeekNum);
    } else if (newRule.freq === Frequency.YEARLY) {
      this.byMonthDay.push(...newRule.byMonthDay);
      this.byMonth.push(...newRule.byMonth);
    }
  }

  public isValidRecurrence(): boolean {
    if (this.interval < 1) {
      return false;
    }
    if (this.freq === Frequency.WEEKLY && this.byWeekDay.length === 0) {
      return false;
    }
    const isValidMonthly = this.byMonthDay.length > 0 || (this.byWeekDay.length > 0 &&
      this.byWeekDay.length === this.byWeekNum.length &&
      this.byWeekNum[0] !== 0);
    if (this.freq === Frequency.MONTHLY && !isValidMonthly) {
      return false;
    }

    return true;
  }

  private parsePart(part: string) {
    if (part === null || part === undefined || part.length === 0) {
      return;
    }
    const splitIndex: number = part.indexOf(PART_CONNECTOR);
    if (!splitIndex || splitIndex < 0) {
      return;
    }
    const key: string = part.slice(0, splitIndex);
    const value: string = part.slice(splitIndex + PART_CONNECTOR.length);
    parsePartByKey(key, value, this);
  }

  private formatFreq(): string {
    if (!this.freq) {
      return '';
    }
    switch (this.freq) {
      case Frequency.SECONDLY:
        return 'FREQ=SECONDLY';
      case Frequency.MINUTELY:
        return 'FREQ=MINUTELY';
      case Frequency.HOURLY:
        return 'FREQ=HOURLY';
      case Frequency.DAILY:
        return 'FREQ=DAILY';
      case Frequency.WEEKLY:
        return 'FREQ=WEEKLY';
      case Frequency.MONTHLY:
        return 'FREQ=MONTHLY';
      case Frequency.YEARLY:
        return 'FREQ=YEARLY';
      default:
        return '';
    }
  }

  private formatUntil(): string {
    if (this.until && this.until.length > 0) {
      return ';UNTIL=' + this.until;
    }
    return '';
  }

  private formatCount(): string {
    if (this.count != 0) {
      return ';COUNT=' + this.count;
    }
    return '';
  }

  private formatInterval(): string {
    if (this.interval != 0) {
      return ';INTERVAL=' + this.interval;
    }
    return '';
  }

  private weekToString(week: Weeks): string {
    switch (week) {
      case Weeks.MON:
        return 'MO';
      case Weeks.TUE:
        return 'TU';
      case Weeks.WED:
        return 'WE';
      case Weeks.THUR:
        return 'TH';
      case Weeks.FRI:
        return 'FR';
      case Weeks.SAT:
        return 'SA';
      case Weeks.SUN:
        return 'SU';
      default:
        return '';
    }
  }

  private formatWeekStart(): string {
    const weekStart: string = this.weekToString(this.weekStart);
    if (weekStart && weekStart.length > 0) {
      return ';WKST=' + this.weekToString(this.weekStart);
    }
    return '';
  }

  private formatBySecond(): string {
    if (this.bySecond && this.bySecond.length > 0) {
      return ';BYSECOND=' + this.bySecond.join(',');
    }
    return '';
  }

  private formatByMinute(): string {
    if (this.byMinute && this.byMinute.length > 0) {
      return ';BYMINUTE=' + this.byMinute.join(',');
    }
    return '';
  }

  private formatByHour(): string {
    if (this.byHour && this.byHour.length > 0) {
      return ';BYHOUR=' + this.byHour.join(',');
    }
    return '';
  }

  private formatByDay(): string {
    if (!this.byWeekDay || this.byWeekDay.length === 0) {
      return '';
    }
    let resultStr: string = ';BYDAY=';
    this.byWeekDay.forEach((week: Weeks, index: number) => {
      if (index > 0) {
        resultStr += ',';
      }
      if (index >= 0 && this.byWeekNum.length > index && this.byWeekNum[index] !== 0) {
        resultStr += this.byWeekNum[index];
      }
      resultStr += this.weekToString(week);
    });
    return resultStr;
  }

  private formatByMonthDay(): string {
    if (this.byMonthDay && this.byMonthDay.length > 0) {
      return ';BYMONTHDAY=' + this.byMonthDay.join(',');
    }
    return '';
  }

  private formatByYearDay(): string {
    if (this.byYearDay && this.byYearDay.length > 0) {
      return ';BYYEARDAY=' + this.byYearDay.join(',');
    }
    return '';
  }

  private formatByWeek(): string {
    if (this.byWeek && this.byWeek.length > 0) {
      return ';BYWEEKNO=' + this.byWeek.join(',');
    }
    return '';
  }

  private formatByMonth(): string {
    if (this.byMonth && this.byMonth.length > 0) {
      return ';BYMONTH=' + this.byMonth.join(',');
    }
    return '';
  }

  private formatBySetPos(): string {
    if (this.bySetPos && this.bySetPos.length > 0) {
      return ';BYSETPOS=' + this.bySetPos.join(',');
    }
    return '';
  }

  /**
   * 按星期几拼接
   * @param language 当前语言环境
   *
   * @return (星期几）
   */
  private formatByDayToString(language?: string): string {
    if (!this.byWeekDay || this.byWeekDay.length === 0) {
      return '';
    }
    let resultStr: string = '(';
    this.byWeekDay.forEach((week: Weeks, index: number) => {
      if (index > 0) {
        resultStr += ', ';
      }
      if (index >= 0 && this.byWeekNum.length > index && this.byWeekNum[index] !== 0) {
        resultStr += this.byWeekNum[index];
      }
      resultStr += GlobalThis.getResourceStr(DAY_OF_WEEK_MAP.get(week), language);
    });
    return resultStr + ')';
  }

  /**
   * 按周几拼接
   * @param language 当前语言环境
   *
   * @return 周几
   */
  private formatByWeekDayToString(language?: string): string {
    if (!this.byWeekDay || this.byWeekDay.length === 0) {
      return '';
    }
    if (!language) {
      language = I18nUtil.getSystemLanguage();
    }
    // 阿语下使用阿语逗号，其他语言使用顿号
    const comma = GlobalThis.getResourceStr($r('app.string.slight_pause_mark'), language)
      .replace('%1$s', '')
      .replace('%2$s', '');
    let resultStr: string = '';
    this.byWeekDay.forEach((week: Weeks, index: number) => {
      if (index > 0) {
        resultStr += comma;
      }
      if (index >= 0 && this.byWeekNum.length > index && this.byWeekNum[index] !== 0) {
        resultStr += this.byWeekNum[index];
      }
      resultStr += GlobalThis.getResourceStr(DAY_OF_WEEK_SHORT_MAP.get(week), language);
    });
    return resultStr;
  }

  /**
   * 每月重复之第几个周几展示文本
   * @param language 当前语言环境
   *
   * @return 每月周几
   */
  private formatByWeekNumAndByWeekDayToString(language?: string): string {
    if (!this.byWeekDay || this.byWeekDay.length === 0 || !this.byWeekNum || this.byWeekNum.length === 0) {
      return '';
    }

    let resultStr: string = '(';
    const weekOfMonthResource = WEEK_OF_MONTH_MAP.get(this.byWeekNum[0]);
    if (!weekOfMonthResource) {
      return '';
    }
    const weekOfMonthStr = GlobalThis.getResourceStr(weekOfMonthResource, language);
    const dayOfWeekResource = DAY_OF_WEEK_MAP.get(this.byWeekDay[0]);
    const dayOfWeekStr = GlobalThis.getResourceStr(dayOfWeekResource, language);
    resultStr += weekOfMonthStr.replace('%s', '') + dayOfWeekStr;

    return resultStr += ')';
  }

  /**
   * 用户自定义时间
   * @param language 当前语言环境
   *
   * @return 重复时间
   */
  private toCustomString(language?: string): ResourceStr {
    let recurrenceString: string = '';
    if (this.freq === Frequency.DAILY) {
      recurrenceString = this.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_day'), this.interval, language).toString()
        : GlobalThis.getResourceStr($r('app.string.every_day_repeat'), language)
    } else if (this.freq === Frequency.WEEKLY) {
      let repeatWeeklyStr = this.formatByWeekDayToString(language);
      if (!language) {
        language = I18nUtil.getSystemLanguage();
      }
      // 西语下星期在句子中需要小写
      repeatWeeklyStr = language.includes('es') ? repeatWeeklyStr.toLowerCase() : repeatWeeklyStr;
      if (this.interval > 1) {
        recurrenceString += repeatWeeklyStr;
      } else {
        recurrenceString = GlobalThis.getResourceStrParms($r('app.string.every_week_repeat_of'), repeatWeeklyStr);
      }
      Log.info(TAG, `toCustomString WEEKLY recurrenceString : ${recurrenceString}`);
    } else if (this.freq === Frequency.MONTHLY) {
      recurrenceString = this.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_month'), this.interval, language).toString()
        : GlobalThis.getResourceStr($r('app.string.every_month_repeat'), language)
      recurrenceString += this.formatByWeekNumAndByWeekDayToString(language);
    } else if (this.freq === Frequency.YEARLY) {
      if (this.isLunarEvent()) {
        recurrenceString = this.interval > 1
          ? GlobalThis.getPluralStr($r('app.plural.every_repeat_year'), this.interval, language).toString()
          : GlobalThis.getResourceStr($r('app.string.every_lunar_year_repeat'), language)
      } else {
        recurrenceString = this.interval > 1
          ? GlobalThis.getPluralStr($r('app.plural.every_repeat_year'), this.interval, language).toString()
          : GlobalThis.getResourceStr($r('app.string.every_year_repeat'), language)
      }
    }
    if (this.freq === Frequency.WEEKLY && this.interval > DEFAULT_NUM) {
      return $r('app.plural.every_repeat_week_of', this.interval, this.interval, recurrenceString)
    }
    return recurrenceString;
  }
}