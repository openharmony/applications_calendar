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
import {
  behaviorEvents,
  DeviceConfig,
  FoldScreenType,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  ReportUtil,
  statisticEvents
} from '@app/common';
import Want from '@ohos.app.ability.Want';
import formInfo from '@ohos.app.form.formInfo';
import FormExtensionCallback from '@app/common/src/main/ets/card/FormExtensionCallback';
import dataShare from '@ohos.data.dataShare';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import { CardType, ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { MonthCardHandler } from '../../monthCard/controller/MonthCardHandler';
import {
  PROXY_URI_CALENDAR,
  PROXY_URI,
  dsOptions,
  delAndAddDataShareHelper,
  MAX_RETRY_TIMES
} from '../../utils/RegisterDataShareHelperUtils';
import { i18n } from '@kit.LocalizationKit';
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { display } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import {
  FORMAT_START_OF_DAY_UTC_TIME,
  FORMAT_CURRENT_UTC_TIME,
  QUERY_CONDITION_BASIC,
  QUERY_TODAY_AGENDA_SQL,
  getQueryTodayAgendaSql
} from '../../utils/UpdateSQLUtils';
import { CardAction } from '../../common/CardAction';
import { AgendaCardDataProxyHelper } from './AgendaCardDataProxyHelper';

const TAG: string = 'AgendaCardController2x2';

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
        BEGIN < ${FORMAT_START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY} * 2
        AND
        END > ${FORMAT_CURRENT_UTC_TIME}
      )
      AND important_event_type = 0
    ORDER BY startDay, BEGIN ASC
    LIMIT 20`;
}

// 卡片日程数据查询 sql: strftime获取的是秒级别的时间戳    --  计算后天23:59:59之前的日程数量
const QUERY_VALID_AGENDA_SQL_2X2: string = queryValidAgendaSql(QUERY_CONDITION_BASIC.join(','));

// 卡片刷新时间计算 sql：日程过期; 会议日程提前 10 分钟; 会议日程开始时间; 每天0点、18点刷新
const REFRESH_CARD_SQL: string = `SELECT remindTimer(MIN(min_time) * 1000) FROM (` +
  `SELECT MIN(end / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (end / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT MIN((begin - ${AgendaCardInfo.MINUTES_BEFORE_MEETING} * ${MILLS_PER_MINUTE}) / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (service_type IS NOT NULL AND service_type != '') ` +
  `AND ((begin - ${AgendaCardInfo.MINUTES_BEFORE_MEETING} * ${MILLS_PER_MINUTE}) / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT MIN(begin / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (service_type IS NOT NULL AND service_type != '') ` +
  `AND (begin / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT CASE WHEN strftime('%H', 'now', 'localtime') < '18' THEN ABS(strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC')) + ` +
  `${MILLS_PER_HOUR} * 18 / 1000 ELSE ABS(strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC')) + ` +
  `${MILLS_PER_DAY} / 1000 END as min_time)`;

// 卡片日程数量统计，今明两天
const QUERY_AGENDA_NUM_SQL: string = AgendaCardDataProxyHelper.queryDaysCount(0, 1);

export enum ActionType {
  CREATE = 'create',
  DELETE = 'delete'
}

export default class AgendaCardController2x2 implements FormExtensionCallback {
  public static readonly FORM_NAME_2X2: string = 'AgendaCard2x2';

  onAddForm(context: Context, want: Want) {
    const formIdKey: string = 'ohos.extra.param.key.form_identity';
    let temp = want.parameters;
    let subscriberId: string = '';
    let formId: string = '';
    if (temp !== null && temp !== undefined) {
      subscriberId = temp[formIdKey] as string;
      formId = temp[formInfo.FormParam.IDENTITY_KEY] as string;
    }
    Log.info(TAG, `onAddForm formId: ${formId} start`);

    const proxies: Array<formBindingData.ProxyData> = [
      {
        'key': PROXY_URI_CALENDAR,
        'subscriberId': subscriberId
      }
    ];
    this.reSetDelAndAddTemplate(context, subscriberId);
    const formData: Record<string, Object> = {};
    DeviceConfig.instance().init();
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    formData['deviceLayout'] = DeviceConfig.instance().config.deviceLayout;
    formData['needCommerce'] = DeviceConfig.instance().config.needCommerce;
    formData['isIntent'] = false;
    formData['formId'] = formId;
    formData['startOfWeek'] = viewModel.getSettingData().startOfWeek;
    formData['weekends'] = viewModel.getSettingData().weekends;
    const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
    formData['isAgreeStatement'] = isAgreeStatement;
    const isDoubleUpSingleAgreeStatement = MonthCardHandler.instance().getDoubleUpSingleAgreeStatement(formId);
    formData['isDoubleUpSingleAgreeStatement'] = isDoubleUpSingleAgreeStatement;
    formData['timeZone'] = viewModel.getSettingData().timeZone;
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    formData['subscriptionCalendar'] = viewModel.getSettingData().subscriptionCalendar;
    formData['currentJulianDay'] = currentJulianDay;
    Log.warn(TAG, `onAddForm formId: ${formId} isAgreeStatement= ${isAgreeStatement},` +
      `isDoubleUpSingleAgreeStatement= ${isDoubleUpSingleAgreeStatement},` +
      `currentJulianDay= ${currentJulianDay}`);

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
    let formBinding: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formBinding['proxies'] = proxies;
    this.reportFaStatistic(formId, ActionType.CREATE);
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
    this.delAndAddTemplate(context, subscriberId,
      this.getDataShareTemplate(QUERY_VALID_AGENDA_SQL_2X2));

    const queryColumns = await getQueryTodayAgendaSql();
    const queryValidAgendaSql2x2 = queryValidAgendaSql(queryColumns);
    this.delAndAddTemplate(context, subscriberId,
      this.getDataShareTemplate(queryValidAgendaSql2x2));
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

  delAndAddTemplate(context: Context, subscriberId: string, template: dataShare.Template) {
    try {
      dataShare.createDataShareHelper(context, PROXY_URI, dsOptions).then((dataShareHelper) => {
        if (dataShareHelper) {
          Log.info(TAG, 'delDataShareHelper DataShare createDataShareHelper, subscriberId ' + subscriberId);
          dataShareHelper.delTemplate(PROXY_URI_CALENDAR, subscriberId);
          Log.info(TAG, 'delDataShareHelper addTemplate  init dataShareHelper success!');
          dataShareHelper.addTemplate(PROXY_URI_CALENDAR, subscriberId, template);
        } else {
          Log.error(TAG, 'delDataShareHelper init dataShareHelper failed and dataShareHelper is null!');
        }
      }).catch((err: Error) => {
        Log.logErrorMsg(TAG, 'delDataShareHelper init orientation settings DataShare delTemplate error', err);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'delDataShareHelper init orientation settings DataShare delTemplate catch error', err);
    }
  }

  onCastToNormalForm(context: Context, formId: string) {
  }

  onUpdateForm(context: Context, formId: string, wantParams?: Record<string, Object>) {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let language = i18n.System.getSystemLocale();

    let params: ReportHiEventParams = {
      TYPE: CardType.AGENDA_CARD_2X2,
      FORM_ID: formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);
    let agendaRefreshStr = Math.random().toString();
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    Log.warn(TAG, `onUpdateForm formId: ${formId} julianDayOfNow= ${currentJulianDay}`);
    formProvider.updateForm(formId, formBindingData.createFormBindingData({
      'agendaRefresh': agendaRefreshStr,
      'language': language,
      'currentJulianDay': currentJulianDay
    }));
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);
  }

  reportFaStatistic(formId: string, action: ActionType) {
    let params: ReportHiEventParams = {
      FA_DIMENSION: formInfo.FormDimension.Dimension_2_2
    };
    if (action === ActionType.CREATE) {
      ReportUtil.reportStatisticEvent(statisticEvents.createDayFormDescriptionFa, params);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.deleteDayFormDescriptionFa, params);
    }
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
      if (params['message'] === CardAction.REFRESH_TIME_ZONE) {
        Log.warn(TAG, `onFormEvent formId: ${formId} receive refresh event.`);
        const viewModel = MonthCardHandler.instance().getMonthCardVM();
        formProvider.updateForm(formId, formBindingData.createFormBindingData({
          'timeZone': viewModel.getSettingData().timeZone
        }));
      }
    } catch (e) {
      Log.hilogError(TAG, 'onFormEvent error', e);
    }
    Log.info(TAG, `onFormEvent formId: ${formId} end`);
  }

  onRemoveForm(context: Context, formId: string) {
    Log.info(TAG, `onRemoveForm formId: ${formId}`);
    this.reportFaStatistic(formId, ActionType.DELETE);
  }

  onAcquireFormState(context: Context, want: Want) {
    return formInfo.FormState.READY;
  }
}