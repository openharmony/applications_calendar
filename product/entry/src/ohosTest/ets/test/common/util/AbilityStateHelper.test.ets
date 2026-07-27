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
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

import { Driver } from '@ohos.UiTest';
import { TestUtil } from '../../utils/TestUtil';
import { UIAbility } from '@kit.AbilityKit';
import { AbilityStateHelper } from '@app/common';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
const driver = Driver.create();

const TAG = 'AbilityStateHelperTest'

const foregroundChangedCall: Callback<boolean> = (isMainAbilityForeground: boolean) => {

}

const foregroundChangedCall1: Callback<boolean> = (isMainAbilityForeground: boolean) => {

}
const foregroundChangedCall2: Callback<boolean> = (isMainAbilityForeground: boolean) => {

}

export default function AbilityStateHelperTest() {

  describe('AbilityStateHelperTest', () => {
    it('AbilityStateHelperTest', 0, async (done: Function) => {
      await TestUtil.clickToMainPage(driver, false);
      let ability: UIAbility;
      try {
        ability = await delegator.getCurrentTopAbility();
        expect(AbilityStateHelper.getInstance().addAbilityForegroundCall(ability.context, foregroundChangedCall)).assertTrue();
        expect(AbilityStateHelper.getInstance().addAbilityForegroundCall(ability.context, foregroundChangedCall)).assertFalse();
        expect(AbilityStateHelper.getInstance().addAbilityForegroundCall(ability.context, foregroundChangedCall1)).assertTrue();
        AbilityStateHelper.getInstance().updateAbilityForeground(ability.context, false);
        expect(AbilityStateHelper.getInstance().isAbilityForeground(ability.context)).assertFalse();
        AbilityStateHelper.getInstance().updateAbilityForeground(ability.context, true);
        expect(AbilityStateHelper.getInstance().isAbilityForeground(ability.context)).assertTrue();
        expect(AbilityStateHelper.getInstance().isAbilityForeground(null)).assertFalse();
        expect(AbilityStateHelper.getInstance().removeAbilityForegroundCall(ability.context, foregroundChangedCall1)).assertTrue();
        expect(AbilityStateHelper.getInstance().removeAbilityForegroundCall(ability.context, foregroundChangedCall1)).assertFalse();
        expect(AbilityStateHelper.getInstance().removeAbilityForegroundCall(ability.context, foregroundChangedCall)).assertTrue();
        expect(AbilityStateHelper.getInstance().removeAbilityForegroundCall(ability.context, foregroundChangedCall)).assertFalse();
        expect(AbilityStateHelper.getInstance().removeAbilityForegroundCall(ability.context, foregroundChangedCall2)).assertFalse();
        expect(AbilityStateHelper.getInstance().clearAbility(ability.context)).assertTrue();
        expect(AbilityStateHelper.getInstance().clearAbility(ability.context)).assertFalse();
      } catch (error) {

      }
      done();
    })
  })
}