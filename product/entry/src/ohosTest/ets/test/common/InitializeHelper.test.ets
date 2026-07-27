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
import { InitializeHelper } from '@app/common/src/main/ets/commoncapability/init/InitializeHelper';
import { Initialize } from '@app/common/src/main/ets/commoncapability/init/Initialize';

class InitializeTest implements Initialize {
  initPriority(): number {
    return 0;
  }

  isHasInit(): boolean {
    return false;
  }

  getTag(): string {
    return 'Initialize1';
  }

  async isCanInit(): Promise<boolean> {
    return true;
  }

  async init(): Promise<boolean> {
    return true;
  }
}

export default function InitializeHelperTest() {
  describe('InitializeHelper', () => {
    let initializeHelper: InitializeHelper;
    let initialize1: InitializeTest;

    beforeEach(() => {
      initialize1 = new InitializeTest();
      initializeHelper = InitializeHelper.getInstance();
    });

    it('add_initialize', 0, () => {
      initializeHelper.addInitialize(initialize1);
      expect(initializeHelper.getMInitializes().has(initialize1)).assertTrue();
    });

    it('add_repeat_initialize', 0, () => {
      initializeHelper.addInitialize(initialize1);
      initializeHelper.addInitialize(initialize1);
      expect(initializeHelper.getMInitializes().length).assertEqual(2);
    });

    it('remove_initialize', 0, () => {
      initializeHelper.addInitialize(initialize1);
      expect(initializeHelper.getMInitializes().has(initialize1)).assertTrue();
      initializeHelper.removeInitialize(initialize1);
      expect(initializeHelper.getMInitializes().has(initialize1)).assertFalse();
    });
  });
}