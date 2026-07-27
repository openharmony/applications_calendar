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
import { Log } from '@app/common';
import window from '@ohos.window';

/**
 * 顶部状态栏字体颜色跟随深色模式变化
 *
 */

export const SYSTEM_BAR_PROPERTIES_BLACK: window.SystemBarProperties = {
  statusBarContentColor: "#000000"
};

export const SYSTEM_BAR_PROPERTIES_WHITE: window.SystemBarProperties = {
  statusBarContentColor: "#FFFFFF"
};

const TAG = 'WindowManager';

/**
 * 相关代码：窗口管理类
 */
export class WindowManager {
  private static instance: WindowManager | null = null;
  private windowStage: window.WindowStage | null = null;
  private window: window.Window | null = null;

  public static getInstance(): WindowManager {
    if (!WindowManager.instance) {
      WindowManager.instance = new WindowManager();
    }
    return WindowManager.instance;
  }

  public registerWindowStage(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
  }


  public setSystemBarProperties(isDarkMode: boolean): void {
    let properties: window.SystemBarProperties;
    if (isDarkMode) {
      properties = SYSTEM_BAR_PROPERTIES_WHITE;
    } else {
      properties = SYSTEM_BAR_PROPERTIES_BLACK;
    }
    try {
      this.getWindow().then((win: window.Window) => {
        const promise = win.setWindowSystemBarProperties(properties);
        promise.then(() => {
          Log.info(TAG, 'setSystemBarProperties success');
        }).catch((err: Error)=>{
          Log.error(TAG, 'setSystemBarProperties error, message:' + err?.message);
        })
      });
    } catch (exception) {
      Log.error(TAG, 'Failed to set the system bar properties. Cause: ' + exception?.message);
    }

  }

  private getWindow(): Promise<window.Window> {
    return new Promise((resolve, reject) => {
      if (this.window) {
        resolve(this.window);
        return;
      }

      if (!this.windowStage) {
        reject(null);
        return;
      }

      this.windowStage.getMainWindow().then((window: window.Window) => {
        resolve(window);
      }).catch(() => {
        reject(null);
      });
    });
  }
}