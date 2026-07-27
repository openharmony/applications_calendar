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
import { TypeUtils } from '@app/common';
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

export default function TypeUtilsTest() {
  describe('TypeUtilsTest', () => {

    it('test_TypeUtils_isString', 0, () => {
      expect(TypeUtils.isString('')).assertTrue();
      expect(TypeUtils.isString(false)).assertFalse();
      expect(TypeUtils.isString(1)).assertFalse();
    })

    it('test_TypeUtils_isNumber', 0, () => {
      expect(TypeUtils.isNumber('')).assertFalse();
      expect(TypeUtils.isNumber(false)).assertFalse();
      expect(TypeUtils.isNumber(1)).assertTrue();
    })

    it('test_TypeUtils_isBoolean', 0, () => {
      expect(TypeUtils.isBoolean('')).assertFalse();
      expect(TypeUtils.isBoolean(1)).assertFalse();
      expect(TypeUtils.isBoolean(false)).assertTrue();
      expect(TypeUtils.isBoolean(true)).assertTrue();
    })

    it('test_TypeUtils_isFunction', 0, () => {
      expect(TypeUtils.isFunction('')).assertFalse();
      expect(TypeUtils.isFunction(1)).assertFalse();
      expect(TypeUtils.isFunction(false)).assertFalse();
      expect(TypeUtils.isFunction(true)).assertFalse();
      const fun = () => {
      }
      expect(TypeUtils.isFunction(fun)).assertTrue();
    })
  })
}