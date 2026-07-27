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

/**
 * 双框架卡片基本信息
 */
class DoubleFormBaseInfo {
  public formId: string = '';

  // 授权状态
  public statementState: number = 0;

  // 迁移状态
  public migrateType: number = MigrateType.DEFAULT;

  constructor(formId: string) {
    this.formId = formId;
  }
}

export {
  DoubleFormBaseInfo
}

export enum MigrateType {
  DEFAULT = 0,
  SINGLE_CLONE_SINGLE = 1000,
  DOUBLE_CLONE_SINGLE = 1001,
  DOUBLE_UPDATE_SINGLE = 1002,
}
