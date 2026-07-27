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
import { Recurrence } from '@app/feature.repeatrule';
import ParseInterval from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseInterval';
import PartParser from '@app/feature.repeatrule/src/main/ets/ruleparse/PartParser';
import { FLAG_INTERVAL } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';

export default function ParseIntervalTest() {
  describe('ParseIntervalTest', () => {
    it('legalInterval', 0, () => {
      const value: string = '2';
      const parseInterval: PartParser = new ParseInterval();
      const recurrence: Recurrence = new Recurrence();
      parseInterval.parsePart(value, recurrence);
      expect(recurrence.interval).assertEqual(2);
      expect(recurrence.parseFlag).assertEqual(FLAG_INTERVAL);
    });

    it('illegalInterval_01', 0, () => {
      const value: string = '';
      const parseInterval: PartParser = new ParseInterval();
      const recurrence: Recurrence = new Recurrence();
      parseInterval.parsePart(value, recurrence);
      expect(recurrence.interval).assertEqual(0);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalInterval_02', 0, () => {
      const value: string = 'a2';
      const parseInterval: PartParser = new ParseInterval();
      const recurrence: Recurrence = new Recurrence();
      parseInterval.parsePart(value, recurrence);
      expect(recurrence.interval).assertEqual(0);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalInterval_03', 0, () => {
      const value: string = '-2';
      const parseInterval: PartParser = new ParseInterval();
      const recurrence: Recurrence = new Recurrence();
      parseInterval.parsePart(value, recurrence);
      expect(recurrence.interval).assertEqual(0);
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}