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

import { DateRange } from '@app/common/src/main/ets/date/DateRange';
import { AgendaEventInfo, CalendarContract, CalendarDate, I18nUtil, InstanceService,
  Log,
  QueryInfo } from '@app/common';
// 裁剪日程共享功能 - 移除 ShareInfoUtils
// import { ShareInfoUtils } from '@app/feature.share';

export class AgendaModel {
  private static _instance: AgendaModel = new AgendaModel();
  private range: DateRange.Range = { start: Date.now(), end: Date.now() };
  private cache: AgendaEventInfo[] = [];
  private cacheHoliday: string[] = [];
  private hasUpdate: boolean = true;

  public static instance(): AgendaModel {
    return AgendaModel._instance;
  }

  async query(range: DateRange.Range): Promise<void> {
    if (!this.needUpdate(range)) {
      return;
    }
    const temp: QueryInfo = {
      startTime : range.start,
      endTime : range.end,
      useCalendarUuid: true
    };
    this.range = range;
    this.cache = await InstanceService.INSTANCE.queryInstanceAsync(temp) as AgendaEventInfo[];
    // 查询共享相关信息并插入相关字段到信息对象中
    // 裁剪日程共享功能 - 注释掉 ShareInfoUtils 调用
    // await ShareInfoUtils.insertShareInfo2List(this.cache);
    this.cacheHoliday = this.cache.filter((info) => info.isHoliday()).map(info => info.mTitle.trim());
  }

  getAgendaByRange(range: DateRange.Range, exceptImportantEvent?: boolean,
    chineseHolidayAccountId?: number): AgendaEventInfo[] {
    const res = this.cache.filter((item: AgendaEventInfo) => {
      // 新规格，判断日程点是否显示:仅普通日程、非中国节假日日程和重要日显示
      if (exceptImportantEvent) {
        const isNeedShowAgendaPoint = item.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
          (item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY &&
            chineseHolidayAccountId !== item.mCalendarId) || item. isImportantEvent();
        if (!isNeedShowAgendaPoint) {
          return 0;
        }
      }
      if (item.mIsAllDay) {
        // 全天日程采用UTC时区存储,需要计算偏移量 --welink会插入非UTC时区的全天日程,故需要获取时区计算偏移量
        const timeOffset = I18nUtil.getTimeZoneOffsetById(item.eventTimeZone);
        // 日程的开始结束时间减去对应的偏移量再进行判断
        return item.mBegin - timeOffset < range.end && item.mEnd - timeOffset > range.start;
      } else {
        return item.mBegin < range.end && item.mEnd > range.start;
      }
    });
    return res;
  }

  getFestivalByRange(range: DateRange.Range, chineseHolidayAccountId?: number): string {
    const res = this.cache.filter((item: AgendaEventInfo) => {
      const isNeedShowAgendaPoint = item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY &&
        chineseHolidayAccountId === item.mCalendarId;
      if (!isNeedShowAgendaPoint) {
        return 0;
      }
      // 全天日程采用UTC时区存储,需要计算偏移量 --welink会插入非UTC时区的全天日程,故需要获取时区计算偏移量
      const timeOffset = I18nUtil.getTimeZoneOffsetById(item.eventTimeZone);
      // 日程的开始结束时间减去对应的偏移量再进行判断
      return item.mBegin - timeOffset < range.end && item.mEnd - timeOffset > range.start;
    });
    if (res.length === 0) {
      return '';
    } else {
      return res[0].mTitle;
    }
  }

  findAgendaFromCache(id: number): AgendaEventInfo | undefined {
    return this.cache.find(item => item.mId === id);
  }

  getAgendaCountByRange(range: DateRange.Range, exceptHoliday: boolean, chineseHolidayAccountId: number): number {
    return this.getAgendaByRange(range, exceptHoliday, chineseHolidayAccountId).length;
  }

  getFestivalNameByRange(range: DateRange.Range, chineseHolidayAccountId: number): string {
    return this.getFestivalByRange(range, chineseHolidayAccountId);
  }

  checkHasSameHoliday(holidayName: string): boolean {
    return this.cacheHoliday.includes(holidayName);
  }

  private needUpdate(range: DateRange.Range): boolean {
    return !DateRange.isSameDateRange(this.range, range) || this.hasUpdate;
  }
}