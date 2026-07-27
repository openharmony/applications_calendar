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

import { beforeEach, describe, expect, it } from '@ohos/hypium';
import { NavPageBuilderFactory } from '@app/common';
import { TestUtil } from '../../utils/TestUtil';

@Builder
function harBuilder(value: object) {
}

export default function NavPageBuilderFactoryTest() {
  describe('NavPageBuilderFactoryTest', () => {
    beforeEach(() => {
      TestUtil.setPrivateAttribute(NavPageBuilderFactory, 'builderMap',
        new Map<string, WrappedBuilder<[object]>>())
    });

    it('registerBuilder', 0, () => {
      let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
      NavPageBuilderFactory.registerBuilder('testName', builder);
      expect(NavPageBuilderFactory.getBuilder('testName')).assertEqual(builder);
    })

    it('getBuilder', 0, () => {
      expect(NavPageBuilderFactory.getBuilder('testName1')).assertEqual(undefined);
    })
  })
}