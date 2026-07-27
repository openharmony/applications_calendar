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

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import { CalendarDate, DBUtils, GlobalThis, Log,
  MigrateEventDataKeys,
  PreferencesFiles, PreferencesUtil } from '@app/common';
import Want from '@ohos.app.ability.Want';
import FormExtensionCallback from '@app/common/src/main/ets/card/FormExtensionCallback';
import HashMap from '@ohos.util.HashMap';
import EmptyCardController from '@app/common/src/main/ets/card/EmptyCardController';
import AgendaCardController2x2 from '@app/feature.card/src/main/ets/agendaCard/controller/AgendaCardController2x2';
import AgendaCardController2x4 from '@app/feature.card/src/main/ets/agendaCard/controller/AgendaCardController2x4';
import AgendaCardController4x4 from '@app/feature.card/src/main/ets/agendaCard/controller/AgendaCardController4x4';
import AgendaCardController4x6 from '@app/feature.card/src/main/ets/agendaCard/controller/AgendaCardController4x6';
import { ImportantCardController } from '@app/feature.card/src/main/ets/importantCard/controller/ImportantCardController';
import MonthCardController4x4 from '@app/feature.card/src/main/ets/monthCard/controller/MonthCardController4x4';
import MonthCardController2x2 from '@app/feature.card/src/main/ets/monthCard/controller/MonthCardController2x2';
import formInfo from '@ohos.app.form.formInfo';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { FormBaseInfo } from '@app/common/src/main/ets/card/FormBaseInfo';
import formBindingData from '@ohos.app.form.formBindingData';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { ProxyDBUtils } from '@app/common/src/main/ets/dao/ProxyDBUtils';
import { Configuration } from '@kit.AbilityKit';
import { MonthCardHandler } from '@app/feature.card/src/main/ets/monthCard/controller/MonthCardHandler';

const TAG: string = 'CalendarAllFormAbility';

const formProcessMap: HashMap<string, FormExtensionCallback> = new HashMap<string, FormExtensionCallback>();

/**
 * 所有卡片生命周期处理 Ability
 */
export default class AllFormAbility extends FormExtensionAbility {

  onConfigurationUpdate(newConfig: Configuration): void {
    Log.info(TAG, `AllFormAbility onConfigurationUpdate start`);
    MonthCardHandler.instance().refreshCards(undefined, undefined, newConfig.language);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    GlobalThis.getInstance().extensionContext = this.context;
    Log.info(TAG, `AllFormAbility onAddForm`);
    this.openStaticSubscriber();
    return this.getFormProcessByWant(want).onAddForm(this.context, want);
  }

  onCastToNormalForm(formId: string): void {
    Log.info(TAG, `onCastToNormalForm formId: ${formId}`);
    return this.getFormProcess(formId).onCastToNormalForm(this.context, formId);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    GlobalThis.getInstance().extensionContext = this.context;
    Log.warn(TAG, `onUpdateForm formId: ${formId}`);
    this.getFormProcess(formId).onUpdateForm(this.context, formId, wantParams);
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
  }

  onFormEvent(formId: string, message: string): void {
    // 双上同意了隐私，此处需要取消数据库拦截器使得卡片可以找到对应的日程
    if (PreferencesUtil.getNumberValueSync(PreferencesFiles.DOUBLE_SP_STATE, MigrateEventDataKeys.MIGRATE_IS_AGREE)) {
      DBUtils.INSTANCE.setInitializeInterceptor(null);
      ProxyDBUtils.INSTANCE.setInitializeInterceptor(null);
    }
    GlobalThis.getInstance().extensionContext = this.context;
    Log.info(TAG, `onFormEvent formId: ${formId}`);
    return this.getFormProcess(formId).onFormEvent(this.context, formId, message);
  }

  onRemoveForm(formId: string): void {
    GlobalThis.getInstance().extensionContext = this.context;
    Log.warn(TAG, `onRemoveForm formId: ${formId}`);
    this.getFormProcess(formId).onRemoveForm(this.context, formId);
    if (formProcessMap.hasKey(formId)) {
      formProcessMap.remove(formId);
    }
    FormInfoManager.removeFormInfoByFormID(formId);
  }

  /**
   * 开启卡片静态代理
   */
  openStaticSubscriber() {
    commonEventManager.setStaticSubscriberState(true, ['usual.event.TIME_CHANGED', 'usual.event.TIMEZONE_CHANGED']).then(() => {
      Log.info(TAG, `set StaticSubscriber TIME_CHANGED state success, state is true`);
    }).catch((err: BusinessError) => {
      Log.error(TAG, `set StaticSubscriber TIME_CHANGED state failed, errCode: ${err.code}, errMes: ${err.message}`);
    })
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return this.getFormProcessByWant(want).onAcquireFormState(this.context, want);
  }

  getFormProcess(formId: string, formName?: string, formSize?: number): FormExtensionCallback {
    if (formProcessMap.hasKey(formId)) {
      const process = formProcessMap.get(formId);
      Log.warn(TAG, `Retrieved process from formProcessMap: ${process?.constructor?.name}, formId: ${formId}`);
      if (!(process instanceof EmptyCardController)) {
        return process;
      }
    }
    const process: FormExtensionCallback = this.createFromController(formId, formName, formSize);
    formProcessMap.set(formId, process);
    return process;
  }

  getFormProcessByWant(want: Want): FormExtensionCallback {
    let wantParam = want.parameters;
    let formId: string = '';
    let formName: string = '';
    let formSize: number = 0;
    if (wantParam !== null && wantParam !== undefined) {
      formId = wantParam[formInfo.FormParam.IDENTITY_KEY] as string;
      formName = wantParam[formInfo.FormParam.NAME_KEY] as string;
      formSize = wantParam[formInfo.FormParam.DIMENSION_KEY] as number;
      FormInfoManager.saveFormInfo(formId, formName, formSize);
    }
    return this.getFormProcess(formId, formName, formSize);
  }

  createFromController(formId: string, formName?: string, formSize?: number): FormExtensionCallback {
    if (!formName || !formSize) {
      const info: FormBaseInfo | undefined = FormInfoManager.getFormInfo(formId);
      formName = info?.formName;
      formSize = info?.formDimension;
    }

    Log.warn(TAG, `createFromController formName = ${formName}, formId: ${formId}`);
    if (formName === AgendaCardController2x2.FORM_NAME_2X2) {
      return new AgendaCardController2x2();
    } else if (formName === AgendaCardController2x4.FORM_NAME_2X4) {
      return new AgendaCardController2x4();
    } else if (formName === AgendaCardController4x4.FORM_NAME_4x4) {
      return new AgendaCardController4x4();
    } else if (formName === AgendaCardController4x6.FORM_NAME_4x6) {
      return new AgendaCardController4x6();
    } else if (formName === MonthCardController2x2.FORM_NAME) {
      return new MonthCardController2x2()
    } else if (formName === MonthCardController4x4.FORM_NAME) {
      return new MonthCardController4x4();
    } else if (formName === ImportantCardController.FORM_NAME_2x2) {
      return new ImportantCardController(FormDimension.Dimension_2_2);
    } else if (formName === ImportantCardController.FORM_NAME_2x4) {
      return new ImportantCardController(FormDimension.Dimension_2_4);
    }
    return new EmptyCardController();
  }
}
