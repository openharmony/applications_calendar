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

import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { HAGHelper } from '@app/service.network/src/main/ets/onelink/HAGHelper';
import { PermissionState } from '@app/common';


export default function HAGHelperTest() {
  describe('HAGHelperTest', () => {
    let helper: HAGHelper;
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
      helper = HAGHelper.instance();
    });

    it('HAGHelperTest_doInBackground_CONFIRMED', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(helper, helper.getNetPermission);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(PermissionState.CONFIRMED);
      let result = await helper.doInBackground();
      expect(result).assertEqual(true);
      done();
    });


    it('HAGHelperTest_doInBackground_DENIED', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(helper, helper.getNetPermission);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(PermissionState.DENIED);
      let result = await helper.doInBackground();
      expect(result).assertEqual(true);
      done();
    });


    it('HAGHelperTest_doInBackground_UNCONFIRMED', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(helper, helper.getNetPermission);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(PermissionState.UNCONFIRMED);
      let result = await helper.doInBackground();
      expect(result).assertEqual(true);
      done();
    });
  })
}