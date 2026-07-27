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
 * 提取字符串中所有HTTPS链接
 */
export function getHttpsLinks(text: string): Set<string> {
  const regex = /https?:\/\/[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]/gi;
  const matches = text.match(regex) || [];
  return new Set(matches);
}

/**
 * 判断两个字符串是否包含相同的HTTPS链接集合
 */
export function hasSameHttpsLinks(str1: string, str2: string): boolean {
  const links1 = getHttpsLinks(str1);
  const links2 = getHttpsLinks(str2);

  // 比较集合大小和内容
  if (links1.size !== links2.size) {
    return false;
  }
  for (const link of links1) {
    if (!links2.has(link)) {
      return false;
    }
  }
  return true;
}