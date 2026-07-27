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

import { beforeEach, describe, expect, it } from '@ohos/hypium';
import { GlobalEnv, GlobalEnvEnum } from '@app/common';
import { emitter } from '@kit.BasicServicesKit';

export default function GlobalEnvTest() {
  describe('GlobalEnvTest', () => {
    beforeEach(() => {
      GlobalEnv.reset();
    });

    it('setOrCreate_value_change', 0, async (done: Function) => {
      let called: boolean = false;
      let callback = () => {
        called = true;
        expect(called).assertTrue();
      }
      emitter.on(GlobalEnvEnum.WINDOW_SIZE, callback);
      GlobalEnv.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, 100);
      expect(GlobalEnv.has(GlobalEnvEnum.WINDOW_SIZE)).assertTrue();
      expect(GlobalEnv.get<number>(GlobalEnvEnum.WINDOW_SIZE)).assertEqual(100);
      emitter.off(GlobalEnvEnum.WINDOW_SIZE, callback);
      done();
    });

    it('setOrCreate_value_no_change', 0, async (done: Function) => {
      GlobalEnv.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, 100);
      let called: boolean = false;
      let callback = () => {
        called = true;
        expect(called).assertFalse();
      }
      emitter.on(GlobalEnvEnum.WINDOW_SIZE, callback);
      GlobalEnv.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, 100);
      emitter.off(GlobalEnvEnum.WINDOW_SIZE, callback);
      done()
    });

    it('getFromEventData_undefined', 0, () => {
      const value = GlobalEnv.getFromEventData<number>(GlobalEnvEnum.WINDOW_SIZE, {});
      expect(value).assertUndefined();
    });

    it('getFromEventData_different_env', 0, () => {
      const value = GlobalEnv.getFromEventData<number>(GlobalEnvEnum.WINDOW_SIZE, {
        data: {
          ENV_ENUM_KEY: GlobalEnvEnum.DARK_MODE, ENV_VALUE_KEY: 'value'
        }
      });
      expect(value).assertUndefined();
    });

    it('getFromEventData_normal', 0, () => {
      const value = GlobalEnv.getFromEventData<number>(GlobalEnvEnum.WINDOW_SIZE, {
        data: {
          ENV_ENUM_KEY: GlobalEnvEnum.DARK_MODE, ENV_VALUE_KEY: 'value'
        }
      });
      expect(value).assertUndefined();
    });
  })
}

