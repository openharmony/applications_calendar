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

import i18n from '@ohos.i18n';
import { LunarDateUtil } from '@app/common/src/main/ets/date/LunarDateUtil';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

/**
 * 传入date返回对应的年月日字符串，同年不显示年
 *
 * @param date 日期
 * @returns 格式化后的字符串
 */

export function getDateText(
  date: CalendarDate,
  eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR,
  isCard?: boolean,
): string {
  if (!date) {
    return '';
  }
  if (eventCalendarType === CalendarContract.AgendaCalendarType.LUNAR) {
    return LunarDateUtil.toLunarDateString(date, undefined, isCard);
  } else {
    const lang: string = i18n.System.getSystemLanguage();
    const now: CalendarDate = new CalendarDate();
    if (date.getUTCFullYear() === now.getUTCFullYear()) {
      return date.toLocaleDateString(lang, { month: 'long', day: 'numeric' });
    } else {
      return date.toLocaleDateString(lang, { year: 'numeric', month: 'long', day: 'numeric' });
    }
  }
}

/**
 * 传入time返回12/24小时制的时间格式
 *
 * @param time 时间
 * @returns 格式化后的字符串
 */

export function getTimeStr(time: number): string {
  const dateTime = new CalendarDate(time);
  return DateUtil.intlDateFormatChineseStyle(dateTime, {
    hour: 'numeric',
    minute: '2-digit',
    hour12: !I18nUtil.is24HourClock()
  });
}

/**
 * 传入年月日返回儒略日
 * @param year
 * @param month
 * @param monthDay
 * @returns
 */
export function date2julianDay(year: number, month: number, monthDay: number): number {
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