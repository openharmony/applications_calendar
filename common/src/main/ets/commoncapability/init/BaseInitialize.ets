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

import { InitializeInterceptor } from './InitializeInterceptor';
import { Initialize } from './Initialize';
import { Log } from '../../default/common/Log';

const TAG = 'BaseInitialize'

export abstract class BaseInitialize implements Initialize {
  /**
   * isHasInit
   */
  protected mIsHasInit: boolean = false;
  /**
   * isInitting
   */
  protected isInitializing: boolean = false;
  protected initializeInterceptor: InitializeInterceptor | null = null;

  initPriority(): number {
    return 0;
  }

  isHasInit(): boolean {
    return this.mIsHasInit;
  }

  getTag(): string {
    return TAG;
  }

  setInitializeInterceptor(initializeInterceptor: InitializeInterceptor | null) {
    this.initializeInterceptor = initializeInterceptor;
  }

  async isCanInit(): Promise<boolean> {
    if (this.initializeInterceptor) {
      const isCanInit: boolean = await this.initializeInterceptor.isCanInit()
      if (!isCanInit) {
        Log.info(this.getTag(), `isCanInit initializeInterceptor is can not init`)
        return false;
      }
    }
    if (this.mIsHasInit || this.isInitializing) {
      Log.info(this.getTag(), `isCanInit mIsHasInit is ${this.mIsHasInit} isInitializing is ${this.isInitializing} can not init`)
      return false;
    }
    return true;
  }

  async doInit(): Promise<boolean> {
    return true;
  };

  async init(): Promise<boolean> {
    this.beforeInit();
    const initResult: boolean = await this.doInit();
    this.afterInit(initResult);
    return initResult;
  }

  private beforeInit() {
    this.isInitializing = true;
  }

  private afterInit(initResult: boolean) {
    this.isInitializing = false;
    this.mIsHasInit = initResult;
  }
}