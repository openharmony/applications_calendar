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
import { AccessCountMap } from '@app/common/src/main/ets/templates/AccessCountMap';

export default function AccessCountMapTest() {
  describe('AccessCountMapTest', () => {

    it('set_and_get', 0, () => {
      const map = new AccessCountMap<string, number>(3);
      map.set('a', 1);
      map.set('b', 2);
      map.set('c', 3);
      expect(map.get('a')).assertEqual(1);
      expect(map.get('b')).assertEqual(2);
      expect(map.get('c')).assertEqual(3);
    });

    it('set_and_get_with_max_size', 0, () => {
      const map = new AccessCountMap<string, number>(2);
      map.set('a', 1);
      map.set('b', 2);
      map.set('c', 3);
      expect(map.get('a')).assertEqual(undefined);
      expect(map.get('b')).assertEqual(2);
      expect(map.get('c')).assertEqual(3);
    });

    it('has', 0, () => {
      const map = new AccessCountMap<string, number>(3);
      map.set('a', 1);
      expect(map.has('a')).assertEqual(true);
      expect(map.has('b')).assertEqual(false);
    });

    it('set_and_get_with_max_size_and_access_count', 0, () => {
      const map = new AccessCountMap<string, number>(3);
      map.set('a', 1);
      map.set('b', 2);
      map.set('c', 3);
      map.get('a');
      map.get('a');
      map.set('d', 4);
      expect(map.get('a')).assertEqual(1);
      expect(map.get('b')).assertEqual(undefined);
      expect(map.get('c')).assertEqual(3);
      expect(map.get('d')).assertEqual(4);
    });
  })
}