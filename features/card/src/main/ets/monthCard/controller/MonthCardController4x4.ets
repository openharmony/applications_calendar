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
  CalendarAccountType,
  CalendarContract,
  CalendarDate,
  CHINA_COUNTRY_CODE,
  CUSTOM_CHINA_COUNTRY_CODE,
  DateUtil,
  DeviceConfig,
  FoldScreenType,
  IMonthInfo,
  Log,
  MILLS_PER_DAY,
  ReportHiEventParams,
  ReportUtil,
  ThrottleFunction,
  traceEvents
} from '@app/common';
import Want from '@ohos.app.ability.Want';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import formProvider from '@ohos.app.form.formProvider';
import { CardAction } from '../../common/CardAction';
import { Direction } from '../common/MonthCardEnum'
import FormExtensionCallback from '@app/common/src/main/ets/card/FormExtensionCallback';
import { MonthCardHandler } from './MonthCardHandler';
import { CardType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { display } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { dataShare } from '@kit.ArkData';
import {
  delAndAddDataShareHelper,
  MAX_RETRY_TIMES,
  PROXY_URI_CALENDAR,
  registerDataShareHelper
} from '../../utils/RegisterDataShareHelperUtils';
import { HashMap } from '@kit.ArkTS';
import { FestivalAbbreviationMap } from '@app/common/src/main/ets/date/FestivalAbbreviationMap';

const TAG: string = '[MonthCard][MonthCardController4x4]';

// 只获取中国节假日数据
function queryHoliday(start: number, end: number, displayDate = 'now') {
  return `SELECT
 title,startDay,endDay
FROM
  Instances
  INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
  INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
WHERE
  visible = 1
  AND (
    BEGIN
        < strftime('%s', '${displayDate}', 'localtime', 'start of month') * 1000 + ${MILLS_PER_DAY} * ${end}
        AND
      END > strftime('%s', '${displayDate}', 'localtime', 'start of month') * 1000 + ${MILLS_PER_DAY} *  ${start}
      )
  AND important_event_type = ${CalendarContract.EventImportantType.HOLIDAY}
  AND Calendars.account_type = '${CalendarAccountType.HOLIDAY_ACCOUNT_TYPE}'
  AND (Calendars.account_name = '${CHINA_COUNTRY_CODE}' OR Calendars.account_name = '${CUSTOM_CHINA_COUNTRY_CODE}')`;
}

// 查询近1个月的日程
// 35天或42天，从每月1号开始，左最多补齐6天，右最多补齐36天
function queryHolidayDay(displayDate = 'now') {
  // 合并
  let sql = 'SELECT * FROM ( ';
  // 13天数量
  for (let i = -6; i <= 36; i++) {
    sql += queryHoliday(i, i + 1, displayDate);
    if (i != 36) {
      sql += ' UNION ALL ';
    }
  }
  sql += ' ) ORDER BY startDay ASC ';
  return sql;
}

const QUERY_HOLIDAY_SQL: string = queryHolidayDay();

/**
 * 查询displayDate当天的日程数量
 * @returns
 */
function queryOneDay(start: number, end: number, displayDate = 'now') {
  return `
    SELECT
      strftime('%s', '${displayDate}', 'localtime', 'start of month', 'UTC') * 1000 + ${MILLS_PER_DAY} * ${start} as startTimeOfDay,
      SUM(agendaNum) AS agendaNum
    FROM
      (-- 不加UTC查全天日程
        SELECT
          Count(*) AS agendaNum
        FROM
          Instances
          INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
          INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
        WHERE
          visible = 1
          AND (
            begin < strftime('%s', '${displayDate}', 'localtime', 'start of month') * 1000 + ${MILLS_PER_DAY} * ${end}
            AND
            end > strftime('%s', '${displayDate}', 'localtime', 'start of month') * 1000 + ${MILLS_PER_DAY} * ${start}
          )
          AND important_event_type = 0
          AND allDay = 1
        UNION ALL-- 加UTC查普通日程
        SELECT
          Count(*) AS agendaNum
        FROM
          Instances
          INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
          INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
          WHERE
          visible = 1
          AND (
            begin < strftime('%s', '${displayDate}', 'localtime', 'start of month', 'UTC') * 1000 + ${MILLS_PER_DAY} * ${end}
            AND
            end > strftime('%s', '${displayDate}', 'localtime', 'start of month', 'UTC') * 1000 + ${MILLS_PER_DAY} * ${start}
          )
          AND important_event_type = 0
          AND allDay = 0
     )`;
}

function getFestivalAbbreviation(): string {
  let festivalAbbreviationRecord: Record<string, string> = {};
  const festivalAbbreviationMap: HashMap<string, string> = FestivalAbbreviationMap.getInstance();
  for (let key of festivalAbbreviationMap.keys()) {
    festivalAbbreviationRecord[key] = festivalAbbreviationMap.get(key);
  }
  return JSON.stringify(festivalAbbreviationRecord);
}

// 查询近1个月的日程
// 35天或42天，从每月1号开始，左最多补齐6天，右最多补齐36天
function queryMonthDay(displayDate = 'now') {
  // 合并
  let sql = 'SELECT * FROM ( ';
  // 13天数量
  for (let i = -6; i <= 36; i++) {
    sql += queryOneDay(i, i + 1, displayDate);
    if (i != 36) {
      sql += ' UNION ALL ';
    }
  }
  sql += ' ) ORDER BY startTimeOfDay ASC ';
  return sql;
}

const QUERY_AGENDA_NUM_SQL: string = queryMonthDay();

// 卡片刷新时间计算 sql：日程过期;每天0点刷新
const REFRESH_CARD_SQL: string = `SELECT remindTimer(MIN(min_time) * 1000) FROM (` +
  `SELECT MIN(end / 1000) AS min_time FROM Instances INNER JOIN Events ` +
  `ON (Instances.event_uuid = Events.uuid) WHERE (end / 1000) > ABS(strftime('%s', datetime('now', 'localtime'), 'UTC')) ` +
  `UNION ` +
  `SELECT ABS(strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC')) + ` +
  `${MILLS_PER_DAY} / 1000 as min_time) `;

/**
 * 月视图卡片生命周期处理 Ability
 */
export default class MonthCardController4x4 implements FormExtensionCallback {
  public static FORM_NAME: string = 'MonthCard4x4';

  getDayAgendaNumInfoProxies(context: Context, want: Want) {
    const formIdKey: string = 'ohos.extra.param.key.form_identity';
    let params = want?.parameters;
    let subscriberId: string = '';
    if (params !== null && params !== undefined) {
      subscriberId = params[formIdKey] as string;
    }
    const template: dataShare.Template = {
      predicates: {
        'dayAgendaNumInfo': QUERY_AGENDA_NUM_SQL,
        'holidayInfo' : QUERY_HOLIDAY_SQL
      },
      scheduler: REFRESH_CARD_SQL
    };
    const proxies: formBindingData.ProxyData[] = [
      {
        'key': PROXY_URI_CALENDAR,
        'subscriberId': subscriberId
      }
    ];
    registerDataShareHelper(context, subscriberId, template, MAX_RETRY_TIMES);

    return proxies;
  }

  updateDayAgendaNumInfo(context: Context, formId: string, displayDate = 'now') {
    const template: dataShare.Template = {
      predicates: {
        'dayAgendaNumInfo': queryMonthDay(displayDate),
        'holidayInfo' : queryHolidayDay(displayDate)
      },
      scheduler: REFRESH_CARD_SQL
    };
    delAndAddDataShareHelper(context, formId, template, MAX_RETRY_TIMES);
  }

  onAddForm(context: Context, want: Want): formBindingData.FormBindingData {
    let temp = want.parameters;
    let formId: string = '';
    if (temp) {
      formId = temp[formInfo.FormParam.IDENTITY_KEY] as string;
    }
    Log.info(TAG, `onAddForm formId: ${formId} start`);

    const formData: Record<string, Object> = {};
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    hiTraceMeter.startTrace(traceEvents.allMonthVM, 0);
    formData['cardSingleMonthVMJSONStr'] = JSON.stringify(viewModel.getAllMonthVM());
    hiTraceMeter.finishTrace(traceEvents.allMonthVM, 0);
    formData['deviceLayout'] = DeviceConfig.instance().config.deviceLayout;
    formData['startOfWeek'] = viewModel.getSettingData().startOfWeek;
    formData['weekends'] = viewModel.getSettingData().weekends;
    formData['formId'] = formId;
    formData['displayDate'] = new CalendarDate().getTime();
    formData['isAgreeStatement'] = viewModel.getSettingData().isAgreeStatement;
    formData['festivalAbbreviation'] = getFestivalAbbreviation();
    const julianDayOfNow = FormUtils.getCurrentJulianDay();
    formData['currentJulianDay'] = julianDayOfNow;
    Log.warn(TAG, `onAddForm formId: ${formId} julianDayOfNow= ${julianDayOfNow}`);
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

    const formBinding: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formBinding['proxies'] = this.getDayAgendaNumInfoProxies(context, want);

    return formBinding;
  }

  onCastToNormalForm(context: Context, formId: string): void {
  }

  onUpdateForm(context: Context, formId: string): void {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let params: ReportHiEventParams = {
      TYPE: CardType.MONTH_CARD_4X4,
      FORM_ID: formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);

    // 跨天刷新，直接调用卡片刷新
    // 调用postCard刷新，息屏会被拦截
    MonthCardHandler.instance().refreshCards(formId);
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>): void {
  }

  getCurMonthDisplayDate(date: CalendarDate, direction = 0): string {
    const result: IMonthInfo = DateUtil.getOffsetMonthInfo({
      year: date.getFullYear(),
      month: date.getMonth()
    }, direction);
    const addZero = (num: number): string => ('00' + num).slice(-2);

    // 重置到1号，防止1月31 ->2月31出现异常
    return [result.year, addZero(result.month + 1), '01'].join('-');
  }

  switchToPreMonthHandler(context: Context, formId: string, formData: Record<string, Object>, displayDate: number) {
    ThrottleFunction.instance().debounceInstant(TAG + 'switchToPreMonthHandler', () => {
      const now = new CalendarDate().getTime();
      const viewModel = MonthCardHandler.instance().getMonthCardVM();

      Log.warn(TAG, `switchToPreMonthHandler. now= ${now}`);
      // 此处增加now, 为了实时监听到数据响应，后续会做特殊处理，详见后续处理：JSON.parse(preMonthVMJSONStr.substring(LENGTH_OF_TIME))
      formData['preMonthVMJSONStr'] = now + JSON.stringify(viewModel.getSingleMonthVM(new CalendarDate(displayDate), Direction.PRE_MONTH));
      const curMonthDisplayDate = this
        .getCurMonthDisplayDate(new CalendarDate(displayDate), Direction.PRE_MONTH);
      this.updateDayAgendaNumInfo(context, formId, curMonthDisplayDate);
      formData['festivalAbbreviation'] = getFestivalAbbreviation();
      formData['displayDate'] = new CalendarDate(curMonthDisplayDate).getTime();
      // 降低左右点击切换延迟，提升流畅度
    }, 100);
  }

  switchToNextMonthHandler(context: Context, formId: string, formData: Record<string, Object>, displayDate: number) {
    ThrottleFunction.instance().debounceInstant(TAG + 'switchToNextMonthHandler', () => {
      const now = new CalendarDate().getTime();
      const viewModel = MonthCardHandler.instance().getMonthCardVM();

      Log.warn(TAG, `swithToNextMonthHandler. now= ${now}`);
      // 此处增加now, 为了实时监听到数据响应，后续会做特殊处理，详见后续处理：JSON.parse(preMonthVMJSONStr.substring(LENGTH_OF_TIME))
      formData['nextMonthVMJSONStr'] = now + JSON.stringify(viewModel.getSingleMonthVM(new CalendarDate(displayDate), Direction.NEXT_MONTH));
      const curMonthDisplayDate = this
        .getCurMonthDisplayDate(new CalendarDate(displayDate), Direction.NEXT_MONTH);
      this.updateDayAgendaNumInfo(context, formId, curMonthDisplayDate);
      formData['festivalAbbreviation'] = getFestivalAbbreviation();
      formData['displayDate'] = new CalendarDate(curMonthDisplayDate).getTime();
    }, 100);
  }

  refreshAgendaDotHandler(context: Context, formId: string, formData: Record<string, Object>) {
    ThrottleFunction.instance().debounceInstant(TAG + 'refreshAgendaDotHandler', () => {
      this.updateDayAgendaNumInfo(context, formId, 'now');
      formData['displayDate'] = new CalendarDate().getTime();
    });
  }

  onFormEventDefaultHandler(formId: string) {
    ThrottleFunction.instance().debounceInstant(TAG + 'onFormEventDefaultHandler', () => {
      MonthCardHandler.instance().refreshCards(formId);
    });
  }

  onFormEvent(context: Context, formId: string, message: string): void {
    Log.warn(TAG, `onFormEvent formId: ${formId} start, message is ${message}`);

    const params: ParamsType = JSON.parse(message);
    const formData: Record<string, Object> = {};
    try {
      if (params.message === CardAction.SWITCH_TO_PRE_MONTH) {
        Log.info(TAG, `formId: ${formId} onFormEvent: SWITCH_TO_PRE_MONTH`);
        this.switchToPreMonthHandler(context, formId, formData, params.displayDate);
      } else if (params.message === CardAction.SWITCH_TO_NEXT_MONTH) {
        Log.info(TAG, `formId: ${formId} onFormEvent: SWITCH_TO_NEXT_MONTH`);
        this.switchToNextMonthHandler(context, formId, formData, params.displayDate);
      } else if (params.message === CardAction.REFRESH_AGENDA_DOT) {
        Log.info(TAG, `formId: ${formId} onFormEvent: REFRESH_AGENDA_DOT`);
        this.refreshAgendaDotHandler(context, formId, formData)
      } else {
        // 继续下发空 formData 会覆盖卡片已有绑定数据，导致卡片闪烁或短暂消失。
        Log.info(TAG, `formId: ${formId} onFormEvent: ${params.message}`);
        this.onFormEventDefaultHandler(formId);
        return;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'onFormEvent', err);
    }
    formData['currentJulianDay'] = FormUtils.getCurrentJulianDay();
    this.reportSwitchMonths(params.message);
    formProvider.updateForm(formId, formBindingData.createFormBindingData(formData)).then(() => {
      Log.log(TAG, 'onFormEvent Update Success, and formId is ' + formId);
    }).catch((err: Error) => {
      Log.error(TAG, `Failed to updateForm. formId is ${formId} , error: ${err.message}`);
    });
    Log.info(TAG, `onFormEvent formId: ${formId} end`);
  }

  /**
   * 切换月份打点
   * @param action
   */
  reportSwitchMonths(action: number) {
    let params: ReportHiEventParams = {
      ACTION: action
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.monthCardSwitchMonths, params);
  }

  onRemoveForm(context: Context, formId: string): void {
  }

  onAcquireFormState(context: Context, want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}

export interface ParamsType {
  message: number,
  params: Params,
  action: string,
  displayDate: number
}

export interface Params {
  message: number,
  displayDate: number
}



