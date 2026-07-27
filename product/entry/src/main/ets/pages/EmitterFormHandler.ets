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
import { emitter } from '@kit.BasicServicesKit';
import {
  AgendaEventInfo,
  behaviorEvents,
  CalendarDate,
  CommonInnerEvent,
  DateUtil,
  EmptyUtils,
  EventService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPathManager,
  NavPathName,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceEnum,
  ServiceManager,
  SourceTypeEnum
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { uri } from '@kit.ArkTS';
import { Want } from '@kit.AbilityKit';
import { ImportExportService, ImportVcsCallBack } from '@app/feature.importexport';
import { AGENDA_SEARCH_DATE_BEGIN, AGENDA_SEARCH_DATE_END } from '@app/common/src/main/ets/agenda/Constants';


const TAG = 'EmitterFormHandler';

const DETAIL_WANT_PARAM_ID: string = 'event_id';

const DETAIL_WANT_PARAM_START_TIME: string = 'start';

const DETAIL_WANT_PARAM_END_TIME: string = 'end';

const SWITCH_ON: number = 1;

export type ActionType = 'CLICK_MONTH_FORM_HEADER' | 'CLICK_AGENDA_DETAIL' | 'CLICK_CREATE_EVENT'
  | 'SHARE_PUSH' | 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW';

export class EmitterFormHandler {
  private static _instance: EmitterFormHandler = new EmitterFormHandler();

  static instance(): EmitterFormHandler {
    return EmitterFormHandler._instance;
  }

  //卡片相关响应事件
  private eventFormHandler: () => void = (): void => {
  };

  /**
   * 监听事件
   */
  emitterForm(): void {
    this.eventFormHandler = () => {
      Log.log(TAG, 'emitterForm success');
      const temp: Want | null = GlobalThis.getInstance().abilityWant;
      if (temp && temp.parameters) {
        this.parseWantParams(temp.parameters.action as ActionType, temp.parameters as Object as ParametersInter);
      }
    }
    emitter.on({ eventId: CommonInnerEvent.EVENT_FORM }, this.eventFormHandler);
  }

  unEmitterForm(): void {
    emitter.off(CommonInnerEvent.EVENT_FORM, this.eventFormHandler);
  }

  /**
   * 解析want携带的数据
   *
   * @param action 自定义action
   * @param parameters want参数
   */
  async parseWantParams(action: ActionType | undefined, parameters: ParametersInter | undefined): Promise<void> {
    Log.info(TAG, `form event action: ${action}`);
    if (this.tryHandleShare(GlobalThis.getInstance().abilityWant)) {
      return;
    }
    if (await this.jumpToAgendaDetail(GlobalThis.getInstance().abilityWant)) {
      return;
    }
    switch (action) {
      case 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW': {
        if (!parameters || !parameters.startTimestamp) {
          Log.error(TAG, 'parameters is Illegal! Pay Attention To Source Date In Agenda Preview!');
          break;
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.clickPreviewJumpToCalendar);
        let timeStamp = Number.parseInt(parameters.startTimestamp);
        if (isNaN(timeStamp)) {
          Log.warn(TAG, `parameters.startTimestamp is not a valid number: ${parameters.startTimestamp}`);
          timeStamp = Date.now();
        }
        if (new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime() > timeStamp ||
          new CalendarDate(AGENDA_SEARCH_DATE_END).getTime() < timeStamp) {
          Log.info(TAG, 'jump by preview timeStamp exceeding the time limit ')
          timeStamp = Date.now();
        }
        const desDate = new CalendarDate(timeStamp);
        parameters.year = desDate.getFullYear();
        parameters.month = desDate.getMonth();
        parameters.day = desDate.getDate();
        if (await this.jumpToMonth(parameters)) {
          Log.warn(TAG, 'parameters! Pay Attention To Source Date In Agenda Preview!');
          return;
        }
      }
      case 'CLICK_MONTH_FORM_HEADER': {
        if (!parameters) {
          Log.error(TAG, 'parameters is Illegal! Pay Attention To Source Date!');
          break;
        }
        if (await this.jumpToMonth(parameters)) {
          Log.warn(TAG, 'parameters! Pay Attention To Source Date!');
          return;
        }
        break;
      }
      case 'CLICK_AGENDA_DETAIL': {
        Log.info(TAG, 'CLICK_AGENDA_DETAIL');
        const action: string | undefined = parameters?.action;
        const id: number | undefined = parameters?.id;
        const instanceStartMills: number | undefined = parameters?.instanceStartMills;
        if (id === undefined || id <= 0) {
          // 默认值
          if (await this.jumpToMonth(parameters)) {
            return;
          }
        }
        Log.info(TAG, `parameters.action = ${parameters?.action}, id = ${parameters?.id}`);
        const param: Record<string, number | string | AgendaEventInfo | undefined> = {};
        param.action = action;
        param.id = id;
        param.instanceStartMills = instanceStartMills;
        if (parameters?.holidayInfo) {
          try {
            param.holidayInfo = JSON.parse(parameters.holidayInfo);
          } catch (error) {
            Log.logErrorMsg(TAG, 'JSON.parse(parameters.holidayInfo)', error);
          }
        }
        param.instanceEndMills = parameters?.instanceEndMills;
        // 检查 path 堆栈中栈顶是不是 AGENDA_DETAIL
        const pathStack = NavPathManager.getInstance().getRouter(RouterName.ENTRY_HAP);
        if (!pathStack) {
          break;
        }
        let pathNames = pathStack.getAllPathName();
        if (pathNames.length > 0) {
          let topPathName = pathNames[pathNames.length - 1]
          // 如果是栈顶是AGENDA_DETAIL，不再PUSH
          if (topPathName === NavPathName.AGENDA_DETAIL) {
            emitter.emit({ eventId: CommonInnerEvent.EVENT_FORM_DETAIL }, param)
            break;
          }
        }
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_DETAIL,
          routerName: RouterName.ENTRY_HAP,
          param: param,
          animated: false
        });
        break;
      }
      default:
        break;
    }
  }

  /**
   * 跳转到月视图
   *
   * @param parameters want参数
   */
  private async jumpToMonth(parameters: ParametersInter | undefined): Promise<boolean> {
    if (!parameters) {
      return false;
    }

    NavPathManager.getInstance().clear(RouterName.ENTRY_HAP);
    const currentDate = new CalendarDate();
    const year = parameters.year !== undefined ? parameters.year : currentDate.getFullYear();
    const month = parameters.month !== undefined ? parameters.month : currentDate.getMonth();
    const day = parameters.day !== undefined ? parameters.day : currentDate.getDate();
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, DateUtil.dateToStamp(year, month, day));
    // 额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    return true;
  }

  private tryHandleShare(abilityWant: Want | null): boolean {
    if (!abilityWant) {
      Log.warn(TAG, `tryHandleShare abilityWant is null`);
      return false;
    }
    if (!abilityWant.uri) {
      Log.debug(TAG, `tryHandleShare abilityWant uri null`);
      return false;
    }
    if (!abilityWant.uri.endsWith('.vcs')) {
      Log.info(TAG, `tryHandleShare uri is not vcs`);
      return false;
    }
    Log.info(TAG, `tryHandleShare uri vcs need handle`);
    this.doImport(abilityWant.uri);
    return true;
  }

  private async doImport(uri: string): Promise<boolean> {
    try {
      let service = await ServiceManager.getInstance()
        .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
      service?.import(uri, ImportVcsCallBack.getInstance());
      return true;
    } catch (error) {
      Log.logErrorMsg(TAG, 'doImport', error);
      return false;
    }
  }

  /**
   * 尝试解析通知里的Uri 跳转到日程详情,目前不支持循环日程,需要通知代理处理
   * calendar://com.openharmony.calendar?event_id=${notificationInfo.eventId}
   * @param abilityWant
   * @return 是否处理 abilityWant
   */
  private async jumpToAgendaDetail(abilityWant: Want | null): Promise<boolean> {
    if (!abilityWant?.uri || EmptyUtils.isEmptyString(abilityWant?.uri, true)) {
      Log.warn(TAG, `tryJumpToAgendaDetail uri is null`);
      return false;
    }
    try {
      const agendaUri: uri.URI = new uri.URI(abilityWant?.uri);
      // calendarDate 通知里的uri 的协议格式
      if ('calendar' != agendaUri.scheme || 'com.openharmony.calendar' != agendaUri.host) {
        return false;
      }
      const urlParams: string[] = agendaUri.query.split('&');
      const jumpParam: Record<string, number | string> = {};
      this.parseJumpEventDetailParams(urlParams, jumpParam);

      return await this.jumpAgendaDetail(jumpParam);
    } catch (err) {
      Log.logErrorMsg(TAG, `JumpToAgendaDetail uri is ${abilityWant?.uri} illeagl`, err);
      return false;
    }
  }

  public parseJumpEventDetailParams(urlParams: string[], jumpParam: Record<string, number | string>): void {
    if (EmptyUtils.isEmptyArray(urlParams)) {
      return;
    }
    for (let element of urlParams) {
      const keyValue: string[] = element.split('=');
      if (EmptyUtils.isEmptyArray(keyValue) || keyValue.length <= 1) {
        continue;
      }
      try {
        const key = keyValue[0];
        const value = keyValue[1];
        switch (key) {
          case DETAIL_WANT_PARAM_ID:
            Log.info(TAG, `tryJumpToAgendaDetail eventId is ${keyValue[1]}`);
            const id = Number.parseInt(value);
            if (!isNaN(id)) {
              jumpParam.id = id;
            }
            break;
          case DETAIL_WANT_PARAM_START_TIME:
            const instanceStartMills = Number.parseInt(value);
            if (!isNaN(instanceStartMills)) {
              jumpParam.instanceStartMills = instanceStartMills;
            }
            break;
          case DETAIL_WANT_PARAM_END_TIME:
            const instanceEndMills = Number.parseInt(value);
            if (!isNaN(instanceEndMills)) {
              jumpParam.instanceEndMills = instanceEndMills;
            }
            break;
          default:
            Log.info(TAG, `tryJumpToAgendaDetail get unknown key ${key}`);
            break;
        }
      } catch (error) {
          Log.logErrorMsg(TAG, 'parseJumpEventDetailParams', error);
      }
    }
  }

  private async jumpAgendaDetail(jumpParam: Record<string, number | string>): Promise<boolean> {
    if (!jumpParam.id && jumpParam.id !== 0) {
      return false;
    }
    // 裁剪日程共享功能 - 直接作为普通日程处理
    if (jumpParam.id !== undefined && jumpParam.id > 0) {
      return this.jumpCustomAgenda(jumpParam);
    }
    return false;
  }

  private jumpCustomAgenda(jumpParam: Record<string, string | number>): boolean {
    NavPathManager.getInstance().replacePathByName({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: jumpParam
    }, false);
    ReportUtil.reportBehaviorEvent(behaviorEvents.notificationGoToAgendaDetail);
    Log.info(TAG, 'send to agenda detail');
    return true;
  }
}

export interface ParametersInter {
  startTimestamp?: string;
  year: number;
  month: number;
  day: number;
  action: string | ActionType;
  id: number;
  faType: string;
  dimension: string;
  holidayInfo: string;
  instanceStartMills: number;
  instanceEndMills: number;
}
