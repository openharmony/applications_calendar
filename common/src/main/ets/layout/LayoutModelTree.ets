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
import { Env } from './GlobalEnv';

export class LayoutRuleNode {
  public value: LayoutRule;
  public children: LayoutRuleNode[] = [];

  constructor(rule: LayoutRule) {
    this.value = rule;
  }

  addChild(rule: LayoutRule) {
    this.children.push(new LayoutRuleNode(rule));
  }
}

export class LayoutModelTree {
  // 规则列表
  public rootNode: LayoutRuleNode;

  constructor(rootLayoutRule: LayoutRule) {
    this.rootNode = new LayoutRuleNode(rootLayoutRule);
  }

  // 广度遍历树响应布局变化回调
  callback(data: Env) {
    if (!data || !data.data) {
      return;
    }
    const envName = data.name;
    const queue: LayoutRuleNode[] = [this.rootNode];
    while (queue.length > 0) {
      const currentNode = queue.shift()!;
      if (currentNode.value.needChange(envName)) {
        currentNode.value.onChange(data);
      }
      if (currentNode.children && currentNode.children.length > 0) {
        // 将子节点添加到队列中
        queue.push(...currentNode.children);
      }
    }
  }
}