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
import { beforeEach, describe, expect, it } from '@ohos/hypium'
import { factory, publicApi, Service, ServiceFactory } from '@app/common'
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts'

const TAG = 'ServiceFactoryTest'


export default function ServiceFactoryTest() {
  describe('ServiceFactoryTest', () => {
    beforeEach(() => {
      ServiceFactory.clear();
    })
    it('unregister_name', 0, () => {
      class TestClass1 extends Service {
      }
      ServiceFactory.register('TestClass1', TestClass1);
      let instance = ServiceFactory.getConstructor('others');
      expect(instance).assertNull();
    })

    it('register_manually', 0, () => {
      class TestService2 extends Service {
      }

      ServiceFactory.register('TestService2', TestService2);
      let instance = ServiceFactory.getConstructor('TestService2');
      expect(instance).not().assertNull();
    })

    it('register_duplicate', 0, () => {
      class TestService2 extends Service {
      }

      let ret = ServiceFactory.register('TestService2', TestService2);
      expect(ret).assertEqual(ServiceErrCode.SUCCESS);
      ret = ServiceFactory.register('TestService2', TestService2);
      expect(ret).assertEqual(ServiceErrCode.SERVICE_ALREADY_REGISTERED);
    })

    it('register_manually_other_name', 0, () => {
      class TestService2 extends Service {
      }

      ServiceFactory.register('OtherService', TestService2);
      let instance = ServiceFactory.getConstructor('OtherService');
      expect(instance).not().assertNull();
    })

    it('register_by_factory_no_name', 0, () => {
      @factory(' ')
      class TestService extends Service {
      }
      let constructor = ServiceFactory.getConstructor(TestService.name);
      expect(constructor).assertNull();
    })

    it('register_by_factory_other_name', 0, () => {
      @factory('OtherService')
      class TestService extends Service {
      }
      let constructor = ServiceFactory.getConstructor(TestService.name);
      expect(constructor).assertNull();
      constructor = ServiceFactory.getConstructor('OtherService');
      expect(constructor).not().assertNull();
    })

    it('getConstructorAsync_after_register', 0, async (done : Function) => {
      class TestService extends Service {
      }
      expect(ServiceFactory.register('TestService', TestService)).assertEqual(ServiceErrCode.SUCCESS);
      let instance = await ServiceFactory.getConstructorAsync('TestService');
      if (instance) {
        let tmp = new instance() as TestService;
        expect(tmp).not().assertNull();
      } else {
        expect(instance).not().assertNull();
      }
      done();
    })

    it('getConstructorAsync_getModuleName_failed', 0, async (done : Function) => {
      let instance = await ServiceFactory.getConstructorAsync('TestService');
      expect(instance).assertUndefined();
      done();
    })
  })
}