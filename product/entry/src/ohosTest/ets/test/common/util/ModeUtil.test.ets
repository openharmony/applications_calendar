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

import { ModeUtil, UnusualMode } from '@app/common';
import { describe, expect, it } from '@ohos/hypium';

export default function ModeUtilTest() {
  describe('ModeUtilTest', () => {
    it('isHiCarOrVerdeModeTest_01', 0, () => {
      expect(ModeUtil.isHiCarOrSmallUpDownFoldMode(undefined)).assertFalse();
    });

    it('isHiCarOrVerdeModeTest_02', 0, () => {
      expect(ModeUtil.isHiCarOrSmallUpDownFoldMode(UnusualMode.HICAR)).assertTrue();
    });

    it('isHiCarOrVerdeModeTest_03', 0, () => {
      expect(ModeUtil.isHiCarOrSmallUpDownFoldMode(UnusualMode.SMALL_UP_DOWN_FOLD)).assertTrue();
    });

    it('isHiCarOrVerdeModeTest_04', 0, () => {
      expect(ModeUtil.isHiCarOrSmallUpDownFoldMode(UnusualMode.DEFAULT)).assertFalse();
    });
    it('isVerdeModeTest_01', 0, () => {
      expect(ModeUtil.isSmallUpDownFoldMode(undefined)).assertFalse();
    });

    it('isVerdeModeTest_02', 0, () => {
      expect(ModeUtil.isSmallUpDownFoldMode(UnusualMode.HICAR)).assertFalse();
    });

    it('isVerdeModeTest_03', 0, () => {
      expect(ModeUtil.isSmallUpDownFoldMode(UnusualMode.SMALL_UP_DOWN_FOLD)).assertTrue();
    });

    it('isVerdeModeTest_04', 0, () => {
      expect(ModeUtil.isSmallUpDownFoldMode(UnusualMode.DEFAULT)).assertFalse();
    });
  });
}