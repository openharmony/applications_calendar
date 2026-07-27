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
import { CompId, MINUTES_PER_DAY } from '@app/common';
import { RadioListOption } from './RadioList';

// 全天默认提醒时间配置项，值（单位：分钟）
export const DEFAULT_ALL_DAY_REMINDER_OPTIONS: RadioListOption[] = [ //当前多参数复数字符串不支持转换为text，无障碍播报有问题需重新提翻，拆分占位符
  { label: $r('app.string.no_calendar_display_name'), value: -1, text: '无', isMutex: true, isDefault: true },
  { label: $r('app.string.all_day_on_the_day', 9), value: 0, text: '当天 (上午 9 点)' },
  { label: $r('app.plural.all_day_days_ago', 1, 1, 9), value: MINUTES_PER_DAY, text: '一天前 (上午 9 点)' },
  { label: $r('app.plural.all_day_days_ago', 2, 2, 9), value: MINUTES_PER_DAY * 2, text: '两天前 (上午 9 点)' },
  { label: $r('app.plural.all_day_days_ago', 3, 3, 9), value: MINUTES_PER_DAY * 3, text: '三天前 (上午 9 点)' },
  { label: $r('app.string.all_day_one_week_before', 1, 9), value: MINUTES_PER_DAY * 7, text: '一周前 (上午 9 点)' },
];


// 默认提醒时间配置项，值（单位：分钟）
export const DEFAULT_REMINDER_OPTIONS: RadioListOption[] = [
  { label: $r('app.string.no_calendar_display_name'), value: -1, compId: CompId.NO_REMINDER, isMutex: true, isDefault: true },
  { label: $r('app.string.at_time_of_event'), value: 0, compId: CompId.AT_TIME_OF_EVENT },
  { label: $r('app.string.five_minutes_before', 5), value: 5, compId: CompId.FIVE_MINUTES_BEFORE },
  { label: $r('app.string.five_minutes_before', 10), value: 10, compId: CompId.TEN_MINUTES_BEFORE },
  { label: $r('app.string.five_minutes_before', 15), value: 15, compId: CompId.FIFTEEN_MINUTES_BEFORE },
  { label: $r('app.string.five_minutes_before', 30), value: 30, compId: CompId.THIRTY_MINUTES_BEFORE },
  { label: $r('app.string.an_hour_before'), value: 60, compId: CompId.AN_HOUR_BEFORE },
  { label: $r('app.string.two_hours_before'), value: 120, compId: CompId.TWO_HOURS_BEFORE },
  { label: $r('app.string.one_day_before'), value: 1440, compId: CompId.ONE_DAY_BEFORE },
  { label: $r('app.string.two_days_before'), value: 2880, compId: CompId.TWO_DAYS_BEFORE },
  { label: $r('app.string.one_week_before'), value: 10080, compId: CompId.ONE_WEEK_BEFORE }
];