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
import { EmptyUtils, Log } from '@app/common/index'
import { HashMap, HashSet } from '@kit.ArkTS'

const TAG = 'UtilTest'

export default function UtilTest() {
  describe('UtilTest', () => {

    it('isEmptyString', 0, (done: Function) => {
      Log.info(TAG, `${TAG} isEmptyString begin`);
      expect(EmptyUtils.isEmptyString('')).assertEqual(true);
      expect(EmptyUtils.isEmptyString(null)).assertEqual(true);
      expect(EmptyUtils.isEmptyString(undefined)).assertEqual(true);
      expect(EmptyUtils.isEmptyString(' ', true)).assertEqual(true);
      expect(EmptyUtils.isEmptyString(' xx', true)).assertEqual(false);
      expect(EmptyUtils.isEmptyString(' xx')).assertEqual(false);

      expect(EmptyUtils.isNotEmptyString('')).assertEqual(false);
      expect(EmptyUtils.isNotEmptyString(null)).assertEqual(false);
      expect(EmptyUtils.isNotEmptyString(undefined)).assertEqual(false);
      expect(EmptyUtils.isNotEmptyString(' ', true)).assertEqual(false);
      expect(EmptyUtils.isNotEmptyString(' xx', true)).assertEqual(true);
      expect(EmptyUtils.isNotEmptyString(' xx')).assertEqual(true);
      done();
    })


    it('isEmptyArray', 0, (done: Function) => {
      Log.info(TAG, `${TAG} isEmptyString begin`);
      expect(EmptyUtils.isEmptyArray(null)).assertEqual(true);
      expect(EmptyUtils.isEmptyArray(undefined)).assertEqual(true);
      expect(EmptyUtils.isEmptyArray([])).assertEqual(true);
      const map: Map<string, string> = new Map();
      const hashMap: HashMap<string, string> = new HashMap();
      const set: Set<string> = new Set();
      const hashSet: HashSet<string> = new HashSet();
      expect(EmptyUtils.isEmptyArray(map)).assertEqual(true);
      expect(EmptyUtils.isEmptyArray(hashMap)).assertEqual(true);
      expect(EmptyUtils.isEmptyArray(set)).assertEqual(true);
      expect(EmptyUtils.isEmptyArray(hashSet)).assertEqual(true);

      expect(EmptyUtils.isNotEmptyArray(null)).assertEqual(false);
      expect(EmptyUtils.isNotEmptyArray(undefined)).assertEqual(false);
      expect(EmptyUtils.isNotEmptyArray([])).assertEqual(false);

      map.set('', '');
      hashMap.set('', '');
      set.add('');
      hashSet.add('');

      expect(EmptyUtils.isEmptyArray(map)).assertEqual(false);
      expect(EmptyUtils.isEmptyArray(hashMap)).assertEqual(false);
      expect(EmptyUtils.isEmptyArray(set)).assertEqual(false);
      expect(EmptyUtils.isEmptyArray(hashSet)).assertEqual(false);


      done();
    })

    it('test_isNotOrEmptyString', 0, () => {
      expect(EmptyUtils.isNotOrEmptyString('')).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString(null)).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString(undefined)).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString(1)).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString(true)).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString('  ', true)).assertEqual(true);
      expect(EmptyUtils.isNotOrEmptyString('aaa  ', true)).assertEqual(false);
    })

    it('test_isStringAndNotEmpty', 0, () => {
      expect(EmptyUtils.isStringAndNotEmpty('')).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty(null)).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty(undefined)).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty(1)).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty(true)).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty('  ', true)).assertEqual(false);
      expect(EmptyUtils.isStringAndNotEmpty('aaa  ', true)).assertEqual(true);
    })

  })
}