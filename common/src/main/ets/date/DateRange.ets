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

import { CalendarDate } from './CalendarDate';

export namespace DateRange {
  /**
   * 时间戳区间
   */
  export interface Range {
    start: number; // 起始时间戳 单位 ms
    end: number; // 结束时间戳 单位 ms
  }

  /**
   * 判断是否同一个时间区间
   *
   * @param range1 时间范围1
   * @param range2 时间范围2
   *
   * @return 是否相同
   */
  export function isSameDateRange(range1: Range, range2: Range): boolean {
    return range1.start === range2.start && range1.end === range2.end;
  }

  /**
   * 判断是否在时间范围内
   *
   * @param _date 要判定的时间戳或者Date对象
   * @param range 时间范围
   *
   * @return 是否在时间范围内
   */
  export function isDateInRange(_date: number, range: Range): boolean {
    return _date >= range.start && _date < range.end;
  }
}