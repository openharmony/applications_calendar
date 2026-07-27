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

import { describe, expect, it } from '@ohos/hypium'
import { encode, Log } from '@app/common/index'

const TAG = 'Base64UtilTest'

export default function Base64UtilTest() {
  describe('Base64UtilTest', () => {

    it('encode', 0, (done: Function) => {
      Log.info(TAG, `${TAG} Base64Util_encode begin`);
      expect(encode('u_pu2t15s3:yjxzafk2')).assertEqual('dV9wdTJ0MTVzMzp5anh6YWZrMg==');
      done();
    })

  })
}