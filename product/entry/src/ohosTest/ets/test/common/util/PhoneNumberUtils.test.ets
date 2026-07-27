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
import { PhoneNumberUtils } from '@app/common';

const TAG = 'PhoneNumberUtilsTest';

export default function PhoneNumberUtilsTest() {
  describe('PhoneNumberUtilsTest', () => {
    const nomalPhone = '13611112222';
    const xgPhone = '51111222'
    const amPhone = '61111222'
    const twPhone = '0911112222';
    const code86 = '+86';
    const code852 = '+852';
    const code853 = '+853';
    const code886 = '+886';
    const codeNotSupport = '+123';
    it('removeInternationalCode_null', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode('')).assertEqual('')
    })
    it('removeInternationalCode_normal', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(nomalPhone)).assertEqual(nomalPhone)
    })
    it('removeInternationalCode_86', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(code86 + nomalPhone)).assertEqual(nomalPhone)
    })
    it('removeInternationalCode_852', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(code852 + xgPhone)).assertEqual(xgPhone)
    })
    it('removeInternationalCode_853', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(code853 + amPhone)).assertEqual(amPhone)
    })
    it('removeInternationalCode_886', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(code886 + twPhone)).assertEqual(twPhone)
    })
    it('removeInternationalCode_NotSupport', 0, () => {
      expect(PhoneNumberUtils.removeInternationalCode(codeNotSupport + nomalPhone)).assertEqual(nomalPhone)
    })
  })
}