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
import { GlobalEnvEnum, LayoutProp } from '@app/common';
import { YearGridLayoutRule } from '@app/feature.yearview/src/main/ets/layoutmodel/YearGridLayoutRule';
import { GridProp } from '@app/feature.yearview/src/main/ets/layoutmodel/YearViewLayoutProp';
import { DayLayout } from '@app/feature.yearview/src/main/ets/layoutmodel/SingleDayLayoutRule';

const gridProp: LayoutProp<GridProp> = new LayoutProp('GridProp', new GridProp());
const dayLayout: LayoutProp<DayLayout> = new LayoutProp('DayLayout', new DayLayout());

export default function YearGridLayoutRuleTest() {
  describe('YearGridLayoutRuleTest', () => {
    it('constructor_with_env', 0, () => {
      AppStorage.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, {
        width: 100, height: 100
      });
      let rule = new YearGridLayoutRule(gridProp, dayLayout);
      expect(rule.calRatioBp(0, 0)).assertNull();
    })

    it('calRatioBp', 0, () => {
      let rule = new YearGridLayoutRule(gridProp, dayLayout);
      expect(rule.calRatioBp(0, 0)).assertNull();
      expect(rule.calRatioBp(-1, -1)).assertNull();
      expect(rule.calRatioBp(100, 0)).assertNull();
      expect(rule.calRatioBp(0, 100)).assertNull();
      expect(rule.calRatioBp(100, 100)).not().assertNull();
    })
  })
}