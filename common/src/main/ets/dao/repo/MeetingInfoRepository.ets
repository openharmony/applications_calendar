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

const TAG = 'MeetingInfoRepository';

export class MeetingInfoRepository {
  public static readonly INSTANCE: MeetingInfoRepository = new MeetingInfoRepository();
  private readonly QUERY_MEETING_INFO_PROJECTIONS: string[] = [
    CalendarContract.BaseColumns.ID,
    CalendarContract.MeetingInfoColumns.INSTANCE_ID,
    CalendarContract.MeetingInfoColumns.EVENT_ID,
    CalendarContract.MeetingInfoColumns.BEGIN,
    CalendarContract.MeetingInfoColumns.LINK
  ];

  async queryByEvent(eventId: number, begin: number): Promise<InnerResultSet | undefined> {
    // 构建查询条件
    const tag = 'queryMeetingInfoByEvent';
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates
      .equalTo(CalendarContract.MeetingInfoColumns.EVENT_ID, eventId)
      .and()
      .equalTo(CalendarContract.MeetingInfoColumns.BEGIN, begin)
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.MEETING_INFO, predicates,
      this.QUERY_MEETING_INFO_PROJECTIONS, tag);
  }
}