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

import { DBUtils } from '../DBUtils';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { InnerResultSet } from '../util/InnerResultSet';

const TAG = 'AttendeeRepository';

export class AttendeeRepository {
  async queryAttendeeByEventId(eventId: number, columns: Array<string>): Promise<InnerResultSet | undefined> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarContract.RemindersColumns.EVENT_ID, eventId);
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.ATTENDEES,
      predicates, columns, 'queryAttendeeByEventId');
  }
}