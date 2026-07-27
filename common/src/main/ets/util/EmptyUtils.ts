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

import { Log } from '../default/common/Log';
import { TypeUtils } from './TypeUtils';

interface Collection {
  length?: number,
  size?: number
}

type BasicType = number | string | boolean;

const TAG = 'EmptyUtils';

export class EmptyUtils {
  /**
   * 检查给定的字符串是否为空
   *
   * @param stringContent 需要检查的字符串，可以是string，null或undefined
   * @param strongCheck 是否进行强校验，默认为false，如果设置为true，除了null和undefined，空字符串也会被认为是空
   * @return 如果字符串为空，返回true，否则返回false
   */
  static isEmptyString(stringContent: string | null | undefined, strongCheck?: boolean): boolean {
    if (!stringContent) {
      return true;
    }
    if (strongCheck) {
      return stringContent.trim().length <= 0;
    } else {
      return stringContent.length <= 0;
    }
  }

  /**
   * 检查给定的字符串是否为空或纯粹的空字符串或非字符串
   *
   * @param stringContent 需要检查的字符串，可以是string，null或undefined
   * @param strongCheck 是否进行强校验，默认为false，如果设置为true，除了null和undefined，空字符串也会被认为是空
   * @return 如果字符串为空，返回true，否则返回false
   */
  static isNotOrEmptyString(stringContent: ESObject, strongCheck?: boolean): boolean {
    if (EmptyUtils.isUndefinedOrNull(stringContent)) {
      return true;
    }
    if (!TypeUtils.isString(stringContent)) {
      Log.warn(TAG, `isNotOrEmptyString type is not string`);
      return true;
    }
    return EmptyUtils.isEmptyString((stringContent as string), strongCheck);
  }

  /**
   * 检查给定的字符串是否是纯粹的非空字符串
   *
   * @param stringContent 需要检查的字符串，可以是string，null或undefined
   * @param strongCheck 是否进行强校验，默认为false，如果设置为true，除了null和undefined，空字符串也会被认为是空
   * @return 如果字符串为空，返回false，否则返回true
   */
  static isStringAndNotEmpty(stringContent: ESObject, strongCheck?: boolean): stringContent is string {
    if (EmptyUtils.isUndefinedOrNull(stringContent)) {
      return false;
    }
    if (!TypeUtils.isString(stringContent)) {
      Log.warn(TAG, `isStringAndNotEmpty type is not string`);
      return false;
    }
    return EmptyUtils.isNotEmptyString((stringContent as string), strongCheck);
  }

  /**
   * 检查给定的字符串是否为空,避免实际传numer类型，导致!0 = true
   *
   * @param stringContent 需要检查的字符串，可以是string，null或undefined
   * @param strongCheck 是否进行强校验，默认为false，如果设置为true，除了null和undefined，空字符串也会被认为是空
   * @return 如果字符串为空，返回true，否则返回false
   */
  static isEmptyStringCheckType(stringContent: string | null | undefined, strongCheck?: boolean): boolean {
    if (EmptyUtils.isUndefinedOrNull(stringContent)) {
      return true;
    }
    if (typeof stringContent !== 'string') {
      Log.warn(TAG, `isEmptyString stringContent is ${stringContent} not string`);
      return false;
    }
    if (strongCheck) {
      return stringContent.trim().length <= 0;
    } else {
      return stringContent.length <= 0;
    }
  }

  static isNotEmptyString(stringContent: string | null | undefined, strongCheck?: boolean): boolean {
    return !EmptyUtils.isEmptyString(stringContent, strongCheck);
  }

  static isEmptyArray(array: Collection | undefined): boolean {
    if (!array) {
      return true;
    }
    return (array.length !== undefined && array.length <= 0) || array.size !== undefined && array.size <= 0;
  }

  static isNotEmptyArray(array: Collection | undefined): array is Object {
    return !EmptyUtils.isEmptyArray(array);
  }

  static isUndefinedOrNull(obj: ESObject): obj is null | undefined {
    return obj === null || obj === undefined;
  }
}

