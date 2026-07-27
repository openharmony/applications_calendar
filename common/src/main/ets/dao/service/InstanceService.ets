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

import { InstanceRepository } from '../repo/InstanceRepository';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { AgendaEventInfo } from '../../agenda/AgendaEventInfo';
import { CommonService,
  getAgendaEventInfos,
  getAgendaEventInfosByCalendarUuid,
  silentGetAgendaEventInfos, silentGetAgendaEventInfosByCalendarUuid } from '../CommonService';
import HashMap from '@ohos.util.HashMap';
import { CalendarService } from './CalendarService';
import { CornerType } from '../../agenda/CornerType';
import { Log } from '../../default/common/Log';
import { maskString } from '../../util/SensitiveStrUtils';
import { reInitGlobalContextInTaskPool, runTaskAsync } from '../../util/TaskPool';
import { GlobalThis } from '../../data/GlobalThis';
import common from '@ohos.app.ability.common';
import { AgendaUtil } from '../../agenda/AgendaUtil';
import { CalendarMetaDataService } from './CalendarMetaDataService';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';
import lazy { EventService } from './EventService';
import lazy { taskpool } from '@kit.ArkTS';
import { CalendarDate } from '../../date/CalendarDate';
import { DeduplicateProcessor } from '../../event/DeduplicateProcessor';
import { CalendarDataFeature, CalendarDataFeatureHelper } from '../../util/CalendarDataFeatureHelper';

const TAG = 'InstanceService';
const taskMaxIndex = 100;
const TEN_MILLS_PER_SECOND =  10000;

export class InstanceService {
  static readonly INSTANCE: InstanceService = new InstanceService();
  private taskIndex = 0; // 当前所在的线程索引
  private constructor() {
  }

  /**
   * 查询日程
   *
   * @param queryInfo 搜索条件
   */
  async queryInstanceAsync(queryInfo: QueryInfo): Promise<Array<AgendaEventInfo>> {
    const context = GlobalThis.getInstance().getDbContext();
    if (!context) {
      Log.warn(TAG, 'queryInstanceAsync context invalid');
      return [];
    }
    let canSilentQuery = await this.canSilentQuery(queryInfo);
    let data: AgendaEventInfo[] = [];
    if (this.taskIndex >= taskMaxIndex) {
      this.taskIndex = 0;
    }
    this.taskIndex += 1;
    if (canSilentQuery) {
      data = await runTaskAsync(silentQueryInstancesTask, this.taskIndex, context, queryInfo, DeduplicateProcessor.INSTANCE) as AgendaEventInfo[];
    } else {
      data = await runTaskAsync(queryInstancesTask, this.taskIndex, context, queryInfo, DeduplicateProcessor.INSTANCE) as AgendaEventInfo[];
    }
    Log.info(TAG, `querInstancesAsync range=${queryInfo?.startTime}->${queryInfo?.endTime}
                      filterRepeat:${queryInfo?.filterRepeat} length: ${data.length}`);
    return data.map(item => new AgendaEventInfo(item));
  }

  private metaData : CalendarContract.CalendarMetaData = new CalendarContract.CalendarMetaData;
  private lastLoadMateDataTime: number = Date.now();

  async canSilentQuery(queryInfo: QueryInfo): Promise<boolean> {
    const isSupportProxyFeature = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.DB_PROXY);
    if (!isSupportProxyFeature) {
      return false;
    }
    const tag = TAG + '-canSilentQuery';
    const beginTime = queryInfo.startTime;
    const endTime = queryInfo.endTime;
    Log.info(tag, `check begin: ${beginTime} end : ${endTime}`);
    // 如果扩展时间段已经包含查询时间，直接静默查询, 就不用再查询，区间只会越来越大
    const now: number = Date.now();

    // 缓存超过10s后失效，重新从数据库中获取
    if ((now - this.lastLoadMateDataTime < TEN_MILLS_PER_SECOND)
      && this.metaData.minInstance <= beginTime && this.metaData.maxInstance >= endTime) {
      Log.info(tag, `check ok`);
      return true;
    }
    Log.info(tag, `data not init, need query`);
    this.lastLoadMateDataTime = now;
    this.metaData = await CalendarMetaDataService.INSTANCE.query();
    // 查询失败：可能是没有建立数据库, 还是走非静默查询
    Log.info(tag, `minInstance:${this.metaData.minInstance}, maxInstance:${this.metaData.maxInstance}`);
    if (this.metaData.minInstance <= beginTime && this.metaData.maxInstance >= endTime) {
      Log.info(tag, 'check ok');
      return true;
    }
    Log.info(tag, 'check failed');
    return false;
  }

  /**
   * 查询分组后的日程
   *
   * @param queryInfo 搜索条件
   * @return Array<AgendaEventInfo> 分组后的日程
   */
  async queryInstanceGrouped(queryInfo: QueryInfo): Promise<AgendaEventInfo[]> {
    // 查询日程
    const begin: number = Date.now();
    if (queryInfo) {
      queryInfo.useCalendarUuid = true;
    }
    const result: Array<AgendaEventInfo> = await this.queryInstanceAsync(queryInfo);
    Log.info(TAG, `querInstancesAsync cost ${Date.now() - begin}ms, range=${queryInfo?.startTime}->${queryInfo?.endTime}`);
    if (result.length === 0) {
      return [];
    }
    const julianDayBegin: number = new CalendarDate(queryInfo.startTime).getJulianDay();
    const julianDayEnd: number = new CalendarDate(queryInfo.endTime).getJulianDay();

    return this.groupAgendaByDay(result, julianDayBegin, julianDayEnd);
  }

  async queryAccountListTask(): Promise<CalendarContract.Accounts[]> {
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.warn(TAG, `queryAccountListTask get invalid context`);
      return [];
    }
    const data = (await runTaskAsync(queryAccountListTask, context)) as CalendarContract.Accounts[];
    let invisibleAccountNum: number = 0;
    data.forEach((account) => {
      if (!account?.visible) {
        invisibleAccountNum++;
      }
    });
    Log.info(TAG, `queryAccountListTask result length is ${data?.length}, invisibleAccountNum = ${invisibleAccountNum}`);
    return data;
  }

  /**
   * 按天对日程分组
   *
   * @param originList 待分组日程项
   * @param rangeBegin 分组的范围开始
   * @param rangeEnd 分组的范围结束
   */
  private async groupAgendaByDay(originList: Array<AgendaEventInfo>, julianDayBegin: number, julianDayEnd: number): Promise<Array<AgendaEventInfo>> {
    if (originList.length === 0) {
      return [];
    }

    const data: AgendaEventInfo[] = (await runTaskAsync(groupAgendaByDayTask, originList, julianDayBegin, julianDayEnd)) as AgendaEventInfo[];
    // taskpool返回的数据，只有属性，没有方法，因此需要重新new
    return data.map(item => new AgendaEventInfo(item));
  }

  async queryImportantEventsTask(): Promise<Array<AgendaEventInfo>> {
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `queryImportantEventsTask get invalid context`);
      return [];
    }
    const data = (await runTaskAsync(queryImportantAgendaTask, context, DeduplicateProcessor.INSTANCE)) as AgendaEventInfo[];
    Log.info(TAG, `queryImportantEventsTask result length is ${data?.length}`);
    return data.map(item => new AgendaEventInfo(item));
  }
}

@Concurrent
async function silentQueryInstancesTask(taskIndex: number, context: common.UIAbilityContext,
                                        queryInfo: QueryInfo, deduplicateProcessor:DeduplicateProcessor) : Promise<AgendaEventInfo[]> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const resultArray: AgendaEventInfo[] = [];
  const TAG: string = `InstancesService-task-silent-${taskIndex}`;
  const getLong = DataShareResultUtil.getColumnLongData;
  const repo: InstanceRepository = new InstanceRepository();
  const beginTime = queryInfo.startTime;
  const endTime = queryInfo.endTime;
  const searchText = queryInfo.searchText || '';
  const literalSearchCharacters: string = '@#$%_?';
  let useLiteralSearch: boolean = false;
  for (const char of literalSearchCharacters) {
    if (searchText.includes(char)) {
      useLiteralSearch = true;
      break;
    }
  }
  const eventIds = queryInfo.eventIds;
  Log.info(TAG, `start beginTime:${beginTime}, endTime:${endTime}, eventIds: ${eventIds}`);
  let resultSet = await repo.queryConditionSilent(beginTime, endTime, eventIds);
  if (!resultSet) {
    Log.error(TAG, 'get instance result is null');
    return [];
  }
  // 查询到数据之后, 再去查Events表, 填充Instance的数据
  Log.info(TAG, `get instance count ${resultSet.rowCount}`);
  const eventUuidList: string[] = [];
  const eventUuidSet = new Set<string>();
  const holidaySet = new Set<string>();
  const instanceResultArray: AgendaEventInfo[] = []; // 原始数据
  try {
    if (resultSet.rowCount <= 0) {
      Log.warn(TAG, 'get instance empty');
      return [];
    }
    // 获取eventId集合，批量查询
    resultSet.goToFirstRow();
    do {
      const item: AgendaEventInfo = new AgendaEventInfo();
      item.mId = getLong(resultSet, CalendarContract.InstancesColumns.EVENT_ID, 0);
      item.mStartDay = getLong(resultSet, CalendarContract.InstancesColumns.INSTANCE_START_DAY, 0);
      item.mEndDay = getLong(resultSet, CalendarContract.InstancesColumns.INSTANCE_END_DAY, 0);
      item.mBegin = getLong(resultSet, CalendarContract.InstancesColumns.INSTANCE_BEGIN, 0);
      item.mEnd = getLong(resultSet, CalendarContract.InstancesColumns.INSTANCE_END, 0);
      item.uuid = DataShareResultUtil.getColumnStringData(resultSet, 'event_uuid', '');
      item.mCalendarUuid = DataShareResultUtil.getColumnStringData(resultSet, CalendarContract.EventsColumns.CALENDAR_UUID, '');
      instanceResultArray.push(item);
      if (!eventUuidSet.has(item.uuid)) {
        eventUuidSet.add(item.uuid);
        eventUuidList.push(item.uuid);
      }
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.warn(TAG, `instance prase err ${err?.code} ${err?.message}`);
  } finally {
    resultSet?.close();
  }
  Log.debug(TAG, `queryEventsByEventIds id cout:${eventUuidList.length}`);
  taskpool.Task.sendData(TAG, true);
  const eventMaxIndex = 1000;
  let eventUuidListGroup: string[][] = [];
  for (let i = 0; i < eventUuidList.length; i += eventMaxIndex) {
    eventUuidListGroup.push(eventUuidList.slice(i, i + eventMaxIndex));
  }
  const eventResultArray: AgendaEventInfo[] = [];
  for (let eventUuids of eventUuidListGroup) {
    const eventResultList = await EventService.INSTANCE.queryEventsByEventUuids(eventUuids, undefined,
      useLiteralSearch ? '' : searchText);
    for (let event of eventResultList) {
      eventResultArray.push(event);
    }
  }
  taskpool.Task.sendData(TAG, false);
  Log.info(TAG, `queryEventsByEventIds eventResultArray cout:${eventResultArray.length}`);
  const tmpResultArray: AgendaEventInfo[] = []; // 原始数据
  eventUuidSet.clear();
  for (let item of instanceResultArray) {
    const eventItem = eventResultArray.find(it => it.uuid === item.uuid);
    if (!eventItem) {
      Log.error(TAG, `find event failed id: ${item.mId}, event_uuid: ${maskString(item.uuid)}`);
      continue;
    }
    // 日程id与instance eventId不一致 ，日程错乱维测
    if (eventItem.mId !== item.mId) {
      Log.error(TAG, `find event error id: ${eventItem.mId} instance eventId: ${item.mId}, begin/end: ${item.mBegin}/${item.mEnd}, uuid: ${maskString(item.uuid)}`);
    }
    if (queryInfo.filterRepeat && eventUuidSet.has(item.uuid)) {
      continue; // 过滤重复日程
    }
    // 过滤重复节日
    if (eventItem.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      if (holidaySet.has(eventItem.mTitle + '-' + item.mStartDay)) {
        continue;
      }
      holidaySet.add(eventItem.mTitle + '-' + item.mStartDay);
    }
    let newItem = new AgendaEventInfo(eventItem); // 拷贝构造
    newItem.mStartDay = item.mStartDay;
    newItem.mEndDay = item.mEndDay;
    newItem.mBegin = item.mBegin;
    newItem.mEnd = item.mEnd;
    newItem.mIsMultiDayEvent = newItem.mStartDay !== newItem.mEndDay;
    eventUuidSet.add(item.uuid);
    tmpResultArray.push(newItem);
  }
  // 查询  账户 - calendar
  let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
  Log.info(TAG, `queryCalendarList accounts: ${accounts.length}`);

  let uniqueArray: AgendaEventInfo[] = [];
  if (queryInfo.useCalendarUuid) {
    Log.info(TAG, 'fill display color by calendar_uuid');
    uniqueArray =
      await silentGetAgendaEventInfosByCalendarUuid(queryInfo, accounts, tmpResultArray, deduplicateProcessor, TAG);
  } else {
    uniqueArray = await silentGetAgendaEventInfos(queryInfo, accounts, tmpResultArray, deduplicateProcessor, TAG);
  }
  Log.info(TAG, 'end');
  return useLiteralSearch ? uniqueArray.filter((event: AgendaEventInfo): boolean => {
    return event.mTitle.includes(searchText) || event.mLocation.includes(searchText) ||
      event.mDescription.includes(searchText);
  }) : uniqueArray;
}

@Concurrent
async function queryInstancesTask(taskIndex: number, context: common.UIAbilityContext, queryInfo: QueryInfo,
                                  deduplicateProcessor:DeduplicateProcessor): Promise<AgendaEventInfo[]> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const resultArray: AgendaEventInfo[] = [];
  const TAG: string = 'InstancesService-task-' + taskIndex.toString();
  const repo: InstanceRepository = new InstanceRepository;
  const searchText = queryInfo.searchText || '';
  const literalSearchCharacters: string = '@#$%_?';
  let useLiteralSearch: boolean = false;
  for (const char of literalSearchCharacters) {
    if (searchText.includes(char)) {
      useLiteralSearch = true;
      break;
    }
  }
  Log.info(TAG, 'start');
  // 条件查询
  try {
    const resultSet = await repo.queryCondition(queryInfo.startTime, queryInfo.endTime,
      useLiteralSearch ? undefined : queryInfo.searchText);
    if (!resultSet || resultSet.rowCount <= 0) {
      Log.warn(TAG, 'there is no data');
      return [];
    }

    // 查询  账户 - calendar
    let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();

    let uniqueArray: AgendaEventInfo[] = [];
    if (queryInfo.useCalendarUuid) {
      uniqueArray =
        await getAgendaEventInfosByCalendarUuid(queryInfo, accounts, resultArray, deduplicateProcessor, resultSet, TAG);
    } else {
      uniqueArray = await getAgendaEventInfos(queryInfo, accounts, resultArray, deduplicateProcessor, resultSet, TAG);
    }
    return useLiteralSearch ? uniqueArray.filter((event: AgendaEventInfo): boolean => {
      return event.mTitle.includes(searchText) || event.mLocation.includes(searchText) ||
        event.mDescription.includes(searchText);
    }) : uniqueArray;
  } catch (err) {
    Log.error(TAG, `queryInstancesTask getErr: ${err?.message}`);
  }
  Log.info(TAG, 'queryInstancesTask end');
  return [];
}

@Concurrent
function groupAgendaByDayTask(originList: Array<AgendaEventInfo>, julianDayBegin: number, julianDayEnd: number): Array<AgendaEventInfo> {
  const res: Array<AgendaEventInfo> = [];
  const startDay: number = Math.min(...originList.map((item: AgendaEventInfo) => item.mStartDay));
  const startJulianDay: number = Math.max(startDay, julianDayBegin);
  const endDay: number = Math.max(...originList.map((item: AgendaEventInfo) => item.mEndDay));
  const endJulianDay: number = Math.min(endDay, julianDayEnd);

  let groupOneDay: (day: number) => AgendaEventInfo[] = (day: number): AgendaEventInfo[] => {
    const oneDayList: AgendaEventInfo[] = [];
    for (let item of originList) {
      if (item.mStartDay > day || item.mEndDay < day) {
        continue;
      }

      const info: AgendaEventInfo = new AgendaEventInfo(item);
      info.setFlag(day);
      oneDayList.push(info);
    }
    return oneDayList;
  }

  let setCorner: (oneDayList: AgendaEventInfo[]) => void = (oneDayList: AgendaEventInfo[]): void => {
    if (oneDayList.length > 0) {
      oneDayList[0].mIsSetDayHead = true;
      if (oneDayList.length === 1) {
        oneDayList[0].mCornerType = CornerType.CORNER_ALL;
      } else {
        oneDayList[0].mCornerType = CornerType.CORNER_UP;
        oneDayList[oneDayList.length - 1].mCornerType = CornerType.CORNER_DOWN;
      }
    }
  }

  let sortList: (a: AgendaEventInfo, b: AgendaEventInfo) => number = (a: AgendaEventInfo, b: AgendaEventInfo): number => {
    // 1. 节假日排在最前面
    if (a.isHoliday() && !b.isHoliday()) {
      return -1;
    }

    if (!a.isHoliday() && b.isHoliday()) {
      return 1;
    }

    if (a.isHoliday() && b.isHoliday() && a.mTitle === '入九' && b.mTitle === '冬至') {
      return 1;
    }

    // 2. 全天日程排在节假日之后
    if (a.mIsAllDay && !b.mIsAllDay) {
      return -1;
    }

    if (!a.mIsAllDay && b.mIsAllDay) {
      return 1;
    }

    // 3. 分时段日程按开始时间排序
    if (a.mBegin !== b.mBegin) {
      return a.mBegin - b.mBegin;
    }

    if (a.mEnd !== b.mEnd) {
      return a.mEnd - b.mEnd;
    }

    // 4. 如果时间和结束时间都相同，按标题排序
    const getTitle = (item: AgendaEventInfo): string => {
      return item.mTitle ?? '';
    };
    return getTitle(a).localeCompare(getTitle(b));
  }

  for (let day = startJulianDay; day <= endJulianDay; day++) {
    const oneDayList: Array<AgendaEventInfo> = groupOneDay(day);
    oneDayList.sort((a: AgendaEventInfo, b: AgendaEventInfo) => sortList(a, b));
    setCorner(oneDayList);
    AgendaUtil.findConflictAgenda(oneDayList.filter(event => !event.isImportantEvent()));
    for (const item of oneDayList) {
      res.push(item);
    }
  }
  return res;
}

@Concurrent
async function queryImportantAgendaTask(
  context: common.UIAbilityContext, deduplicateProcessor:DeduplicateProcessor): Promise<Array<AgendaEventInfo>> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const TAG: string = 'queryImportantAgenda_task';

  // 条件查询
  try {
    const importantAgendaList = await EventService.INSTANCE.queryImportantEvents();
    // 查询  账户 - calendar
    let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
    Log.info(TAG, `queryCalendarList accounts: ${accounts.length}`);
    // 将查询的帐户结果 result 转化为帐户数组
    const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
    const agendaEventInfos = await deduplicateProcessor.reduceAgendaEventInfos(importantAgendaList, accountMap);
    return agendaEventInfos;
  } catch (error) {
    Log.error(TAG, `queryImportantAgendaTask getErr: ${error?.message}`);
  }
  return [];
}

@Concurrent
async function queryAccountListTask(
  context: common.UIAbilityContext): Promise<CalendarContract.Accounts[]> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const TAG: string = 'queryAccountListTask_task';

  // 条件查询
  try {
    let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
    return accounts;
  } catch (error) {
    Log.error(TAG, `queryAccountListTask_task getErr: ${error?.message}`);
  }
  return [];
}

export interface QueryInfo {
  startTime: number; // 起始时间戳
  endTime: number;   // 结束时间戳
  calendarId?: number;
  skipQueryAccount?: boolean;
  filterRepeat?: boolean;
  keepImportantEvents?: boolean;
  searchText?: string;
  currentPage?: number;
  eventIds?: number[];
  useCalendarUuid?: boolean;
  calendarUuid?: string;
}