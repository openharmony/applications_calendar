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
import FormExtensionCallback from '@app/common/src/main/ets/card/FormExtensionCallback';
import Want from '@ohos.app.ability.Want';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import formProvider from '@ohos.app.form.formProvider';
import { behaviorEvents, DeviceConfig, FoldScreenType, Log, ReportHiEventParams, } from '@app/common';
import { MonthCardHandler } from './MonthCardHandler';
import { CardType, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { display } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { CardAction } from '../../common/CardAction';
import { ParamsType } from './MonthCardController4x4';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';

const TAG: string = 'MonthCardController2x2';

export default class MonthCardController2x2 implements FormExtensionCallback {
  public static FORM_NAME: string = 'MonthCard2x2';

  onAddForm(context: Context, want: Want): formBindingData.FormBindingData {
    let params = want?.parameters;
    let formId: string = '';
    if (params) {
      formId = params[formInfo.FormParam.IDENTITY_KEY] as string;
    }
    Log.info(TAG, `onAddForm formId: ${formId} start`);

    const formData: Record<string, Object> = {};
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    formData['formId'] = formId;
    formData['curMonthVM'] = JSON.stringify(viewModel.getCurMonthVM());
    formData['startOfWeek'] = viewModel.getSettingData().startOfWeek;
    formData['weekends'] = viewModel.getSettingData().weekends;
    formData['deviceLayout'] = DeviceConfig.instance().config.deviceLayout;
    const julianDayOfNow = FormUtils.getCurrentJulianDay();
    formData['currentJulianDay'] = julianDayOfNow;
    formData['subscriptionCalendar'] = viewModel.getSettingData().subscriptionCalendar;
    Log.warn(TAG, `onAddForm formId: ${formId} julianDayOfNow=${julianDayOfNow}`);
    try {
      const foldStatus = display.getFoldStatus();
      const foldScreenType: string = systemParameterEnhance.getSync('const.window.foldscreen.type', '0,0,0,0');
      if (foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED &&
        foldScreenType === FoldScreenType.SMALL_UP_DOWN_FOLD) {
        formData['isSmallUp'] = true;
      } else {
        formData['isSmallUp'] = false;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'check is small up', err);
    }

    Log.info(TAG, `onAddForm formId: ${formId} end`);
    // 将fd封装在formData中并返回至卡片页面
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(context: Context, formId: string): void {
  }

  onUpdateForm(context: Context, formId: string): void {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let params: ReportHiEventParams = {
      TYPE: CardType.MONTH_CARD_2X2,
      FORM_ID: formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);
    MonthCardHandler.instance().refreshCards(formId);
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>): void {
  }

  onFormEvent(context: Context, formId: string, message: string): void {
    Log.warn(TAG, `onFormEvent formId: ${formId} start, message is ${message}`);
    if (!message) {
      Log.error(TAG, 'message is null');
      return;
    }
    const params: ParamsType = JSON.parse(message);
    if (params.message === null || params.message === undefined) {
      Log.warn(TAG, `formId: ${formId} params.message is null or undefinded!`);
      return;
    }
    if (params.message === CardAction.REFRESH_MONTH_VIEW) {
      Log.info(TAG, `formId: ${formId} refresh monthcardview`);
      MonthCardHandler.instance().refreshCards(formId);
    }
    Log.info(TAG, `onFormEvent formId: ${formId} end`);
  }

  onRemoveForm(context: Context, formId: string): void {
  }

  onAcquireFormState(context: Context, want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}