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
import { FLAG_BY_MINUTE, parseNumberList } from '../RecurrenceParser';
import PartParser from './PartParser';

const TAG: string = 'ParseByMinute';

const MIN_MINUTE: number = 0;

const MAX_MINUTE: number = 59;

/**
 * 解析按分钟循环的配置
 */
export default class ParseByMinute implements PartParser {
  parsePart(value: string, recurrence: Recurrence) {
    if (!recurrence) {
      Log.warn(TAG, `parsePart get invalid params`);
      return;
    }
    recurrence.byMinute = parseNumberList(value, MIN_MINUTE, MAX_MINUTE);
    if (recurrence.byMinuteCount() > 0) {
      recurrence.parseFlag |= FLAG_BY_MINUTE;
    }
  }
}