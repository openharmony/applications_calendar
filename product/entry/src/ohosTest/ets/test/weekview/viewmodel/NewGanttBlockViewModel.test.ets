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
import { NewGanttBlockViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/NewGanttBlockViewModel';

export default function NewGanttBlockViewModelTest() {
  describe('GanttAddBlockViewModelTest', () => {
    it('updateNewAgendaHeight_01', 0, () => {
      const addBlock = new NewGanttBlockViewModel();
      addBlock.positionY = 20;

      addBlock.updateNewAgendaHeight(-20, true);
      expect(addBlock.height).assertEqual(40);
      expect(addBlock.positionX).assertEqual(0);
      addBlock.updateUpHeight();
      expect(addBlock.heightCount).assertEqual(2);
      expect(addBlock.originalHeight).assertEqual(40);
    })

    it('updateNewAgendaHeight_02', 0, () => {
      const addBlock = new NewGanttBlockViewModel();
      addBlock.positionY = 20;
      addBlock.updateNewAgendaHeight(-20, false);
      expect(addBlock.height).assertEqual(40);
      expect(addBlock.positionX).assertEqual(0);
      addBlock.updateDownHeight();
      expect(addBlock.heightCount).assertEqual(2);
      expect(addBlock.originalHeight).assertEqual(40);
    })
  })
}