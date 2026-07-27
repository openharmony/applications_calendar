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

import { ReminderRepository } from '../repo/ReminderRepository';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Log } from '../../default/common/Log';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import HashMap from '@ohos.util.HashMap';
import { EmptyUtils } from '../../util/EmptyUtils';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '../../default/common/TraceEvents';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';

const TAG = 'ReminderService';

export class ReminderService {
  static readonly INSTANCE: ReminderService = new ReminderService();
  public repo: ReminderRepository;

  private constructor() {
    this.repo = new ReminderRepository;
  }

  /**
   * 更新提醒，使用先删除所有提醒，再添加提醒的形式
   *
   * @param eventId 日程id
   * @param checkValuesArray 提醒时间
   * @param initReminders 初始日程提醒时间数量
   * @return 是否成功
   */
  async updateReminderByReplace(eventId: number, checkValuesArray: CalendarContract.Reminders[], initReminders: number): Promise<boolean> {
    try {
      let rowsDeleted = 0;
      //如果原始日程没有提醒时间，无需删除
      if (initReminders !== 0) {
        rowsDeleted = await this.deleteReminderByEventId(eventId);
      }
      if (rowsDeleted >= 0 && checkValuesArray?.length === 0) {
        Log.info(TAG, 'checkValuesArray?.length = 0');
        // 提醒列表长度为 0 直接返回
        return true;
      } else if (rowsDeleted >= 0 && checkValuesArray?.length > 0) {
        const isSucceed: boolean = await this.insertReminderArray(eventId, checkValuesArray);
        Log.log(TAG, 'updateReminder checkValuesArray length ' + checkValuesArray?.length + ', eventId: ' + eventId);
        return isSucceed;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'updateReminderByReplace', err);
      SqlFaultHandle.updateSqlFail(err?.message, TAG)
    }
    return false;
  }

  async insertReminderArray(eventId: number, checkValuesArray: CalendarContract.Reminders[]): Promise<boolean> {
    if (!checkValuesArray || checkValuesArray === undefined) {
      Log.error(TAG, 'CheckValuesArray is null');
      return false;
    }
    try {
      for (let reminder of checkValuesArray) {
        reminder.eventId = eventId;
        let reminderId: number = await this.insertReminder(reminder);
        if (reminderId <= 0) {
          return false;
        }
      }
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'insertReminderArray', err);
      SqlFaultHandle.insertSqlFail(err?.message, TAG)
      return false;
    }
  }


  async queryReminderInfoByEventIds(eventIds: Array<number>): Promise<HashMap<number, Array<CalendarContract.Reminders>>> {
    const resultMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
    if (EmptyUtils.isEmptyArray(eventIds)) {
      Log.warn(TAG, `queryReminderInfoByEventIds eventIds is Empty`);
      return resultMap;
    }
    const columnArray: Array<string> = [
      CalendarContract.RemindersColumns.ID as string,
      CalendarContract.RemindersColumns.EVENT_ID as string,
      CalendarContract.RemindersColumns.REMIND_MINUTES as string,
      CalendarContract.RemindersColumns.REMIND_TYPE as string
    ];
    const resultSet = await this.repo.queryReminderByEventIds(eventIds, columnArray);

    if (!resultSet) {
      Log.warn(TAG, `queryReminderInfoByEventIds  resultSet is null`);
      return resultMap;
    }
    try {
      if (resultSet.rowCount <= 0) {
        Log.warn(TAG, `queryReminderInfoByEventIds  count is ${resultSet.rowCount}`);
        return resultMap;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, `queryReminderInfoByEventIds goToFirstRow false`);
        return resultMap;
      }
      do {
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.id = DataShareResultUtil.getColumnLongData(resultSet, '_id', 0);
        reminder.eventId = DataShareResultUtil.getColumnLongData(resultSet, 'event_id', 0);
        reminder.remindMinutes = DataShareResultUtil.getColumnLongData(resultSet, 'minutes', 0);
        reminder.remindType = DataShareResultUtil.getColumnLongData(resultSet, 'method', 0);
        let result: Array<CalendarContract.Reminders> | undefined = undefined;
        if (resultMap.hasKey(reminder.eventId)) {
          result = resultMap.get(reminder.eventId);
        } else {
          result = new Array();
          resultMap.set(reminder.eventId, result);
        }
        result.push(reminder);
      } while (resultSet.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryReminderInfoByEventIds', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG);
    } finally {
      resultSet.close();
    }
    return resultMap;
  }


  /**
   * 查询某一个日程的提醒 Rminder 详情
   *
   * @param eventId 日程id
   */
  async queryReminderInfo(eventId: number): Promise<Array<CalendarContract.Reminders>> {

    const columnArray: Array<string> = [
      CalendarContract.RemindersColumns.ID as string,
      CalendarContract.RemindersColumns.EVENT_ID as string,
      CalendarContract.RemindersColumns.REMIND_MINUTES as string,
      CalendarContract.RemindersColumns.REMIND_TYPE as string
    ];
    const resultSet = await this.repo.queryReminderByEventId(eventId, columnArray);
    const result: Array<CalendarContract.Reminders> = [];
    if (!resultSet) {
      return result;
    }
    try {
      while (resultSet.goToNextRow()) {
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.id = DataShareResultUtil.getColumnLongData(resultSet, '_id', 0);
        reminder.eventId = DataShareResultUtil.getColumnLongData(resultSet, 'event_id', 0);
        reminder.remindMinutes = DataShareResultUtil.getColumnLongData(resultSet, 'minutes', 0);
        reminder.remindType = DataShareResultUtil.getColumnLongData(resultSet, 'method', 0);
        result.push(reminder);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryReminderInfo', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      resultSet.close();
    }
    return result;
  }

  /**
   * 查询某一个日程的提醒 Reminder 详情
   *
   * @param eventUuid 日程的 Uuid
   * @returns Reminder 详情
   */
  async queryReminderInfoByUuid(eventUuid: string): Promise<Array<CalendarContract.Reminders>> {
    const columnArray: Array<string> = [
      CalendarContract.RemindersColumns.ID as string,
      CalendarContract.RemindersColumns.EVENT_ID as string,
      CalendarContract.RemindersColumns.REMIND_MINUTES as string,
      CalendarContract.RemindersColumns.REMIND_TYPE as string,
      CalendarContract.RemindersColumns.EVENT_UUID as string
    ];
    const resultSet = await this.repo.queryReminderByEventUuid(eventUuid, columnArray);
    const result: Array<CalendarContract.Reminders> = [];
    if (!resultSet) {
      return result;
    }
    try {
      while (resultSet.goToNextRow()) {
        const reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
        reminder.id = DataShareResultUtil.getColumnLongData(resultSet, '_id', 0);
        reminder.eventUuid = DataShareResultUtil.getColumnStringData(resultSet, 'eventUuid', '');
        reminder.eventId = DataShareResultUtil.getColumnLongData(resultSet, 'event_id', 0);
        reminder.remindMinutes = DataShareResultUtil.getColumnLongData(resultSet, 'minutes', 0);
        reminder.remindType = DataShareResultUtil.getColumnLongData(resultSet, 'method', 0);
        result.push(reminder);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryReminderInfoByUuid', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      resultSet.close();
    }
    return result;
  }

  async insertReminder(reminder: CalendarContract.Reminders): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.insertReminder, 0);
    let result: Promise<number> = this.repo.insertReminder(this.getReminderInfo(reminder));
    hiTraceMeter.finishTrace(traceEvents.insertReminder, 0);
    return result;
  }

  async deleteReminderById(reminderId: number): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.deleteReminderById, 0);
    let result: Promise<number> = this.repo.deleteReminderById(reminderId);
    hiTraceMeter.finishTrace(traceEvents.deleteReminderById, 0);
    return result;
  }

  async deleteReminderByEventId(eventId: number): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.deleteReminderByEventId, 0);
    let result: Promise<number> = this.repo.deleteReminderByEventId(eventId);
    hiTraceMeter.finishTrace(traceEvents.deleteReminderByEventId, 0);
    return result;
  }

  async updateReminderById(reminderId: number, reminder: CalendarContract.Reminders): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.updateReminderById, 0);
    let result: Promise<number> = this.repo.updateReminderById(reminderId, this.getReminderInfo(reminder));
    hiTraceMeter.finishTrace(traceEvents.updateReminderById, 0);
    return result;
  }

  private getReminderInfo(reminder: CalendarContract.Reminders): ValuesBucket {
    const reminderInfo = {} as ValuesBucket;
    reminderInfo[CalendarContract.RemindersColumns.EVENT_ID] = reminder.eventId;
    reminderInfo[CalendarContract.RemindersColumns.REMIND_MINUTES] = reminder.remindMinutes;
    reminderInfo[CalendarContract.RemindersColumns.REMIND_TYPE] = reminder.remindType;
    return reminderInfo;
  }
}