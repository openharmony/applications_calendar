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

import { ServiceControl } from './Service';
import { ServiceEnvEvent } from './ServiceConsts';

export interface ServiceConfig {
  info: ServiceInfo,
  controlStrategies: ServiceControlStrategy[]
}

export interface ServiceInfo {
  name: string,
  module?: string,
}

// 控制策略
export interface ServiceControlStrategy {
  cmd: ServiceControl, // 控制行为
  triggerEvent: ServiceEnvEvent, // 触发事件
  delayTime?: number, // 可选参数，表示延迟开始的时间，单位为毫秒
}