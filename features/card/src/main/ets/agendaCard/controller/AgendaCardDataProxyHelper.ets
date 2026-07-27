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

import { Log, MILLS_PER_DAY } from '@app/common';
import { CURRENT_TIME, CURRENT_UTC_TIME, START_OF_DAY_TIME, START_OF_DAY_UTC_TIME } from '../../utils/UpdateSQLUtils';

const TAG: string = 'AgendaCardDataProxyHelper';

/**
 * 去重的基础条件
 */
const DEDUPLICATION_CONDITION: string = `begin,
    end,
    title,
    calendar_id,
    eventLocation,
    allDay`;


export class AgendaCardDataProxyHelper {
  /**
   * 查询距今start-end天的日程数量
   * 携带UTC的是普通日程，不携带的是全天日程
   * DISTINCT去除重复日程，防止视图上没有，但是卡片上显示多条
   * isStartNow去除今天过期日程
   * @returns
   */
  public static queryOneDayCount(start: number, end: number, isStartNow = false) {
    Log.info(TAG, `isStartNow： ${isStartNow}`)
    return `SELECT
        strftime('%s', 'now', 'localtime', 'start of day', 'UTC') * 1000 + ${MILLS_PER_DAY} * ${start} AS startTimeOfDay,
        SUM(agendaNum) AS agendaNum
      FROM (
        SELECT
          Count(*) AS agendaNum
        FROM (
          SELECT DISTINCT ${DEDUPLICATION_CONDITION}
          FROM
            Instances
            INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
            INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
          WHERE
            visible = 1
            AND (
              BEGIN < ${START_OF_DAY_TIME} + ${MILLS_PER_DAY} * ${end}
              AND
              END > ${isStartNow ? CURRENT_TIME : `${START_OF_DAY_TIME} + ${MILLS_PER_DAY} * ${start}`}
            )
            AND important_event_type = 0
            AND allDay = 1
        )
        UNION ALL
        SELECT
          Count(*) AS agendaNum
        FROM (
          SELECT DISTINCT ${DEDUPLICATION_CONDITION}
          FROM
            Instances
            INNER JOIN Events ON (Instances.event_uuid = Events.uuid)
            INNER JOIN Calendars ON (Events.calendar_uuid = Calendars.uuid)
          WHERE
              visible = 1
            AND (
              BEGIN < ${START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY} * ${end}
              AND
              END > ${isStartNow ? CURRENT_UTC_TIME : `${START_OF_DAY_UTC_TIME} + ${MILLS_PER_DAY} * ${start}`}
            )
            AND important_event_type = 0
            AND allDay = 0
        )
      )`;
  }
  // 查询当前天及前后日程
  public static queryDaysCount(prev = 0, next = 6): string {
    // 合并
    let sql = 'SELECT * FROM ( ';
    for (let i = prev; i <= next; i++) {
      sql += AgendaCardDataProxyHelper.queryOneDayCount(i, i + 1, i === 0);
      if (i != next) {
        sql += ' UNION ALL ';
      }
    }
    sql += ' ) ORDER BY startTimeOfDay ASC ';
    return sql;
  }
}