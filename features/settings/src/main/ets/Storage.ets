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

import data_preferences from '@ohos.data.preferences';
import { CommonInnerEvent, EmitterCollector, GlobalThis, Log, maskString} from '@app/common';
import { ISettingItem, IsSettingData } from './groupConfig/declare';
import { SettingData } from './groupConfig/index';
import ArrayList from '@ohos.util.ArrayList';
import settingKeys from './settingKeys';

const TAG: string = 'SettingStorage';

/**
 * 处理各设置项的本地持久化数据
 *
 * @since 2022-06-25
 */

class SettingStore {
  public static readonly INSTANCE: SettingStore = new SettingStore();
  private storage: data_preferences.Preferences| null = null;

  //异步等待初始化的Resolve,初始化完毕后,通知唤醒
  private waitInitOverResolves: ArrayList<Function> = new ArrayList();

  private isInitializing = false;

  private hasInitSuccess = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  //移除设置sp缓存后，需要重新初始化
  async reInit() {
    this.hasInitSuccess = false;
    this.emitterCollector.off();
    try {
      await this.init();
    } catch (err) {
      Log.logErrorMsg(TAG, 'reInit', err);
    }
  }
  /**
   * 初始化设置项
   */
  async init(): Promise<undefined> {
    if (this.hasInitSuccess) {
      return;
    }
    if (this.isInitializing) {
      Log.info(TAG, 'init isInitializing please wait');
      return new Promise<undefined>((resolve) => {
        this.waitInitOverResolves.add(resolve);
      });
    }
    this.isInitializing = true;
    Log.info(TAG, `init start`);

    const context = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `init context is null`);
      this.initOver(false)
      return;
    }
    try {
      this.storage = await data_preferences.getPreferences(context, 'settings');
    } catch (error) {
      Log.logErrorMsg(TAG, 'init', error);
    }

    if (!this.storage) {
      Log.error(TAG, `init storage is null`);
      this.initOver(false);
      return;
    }

    const iSettingData: IsSettingData[] = await SettingData.getSettingData();
    iSettingData.forEach((group: IsSettingData) => {
      group.items.forEach((item: ISettingItem) => {
        // SHARE_SWITCH 的首选项key有脏数据,不能再用这个key
        if (item.settingKey && settingKeys.isShareSwitch !== item.settingKey) {
          try {
            item.defaultVal ?? Log.error(TAG, item.settingKey + ' must set default value');
            if (!this.storage?.hasSync(item.settingKey)) {
              this.storage?.putSync(item.settingKey, item.defaultVal);
              this.storage?.flush();
            }
            if (item.syncState) {
              const value = this.storage?.getSync(item.settingKey, item.defaultVal);
              item.syncState(value);
              Log.info(TAG, `syncState settingKey ${item.settingKey} ${maskString(value?.toString())}`);
            }
          } catch (err) {
            // 抛了异常
            Log.logErrorMsg(TAG, `${item.settingKey},preference error`, err);
          }
        }
      });
    });
    this.initOver(true);
    return;
  }

  async set(key: string, val: string | number) {
    if (!this.storage) {
      Log.error(TAG, `set storage is null`)
      await this.init();
    }
    if (!this.storage) {
      Log.error(TAG, `set after init storage is still null`)
      return;
    }
    try {
      this.storage.putSync(key, val);
      await this.storage.flush();
      Log.info(TAG, `set key:${key} ${maskString(val?.toString())}`);
    } catch (error) {
      Log.logErrorMsg(TAG, `set key ${key}`, error);
    }
  }

  async get(key: string, defaultVal?: string | number): Promise<data_preferences.ValueType> {
    if (!this.storage) {
      Log.error(TAG, `get storage is null`)
      await this.init();
    }
    if (!this.storage) {
      Log.error(TAG, `get after init storage is still null`)
      return '';
    }
    return this.storage.getSync(key, defaultVal ?? '');
  }

  private initOver(initResult: boolean) {
    this.isInitializing = false;
    this.hasInitSuccess = initResult;
    this.notifyAll();
  }

  /**
   * 通知等待初始化結果的的异步callBack
   */
  private notifyAll() {
    Log.info(TAG, `notifyAll waitInitOverResolve count is ${this.waitInitOverResolves.length}`);
    for (let i = 0; i < this.waitInitOverResolves.length; i++) {
      const func: Function = this.waitInitOverResolves[i];
      func();
    }
    this.waitInitOverResolves.clear();
  }
}
;

export { SettingStore };
