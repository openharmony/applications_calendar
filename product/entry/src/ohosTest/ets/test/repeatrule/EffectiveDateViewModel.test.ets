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

import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';
import {
  EffectiveDateMode,
  EffectiveDateViewModel } from '@app/commons.repeatruleview/src/main/ets/EffectiveDateViewModel';
import { describe, it, expect } from '@ohos/hypium';
import { beforeEach } from '@ohos/hypium/src/main/interface';

export default function EffectiveDateViewModelTest() {
  describe('EffectiveDateViewModelTest', () => {
    let vm: EffectiveDateViewModel;

    beforeEach(() => {
      vm = new EffectiveDateViewModel();
    })

    it('init_01', 0, (done: Function) => {
      const recurrence = new Recurrence();
      vm.init(recurrence, false, '');
      expect(vm.effectiveDateMode).assertEqual(EffectiveDateMode.FOREVER);
      done();
    });

    it('init_02', 0, (done: Function) => {
      const recurrence = new Recurrence();
      recurrence.setUntil(new Date().getTime());
      vm.init(recurrence, false, '');
      expect(vm.effectiveDateMode).assertEqual(EffectiveDateMode.UNTIL);
      done();
    });

    it('init_03', 0, (done: Function) => {
      const recurrence = new Recurrence();
      recurrence.setCount(5);
      vm.init(recurrence, false, '');
      expect(vm.effectiveDateMode).assertEqual(EffectiveDateMode.COUNT);
      done();
    });

    it('onEffectiveDateModeChanged_01', 0, (done: Function) => {
      vm.onEffectiveDateModeChanged(0);
      expect(vm.effectiveDateMode).assertEqual(EffectiveDateMode.FOREVER);
      expect(vm.isShowTimePick).assertTrue();
      expect(vm.isShowLimitsTimePick).assertTrue();
      done();
    });
  })
}