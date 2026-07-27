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
import { CalendarDataFeature, CalendarDataFeatureHelper, Log, MILLS_PER_DAY } from '@app/common';
import { EVENTLOCATION_LIMIT_LENGTH, TITLE_LIMIT_LENGTH } from './CardUtils';

const TAG: string = 'AgendaCardDataProxyHelper';
/** 一天的开始时间毫秒戳，携带UTC */
export const START_OF_DAY_UTC_TIME: string = `strftime('%s', 'now', 'localtime', 'start of day', 'UTC') * 1000`;
/** 一天的开始时间毫秒戳，不携带UTC */
export const START_OF_DAY_TIME: string = `strftime('%s', 'now', 'localtime', 'start of day') * 1000`;
/** 当前时间毫秒戳，携带UTC */
export const CURRENT_UTC_TIME: string = `strftime('%s', 'now', 'localtime', 'UTC') * 1000`;
/** 当前时间毫秒戳，不携带UTC */
export const CURRENT_TIME: string = `strftime('%s', 'now', 'localtime') * 1000`;
/** 一天的开始时间毫秒戳，携带UTC，使用datetime转换 */
export const FORMAT_START_OF_DAY_UTC_TIME: string = `strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC') * 1000`;
/** 当前时间毫秒戳，携带UTC，使用datetime转换 */
export const FORMAT_CURRENT_UTC_TIME: string = `strftime('%s', datetime('now', 'localtime'), 'UTC') * 1000`;

/**
 * select基础条件，用于2x2,2x4,4x4日程卡片
 */
export const QUERY_CONDITION_BASIC: string[] = [
  `Instances._id AS id`,
  `event_id`,
  `BEGIN`,
  `END`,
  `startDay`,
  `endDay`,
  `startMinute`,
  `endMinute`,
  `SUBSTR(title, 1, ${TITLE_LIMIT_LENGTH}) AS title`,
  `allDay`,
  `SUBSTR(eventLocation, 1, ${EVENTLOCATION_LIMIT_LENGTH}) AS eventLocation`,
  `calendar_id`,
  `calendar_color`,
  `account_type`,
  `service_verified`,
  `service_type`,
  `service_cp_bz_uri`,
  `Events.creator`,
  `Instances.event_uuid`,
  `events.calendar_uuid`,
];

/**
 * 卡片当天日程数据查询 sql: strftime获取的是秒级别的时间戳
 * 用于展示日程提示语，即今日日程已全部完成或今日无日程
 * 携带UTC的是普通日程，不携带UTC的是全天日程
 */
export const QUERY_TODAY_AGENDA_SQL: string = `SELECT *
    FROM (
      SELECT ${QUERY_CONDITION_BASIC}
      FROM
        Instances
        INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
        INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
      WHERE visible = 1
        AND (
          BEGIN < ${START_OF_DAY_TIME} + ${MILLS_PER_DAY}
          AND
          END > ${START_OF_DAY_TIME}
          )
        AND important_event_type = 0
        AND allDay = 1
      UNION ALL
      SELECT ${QUERY_CONDITION_BASIC}
      FROM
        Instances
        INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
        INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
      WHERE visible = 1
        AND (
          BEGIN < ${START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY}
          AND
          END > ${START_OF_DAY_UTC_TIME}
          )
        AND important_event_type = 0
        AND allDay = 0
    )
    ORDER BY startDay, BEGIN ASC
    LIMIT 1`;

/**
 * 所有的Columns都需要从该方法获取
 * V1:新增附件字段attachment_count
 * @returns 所有需要查询的字段string
 */
export async function getQueryTodayAgendaSql(): Promise<string> {
  const queryCondition = [...QUERY_CONDITION_BASIC];
  if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
    queryCondition.push(`attachment_count`);
  }
  return queryCondition.join(`,`);
}