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
import PartParser from '@app/feature.repeatrule/src/main/ets/ruleparse/PartParser';
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
import ParseByMonthDay from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseByMonthDay';
import { Recurrence } from '@app/feature.repeatrule';
import { FLAG_BY_MONTH_DAY } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';

export default function ParseByMonthDayTest() {
  describe('ParseByMonthDayTest', () => {
    it('legalByMonthDay_01', 0, () => {
      const value: string = '20';
      const parseByMonthDay: PartParser = new ParseByMonthDay();
      const recurrence: Recurrence = new Recurrence();
      parseByMonthDay.parsePart(value, recurrence);
      expect(recurrence.byMonthDay).assertDeepEquals([20]);
      expect(recurrence.parseFlag).assertEqual(FLAG_BY_MONTH_DAY);
    });

    it('legalByMonthDay_02', 0, () => {
      const value: string = '-20';
      const parseByMonthDay: PartParser = new ParseByMonthDay();
      const recurrence: Recurrence = new Recurrence();
      parseByMonthDay.parsePart(value, recurrence);
      expect(recurrence.byMonthDay).assertDeepEquals([-20]);
      expect(recurrence.parseFlag).assertEqual(FLAG_BY_MONTH_DAY);
    });

    it('illegalByMonthDay_01', 0, () => {
      const value: string = '';
      const parseByMonthDay: PartParser = new ParseByMonthDay();
      const recurrence: Recurrence = new Recurrence();
      parseByMonthDay.parsePart(value, recurrence);
      expect(recurrence.byMonthDay).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalByMonthDay_02', 0, () => {
      const value: string = 'a20';
      const parseByMonthDay: PartParser = new ParseByMonthDay();
      const recurrence: Recurrence = new Recurrence();
      parseByMonthDay.parsePart(value, recurrence);
      expect(recurrence.byMonthDay).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}