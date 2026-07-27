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

import { AttendeeRepository } from '../repo/AttendeeRepository';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Log } from '../../default/common/Log';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';

const TAG = 'AttendeeService';

export class AttendeeService {
  static readonly INSTANCE: AttendeeService = new AttendeeService();
  public attendeeDao: AttendeeRepository = new AttendeeRepository();

  private constructor() {
  }


  /**
   * 查询某一个日程对应的与会人 Attendee 详情
   *
   * @param eventId 日程id
   */
  async queryAttendeeInfoByEventId(eventId: number): Promise<Array<CalendarContract.Attendees>> {

    const columnArray: Array<string> = [
      CalendarContract.AttendeesColumns.ID as string,
      CalendarContract.AttendeesColumns.EVENT_ID as string,
      CalendarContract.AttendeesColumns.ATTENDEE_NAME as string,
      CalendarContract.AttendeesColumns.ATTENDEE_EMAIL as string,
      CalendarContract.AttendeesColumns.ATTENDEE_STATUS as string,
      CalendarContract.AttendeesColumns.ATTENDEE_RELATIONSHIP as string,
      CalendarContract.AttendeesColumns.ATTENDEE_TYPE as string,
      CalendarContract.AttendeesColumns.ATTENDEE_IDENTITY as string,
      CalendarContract.AttendeesColumns.ATTENDEE_ID_NAMESPACE as string
    ];
    const resultSet = await this.attendeeDao.queryAttendeeByEventId(eventId, columnArray);
    const result: Array<CalendarContract.Attendees> = [];
    if (!resultSet) {
      return result;
    }
    try {
      while (resultSet.goToNextRow()) {
        const attendees: CalendarContract.Attendees = new CalendarContract.Attendees();
        attendees.id = DataShareResultUtil.getColumnLongData(resultSet, CalendarContract.AttendeesColumns.ID, 0);
        attendees.eventId = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.AttendeesColumns.EVENT_ID, 0);
        attendees.attendeeName = DataShareResultUtil.getColumnStringData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_NAME, '');
        attendees.attendeeEmail = DataShareResultUtil.getColumnStringData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_EMAIL, '');
        attendees.attendeeStatus = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_STATUS, 0);
        attendees.attendeeRelationship = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_RELATIONSHIP, 0);
        attendees.attendeeType = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_TYPE, 0);
        attendees.attendeeIdentity = DataShareResultUtil.getColumnStringData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_IDENTITY, '');
        attendees.attendeeIdNamespace = DataShareResultUtil.getColumnStringData(
          resultSet, CalendarContract.AttendeesColumns.ATTENDEE_ID_NAMESPACE, '');
        result.push(attendees);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryAttendeeInfoByEventId', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG)
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return result;
  }
}