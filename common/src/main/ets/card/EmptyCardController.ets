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
import FormExtensionCallback from './FormExtensionCallback';
import formInfo from '@ohos.app.form.formInfo';
import { Log } from '../default/common/Log';
import formBindingData from '@ohos.app.form.formBindingData';
import { ReportHiEventParams, ReportUtil } from '../default/util/ReportUtil';
import { faultEvents } from '../default/common/HiEvents';

const TAG: string = 'EmptyCardController';

/**
 * 异常分支的卡片controller
 */
export default class EmptyCardController implements FormExtensionCallback {
  onAddForm(context: Context, want: Want): formBindingData.FormBindingData {
    let formId: string = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string || '';
    Log.warn(TAG, `onAddForm formId: ${formId}`);
    this.reportFaultEvent('onAddForm', formId, faultEvents.emptyCardAddForm);
    return formBindingData.createFormBindingData();
  }

  onCastToNormalForm(context: Context, formId: string) {
    Log.warn(TAG, `onCastToNormalForm: ${formId}`);
  }

  onUpdateForm(context: Context, formId: string) {
    Log.warn(TAG, `onUpdateForm: ${formId}`);
    this.reportFaultEvent('onUpdateForm', formId, faultEvents.emptyCardUpdateForm);
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>) {
    Log.warn(TAG, `onChangeFormVisibility`);
  }

  onFormEvent(context: Context, formId: string, message: string) {
    Log.warn(TAG, `onFormEvent: ${formId}`);
    this.reportFaultEvent('onFormEvent', formId, faultEvents.emptyCardFormEvent);
  }

  onRemoveForm(context: Context, formId: string) {
    Log.warn(TAG, `onRemoveForm: ${formId}`);
  }

  onAcquireFormState(context: Context, want: Want): formInfo.FormState {
    Log.warn(TAG, `onAcquireFormState`);
    return formInfo.FormState.READY;
  }

  /**
   * 异常行为故障打点上报
   *
   * @param flag 具体行为触发
   * @param formId 卡片id
   * @param faultEvent 故障事件
   */
  private reportFaultEvent(flag: string, formId: string, faultEvent: string) {
    let params: ReportHiEventParams = {
      FORM_ID: formId,
      EVENT_TYPE: flag
    };
    ReportUtil.reportFaultEvent(faultEvent, params);
  }
}