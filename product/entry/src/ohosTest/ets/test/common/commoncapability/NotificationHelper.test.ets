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
import { Log, NotificationHelper, PreferencesUtil } from '@app/common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { NotificationRequestState } from '@app/common/src/main/ets/default/common/declare';
import { UIAbility } from '@kit.AbilityKit';
import { Driver } from '@kit.TestKit';
import { TestUtil } from '../../utils/TestUtil';

const TAG = 'NotificationHelperTest'

const driver = Driver.create();

const delegator = AbilityDelegatorRegistry.getAbilityDelegator()

const permissionChangedCallA = (isNotificationGranted: boolean) => {

}
const permissionChangedCallB = (isNotificationGranted: boolean) => {

}
const permissionChangedCallC = (isNotificationGranted: boolean) => {

}

class MockNotificationHelper extends NotificationHelper {
  public updateRequestNotificationState(notificationRequestState: NotificationRequestState): void {
    super.updateRequestNotificationState(notificationRequestState);
  }
}

const notificationHelper = new MockNotificationHelper();

export default function NotificationHelperTest() {
  describe('NotificationHelperTest', () => {

    it('addNotificationPermissionChangedListener', 0, (done: Function) => {
      expect(notificationHelper.addNotificationPermissionChangedListener(permissionChangedCallA)).assertEqual(true);
      expect(notificationHelper.addNotificationPermissionChangedListener(permissionChangedCallA)).assertEqual(false);
      expect(notificationHelper.addNotificationPermissionChangedListener(permissionChangedCallB)).assertEqual(true);
      expect(notificationHelper.removeNotificationPermissionChangedListener(permissionChangedCallB)).assertEqual(true);
      expect(notificationHelper.removeNotificationPermissionChangedListener(permissionChangedCallB)).assertEqual(false);
      expect(notificationHelper.removeNotificationPermissionChangedListener(permissionChangedCallC)).assertEqual(false);
      expect(notificationHelper.removeNotificationPermissionChangedListener(permissionChangedCallA)).assertEqual(true);
      done();
    })

    let actionCount = 0;
    const permissionChangedCallD = (isNotificationGranted: boolean) => {
      if (actionCount === 1) {
        expect(isNotificationGranted).assertEqual(false);
      }
      if (actionCount === 2) {
        expect(isNotificationGranted).assertEqual(true);
      }
    }

    it('updateRequestNotificationState', 0, (done: Function) => {
      notificationHelper.addNotificationPermissionChangedListener(permissionChangedCallD);
      actionCount++;
      notificationHelper.updateRequestNotificationState(NotificationRequestState.REQUEST_FAILED);
      expect(notificationHelper.isNotificationGranted()).assertEqual(false);
      actionCount++;
      notificationHelper.updateRequestNotificationState(NotificationRequestState.REQUEST_SUCCESS);
      expect(notificationHelper.isNotificationGranted()).assertEqual(true);
      done();
    })

    it('setBadgeNumber', 0, async (done: Function) => {
      await TestUtil.clickToMainPage(driver, false);
      let ability: UIAbility;
      try {
        ability = await delegator.getCurrentTopAbility();
        PreferencesUtil.init(ability.context);
      } catch (error) {
        Log.error(TAG, 'get current top ability error')
      }
      done();
      expect(await notificationHelper.setBadgeNumber(-1)).assertEqual(false);
      expect(await notificationHelper.setBadgeNumber(5)).assertEqual(true);
    })

  })
}