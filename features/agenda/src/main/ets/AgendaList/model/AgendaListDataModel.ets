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

import {
  AgendaEventInfo,
  InstanceService,
  Log,
  QueryInfo,
  DateRange,
  MILLS_THIRTY_DAYS,
  CalendarContract,
  CalendarService,
  AccountUtils,
  CalendarDate,
  PreferencesUtil,
  PreferencesFiles,
  AgendaListKey,
  EmptyUtils,
} from '@app/common';
import { AgendaListItemViewModel } from '@app/common/src/main/ets/agenda/AgendaListDataSource';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
// 自动扩展查询时间边界获取到的最大数据
const MAX_AUTO_QUERY_LENGTH = 30;
// 自动扩展查询边界最大次数，用于规避日程稀疏而多次查询的场景
const MAX_AUTO_QUERY_TIMES = 3;
// 无效日历账户id
export const ILLEGAL_CALENDAR_ID = -1;

const TAG = 'AgendaDataModel';

export class AgendaListDataModel {
  private agendaResult: AgendaListItemViewModel[] = [];
  private range: DateRange.Range = { start: Date.now(), end: Date.now() };
  private maxRange: DateRange.Range = { start: Date.now(), end: Date.now() };
  private calendarUuid: string = '';
  private eventIdSet: Set<number> = new Set();
  // 状态值，不仅初始化需要用，上拉/下拉加载日程的时候也需要用
  private isShowHoliday: boolean = true;

  constructor(range: DateRange.Range, maxRange: DateRange.Range, calendarUuid: string) {
    cloneRange(this.range, range);
    cloneRange(this.maxRange, maxRange);
    this.calendarUuid = calendarUuid;
    this.isShowHoliday = PreferencesUtil.getBooleanValueSync(
      PreferencesFiles.AGENDA_LIST_IS_SHOW_HOLIDAY, AgendaListKey.IS_SHOW_HOLIDAY, true);
  }

  /**
   * 初始化日程列表
   * @param isDeFaultInit：是否默认初始化，如果否，则使用传入的时间范围进行初始化，否则用constructor的时间范围初始化
   * @param range
   * @param filterRepeat 是否过滤重复日程
   */
  public async init(isDeFaultInit: boolean = true, range: DateRange.Range = { start: Date.now(), end: Date.now() },
                    filterRepeat: boolean = false) {
    this.agendaResult = [];
    let queryTimes = 0;
    let result: AutoQueryResult = { agendaList: [], range: { start: Date.now(), end: Date.now() } };
    if (!isDeFaultInit) {
      cloneRange(this.range, range);
    }
    cloneRange(result.range, this.range);
    while (queryTimes <= MAX_AUTO_QUERY_TIMES) {
      let res = await this.query(result.range, filterRepeat);
      if (res.length >= MAX_AUTO_QUERY_LENGTH) {
        result.agendaList = res;
        break;
      }
      result.range.start = result.range.start - MILLS_THIRTY_DAYS;
      result.range.end = result.range.end + MILLS_THIRTY_DAYS;
      queryTimes++;
    }

    if (result.agendaList.length < MAX_AUTO_QUERY_LENGTH) {
      result.agendaList = await this.query(this.maxRange, filterRepeat);
      cloneRange(result.range, this.maxRange);
    }

    this.eventIdSet = new Set(result.agendaList.map(e=>e.mId));

    Log.info(TAG, `init result.agendaList length= ${result.agendaList.length}`);
    this.agendaResult = result.agendaList.map(e => new AgendaListItemViewModel(e));
    cloneRange(this.range, result.range);
  }

  /**
   * 从存储端获取日程数据
   * @param range
   * @param filterRepeat 是否过滤重复日程
   * @returns
   */
  private async query(range: DateRange.Range, filterRepeat: boolean = false): Promise<AgendaEventInfo[]> {
    try {
      const temp: QueryInfo = {
        startTime : range.start,
        endTime : range.end,
        filterRepeat : filterRepeat
      };
      if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
        temp.calendarUuid = this.calendarUuid;
      } else {
        // “我的日历”账户不可见时，查询全部日程需保留重要日
        const accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
        const defaultAccount = accounts.find(account => {
          AccountUtils.isDefaultAccount(account);
        })
        temp.keepImportantEvents = !defaultAccount?.visible;
      }
      Log.info(TAG, `query begin = ${temp.startTime}, query end = ${temp.endTime}`);
      let groupResult: AgendaEventInfo[] = await InstanceService.INSTANCE.queryInstanceGrouped(temp);
      // 过滤节假日日程
      if (!this.isShowHoliday) {
        groupResult = groupResult.filter(event => !event.isHoliday());
      }
      return groupResult;
    } catch (err) {
      Log.logErrorMsg(TAG, 'query failed', err);
      return [];
    }
  }

  /**
   * 自动扩展查询边界，查询日程
   * @param range
   * @param maxRange
   * @param isQueryPast
   * @returns AutoQueryResult
   */
  private async autoQueryAgenda(
    range: DateRange.Range,
    isQueryPast: boolean,
    filter: boolean = false
  ): Promise<AutoQueryResult> {
    let queryTimes = 1;
    const result: AutoQueryResult = { agendaList: [], range: { start: Date.now(), end: Date.now() } };
    cloneRange(result.range, range);

    while (queryTimes <= MAX_AUTO_QUERY_TIMES) {
      let res = await this.query(result.range, filter);

      if (isQueryPast) {
        result.agendaList = [...res, ...result.agendaList];
        if (result.agendaList.length >= MAX_AUTO_QUERY_LENGTH || result.range.start === this.maxRange.start) {
          break;
        }
        result.range.end = result.range.start;
        result.range.start = Math.max(this.maxRange.start, result.range.start - MILLS_THIRTY_DAYS);
      } else {
        result.agendaList = [...result.agendaList, ...res];
        if (result.agendaList.length >= MAX_AUTO_QUERY_LENGTH || result.range.end === this.maxRange.end) {
          break;
        }
        result.range.start = result.range.end;
        result.range.end = Math.min(this.maxRange.end, result.range.end + MILLS_THIRTY_DAYS);
      }

      queryTimes++;
    }

    if (result.agendaList.length < MAX_AUTO_QUERY_LENGTH) {
      if (isQueryPast) {
        result.range.start = this.maxRange.start;
        result.range.end = this.range.start;
        const res = await this.query(result.range, filter);
        result.agendaList = res;
      } else {
        result.range.end = this.maxRange.end;
        result.range.start = this.range.end;
        const res = await this.query(result.range, filter);
        result.agendaList = res;
      }
    }

    return result;
  }

  /**
   * 加载过去日程
   */
  public async queryPastAgenda(queryRange: DateRange.Range, filter: boolean = false): Promise<AutoQueryResult> {
    const result = await this.autoQueryAgenda(queryRange, true, filter);
    let list = result.agendaList.map(e => new AgendaListItemViewModel(e));
    if (filter) { // 过滤重复日程
      list = list.filter(e=>!this.eventIdSet.has(e.mId)); // 去掉已经有的EventId
    }
    this.agendaResult = [...list, ...this.agendaResult];
    this.eventIdSet = new Set(this.agendaResult.map(e=>e.mId)); // 生成最新的EventId 集合
    this.range.start = result.range.start;
    return result;
  }

  /**
   * 加载未来日程
   */
  public async queryFutureAgenda(queryRange: DateRange.Range, filter: boolean = false): Promise<AutoQueryResult> {
    const result = await this.autoQueryAgenda(queryRange, false, filter);
    let list = result.agendaList.map(e => new AgendaListItemViewModel(e));
    if (filter) { // 过滤重复日程
      list = list.filter(e=>!this.eventIdSet.has(e.mId)); // 去掉已经有的EventId
    }
    this.agendaResult = [...this.agendaResult, ...list];
    this.eventIdSet = new Set(this.agendaResult.map(e=>e.mId));
    this.range.end = result.range.end;
    return result;
  }

  public findIndexFromCache(targetAgenda: AgendaEventInfo): number {
    return this.agendaResult.findIndex(item => item.mId === targetAgenda.mId &&
      item.mBegin === targetAgenda.mBegin && item.mDay === targetAgenda.mDay);
  }

  public setMaxRange(maxRange: DateRange.Range) {
    cloneRange(this.maxRange, maxRange);
  }

  public getAgendaResult() {
    return this.agendaResult;
  }

  public setIsShowHoliday(isShowHoliday: boolean) {
    return this.isShowHoliday = isShowHoliday;
  }

  public getRange() {
    return this.range;
  }

  // 过滤重节假日
  public async filterHoliday() {
    this.agendaResult = this.agendaResult.filter(event => !event.isHoliday());
    return this.agendaResult;
  }

  public setData(events: AgendaListItemViewModel[]) {
    this.agendaResult = events;
  }
}

export interface AutoQueryResult {
  agendaList: AgendaEventInfo[];
  range: DateRange.Range;
}

export function cloneRange(newRange: DateRange.Range, range: DateRange.Range) {
  newRange.start = range.start;
  newRange.end = range.end;
}