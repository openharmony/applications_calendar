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

import { EmptyUtils, MILLS_PER_DAY, MILLS_PER_HOUR, MILLS_PER_MINUTE, MILLS_PER_SECOND, MILLS_PER_WEEK } from '@app/common';

const UNICODE_ZERO: number = '0'.charCodeAt(0);
const UNICODE_NINE: number = '9'.charCodeAt(0);
const UNICODE_POSITIVE: number = '+'.charCodeAt(0);
const UNICODE_NEGATIVE: number = '-'.charCodeAt(0);
const UNICODE_P: number = 'P'.charCodeAt(0);
const UNICODE_T: number = 'T'.charCodeAt(0);
const UNICODE_W: number = 'W'.charCodeAt(0);
const UNICODE_D: number = 'D'.charCodeAt(0);
const UNICODE_H: number = 'H'.charCodeAt(0);
const UNICODE_M: number = 'M'.charCodeAt(0);
const UNICODE_S: number = 'S'.charCodeAt(0);

/**
 * 循环日程的持续时长字段解析
 */
export class Duration {
  sign: number = 1;
  weeks: number = 0;
  days: number = 0;
  hours: number = 0;
  minutes: number = 0;
  seconds: number = 0;

  public static parse(durationStr: string): Duration {
    const duration: Duration = new Duration();
    duration.parse(durationStr);
    return duration;
  }

  public static defaultDuration(): number {
    return MILLS_PER_HOUR;
  }

  public getMills() {
    return this.sign * this.getMillsUnSigned();
  }

  public parse(durationStr: string) {
    this.reset();
    if (EmptyUtils.isEmptyString(durationStr)) {
      return;
    }
    const isParseSuccess: boolean = this.parseDuration(durationStr);
    if (!isParseSuccess) {
      this.reset();
    }
  }

  public isValid(): boolean {
    return this.getMillsUnSigned() > 0;
  }

  private getMillsUnSigned(): number {
    return MILLS_PER_WEEK * this.weeks + MILLS_PER_DAY * this.days + MILLS_PER_HOUR * this.hours +
      MILLS_PER_MINUTE * this.minutes + MILLS_PER_SECOND * this.seconds;
  }

  private reset() {
    this.sign = 1;
    this.weeks = 0;
    this.days = 0;
    this.hours = 0;
    this.minutes = 0;
    this.seconds = 0;
  }

  private parseDuration(str: string): boolean {
    let index: number = 0;

    // 判断第一个字符是否为正负号
    let charCode: number = str.charCodeAt(0);
    if (charCode === UNICODE_NEGATIVE) {
      this.sign = -1;
      index++;
    } else if (charCode === UNICODE_POSITIVE) {
      index++;
    }

    // 首字母必须以P开头
    if (index >= str.length) {
      return false;
    }
    charCode = str.charCodeAt(index);
    if (charCode !== UNICODE_P) {
      return false;
    }
    index++;

    if (index >= str.length) {
      return false;
    }
    charCode = str.charCodeAt(index);

    // P后面有T和无T均可
    if (charCode === UNICODE_T) {
      index++;
    }

    // 解析*W *D *H *M *S 等数据样式，转换成duration周、日、时、分、秒对应的值
    return this.parseDurationData(str, index);
  }

  private parseDurationData(str: string, index: number): boolean {
    let charCode: number;
    let num: number = 0;
    for (; index < str.length; index++) {
      charCode = str.charCodeAt(index);

      if (charCode >= UNICODE_ZERO && charCode <= UNICODE_NINE) {
        // 将数字字符串解析成解析数字
        num *= 10;
        num += charCode - UNICODE_ZERO;
      } else if (charCode === UNICODE_W) {
        // 数组后跟的是W，则将数字赋值为weeks字段，并将数字重置
        this.weeks = num;
        num = 0;
      } else if (charCode === UNICODE_D) {
        // 数组后跟的是D，则将数字赋值为days字段，并将数字重置
        this.days = num;
        num = 0;
      } else if (charCode === UNICODE_H) {
        // 数组后跟的是H，则将数字赋值为hours字段，并将数字重置
        this.hours = num;
        num = 0;
      } else if (charCode === UNICODE_M) {
        // 数组后跟的是M，则将数字赋值为minutes字段，并将数字重置
        this.minutes = num;
        num = 0;
      } else if (charCode === UNICODE_S) {
        // 数组后跟的是S，则将数字赋值为seconds字段，并将数字重置
        this.seconds = num;
        num = 0;
      } else if (charCode !== UNICODE_T) {
        // duration中的字符，只能是P、T、W、D、H、M、S、0-9中的字符，以外的字符，则认为是格式错误
        return false;
      }
    }
    return true;
  }
}