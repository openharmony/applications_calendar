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

import { describe, expect, it } from '@ohos/hypium';
import { Env, LayoutModelTree, LayoutRule } from '@app/common';

class MockLayoutRule extends LayoutRule {
  public onChangeCalled: boolean = false;

  constructor(name: string, watchEnvList: string[]) {
    super(name, watchEnvList);
  }

  onChange(): boolean {
    this.onChangeCalled = true;
    return true;
  }
}

export default function LayoutTreeModelTest() {
  describe('LayoutTreeModelTest', () => {
    it('constructor', 0, () => {
      let rootLayoutRule = new MockLayoutRule('root', ['testEnv'])
      let layoutModel = new LayoutModelTree(rootLayoutRule);
      layoutModel.callback(new Env('testEnv'));
      expect(rootLayoutRule.onChangeCalled).assertTrue();
    });

    it('callback_with_child', 0, () => {
      let rootLayoutRule = new MockLayoutRule('root', ['testEnv'])
      let layoutModel = new LayoutModelTree(rootLayoutRule);
      let rootNode = layoutModel.rootNode;
      let childrenRule1 = new MockLayoutRule('childrenRule1', ['testEnv']);
      let childrenRule2 = new MockLayoutRule('childrenRule2', ['testEnv'])
      rootNode.addChild(childrenRule1);
      rootNode.addChild(childrenRule2);
      layoutModel.callback(new Env('testEnv'));
      expect(rootLayoutRule.onChangeCalled).assertTrue();
      expect(childrenRule1.onChangeCalled).assertTrue();
      expect(childrenRule2.onChangeCalled).assertTrue();
    });

    it('callback_child_not_need_change', 0, () => {
      let rootLayoutRule = new MockLayoutRule('root', ['testEnv'])
      let layoutModel = new LayoutModelTree(rootLayoutRule);
      let rootNode = layoutModel.rootNode;
      let childrenRule1 = new MockLayoutRule('childrenRule1', ['testEnv1']);
      let childrenRule2 = new MockLayoutRule('childrenRule2', ['testEnv'])
      rootNode.addChild(childrenRule1);
      rootNode.addChild(childrenRule2);
      layoutModel.callback(new Env('testEnv'));
      expect(rootLayoutRule.onChangeCalled).assertTrue();
      expect(childrenRule1.onChangeCalled).assertFalse();
      expect(childrenRule2.onChangeCalled).assertTrue();
    });

    it('callback_with_multi_level', 0, () => {
      let rootLayoutRule = new MockLayoutRule('root', ['testEnv'])
      let layoutModel = new LayoutModelTree(rootLayoutRule);
      let rootNode = layoutModel.rootNode;
      let childrenRule1 = new MockLayoutRule('childrenRule1', ['testEnv']);
      let childrenRule2 = new MockLayoutRule('childrenRule2', ['testEnv'])
      rootNode.addChild(childrenRule1);
      rootNode.children[0].addChild(childrenRule2);
      layoutModel.callback(new Env('testEnv'));
      expect(rootLayoutRule.onChangeCalled).assertTrue();
      expect(childrenRule1.onChangeCalled).assertTrue();
      expect(childrenRule2.onChangeCalled).assertTrue();
    });

    // 保证布局逐层响应
    it('callback_level_by_level', 0, () => {
      let flag = 0;

      class TestLayoutRule1 extends LayoutRule {
        constructor(name: string, watchEnvList: string[]) {
          super(name, watchEnvList);
        }

        onChange(): boolean {
          if (flag === 0) {
            flag = 1;
          }
          return true;
        }
      }

      class TestLayoutRule2 extends LayoutRule {
        constructor(name: string, watchEnvList: string[]) {
          super(name, watchEnvList);
        }

        onChange(): boolean {
          if (flag === 1) {
            flag = 2;
          } else {
            flag = 3;
          }
          return true;
        }
      }

      let rootLayoutRule = new MockLayoutRule('root', ['testEnv'])
      let layoutModel = new LayoutModelTree(rootLayoutRule);
      let rootNode = layoutModel.rootNode;
      let childrenRule1 = new TestLayoutRule1('childrenRule1', ['testEnv']);
      let childrenRule2 = new TestLayoutRule2('childrenRule2', ['testEnv'])
      rootNode.addChild(childrenRule1);
      rootNode.children[0].addChild(childrenRule2);
      layoutModel.callback(new Env('testEnv'));
      expect(rootLayoutRule.onChangeCalled).assertTrue();
      expect(flag).assertEqual(2);
    });
  })
}

