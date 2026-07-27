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

import { factory, Service } from '../../framework/Service';
import { emitter } from '@kit.BasicServicesKit';
import { ServiceStateChangeInfo } from '../../framework/ServiceStateObserver';
import { ServiceEvent } from '../../framework/ServiceConsts';
import { Log } from '../../../default/common/Log';
import { ServiceEnum } from '../../framework/ServiceEnum';

const TAG = '[Service][Auditor]';

@factory(ServiceEnum.AUDITOR_SERVICE)
export class AuditorService extends Service {
  async doStart(): Promise<void> {
    emitter.on<ServiceStateChangeInfo>(ServiceEvent.SERVICE_STATE_CHANGE, this.onServiceStateChange);
  }

  async doStop(): Promise<void> {
    emitter.off<ServiceStateChangeInfo>(ServiceEvent.SERVICE_STATE_CHANGE, this.onServiceStateChange);
  }

  private onServiceStateChange: (data: emitter.GenericEventData<ServiceStateChangeInfo>) => void =
    (data: emitter.GenericEventData<ServiceStateChangeInfo>): void => {
      if (!data || !data.data) {
        return;
      }
      const info = data.data;
      Log.hilogInfo(TAG,
        'ServiceStateChange, name: %{public}s, fromState: %{public}d, toState: %{public}d',
        info.serviceName, info.lastState, info.currentState)
    }
}