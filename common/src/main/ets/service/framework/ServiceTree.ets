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

import { Service } from './Service';

export class ServiceNode {
  private _value: Service;
  public get value() : Service {
    return this._value;
  }

  public set value(value: Service) {
    this._value = value;
  }

  public children: ServiceNode[] = [];

  constructor(service: Service) {
    this._value = service;
  }

  addChild(service: Service) {
    this.children.push(new ServiceNode(service));
  }
}

export class ServiceTree {
  private _rootNode: ServiceNode;

  constructor(rootService: Service) {
    this._rootNode = new ServiceNode(rootService);
  }

  public addNode(parentName: string, child: Service) {
    let parentNode = this.findService(parentName);
    if (!parentNode) {
      return;
    }
    parentNode.addChild(child);
  }

  public findService(serviceName: string) {
    let queue: ServiceNode[] = [this._rootNode];
    while (queue.length > 0) {
      let node = queue.shift();
      if (!node) {
        continue;
      }
      if (node.value.name === serviceName) {
        return node;
      }
      for (let child of node.children) {
        queue.push(child);
      }
    }
    return null;
  }
}