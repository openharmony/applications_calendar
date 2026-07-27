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

import util from '@ohos.util';
import { EmptyUtils } from './EmptyUtils';
import { Result } from './../templates/Result';
import { Log } from '../default/common/Log';

const EMPTY_STRING = '';

const TAG = 'StringUtil';

/**
 * 字符串工具类
 */
export class StringUtils {
  /**
   * 字符串转字节数组
   * @param str 字符串
   */
  public static stringToUint8Array(str: string): Result<Uint8Array> {
    if (EmptyUtils.isUndefinedOrNull(str)) {
      return Result.buildSuccessResult(new Uint8Array());
    }
    if (str === EMPTY_STRING) {
      return Result.buildSuccessResult(new Uint8Array());
    }
    try {
      const textEncoder: util.TextEncoder = new util.TextEncoder();
      return Result.buildSuccessResult(textEncoder.encodeInto(str));
    } catch (error) {
      Log.logErrorMsg(TAG, 'stringToUint8Array', error);
      return Result.buildByErrorWithData(error, new Uint8Array());
    }
  }

  /**
   * 字节数组转字符串
   * @param bytes 字节数组
   */
  public static uint8ArrayToString(bytes: Uint8Array, emptyString: string = EMPTY_STRING): Result<string> {
    if (!bytes || bytes.length === 0) {
      return Result.buildSuccessResult(emptyString);
    }
    try {
      const textEncoder: util.TextDecoder = new util.TextDecoder();
      return Result.buildSuccessResult(textEncoder.decodeWithStream(bytes));
    } catch (error) {
      Log.logErrorMsg(TAG, 'uint8ArrayToString', error);
      return Result.buildByErrorWithData(error, emptyString);
    }
  }

  /**
   * 判断字符串是否只包含数字
   */
  public static containsOnlyDigits(str: string): boolean {
    return /^\d+$/.test(str);
  }
}
