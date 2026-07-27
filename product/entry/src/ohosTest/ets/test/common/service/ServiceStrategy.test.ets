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
import { describe, expect, it } from '@ohos/hypium'
import { Service, ServiceEnvEvent, ServiceState } from '@app/common/index'
import { ServiceControl } from '@app/common/src/main/ets/service/framework/Service'
import { ServiceControlStrategy } from '@app/common/src/main/ets/service/framework/ServiceConfig'

class TestService extends Service {
}

export default function ServiceStrategyTest() {
  describe('ServiceStrategyTest', () => {
    it('single_strategy', 0, () => {
      let service = new TestService('TestService');
      const testStrategy : ServiceControlStrategy = {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.ABILITY_STAGE_CREATE
      }
      expect(service.curState).assertEqual(ServiceState.STOPPED);
    })
  })
}