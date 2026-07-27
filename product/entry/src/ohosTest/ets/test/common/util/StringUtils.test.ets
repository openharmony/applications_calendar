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

import { describe, expect, it, } from '@ohos/hypium';
import { StringUtils } from '@app/common/index';


export default function StringUtilsTest() {
  describe('StringUtilsTest', () => {
    it('test_stringToUint8Array', 0, () => {
      expect(StringUtils.stringToUint8Array('').data.length === 0).assertTrue();
      expect(StringUtils.stringToUint8Array(null).data.length === 0).assertTrue();
      expect(StringUtils.stringToUint8Array(undefined).data.length === 0).assertTrue();
      expect(StringUtils.stringToUint8Array('中').data.length === 3).assertTrue();
    })

    it('test_uint8ArrayToString', 0, () => {
      expect(StringUtils.uint8ArrayToString(new Uint8Array()).data).assertEqual('');
      expect(StringUtils.uint8ArrayToString(null).data).assertEqual('');
      expect(StringUtils.uint8ArrayToString(StringUtils.stringToUint8Array('中').data).data).assertEqual('中');
    })

    it('test_containsOnlyDigits', 0, () => {
      expect(StringUtils.containsOnlyDigits('123456')).assertTrue();
      expect(StringUtils.containsOnlyDigits('a123456')).assertFalse();
      expect(StringUtils.containsOnlyDigits('')).assertFalse();
      expect(StringUtils.containsOnlyDigits("123'")).assertFalse();
      expect(StringUtils.containsOnlyDigits('abcdefg')).assertFalse();
    })
  })
}