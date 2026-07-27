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

import { beforeAll, describe, expect, it } from '@ohos/hypium'
import { GlobalThis, PermissionState, PreferencesFiles, PreferencesUtil, StatementStateKeys } from '@app/common/index'
import { NetWorkManger } from '@app/service.network/src/main/ets/impl/NetWorkManger'
import { TestUtil } from '../../utils/TestUtil'
import { UIAbility } from '@kit.AbilityKit'
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry'
import { Driver } from '@ohos.UiTest'

const TAG = 'NetWorkMangerTest'

const permissionChangedCallA = (isUserAgreeNetWork: boolean) => {

}
const permissionChangedCallB = (isUserAgreeNetWork: boolean) => {

}
const permissionChangedCallC = (isUserAgreeNetWork: boolean) => {

}

const delegator = AbilityDelegatorRegistry.getAbilityDelegator();

const driver = Driver.create();

export default function NetWorkMangerTest() {
  describe('NetWorkMangerTest', () => {

    beforeAll(async (done: Function) => {
      await TestUtil.clickToMainPage(driver, false);
      let ability: UIAbility;
      try {
        ability = await delegator.getCurrentTopAbility();
        PreferencesUtil.init(ability.context);
      } catch (error) {
      }
      done();
    })

    it('NetWorkMangeInit_return_false', 0, async (done: Function) => {
      PreferencesUtil
        .putBooleanValueSync(PreferencesFiles.STATEMENT_STATE, StatementStateKeys.KEY_IS_AGREE_STATEMENT, false);
      GlobalThis.getInstance().objectMap.remove('NetWorkManger');
      expect(NetWorkManger.getInstance().isUserAgreeNetWorkSync()).assertFalse();
      expect(await NetWorkManger.getInstance().isUserAgreeNetWork()).assertFalse();
      done();
    })

    it('NetWorkMangeInit_return_true', 0, async (done: Function) => {
      PreferencesUtil
        .putBooleanValueSync(PreferencesFiles.STATEMENT_STATE, StatementStateKeys.KEY_IS_AGREE_STATEMENT, true);
      GlobalThis.getInstance().objectMap.remove('NetWorkManger');
      TestUtil.setPrivateAttribute(NetWorkManger.getInstance(), 'isUserNetWorkGranted', true);
      expect(NetWorkManger.getInstance().isUserAgreeNetWorkSync()).assertTrue();
      expect(await NetWorkManger.getInstance().isUserAgreeNetWork()).assertTrue();
      done();
    })

    it('addNetWorkPermissionChangedListener', 0, (done: Function) => {
      expect(NetWorkManger.getInstance().addNetWorkPermissionChangedListener(permissionChangedCallA)).assertEqual(true);
      expect(NetWorkManger.getInstance().addNetWorkPermissionChangedListener(permissionChangedCallA)).assertEqual(false);
      expect(NetWorkManger.getInstance().addNetWorkPermissionChangedListener(permissionChangedCallB)).assertEqual(true);
      expect(NetWorkManger.getInstance().removeNetWorkPermissionChangedListener(permissionChangedCallB)).assertEqual(true);
      expect(NetWorkManger.getInstance().removeNetWorkPermissionChangedListener(permissionChangedCallB)).assertEqual(false);
      expect(NetWorkManger.getInstance().removeNetWorkPermissionChangedListener(permissionChangedCallC)).assertEqual(false);
      expect(NetWorkManger.getInstance().removeNetWorkPermissionChangedListener(permissionChangedCallA)).assertEqual(true);
      done();
    })

    let actionCount = 0;
    const permissionChangedCallD = (isUserAgreeNetWork: boolean) => {
      if (actionCount === 1) {
        expect(isUserAgreeNetWork).assertEqual(true);
      }
      if (actionCount === 2) {
        expect(isUserAgreeNetWork).assertEqual(false);
      }
    }

    it('updateUserNetWorkState', 0, async (done: Function) => {
      NetWorkManger.getInstance().addNetWorkPermissionChangedListener(permissionChangedCallD);
      actionCount++;
      await NetWorkManger.getInstance().updateUserNetWorkState(PermissionState.CONFIRMED);
      expect(NetWorkManger.getInstance().isUserAgreeNetWorkSync()).assertEqual(true);
      actionCount++;
      await NetWorkManger.getInstance().updateUserNetWorkState(PermissionState.DENIED);
      expect(NetWorkManger.getInstance().isUserAgreeNetWorkSync()).assertEqual(false);
      done();
    })

  })
}