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

import { GlobalThis, WindowSizeManager } from '@app/common';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { UIContext, window } from '@kit.ArkUI';

export default function WindowSizeManagerTest() {
  describe('WindowSizeManagerTest', () => {
    let windowSizeManager = WindowSizeManager.getInstance();
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('initTest_01', 0, () => {
      AppStorage.setOrCreate('uiContext', undefined);
      windowSizeManager.init();
      expect(WindowSizeManager.getInstance()).assertEqual(WindowSizeManager.getInstance());
    });

    it('initTest_02', 0, () => {
      let uiContext = new UIContext();
      AppStorage.setOrCreate('uiContext', uiContext);
      const getHostContext = mocker.mockFunc(uiContext, uiContext.getHostContext);
      when(getHostContext)(ArgumentMatchers.any).afterReturn(GlobalThis.getInstance().getBasicContext());

      const updateSize = mocker.mockFunc(windowSizeManager, windowSizeManager.updateSize);
      when(updateSize)(ArgumentMatchers.any).afterThrow('initTest_02 error');
      windowSizeManager.init();
      expect(WindowSizeManager.getInstance()).assertEqual(WindowSizeManager.getInstance());
      mocker.ignoreMock(windowSizeManager, windowSizeManager.updateSize);
    });

    it('updateSizeTest_01', 0, () => {
      let w = {
        getWindowProperties() {
          throw new Error('updateSizeTest_02 error');
          return {
            windowRect: {
            }
          } as window.WindowProperties;
        }
      } as window.Window;

      let c = {
        px2vp(value: number) {
          return value;
        }
      } as UIContext;

      windowSizeManager?.updateSize(w, c);
      expect(windowSizeManager?.get()).not().assertUndefined();
    });

    it('updateSizeTest_02', 0, () => {
      let w = {
        getWindowProperties() {
          return {
            windowRect: {
              width: 100,
              height: 100
            }
          } as window.WindowProperties;
        }
      } as window.Window;
      let c = {
        px2vp(value: number) {
          return value;
        }
      } as UIContext;
      windowSizeManager.updateSize(w, c);
      expect(windowSizeManager.get().width).assertLarger(0);
    });
  });
}