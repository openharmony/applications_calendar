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
import { Frequency } from '../Constants';
import { Recurrence } from '../Recurrence';
import { FLAG_FREQ } from '../RecurrenceParser';
import PartParser from './PartParser';

const FREQ_MAP: Record<string, Frequency> = {
  'SECONDLY': Frequency.SECONDLY,
  'MINUTELY': Frequency.MINUTELY,
  'HOURLY': Frequency.HOURLY,
  'DAILY': Frequency.DAILY,
  'WEEKLY': Frequency.WEEKLY,
  'MONTHLY': Frequency.MONTHLY,
  'YEARLY': Frequency.YEARLY
}

const TAG: string = 'ParseFreq';

/**
 * 解析循环频率，每天 每周 每月等
 */
export default class ParseFreq implements PartParser {
  parsePart(value: string, recurrence: Recurrence) {
    if (!recurrence) {
      Log.warn(TAG, `parsePart get invalid params`);
      return;
    }
    const freq: Frequency = FREQ_MAP[value];
    recurrence.freq = freq ?? Frequency.NONE;
    recurrence.parseFlag |= FLAG_FREQ;
  }
}