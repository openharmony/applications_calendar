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
import { ManagementService, Service, ServiceFactory } from '@app/common/index';
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts';

const testServiceName = 'TestService';

class TestService extends Service {
  constructor() {
    super(testServiceName);
  }
}
;

export default function ManagementServiceTest() {
  describe('ManagementServiceTest', () => {
    let manager: ManagementService;
    beforeEach(() => {
      manager = new ManagementService();
      ServiceFactory.clear();
    })

    it('getService_empty_name', 0, async (done: Function) => {
      expect(manager.getService('')).assertEqual(undefined);
      expect(manager.getService(' ')).assertEqual(undefined);
      done();
    })

    it('getService_not_exist', 0, async (done: Function) => {
      expect(manager.getService('111')).assertEqual(undefined);
      done();
    })

    it('addService', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      expect(await manager.getService('TestService')).assertEqual(service);
      done();
    })

    it('addService_duplicate', 0, async (done: Function) => {
      const service = new TestService();
      expect(manager.addService(service)).assertEqual(ServiceErrCode.SUCCESS);
      expect(manager.addService(service)).assertEqual(ServiceErrCode.SERVICE_ALREADY_EXIST);
      done();
    })

    it('removeService', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      manager.removeService(service.name);
      expect(manager.getService('TestService')).assertEqual(undefined);
      done();
    })

    it('removeService_when_serviceName_is_empty', 0, async (done: Function) => {
      expect(manager.removeService('')).assertEqual(ServiceErrCode.SERVICE_NAME_INVALID);
      expect(manager.removeService(' ')).assertEqual(ServiceErrCode.SERVICE_NAME_INVALID);
      done();
    })

    it('startService_not_exist', 0, async (done: Function) => {
      const result = await manager.startService('aaa');
      expect(result).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('startService_exist', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      const result = await manager.startService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    })

    it('startService_delay', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      const result = await manager.startService(testServiceName, 100);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    })

    it('stopService_not_exist', 0, async (done: Function) => {
      const result = await manager.stopService('aaa');
      expect(result).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('stopService_exist_not_running', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      const result = await manager.stopService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    });

    it('stopService_exist_running', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      await manager.startService(testServiceName);
      const result = await manager.stopService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    });

    it('removeService_not_exist', 0, async (done: Function) => {
      const result = manager.removeService('aaa');
      expect(result).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('pauseService_not_exist', 0, async (done: Function) => {
      const result = await manager.pauseService('aaa');
      expect(result).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('pauseService_not_running', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      const result = await manager.pauseService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    });

    it('pauseService_running', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      await manager.startService(testServiceName);
      const result = await manager.pauseService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    });

    it('continueService_not_exist', 0, async (done: Function) => {
      const result = await manager.continueService('aaa');
      expect(result).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('continueService_not_paused', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      const result = await manager.continueService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    });

    it('continueService_paused', 0, async (done: Function) => {
      const service = new TestService();
      manager.addService(service);
      await manager.startService(testServiceName);
      await manager.pauseService(testServiceName);
      const result = await manager.continueService(testServiceName);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      done();
    });
  })
}