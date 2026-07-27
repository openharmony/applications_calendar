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

import { ServiceEnvEvent, ServiceEvent } from './ServiceConsts';
import { emitter } from '@kit.BasicServicesKit';
import { AbilityConstant } from '@kit.AbilityKit';

export interface ServiceEnv {
  state: ServiceEnvEvent
}

export class ServiceGlobalEnv {
  static onEnvChange(state: ServiceEnvEvent): void {
    emitter.emit<ServiceEnv>(ServiceEvent.SERVICE_ENV_CHANGE,
      {
        priority: emitter.EventPriority.IMMEDIATE
      },
      {
        data: { state: state }
      });
  }
}