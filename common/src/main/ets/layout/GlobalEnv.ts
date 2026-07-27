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

import { HashMap } from '@kit.ArkTS';
import emitter from '@ohos.events.emitter';

// 全局环境变量枚举定义
export const enum GlobalEnvEnum {
  WINDOW_SIZE = 'window_size',
  DARK_MODE = 'dark_mode',
}

export class Env {
  public name: string;
  public data: HashMap<string, string | number> = new HashMap();

  constructor(name: string) {
    this.name = name;
  }
}

// 全局环境变量管理
export class GlobalEnv {
  static ENV_ENUM_KEY = 'envName';
  static ENV_VALUE_KEY = 'newValue';
  private static prop: HashMap<GlobalEnvEnum, Object> = new HashMap<GlobalEnvEnum, Object>();

  static reset(): void {
    GlobalEnv.prop.clear();
  }

  static setOrCreate<T>(env: GlobalEnvEnum, newValue: T): void {
    const curValue = GlobalEnv.get<T>(env);
    if (curValue !== newValue) {
      // notify change
      GlobalEnv.prop.set(env, newValue);
      emitter.emit(env, { data: { ENV_ENUM_KEY: env, ENV_VALUE_KEY: newValue } });
    }
  }

  static delete(env: GlobalEnvEnum): boolean {
    GlobalEnv.prop.remove(env);
    return true;
  }

  static has(env: GlobalEnvEnum): boolean {
    return GlobalEnv.prop.hasKey(env);
  }

  static get<T>(env: GlobalEnvEnum): T {
    return GlobalEnv.prop.get(env) as T;
  }

  /**
   * 从事件数据中获取指定类型的数据
   * @param env 全局环境枚举，用于指定获取数据的环境
   * @param data 事件数据，包含了各种类型的数据
   * @return 返回指定类型的数据，如果没有找到则返回undefined
   */
  static getFromEventData<T>(env: GlobalEnvEnum, data: emitter.EventData): T | undefined {
    if (!data.data) {
      return undefined;
    }
    const envName = data.data.ENV_ENUM_KEY as string;
    if (envName !== env) {
      return undefined;
    }
    return data.data.ENV_VALUE_KEY as T;
  }
}