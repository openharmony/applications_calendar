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

import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { Env, GlobalEnvEnum, LayoutModel, LayoutRule } from '@app/common';

class LayoutModelMock extends LayoutModel {
  constructor() {
    super();
  }
}

let layoutModel = new LayoutModelMock();

/*
watch window size change
 * */
class MockLayoutRule extends LayoutRule {
  constructor() {
    super('MockLayoutRule', [GlobalEnvEnum.WINDOW_SIZE]);
  }

  onChange(data: Env): boolean {
    return true;
  }
}

export default function LayoutModelEnvTest() {
  describe('LayoutModelEnvTest', () => {
    let mocker: MockKit
    beforeEach(() => {
      mocker = new MockKit;
      layoutModel.unInit();
    })
    it('rule_onchange_when_watch_env_change', 0, () => {
      let rule = new MockLayoutRule();
      let res = layoutModel.addRule(rule);
      if (!res) {
        expect('addRule failed').assertEqual('addRule success');
      }
      mocker.mockFunc(rule, rule.onChange);
      let env = new Env(GlobalEnvEnum.WINDOW_SIZE);
      layoutModel.callback(env)
      mocker.verify('onChange', [env]).once();
    });

    it('rule_onchange_when_other_env_change', 0, () => {
      let rule = new MockLayoutRule();
      let res = layoutModel.addRule(rule);
      if (!res) {
        expect('addRule failed').assertEqual('addRule success');
      }
      mocker.mockFunc(rule, rule.onChange);
      let env = new Env(GlobalEnvEnum.DARK_MODE);
      layoutModel.callback(env);
      mocker.verify('onChange', [env]).times(0);
    });
  })
}

