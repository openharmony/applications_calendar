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
  Log,
  AgendaEventInfo,
  behaviorEvents,
  CommonInnerEvent,
  GlobalThis,
  MINUTES_PER_DAY,
  MINUTES_PER_HOUR,
  statisticEvents,
  CalendarContract,
  CalendarService,
  CommonService,
  ReminderService,
  EmptyUtils,
} from '@app/common';

import { FromType, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { emitter } from '@kit.BasicServicesKit';
import { CreateAgendaPageSource } from '../CreateAgenda/Constants';
import { resourceManager } from '@kit.LocalizationKit';
import { HashMap } from '@kit.ArkTS';

const TAG = 'AgendaOperateHelper';
const ACCOUNT_TYPE_EMAIL: string = 'email';

export class AgendaOperateHelper {
  /**
   * 分享日程
   *
   * @param agenda: 被分享日程
   * @param fromType: 来源入口
   * @param isCalledByRoot: 是否由PC端AgendaDetailRoot切换状态调用
   * @param shareAnchorViewId: 分享的viewId
   */
  public async shareAgenda(
    agenda: AgendaEventInfo,
    fromType: FromType,
    shareAnchorViewId: string
  ) {
    let params: ReportHiEventParams = {
      FROM_TYPE: fromType,
      TYPE: agenda.mImportantEventType
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDetailShare, params);
    emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
      data: {
        compId: shareAnchorViewId,
        eventIds: [agenda.mId]
      }
    })
    return true;
  }

  public static getShareableEvents(events: AgendaEventInfo[]) {
    if (EmptyUtils.isEmptyArray(events)) {
      Log.warn(TAG, `getShareableEvents events is empty`);
      return [];
    }
    let resultArray: number[] = [];
    events.forEach(event => {
      resultArray.push(event.mId);
    });
    return resultArray;
  }

  /**
   * 分享多个日程
   *
   * @param agenda: 被分享日程列表
   * @param fromType: 来源入口
   * @param isCalledByRoot: 是否由PC端AgendaDetailRoot切换状态调用
   * @param shareAnchorViewId: 分享的viewId
   */
  public async shareMultipleAgenda(
    agendaIds: number[],
    shareAnchorViewId: string
  ) {
    if (agendaIds.length < 1) {
      return;
    }
    emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
      data: {
        compId: shareAnchorViewId,
        eventIds: agendaIds
      }
    })
    return true;
  }

  /**
   * 拉起编辑非重复日程或重复日程所有实例的半模态
   *
   * @param agenda: 被编辑的日程
   */
  public editAgenda(agenda: AgendaEventInfo, isSubAbility: boolean = false) {
    ReportUtil.reportStatisticEvent(statisticEvents.agendaDetailGoToEditAgenda);
    let event = AgendaEventInfo.deepCloneAgendaEventInfo(agenda);
    const notifyEditEvent: (event: AgendaEventInfo) => void = () => {
      let eventData: emitter.EventData = {
        data: {
          'intent': CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE,
          'eventInfo': JSON.stringify(event),
          'isSubAbility': isSubAbility,
          'eventId': event.mId,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    }
    // 带着提醒传递，否则 createAgenda 里面没有checkValuesArray
    this.notifyEditEventWithReminder(event, notifyEditEvent);
    return true;
  }

  /**
   * 拉起编辑单个重复日程的半模态
   *
   * @param agenda: 被编辑的单个重复日程
   * @param instanceStartMills 被编辑日程实例的开始时间戳
   * @param instanceEndMills 被编辑日程实例的结束时间戳
   *
   */
  public editThisAgenda(agenda: AgendaEventInfo, instanceStartMills: number, instanceEndMills: number,
    isSubAbility: boolean = false) {
    ReportUtil.reportStatisticEvent(statisticEvents.agendaDetailGoToEditAgenda);
    let event = AgendaEventInfo.deepCloneAgendaEventInfo(agenda);
    const notifyEditEvent: (event: AgendaEventInfo) => void = () => {
      let eventData: emitter.EventData = {
        data: {
          'intent': CreateAgendaPageSource.EDIT_THIS_AGENDA,
          'eventInfo': JSON.stringify(event),
          'instanceStartMills': instanceStartMills,
          'instanceEndMills': instanceEndMills,
          'isSubAbility': isSubAbility,
          'eventId': event.mId,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    }
    // 带着提醒传递，否则 createAgenda 里面没有checkValuesArray
    this.notifyEditEventWithReminder(event, notifyEditEvent);
    return true;
  }

  /**
   * 拉起编辑当前单个重复日程及以后日程的半模态
   *
   * @param agenda: 被编辑的单个重复日程
   * @param instanceStartMills 被编辑日程实例的开始时间戳
   * @param instanceEndMills 被编辑日程实例的结束时间戳
   */
  public editThisAgendaAndBeyond(agenda: AgendaEventInfo, instanceStartMills: number, instanceEndMills: number,
    isSubAbility: boolean = false) {
    ReportUtil.reportStatisticEvent(statisticEvents.agendaDetailGoToEditAgenda);
    let event = AgendaEventInfo.deepCloneAgendaEventInfo(agenda);
    const notifyEditEvent: (event: AgendaEventInfo) => void = () => {
      let eventData: emitter.EventData = {
        data: {
          'intent': CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND,
          'eventInfo': JSON.stringify(event),
          'instanceStartMills': instanceStartMills,
          'instanceEndMills': instanceEndMills,
          'isSubAbility': isSubAbility,
          'eventId': event.mId,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    }
    this.notifyEditEventWithReminder(event, notifyEditEvent);
    return true;
  }

  public getResourceStr(resource: resourceManager.Resource, language: string): string {
    return GlobalThis.getResourceStr(resource, language);
  }

  public getPluralStr(resource: resourceManager.Resource, num: number, language: string): string {
    return GlobalThis.getPluralStr(resource, num, language);
  }

  /**
   * 发送事件通知搜索列表页软删除
   *
   * @param eventId: 日程id
   * @param displayStartMills: 日程开始时间戳
   */
  public eventToSoftDelete(eventId: number, displayStartMills: number) {
    const eventData: emitter.EventData = {
      data: {
        eventId,
        displayStartMills,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL }, eventData);
    return true;
  }

  // 带着提醒传递，否则 createAgenda 里面没有checkValuesArray
  private async notifyEditEventWithReminder(event: AgendaEventInfo, notifyEditEvent: Callback<AgendaEventInfo>) {
    await AgendaOperateHelper.getCheckValueForEdit(event);
    notifyEditEvent(event);
  }

  // 获取编辑用提醒列表
  public static async getCheckValueForEdit(event: AgendaEventInfo) {
    try {
      let reminders: CalendarContract.Reminders[] = await ReminderService.INSTANCE.queryReminderInfo(event.mId);
      if (reminders) {
        reminders = reminders.sort((a, b) => {
          return a.remindMinutes - b.remindMinutes;
        });
      }
      event.checkValuesArray = reminders;
    } catch (error) {
      Log.logErrorMsg(TAG, 'notifyEditEventWithReminder', error);
      event.checkValuesArray = [];
    }
  }
}