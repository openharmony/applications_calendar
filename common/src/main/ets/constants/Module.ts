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

export enum ModuleType {
  HAR,
  HSP
};

export enum ModuleName {
  AGENDA = '@app/feature.agenda',
  SETTINGS = '@app/feature.settings',
  SHARE = '@app/feature.share',
  IMPORT_EXPORT = '@app/feature.importexport',
  SUB_FEATURE = '@app/feature.subfeature',
  CARD = '@app/feature.card',
  COMMON = '@app/common',
  TIME_ZONE_SERVICE = '@app/service.timezone',
  REPEAT_RULE = '@app/feature.repeatrule',
  SERVICE_NETWORK = '@app/service.network',
  SERVICE_LOCATION = '@app/service.location',
  SERVICE_ATTACHMENT = '@app/service.attachment',
};

export interface ModuleInfo {
  name : ModuleName,
  type : ModuleType
};