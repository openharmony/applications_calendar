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

import { PasteHelper } from '@app/feature.agenda';
import { describe, expect, it } from '@ohos/hypium';


export default function PasteHelperTest() {
  describe('PasteHelperTest', () => {

    it('askSystemPaste_empty', 0, (done: Function) => {
      PasteHelper.getInstance().clearSystemBoard();
      let hasContent: boolean = PasteHelper.getInstance().askSystemPaste();
      expect(hasContent).assertEqual(false);
      done();
    })

    it('askSystemPaste_notEmpty', 0, (done: Function) => {
      let content: string = 'this is paste content';
      PasteHelper.getInstance().clearSystemBoard();
      PasteHelper.getInstance().setSystemBoard(content);
      let hasContent: boolean = PasteHelper.getInstance().askSystemPaste();
      expect(hasContent).assertEqual(true);
      done();
    })
  })
}