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
import { ModuleName } from '@app/common/src/main/ets/constants/Module';
import { ServiceEnvEvent } from '@app/common/src/main/ets/service/framework/ServiceConsts';
import { ServiceControl } from '@app/common/src/main/ets/service/framework/Service';
import { ServiceConfig, ServiceControlStrategy } from '@app/common/src/main/ets/service/framework/ServiceConfig';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';

const DEFAULT_START_STRATEGY: ServiceControlStrategy = {
  cmd: ServiceControl.START,
  triggerEvent: ServiceEnvEvent.ABILITY_STAGE_CREATE
};
const DEFAULT_STOP_STRATEGY: ServiceControlStrategy = {
  cmd: ServiceControl.STOP,
  triggerEvent: ServiceEnvEvent.ABILITY_STAGE_DESTROY
};
const DEFAULT_START_AND_STOP_STRATEGY: ServiceControlStrategy[] = [
  DEFAULT_START_STRATEGY,
  DEFAULT_STOP_STRATEGY
];

export const g_serviceConfig: ReadonlyArray<ServiceConfig > = [
  {
    info: {
      name: ServiceEnum.AUDITOR_SERVICE, module: ModuleName.COMMON
    },
    controlStrategies: DEFAULT_START_AND_STOP_STRATEGY
  },
  {
    info: {
      name: ServiceEnum.SYS_WRAPPER_SERVICE, module: ModuleName.COMMON
    },
    controlStrategies: DEFAULT_START_AND_STOP_STRATEGY
  },
  {
    info: {
      name: ServiceEnum.CARD_SERVICE, module: ModuleName.CARD
    },
    controlStrategies: [
      {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.MAIN_WINDOW_SHOWN
      },
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.SHARE_SERVICE, module: ModuleName.SHARE
    },
    controlStrategies: [
      {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.MAIN_WINDOW_SHOWN,
        delayTime: 100
      },
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.ICS_VCS_SERVICE, module: ModuleName.IMPORT_EXPORT
    },
    controlStrategies: [
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.IMPORT_EXPORT_SERVICE, module: ModuleName.IMPORT_EXPORT
    },
    controlStrategies: [
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.GLOBAL_NET_SERVICE, module: ModuleName.SERVICE_NETWORK
    },
    controlStrategies: DEFAULT_START_AND_STOP_STRATEGY
  },
  {
    info: {
      name: ServiceEnum.AGENDA_DELETE_SERVICE, module: ModuleName.AGENDA
    },
    controlStrategies: DEFAULT_START_AND_STOP_STRATEGY
  },
  {
    info: {
      name: ServiceEnum.AGENDA_SERVICE, module: ModuleName.AGENDA
    },
    controlStrategies: DEFAULT_START_AND_STOP_STRATEGY
  },
  {
    info: {
      name: ServiceEnum.LOCK_TIME_ZONE_SERVICE, module: ModuleName.TIME_ZONE_SERVICE
    },
    controlStrategies: [
      {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.MAIN_WINDOW_SHOWN
      },
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.AGENDA_LOCATION_SERVICE, module: ModuleName.SERVICE_LOCATION
    },
    controlStrategies: [
      {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.MAIN_WINDOW_SHOWN
      },
      DEFAULT_STOP_STRATEGY
    ]
  },
  {
    info: {
      name: ServiceEnum.ATTACHMENT_SERVICE, module: ModuleName.SERVICE_ATTACHMENT
    },
    controlStrategies: [
      {
        cmd: ServiceControl.START,
        triggerEvent: ServiceEnvEvent.MAIN_WINDOW_SHOWN
      },
      DEFAULT_STOP_STRATEGY
    ]
  }
];