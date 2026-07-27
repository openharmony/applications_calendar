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

import { describe, expect, it } from '@ohos/hypium';
import { Frequency, Recurrence } from '@app/feature.repeatrule';
import PartParser from '@app/feature.repeatrule/src/main/ets/ruleparse/PartParser';
import ParseFreq from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseFreq';
import { FLAG_FREQ } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';

export default function ParseFreqTest() {
  describe('ParseFreqTest', () => {
    it('daily', 0, () => {
      const value: string = 'DAILY';
      const parseFreq: PartParser = new ParseFreq();
      const recurrence: Recurrence = new Recurrence();
      parseFreq.parsePart(value, recurrence);
      expect(recurrence.freq).assertEqual(Frequency.DAILY);
      expect(recurrence.parseFlag).assertEqual(FLAG_FREQ);
    });

    it('none', 0, () => {
      const value: string = '';
      const parseFreq: PartParser = new ParseFreq();
      const recurrence: Recurrence = new Recurrence();
      parseFreq.parsePart(value, recurrence);
      expect(recurrence.freq).assertEqual(Frequency.NONE);
      expect(recurrence.parseFlag).assertEqual(FLAG_FREQ);
    });
  })
}