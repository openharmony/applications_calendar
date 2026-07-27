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
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import dataShare from '@ohos.data.dataShare';
import {
  behaviorEvents,
  DeviceConfig,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_MINUTE,
  MILLS_PER_WEEK,
  ReportUtil,
  statisticEvents
} from '@app/common';
import Want from '@ohos.app.ability.Want';
import formProvider from '@ohos.app.form.formProvider';
import { ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { MonthCardHandler } from '../../monthCard/controller/MonthCardHandler';
import {
  delAndAddDataShareHelper,
  MAX_RETRY_TIMES,
  PROXY_URI_CALENDAR,
  registerDataShareHelper
} from '../../utils/RegisterDataShareHelperUtils';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { i18n } from '@kit.LocalizationKit';
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardAction } from '../../common/CardAction'
import {
  FORMAT_START_OF_DAY_UTC_TIME,
  FORMAT_CURRENT_UTC_TIME,
  QUERY_CONDITION_BASIC,
  getQueryTodayAgendaSql,
  QUERY_TODAY_AGENDA_SQL
} from '../../utils/UpdateSQLUtils';
import { AgendaCardDataProxyHelper } from './AgendaCardDataProxyHelper';

const TAG: string = 'AgendaCardController4x4';

/**
 * 卡片日程数据查询sql
 * @param queryColumns 需要查询的Columns
 * @returns 查询的sql
 */
function queryValidAgendaSql(queryColumns: string): string {
  return `SELECT ${queryColumns}
    FROM
      Instances
      INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
      INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
    WHERE
      visible = 1
      AND (
        BEGIN < ${FORMAT_START_OF_DAY_UTC_TIME} + ${MILLS_PER_WEEK}
        AND
        END > ${FORMAT_CURRENT_UTC_TIME}
       )
      AND important_event_type = 0
    ORDER BY startDay, BEGIN ASC
    LIMIT 20`;
}

// 卡片日程数据查询 sql: strftime获取的是秒级别的时间戳
const QUERY_VALID_AGENDA_SQL: string = queryValidAgendaSql(QUERY_CONDITION_BASIC.join(','));

// 卡片刷新时间计算 sql：会议日程提前 10 分钟，日程过期，每天 0 点
const REFRESH_CARD_SQL: string = `SELECT remindTimer(MIN(min_time) * 1000) FROM (` +
  `SELECT MIN(end / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (end / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT MIN((begin - ${AgendaCardInfo.MINUTES_BEFORE_MEETING} * ${MILLS_PER_MINUTE}) / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (service_type IS NOT NULL AND service_type != '') ` +
  `AND ((begin - ${AgendaCardInfo.MINUTES_BEFORE_MEETING} * ${MILLS_PER_MINUTE}) / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT ABS(strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC')) + ` +
  `${MILLS_PER_DAY} / 1000 as min_time)`;

// 卡片日程数量统计，7天
const QUERY_AGENDA_NUM_SQL: string = AgendaCardDataProxyHelper.queryDaysCount(0, 6);

/**
 * 日程卡片生命周期处理 Ability
 */
export default class AgendaCardController4x4 implements FormExtensionCallback {
  public static FORM_NAME_4x4: string = 'AgendaCard4x4';

  onAddForm(context: Context, want: Want) {
    let temp = want.parameters;
    let subscriberId: string = '';
    let formId: string = '';
    let dimension: number = 0;
    if (temp) {
      subscriberId = temp[formInfo.FormParam.IDENTITY_KEY] as string
      formId = temp[formInfo.FormParam.IDENTITY_KEY] as string;
      dimension = temp[formInfo.FormParam.DIMENSION_KEY] as number;
    }
    Log.info(TAG, `onAddForm formId: ${formId} start`);

    const formData: Record<string, Object> = {};
    DeviceConfig.instance().init();
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    formData['deviceLayout'] = DeviceConfig.instance().config.deviceLayout;
    formData['needCommerce'] = DeviceConfig.instance().config.needCommerce;
    formData['formId'] = formId;
    formData['startOfWeek'] = viewModel.getSettingData().startOfWeek;
    formData['weekends'] = viewModel.getSettingData().weekends;
    const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
    formData['isAgreeStatement'] = isAgreeStatement;
    const isDoubleUpSingleAgreeStatement = MonthCardHandler.instance().getDoubleUpSingleAgreeStatement(formId);
    formData['isDoubleUpSingleAgreeStatement'] = isDoubleUpSingleAgreeStatement;
    formData['curMonthVM'] = JSON.stringify(viewModel.getCurMonthVM());
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    formData['subscriptionCalendar'] = viewModel.getSettingData().subscriptionCalendar;
    formData['currentJulianDay'] = currentJulianDay;
    Log.warn(TAG, `onAddForm formId: ${formId} isAgreeStatement= ${isAgreeStatement},` +
      `isDoubleUpSingleAgreeStatement= ${isDoubleUpSingleAgreeStatement},` +
      `currentJulianDay= ${currentJulianDay}`);
    const proxies: Array<formBindingData.ProxyData> = [
      {
        'key': PROXY_URI_CALENDAR,
        'subscriberId': subscriberId
      }
    ];

    this.reSetDelAndAddTemplate(context, subscriberId);
    let formBinding: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formBinding['proxies'] = proxies;
    this.reportFaStatistic('create', dimension);
    Log.info(TAG, `onAddForm formId: ${formId} end`);
    return formBinding;
  }

  /**
   * 用于注册数据代理
   * 说明：因onAddForm不支持异步，所以需要先注册一遍基础数据代理，然后异步查询出所有的Columns之后再重新注册新代理
   * @param context context
   * @param subscriberId 卡片唯一标识
   */
  async reSetDelAndAddTemplate(context: Context, subscriberId: string) {
    registerDataShareHelper(context, subscriberId,
      this.getDataShareTemplate(QUERY_VALID_AGENDA_SQL), MAX_RETRY_TIMES);

    const queryColumns = await getQueryTodayAgendaSql();
    const queryAgendaSql: string = queryValidAgendaSql(queryColumns);
    delAndAddDataShareHelper(context, subscriberId,
      this.getDataShareTemplate(queryAgendaSql), MAX_RETRY_TIMES);
  }

  /**
   * 获取数据代理参数
   * 说明：因onAddForm所以需要先注册一遍基础数据代理，然后查询出需要查询的Columns之后再重新注册新代理
   * @param querySql 数据代理的查询语句
   * @returns dataShare.Template
   */
  getDataShareTemplate(querySql: string): dataShare.Template {
    const template: dataShare.Template = {
      predicates: {
        'agendaObjList': querySql,
        'todayAgendaObjList': QUERY_TODAY_AGENDA_SQL,
        'dayAgendaNumInfo': QUERY_AGENDA_NUM_SQL
      },
      scheduler: REFRESH_CARD_SQL
    };
    return template;
  }

  onCastToNormalForm(context: Context, formId: string) {
  }

  reportFaStatistic(action: string, dimension: number, formId?: string) {
    let params: ReportHiEventParams = {
      FA_DIMENSION: dimension,
      FORM_ID: formId
    }
    if (action === 'create') {
      ReportUtil.reportStatisticEvent(statisticEvents.createDayFormDescriptionFa, params);
    } else if (action === 'update') {
      ReportUtil.reportStatisticEvent(behaviorEvents.cardRefresh, params);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.deleteDayFormDescriptionFa, params);
    }
  }

  onUpdateForm(context: Context, formId: string) {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let language = i18n.System.getSystemLocale();

    const cardInfo = FormInfoManager.getFormInfo(formId);
    this.reportFaStatistic('update', cardInfo?.formDimension as number, formId);

    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    const agendaRefreshStr = Math.random().toString();
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    Log.warn(TAG, `onUpdateForm formId: ${formId} julianDayOfNow= ${currentJulianDay}`)
    formProvider.updateForm(formId, formBindingData.createFormBindingData({
      'agendaRefresh': agendaRefreshStr,
      'curMonthVM': JSON.stringify(viewModel.getCurMonthVM()),
      'startOfWeek': viewModel.getSettingData().startOfWeek,
      'weekends': viewModel.getSettingData().weekends,
      'language': language,
      'currentJulianDay': currentJulianDay
    }));

    // 跨天刷新月视图
    // 防止息屏被拦截
    MonthCardHandler.instance().refreshCards(formId);
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>) {
  }

  onFormEvent(context: Context, formId: string, message: string) {
    Log.info(TAG, `onFormEvent formId: ${formId} start, message is ${message}`);
    if (!message) {
      return;
    }
    try {
      const msg: object = JSON.parse(message);
      const params: object = msg['params'];
      if (!params) {
        return;
      }
      if (params['message'] === CardAction.FINISH_FIRST_DATA_PROCESSING) {
        Log.info(TAG, 'setIsDataProcessedFirstTime')
        formProvider.updateForm(formId, formBindingData.createFormBindingData({
          'isDataProcessedFirstTime': true
        }));
      } else if (params['message'] === CardAction.REFRESH_MONTH_VIEW) {
        Log.warn(TAG, `onFormEvent formId: ${formId} receive refresh event.`)
        MonthCardHandler.instance().refreshCards(formId);
      }
    } catch (e) {
      Log.hilogError(TAG, 'onFormEvent error', e)
    }
    Log.info(TAG, `onFormEvent formId: ${formId} end`);
  }

  onRemoveForm(context: Context, formId: string) {
    Log.info(TAG, 'onRemoveForm formId:' + formId);
    const cardInfo = FormInfoManager.getFormInfo(formId);
    this.reportFaStatistic('delete', cardInfo?.formDimension as number);
  }

  onAcquireFormState(context: Context, want: Want) {
    return formInfo.FormState.READY;
  }
}
