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

import ArrayList from '@ohos.util.ArrayList';
import { Log } from '../../default/common/Log';
import { Initialize } from './Initialize';

const TAG = 'InitializeHelper'

export class InitializeHelper {
  private static sInstance: InitializeHelper | null = null;
  private mInitializes: ArrayList<Initialize> = new ArrayList

  public static getInstance(): InitializeHelper {
    if (!InitializeHelper.sInstance) {
      InitializeHelper.sInstance = new InitializeHelper();
    }
    return InitializeHelper.sInstance;
  }

  async initModules() {
    for (let i = 0; i < this.mInitializes.length; i++) {
      const initialize: Initialize = this.mInitializes[i];
      if (await initialize.isCanInit()) {
        const initResult: boolean = await initialize.init();
        Log.info(TAG, `init ${initialize.getTag()} initResult is ${initResult}`);
      } else {
        Log.warn(TAG, `unable init ${initialize.getTag()}`);
      }
    }
  }

  getMInitializes(): ArrayList<Initialize> {
    return this.mInitializes;
  }

  addInitialize(initialize: Initialize): boolean {
    if (!initialize) {
      Log.error(TAG, 'addInitialize initialize is null');
      return false;
    }
    if (this.mInitializes.has(initialize)) {
      Log.warn(TAG, `addInitialize ${initialize.getTag()} has added`);
      return false;
    }
    this.mInitializes.add(initialize);
    return true;
  }

  removeInitialize(initialize: Initialize): boolean {
    if (!initialize) {
      Log.error(TAG, 'removeInitialize initialize is null');
      return false;
    }
    this.mInitializes.remove(initialize);
    return true;
  }
}