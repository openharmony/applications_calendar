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
import MonthCardLayoutFactory from '@app/feature.card/src/main/ets/monthCard/layout/MonthCardLayout';
import { FormName } from '@app/feature.card/src/main/ets/utils/FormName';

export default function MonthCardLayoutBuilderTest() {
  describe('MonthCardLayoutBuilderTest', () => {
    // 新建一个VM
    it('TestNormalBuilder_2x2', 0, () => {
      const monthCardLayout = MonthCardLayoutFactory.createLayout(FormName.MONTH_CARD_2X2);
      expect(monthCardLayout.cardName).assertEqual(FormName.MONTH_CARD_2X2);
    })

    it('TestNormalBuilder_4x4', 0, () => {
      const monthCardLayout = MonthCardLayoutFactory.createLayout(FormName.MONTH_CARD_4X4);
      expect(monthCardLayout.cardName).assertEqual(FormName.MONTH_CARD_4X4);
    })
  })
}