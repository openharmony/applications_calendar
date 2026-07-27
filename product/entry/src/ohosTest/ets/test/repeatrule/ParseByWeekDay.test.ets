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
import ParseByWeekDay from '@app/feature.repeatrule/src/main/ets/ruleparse/ParseByWeekDay';
import { Recurrence } from '@app/feature.repeatrule';
import { FLAG_BY_WEEK_DAY } from '@app/feature.repeatrule/src/main/ets/RecurrenceParser';

export default function ParseByWeekDayTest() {
  describe('ParseByWeekDayTest', () => {
    it('legalByWeekDay_01', 0, () => {
      const value: string = '2MO';
      const parseByWeekDay: PartParser = new ParseByWeekDay();
      const recurrence: Recurrence = new Recurrence();
      parseByWeekDay.parsePart(value, recurrence);
      expect(recurrence.byWeekNum).assertDeepEquals([2]);
      expect(recurrence.byWeekDay).assertDeepEquals([2]);
      expect(recurrence.parseFlag).assertEqual(FLAG_BY_WEEK_DAY);
    });

    it('legalByWeekDay_02', 0, () => {
      const value: string = 'MO,TU';
      const parseByWeekDay: PartParser = new ParseByWeekDay();
      const recurrence: Recurrence = new Recurrence();
      parseByWeekDay.parsePart(value, recurrence);
      expect(recurrence.byWeekDay).assertDeepEquals([2, 3]);
      expect(recurrence.parseFlag).assertEqual(FLAG_BY_WEEK_DAY);
    });

    it('illegalByWeekDay_01', 0, () => {
      const value: string = '';
      const parseByWeekDay: PartParser = new ParseByWeekDay();
      const recurrence: Recurrence = new Recurrence();
      parseByWeekDay.parsePart(value, recurrence);
      expect(recurrence.byWeekNum).assertDeepEquals([]);
      expect(recurrence.byWeekDay).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalByWeekDay_02', 0, () => {
      const value: string = '2mon';
      const parseByWeekDay: PartParser = new ParseByWeekDay();
      const recurrence: Recurrence = new Recurrence();
      parseByWeekDay.parsePart(value, recurrence);
      expect(recurrence.byWeekNum).assertDeepEquals([]);
      expect(recurrence.byWeekDay).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });

    it('illegalByWeekDay_03', 0, () => {
      const value: string = 'MON,tue';
      const parseByWeekDay: PartParser = new ParseByWeekDay();
      const recurrence: Recurrence = new Recurrence();
      parseByWeekDay.parsePart(value, recurrence);
      expect(recurrence.byWeekNum).assertDeepEquals([]);
      expect(recurrence.byWeekDay).assertDeepEquals([]);
      expect(recurrence.parseFlag).assertEqual(0);
    });
  })
}