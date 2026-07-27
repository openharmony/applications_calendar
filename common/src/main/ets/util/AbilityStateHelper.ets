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

import { LightWeightMap } from '@kit.ArkTS';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';
import { Log } from '../default/common/Log';
import { common } from '@kit.AbilityKit';


const TAG: string = `AbilityStateHelper`;

/*
 * AbilityStateHelper
 */
export class AbilityStateHelper {
  private readonly abilityForegroundCallBacks:
    LightWeightMap<common.UIAbilityContext, Callback<boolean>[]> = new LightWeightMap();
  private readonly abilityForegroundStates: LightWeightMap<common.UIAbilityContext, boolean> = new LightWeightMap();

  public static getInstance(): AbilityStateHelper {
    return SingleInstanceHelper.createOrGet(AbilityStateHelper, TAG);
  }

  clearAbility(abilityContext: common.UIAbilityContext): boolean {
    const result = this.abilityForegroundCallBacks.hasKey(abilityContext);
    this.abilityForegroundCallBacks.remove(abilityContext);
    this.abilityForegroundStates.remove(abilityContext);
    return result;
  }

  public updateAbilityForeground(abilityContext: common.UIAbilityContext, isAbilityForeground: boolean) {
    this.abilityForegroundStates.set(abilityContext, isAbilityForeground);
    const callBacks = this.abilityForegroundCallBacks.get(abilityContext);
    if (!callBacks) {
      return;
    }
    for (let callBack of callBacks) {
      callBack(isAbilityForeground);
    }
  }

  public isAbilityForeground(abilityContext: common.UIAbilityContext | null): boolean {
    if (!abilityContext) {
      return false;
    }
    if (!this.abilityForegroundStates.hasKey(abilityContext)) {
      return false;
    }
    return this.abilityForegroundStates.get(abilityContext);
  }

  public addAbilityForegroundCall(abilityContext: common.UIAbilityContext, call: Callback<boolean>): boolean {
    let callBacks = this.abilityForegroundCallBacks.get(abilityContext);
    if (callBacks?.includes(call)) {
      return false;
    }
    if (!callBacks) {
      callBacks = [];
      this.abilityForegroundCallBacks.set(abilityContext, callBacks);
    }
    callBacks.push(call);
    call(this.isAbilityForeground(abilityContext));
    return true;
  }

  public removeAbilityForegroundCall(abilityContext: common.UIAbilityContext, call: Callback<boolean>): boolean {
    let callBacks = this.abilityForegroundCallBacks.get(abilityContext);
    if (!callBacks) {
      Log.warn(TAG, `removeAbilityForegroundCall callBacks of abilityContext`);
      return false;
    }
    const index = callBacks.indexOf(call);
    if (index < 0 || index >= callBacks.length) {
      return false;
    }
    callBacks.splice(index, 1);
    return true;
  }
}