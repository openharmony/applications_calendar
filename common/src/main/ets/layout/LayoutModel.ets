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

import { LayoutRule } from './LayoutRule';
import { emitter } from '@kit.BasicServicesKit';
import { Callback } from '@ohos.base';
import { Env } from './GlobalEnv';

export class LayoutModel {
  // 规则列表
  protected _ruleMap: LayoutRule[];
  private allEnvWatchList: Map<string, string[]>;
  private callbackMap: Map<string, Callback<Env>>;

  constructor() {
    this.callbackMap = new Map<string, Callback<Env>>();
    this._ruleMap = [];
    this.allEnvWatchList = new Map<string, string[]>();
  }

  unInit(): void {
    this.allEnvWatchList.forEach((values, key) => {
      this.unSubscribeEnvChange(key);
    })
    this.clearRule();
  }

  callback(data: Env) {
    if (!data || !data.data) {
      return;
    }
    let rules = this.allEnvWatchList.get(data.name);
    if (!rules) {
      return;
    }
    rules.forEach(name => {
      let rule = this.getRule(name);
      if (rule) {
        rule.onChange(data);
      }
    })
  }

  /**
   * 根据规则名称获取对应的规则
   *
   * @param ruleName 规则名称
   * @returns 对应的规则
   */
  public getRule(ruleName: string): LayoutRule | undefined {
    return this._ruleMap.find(rule => rule.name === ruleName);
  }

  /**
   * 添加规则
   *
   * @param rule 规则
   */
  public addRule(rule: LayoutRule): boolean {
    if (this.getRule(rule.name)) {
      return false;
    }
    this._ruleMap.push(rule);
    this.updateWatchList(rule);
    return true;
  }

  /**
   * 获取所有规则
   *
   * @returns 所有规则
   */
  public getAllRule(): LayoutRule[] {
    return this._ruleMap;
  }

  /**
   * 删除规则
   *
   * @param ruleName 规则名称
   */
  public removeRule(ruleName: string): boolean {
    const index = this._ruleMap.findIndex(item => item.name === ruleName);
    if (index < 0) {
      return false;
    }
    this._ruleMap.splice(index, 1);
    return true;
  }

  /**
   * 清空规则
   */
  public clearRule(): void {
    this._ruleMap = [];
  }

  protected updateWatchList(rule: LayoutRule) {
    rule.watchEnvList.forEach(env => {
      let ruleList = this.allEnvWatchList.get(env);
      if (!ruleList) {
        this.allEnvWatchList.set(env, [rule.name]);
        this.callbackMap.set(env, this.callback);
        this.envChangeHandler = (data: Env) => this.callback(data);
      } else {
        ruleList.push(rule.name);
      }
    })
  }

  protected unSubscribeEnvChange(env: string) {
    let callback = this.callbackMap.get(env);
    if (callback) {
      emitter.off(env, callback as Callback<emitter.EventData>);
      this.callbackMap.delete(env);
    }
  }

  private envChangeHandler: Callback<Env> = () => {
  };
}