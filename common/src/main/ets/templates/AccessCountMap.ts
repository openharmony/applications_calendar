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
 * 一个带有访问计数的Map类，当Map的大小超过设定的最大值时，会删除访问次数最少的条目
 * @template K Map的键类型
 * @template V Map的值类型
 */
export class AccessCountMap<K, V> {
  private map: Map<K, {
    value: V;
    count: number
  }> = new Map();
  private maxSize: number;

  constructor(maxSize: number) {
    this.maxSize = maxSize;
  }

  set(key: K, value: V): void {
    if (this.map.size >= this.maxSize) {
      // Find the entry with the lowest access count
      let minCount = Infinity;
      let minKey: K | undefined;
      for (const [k, entry] of this.map.entries()) {
        if (entry.count < minCount) {
          minCount = entry.count;
          minKey = k;
        }
      }

      // Delete the entry with the lowest access count
      if (minKey !== undefined) {
        this.map.delete(minKey);
      }
    }

    // Add or update the entry
    const existingEntry = this.map.get(key);
    if (existingEntry) {
      existingEntry.value = value;
      existingEntry.count++;
    } else {
      this.map.set(key, { value, count: 1 });
    }
  }

  get(key: K): V | undefined {
    const entry = this.map.get(key);
    if (entry) {
      entry.count++;
      return entry.value;
    }
    return undefined;
  }

  has(key: K): boolean {
    return this.map.has(key);
  }
}
