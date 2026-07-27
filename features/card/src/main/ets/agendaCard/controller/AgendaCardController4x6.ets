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
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  DeviceConfig,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_MINUTE,
  ReportUtil,
  statisticEvents
} from '@app/common';
import Want from '@ohos.app.ability.Want';
import formProvider from '@ohos.app.form.formProvider';
import { CardType, ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { MonthCardHandler } from '../../monthCard/controller/MonthCardHandler';
import { dsOptions, PROXY_URI, PROXY_URI_CALENDAR } from '../../utils/RegisterDataShareHelperUtils';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { i18n } from '@kit.LocalizationKit';
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardAction } from '../../common/CardAction'
import { CardDbUtils } from '../../common/CardDbUtils';
import { EVENTLOCATION_LIMIT_LENGTH, TITLE_LIMIT_LENGTH } from '../../utils/CardUtils';
import {
  CURRENT_TIME,
  CURRENT_UTC_TIME,
  QUERY_TODAY_AGENDA_SQL,
  START_OF_DAY_TIME,
  START_OF_DAY_UTC_TIME
} from '../../utils/UpdateSQLUtils';

const TAG: string = 'AgendaCardController4x6';

// 由于其他天查整天24小时的数据，20条担心不够，按规格一天35条限制查询数量，避免过多数据传递到卡片，导致超出卡片限制，出现空卡
const OTHER_DAY_LIMIT: number = 35;

const QUERY_CONDITION_BASE: string[] = [
  'Instances._id AS id',
  'event_id',
  'begin',
  'end',
  'startDay',
  'endDay',
  'startMinute',
  'endMinute',
  `SUBSTR(title, 1, ${TITLE_LIMIT_LENGTH}) AS title`,
  'allDay',
  'Events.creator',
  `SUBSTR(eventLocation, 1, ${EVENTLOCATION_LIMIT_LENGTH}) AS eventLocation`,
  'calendar_id',
  'calendar_color',
  'account_type',
  'service_verified',
  'service_type',
  `Instances.event_uuid`,
  `events.calendar_uuid`,
];

/**
 * 所有的Columns都需要从该方法获取
 * V1:新增附件字段attachment_count
 * @returns 所有需要查询的字段string
 */
async function getQueryConditionAll(): Promise<string> {
  const condition = [...QUERY_CONDITION_BASE];
  if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
    condition.push(`attachment_count`);
  }
  return condition.join(`,`);
}

/**
 * 查询距今start-end天的日程的前limit条
 * @param limit 限制查询条数
 * @param hasUri 是否查询uri字段
 * @param isStartNow 是否从当前时间查起，而不是0点起
 * @returns
 */
function queryOneDay(start: number, end: number, limit: number,
                     queryColumns: string, hasUri: boolean = false, isStartNow: boolean = false) {
  // 需要判断是否查询uri字段(该字段较长，为避免数据超限，需单独处理)
  return `SELECT * FROM (
    SELECT * FROM (
      SELECT
        ${queryColumns}
        ${hasUri ? ',service_cp_bz_uri ' : ',null as service_cp_bz_uri'}
      FROM
        Instances
      INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
      INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
      WHERE
        visible = 1
        AND (
          BEGIN < ${START_OF_DAY_TIME} + ${MILLS_PER_DAY} * ${end}
          AND ` +
    (isStartNow ?
      `END > ${CURRENT_TIME}` :
      `END > ${START_OF_DAY_TIME} + ${MILLS_PER_DAY} * ${start}`) +
    `)
        AND important_event_type = 0
        AND allDay = 1

      UNION ALL

      SELECT
        ${queryColumns}
        ${hasUri ? ',service_cp_bz_uri ' : ',null as service_cp_bz_uri'}
      FROM
        Instances
      INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
      INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
      WHERE
        visible = 1
        AND (
          BEGIN < ${START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY} * ${end}
          AND ` +
    (isStartNow ?
      `END > ${CURRENT_UTC_TIME}` :
      `END > ${START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY} * ${start}`) +
    `)
        AND important_event_type = 0
        AND allDay = 0
    )
    ORDER BY startDay,begin ASC
    LIMIT ${limit}
  )`;
}

/**
 * 查询当前天及前后六天日程
 * @param queryColumns 需要查询的Columns
 */
function queryWeekDay(queryColumns: string) {
  // 合并并去重
  let sql = 'SELECT DISTINCT * FROM ( ';
  // 前6天，每天查1条
  for (let i = -6; i <= -1; i++) {
    sql += queryOneDay(i, i + 1, 1, queryColumns);
    sql += ' UNION ALL ';
  }
  // 今天查20个,且需要uri字段
  sql += queryOneDay(0, 1, 35, queryColumns, true, false); // 查询今天的日程 限制放开到35
  // 后6天，每天查1条
  for (let i = 1; i <= 6; i++) {
    sql += ' UNION ALL ';
    sql += queryOneDay(i, i + 1, 1, queryColumns);
  }
  sql += ' ) ORDER BY startDay ASC ';
  return sql;
}

const QUERY_VALID_AGENDA_SQL: string = queryWeekDay(QUERY_CONDITION_BASE.join(','));

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

/**
 * 日程卡片生命周期处理 Ability
 */
export default class AgendaCardController4x6 implements FormExtensionCallback {
  public static FORM_NAME_4x6: string = 'AgendaCard4x6';

  onAddForm(context: Context, want: Want) {
    let params = want?.parameters;
    let subscriberId: string = '';
    let formId: string = '';
    let dimension: number = 0;
    if (params) {
      subscriberId = params[formInfo.FormParam.IDENTITY_KEY] as string
      formId = params[formInfo.FormParam.IDENTITY_KEY] as string;
      dimension = params[formInfo.FormParam.DIMENSION_KEY] as number;
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
    formData['currentJulianDay'] = currentJulianDay;
    Log.warn(TAG, `onAddForm formId: ${formId} isAgreeStatement= ${isAgreeStatement},` +
      `isDoubleUpSingleAgreeStatement= ${isDoubleUpSingleAgreeStatement},` +
      `currentJulianDay= ${currentJulianDay}`);
    Log.debug(TAG, 'onAddForm QUERY_VALID_AGENDA_SQL = ' + QUERY_VALID_AGENDA_SQL)
    const proxies: formBindingData.ProxyData[] = [
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

  // 方法重复，但是由于未知特性无法抽出公共函数，暂时留存，待后续解决
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

  /**
   * 用于注册数据代理
   * 说明：因onAddForm不支持异步，所以需要先注册一遍基础数据代理，然后异步查询出所有的Columns之后再重新注册新代理
   * @param context context
   * @param subscriberId 卡片唯一标识
   */
  async reSetDelAndAddTemplate(context: Context, subscriberId: string) {
    this.delAndAddTemplate(context, subscriberId, this.getDataShareTemplate(QUERY_VALID_AGENDA_SQL));

    const queryColumns = await getQueryConditionAll();
    const queryValidAgendaSql: string = queryWeekDay(queryColumns);
    this.delAndAddTemplate(context, subscriberId, this.getDataShareTemplate(queryValidAgendaSql));
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
      },
      scheduler: REFRESH_CARD_SQL
    };
    return template;
  }

  onCastToNormalForm(context: Context, formId: string) {
  }

  reportFaStatistic(action: string, dimension: number) {
    let params: ReportHiEventParams = {
      FA_DIMENSION: dimension
    }
    if (action === 'create') {
      ReportUtil.reportStatisticEvent(statisticEvents.createDayFormDescriptionFa, params);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.deleteDayFormDescriptionFa, params);
    }
  }

  onUpdateForm(context: Context, formId: string) {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let language = i18n.System.getSystemLocale();
    let params: ReportHiEventParams = {
      TYPE: CardType.AGENDA_CARD_4X6,
      FORM_ID: formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);

    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    const agendaRefreshStr = Math.random().toString();
    const currentJulianDay = FormUtils.getCurrentJulianDay();
    Log.warn(TAG, `onUpdateForm formId: ${formId} julianDayOfNow= ${currentJulianDay}`);
    formProvider.updateForm(formId, formBindingData.createFormBindingData({
      'agendaRefresh': agendaRefreshStr,
      'curMonthVM': JSON.stringify(viewModel.getCurMonthVM()),
      'startOfWeek': viewModel.getSettingData().startOfWeek,
      'weekends': viewModel.getSettingData().weekends,
      'language': language,
      'currentJulianDay': currentJulianDay
    }));
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>) {
  }

  async onFormEvent(context: Context, formId: string, message: string) {
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
      } else if (params['message'] === CardAction.SEARCH_AGENDA_4X6) {
        Log.info(TAG, 'CardAction SEARCH_AGENDA_4X6 start');
        // 增量日程数据
        let agendaAddedList: AgendaCardInfo[] = await CardDbUtils.queryAgendaByDay(context, params['julianDay'],
          OTHER_DAY_LIMIT);
        Log.info(TAG, `agendaAddedList.length=${agendaAddedList?.length}`);
        Log.debug(TAG, `agendaAddedList = ${JSON.stringify(agendaAddedList)}`);
        formProvider.updateForm(formId, formBindingData.createFormBindingData({
          'agendaAddedList': JSON.stringify(agendaAddedList)
        }));
      } else if (params['message'] === CardAction.REMOVE_ADDED_4X6) {
        Log.info(TAG, 'CardAction REMOVE_ADDED_4X6 start')
        // 移除缓存数据，避免重启场景一次性读入会超限
        let cleanName: string = params['name'];
        Log.info(TAG, 'clean bindingData:' + cleanName);
        let bindingData: string = '{"' + cleanName + '":"clean"}';
        formProvider.updateForm(formId, formBindingData.createFormBindingData(JSON.parse(bindingData)));
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
