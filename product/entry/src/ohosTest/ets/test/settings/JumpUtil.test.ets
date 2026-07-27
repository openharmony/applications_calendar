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
import { ArgumentMatchers, beforeAll, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { Log } from '@app/common';
import { common, UIAbility } from '@kit.AbilityKit';
import { JumpUtils } from '@app/feature.settings/src/main/ets/utils/JumpUtil';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { TestUtil } from '../utils/TestUtil';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
const TAG = 'JumpUtilsTest';

export default function JumpUtilsTest() {
  let ability: UIAbility;
  describe('JumpUtilsTest', () => {
    beforeAll(async (done: Function) => {
      try {
        ability = await delegator.getCurrentTopAbility();
      } catch (error) {
        Log.error(TAG, `getCurrentTopAbility error for ${error?.message}`);
      }
      done();
    })

    it('test_startApp', 0, async (done: Function) => {
      let startApp = TestUtil.getPrivateFunction(JumpUtils, 'startApp');
      if (startApp) {
        let mocker: MockKit = new MockKit();
        let context: common.UIAbilityContext = ability.context;
        let mockStartAbility: Function = mocker.mockFunc(context, context.startAbility);
        when(mockStartAbility)(ArgumentMatchers.any).afterReturn(Promise.resolve());

        let url: string = 'store://enterprise/manifest';
        let callback: Function | undefined = undefined;
        let parameters: Record<string, Object> | undefined = undefined;
        let isSpecificApp: boolean = false;
        let result: ESObject = await startApp(context, url, callback, parameters, isSpecificApp);
        expect(result).assertUndefined();

        isSpecificApp = true;
        when(mockStartAbility)(ArgumentMatchers.any).afterReturn(Promise.resolve());
        result = await startApp(context, url, callback, parameters, isSpecificApp);
        expect(result).assertUndefined();
        when(mockStartAbility)(ArgumentMatchers.any).afterReturn(Promise.reject(new Error('错误')));
        result = await startApp(context, url, callback, parameters, isSpecificApp);
        expect(result).assertUndefined();

        mocker.ignoreMock(context, context.startAbility);
        done();
      }
    });

    it('test_getSpecificApp', 0, () => {
      let getSpecificApp = TestUtil.getPrivateFunction(JumpUtils, 'getSpecificApp');
      if (getSpecificApp) {
        expect(getSpecificApp('store://enterprise/manifest')).assertEqual('com.openharmony.appgallery');
        expect(getSpecificApp('')).assertEqual('');
      }
    })

  })
}