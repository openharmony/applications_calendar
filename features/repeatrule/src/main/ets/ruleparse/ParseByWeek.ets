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
import { FLAG_BY_WEEK_NUM, parseNumberList } from '../RecurrenceParser';
import PartParser from './PartParser';

const TAG: string = 'ParseByWeek';

const MAX_WEEKS_OF_YEAR: number = 53;

const MAX_WEEKS_OF_LAST_YEAR: number = -53;

/**
 * 解析按周循环的配置
 */
export default class ParseByWeek implements PartParser {
  parsePart(value: string, recurrence: Recurrence) {
    if (!recurrence) {
      Log.warn(TAG, `parsePart get invalid params`);
      return;
    }
    recurrence.byWeek = parseNumberList(value, MAX_WEEKS_OF_LAST_YEAR, MAX_WEEKS_OF_YEAR, false);
    if (recurrence.byWeekCount() > 0) {
      recurrence.parseFlag |= FLAG_BY_WEEK_NUM;
    }
  }
}