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

import { DateUtil, HOURS_PER_DAY, MINUTES_PER_DAY, MINUTES_PER_HOUR, DAY_PER_WEEK } from './DateUtil';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import intl from '@ohos.intl';
import { i18n } from '@kit.LocalizationKit';

// 全天日程固定以当天9点为提醒计算的基准点，不同于普通日程是以日程dtstart为基准点，因此需要做固定偏移计算
const ALL_DAY_HOUR_OFFSET: number = 9;

export const NO_REMINDER_VALUE = -1;

const TAG: string = 'ReminderUtil';

interface AllDayReminderInfo {
  dayOffset: number;
  hour: number;
  minute: number;
}

export class ReminderUtil {

  /**
   * 根据用户设置的全天日程提醒偏移天数，和设置的提醒时间点，计算出存数据库Reminder表的minute值
   *
   * 全天日程的提醒基准点是当天9点，因此需要固定减去9个小时(存储侧)的偏移量。
   * 提醒设置正数是提前，负数是延后，10点是-1h，8点是1h，0点是9h。
   *
   * @param dayOffset 提前多少天
   * @param hour 设定的提醒时间是几点
   * @param minute 设定的提醒时间是几分
   * @returns 存数据库Reminder表的minute实际值
   */
  public static generateAllDayReminderMinute(dayOffset: number, hour: number, minute: number): number {
    const hourOffset = -(hour - ALL_DAY_HOUR_OFFSET);
    const minuteOffset = -minute;
    return dayOffset * MINUTES_PER_DAY + hourOffset * MINUTES_PER_HOUR + minuteOffset;
  }

  /**
   * 根据数据库Reminders表的minute值，解析出用户设置的提醒偏移天数，以及几点几分，用于详情页展示。
   *
   * 与 #{generateAllDayReminderMinute} 成对执行，一个转换为相对分钟数，一个转换为天、时、分
   *
   * @param reminderMinute 数据库Reminders表的minute值
   * @returns 天、时、分的数据结构
   */
  public static parseAllDayReminderMinute(reminderMinute: number): AllDayReminderInfo {
    let dayOffset: number =
      reminderMinute >= 0 ? Math.floor(reminderMinute / MINUTES_PER_DAY) : Math.ceil(reminderMinute / MINUTES_PER_DAY);
    const remainingMinute = reminderMinute % MINUTES_PER_DAY;

    let hourOffset = remainingMinute >= 0 ? Math.floor(remainingMinute / MINUTES_PER_HOUR) :
      Math.ceil(remainingMinute / MINUTES_PER_HOUR);
    const minuteOffset = remainingMinute % MINUTES_PER_HOUR;
    let minute = -minuteOffset;

    if (minute < 0) {
      minute += MINUTES_PER_HOUR;
      hourOffset++;
    } else if (minute > 60) {
      minute -= MINUTES_PER_HOUR;
      hourOffset--;
    }

    let hour = ALL_DAY_HOUR_OFFSET - hourOffset;
    if (hour < 0) {
      hour += HOURS_PER_DAY;
      dayOffset++;
    } else if (hour > HOURS_PER_DAY) {
      hour -= HOURS_PER_DAY;
      dayOffset--;
    }
    return {
      dayOffset: dayOffset,
      hour: hour,
      minute: minute
    } as AllDayReminderInfo;
  }

  /**
   * 三方适配XX分钟/XX小时/天前/后
   *
   * @param remindMinutes: 提醒时间
   * @param mIsAllDay：是否全天日程
   * @param language：当前系统语言
   */
  public static getReminderText(remindMinutes: number, mIsAllDay: boolean, language: string): ResourceStr {
    Log.info(TAG, `getReminderText language: ${language}, and remindMinutes : ${remindMinutes}`);
    let roundingByDay = 0;
    let roundingByHour = 0;
    let roundingByMinute = 0;
    let remindMinutesAbs = Math.abs(remindMinutes);

    if (remindMinutes === NO_REMINDER_VALUE) {
      return GlobalThis.getResourceStr($r('app.string.no_calendar_display_name'), language)
    }

    if (mIsAllDay) {
      return ReminderUtil.getAllDayLabelByMinute(remindMinutes, language);
    }

    if (remindMinutesAbs === 0) {
      return GlobalThis.getResourceStr($r('app.string.at_time_of_event'), language);
    }

    if (remindMinutesAbs % MINUTES_PER_DAY === 0) {
      roundingByDay = remindMinutesAbs / MINUTES_PER_DAY;
    } else if (remindMinutes % MINUTES_PER_HOUR === 0) {
      roundingByHour = remindMinutesAbs / MINUTES_PER_HOUR;
    } else {
      roundingByMinute = remindMinutesAbs;
    }

    if (remindMinutes > 0) {
      return roundingByDay ?
        roundingByDay === 7
          ? GlobalThis.getResourceStr($r('app.string.one_week_before'), language)
          : GlobalThis.getPluralStr($r('app.plural.days_ago'), roundingByDay, language)
        : roundingByHour
          ? GlobalThis.getPluralStr($r('app.plural.hours_ago'), roundingByHour, language)
          : GlobalThis.getPluralStr($r('app.plural.minutes_ago'), roundingByMinute, language);
    } else {
      return roundingByDay ?
        roundingByDay === 7
          ? GlobalThis.getResourceStr($r('app.string.one_week_later'), language).replace('%s', '1')
          : GlobalThis.getPluralStr($r('app.plural.days_later'), roundingByDay, language)
        : roundingByHour
          ? GlobalThis.getPluralStr($r('app.plural.hours_later'), roundingByHour, language)
          : GlobalThis.getPluralStr($r('app.plural.minutes_later'), roundingByMinute, language);
    }
  }

  private static getAllDayLabelByMinute(reminderMinute: number, language: string): ResourceStr {
    // 1.根据全天日程的minute数值，计算出对应的天数、小时分钟数
    const info = ReminderUtil.parseAllDayReminderMinute(reminderMinute);

    // 2 生成xx天前部分文本
    const dayOffset: number = info.dayOffset;
    let dateLabel: string = '';
    if (dayOffset === 0) {
      dateLabel = GlobalThis.getResourceStr($r('app.string.on_the_same_day'), language);
    } else if (dayOffset === DAY_PER_WEEK) {
      dateLabel = GlobalThis.getResourceStr($r('app.string.one_week_before'), language);
    } else if (dayOffset === -DAY_PER_WEEK) {
      dateLabel = GlobalThis.getResourceStr($r('app.string.one_week_later')).replace('%s', '1');
    } else if (reminderMinute > 0) {
      dateLabel = GlobalThis.getPluralStr($r('app.plural.days_ago'), dayOffset, language);
    } else {
      dateLabel = GlobalThis.getPluralStr($r('app.plural.days_later'), -dayOffset, language);
    }

    // 3 生成HH:mm部分文本
    const hour: number = info.hour;
    const minute: number = info.minute;
    const date = new Date();
    date.setHours(hour, minute, 0, 0);
    const options: intl.DateTimeOptions = {
      timeStyle: 'short',
      hour: '2-digit',
      minute: '2-digit',
      hour12: !i18n.System.is24HourClock()
    };
    let minuteLabel = DateUtil.intlDateFormatChineseStyle(date, options) ?? '';

    // 4 将两部分文本拼接到一起
    if (dateLabel.length > 0 && minuteLabel.length > 0) {
      return `${dateLabel} (${minuteLabel})`;
    } else {
      return `${dateLabel} ${minuteLabel}`;
    }
  }
}