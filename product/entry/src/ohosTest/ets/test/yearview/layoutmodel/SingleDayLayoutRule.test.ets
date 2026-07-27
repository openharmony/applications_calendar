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
import { LayoutProp } from '@app/common';
import { DayLayout, DayLayoutBp, dayLayoutBps, SingleDayLayoutRule } from '@app/feature.yearview/src/main/ets/layoutmodel/SingleDayLayoutRule';

export default function SingleDayLayoutRuleTest() {
  let dayLayout: LayoutProp<DayLayout> = new LayoutProp('DayLayout', new DayLayout());
  describe('SingleDayLayoutRuleTest', () => {
    it('constructor_with_env', 0, () => {
      let rule = new SingleDayLayoutRule(dayLayout);
      expect(dayLayout.value.dayFontSize).assertEqual(8.5);
    })

    it('reCalLayout_allBps', 0, () => {
      let rule = new SingleDayLayoutRule(dayLayout);
      dayLayoutBps.forEach(item => {
        rule.reCalLayout(item.width, item.height, 1);
        expect(dayLayout.value.dayFontSize).assertEqual(item.layout.dayFontSize);
      })
    })

    it('DayLayoutBp', 0, () => {
      let bp = new DayLayoutBp();
      expect(bp.width).assertEqual(0);
      expect(bp.height).assertEqual(0);
      expect(bp.layout).not().assertNull();
    })
  })
}