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
import { CompId } from '@app/common';
import { RadioListDialogOption } from '@app/common.components';
/**
 * 设置历法
 *
 * @since 2022-09-08
 */
export enum Calendars {

  NO_CALENDAR_SELECTED = -1,

  /**
   * 中国农历
   */
  CALENDAR_CHINESE_LUNAR = 0,

  /**
   * 和历
   * icu supported
   */
  CALENDAR_JAPANESE = 2,

  /**
   * 波斯历
   */
  CALENDAR_PERSIAN = 3,

  /**
   * 希伯来历
   * icu supported
   */
  CALENDAR_HEBREW = 4,

  /**
   * 伊斯兰希吉来历
   * icu supported
   */

  CALENDAR_ISLAMIC = 5,


  /**
   * 佛历
   */
  CALENDAR_BUDDHIST = 6,

  /**
   * 印度国定历
   * icu supported
   */
  CALENDAR_INDIAN = 7,

}

export const CalendarsArray: Calendars [] = [Calendars.NO_CALENDAR_SELECTED, Calendars.CALENDAR_CHINESE_LUNAR,
  Calendars.CALENDAR_JAPANESE, Calendars.CALENDAR_PERSIAN,
  Calendars.CALENDAR_HEBREW, Calendars.CALENDAR_ISLAMIC,
  Calendars.CALENDAR_BUDDHIST, Calendars.CALENDAR_INDIAN];

//历法配置项
export const currentSupportCalendars: number [] =
  [Calendars.NO_CALENDAR_SELECTED, Calendars.CALENDAR_CHINESE_LUNAR];

//历法配置项
export const allCalendarOptions: RadioListDialogOption[] = [
  { label: $r('app.string.no_calendar_display_name'), value: -1, compId: CompId.NONE },
  { label: $r('app.string.chinese_calendar_display_name'), value: 0, compId: CompId.CHINESE_CALENDAR },
  { label: $r('app.string.japanese_calendar_display_name'), value: 2, compId: CompId.JAPANESE_CALENDAR },
  { label: $r('app.string.persian_calendar_display_name'), value: 3, compId: CompId.PERSIAN_CALENDAR },
  { label: $r('app.string.hebrew_calendar_display_name'), value: 4, compId: CompId.HEBREW_CALENDAR },
  { label: $r('app.string.islamic_hijilai_calendar_display_name'), value: 5, compId: CompId.ISLAMIC_CALENDAR },
  { label: $r('app.string.buddhist_calendar_display_name'), value: 6, compId: CompId.BUDDHIST_CALENDAR },
  { label: $r('app.string.indian_national_calendar_display_name'), value: 7, compId: CompId.INDIAN_NATIONAL_CALENDAR },
];


//目前支持的历法配置项
export const currentSupportOptions: RadioListDialogOption[] = allCalendarOptions
  .filter((radioListDialogOption: RadioListDialogOption, index: number, array: RadioListDialogOption[]) => {
    return currentSupportCalendars.indexOf(radioListDialogOption.value) != -1;
  })