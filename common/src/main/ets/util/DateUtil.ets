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
import { I18nUtil } from './I18nUtil';
import intl from '@ohos.intl';
import { DateFormatter } from '../date/DateFormatter';
import { DateManager } from '../date/DateManager';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { GlobalThis } from '../data/GlobalThis';
import i18n from '@ohos.i18n';
import { Log } from '../default/common/Log';
import { LunarDateUtil } from '../date/LunarDateUtil';
import { SubscriptionCalendar } from '../constants/SettingEnumConstants';
import { CalendarDate } from '../date/CalendarDate';
import HashMap from '@ohos.util.HashMap';
import { TimeZoneUtil } from './TimeZoneUtil';

const TAG = 'DateUtil';

/**
 * 日期工具类
 *
 * @since 2022-03-21
 */
export enum AmOrPmChinese {
  AM_CHINESE = '上午',
  PM_CHINESE = '下午'
}

export enum AmOrPmChineseStyle {
  MIDNIGHT = '半夜',
  BEFORE_DAWN = '凌晨',
  DAWN = '清晨',
  EARLY_MORNING = '早上',
  MORNING = '上午',
  NOON = '中午',
  AFTERNOON = '下午',
  DUSK = '傍晚',
  EVENING = '晚上'
}

const MAX_DAY_IN_MONTH: Record<number, number> = {
  1: 31,
  3: 31,
  4: 30,
  5: 31,
  6: 30,
  7: 31,
  8: 31,
  9: 30,
  10: 31,
  11: 30,
  12: 31
};

export enum DayCapEnum {
  THE_DAY_BEFORE_YESTERDAY_GAP = -2,
  YESTERDAY_GAP = -1,
  TODAY_GAP = 0,
  TOMORROW_GAP = 1,
  THE_DAY_AFTER_TOMORROW_GAP = 2,
  OTHER_DAYS_GAP = 3,
}

const MATCH_HOUR: number = 2;

const MATCH_AM_OR_PM: number = 1;

const MATCH_MINUTE: number = 3;

export const HOURS_PER_DAY = 24;

// 一周7天
export const DAY_PER_WEEK: number = 7;

// 一年12个月
export const MONTH_PER_YEAR: number = 12;

// 一小时分钟数
export const MINUTES_PER_HOUR = 60;

// 一天分钟数
export const MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;

// 一分钟秒数
export const SECONDS_PER_MINUTE = 60;

// 一秒毫秒数
export const MILLS_PER_SECOND = 1000;

// 一分钟毫秒数
export const MILLS_PER_MINUTE = MILLS_PER_SECOND * SECONDS_PER_MINUTE;

// 一小时毫秒数
export const MILLS_PER_HOUR = MILLS_PER_MINUTE * MINUTES_PER_HOUR;

// 一天毫秒数
export const MILLS_PER_DAY = MILLS_PER_HOUR * HOURS_PER_DAY;

// 15天毫秒数
export const MILLS_FIFTEEN_DAYS = MILLS_PER_DAY * 15;

// 30天毫秒数
export const MILLS_THIRTY_DAYS = MILLS_PER_DAY * 30;

// 365天的毫秒数
export const MILLS_ONE_YEAR = MILLS_PER_DAY * 365;

// 一周毫秒数
export const MILLS_PER_WEEK = MILLS_PER_DAY * DAY_PER_WEEK;

// 年份下限值：公元1年
export const YEAR_LOWER_LIMIT: number = 1;

// 月份下限值：公元1年1月
export const MONTH_LOWER_LIMIT: number = YEAR_LOWER_LIMIT * 12 + 0;

// 年份上限值：公元5000年
export const YEAR_UPPER_LIMIT: number = 5000;

// 月份上限值：公元5000年12月
export const MONTH_UPPER_LIMIT: number = YEAR_UPPER_LIMIT * 12 + 11;

// 农历显示开始时间：1900年1月1日
export const LUNAR_START_TIME: number = 1900;

// 农历显示结束时间：2100年12月31日
export const LUNAR_END_TIME: number = 2100;

export enum WeekDisplay {
  MON = 'Monday',
  TUE = 'Tuesday',
  WED = 'Wednesday',
  THU = 'Thursday',
  FRI = 'Friday',
  SAT = 'Saturday',
  SUN = 'Sunday'
}

export const timeStringForDisplay: Resource[] = [
  $r('app.string.Sun'),
  $r('app.string.Mon'),
  $r('app.string.Tue'),
  $r('app.string.Wed'),
  $r('app.string.Thu'),
  $r('app.string.Fri'),
  $r('app.string.Sat')
]

export const weekMap: Resource[] = [
  $r('app.string.Sunday'),
  $r('app.string.Monday'),
  $r('app.string.Tuesday'),
  $r('app.string.Wednesday'),
  $r('app.string.Thursday'),
  $r('app.string.Friday'),
  $r('app.string.Saturday')
]

export class DateUtil {
  // 正则表达式：匹配中文下的日历时间
  // eg：“上午8:00”
  private static regularExpr: RegExp = new RegExp('([\u4e00-\u9fa5][\u4e00-\u9fa5])(1?[0-2]|[1-9]):([0-5][0-9])');
  private static formatCache: Map<string, intl.DateTimeFormat> = new Map();

  //timezone - offset 映射map
  private static timezoneCache: HashMap<string, number> = new HashMap();

  // 12小时制下，上午时间的中文显示
  private static readonly amChineseStyleMap: Map<number, string> = new Map([
    [1, AmOrPmChineseStyle.BEFORE_DAWN],
    [2, AmOrPmChineseStyle.BEFORE_DAWN],
    [3, AmOrPmChineseStyle.BEFORE_DAWN],
    [4, AmOrPmChineseStyle.BEFORE_DAWN],
    [5, AmOrPmChineseStyle.DAWN],
    [6, AmOrPmChineseStyle.DAWN],
    [7, AmOrPmChineseStyle.EARLY_MORNING],
    [8, AmOrPmChineseStyle.EARLY_MORNING],
    [9, AmOrPmChineseStyle.MORNING],
    [10, AmOrPmChineseStyle.MORNING],
    [11, AmOrPmChineseStyle.NOON],
    [12, AmOrPmChineseStyle.MIDNIGHT],
  ]);

  // 12小时制下，下午时间的中文显示
  private static readonly pmChineseStyleMap: Map<number, string> = new Map([
    [1, AmOrPmChineseStyle.AFTERNOON],
    [2, AmOrPmChineseStyle.AFTERNOON],
    [3, AmOrPmChineseStyle.AFTERNOON],
    [4, AmOrPmChineseStyle.AFTERNOON],
    [5, AmOrPmChineseStyle.DUSK],
    [6, AmOrPmChineseStyle.DUSK],
    [7, AmOrPmChineseStyle.EVENING],
    [8, AmOrPmChineseStyle.EVENING],
    [9, AmOrPmChineseStyle.EVENING],
    [10, AmOrPmChineseStyle.EVENING],
    [11, AmOrPmChineseStyle.MIDNIGHT],
    [12, AmOrPmChineseStyle.NOON],
  ]);

  /**
   * 根据偏移量计算年份月份信息，offset < 0表示前offset个月份，offset > 0表示后offset个月份
   * 公元1年1月往前展示公元5000年12月；公元5000年12月往后展示公元1年1月
   *
   * @param monthInfo 基准年份月份信息，基于此信息进行偏移计算
   * @param offset 月份偏移量
   * @return 计算偏移量后的年份月份信息，偏移后取当月1日的时间戳
   */
  static getOffsetMonthInfo(monthInfo: IMonthInfo, offset: number = 0): IMonthInfo {
    const year = monthInfo.year;
    const month = monthInfo.month;
    let sum = year * MONTH_PER_YEAR + month + offset;

    sum = DateUtil.countOffsetDepLimit(sum, MONTH_LOWER_LIMIT, MONTH_UPPER_LIMIT);

    const result: IMonthInfo = {
      year: 0,
      month: 0
    };
    result.year = Math.floor(sum / MONTH_PER_YEAR);
    result.month = sum % MONTH_PER_YEAR;
    return result;
  }

  /**
   * 根据月份偏移量计算时间戳
   *
   * @param timeStamp 时间戳
   * @param monthOffset 月份偏移量
   * @return 计算偏移量后的时间戳
   */
  static getOffsetMonthTimeStamp(timeStamp: number, monthOffset: number = 0): number {
    const date = new CalendarDate(timeStamp);
    const year = date.getFullYear();
    const month = date.getMonth();
    const curYear: number = new CalendarDate().getFullYear();
    const curMonth: number = new CalendarDate().getMonth();

    const result = DateUtil.getOffsetMonthInfo({ year, month }, monthOffset);
    const day: number = (curYear === result.year && curMonth === result.month) ? new CalendarDate().getDate() : 1

    return DateUtil.dateToStamp(result.year, result.month, day);
  }

  /**
   * 切换年视图时计算当前是否有选中，有的话切换时维持选中的当月当天，没有的话重置为1月1号
   *
   * @return 是否需要重置为1月1号
   */
  static isSelectDayInit(targetYear: number): boolean {
    const nowTime = new CalendarDate();
    let selectDay = DateManager.getInstance().selectedDay;
    // 是否选中当月当天
    const isSelectToday = nowTime.getMonth() + 1 === selectDay.solarMonth && nowTime.getDate() === selectDay.solarDay;
    // 是否滚动到当前年
    const isCurrentYear = nowTime.getFullYear() === targetYear;
    if (!isCurrentYear && isSelectToday) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * 根据边界值修正偏移量
   *
   * @param val 待修正的值
   * @param lowerLimit 下限值
   * @param upperLimit 上限值
   */
  static countOffsetDepLimit(val: number, lowerLimit: number, upperLimit: number): number {
    let result = val;
    if (result < lowerLimit) {
      result = upperLimit + result - lowerLimit + 1;
    } else if (result > upperLimit) {
      result = lowerLimit + result - upperLimit - 1;
    }
    return result;
  }

  /**
   * 格式化日期
   *
   * @param date 日期
   * @param fmt 格式化字符串
   * @returns 字符串
   */
  static dateFormat(date: CalendarDate | Date, fmt: string = 'YYYY-MM-dd HH:mm'): string {
    let ret: RegExpExecArray;
    const opt: Map<string, string> = new Map();
    opt.set('Y+', date.getFullYear() + '');
    opt.set('M+', (date.getMonth() + 1) + '');
    opt.set('d+', date.getDate() + '');
    opt.set('H+', date.getHours() + '');
    opt.set('m+', date.getMinutes() + '');
    opt.set('s+', date.getSeconds() + '');
    opt.set('S+', date.getMilliseconds() + '');
    opt.forEach((value, key) => {
      ret = new RegExp('(' + key + ')').exec(fmt) as RegExpExecArray;
      if (ret) {
        fmt = fmt.replace(ret[1], (value.length < ret[1].length
          ? DateUtil.padStart(value, ret[1].length, '0') : opt.get(key)) as string);
      }
    })
    return fmt;
  }

  /**
   * 格式化日期
   *
   * @param date 日期
   * @param fmt 格式化字符串
   * @returns 字符串
   */
  static dateFormatUTC(date: Date, fmt: string = 'YYYY-MM-dd HH:mm'): string {
    let ret: RegExpExecArray;
    const opt: Map<string, string> = new Map();
    opt.set('Y+', date.getUTCFullYear() + '');
    opt.set('M+', (date.getUTCMonth() + 1) + '');
    opt.set('d+', date.getUTCDate() + '');
    opt.set('H+', date.getUTCHours() + '');
    opt.set('m+', date.getUTCMinutes() + '');
    opt.set('s+', date.getUTCSeconds() + '');
    opt.set('S+', date.getUTCMilliseconds() + '');
    opt.forEach((value, key) => {
      ret = new RegExp('(' + key + ')').exec(fmt) as RegExpExecArray;
      if (ret) {
        fmt = fmt.replace(ret[1], (value.length < ret[1].length
          ? DateUtil.padStart(value, ret[1].length, '0') : opt.get(key)) as string);
      }
    })
    return fmt;
  }

  static lunarDateString(date: CalendarDate): string {
    const systemLanguage: string = i18n.System.getSystemLanguage();
    const dateTimeOptions: intl.DateTimeOptions = { 'weekday': 'long' };
    const dateFormat = DateUtil.intlDateFormat(date, dateTimeOptions, systemLanguage);
    Log.info(TAG, `lunarDateString dateFormat ${dateFormat}`);
    const lunarDate: string = `${LunarDateUtil.getLunarDate(date)} ${dateFormat}`;
    return lunarDate;
  }

  static getDayOffsetFromToday(timeStamp: number) {
    let current = new CalendarDate().setHours(0, 0, 0, 0);
    let offset = Math.ceil(Math.abs(current - timeStamp) / MILLS_PER_DAY) - 1;
    return offset;
  }

  /**
   * 获取目标日期与当前日期天数差值
   *
   * @param timeStamp 目标日期时间戳
   * @param type 倒数日-2 正数日-1
   * @returns 返回目标日期与当前日期天数差值
   */
  static getDayOffset(timeStamp: number, type: number = 1, displayDate?: number, language?: string): ContentType {
    let current = new CalendarDate().setHours(0, 0, 0, 0);
    if (displayDate) {
      current = new CalendarDate(displayDate).setHours(0, 0, 0, 0);
    }
    timeStamp = new CalendarDate(timeStamp).setHours(0, 0, 0, 0);
    if (timeStamp <= current) {
      let dayOffset = Math.ceil((current - timeStamp) / MILLS_PER_DAY)
      if (type === CalendarContract.EventImportantType.ANNIVERSARIES) {
        // 纪念日当天也按一天（与双框架保持一致）
        dayOffset += 1;
      }
      if (type === CalendarContract.EventImportantType.COUNTDOWN ||
        type === CalendarContract.EventImportantType.HOLIDAY) {
        dayOffset = 0
      }
      return {
        unit: $r('app.plural.in_days', dayOffset, ''),
        dayOffset: dayOffset,
        content: dayOffset === 0 ? '' : GlobalThis.getPluralStr($r('app.plural.in_days'), dayOffset, language).toString(),
        type: type === CalendarContract.EventImportantType.COUNTDOWN ? 'days_later' : 'in_days',
      }
    } else if (timeStamp > current) {
      let dayOffset = Math.ceil((timeStamp - current) / MILLS_PER_DAY);
      return {
        unit: $r('app.plural.days_later', dayOffset, ''),
        dayOffset: dayOffset,
        content: GlobalThis.getPluralStr($r('app.plural.days_later'), dayOffset, language).toString(),
        type: 'days_later',
      }
    } else {
      if (type === CalendarContract.EventImportantType.COUNTDOWN ||
        type === CalendarContract.EventImportantType.HOLIDAY) {
        return {
          unit: $r('app.plural.days_later', 1, ''),
          dayOffset: 0,
          content: '',
          type: 'days_later',
        }
      } else {
        return {
          unit: $r('app.plural.in_days', 1, ''),
          dayOffset: 1,
          content: GlobalThis.getPluralStr($r('app.plural.in_days'), 1, language).toString(),
          type: 'in_days',
        }
      }
    }
  }

  /**
   * 字符串前置补全
   *
   * @param str 待补全的目标字符串
   * @param targetLen 目标字符串长度
   * @param padStr 补充的字符
   */
  static padStart(str: string, targetLen: number, padStr: string): string {
    targetLen = targetLen >> 0;
    padStr = String(padStr || ' ');
    if (str.length > targetLen) {
      return String(str);
    } else {
      targetLen = targetLen - str.length;
      if (targetLen > padStr.length) {
        padStr += padStr.repeat(targetLen / padStr.length);
      }
      return padStr.slice(0, targetLen) + String(str);
    }
  }

  /**
   * 根据年月日获取0点的时间戳
   * @param year
   * @param month
   * @param day
   * 计算公式：
   * 系统默认时区时间戳（Date()时区为系统默认时区）= 年月日（UTC GMT + 0时区） +偏移量1  ---1式
   * 目标地区日期时间戳= 年月日（UTC GMT + 0时区） +偏移量2  ---2式
   * 2式-1式： 目标地区日期时间戳=当前时区时间戳+偏移量2-偏移量1
   * @returns 目标地区日期对应的时间戳
   */
  static dateToStamp(year: number, month: number, day: number): number {
    if (year <= 1582) { // 针对1582年10月消失的10天做的特殊处理,Date()并不会对消失的10天做特殊处理故改为使用CalendarDate
      return new CalendarDate(year, month, day).setHours(0, 0, 0, 0);
    }
    const date: Date = new Date(year, month, day);
    let tempTime = date.getTime() + DateUtil.getTimeZoneOffset(I18nUtil.getSystemTimeZone(), date.getTime()) -
      DateUtil.getTimeZoneOffset(CalendarDate.timeZone, date.getTime());
    // 处理夏令时导致的时间戳异常，夏令时时获取的当前零点的时间戳实际上指向的是上一天的23点，因此需要额外偏移一个小时
    if (new CalendarDate(tempTime).getHours() === 23) {
      tempTime += MILLS_PER_HOUR;
    }
    return tempTime;
  }

  /**
   * 判断年月日信息和Date表示的是否是同一天
   */
  static isSameDay(date1: CalendarDate, data2: CalendarDate): boolean {
    return (date1.getDate() === data2.getDate() && date1.getMonth() === data2.getMonth() &&
      date1.getFullYear() === data2.getFullYear())
  }

  static isSameDayTimeStamp(stamp1: number, stamp2: number): boolean {
    const timeZoneOffset = DateUtil.getTimeZoneOffset(CalendarDate.timeZone, stamp1);

    // 获取当前系统默认时区偏移量
    const offset = DateUtil.getTimeZoneOffset(I18nUtil.getSystemTimeZone(), stamp1);

    // 将时间戳转换为UTC GMT+0时间，再加目标时区的偏移量，得到目标时区的时间
    const gmtDate1 = new Date(stamp1 - offset + timeZoneOffset);
    const gmtDate2 = new Date(stamp2 - offset + timeZoneOffset);
    Log.info(TAG,`isSameDayTimeStamp  gmtDate1: ${gmtDate1.toString()}  gmtDate2: ${gmtDate2.toString()}`)
    // 比较年、月、日
    return DateUtil.isSameYearMonthDay(gmtDate1, gmtDate2);
  }

  /**
   * 比较两个date年月日是否相等
   * @param date1
   * @param date2
   * @returns
   */
  static isSameYearMonthDay(date1: Date, date2: Date) {
    return (
      date1.getFullYear() === date2.getFullYear() &&
        date1.getMonth() === date2.getMonth() &&
        date1.getDate() === date2.getDate()
    );
  }

  /**
   * 获取锁定时区的偏移量（单位是毫秒）
   * @returns
   */
  static getTimeZoneOffset(timezoneId: string, timeStamp: number): number {
    if (!DateUtil.timezoneCache.hasKey(timezoneId)) {
      DateUtil.timezoneCache.set(timezoneId,
        TimeZoneUtil.getTimeZoneOffset(timezoneId, timeStamp));
    }
    return DateUtil.timezoneCache.get(timezoneId);
  }

  /**
   * 获取区域默认一周开始日
   * getFirstDayOfWeek返回的数值是1~7，算法接口的数值范围是0~6，所以需要-1
   *
   * @return 区域默认一周开始日
   */
  static getDefaultStartOfWeek(): number {
    const locale = i18n.System.getSystemLocale();
    return I18nUtil.getCalendar(locale).getFirstDayOfWeek() - 1;
  };

  /**
   * 根据系统语言，使用intl和i18n进行日期格式化
   *
   * @param date 日期
   * @param dateTimeOptions 格式化选项
   * @return 格式化后的字符串
   */
  static intlDateFormat(date: CalendarDate, dateTimeOptions: intl.DateTimeOptions, systemLanguage?: string): string {
    return DateUtil.intlDateFormatOri(date.getDateInfo(), dateTimeOptions, systemLanguage) ?? '';
  }

  static intlDateFormatOri(date: Date, dateTimeOptions: intl.DateTimeOptions, systemLanguage?: string): string {
    let result = DateFormatter.instance().format(date, dateTimeOptions, systemLanguage) ?? '';
    return result;
  }

  static intlCardDateFormat(date: Date, opt: intl.DateTimeOptions, systemLanguage: string): string {
    const language: string = systemLanguage;
    const key: string = language + JSON.stringify(opt);
    if (DateUtil.formatCache.has(key)) {
      return DateUtil.formatCache.get(key)?.format(date) ?? '';
    }

    const locale: intl.Locale | undefined = language ? new intl.Locale(language) : undefined;
    if (!locale) {
      return '';
    }
    const dateFormat: intl.DateTimeFormat = new intl.DateTimeFormat(locale?.toString(), opt);
    DateUtil.formatCache.set(key, dateFormat);
    return dateFormat.format(date) ?? '';
  }

  /**
   * 获取时间戳在锁定时区的年月日(Date), 返回的data只用户显示年月日信息，
   */
  static getLockTimeZoneDate(stamp: number): Date {
    const timeZoneOffset = DateUtil.getTimeZoneOffset(CalendarDate.timeZone, Date.now());

    // 获取当前系统默认时区偏移量
    const offset = DateUtil.getTimeZoneOffset(I18nUtil.getSystemTimeZone(), Date.now());
    return new Date(stamp - offset + timeZoneOffset);
  }

  /**
   * 根据系统语言，进行日期格式化
   *
   * @param date 日期
   * @return 格式化后的字符串
   */
  static getDateText(date: CalendarDate): string {
    let now = new CalendarDate();
    let option: Record<string, string> = { 'month': 'long', 'day': 'numeric' }
    if (date.getFullYear() !== now.getFullYear()) {
      option = { 'year': 'numeric', 'month': 'long', 'day': 'numeric' }
    }
    return DateUtil.intlDateFormatChineseStyle(date, option)
  }

  /**
   * 根据系统语言，使用intl和i18n进行日期格式化 (12小时制进行中文本土化特殊处理)
   *
   * @param date 日期
   * @param dateTimeOptions 格式化选项
   */
  static intlDateFormatChineseStyle(date: CalendarDate | Date, dateTimeOptions: intl.DateTimeOptions,
                                    isCard: boolean = false): string {
    if (date instanceof CalendarDate) {
      return DateUtil.intlDateFormatChineseStyle(date.getDateInfo(), dateTimeOptions, isCard);
    }
    let systemLanguage: string = '';
    let is24HourClock: boolean = true;
    systemLanguage = i18n.System.getSystemLanguage();
    is24HourClock = i18n.System.is24HourClock();
    if (isCard) {
      dateTimeOptions.hour12 = !is24HourClock;
    }
    if (!dateTimeOptions.timeZone) {
      dateTimeOptions.timeZone = CalendarDate.timeZone;
    }
    const isChineseLanguage: boolean = I18nUtil.isChineseLanguage(systemLanguage);

    let dateFormat: string = ''
    if (!isCard) {
      dateFormat = DateUtil.intlDateFormatOri(date, dateTimeOptions, systemLanguage);
    } else {
      dateFormat = DateUtil.intlCardDateFormat(date, dateTimeOptions, systemLanguage);
    }

    // 中文语言和12小时制下对时间本土化特殊处理
    if (isChineseLanguage && !is24HourClock) {
      // 对正则表达式的指针位置 0 处理
      DateUtil.regularExpr.lastIndex = 0;
      // 根据正则表达式正则匹配中文 12 小时制时间
      let matchDateFormat = DateUtil.regularExpr.exec(dateFormat);
      if (matchDateFormat != null) {
        // 正则匹配的“上午”和 “下午”
        const amOrPmReg = matchDateFormat[1];
        // 正则匹配的“小时”
        const hourReg = Number(matchDateFormat[2]);
        // 正则匹配的“分钟”
        const minuteReg = matchDateFormat[3];
        const amOrPmChineseStyle = DateUtil.transDateFormatToChineseStyle(amOrPmReg, hourReg);
        //手动12小时制补0
        const needReplaceStr = amOrPmReg + matchDateFormat[2];
        const replaceStr = amOrPmChineseStyle + (hourReg < 10 ? '0' + matchDateFormat[2] : matchDateFormat[2]);
        dateFormat = dateFormat.replace(needReplaceStr, replaceStr);
      }
    }
    Log.debug(TAG, `timeZone:${CalendarDate.timeZone}  dateFormat:${dateFormat} `)
    return dateFormat;
  }

  /**
   * 对 12小时制 进行中文本土化特殊处理：如 “上午” 转换为 “半夜”
   *
   * @param amOrPm “上午”和 “下午”
   * @param hour 小时
   * @return 格式化后的字符串
   * 规则：
   * 上午1:00 =< time < 上午5:00 : 凌晨
   * 上午5:00 =< time < 上午7:00 : 清晨
   * 上午7:00 =< time < 上午9:00 : 早上
   * 上午9:00 =< time < 上午11:00 : 上午
   * 上午11:00 =< time < 下午1:00 : 中午
   * 下午1:00 =< time < 下午5:00 : 下午
   * 下午5:00 =< time < 下午7:00 : 傍晚
   * 下午7:00 =< time < 下午11:00 : 晚上
   * 下午11:00 =< time < 上午1:00 : 半夜
   */
  static transDateFormatToChineseStyle(amOrPm: string, hour: number): string {
    if (amOrPm === AmOrPmChinese.AM_CHINESE) {
      let str = DateUtil.amChineseStyleMap.get(hour);
      if (typeof str === 'string') {
        return str;
      }
    } else if (amOrPm === AmOrPmChinese.PM_CHINESE) {
      let str = DateUtil.pmChineseStyleMap.get(hour);
      if (typeof str === 'string') {
        return str;
      }
    }
    return '';
  }

  /**
   * 获取国际化月份
   *
   * @param month 月份。0~11
   * @return 国际化月份字符
   */
  static getMonthTitle(month: number, language?: string): string {
    const systemLanguage = language ? language : I18nUtil.getSystemLanguage();
    const date = new CalendarDate();
    date.setMonth(month, 1);
    const res = DateFormatter.instance().format(date.getDateInfo(), { month: 'short' }, systemLanguage) ?? '';
    return res;
  }

  /**
   * 获取国际化星期字符
   *
   * @param isYearView 是否为年视图
   * @return 字符数组
   */
  static getWeekTitle(isYearView?: boolean, language?: string): string[] {
    const systemLanguage = language ? language : I18nUtil.getSystemLanguage();
    const isChineseLanguage = I18nUtil.isChineseLanguage(systemLanguage);
    const date = new CalendarDate();
    const weekDay = date.getDay(); // 返回一周（0~6）的某一天的数字。星期天为 0, 星期一为 1, 以此类推。
    const sundayTimestamp = date.getTime() - weekDay * MILLS_PER_DAY;

    return new Array(DAY_PER_WEEK).fill('').map((day: number, i) => {
      const date = new CalendarDate(sundayTimestamp + i * MILLS_PER_DAY);
      if (isChineseLanguage || isYearView) {
        return DateUtil.intlDateFormat(date, { weekday: 'narrow' }, systemLanguage);
      } else {
        return DateUtil.intlDateFormat(date, { weekday: 'short' }, systemLanguage).toLocaleUpperCase();
      }
    });
  }

  /**
   * 日期转儒略日
   * @param year 年
   * @param month 月
   * @param monthDay 日
   */
  static date2julianDay(year: number, month: number, monthDay: number): number {
    let diff: number = 0;
    let mMonth = month;
    let mYear = year;
    if (mMonth <= 2) {
      mMonth += 12;
      mYear -= 1;
    }
    if (mYear * 372 + mMonth * 31 + monthDay >= 588829) {
      diff = Math.floor(mYear / 100);
      diff = Math.floor(2 - diff + mYear / 400);
    }
    let dd: number = monthDay + 0.5000115740;
    return Math.floor(Math.floor(365.25 * (mYear + 4716) + 0.01) +
    Math.floor(30.60001 * (mMonth + 1)) + dd + diff - 1524.5);
  }

  /**
   * 根据时间戳获取儒略日
   * @param timeStamp 时间戳，若不传入则返回当前时间儒略日
   */
  static getJulianDay(timeStamp?: number): number {
    return new CalendarDate(timeStamp).getJulianDay();
  }

  /**
   * 儒略日转CalendarDate日期
   *
   * @param julianDay 儒略日
   */
  static julianDay2Date(julianDay: number): CalendarDate {
    const date = DateUtil.julianDay2OriDate(julianDay);
    return new CalendarDate(date)
  }

  /**
   * 儒略日转CalendarDate日期
   *
   * @param julianDay 儒略日
   */
  static julianDay2OriDate(julianDay: number): Date {
    let count: number;
    let tempJulianDay = julianDay;
    if (tempJulianDay >= 2299161) {
      count = Math.floor((tempJulianDay - 1867216.25) / 36524.25);
      tempJulianDay += 1 + count - Math.floor(count / 4);
    }
    tempJulianDay += 1524;
    let year = 0;
    year = Math.floor((tempJulianDay - 122.1) / 365.25);
    tempJulianDay -= Math.floor(365.25 * year);
    let month = 0;
    month = Math.floor(tempJulianDay / 30.601);
    tempJulianDay -= Math.floor(30.601 * month);
    let monthDay = 0;
    monthDay = tempJulianDay;
    if (month > 13) {
      month -= 13;
      year -= 4715;
    } else {
      month -= 1;
      year -= 4716;
    }
    return new Date(year, month - 1, monthDay);
  }

  /**
   * 取余获取时间戳所表示当天的0点0分0秒时间戳
   */
  static getStartOfDayTimeStamp(dateStamp?: number, supportLockTimeZone: boolean = true): number {
    const startOfDay = supportLockTimeZone ?
      new CalendarDate(dateStamp) : dateStamp ? new Date(dateStamp) : new Date();
    startOfDay.setHours(0, 0, 0, 0); // 设置时间为零点
    return startOfDay.getTime();
  }

  /**
   * 取余获取date当天的0点0分0秒时间对象
   */
  static getStartOfDay(date: CalendarDate): CalendarDate {
    const startOfDay = new CalendarDate(date.getTime());
    startOfDay.setHours(0, 0, 0, 0); // 设置时间为零点
    return startOfDay;
  }

  /**
   * 从页面传入的 startOfWeek 进行解析，获取一周开始日
   *
   * @param startOfWeek 从界面传入的一周开始记录，存在其值为-1 的场景，此时为需要根据当地时间获取默认的一周开始日
   * @return _startOfWeek 根据默认值修正的实际的一周开始日
   */
  static getStartOfWeek(startOfWeek: number): number {
    let _startOfWeek: number;
    if (startOfWeek === -1) {
      _startOfWeek = DateUtil.getDefaultStartOfWeek();
    } else {
      _startOfWeek = startOfWeek;
    }
    return _startOfWeek;
  }

  /**
   * 获取date当天起始的毫秒数 00:00:00.000
   *
   * @param date date当天
   * @returns 起始毫秒数
   */
  static getStartMillsOfDate(date: CalendarDate): number {
    const temp: CalendarDate = new CalendarDate(date.getTime());
    temp.setHours(0, 0, 0, 0);
    let timeStamp = temp.getTime();
    if (temp.getHours() !== 0) {
      timeStamp += (HOURS_PER_DAY - temp.getHours()) * MILLS_PER_HOUR;
    }
    return timeStamp;
  }

  /**
   * 获取date当天结束的毫秒数 23:59:59.999
   *
   * @param date date当天
   * @returns 结束毫秒数
   */
  static getEndMillsOfDate(date: CalendarDate): number {
    const temp: CalendarDate = new CalendarDate(date.getTime());
    temp.setHours(23, 59, 59, 999);
    return temp.getTime();
  }

  /**
   * 获取一个月最多有多少天
   *
   * @param year 年份，用于判断闰年
   * @param realMonth 真实月份，1-12 1表示1月 12表示12月
   * @returns 当年当月的天数
   */
  static getMaxDayInMonth(year: number, realMonth: number): number {
    if (realMonth > 12) {
      realMonth %= 12;
    }
    if (realMonth === 2) {
      const isLeapYear: boolean = DateUtil.isLeapYear(year);
      return isLeapYear ? 29 : 28;
    } else {
      return MAX_DAY_IN_MONTH[realMonth];
    }
  }

  /**
   * 是否是闰年
   */
  static isLeapYear(year: number): boolean {
    return (year % 4 === 0) && ((year % 100 !== 0) || (year % 400 === 0));
  }

  /**
   * 显示时间
   *
   * @param inputTime 消息时间
   * @returns 显示时间字串
   */
  static formatTimeDistanceFromNow(inputTime: CalendarDate): string {
    const currentTime = new CalendarDate();
    const timeDiff = DateUtil.get24HoursStartTime(currentTime.getTime()) - inputTime.getTime();
    let locale: string = 'zh-CN';
    let localeMonth: 'numeric' | '2-digit' | 'long' | 'short' | 'narrow' | undefined = 'long';
    const lang: string = i18n.System.getSystemLanguage();
    if (lang === 'en-Latn-US') {
      locale = 'en-US';
      localeMonth = 'numeric';
    }

    if (timeDiff <= 0) {
      // 0点到当前24小时之内，显示具体时间点
      return inputTime.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
    } else if (timeDiff < MILLS_PER_DAY) {
      // 超过24小时-48小时，显示昨天
      return GlobalThis.getResourceStr($r('app.string.yesterday'));
    } else if (timeDiff < MILLS_PER_WEEK) {
      // 48小时以上，显示相应的星期几
      const week = inputTime.getDay();
      return GlobalThis.getResourceStr(timeStringForDisplay[week]);
    } else if (
      inputTime.getFullYear() === currentTime.getFullYear()
    ) {
      // 超过一周，但在当年内，显示xx月xx日
      return inputTime.toLocaleDateString(locale, { month: localeMonth, day: 'numeric' });
    } else {
      // 超过当年，显示xx年xx月xx日
      return inputTime.toLocaleDateString(locale, { year: 'numeric', month: localeMonth, day: 'numeric' });
    }
  }

  // 根据时间显示xx年xx月xx日
  static formatTimeFromInputTime(inputTime: CalendarDate): string {
    let locale: string = 'zh-CN';
    let localeMonth: 'numeric' | '2-digit' | 'long' | 'short' | 'narrow' | undefined = 'long';
    return inputTime.toLocaleDateString(locale, { year: 'numeric', month: localeMonth, day: 'numeric' });
  }

  // 一天开始时间戳
  static get24HoursStartTime(timestamp: number): number {
    let newTimeStamp = new CalendarDate(timestamp).setHours(0, 0, 0, 0);
    const newDate = new CalendarDate(newTimeStamp); // 当天开始时间戳
    if (newDate.getHours() !== 0) {
      newTimeStamp += (HOURS_PER_DAY - newDate.getHours()) * MILLS_PER_HOUR;
    }
    return newTimeStamp; // 当天开始时间戳
  }

  /**
   * 获取新建日程的默认开始时间，当前时间的分秒值 + 传入时间的日期值
   * 如果当前时间为整点或半点刚过一分钟内，默认开始时间为当前整点或半点
   * 如果当前时间为整点或半点超过一分钟，默认开始时间为下一个整点或半点
   * @param dateParam 需要创建的时间的日期对象
   * @param needSaveTime: number = 0 外部传入的保留时间标志,若存在,则不对传入时间作截取操作
   */
  static getStartDateByCombine(dateParam: number, needSaveTime: number): CalendarDate {
    let nowTimeMills = dateParam;
    const halfHourMills = MILLS_PER_HOUR / 2;
    const oneMinuteMills = MILLS_PER_MINUTE;
    //是否需要保留传入时间的分秒值
    if (!needSaveTime || needSaveTime !== 1) { //无需保留时分
      const now = new CalendarDate();
      // 保留传入的日期
      const nowBeyondZeroTimeMills = now.getTime() - DateUtil.getStartOfDayTimeStamp();
      // 新的时间 = 当前时间的分秒值 + 传入时间的日期值
      const beginOfNewAgenda = DateUtil.getStartOfDayTimeStamp(dateParam);
      const nowOfNewAgenda = new CalendarDate(beginOfNewAgenda + nowBeyondZeroTimeMills);
      nowTimeMills = nowOfNewAgenda.getTime();
    } else { //需要保留时分
      //传入时间减去半小时以取其区间
      nowTimeMills = nowTimeMills - halfHourMills;
    }
    // 如果当前时间为整点或半点刚过一分钟内，默认开始时间为当前整点或半点
    if (nowTimeMills % halfHourMills < oneMinuteMills) {
      return new CalendarDate(Math.trunc(nowTimeMills / oneMinuteMills) * oneMinuteMills);
    }
    // 如果当前时间为整点或半点超过一分钟，默认开始时间为下一个整点或半点
    return new CalendarDate(Math.trunc(nowTimeMills / halfHourMills) * halfHourMills + halfHourMills);
  }

  /**
   * 1900 1.1 - 2100 12.31 显示农历（R2的规格）
   */
  static isNeedDisplayLunaMonth(year: number): boolean {
    return year >= LUNAR_START_TIME && year <= LUNAR_END_TIME;
  }

  /**
   * 获取startTime到endTime之间的天数，向下取整
   * @param startTime 开始时间戳
   * @param endTime 结束时间戳
   */
  static getDiffDays(startTime: number, endTime: number): number {
    return Math.floor((endTime - startTime) / MILLS_PER_DAY);
  }

  /**
   * 获取当前的日期与展示日期的天数距离，返回UI界面显示的具体文字
   *
   * @param time 展示的日期
   * @param language 当前语言,刷新用
   * @return DateTime 月视图日程图层显示的当前日期与展示日期的距离文字
   */
  static getDateTime(time: CalendarDate, language: string, currentTime: number): string {
    const currentDate: CalendarDate = new CalendarDate(currentTime);
    const today = new CalendarDate(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate()).getTime();
    const selectTime: number = DateUtil.getStartOfDay(time).getTime();
    const gapTime = Math.round((selectTime - today) / MILLS_PER_DAY);
    let dateString: string;
    switch (gapTime) {
      case DayCapEnum.THE_DAY_BEFORE_YESTERDAY_GAP: {
        dateString = DateUtil.checkEnglishForStr(language,
          $r('app.plural.days_ago'), $r('app.string.the_day_before_yesterday'), Math.abs(gapTime));
        break;
      }
      case DayCapEnum.YESTERDAY_GAP: {
        dateString = GlobalThis.getResourceStr($r('app.string.yesterday'), language);
        break;
      }
      case DayCapEnum.TODAY_GAP: {
        dateString = GlobalThis.getResourceStr($r('app.string.today'), language);
        break;
      }
      case DayCapEnum.TOMORROW_GAP: {
        dateString = GlobalThis.getResourceStr($r('app.string.tomorrow'), language);
        break;
      }
      case DayCapEnum.THE_DAY_AFTER_TOMORROW_GAP: {
        dateString = DateUtil.checkEnglishForStr(language,
          $r('app.plural.days_later'), $r('app.string.the_day_after_tomorrow'), gapTime);
        break;
      }
      default:
        if (gapTime >= DayCapEnum.OTHER_DAYS_GAP) {
          dateString = GlobalThis.getPluralStr($r('app.plural.days_later'),
            gapTime, language);
        } else {
          dateString = GlobalThis.getPluralStr($r('app.plural.days_ago'),
            Math.abs(gapTime), language);
        }
        break;
    }
    return dateString;
  }

  /**
   * 根据语言获取不同的天数字符串,英文下前天和后天的文字太长因此改为x天前和x天后
   * @param language 语言
   * @param enStr 英文字符串
   * @param cnStr 中午字符串
   * @param gapTime 英文用距当天天数
   * @returns
   */
  static checkEnglishForStr(language: string, enStr: Resource, cnStr: Resource, gapTime: number): string {
    const isEnglish = language.split('-')[0].toLocaleLowerCase() === 'en';
    return isEnglish ?
    GlobalThis.getPluralStr(enStr,
      gapTime, language) :
    GlobalThis.getResourceStr(cnStr,
      language);
  }

  /**
   * 根据历法获取显示的农历日期
   * @param time 选中时间
   * @param subscriptionCalendar 当前历法
   * @param systemRegion 当前地区
   * @returns 农历日期(农历五月廿四)
   */
  static getCalendarTime(time: CalendarDate, subscriptionCalendar: SubscriptionCalendar, systemRegion: string) {
    const dateTime = new CalendarDate(time.getFullYear(), time.getMonth(), time.getDate(), 8);
    Log.info(TAG, `Lunar time of the Current display date: ${dateTime} region: ${systemRegion}`);
    switch (subscriptionCalendar) {
      case SubscriptionCalendar.CHINESE_CALENDAR:
        if (!DateUtil.isNeedDisplayLunaMonth(time.getFullYear())) {
          return '';
        }
        return LunarDateUtil.toFullLunarDateString(dateTime);
      case SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR:
        let calendar: i18n.Calendar = i18n.getCalendar(systemRegion, 'islamic_civil');
        const date: Date = new Date(dateTime.getTime());
        calendar.setTime(date);
        const timeOption: intl.DateTimeOptions = { year : 'numeric', month: 'long', day: 'numeric' };
        const dateStr = DateUtil.intlDateFormatChineseStyle(new CalendarDate(calendar.get('year'),
          calendar.get('month'), calendar.get('date')), timeOption);
        return calendar.getDisplayName(I18nUtil.getSystemLanguage()) + dateStr;
    }
    return '';
  }

  // 转换时区到UTC
  static changeToUTCTime(time: number, showTime: boolean = true, offset: number = 0) {
    let date = new CalendarDate(time);
    let year = date.getUTCFullYear();
    let month = date.getUTCMonth();
    let day = date.getUTCDate();
    let hour = date.getUTCHours();
    let minute = date.getUTCMinutes();
    if (showTime) {
      return Date.UTC(year, month, day + offset, hour, minute);
    } else {
      return Date.UTC(year, month, day + offset);
    }
  }

  /**
   * 传入date判断返回对应格式，同年不显示年
   *
   * @param date 日期
   * @returns 格式化标准
   */
  static judgmentDateDisplay(date: CalendarDate): intl.DateTimeOptions {
    const now = new CalendarDate();
    if (date.getUTCFullYear() === now.getUTCFullYear()) {
      return { month: 'short', day: 'numeric' };
    }
    return { year: 'numeric', month: 'short', day: 'numeric' };
  }

  /**
   * 获取当前周的开始时间（周一00:00:00.000）的毫秒时间戳
   * @returns number 当前周开始时间的毫秒时间戳
   */
  static getStartOfCurrentWeek(timeStamp?: number): number {
    // 获取当前时间
    let now = new Date();
    if (timeStamp) {
      now = new Date(timeStamp)
    }

    // 计算本周开始时间（周一00:00:00）
    const dayOfWeek = now.getDay(); // 0是周日，1是周一...6是周六
    const diff = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1); // 调整为周一
    const startOfWeek = new Date(now.setDate(diff));
    startOfWeek.setHours(0, 0, 0, 0);

    return startOfWeek.getTime();
  }

  /**
   * 获取当前周的结束时间（周日23:59:59.999）的毫秒时间戳
   * @returns number 当前周结束时间的毫秒时间戳
   */
  static getEndOfCurrentWeek(): number {
    // 先获取本周开始时间
    const startOfWeek = new Date(DateUtil.getStartOfCurrentWeek());

    // 计算本周结束时间（周日23:59:59.999）
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    return endOfWeek.getTime();
  }

  /**
   * 对时间段、日期段进行格式化。
   * @param startDate
   * @param endDate
   */
  static formatRange(startTimeStamp: number, endTimeStamp: number,
                     dateTimeFormatOptions: Intl.DateTimeFormatOptions =
                     { year: 'numeric', month: 'numeric', day: 'numeric' }): string {

    Log.info(TAG, `formatRange timeStamp: ${startTimeStamp}-${endTimeStamp}`);
    let is24HourClock: boolean = true;
    is24HourClock = i18n.System.is24HourClock();
    dateTimeFormatOptions.hour12 = !is24HourClock;

    if (!dateTimeFormatOptions.timeZone) {
      dateTimeFormatOptions.timeZone = CalendarDate.timeZone;
    }
    const locales: string = i18n.System.getSystemLocale();
    const formatter = new Intl.DateTimeFormat(locales, dateTimeFormatOptions);
    let formattedDateRange: string = formatter.formatRange(startTimeStamp, endTimeStamp);
    Log.info(TAG, `formatRange dateRangeStr: ${formattedDateRange}`);
    return formattedDateRange;
  }

}

/**
 * Month Info
 *
 * year: full year of Date
 * month: month of Date enumerate from 0 to 11 in the Gregorian calendar
 */
export interface IMonthInfo {
  year: number;
  month: number;
}

class ContentType {
  public unit: Resource = $r('app.plural.in_days');

  public dayOffset: number = 0;

  public content: string = '';

  public type: string = '';
}

