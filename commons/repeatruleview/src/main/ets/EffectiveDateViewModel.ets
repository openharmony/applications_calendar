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
import { CalendarDate, Log } from '@app/common';
import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';

const TAG = 'EffectiveDateViewModel';
/**
 * EffectiveDate VM
 *
 * @since 2025-10-10
 */
@Observed
export class EffectiveDateViewModel {
  // 有效日期的模式
  @Track public effectiveDateMode: EffectiveDateMode = EffectiveDateMode.FOREVER;
  // 是否显示有效日期切换菜单
  @Track public showEffectiveDateMenu: boolean = false;
  // 截止日期
  @Track public upToDate: Date = new Date();
  // 限定次数
  @Track public limitedTimes: number = 5;
  // 是否展示时间选择器
  @Track public isShowTimePick: boolean = true;
  // 是否展示次数选择器
  @Track public isShowLimitsTimePick: boolean = true;
  // 是否禁用编辑
  @Track public disabled: boolean = false;
  // 日程的时区
  @Track public timeZone: string = CalendarDate.timeZone;

  init(recurrence: Recurrence, disabled = false, timeZone = CalendarDate.timeZone) {
    this.disabled = disabled;
    this.timeZone = timeZone;
    if (recurrence.hasUntil()) {
      this.effectiveDateMode = EffectiveDateMode.UNTIL;
      this.upToDate = new Date(recurrence.getUntilMills(this.timeZone));
    } else if (recurrence.hasCount()) {
      this.effectiveDateMode = EffectiveDateMode.COUNT;
      this.limitedTimes = recurrence.count;
    } else {
      this.effectiveDateMode = EffectiveDateMode.FOREVER;
    }
  }

  onEffectiveDateModeChanged(value: number) {
    if (value !== EffectiveDateMode.FOREVER && value !== EffectiveDateMode.UNTIL && value !== EffectiveDateMode.COUNT) {
      Log.warn(TAG, `value is invalid: ${value}`);
      return;
    }
    this.effectiveDateMode = value;
    // 切换模式后，需要重新展示选择器
    this.isShowTimePick = true;
    this.isShowLimitsTimePick = true;
  }
}

export enum EffectiveDateMode {
  // 无截止限制
  FOREVER = 0,
  // 按日期限制截止
  UNTIL = 1,
  // 按次数限制截止
  COUNT = 2
}