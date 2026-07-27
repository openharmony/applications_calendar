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
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '../../default/common/TraceEvents';
import { Log } from '../../default/common/Log';
import { InnerResultSet } from '../util/InnerResultSet';
import { CalendarDataFeature, CalendarDataFeatureHelper } from '../../util/CalendarDataFeatureHelper';

const TAG = 'InstanceRepository';

export class InstanceRepository {
  private readonly QUERY_INSTANCE_PROJECTIONS: string[] = [
    'Instances._id',
    CalendarContract.InstancesColumns.EVENT_ID,
    CalendarContract.InstancesColumns.INSTANCE_BEGIN,
    CalendarContract.InstancesColumns.INSTANCE_END,
    CalendarContract.InstancesColumns.INSTANCE_START_DAY,
    CalendarContract.InstancesColumns.INSTANCE_END_DAY,
    CalendarContract.InstancesColumns.INSTANCE_START_MINUTE,
    CalendarContract.InstancesColumns.INSTANCE_END_MINUTE,
    'Events.uuid', // Event的UUID
    CalendarContract.EventsColumns.TITLE,
    CalendarContract.EventsColumns.ALL_DAY,
    CalendarContract.EventsColumns.EVENT_LOCATION,
    CalendarContract.EventsColumns.DESCRIPTION,
    CalendarContract.EventsColumns.CALENDAR_ID,
    CalendarContract.EventsColumns.CALENDAR_UUID,
    CalendarContract.EventsColumns.SERVICE_VERIFIED,
    CalendarContract.EventsColumns.SERVICE_TYPE,
    CalendarContract.EventsColumns.SERVICE_CP_BZ_URI,
    CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE,
    CalendarContract.EventsColumns.RRULE,
    CalendarContract.EventsColumns.RDATE,
    CalendarContract.EventsColumns.EXRULE,
    CalendarContract.EventsColumns.EXDATE,
    CalendarContract.EventsColumns.START_TIMEZONE,
    CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE,
    CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE,
    CalendarContract.EventsColumns.IDENTIFIER,
    CalendarContract.EventsColumns.DTSTART,
    `${CalendarContract.Tables.EVENTS}.${CalendarContract.EventsColumns.CREATOR}`
  ];

  async queryCondition(begin: number, end: number, searchText?: string): Promise<InnerResultSet | undefined> {
    // 构建查询条件
    const tag = 'queryCondition';
    let result: InnerResultSet | undefined = undefined;
    const predicates = new dataSharePredicates.DataSharePredicates();
    // 非静默查询会进行自动扩表
    let uri: string = `&begin=${begin}&end=${end}&orderByAsc=startDay`;
    if (searchText) {
      uri = uri + `&searchText=${encodeURIComponent(searchText)}`;
    }
    const projections = [...this.QUERY_INSTANCE_PROJECTIONS];
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      projections.push(CalendarContract.EventsColumns.ATTACHMENT_COUNT);
    }
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
      projections.push(CalendarContract.EventsColumns.LANGUAGE_RESOURCES);
    }
    result = await DBUtils.INSTANCE.queryWithExtraUrl(CalendarContract.Tables.INSTANCES, predicates,
      projections, tag, uri);
    return result;
  }

  async queryConditionSilent(beginTime: number, endTime: number,
                             eventIds?: number[]): Promise<InnerResultSet | undefined> {
    const tag = 'queryConditionSilent';
    // 构建查询条件
    hiTraceMeter.startTrace(traceEvents.queryCondition, 0);
    const columns: string[] = [
      CalendarContract.InstancesColumns.EVENT_ID,
      CalendarContract.InstancesColumns.INSTANCE_BEGIN,
      CalendarContract.InstancesColumns.INSTANCE_END,
      CalendarContract.InstancesColumns.INSTANCE_START_DAY,
      CalendarContract.InstancesColumns.INSTANCE_END_DAY,
      'event_uuid',
    ]
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.beginWrap()
      .greaterThanOrEqualTo(CalendarContract.InstancesColumns.INSTANCE_END, beginTime)
      .and()
      .lessThanOrEqualTo(CalendarContract.InstancesColumns.INSTANCE_BEGIN, endTime)
      .endWrap()
    if (eventIds && eventIds.length > 0) {
      predicates.and().in(CalendarContract.InstancesColumns.EVENT_ID, eventIds);
    }
    const result = await DBUtils.INSTANCE.query(CalendarContract.Tables.INSTANCES,
      predicates, columns, tag);
    hiTraceMeter.finishTrace(traceEvents.queryCondition, 0);
    return result;
  }
}