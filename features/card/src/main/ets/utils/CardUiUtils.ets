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
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { LunarDateUtil } from '@app/common/src/main/ets/date/LunarDateUtil';
import { AgendaCardGroup, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { MAIN_LUNAR_TERM, ALL_LUNAR_MONTH } from '@app/common/src/main/ets/date/LunarTermConsts';
import { i18n } from '@kit.LocalizationKit';
import { DayAgendaNumInfo } from '../agendaCard/common/DayAgendaNumInfo';
import { DateManager } from '@app/common/src/main/ets/date/DateManager';
import { FestivalDay } from '@app/common/src/main/ets/date/FestivalData';
import { DayData } from '@app/common/src/main/ets/date/Date';

const TAG: string = 'CardUiUtils';

export class CardUiUtils {
  public static getLunarDayString(julianDayOfNow: number): string {
    if (!julianDayOfNow) {
      Log.error(TAG, 'getLunarDayString, julianDayOfNow is null');
      return '';
    }

    const calendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemRegion(), 'chinese');
    const date = FormUtils.julianDay2Date(julianDayOfNow);
    calendar.setTime(date.getTime());
    calendar.setTimeZone(date.getTimeZone());

    const isLeapMonth = calendar.get('is_leap_month');
    const month = calendar.get('month');
    const day = calendar.get('date');

    const lunarMonthText = ALL_LUNAR_MONTH[month];
    const leapMonthText = isLeapMonth ? '闰' : '';
    const lunarDateText = LunarDateUtil.getChineseDay(day, i18n.System.getSystemLanguage(), true);

    return leapMonthText + lunarMonthText + lunarDateText;
  }

  public static getMonthTitle(month: number): string {
    if (month === undefined) {
      Log.error(TAG, 'month is null');
      return '';
    }

    if (month < 0 || month > 11) {
      Log.error(TAG, 'month is invalid');
      return '';
    }

    const language = i18n.System.getSystemLanguage();

    Log.info(TAG, 'getMonthTitle, month = ' + month);
    return DateUtil.getMonthTitle(month, language);
  }

  public static getFestivalText(julianDayOfNow: number): string {
    if (!julianDayOfNow) {
      Log.error(TAG, 'getFestivalText, julianDayOfNow is null');
      return '';
    }

    const day: CalendarDate = FormUtils.julianDay2Date(julianDayOfNow);
    const dayDate: DayData | undefined =
      DateManager.getInstance().getDayData(day.getFullYear(), day.getMonth() + 1, day.getDate());
    const festivals: FestivalDay[] = dayDate?.festivals ?? [];
    return festivals.length > 0 ? (MAIN_LUNAR_TERM.includes(festivals[0].name) ? festivals[0].name : '') : '';
  }

  public static getLunarText(julianDayOfNow: number): string {
    const dayText = CardUiUtils.getLunarDayString(julianDayOfNow);
    const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

    return [
      dayText,
      festivalText
    ].filter(Boolean).join(' ');
  }

  public static getAgendaCountFromGroupList(agendaGroupList: AgendaCardGroup[]): number {
    if (EmptyUtils.isEmptyArray(agendaGroupList)) {
      Log.warn(TAG, 'getAgendaCountFromGroupList, agendaGroupList is empty');
      return 0;
    }

    // 2x2只有当天未过期数据，或者只有明天数据(18:00后显示明天)
    // 2x4只有当天未过期数据
    const agendaGroup = agendaGroupList[0];

    return CardUiUtils.getAgendaCount(agendaGroup);
  }

  public static getAgendaCount(agendaGroup: AgendaCardGroup): number {
    if (EmptyUtils.isUndefinedOrNull(agendaGroup)) {
      Log.warn(TAG, 'getAgendaCount, agendaGroup is null');
      return 0;
    }

    const items = agendaGroup.items;
    if (EmptyUtils.isEmptyArray(items)) {
      Log.warn(TAG, 'getAgendaCount, items is empty');
      return 0;
    }

    return items.length;
  }

  public static dayAgendaNumInfo2agendaNumsMap(dayAgendaNumInfo: DayAgendaNumInfo[]): Map<number, number> {
    const agendaNumsMap = new Map<number, number>();

    if (EmptyUtils.isUndefinedOrNull(dayAgendaNumInfo)) {
      Log.warn(TAG, `this.dayAgendaNumInfo is null or undefined!`)
      return agendaNumsMap;
    }

    dayAgendaNumInfo.forEach((item: DayAgendaNumInfo) => {
      let julianDay = new CalendarDate(item.startTimeOfDay).getJulianDay();
      agendaNumsMap.set(julianDay, item.agendaNum);
    });
    
    return agendaNumsMap;
  }
}
