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

import { Log } from '@app/common';
import { Recurrence } from '../Recurrence';
import { FLAG_BY_MONTH, parseNumberList } from '../RecurrenceParser';
import PartParser from './PartParser';

const TAG: string = 'ParseByMonth';

// rrule中month的取值范围是1-12，系统api中的取值范围是0-11
const MIN_MONTH_OF_YEAR: number = 1;

// rrule中month的取值范围是1-12，系统api中的取值范围是0-11
const MAX_MONTH_OF_YEAR: number = 12;

/**
 * 解析按月循环的配置
 */
export default class ParseByMonth implements PartParser {
  parsePart(value: string, recurrence: Recurrence) {
    if (!recurrence) {
      Log.warn(TAG, `parsePart get invalid params`);
      return;
    }
    recurrence.byMonth = parseNumberList(value, MIN_MONTH_OF_YEAR, MAX_MONTH_OF_YEAR, false);
    if (recurrence.byMonthCount() > 0) {
      recurrence.parseFlag |= FLAG_BY_MONTH;
    }
  }
}