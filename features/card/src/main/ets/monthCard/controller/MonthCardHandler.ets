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

import { MonthCardModel } from '../model/MonthCardModel';
import lazy { formProvider } from '@kit.FormKit';
import formBindingData from '@ohos.app.form.formBindingData';
import { FormBaseInfo } from '@app/common/src/main/ets/card/FormBaseInfo';
import { MigrateType } from '@app/common/src/main/ets/card/DoubleFormBaseInfo';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { FormName } from '../../utils/FormName';
import { DoubleFormInfoManager } from '@app/common/src/main/ets/card/DoubleFormInfoManager';
import { behaviorEvents } from '@app/common/src/main/ets/default/common/HiEvents';
import { CardService, RefreshConfig } from '@app/common/src/main/ets/service/implements/card/CardService';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import lazy { cardTypes } from '../../agendaCard/common/CardFormMonthViewModel';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { I18nUtil } from '@app/common';

const TAG = 'MonthCardHandler';

/**
 * 月视图卡片数据处理
 */
export class MonthCardHandler {
  private static _instance: MonthCardHandler = new MonthCardHandler();

  static instance(): MonthCardHandler {
    return MonthCardHandler._instance;
  }

  /**
   * 刷新卡片
   * @param formId 可选参数，如果提供则刷新单张卡片，否则刷新所有卡片
   * @param refreshConfig 可选参数，触发 refreshConfig
   */
  refreshCards(formId?: string, refreshConfig?: RefreshConfig, language?: string) {
    // 读取应用的缓存设置数据
    let cardInfos: FormBaseInfo[];

    if (formId) {
      const singleCardInfo = FormInfoManager.getFormInfo(formId);
      cardInfos = singleCardInfo ? [singleCardInfo] : [];
    } else {
      cardInfos = FormInfoManager.getAllFormInfo();
    }

    if (cardInfos.length === 0) {
      Log.error(TAG, `refreshCards cardInfos is empty`);
      this.closeStaticSubscriber();
      return;
    }
    Log.warn(TAG, `refreshCards cardInfos length = ${cardInfos.length}`);
    const viewModel = this.getMonthCardVM();
    cardInfos.forEach(async (info: FormBaseInfo) => {
      if (info === null || info === undefined) {
        Log.error(TAG, `refreshCards cardInfo is empty`)
        return;
      }
      if (info.formName === FormName.MONTH_CARD_4X4) {
        Log.warn(TAG, `refreshCards: ${info.formName} formId: ${info.formId} month_card_4x4 is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, true, viewModel);
      } else if (info.formName === FormName.MONTH_CARD_2X2 ||
        info.formName === FormName.AGENDA_CARD_2X2 ||
        info.formName === FormName.AGENDA_CARD_2X4 ||
        info.formName === FormName.AGENDA_CARD_4X4 ||
        info.formName === FormName.AGENDA_CARD_4X6) {
        Log.warn(TAG, `refreshCards: ${info.formName} formId: ${info.formId} is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, false, viewModel);
      } else if (info.formName === FormName.IMPORTANT_CARD_2X2 ||
        info.formName === FormName.IMPORTANT_CARD_2X4) {
        this.refreshImportantCard(info, refreshConfig)
      }
    });
  }


  /**
   * 关闭卡片静态代理
   */
  closeStaticSubscriber() {
    commonEventManager.setStaticSubscriberState(false, ['usual.event.TIME_CHANGED', 'usual.event.TIMEZONE_CHANGED'])
      .then(() => {
      Log.info(TAG, `set StaticSubscriber TIME_CHANGED state success, state is false`);
    }).catch((err: BusinessError) => {
      Log.error(TAG, `set StaticSubscriber TIME_CHANGED state failed, errCode: ${err.code}, errMes: ${err.message}`);
    })
  }

  initAllCards() {
    // 读取应用的缓存设置数据
    const cardInfo: FormBaseInfo[] = FormInfoManager.getAllFormInfo();
    if (cardInfo.length === 0) {
      Log.info(TAG, `initAllCards cardInfo is null!`);
      return;
    }
    Log.warn(TAG, `initAllCards cardInfos length = ${cardInfo.length}`);
    const viewModel = this.getMonthCardVM();
    cardInfo.forEach((info: FormBaseInfo) => {
      const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
      Log.info(TAG, `initAllCard: ${info.formName} formId: ${info.formId} is refreshed, isAgreeStatement = ${isAgreeStatement}`);
      formProvider.updateForm(info.formId, formBindingData.createFormBindingData({
        'isAgreeStatement': isAgreeStatement,
      }));
    })
  }

  refreshAllCardsDoubleUpSingleAgreeStatement() {
    Log.info(TAG, `updateMigrateStatus start`);
    const cardInfos = FormInfoManager.getAllFormInfo();

    if (cardInfos.length === 0) {
      Log.warn(TAG, `updateMigrateStatus: cardInfos is invalid`);
      return;
    }

    Log.warn(TAG, `refreshAllCardsDoubleUpSingleAgreeStatement cardInfos length = ${cardInfos.length}`);
    cardInfos.forEach(cardInfo => {
      formProvider.updateForm(cardInfo.formId, formBindingData.createFormBindingData({
        isDoubleUpSingleAgreeStatement: this.getDoubleUpSingleAgreeStatement(cardInfo.formId)
      }));
    });
  }

  getAgreeStatement() {
    const viewModel = this.getMonthCardVM();
    const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
    return isAgreeStatement;
  }

  getDoubleUpSingleAgreeStatement(formId: string) {
    if (!formId) {
      Log.warn(TAG, `getDoubleUpSingleAgreeStatement: formId is invalid`);
      return false;
    }

    const singleFormId = BigInt.asIntN(32, BigInt(formId)).toString();
    const originDoubleCardInfo = DoubleFormInfoManager.getFormInfo(formId);
    const doubleToSingleCardInfo = DoubleFormInfoManager.getFormInfo(singleFormId);
    const doubleCardInfo = originDoubleCardInfo || doubleToSingleCardInfo;

    if (doubleCardInfo === undefined) {
      Log.warn(TAG, `getDoubleUpSingleAgreeStatement: cardInfo is invalid`);
      return false;
    }

    const isAgree = doubleCardInfo.statementState === 1;
    const isDoubleUpdateSingle = doubleCardInfo.migrateType === MigrateType.DOUBLE_UPDATE_SINGLE;
    Log.info(TAG, `getDoubleUpSingleAgreeStatement: ${formId} ${doubleCardInfo.migrateType}`);

    return isAgree && isDoubleUpdateSingle;
  }

  /**
   * 刷新所有班休卡片
   *
   */
  refreshRecessCards() {
    const cardInfos: FormBaseInfo[] = FormInfoManager.getAllFormInfo();
    if (cardInfos.length === 0) {
      Log.info(TAG, `refreshRecessCards cardInfos is null!`);
      return;
    }

    Log.warn(TAG, `refreshRecessCards cardInfos length = ${cardInfos.length}`);
    const viewModel = this.getMonthCardVM();
    cardInfos.forEach((info: FormBaseInfo) => {
      if (info?.formName === FormName.MONTH_CARD_4X4) {
        Log.warn(TAG, `refreshRecessCards: ${info.formName} formId: ${info.formId} is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, true, viewModel);
      } else if (info?.formName === FormName.MONTH_CARD_2X2) {
        Log.warn(TAG, `refreshRecessCards: ${info.formName} formId: ${info.formId} is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, false, viewModel);
      }
    });
  }

  /**
   * 刷新所有含农历和节假日的卡片
   *
   */
  refreshTermCards() {
    const cardInfos: FormBaseInfo[] = FormInfoManager.getAllFormInfo();
    if (cardInfos.length === 0) {
      Log.info(TAG, `refreshTermCards cardInfos is null!`);
      return;
    }
    Log.warn(TAG, `refreshTermCards cardInfos length = ${cardInfos.length}`);
    const viewModel = this.getMonthCardVM();
    cardInfos.forEach((info: FormBaseInfo) => {
      if (info?.formName === FormName.MONTH_CARD_4X4) {
        Log.warn(TAG, `refreshTermCards: ${info.formName} formId: ${info.formId} is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, true, viewModel);
      } else if (info?.formName === FormName.AGENDA_CARD_4X6) {
        Log.warn(TAG, `refreshTermCards: ${info.formName} formId: ${info.formId} is refreshed`);
        this.reportCardRefresh(info);
        this.deliverCurrentVM(info, false, viewModel);
      } else if (info.formName === FormName.IMPORTANT_CARD_2X2 ||
        info.formName === FormName.IMPORTANT_CARD_2X4) {
        this.refreshImportantCard(info)
      }
    });
  }

  /**
   * 透传月份数据以及设置项到卡片
   * @param cardInfo 卡片信息
   * @param isMonthCard4x4 是否是月视图4x4卡片
   */
  deliverCurrentVM(cardInfo: FormBaseInfo, isMonthCard4x4 = false, viewModel: MonthCardModel) {
    const formData: Record<string, Object> = {};
    if (isMonthCard4x4) {
      formData['cardSingleMonthVMJSONStr'] = JSON.stringify(viewModel.getAllMonthVM());
      formData['preMonthVMJSONStr'] = '';
      formData['nextMonthVMJSONStr'] = '';
    } else {
      formData['curMonthVM'] = JSON.stringify(viewModel.getCurMonthVM());
    }
    formData['startOfWeek'] = viewModel.getSettingData().startOfWeek;
    formData['weekends'] = viewModel.getSettingData().weekends;
    const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
    formData['isAgreeStatement'] = isAgreeStatement;
    formData['timeZone'] = viewModel.getSettingData().timeZone;
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    formData['currentJulianDay'] = currentJulianDay;
    formData['subscriptionCalendar'] = viewModel.getSettingData().subscriptionCalendar;
    // 修改系统时间不会走controller的upDateForm，所以需要在这里触发农历日期的刷新回调
    formData['agendaRefresh'] = Math.random().toString();
    formData['updateLunarInfoStr'] = Math.random().toString();
    Log.warn(TAG, `deliverCurrentVM isAgreeStatement= ${isAgreeStatement}, currentJulianDay= ${currentJulianDay}`);
    formProvider.updateForm(cardInfo.formId, formBindingData.createFormBindingData(formData));
  }


  /**
   * 刷新重要日卡片
   * @param cardInfo 卡片信息
   * @param refreshConfig 可选参数，触发 refreshConfig
   */
  async refreshImportantCard(cardInfo: FormBaseInfo, refreshConfig?: RefreshConfig) {
    Log.info(TAG, `refreshImportantCard: ${cardInfo.formName} formId: ${cardInfo.formId} is refreshed`);
    const cardService = await ServiceManager.getInstance().getDynamicService<CardService>(ServiceEnum.CARD_SERVICE)
    if (cardService) {
      cardService.refreshImportantCard(
        GlobalThis.getInstance().getFromContext(),
        cardInfo.formId,
        undefined,
        undefined,
        refreshConfig);
    } else {
      Log.warn(TAG, `no cardService`);
    }
  }

  /**
   * 卡片刷新打点
   */
  reportCardRefresh(cardInfo: FormBaseInfo) {
    let params: ReportHiEventParams = {
      TYPE: cardTypes.get(cardInfo.formName),
      FORM_ID: cardInfo.formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);
  }

  /**
   * 获取月视图模型
   */
  getMonthCardVM(displayDate?: CalendarDate) {
    return new MonthCardModel(displayDate);
  }
}