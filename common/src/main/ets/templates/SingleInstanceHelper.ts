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
import { GlobalThis } from '../data/GlobalThis';

const TAG = 'Singleton';

/**
 * 单例对象工具类，用于使用Ability单例对象
 */
export class SingleInstanceHelper {
  // 通过globalThis存取值
  // 第三个参数是构造方法中的参数，可以有多个，如果不传，即是无参构造方法
  public static createOrGet<T>(objectClass: { new(...input): T }, storageKey: string, ...input: Array<string>): T {
    if (!GlobalThis.getInstance().objectMap.get(storageKey)) {
      GlobalThis.getInstance().objectMap.set(storageKey, new objectClass(...input) as Object);
      Log.info(TAG, ` Create key of ${storageKey}`);
    }
    // 通过globalThis存取值
    return GlobalThis.getInstance().objectMap.get(storageKey) as T;
  }
}