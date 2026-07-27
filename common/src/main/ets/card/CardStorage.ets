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

import HashMap from '@ohos.util.HashMap';
import preferences from '@ohos.data.preferences';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import { ReportHiEventParams, ReportUtil } from '../default/util/ReportUtil';
import { faultEvents } from '../default/common/HiEvents';

const storageMap: HashMap<string, CardStorage> = new HashMap<string, CardStorage>();

const TAG: string = 'CardStorage';

/**
 * 卡片SP缓存数据管理
 */
class CardStorage {
  // sp文件名
  private name: string = '';

  private sp: preferences.Preferences | undefined = undefined;

  constructor(fileName: string) {
    const context: Context | null = GlobalThis.getInstance().abilityStageContext;
    this.name = fileName;
    this.init(context);
  }

  init(context: Context | null) {
    if (context === null) {
      Log.error(TAG, 'Context is Null in CardStorage');
      return;
    }
    try {
      this.sp = preferences.getPreferencesSync(context, { name: this.name });
      if (!this.sp) {
        Log.error(TAG, `init sp is null`);
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'init error', error);
    }
  }

  set<T>(key: string, value: T) {
    if (!this.sp) {
      Log.error(TAG, `set key: ${key} sp is null`);
      return;
    }
    const json: string = JSON.stringify(value);
    Log.info(TAG, `set ${key}`);
    try {
      this.sp.putSync(key, json);
      this.sp.flushSync();
    } catch (err) {
      let params: ReportHiEventParams = {
        FORM_ID: key,
        CUR_TIME: Date.now()
      };
      ReportUtil.reportFaultEvent(faultEvents.setCardInfoToSpFail, params);
      Log.error(TAG, `set ${key} to ${this.name} failed: ${err?.message}`);
    }
  }

  get<T>(key: string): T | undefined {
    if (!this.sp) {
      Log.error(TAG, `get key: ${key} sp is null`);
      return undefined;
    }
    this.sp.flushSync();
    const json: string = this.sp.getSync(key, '') as string;
    if (!json) {
      Log.error(TAG, `get: json is null`);
      return undefined;
    }
    try {
      const data = JSON.parse(json) as T;
      return data;
    } catch (err) {
      Log.logErrorMsg(TAG, `get ${key} from ${this.name} failed`, err);
    }
    return undefined;
  }

  delete(key: string): void {
    if (!this.sp) {
      Log.error(TAG, `delete key: ${key} sp is null`);
      return;
    }
    Log.info(TAG, `delete ${key}`);
    const hasKey: boolean | undefined = this.sp.hasSync(key);
    if (!hasKey) {
      Log.error(TAG, `not hasKey`);
      return;
    }
    try {
      this.sp.deleteSync(key);
      this.sp.flushSync();
    } catch (err) {
      Log.logErrorMsg(TAG, `delete ${key} from ${this.name} failed`, err);
    }
  }

  getAllSync(): string | undefined {
    if (!this.sp) {
      Log.error(TAG, `getAllSync sp is null`);
      return undefined;
    }
    try {
      this.sp.flushSync();
      const json: string = this.sp.getAllSync() as string;
      if (!json) {
        return undefined;
      }
      return json;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getAllSync failed', err);
    }
    return undefined;
  }
}

function getStorage(name: string): CardStorage {
  if (storageMap.hasKey(name)) {
    return storageMap.get(name);
  }
  let storage = new CardStorage(name);
  storageMap.set(name, storage);
  return storage;
}

function getLatestStorage(name: string): CardStorage {
  let storage = new CardStorage(name);
  Log.info(TAG, `getLatestStorage: name is ${name}`);
  storageMap.set(name, storage);
  return storage;
}

export {
  CardStorage, getStorage, getLatestStorage
}