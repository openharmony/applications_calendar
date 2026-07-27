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

import { EventMode } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { ImportantEntity } from './ImportantEntity';
import { getAdaptImportantTime } from '@app/common/src/main/ets/adapter/RecurrenceImportantAdapt';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DateManager } from '@app/common/src/main/ets/date/DateManager';
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';
import { MILLS_PER_DAY } from '@app/common/src/main/ets/util/DateUtil';
import { ALL_LUNAR_TERM } from '@app/common/src/main/ets/date/LunarTermConsts';

const TAG: string = 'ImportantCardModel';

// 支持显示和设置的中国节假日，固定七个法定节日+常用的七夕重阳
export const SUPPORT_CHINESE_HOLIDAYS: string[] = ['元旦', '春节', '清明节', '劳动节', '端午节', '中秋节', '国庆节', '七夕节', '重阳节'];

// 支持显示和设置的节气，包括24节气和三伏数九
export const SUPPORT_SOLAR_TERMS: string[] = [...ALL_LUNAR_TERM];

class LocalHolidayEntityData {
}

export function getRecentLocalHolidayEntities(): ImportantEntity[] {
  const result: ImportantEntity[] = [];
  const todayStart: number = new CalendarDate(Date.now()).setHours(0, 0, 0);
  const queryDays: number = 366 + 60;
  for (let index = 0; index < queryDays; index++) {
    const date: CalendarDate = new CalendarDate(todayStart + index * MILLS_PER_DAY);
    const dayData = DateManager.getInstance().getDayData(date.getFullYear(), date.getMonth() + 1, date.getDate());
    if (!dayData) {
      continue;
    }
    for (const festival of dayData.festivals) {
      if (!SUPPORT_CHINESE_HOLIDAYS.includes(festival.name) && !SUPPORT_SOLAR_TERMS.includes(festival.name)) {
        continue;
      }
      const entity: ImportantEntity = new ImportantEntity(new LocalHolidayEntityData());
      entity.eventId = 0;
      entity.title = festival.name;
      entity.begin = date.getTime();
      entity.originalBegin = entity.begin;
      entity.end = entity.begin + MILLS_PER_DAY - 1;
      entity.importantEventType = CalendarContract.EventImportantType.HOLIDAY;
      entity.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      result.push(entity);
    }
  }
  return result;
}

/**
 * 重要日卡片数据模型
 */
export class ImportantCardModel {
  private recentHolidayList: ImportantEntity[] = [];
  private fixedImportantList: ImportantEntity[] = [];
  private fixedHolidayList: ImportantEntity[] = [];
  private fixedBirthdayList: ImportantEntity[] = [];
  private cardFormId: string = '';
  private eventMode: EventMode = EventMode.DEFAULT;

  public bindFormId(formId: string): void {
    this.cardFormId = formId;
  }

  public bindMode(eventMode: EventMode): void {
    this.eventMode = eventMode;
  }

  public updateRecentHoliday(dataList: object[]): void {
    const tmpList = this.convertProxyDataToImportant(dataList);
    if (tmpList && tmpList.length > 0) {
      const validList = tmpList.filter((item: ImportantEntity) => {
        return this.isSupportHoliday(item.title);
      });
      this.recentHolidayList = validList.length > 0 ? validList : getRecentLocalHolidayEntities();
    } else {
      this.recentHolidayList = getRecentLocalHolidayEntities();
    }
  }

  public updateFixedImportant(dataList: object[]): void {
    this.fixedImportantList = this.convertProxyDataToImportant(dataList);
  }

  public updateFixedBirthday(dataList: object[]): void {
    this.fixedBirthdayList = this.convertProxyDataToImportant(dataList);
  }

  public updateFixedHoliday(dataList: object[]): void {
    this.fixedHolidayList = this.convertProxyDataToImportant(dataList);
  }

  /**
   * 计算卡片应该显示的重要日信息
   * 优先级：自建重要日>生日>节日，同一类型按时间排序
   *
   * @returns 卡片应该显示的重要日信息
   */
  public getShowImportantEntity(): ImportantEntity | null {
    Log.info(TAG, `getShowImportantEntity mode=${this.eventMode}`);
    if (this.eventMode === EventMode.RECENT_HOLIDAY) {
      return this.calculateByRecentHolidayMode();
    } else if (this.eventMode === EventMode.FIXED_IMPORTANT) {
      return this.calculateFixedImportant(this.fixedImportantList);
    } else if (this.eventMode === EventMode.FIXED_BIRTHDAY) {
      return this.calculateFixedBirthday(this.fixedBirthdayList);
    } else if (this.eventMode === EventMode.FIXED_HOLIDAY) {
      return this.calculateFixedHoliday(this.fixedHolidayList);
    } else {
      return null;
    }
  }

  private calculateByRecentHolidayMode(): ImportantEntity | null {
    // 重置重要日信息，无重要日则需显示默认卡片，即跨年夜
    let showImportantEntity: ImportantEntity | null = null;
    if (!this.recentHolidayList || this.recentHolidayList.length === 0) {
      Log.warn(TAG, 'calculateByRecentHolidayMode no recent holiday');
      return showImportantEntity;
    }
    const recentList: ImportantEntity[] = [...this.recentHolidayList];
    recentList.sort((itemA: ImportantEntity, itemB: ImportantEntity) => {
      return itemA.end - itemB.end;
    });
    for (let index = 0; index < recentList.length; index++) {
      const element = recentList[index];
      if (element.isValid() && !element.isExpired() && this.isSupportHoliday(element.title)) {
        Log.info(TAG, `formId: ${this.cardFormId} show recent holiday: ${maskString(element.title)}`);
        showImportantEntity = element;
        break;
      }
    }
    return showImportantEntity;
  }

  private isSupportHoliday(holidayTitle: string): boolean {
    return SUPPORT_CHINESE_HOLIDAYS.includes(holidayTitle) || SUPPORT_SOLAR_TERMS.includes(holidayTitle);
  }

  private calculateFixedImportant(fixedList: ImportantEntity[]): ImportantEntity | null {
    Log.info(TAG, `calculateFixedImportant fixedList: ${fixedList?.length}`);

    if (!fixedList || fixedList.length === 0) {
      return null;
    }

    const entity: ImportantEntity = fixedList[0];
    Log.info(TAG, `formId: ${this.cardFormId} show fixed important: ${entity.eventId}`);
    if (entity.isExpired()) {
      Log.warn(TAG, `fixed event ${entity.eventId}/${entity.begin} is expired`);
      return null;
    }
    return entity;
  }

  private calculateFixedBirthday(fixedList: ImportantEntity[]): ImportantEntity | null {
    Log.info(TAG, `calculateFixedBirthday fixedList: ${fixedList?.length}`);

    if (!fixedList || fixedList.length === 0) {
      return null;
    }

    Log.info(TAG, `formId: ${this.cardFormId} show fixed birthday: ${fixedList[0].eventId}`);
    return fixedList[0];
  }

  /**
   * 固定节日不同于固定的重要日和生日，不能根据eventId直接查询到准确数据，因而不能直接使用第一个元素作为有效值。
   * 节日查询时，是根据id找到title，再根据title查询相近的日程的，因此需要按时间排序后依次遍历，找到第一个未过期的。
   *
   * @param fixedList 按title查找到的节日列表数据
   * @returns 是否计算成功
   */
  private calculateFixedHoliday(fixedList: ImportantEntity[]): ImportantEntity | null {
    Log.info(TAG, `calculateFixedHoliday fixedList: ${fixedList?.length}`);
    if (!fixedList || fixedList.length === 0) {
      return null;
    }
    // fixedList已按开始时间排序，从按title查询到的数据中，依次从前往后取第一个未过期的数据作为有效数据
    for (let index = 0, size = fixedList.length; index < size; index++) {
      const element = fixedList[index];
      if (!element) {
        continue;
      }
      if (!element.isExpired()) {
        Log.info(TAG, `formId: ${this.cardFormId} show fixed holiday: ${element.title}`);
        return element;
      }
    }
    return null;
  }

  private convertProxyDataToImportant(dataList: object[]): ImportantEntity[] {
    const resultList: ImportantEntity[] = [];
    if (!dataList || dataList.length == 0) {
      return resultList;
    }
    const now: CalendarDate = new CalendarDate();
    for (let index = 0; index < dataList.length; index++) {
      const item = dataList[index];
      // 数据转换为ImportantEntity
      const entity: ImportantEntity = (item instanceof ImportantEntity) ? item : new ImportantEntity(item);
      // 尝试将周期日程的时间进行挪移
      const realBegin: number = getAdaptImportantTime(entity.eventCalendarType, entity.begin, entity.rrule, now);
      const offset: number = realBegin - entity.begin;
      entity.begin = realBegin;
      entity.end = entity.end + offset;
      resultList.push(entity);
    }
    // 按重要日创建时间，由远及近进行排序，最新的排在最前面
    resultList.sort((itemA: ImportantEntity, itemB: ImportantEntity) => {
      if (itemA.importantEventType === itemB.importantEventType &&
        itemA.importantEventType === CalendarContract.EventImportantType.HOLIDAY) {
        return itemA.begin - itemB.begin;
      }
      return itemB.eventTimeStamp - itemA.eventTimeStamp;
    });
    return resultList;
  }
}
