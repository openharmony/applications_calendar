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

import { EmptyUtils } from './EmptyUtils';
import { equalsIgnoreCase } from './CommonUtils';

export const US_ASCII: string = 'US-ASCII';

export const ISO_8859_1: string = 'ISO-8859-1';

export const UTF_8: string = 'UTF-8';

export const UTF_16BE: string = 'UTF-16BE';

export const UTF_16LE: string = 'UTF-16LE';

export const UTF_16: string = 'UTF-16';

export const GBK: string = 'GBK';

//日本的编码
export const SHIFT_JIS: string = 'SHIFT_JIS';


/**
 * todo 待实现
 * operator soft-bank
 *  见双框架
 *  Utils.isExistClass(CalendarCommonUtils.SYSTEMPROPERTIES_CLASS)
 *  ? SOFTBANK_OPTA.equals(SystemPropertiesEx.get("ro.config.hw_opta"))
 *  && SOFTBANK_OPTB.equals(SystemPropertiesEx.get("ro.config.hw_optb")): false;
 * @returns
 */
export function isOperatorSoftbank(): boolean {
  return false;
}

/**
 * todo 待实现
 * 将输入的字符串从原始编码转化为目标编码的字符串
 *
 * @param originalString 需要被转化的字符串
 * @param sourceCharset 原始编码
 * @param targetCharset 目标编码
 * @return 转化后的字符串
 */
export function convertStringCharset(originalString: string, sourceCharset: string, targetCharset: string): string {
  if (EmptyUtils.isEmptyString(originalString)) {
    return '';
  }
  if (EmptyUtils.isEmptyString(sourceCharset) || EmptyUtils.isEmptyString(targetCharset)) {
    return originalString;
  }
  if (equalsIgnoreCase(sourceCharset, targetCharset)) {
    return originalString;
  }

  return originalString;
}

/**
 * todo 待实现
 * @param inputString
 * @param charSet
 * @returns
 */
export function canEncodeInThisCharset(inputString: string, charSet: string): boolean {
  return false;
}