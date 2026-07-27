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

import { UIContext, window } from '@kit.ArkUI';
import { Log } from '../default/common/Log';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'WindowSizeManager';
export class WindowSizeManager {
  private size: window.Size = { width: 0, height: 0 };
  public static instance: WindowSizeManager;

  private constructor() {
  }

  public static getInstance(): WindowSizeManager {
    if (!WindowSizeManager.instance) {
      WindowSizeManager.instance = new WindowSizeManager();
    }
    return WindowSizeManager.instance;
  }

  public init() {
    const uiContext: UIContext | undefined = AppStorage.get('uiContext');
    const context = uiContext?.getHostContext();
    if (!uiContext || !context) {
      Log.error(TAG, `context is undefined.`);
      return;
    }
    window.getLastWindow(context).then((w: window.Window) => {
      this.updateSize(w, uiContext);
    }).catch((err: BusinessError) => {
      Log.error(TAG, `getLastWindow error, errCode: ${err.code}, errMes: ${err.message}`);
    });
  }

  public updateSize(w: window.Window, uiContext: UIContext) {
    try {
      const rect: window.Rect = w.getWindowProperties().windowRect;
      this.size.width = uiContext?.px2vp(rect.width) ?? 0;
      this.size.height = uiContext?.px2vp(rect.height) ?? 0;
      Log.info(TAG, `[windowWidth]${this.size.width} [windowHeight]${this.size.height}`);
    } catch (err) {
      Log.error(TAG, `getWindowProperties error, errCode: ${err.code}, errMes: ${err.message}`);
    }
  }

  public get(): window.Size {
    return this.size;
  }
}