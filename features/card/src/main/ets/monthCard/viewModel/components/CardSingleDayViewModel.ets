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

import { DayMark } from '@app/common/src/main/ets/constants/Constants';
import { SubscriptionCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';

const DEFAULT_NUM: number = -1;

/**
 * 月视图卡片上的 单天宫格 视图模型
 */
@Observed
export class CardSingleDayViewModel {
  // 年
  public year: number = DEFAULT_NUM;
  // 月
  public month: number = DEFAULT_NUM;
  // 日
  public day: number = DEFAULT_NUM;
  // 今天
  public isToday: boolean = false;
  // 班休 0、undefined、null:普通  1：休  2：班
  public mark: number = DayMark.NORMAL;
  // 是否属于当前展示的月份
  public isCurrentMonth: boolean = false;
  // 是否是周末
  public isWeekends: boolean = false;
  // 是否显示TAG
  public showTagText: boolean = false;
  // 节假日、节气、农历 归一化TAG
  public tagText: string = '';
  // 是否显示班休
  public showRecessData: boolean = false;
  // 界面是否显示农历下划线
  public showLunarLine: boolean = false;
  //当天是否有节假日
  public hasFestivals: boolean = false;
  //历法
  public subscriptionCalendar: number = SubscriptionCalendar.NO_CALENDAR;
  //历法
  public showChineseFestival: boolean = true;
  // 是否显示中国节假日
  public showChineseHolidayState: string = 'CN';
  // 是否显示有日程红点
  public showAgendaDot: boolean = false;
  // 儒略日
  public julianDay: number = -1;

  constructor(year?: number, month?: number, day?: number, isToday?: boolean, mark?: number,
              isCurrentMonth?: boolean, isWeekends?: boolean, showTagText?: boolean, tagText?: string,
              showRecessData?: boolean, showLunarLine?: boolean, hasFestivals?: boolean,
              subscriptionCalendar?: number, showChineseFestival?: boolean, showChineseHolidayState?: string) {
    this.year = year ?? DEFAULT_NUM;
    this.month = month ?? DEFAULT_NUM;
    this.day = day ?? DEFAULT_NUM;
    this.isToday = isToday ?? false;
    this.mark = mark ?? DayMark.NORMAL;
    this.isCurrentMonth = isCurrentMonth ?? false;
    this.isWeekends = isWeekends ?? false;
    this.showTagText = showTagText ?? false;
    this.tagText = tagText ?? '';
    this.showRecessData = showRecessData ?? false;
    this.showLunarLine = showLunarLine ?? false;
    this.hasFestivals = hasFestivals ?? false;
    this.subscriptionCalendar = subscriptionCalendar ?? SubscriptionCalendar.NO_CALENDAR;
    this.showChineseFestival = showChineseFestival ?? true;
    this.showChineseHolidayState = showChineseHolidayState ?? 'CN';
    this.julianDay = DateUtil.date2julianDay(this.year, this.month, this.day);
  }

  // 用于数组遍历，本函数内涉及到的变量才能触发视图刷新
  toUniqueString(): string {
    return `${this.year}-${this.month}-${this.day}-${this.isToday}-${this.isWeekends}-${this.isCurrentMonth}-${this.showRecessData}-${this.mark}`;
  }

}

export type CompressedDayData = [
  number, // year
  number, // month
  number, // day
  number, // isToday (1 or 0)
  number, // mark
  number, // isCurrentMonth (1 or 0)
  number, // isWeekends (1 or 0)
  number, // showTagText (1 or 0)
  string, // tagText
  number, // showRecessData (1 or 0)
  number, // showLunarLine (1 or 0)
  number, // hasFestivals (1 or 0)
  number, // subscriptionCalendar
  number, // showChineseFestival (1 or 0)
  string // showChineseHolidayState (CLOSE, CN OR CU_CUSTOM)
];

export enum CompressedDayDataIndex {
  Year = 0,
  Month,
  Day,
  IsToday,
  Mark,
  IsCurrentMonth,
  IsWeekends,
  ShowTagText,
  TagText,
  ShowRecessData,
  ShowLunarLine,
  HasFestivals,
  SubscriptionCalendar,
  ShowChineseFestival,
  ShowChineseHolidayState
}