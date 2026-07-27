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
import { vibrator } from '@kit.SensorServiceKit';
import { Log } from '../default/common/Log';

const TAG = 'VibratorUtils'

/**
 * 马达振动器工具类
 */
export class VibratorUtils {
  /**
   * 触发预制指令的震动
   * @param effectId 预制指令，如:haptic.long_press_light
   * @returns
   */
  public static async startPresetVibration(effectId: string): Promise<void> {
    let isSupport = false;
    try {
      // 查询是否支持指令
      isSupport = await vibrator.isSupportEffect(effectId);
    } catch (error) {
      Log.logErrorMsg(TAG, 'isSupportEffect', error);
    }
    if (!isSupport) {
      Log.warn(TAG, 'isSupportEffect: false');
      return;
    }
    try {
      // 触发马达振动
      await vibrator.startVibration({
        type: 'preset',
        effectId: effectId,
        count: 1,
      }, {
        usage: 'unknown'
      });
    } catch (error) {
      Log.logErrorMsg(TAG, 'startVibration', error);
    }
  }
}

/*
 * VibrationType 振动器预置质量常量
 */
export enum VibrationType {
  // 滑动
  SLIDE = 'haptic.slide',

  // 长按（弱反馈）
  LONG_PRESS_LIGHT = 'haptic.long_press_light',
}
