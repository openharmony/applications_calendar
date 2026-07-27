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
import { ColorType, PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';

export default function PaletteCacheTest() {
  describe('PaletteCacheTest', () => {
    it('PaletteCacheTest_1', 0, () => {
      PaletteCache.instance().setDarkMode(true);
      for (let type = ColorType.THEME; type <= ColorType.TEXT_OPACITY_90; type++) {
        expect(PaletteCache.instance().getColor(type)).not().assertUndefined();
      }
      PaletteCache.instance().setDarkMode(false);
      for (let type = ColorType.THEME; type <= ColorType.TEXT_OPACITY_90; type++) {
        expect(PaletteCache.instance().getColor(type)).not().assertUndefined();
      }
    });

    it('PaletteCacheTest_2', 0, () => {
      const color = PaletteCache.instance().resourceToColor($r('sys.color.ohos_id_color_text_primary'));
      expect(color.alpha).assertEqual(229);
      expect(color.red).assertEqual(0);
      expect(color.green).assertEqual(0);
      expect(color.blue).assertEqual(0);

      const color2 = PaletteCache.instance().getColorV2($r('sys.color.ohos_id_color_text_primary'));
      expect(color2.alpha).assertEqual(229);
      expect(color2.red).assertEqual(0);
      expect(color.green).assertEqual(0);
      expect(color.blue).assertEqual(0);
    });
  })
}