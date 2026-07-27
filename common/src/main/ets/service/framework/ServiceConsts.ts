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

export enum ServiceErrCode {
  SUCCESS = 0,
  // service register
  SERVICE_ALREADY_REGISTERED = 1000001,
  IMPORT_MODULE_UNDEFINED = 1000002,
  MODULE_SERVICE_INIT_UNDEFINED = 1000002,
  MODULE_SERVICE_INIT_TYPE_ERROR,
  // service manager
  SERVICE_UNAVAILABLE = 1000102,
  SERVICE_NAME_INVALID = 1000102,
  SERVICE_NOT_EXIST = 1000103,
  SERVICE_ALREADY_EXIST = 1000104,
  SERVICE_DELETE_FAILED = 1000105,
  // service state
  STATE_TRANSFER_MATCH_FAILED = 1000201,
  STATE_TRANSFER_ACTION_NO_FOUND = 1000202,
  // service state observer
  STATE_OBSERVER_NAME_INVALID = 1000301,
  STATE_OBSERVER_ALREADY_EXIST = 1000302,
  STATE_OBSERVER_NO_FOUND = 1000303,

  API_NOT_FOUND = 1000401,
  API_NAME_INVALID = 1000003,
  API_ALREADY_REGISTERED = 1000003,

  CONTROL_NOT_FOUND = 1000501,
}

// 外部环境事件: ABILITY生命周期 内存变化  配置变化
export enum ServiceEnvEvent {
  ABILITY_STAGE_CREATE,
  ABILITY_STAGE_ACCEPT_WANT,
  ABILITY_STAGE_MEMORY_LEVEL_CHANGE,
  ABILITY_STAGE_CONFIG_UPDATE,
  MAIN_ABILITY_CREATE,
  WINDOW_STAGE_CREATE,
  FOREGROUND,
  BACKGROUND,
  WINDOW_STAGE_DESTROY,
  MAIN_WINDOW_SHOWN,
  MAIN_ABILITY_DESTROY,
  ABILITY_STAGE_DESTROY,
}

// 内部服务事件
export enum ServiceEvent {
  SERVICE_ENV_CHANGE = 'SERVICE_GLOBAL_ENV_CHANGE',
  SERVICE_STATE_CHANGE = 'SERVICE_STATE_CHANGE'
}
