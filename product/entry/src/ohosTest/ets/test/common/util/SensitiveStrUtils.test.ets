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
import { maskString } from '@app/common/index';

export default function SensitiveStrUtilTest() {
  describe('maskString', () => {
    // should return the original string when the length is less than or equal to 0
    it('maskString_emptyStr', 0, () => {
      expect(maskString('')).assertEqual('');
    })

    it('maskString_shortStr', 0, () => {
      expect(maskString('abc')).assertEqual('a***c');
    })

    it('maskString_normalStr', 0, () => {
      expect(maskString('abcdef')).assertEqual('abc***ef');
    })

    it('maskString_longStrLength', 0, () => {
      expect(maskString('12345678')).assertEqual('123***78');
    })

    it('maskString_longStr', 0, () => {
      expect(maskString('abcdefghij')).assertEqual('abc***hij');
    })
  })
}