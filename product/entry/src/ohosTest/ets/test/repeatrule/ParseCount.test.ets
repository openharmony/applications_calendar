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
import PartParser from '@app/feature.repeatrule/src/main/ets/ruleparse/PartParser';
import ParseCount from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseCount';
import { FLAG_COUNT } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';

export default function ParseCountTest() {
  describe('ParseCountTest', () => {
    it('legalCount_01', 0, () => {
      const value: string = '5';
      const parseCount: PartParser = new ParseCount();
      const recurrence: Recurrence = new Recurrence();
      parseCount.parsePart(value, recurrence);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.parseFlag).assertEqual(FLAG_COUNT);
    });

    it('legalCount_02', 0, () => {
      const value: string = '+5';
      const parseCount: PartParser = new ParseCount();
      const recurrence: Recurrence = new Recurrence();
      parseCount.parsePart(value, recurrence);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.parseFlag).assertEqual(FLAG_COUNT);
    });

    it('illegalCount_01', 0, () => {
      const value: string = '';
      const parseCount: PartParser = new ParseCount();
      const recurrence: Recurrence = new Recurrence();
      parseCount.parsePart(value, recurrence);
      expect(recurrence.count).assertEqual(0);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalCount_02', 0, () => {
      const value: string = '5a';
      const parseCount: PartParser = new ParseCount();
      const recurrence: Recurrence = new Recurrence();
      parseCount.parsePart(value, recurrence);
      expect(recurrence.count).assertEqual(5);
      expect(recurrence.parseFlag).assertEqual(FLAG_COUNT);
    });

    it('illegalCount_03', 0, () => {
      const value: string = '-5';
      const parseCount: PartParser = new ParseCount();
      const recurrence: Recurrence = new Recurrence();
      parseCount.parsePart(value, recurrence);
      expect(recurrence.count).assertEqual(0);
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}