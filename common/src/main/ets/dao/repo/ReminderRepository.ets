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

import { Log } from '../../default/common/Log';
import { DBUtils } from '../DBUtils';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { EmptyUtils } from '../../util/EmptyUtils';
import { InnerResultSet } from '../util/InnerResultSet';

const TAG = 'ReminderRepository';

export class ReminderRepository {
  /**
   * 插入 reminder 提醒
   *
   * @param reminder 需要插入的 reminder对象
   * @return 插入的 reminder 的 id
   */
  async insertReminder(reminderInfo: ValuesBucket): Promise<number> {
    return DBUtils.INSTANCE.insert(DBUtils.INSTANCE.URI_REMINDER, reminderInfo, TAG);
  }

  async deleteReminderById(reminderId: number): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.ID, reminderId);
    return DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_REMINDER, predicates, TAG);
  }

  async deleteReminderByEventId(eventId: number): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.EVENT_ID, eventId);
    return DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_REMINDER, predicates, TAG);
  }

  async updateReminderById(reminderId: number, value: ValuesBucket): Promise<number> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.ID, reminderId);
    return DBUtils.INSTANCE.update(DBUtils.INSTANCE.URI_REMINDER, predicates, value, TAG);
  }

  async queryReminderByEventId(eventId: number, columns: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryReminderByEventId';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.EVENT_ID, eventId);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.REMINDERS, predicates, columns, tag);
  }

  async queryReminderByEventUuid(eventUuid: string, columns: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryReminderByEventUuid';
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.EVENT_UUID, eventUuid);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.REMINDERS, predicates, columns, tag);
  }

  async queryReminderByEventIds(eventIds: Array<number>, columns: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryReminderByEventIds';
    if (EmptyUtils.isEmptyArray(eventIds)) {
      Log.warn(tag, 'eventIds is empty');
      return;
    }
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.RemindersColumns.EVENT_ID, eventIds);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.REMINDERS, predicates, columns, tag);
  }
}