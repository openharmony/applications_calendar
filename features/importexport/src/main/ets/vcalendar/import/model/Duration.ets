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

import { EmptyUtils, Log } from '@app/common';

const TAG = 'Duration'

/*
 * 用来计算dtEnd的时间
 */
export class Duration {
  public sign: number = 1;
  public weeks: number = 0;
  public days: number = 0;
  public hours: number = 0;
  public minutes: number = 0;
  public seconds: number = 0;

  public Duration() {
  }


  /**
   * 解析 'P1D' 等字符串
   * @param durationStr
   * @returns false 解析失败
   */
  public parse(durationStr: string): boolean {
    this.reset();
    if (EmptyUtils.isEmptyString(durationStr, true)) {
      Log.warn(TAG, `parse durationStr is empty`);
      return false;
    }
    const len: number = durationStr.length;
    if (len < 1) {
      return false;
    }
    let index: number = 0;
    let c = durationStr.charAt(0);
    if (c == '-') {
      this.sign = -1;
      ++index;
    } else if (c == '+') {
      ++index;
    }
    c = durationStr.charAt(index);
    if (c != 'P') {
      Log.warn(TAG, "Duration.parse(str='" + durationStr + "') expected 'P' at index=" + index);
      return false;
    } else {
      ++index;
      if (len > index) {
        c = durationStr.charAt(index);
        if (c == 'T') {
          ++index;
        }
        for (let n = 0; index < len; ++index) {
          c = durationStr.charAt(index);
          const charCodeOfC = c.charCodeAt(0);
          const charCodeOf0 = '0'.charCodeAt(0)
          const charCodeOf9 = '9'.charCodeAt(0)
          if (charCodeOfC >= charCodeOf0 && charCodeOfC <= charCodeOf9) {
            n *= 10;
            n += charCodeOfC - 48;
          } else if (c == 'W') {
            this.weeks = n;
            n = 0;
          } else if (c == 'H') {
            this.hours = n;
            n = 0;
          } else if (c == 'M') {
            this.minutes = n;
            n = 0;
          } else if (c == 'S') {
            this.seconds = n;
            n = 0;
          } else if (c == 'D') {
            this.days = n;
            n = 0;
          } else if (c != 'T') {
            Log.warn(TAG, "Duration.parse(str='" + durationStr + "') unexpected char '" + c + "' at index=" + index);
            return false;
          }
        }
      }
    }
    return true;
  }

  reset() {
    this.sign = 1;
    this.weeks = 0;
    this.days = 0;
    this.hours = 0;
    this.minutes = 0;
    this.seconds = 0;
  }


  public addTo(dt: number): number {
    return dt + this.getMillis();
  }

  public getMillis(): number {
    const factor: number = 1000 * this.sign;
    return factor * (604800 * this.weeks + 86400 * this.days + 3600 * this.hours + 60 * this.minutes + this.seconds);
  }
}
