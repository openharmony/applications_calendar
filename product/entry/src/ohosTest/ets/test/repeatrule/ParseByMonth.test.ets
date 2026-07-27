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
import ParseByMonth from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseByMonth';
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
import PartParser from '@app/feature.repeatrule/src/main/ets/ruleparse/PartParser';
import { FLAG_BY_MONTH } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';
import { Recurrence } from '@app/feature.repeatrule';

export default function ParseByMonthTest() {
  describe('ParseByMonthTest', () => {
    it('legalByMonth', 0, () => {
      const value: string = '2';
      const parseByMonth: PartParser = new ParseByMonth();
      const recurrence: Recurrence = new Recurrence();
      parseByMonth.parsePart(value, recurrence);
      expect(recurrence.byMonth).assertDeepEquals([2]);
      expect(recurrence.parseFlag).assertEqual(FLAG_BY_MONTH);
    });

    it('illegalByMonth', 0, () => {
      const value: string = '';
      const parseByMonth: PartParser = new ParseByMonth();
      const recurrence: Recurrence = new Recurrence();
      parseByMonth.parsePart(value, recurrence);
      expect(recurrence.byMonth).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalByMonth_02', 0, () => {
      const value: string = '20a';
      const parseByMonth: PartParser = new ParseByMonth();
      const recurrence: Recurrence = new Recurrence();
      parseByMonth.parsePart(value, recurrence);
      expect(recurrence.byMonth).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalByMonth_03', 0, () => {
      const value: string = '-20';
      const parseByMonth: PartParser = new ParseByMonth();
      const recurrence: Recurrence = new Recurrence();
      parseByMonth.parsePart(value, recurrence);
      expect(recurrence.byMonth).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}