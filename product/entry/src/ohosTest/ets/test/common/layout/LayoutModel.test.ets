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
import { GlobalEnvEnum, LayoutModel, LayoutRule } from '@app/common';

class LayoutModelMock extends LayoutModel {
  constructor() {
    super()
  }
}

class MockLayoutRule extends LayoutRule {
  public onChangeCalled: boolean = false;

  constructor(name: string, watchEnvList: GlobalEnvEnum[]) {
    super(name, watchEnvList);
  }

  onChange(): boolean {
    this.onChangeCalled = true;
    return true;
  }
}

export default function LayoutModelTest() {
  describe('LayoutModelTest', () => {
    it('addRule_no_repeat', 0, () => {
      let layoutModel = new LayoutModelMock();
      expect(layoutModel.addRule(new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]))).assertTrue();
    });

    it('addRule_duplicate', 0, () => {
      let layoutModel = new LayoutModelMock();
      const rule = new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]);
      expect(layoutModel.addRule(rule)).assertTrue();
      expect(layoutModel.addRule(rule)).assertFalse();
    });

    it('removeRule_exist', 0, () => {
      let layoutModel = new LayoutModelMock();
      const rule = new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]);
      expect(layoutModel.addRule(rule)).assertTrue();
      expect(layoutModel.removeRule(rule.name)).assertEqual(true);
    });

    it('removeRule_no_exist', 0, () => {
      let layoutModel = new LayoutModelMock();
      const rule = new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]);
      layoutModel.addRule(rule);
      expect(layoutModel.removeRule(rule.name)).assertTrue();
      expect(layoutModel.removeRule(rule.name)).assertFalse();
    });

    it('getRule_exist', 0, () => {
      let layoutModel = new LayoutModelMock();
      layoutModel.addRule(new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]));
      const res = layoutModel.getRule('test');
      expect(res).not().assertUndefined();
    });
    it('getRule_no_exist', 0, () => {
      let layoutModel = new LayoutModelMock();
      layoutModel.addRule(new MockLayoutRule('test', [GlobalEnvEnum.DARK_MODE]));
      layoutModel.removeRule('test');
      const res = layoutModel.getRule('test');
      expect(res).assertUndefined();
    });
    it('getAllRule', 0, () => {
      let layoutModel = new LayoutModelMock();
      let rule1 = new MockLayoutRule('rule1', []);
      let rule2 = new MockLayoutRule('rule2', []);
      layoutModel.addRule(rule1);
      layoutModel.addRule(rule2);
      let rules = layoutModel.getAllRule();
      expect(rules.length).assertEqual(2);
      expect(rules[0]).assertDeepEquals(rule1);
      expect(rules[1]).assertDeepEquals(rule2);
    });
  })
}

