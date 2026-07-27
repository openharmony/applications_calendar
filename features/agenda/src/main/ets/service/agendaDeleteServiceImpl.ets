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
import { AgendaDeleteService, AgendaEventInfo,
  CloudUtils,
  CommonInnerEvent, EventService,
  factory,
  isSyncAbleAccount,
  ServiceEnum } from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { addExDateToDb, updateUntilToDb } from '@app/feature.repeatrule';

const TAG = 'AgendaDeleteServiceImpl';

@factory(ServiceEnum.AGENDA_DELETE_SERVICE)
export class AgendaDeleteServiceImpl extends AgendaDeleteService {
  // 删除回调函数
  private callback: ((success: boolean) => void) | undefined = undefined;

  private eventToSoftDelete(eventId: number, displayStartMills: number) {
    const eventData: emitter.EventData = {
      data: {
        eventId,
        displayStartMills,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL }, eventData);
    return true;
  }

  public async addExclusiveToRepeatRule(eventId: number, timestamp: number) {
    let success = await addExDateToDb(eventId, timestamp);
    if (success) {
      this.eventToSoftDelete(eventId, timestamp); // 过滤删除的日程
      emitter.emit({ eventId: CommonInnerEvent.RESET_MONTH_AGENDA_BLOCK_FOCUS_PARAM });
    }
    if (this.callback) {
      this.callback(success);
      this.callback = undefined;
    }
  }

  public async updateEndTime(eventId: number, endtime: number) {
    let success = await updateUntilToDb(eventId, endtime);
    if (success) {
      emitter.emit({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE }); // 刷新列表
    }
    if (this.callback) {
      this.callback(success);
      this.callback = undefined;
    }
  }

  public async deleteEvent(eventId: number) {
    let deletedRows = await EventService.INSTANCE.deleteEventById(eventId);
    if (deletedRows > 0) {
      this.eventToSoftDelete(eventId, 0); // 过滤删除的单个日程, timestamp 设置为0不会触发过滤重复日程
      emitter.emit({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE }); // 刷新列表 TODO：jS 月视图监听该事件
    }
    if (this.callback) {
      this.callback(deletedRows > 0);
      this.callback = undefined;
    }
  }

  public getDeleteAgendaDialogTitle(title: string): ResourceStr {
    return $r('app.string.whether_to_delete', title);
  }

  notifyDeleteEventWithCallback(eventId: number, timestamp: number, callback: (success: boolean) => void,
    isMainAbility: boolean): void {
    this.notifyDeleteEvent(eventId, timestamp, isMainAbility);
    this.callback = callback;
  }

  public notifyDeleteEvent(eventId: number, timestamp: number, isMainAbility: boolean) {
    emitter.emit({ eventId: CommonInnerEvent.DELETE_AGENDA },
      { data: { 'eventId': eventId, 'timestamp': timestamp, 'isMainAbility': isMainAbility } }); // 通知主界面日程删除
    this.callback = undefined;
  }

  public getDeleteMessage(agenda: AgendaEventInfo | undefined, accountType: string) {
    if (!agenda) {
      return '';
    }
    if (isSyncAbleAccount('', accountType) && CloudUtils.isSupportCloudSync() &&
    CloudUtils.isCloudSyncOpened()) {
      return $r('app.string.delete_with_cloudDevices')
    } else {
      if (agenda.isImportantEvent()) {
        return $r('app.string.delete_important_event')
      } else {
        return $r('app.string.delete_this_event_title')
      }
    }
  }
}
