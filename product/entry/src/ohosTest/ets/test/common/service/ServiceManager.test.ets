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
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium'
import { factory, ManagementService, ModuleName, publicApi, Service, ServiceEnum, ServiceFactory, ServiceManager } from '@app/common/index'
import { afterEach } from '@ohos/hypium/src/main/interface'
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts'
import { TestUtil } from '../../utils/TestUtil'
import { ServiceControl } from '@app/common/src/main/ets/service/framework/Service'

const TAG = 'ServiceManagerTest'

export default function ServiceManagerTest() {
  describe('ServiceManagerTest', () => {
    let manager: ServiceManager = ServiceManager.getInstance();
    beforeEach(() => {
      ServiceFactory.clear();
      manager.init([]);
    })

    afterEach(() => {
      ServiceFactory.clear();
      manager.deInit();
    })

    it('getService_empty_name', 0, () => {
      expect(manager.getService('')).assertEqual(undefined);
    })

    it('getService_not_exist', 0, () => {
      expect(manager.getService('111')).assertEqual(undefined);
    })

    it('startService_with_empty_name', 0, async (done: Function) => {
      const ret = await manager.startService('');
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('startService_with_failed', 0, async (done: Function) => {
      class TestService extends Service {
      };
      let mocker: MockKit = new MockKit();
      let getDynamicServiceFunc = mocker.mockFunc(manager, manager.getDynamicService);
      when(getDynamicServiceFunc)(ArgumentMatchers.any).afterReturn(new TestService('TestService'));
      let manageService = TestUtil.getPrivateAttribute<ManagementService>(manager, 'manager');
      const startServiceFunc = mocker.mockFunc(manageService, manageService.startService);
      when(startServiceFunc)(ArgumentMatchers.any).afterReturn(ServiceErrCode.SERVICE_UNAVAILABLE);
      const ret = await manager.startService('aaa');
      mocker.ignoreMock(manager, getDynamicServiceFunc);
      mocker.ignoreMock(manageService, startServiceFunc);
      expect(ret).assertEqual(ServiceErrCode.SERVICE_UNAVAILABLE);
      done();
    })

    it('pauseService_with_failed', 0, async (done: Function) => {
      const ret = await manager.pauseService('');
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('continueService_failed', 0, async (done: Function) => {
      const ret = await manager.continueService('');
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('controlService', 0, async (done: Function) => {
      const ret = await manager.controlService(ServiceControl.START, '', 0);
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NOT_EXIST);
      done();
    })

    it('getDynamicService_success', 0, async (done: Function) => {
      class TestService extends Service {
      };
      let manageService = TestUtil.getPrivateAttribute<ManagementService>(manager, 'manager');
      manageService.addService(new TestService('TestService'));
      const service = await manager.getDynamicService<Service>('TestService');
      expect(service).not().assertUndefined();
      done();
    })

    it('getDynamicService_failed', 0, async (done: Function) => {
      const service = await manager.getDynamicService<Service>('');
      expect(service).assertUndefined();
      done();
    })

    it('getService_from_factory', 0, () => {
      @factory('TestService')
      class TestService extends Service {
        getTag(): string {
          return 'TestService';
        }
      };
      let instance = manager.getService<TestService>('TestService');
      if (instance) {
        const tag = instance.getTag();
        expect(tag).assertEqual('TestService');
      } else {
        expect(instance).not().assertUndefined();
      }
    })

    it('getService_with_interface', 0, () => {
      abstract class TestServiceInterface extends Service {
        abstract doSomeThing(): string;
      }

      @factory('TestService')
      class TestService extends TestServiceInterface {
        doSomeThing(): string {
          return 'doSomeThing';
        }
      };
      let instance = manager.getService('TestService') as TestServiceInterface;
      if (instance) {
        const ret = instance.doSomeThing();
        expect(ret).assertEqual('doSomeThing');
      } else {
        expect(instance).not().assertUndefined();
      }
    })

    it('callApi_service_not_exist', 0, () => {
      const ret = manager.callApi<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
    })

    it('callApi_service_not_found', 0, () => {
      class TestService extends Service {
        @publicApi
        func() {
        }
      }

      const ret = manager.callApi<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
    })

    it('callApi_api_not_registered', 0, () => {
      @factory('TestService')
      class TestService extends Service {
      }
      const ret = manager.callApi<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
    })

    it('callApi_service_not_running', 0, () => {
      @factory('TestService')
      class TestService extends Service {
        @publicApi
        func() {
        }
      }
      const ret = manager.callApi<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
    })

    it('serviceCall_service_void', 0, async (done: Function) => {
      let param = 1;
      @factory('TestService')
      class TestService extends Service {
        @publicApi
        func() {
          param = 2;
        }
      }
      const result = await manager.startService('TestService');
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      const ret = manager.callApi<void>(`TestService`, `func`);
      expect(param).assertEqual(2);
      done();
    })

    it('serviceCall_return', 0, async (done: Function) => {
      @factory('TestService1')
      class TestService1 extends Service {
        @publicApi
        func1(): boolean {
          return false;
        }
      }
      const result = await manager.startService('TestService1');
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      let ret = manager.callApi<boolean>(`TestService1`, `func1`);
      expect(ret).not().assertUndefined();
      expect(ret).assertFalse();
      done();
    })

    it('serviceCall_with_args', 0, async (done: Function) => {
      @factory('TestService2')
      class TestService2 extends Service {
        @publicApi
        func1(param: string): string {
          return param + param;
        }
      }
      const result = await manager.startService('TestService2');
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      let ret = manager.callApi<boolean>(`TestService2`, `func1`, 'haha');
      expect(ret).not().assertUndefined();
      expect(ret).assertEqual('hahahaha');
      done();
    })

    it('callApiAsync_service_not_exist', 0, async (done: Function) => {
      const ret = await manager.callApiAsync<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
      done();
    })

    it('callApiAsync_service_not_found', 0, async (done: Function) => {
      class TestService extends Service {
        @publicApi
        async func(): Promise<void> {
        }
      }

      const ret = await manager.callApiAsync<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
      done();
    })

    it('callApiAsync_api_not_registered', 0, async (done: Function) => {
      @factory('TestService')
      class TestService extends Service {
      }
      const ret = await manager.callApiAsync<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
      done();
    })

    it('callApiAsync_api_not_registered_service_not_running', 0, async (done: Function) => {
      @factory('TestService')
      class TestService extends Service {
        @publicApi
        func() {
        }
      }
      const ret = await manager.callApiAsync<string>(`TestService`, `func`);
      expect(ret).assertUndefined();
      done();
    })

    it('callApiAsync', 0, async (done: Function) => {
      @factory('TestService3')
      class TestService3 extends Service {
        @publicApi
        async func1(param: string): Promise<string> {
          return param + param;
        }
      }
      const result = await manager.startService('TestService3');
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
      let ret = await manager.callApiAsync<boolean>(`TestService3`, `func1`, 'haha');
      expect(ret).not().assertUndefined();
      expect(ret).assertEqual('hahahaha');
      done();
    })

    it('getServiceModule_serviceName_is_empty', 0, async (done: Function) => {
      const result = manager.getServiceModule('');
      expect(result).assertUndefined();
      done();
    });

    it('getServiceModule_serviceName_is_found', 0, async (done: Function) => {
      manager.init([{
        info: {
          name: ServiceEnum.SYS_WRAPPER_SERVICE, module: ModuleName.COMMON
        },
        controlStrategies: []
      }]
      )
      const result = manager.getServiceModule(ServiceEnum.SYS_WRAPPER_SERVICE);
      expect(result).assertEqual(ModuleName.COMMON);
      done();
    });

    it('getServiceModule_serviceName_is_not_found', 0, async (done: Function) => {
      const serviceName = 'unknownService';
      const result = manager.getServiceModule(serviceName);
      expect(result).assertUndefined();
      done();
    });
  })
}