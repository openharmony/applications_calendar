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
import { CHINESE_HOLIDAY_STATE_VALUE } from '@app/common/src/main/ets/date/HolidayUtil';

/**
 * 查询缓存中的设置项数据模型
 */
export class SettingsDataModel {
  public weekends: number[]; // 周末
  public startOfWeek: number; // 一周开始日
  public subscriptionCalendar: number; // 历法
  public isRecessToggleOn: boolean; // 班休开关
  public systemRegion: string = ''; // 系统地区
  public isAgreeStatement: boolean = false; // 是否已同意日历隐私授权
  public showChineseFestival: boolean = true; // 是否显示中国节假日
  public showChineseHolidayState: string = CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN; // 是否显示中国节假日
  public timeZone: string = ''; // 系统时区

  constructor(weekends?: number[], startOfWeek?: number, subscriptionCalendar?: number, isRecessToggleOn?: boolean) {
    this.weekends = weekends ?? [-1, 0, 6];
    this.startOfWeek = startOfWeek ?? -1;
    this.subscriptionCalendar = subscriptionCalendar ?? 0;
    this.isRecessToggleOn = isRecessToggleOn ?? false;
  }
}