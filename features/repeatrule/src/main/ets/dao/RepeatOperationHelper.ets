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


import { AgendaEventInfo, EventService, Log, MILLS_PER_SECOND, UTC } from '@app/common';
import { FormatTime } from '../time/FormatTime';
import { ValuesBucket } from '@kit.ArkData';
import { Recurrence } from '../Recurrence';

const TAG: string = 'RepeatOperationHelper';

/**
 * 删除单实例时调用，添加exdate到数据库
 *
 * @param eventId 日程id
 * @param instancesStartMills 被删除日程实例的开始时间戳
 * @returns 删除结果
 */
async function addExDateToDb(eventId: number, instancesStartMills: number): Promise<boolean> {
  if (instancesStartMills < 0) {
    Log.warn(TAG, `updateUntilToDb get invalid mills`);
    return false;
  }
  const agendaList: AgendaEventInfo[] = await EventService.INSTANCE.queryEventsByEventIds([eventId]);
  if (agendaList === null || agendaList === undefined || agendaList.length === 0) {
    Log.warn(TAG, `addExDateToDb get empty agendaList eventId:${eventId}`);
    return false;
  }
  const event: AgendaEventInfo = agendaList[0];
  if (!event) {
    Log.warn(TAG, `addExDateToDb get invalid event eventId:${eventId}`);
    return false;
  }
  let exDate: string = event.exDate;
  const newExDate: string = new FormatTime().getTimeInFormat2445(instancesStartMills, UTC);
  if (exDate === null || exDate === undefined || exDate.length === 0) {
    exDate = newExDate;
  } else {
    exDate = `${exDate},${newExDate}`;
  }
  const values: ValuesBucket = {
    'exdate': exDate
  };
  const result: number = await EventService.INSTANCE.updateByEventId(eventId, values);
  return result === 1;
}

/**
 * 删除今后及所有时调用，修改until到数据库
 *
 * @param eventId 日程id
 * @param untilMills 被删除实例的开始时间戳
 * @returns 删除结果
 */
async function updateUntilToDb(eventId: number, untilMills: number): Promise<boolean> {
  if (untilMills < 0) {
    Log.warn(TAG, `updateUntilToDb get invalid mills`);
    return false;
  }
  const agendaList: AgendaEventInfo[] = await EventService.INSTANCE.queryEventsByEventIds([eventId]);
  if (agendaList === null || agendaList === undefined || agendaList.length === 0) {
    Log.warn(TAG, `updateUntilToDb get empty agendaList`);
    return false;
  }
  const event: AgendaEventInfo = agendaList[0];
  if (!event) {
    Log.warn(TAG, `updateUntilToDb get invalid event`);
    return false;
  }
  const recurrence: Recurrence = new Recurrence();
  if (event.isLunarEvent()) {
    recurrence.setLunarEvent();
  }
  recurrence.parse(event.mRepeatRule);
  recurrence.setUntil(untilMills - MILLS_PER_SECOND);
  const rrule: string = recurrence.format();
  const values: ValuesBucket = {
    'rrule': rrule
  };
  const result: number = await EventService.INSTANCE.updateByEventId(eventId, values);
  return result === 1;
}

export {
  addExDateToDb, updateUntilToDb
}