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
import { UnusualMode } from '../constants/Constants';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { Log } from '../default/common/Log';

const TAG = 'ModeUtil';

export class ModeUtil {

  private static retailMode: boolean | undefined = undefined;

  static isHiCarOrSmallUpDownFoldMode(unusualMode: UnusualMode | undefined): boolean {
    if (!unusualMode) {
      return false;
    }
    if (unusualMode === UnusualMode.HICAR) {
      return true;
    }
    if (unusualMode === UnusualMode.SMALL_UP_DOWN_FOLD) {
      return true;
    }
    return false;
  }

  static isSmallUpDownFoldMode(unusualMode: UnusualMode | undefined): boolean {
    if (!unusualMode) {
      return false;
    }
    if (unusualMode === UnusualMode.SMALL_UP_DOWN_FOLD) {
      return true;
    }
    return false;
  }

  static isHiCarMode(unusualMode: UnusualMode | undefined): boolean {
    if (!unusualMode) {
      return false;
    }
    if (unusualMode === UnusualMode.HICAR) {
      return true;
    }
    return false;
  }

  // 判断是否是门店版本
  static isRetailMode() {
    if (ModeUtil.retailMode !== undefined) {
      return ModeUtil.retailMode;
    }
    try {
      let value = systemParameterEnhance.getSync('const.dfx.enable_retail');
      ModeUtil.retailMode = Boolean(value).valueOf();
    } catch (err) {
      Log.logErrorMsg(TAG, 'isRetailMode', err);
      ModeUtil.retailMode = undefined;
      return false;
    }
    return ModeUtil.retailMode;
  }
}

