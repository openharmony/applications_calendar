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

import Want from '@ohos.app.ability.Want';
import formInfo from '@ohos.app.form.formInfo';
import formBindingData from '@ohos.app.form.formBindingData';

/**
 * 卡片生命周期回调
 */
export default interface FormExtensionCallback {
  onAddForm(context: Context, want: Want): formBindingData.FormBindingData;

  onCastToNormalForm(context: Context, formId: string): void;

  onUpdateForm(context: Context, formId: string, wantParams?: Record<string, Object>): void;

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>): void;

  onFormEvent(context: Context, formId: string, message: string): void;

  onRemoveForm(context: Context, formId: string): void;

  onAcquireFormState(context: Context, want: Want): formInfo.FormState;
}