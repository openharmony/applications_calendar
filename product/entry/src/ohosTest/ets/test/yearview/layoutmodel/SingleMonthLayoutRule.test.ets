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
import { MonthLayout, MonthLayoutBp, monthLayoutBps, SingleMonthLayoutRule } from '@app/feature.yearview/src/main/ets/layoutmodel/SingleMonthLayoutRule';
import { LayoutProp } from '@app/common';

const monthLayout: LayoutProp<MonthLayout> = new LayoutProp('monthLayout', new MonthLayout());

export default function SingleMonthLayoutRuleTest() {
  describe('SingleMonthLayoutRuleTest', () => {
    it('constructor_with_env', 0, () => {
      let rule = new SingleMonthLayoutRule(monthLayout);
      expect(monthLayout.value.legendFontSize).assertEqual(monthLayoutBps[0].layout.legendFontSize);
      expect(monthLayout.value.monthFontSize).assertEqual(monthLayoutBps[0].layout.monthFontSize);
    })

    it('reCalLayout_same_size', 0, () => {
      let hasError: boolean = true;
      const width = 100;
      const height = 100;
      let expectLayout = new MonthLayout();
      expectLayout.legendFontSize = monthLayout.value.legendFontSize;
      expectLayout.monthFontSize = monthLayout.value.monthFontSize;
      let rule = new SingleMonthLayoutRule(monthLayout);
      rule.reCalLayout(width, height);
      hasError = false;
      expect(hasError).assertFalse()
    })

    it('reCalLayout_allBps', 0, () => {
      let rule = new SingleMonthLayoutRule(monthLayout);
      monthLayoutBps.forEach(item => {
        rule.reCalLayout(item.width, item.height);
        expect(monthLayout.value).assertDeepEquals(item.layout);
      })
    })

    it('MonthLayoutBp', 0, () => {
      let bp = new MonthLayoutBp();
      expect(bp.width).assertEqual(0);
      expect(bp.height).assertEqual(0);
      expect(bp.layout).not().assertNull();
    })
  })
}