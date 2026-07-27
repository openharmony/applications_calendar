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
import { CalendarDate, DateUtil, Log, MILLS_PER_DAY, MILLS_PER_HOUR, MILLS_PER_MINUTE } from '@app/common';
import { SaveTimeType } from '../Constants';

const TAG = 'CreateAgendaViewModel';

export class CreateAgendaViewModel {

  /**
   * 获取新建日程的默认开始时间，当前时间的分秒值 + 传入时间的日期值
   * 如果当前时间为整点或半点刚过一分钟内，默认开始时间为当前整点或半点
   * 如果当前时间为整点或半点超过一分钟，默认开始时间为下一个整点或半点
   * 如果当前时间为当前23.30往后，则不需要再向下取整，避免跨天
   * @param dateParam 需要创建的时间的日期对象
   * @param needSaveTime 保留时间标志,若存在,则不对传入时间作截取操作
   */
  public getStartDateByCombine(dateParam: number, needSaveTime: SaveTimeType): number {
    Log.info(TAG, `getStartDateByCombine this.needSaveTime:${needSaveTime}, dateParam = ${dateParam}`);
    let nowTimeMills = dateParam;
    const halfHourMills = MILLS_PER_HOUR / 2;
    let isNeedFloor: boolean = true;
    if (needSaveTime === SaveTimeType.DEFAULT) { //无需保留时分
      const now = new CalendarDate();
      // 保留传入的日期
      const nowBeyondZeroTimeMills = now.getTime() - DateUtil.getStartOfDayTimeStamp();
      // 若时间超过了当天的23.30 则不再向下取整，避免跨天
      isNeedFloor = nowBeyondZeroTimeMills < MILLS_PER_DAY - halfHourMills;
      // 新的时间 = 当前时间的分秒值 + 传入时间的日期值
      const beginOfNewAgenda = DateUtil.getStartOfDayTimeStamp(dateParam);
      const nowOfNewAgenda = new CalendarDate(beginOfNewAgenda + nowBeyondZeroTimeMills);
      nowTimeMills = nowOfNewAgenda.getTime();
    } else if (needSaveTime === SaveTimeType.SAVE_START_TIME) { //需要保留时分并取整
      //传入时间减去半小时以取其区间
      nowTimeMills = nowTimeMills - halfHourMills;
    } else { //需要保留时分
      nowTimeMills = nowTimeMills;
      return Math.trunc(nowTimeMills / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    }
    // 如果当前时间为整点或半点刚过一分钟内，默认开始时间为当前整点或半点
    if (nowTimeMills % halfHourMills < MILLS_PER_MINUTE) {
      return Math.trunc(nowTimeMills / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    }
    // 如果当前时间为整点或半点超过一分钟，默认开始时间为下一个整点或半点
    return Math.trunc(nowTimeMills / halfHourMills) * halfHourMills + (isNeedFloor ? halfHourMills : 0);
  }
}