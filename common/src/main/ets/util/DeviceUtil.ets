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

import lazy bundleManager from '@ohos.bundle.bundleManager';
import { Log } from '../default/common/Log';

const TAG = 'DeviceUtil';
const X_GATE_BUNDLE_NAME: string = 'com.openharmony.xgate';
const X_GATE_OTHER_BUNDLE_NAME: string = 'com.openharmony.his.xgate';

/**
 * 设备工具类
 */
export class DeviceUtil {
  private static sIsEnable: boolean | undefined = undefined;

  private constructor() {

  }

  /**
   * 是否是PC it
   * Pc it 返回ture,手机抛异常
   * @returns
   */
  public static async isItVersion(): Promise<boolean> {
    if (DeviceUtil.sIsEnable !== undefined) {
      return DeviceUtil.sIsEnable;
    }
    let isEnable: boolean = false;
    try {
      isEnable = await bundleManager.isApplicationEnabled(X_GATE_BUNDLE_NAME);
      Log.info(TAG, `isItVersion: ${isEnable}`);
    } catch (err) {
      Log.logErrorMsg(TAG, 'isItVersion', err);
      try {
        isEnable = await bundleManager.isApplicationEnabled(X_GATE_OTHER_BUNDLE_NAME);
        Log.info(TAG, `isItVersion: X_GATE_OTHER_BUNDLE_NAME ${isEnable}`);
      } catch (err) {
        Log.logErrorMsg(TAG, 'isItVersion X_GATE_OTHER_BUNDLE_NAME', err);
      }
    }
    DeviceUtil.sIsEnable = isEnable;
    return DeviceUtil.sIsEnable;
  }
}

