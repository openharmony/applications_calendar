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

export enum Frequency {
  NONE = 0, SECONDLY = 1, MINUTELY = 2, HOURLY = 3, DAILY = 4, WEEKLY = 5, MONTHLY = 6, YEARLY = 7,
  CUSTOMIZE = 8
}

export enum Weeks {
  UNDEFINED = 0, SUN = 1, MON = 2, TUE = 3, WED = 4, THUR = 5, FRI = 6, SAT = 7
}

export enum RepeatType {
  NONE = 0, DAILY = 1, WEEKLY = 2, MONTHLY = 3, YEARLY = 4, LUNAR_MONTHLY = 5, LUNAR_YEARLY = 6, CUSTOM = 7
}

export enum WeekOfMonth {
  UNDEFINED = 0, FIRST = 1, SECOND = 2, THIRD = 3, FOURTH = 4, FIFTH = 5, LAST = -1
}

const WEEK_OF_MONTH_ARR: [WeekOfMonth, Resource][] = [
  [WeekOfMonth.FIRST, $r('app.string.first_day_of_week_each_month')],
  [WeekOfMonth.SECOND, $r('app.string.second_day_of_week_each_month')],
  [WeekOfMonth.THIRD, $r('app.string.third_day_of_week_each_month')],
  [WeekOfMonth.FOURTH, $r('app.string.fourth_day_of_week_each_month')],
  [WeekOfMonth.FIFTH, $r('app.string.last_day_of_week_each_month')],
  [WeekOfMonth.LAST, $r('app.string.last_day_of_week_each_month')],
]

const FIRST_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.every_first_sun')],
  [Weeks.MON, $r('app.string.every_first_mon')],
  [Weeks.TUE, $r('app.string.every_first_tus')],
  [Weeks.WED, $r('app.string.every_first_wed')],
  [Weeks.THUR, $r('app.string.every_first_thu')],
  [Weeks.FRI, $r('app.string.every_first_fri')],
  [Weeks.SAT, $r('app.string.every_first_sat')],
];

const SECOND_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.every_second_sun')],
  [Weeks.MON, $r('app.string.every_second_mon')],
  [Weeks.TUE, $r('app.string.every_second_tus')],
  [Weeks.WED, $r('app.string.every_second_wed')],
  [Weeks.THUR, $r('app.string.every_second_thu')],
  [Weeks.FRI, $r('app.string.every_second_fri')],
  [Weeks.SAT, $r('app.string.every_second_sat')],
];

const THIRD_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.every_third_sun')],
  [Weeks.MON, $r('app.string.every_third_mon')],
  [Weeks.TUE, $r('app.string.every_third_tus')],
  [Weeks.WED, $r('app.string.every_third_wed')],
  [Weeks.THUR, $r('app.string.every_third_thu')],
  [Weeks.FRI, $r('app.string.every_third_fri')],
  [Weeks.SAT, $r('app.string.every_third_sat')],
];

const FOURTH_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.every_fourth_sun')],
  [Weeks.MON, $r('app.string.every_fourth_mon')],
  [Weeks.TUE, $r('app.string.every_fourth_tus')],
  [Weeks.WED, $r('app.string.every_fourth_wed')],
  [Weeks.THUR, $r('app.string.every_fourth_thu')],
  [Weeks.FRI, $r('app.string.every_fourth_fri')],
  [Weeks.SAT, $r('app.string.every_fourth_sat')],
];

const LAST_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.every_last_sun')],
  [Weeks.MON, $r('app.string.every_last_mon')],
  [Weeks.TUE, $r('app.string.every_last_tus')],
  [Weeks.WED, $r('app.string.every_last_wed')],
  [Weeks.THUR, $r('app.string.every_last_thu')],
  [Weeks.FRI, $r('app.string.every_last_fri')],
  [Weeks.SAT, $r('app.string.every_last_sat')],
];

export const FIRST_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(FIRST_WEEK_ARR);

export const SECOND_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(SECOND_WEEK_ARR);

export const THIRD_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(THIRD_WEEK_ARR);

export const FOURTH_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(FOURTH_WEEK_ARR);

export const LAST_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(LAST_WEEK_ARR);

export const WEEK_OF_MONTH_TOARR: [WeekOfMonth, ReadonlyMap<Weeks, Resource>][] = [
  [WeekOfMonth.FIRST, FIRST_WEEK_MAP],
  [WeekOfMonth.SECOND, SECOND_WEEK_MAP],
  [WeekOfMonth.THIRD, THIRD_WEEK_MAP],
  [WeekOfMonth.FOURTH, FOURTH_WEEK_MAP],
  [WeekOfMonth.FIFTH, LAST_WEEK_MAP],
  [WeekOfMonth.LAST, LAST_WEEK_MAP],
];

export const WEEK_OF_MONTH_TOMAP: ReadonlyMap<WeekOfMonth, ReadonlyMap<Weeks, Resource>> = new Map(WEEK_OF_MONTH_TOARR);

export const WEEK_OF_MONTH_MAP: ReadonlyMap<WeekOfMonth, Resource> = new Map(WEEK_OF_MONTH_ARR)

// 星期几
const DAY_OF_WEEK_ARR: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.Sunday')],
  [Weeks.MON, $r('app.string.Monday')],
  [Weeks.TUE, $r('app.string.Tuesday')],
  [Weeks.WED, $r('app.string.Wednesday')],
  [Weeks.THUR, $r('app.string.Thursday')],
  [Weeks.FRI, $r('app.string.Friday')],
  [Weeks.SAT, $r('app.string.Saturday')],
]

export const DAY_OF_WEEK_MAP: ReadonlyMap<Weeks, Resource> = new Map(DAY_OF_WEEK_ARR)

// 周几
const DAY_OF_WEEK_ARR_SHORT: [Weeks, Resource][] = [
  [Weeks.SUN, $r('app.string.Sun')],
  [Weeks.MON, $r('app.string.Mon')],
  [Weeks.TUE, $r('app.string.Tue')],
  [Weeks.WED, $r('app.string.Wed')],
  [Weeks.THUR, $r('app.string.Thu')],
  [Weeks.FRI, $r('app.string.Fri')],
  [Weeks.SAT, $r('app.string.Sat')],
]

export const DAY_OF_WEEK_SHORT_MAP: ReadonlyMap<Weeks, Resource> = new Map(DAY_OF_WEEK_ARR_SHORT)