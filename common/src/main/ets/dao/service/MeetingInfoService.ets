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

import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Log } from '../../default/common/Log';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import { MeetingInfoRepository } from '../repo/MeetingInfoRepository';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';

const TAG = 'MeetingInfoService';

export class MeetingInfoService {
  public static readonly INSTANCE: MeetingInfoService = new MeetingInfoService();
  private readonly meetingInfoDao: MeetingInfoRepository = MeetingInfoRepository.INSTANCE;

  private constructor() {
  }

  async queryMeetingInfo(eventId: number, begin: number): Promise<CalendarContract.MeetingInfo | undefined> {
    Log.info(TAG, `queryMeetingInfoById enter ${eventId} ${begin}`);
    let resultSet = await this.meetingInfoDao.queryByEvent(eventId, begin);
    let result: CalendarContract.MeetingInfo | undefined = undefined;
    try {
      if (!resultSet) {
        Log.warn(TAG, 'queryMeetingInfoById no entry');
        return result;
      }
      if (resultSet.goToFirstRow()) {
        result = new CalendarContract.MeetingInfo();
        result.instanceId = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.MeetingInfoColumns.INSTANCE_ID, 0);
        result.eventId = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.MeetingInfoColumns.EVENT_ID, 0);
        result.begin = DataShareResultUtil.getColumnLongData(
          resultSet, CalendarContract.MeetingInfoColumns.BEGIN, 0);
        result.link = DataShareResultUtil.getColumnStringData(
          resultSet, CalendarContract.MeetingInfoColumns.LINK, '');
        return result;
      } else {
        Log.warn(TAG, 'queryMeetingInfoById no entry');
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `queryMeetingInfoById err`, err);
      SqlFaultHandle.querySqlFail(err?.message, TAG);
      return undefined;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return undefined;
  }
}