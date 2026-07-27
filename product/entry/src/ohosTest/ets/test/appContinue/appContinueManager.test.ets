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
import { AgendaEventInfo, AppContinueManager, NavPathName } from '@app/common';
import { common } from '@kit.AbilityKit';

const TAG = 'AppContinueManagerTest';

export default function AppContinueManagerTest() {
  describe('AppContinueManagerTest', () => {
    beforeEach(() => {
    })

    it('addGetRemove', 0, () => {
      AppContinueManager.getInstance().addContinuePage({
        pageName: NavPathName.AGENDA_DETAIL,
        event: new AgendaEventInfo(),
        calendarType: ''
      })
      let continuePage = AppContinueManager.getInstance().getContinuePage();
      expect(continuePage?.pageName).assertEqual(NavPathName.AGENDA_DETAIL);

      AppContinueManager.getInstance().removeContinuePage(NavPathName.AGENDA_DETAIL);
      continuePage = AppContinueManager.getInstance().getContinuePage();
      expect(continuePage).assertUndefined();
    });

    it('setContinueState', 0, () => {
      let success = AppContinueManager.getInstance()
        .setAppContinueState(false, getContext() as common.UIAbilityContext);
      expect(success).assertTrue();
    });
  });
}