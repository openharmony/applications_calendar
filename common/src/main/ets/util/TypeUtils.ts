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


const TYPE_STRING = 'string';
const TYPE_NUMBER = 'number';
const TYPE_BOOLEAN = 'boolean';
const TYPE_FUNCTION = 'function';
const TYPE_OBJECT = 'object';
const TAG = 'TypeUtils';

export class TypeUtils {
  static isString(obj: ESObject): obj is string {
    const type = typeof obj;
    return type === TYPE_STRING;
  }

  static isNumber(obj: ESObject): obj is number {
    const type = typeof obj;
    return type === TYPE_NUMBER;
  }

  static isBoolean(obj: ESObject): obj is boolean {
    const type = typeof obj;
    return type === TYPE_BOOLEAN;
  }

  static isFunction(obj: ESObject): obj is Function {
    const type = typeof obj;
    return type === TYPE_FUNCTION;
  }

  static isObject(obj: ESObject): obj is Object {
    const type = typeof obj;
    return type === TYPE_OBJECT;
  }

  static isNoNullObject(obj: ESObject): obj is Exclude<Object, undefined | null> {
    const type = typeof obj;
    return type === TYPE_OBJECT && obj !== null;
  }

  static isDateObject(obj: ESObject): obj is Date {
    if (!TypeUtils.isNoNullObject(obj)) {
      return false;
    }
    return obj instanceof Date;
  }

  static isArray(obj: ESObject): obj is Array<ESObject> {
    if (Array.isArray) {
      return Array.isArray(obj);
    }
    // fallback for older browsers like  IE 8
    return Object.prototype.toString.call(obj) === '[object Array]';
  }
}