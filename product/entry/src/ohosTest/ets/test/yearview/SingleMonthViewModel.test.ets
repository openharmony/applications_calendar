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
import { SingleMonthViewModel } from '@app/feature.yearview/src/main/ets/viewmodel/SingleMonthViewModel';
import { GlobalData, GlobalDataKeys } from '@app/common';

export default function SingleMonthViewModelTest() {
  describe('SingleMonthViewModelTest', () => {
    beforeEach(() => {
      GlobalData.instance().set(GlobalDataKeys.WEEKENDS, [0, 6]);
    })

    it('construct_001', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      expect(instance.year).assertEqual(2023);
      expect(instance.month).assertEqual(1);
      const monthInfo = instance.monthInfo;
      if (!monthInfo) {
        expect(monthInfo).not().assertUndefined();
      } else {
        expect(monthInfo.getSolarYear()).assertEqual(2023);
        expect(monthInfo.getMonth()).assertEqual(1);
      }
    })

    it('dayViewModels', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      expect(instance.year).assertEqual(2023);
      expect(instance.month).assertEqual(1);
    })

    it('onStartOfWeekChange_01', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      expect(instance.startOfWeek).assertEqual(0);
      expect(instance.dayItemSpace).assertEqual(0);
      instance.onStartOfWeekChange(1);
      expect(instance.startOfWeek).assertEqual(1);
      expect(instance.dayItemSpace).assertEqual(6);
    })

    it('onStartOfWeekChange_02', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      expect(instance.startOfWeek).assertEqual(0);
      expect(instance.dayItemSpace).assertEqual(0);
      instance.onStartOfWeekChange(6);
      expect(instance.startOfWeek).assertEqual(6);
      expect(instance.dayItemSpace).assertEqual(1);
    })

    it('updateByYear_001', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      instance.updateByYear(2025);
      expect(instance.year).assertEqual(2025);
      expect(instance.month).assertEqual(1);
      if (!instance.monthInfo) {
        expect(instance.monthInfo).not().assertUndefined();
      } else {
        expect(instance.monthInfo.getSolarYear()).assertEqual(2025);
        expect(instance.monthInfo.getMonth()).assertEqual(1);
      }
    })

    it('updateByYear_002', 0, () => {
      let instance = new SingleMonthViewModel(2023, 1);
      instance.updateByYear(2025);
      expect(instance.year).assertEqual(2025);
      expect(instance.month).assertEqual(1);
      if (!instance.monthInfo) {
        expect(instance.monthInfo).not().assertUndefined();
      } else {
        expect(instance.monthInfo.getSolarYear()).assertEqual(2025);
        expect(instance.monthInfo.getMonth()).assertEqual(1);
      }
    })
  })
}