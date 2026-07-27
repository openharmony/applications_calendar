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

/**
 * 匿名化函数  字符串匿名处理
 *
 * @param str 需要匿名化的字符串
 * @returns 字符串长度小于等于3 展示首尾字符; 字符串长度在4-8 展示首3个字符,尾2个字符; 字符串大于8,展示首3个字符,尾3个字符
 */
export function maskString(str: string): string {
  if (!str || str.length === 0) {
    return str;
  }
  if (str.length <= 3) {
    return str.substring(0, 1) + '***' + str.substring(str.length - 1);
  } else if (str.length < 9) {
    return str.substring(0, 3) + '***' + str.substring(str.length - 2);
  } else {
    return str.substring(0, 3) + '***' + str.substring(str.length - 3);
  }
}