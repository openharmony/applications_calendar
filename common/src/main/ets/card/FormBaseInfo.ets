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

import lazy formInfo from '@ohos.app.form.formInfo';

/**
 * 卡片基本信息
 */
class FormBaseInfo {
  public formId: string = '';

  public formName: string = '';

  public formDimension: number = 0;

  constructor(formId: string) {
    this.formId = formId;
  }

  isCard2x2(): boolean {
    return this.formDimension == formInfo.FormDimension.Dimension_2_2;
  }

  isCard2x4(): boolean {
    return this.formDimension == formInfo.FormDimension.Dimension_2_4;
  }
}

export {
  FormBaseInfo
}