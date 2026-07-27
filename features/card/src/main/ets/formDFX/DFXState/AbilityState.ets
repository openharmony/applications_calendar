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
import { DFXContext } from '../DFXContext';
import { DFXState } from './DFXState';

/**
 * 卡片处于Ability的运行时的状态
 */
export default class AbilityState implements DFXState {

  private static _instance :AbilityState = new AbilityState();

  /**
   * 获取唯一实例
   * @returns 唯一实例
   */
  public static getInstance():AbilityState {
    return AbilityState._instance;
  }

  public static AbilityState(): AbilityState {
    if (!AbilityState._instance) {
      AbilityState._instance = new AbilityState();
    }
    return AbilityState._instance;
  }

  handleError(context:DFXContext) {

  }

  handleAction(context: DFXContext): void {
    throw new Error('Method not implemented.');
  }

  handleDataRefresh(context: DFXContext): void {
    throw new Error('Method not implemented.');
  }

  handleNormalEvent(context: DFXContext): void {
    throw new Error('Method not implemented.');
  }
}