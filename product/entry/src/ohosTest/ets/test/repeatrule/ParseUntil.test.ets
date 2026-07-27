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
import { FLAG_UNTIL } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';
import ParseUntil from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseUntil';

export default function ParseUntilTest() {
  describe('ParseUntilTest', () => {
    it('legalUntil', 0, () => {
      const value: string = '20240320T153000';
      const parseUntil: PartParser = new ParseUntil();
      const recurrence: Recurrence = new Recurrence();
      parseUntil.parsePart(value, recurrence);
      expect(recurrence.until).assertEqual('20240320T153000');
      expect(recurrence.parseFlag).assertEqual(FLAG_UNTIL);
    });

    it('illegalUntil', 0, () => {
      const value: string = '';
      const parseFreq: PartParser = new ParseUntil();
      const recurrence: Recurrence = new Recurrence();
      parseFreq.parsePart(value, recurrence);
      expect(recurrence.until).assertEqual('');
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}