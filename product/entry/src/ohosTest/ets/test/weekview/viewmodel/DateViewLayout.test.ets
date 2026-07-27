/*
 *  Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 */

import { DateCellViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/DateCellViewModel';
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
import { RootViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/RootViewModel';
import { TabType } from '@app/common';

export default function DateViewLayoutTest() {
  describe('DateViewLayoutTest', () => {
    it('isExtraInfoOnRight', 0, async (done: Function) => {
      let rootVM =  new RootViewModel(TabType.DAY);
      rootVM.extraInfoRight = true;
      let vm = new DateCellViewModel(0, rootVM);
      let onRight = vm.isExtraInfoOnRight();
      expect(onRight).assertTrue();

      rootVM.extraInfoRight = false;
      vm = new DateCellViewModel(0, rootVM);
      onRight = vm.isExtraInfoOnRight();
      expect(onRight).assertFalse();

      done();
    })
  })
}