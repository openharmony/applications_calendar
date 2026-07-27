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
import { beforeEach, describe, expect, it } from '@ohos/hypium';
import { MonthlyViewState } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';

export default function MonthlyViewStateTest() {
  describe('MonthlyViewStateTest', () => {
    let state: MonthlyViewState;

    beforeEach(() => {
      state = new MonthlyViewState();
    })

    it('isWeekendByStartOfWeek_0', 0, () => {
      state.startOfWeek = 0;
      state.weekends = [0, 6]; // 周六 周天
      expect(state.isWeekendByStartOfWeek(0)).assertEqual(true);
      expect(state.isWeekendByStartOfWeek(1)).assertEqual(false);
    })

    it('isWeekendByStartOfWeek_1', 0, () => {
      state.startOfWeek = 1;
      state.weekends = [0, 6]; // 周六 周天
      expect(state.isWeekendByStartOfWeek(0)).assertEqual(false);
      expect(state.isWeekendByStartOfWeek(5)).assertEqual(true);
    })
  })
}