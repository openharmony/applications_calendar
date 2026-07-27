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
import { PaintCache, TextArg } from '@app/common/src/main/ets/graphic/PaintCache';

export default function TextCacheTest() {
  describe('TextCacheTest', () => {
    it('TextCacheTest_1', 0, () => {
      expect(PaintCache.instance().getPath()).not().assertUndefined();
      expect(PaintCache.instance().getPath()).not().assertUndefined();

      const arg1: TextArg = {
        fontSize: 10,
        text: 'arg1',
        bold: false,
        fontFamily: 'defaultFont'
      };
      const arg2: TextArg = {
        fontSize: 10,
        text: 'arg',
        bold: false,
        fontFamily: 'defaultFont'
      };
      const arg3: TextArg = {
        fontSize: 12,
        text: 'arg',
        bold: false,
        fontFamily: 'defaultFont'
      };
      const arg4: TextArg = {
        fontSize: 12,
        text: 'arg',
        bold: true,
        fontFamily: 'defaultFont'
      };
      const arg5: TextArg = {
        fontSize: 12,
        text: 'arg5arg5arg5arg5',
        bold: true,
        fontFamily: 'defaultFont'
      };

      expect(PaintCache.instance().getText(arg1)).not().assertUndefined();
      expect(PaintCache.instance().isInTextCache(arg2)).assertFalse();
      expect(PaintCache.instance().isInTextCache(arg1)).assertTrue();
      expect(PaintCache.instance().getText(arg3)).not().assertUndefined();
      expect(PaintCache.instance().isInTextCache(arg4)).assertFalse();
      expect(PaintCache.instance().getText(arg5)).not().assertUndefined();
      expect(PaintCache.instance().isInTextCache(arg5)).assertFalse();
    });
  })
}