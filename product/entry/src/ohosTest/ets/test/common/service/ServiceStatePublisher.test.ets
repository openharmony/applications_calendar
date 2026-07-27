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
import { describe, expect, it, MockKit } from '@ohos/hypium'
import {
    ServiceStateChangeInfo,
    ServiceStateObserver,
    ServiceStatePublisher
} from '@app/common/src/main/ets/service/framework/ServiceStateObserver'
import { beforeEach } from '@ohos/hypium/src/main/interface'
import { ServiceState } from '@app/common'
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts'

const observerName = 'TestObserver';

class TestObserver extends ServiceStateObserver {
  onServiceStateChanged(changeInfo: ServiceStateChangeInfo): void {
  }
}

export default function ServiceStateObserverTest() {
  describe('ServiceStatePublisherTest', () => {
    let publisher: ServiceStatePublisher;
    beforeEach(() => {
      publisher = new ServiceStatePublisher();
    })
    it('addObserver_not_exist', 0, () => {
      let observer = new TestObserver(observerName);
      const result = publisher.addObserver(observer);
      expect(result).assertEqual(ServiceErrCode.SUCCESS);
    })

    it('addObserver_exist', 0, () => {
      let observer = new TestObserver(observerName);
      expect(publisher.addObserver(observer)).assertEqual(ServiceErrCode.SUCCESS);
      expect(publisher.addObserver(observer)).assertEqual(ServiceErrCode.STATE_OBSERVER_ALREADY_EXIST);
    })

    it('removeObserver_exist', 0, () => {
      let observer = new TestObserver('TestObserver');
      expect(publisher.addObserver(observer)).assertEqual(ServiceErrCode.SUCCESS);
      expect(publisher.removeObserver(observerName)).assertEqual(ServiceErrCode.SUCCESS);
    })

    it('removeObserver_not_exist', 0, () => {
      expect(publisher.removeObserver(observerName)).assertEqual(ServiceErrCode.STATE_OBSERVER_NO_FOUND);
    })

    it('removeObserver_name_invalid', 0, () => {
      expect(publisher.removeObserver('')).assertEqual(ServiceErrCode.STATE_OBSERVER_NAME_INVALID);
      expect(publisher.removeObserver('  ')).assertEqual(ServiceErrCode.STATE_OBSERVER_NAME_INVALID);
    })

    it('notifyObservers', 0, () => {
      let mocker: MockKit = new MockKit();
      let observer = new TestObserver('TestObserver');
      mocker.mockFunc(observer, observer.onServiceStateChanged);
      expect(publisher.addObserver(observer)).assertEqual(ServiceErrCode.SUCCESS);
      const info: ServiceStateChangeInfo = {
        serviceName: 'testService',
        lastState: ServiceState.STOPPED,
        currentState: ServiceState.RUNNING,
      }
      publisher.notifyObservers(info);
      mocker.verify('onServiceStateChanged', [info]).once();
      mocker.clear(observer);
    })
  })
}