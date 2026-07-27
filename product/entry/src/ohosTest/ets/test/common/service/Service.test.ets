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
import { publicApi, Service, ServiceState } from '@app/common/index'
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts'

class TestService extends Service {
}

export default function ServiceTest() {
  describe('ServiceTest', () => {
    it('IServiceTest_init_state', 0, () => {
      let service = new TestService('TestService');
      expect(service.curState).assertEqual(ServiceState.STOPPED);
    })

    it('IServiceTest_stopped_start', 0, async(done : Function) => {
      let service = new TestService('TestService');
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      await service.start();
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      done();
    })

    it('IServiceTest_stopped_pause', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      expect(await service.pause()).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    })

    it('IServiceTest_stopped_continue', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      expect(await service.continue()).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    })

    it('IServiceTest_stopped_stop', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      expect(await service.stop()).assertEqual(ServiceErrCode.SUCCESS);
      done();
    })

    it('IServiceTest_running_stop', 0, async (done : Function) => {
      let service = new TestService('TestService');
      await service.start();
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      expect(await service.stop()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      done();
    })

    it('IServiceTest_running_start', 0, async (done : Function) => {
      let service = new TestService('TestService');
      await service.start();
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      expect(await service.start()).assertEqual(ServiceErrCode.SUCCESS);
      done();
    })

    it('IServiceTest_running_pause', 0, async (done : Function) => {
      let service = new TestService('TestService');
      await service.start();
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      expect(await service.pause()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.PAUSED);
      done();
    })

    it('IServiceTest_running_continue', 0, async (done : Function) => {
      let service = new TestService('TestService');
      await service.start();
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      expect(await service.continue()).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    })

    it('IServiceTest_paused_start', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(await service.start()).assertEqual(ServiceErrCode.SUCCESS);
      expect(await service.pause()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.PAUSED);
      expect(await service.start()).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    })

    it('IServiceTest_paused_stop', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(await service.start()).assertEqual(ServiceErrCode.SUCCESS);
      expect(await service.pause()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.PAUSED);
      expect(await service.stop()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.STOPPED);
      done();
    })

    it('IServiceTest_paused_pause', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(await service.start()).assertEqual(ServiceErrCode.SUCCESS);
      expect(await service.pause()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.PAUSED);
      expect(await service.pause()).assertEqual(ServiceErrCode.STATE_TRANSFER_MATCH_FAILED);
      done();
    })

    it('IServiceTest_paused_continue', 0, async (done : Function) => {
      let service = new TestService('TestService');
      expect(await service.start()).assertEqual(ServiceErrCode.SUCCESS);
      expect(await service.pause()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.PAUSED);
      expect(await  service.continue()).assertEqual(ServiceErrCode.SUCCESS);
      expect(service.curState).assertEqual(ServiceState.RUNNING);
      done();
    })
  })
}