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

import { Log } from '../../../../index';
import lazy systemTimer from '@ohos.systemTimer';
import { BusinessError } from '@ohos.base';

const TAG = 'SystemTimer';

/**
 * 系统定时器工具类
 *
 * @since 2022-11-26
 */
export class SystemTimerUtil {
  private timerId: number = -1;

  /**
   * 创建定时器
   *
   * timerOptions 定时器回调
   * @param end 定时器的触发时间
   */
  createTimer(timerOptions: systemTimer.TimerOptions, end: number) {
    systemTimer.createTimer(timerOptions, (err, timerId) => {
      Log.info(TAG, 'createTimer timerId: ' + timerId + ', end: ' + end);
      if (timerId) {
        systemTimer.startTimer(timerId, end).then((data) => {
          this.timerId = timerId;
          Log.info(TAG, `systemTime.startTimer success timerId : ` + timerId);
        }).catch((error: BusinessError) => {
          Log.logErrorMsg(TAG, 'createTimer->systemTimer.startTimer', error);
        });
      }
    });
  }

  /**
   * 销毁定时器
   */
  destroyTimer() {
    if (this.timerId === -1) {
      return;
    }
    systemTimer.destroyTimer(this.timerId).then((data) => {
      Log.info(TAG, `systemTime.destroyTimer success data timerId: ` + this.timerId);
    }).catch((error: BusinessError) => {
      Log.logErrorMsg(TAG, 'destroyTimer->systemTimer.destroyTimer', error);
    });
  }

  /**
   * 处理定时器
   *
   * @param minEndTime 之前所有日程最小结束时间
   * @param min 当前所有日程最小结束时间（修改日程时间，或者创建一个新日程，导致最小时间发生变化）
   * @param options 创建定时器携带数据
   * @return minEndTime 当前所有日程最小结束时间
   */
  processTimer(minEndTime: number, min: number, options: systemTimer.TimerOptions): number {
    // 判断是否需要更新定时器
    if (minEndTime === -1 || minEndTime > min) {
      if (this.timerId !== -1) {
        this.destroyTimer();
      }
      minEndTime = min;
      this.createTimer(options, min);
    }
    return minEndTime;
  }

  /**
   * 获取timerId
   */
  getTimerId(): number {
    return this.timerId;
  }
}