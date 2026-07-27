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

import HashMap from '@ohos.util.HashMap';
import { AccountUtils } from '../account/AccountUtils';
import { AgendaEventInfo } from '../agenda/AgendaEventInfo';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { Log } from '../default/common/Log';
import { SqlFaultHandle } from '../default/util/ReportUtil';
import { DeduplicateProcessor } from '../event/DeduplicateProcessor';
import { EmptyUtils } from '../util/EmptyUtils';
import { QueryInfo } from './service/InstanceService';
import { InnerResultSet } from './util/InnerResultSet';
import { GlobalThis } from '../data/GlobalThis';
import { I18nUtil } from '../util/I18nUtil';

/**
 * 设置联系人生日标题
 */
function setBirthDayTitle(title: string): string {
  if (!title || title === '') {
    return '';
  }
  const language = I18nUtil.getSystemLanguage();
  const birthDay: Resource = $r('app.string.somebody_birthday');
  const place: string = '%s';
  return GlobalThis.getResourceStr(birthDay, language).replace(place, title);
}

export class CommonService {
  static readonly INSTANCE: CommonService = new CommonService();

  private constructor() {
  }

  /**
   * 创建帐户 UUID 到 帐户的 map 映射
   * @param accounts 帐户列表
   */
  public getAccountByUuidMap(accounts: CalendarContract.Accounts[]
  ): HashMap<string, CalendarContract.Accounts> {
    let accountMap: HashMap<string, CalendarContract.Accounts> = new HashMap<string, CalendarContract.Accounts>();
    for (let i = 0; i < accounts.length; i++) {
      accountMap.set(accounts[i].uuid, this.deepCloneAccounts(accounts[i]));
    }
    return accountMap;
  }

  /**
   * 创建帐户 ID 到 帐户的 map 映射
   * @param accounts 帐户列表
   */
  public getAccountMap(accounts: CalendarContract.Accounts[]): HashMap<number, CalendarContract.Accounts> {
    let accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap<number, CalendarContract.Accounts>();
    for (let i = 0; i < accounts.length; i++) {
      accountMap.set(accounts[i].id, this.deepCloneAccounts(accounts[i]));
    }
    return accountMap;
  }

  deepCloneAccounts(account: CalendarContract.Accounts): CalendarContract.Accounts {
    let newAccount: CalendarContract.Accounts = new CalendarContract.Accounts();
    newAccount.id = account.id;
    newAccount.accountName = account.accountName;
    newAccount.accountType = account.accountType;
    newAccount.name = account.name;
    newAccount.calendarDisplayName = account.calendarDisplayName;
    newAccount.calendarColor = account.calendarColor;
    newAccount.calendarAccessLevel = account.calendarAccessLevel;
    newAccount.visible = account.visible;
    newAccount.canReminder = account.canReminder;
    newAccount.uuid = account.uuid;
    newAccount.creator = account.creator;
    return newAccount;
  }
}

export async function silentGetAgendaEventInfos(
  queryInfo: QueryInfo,
  accounts: CalendarContract.Accounts[],
  tmpResultArray: AgendaEventInfo[],
  deduplicateProcessor:DeduplicateProcessor,
  tag: string): Promise<AgendaEventInfo[]> {
  let resultArray: AgendaEventInfo[] = [];
  // 将查询的帐户结果 result 转化为帐户数组
  const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);

  if (queryInfo.skipQueryAccount) {
    const uniqueArray = await deduplicateProcessor.reduceAgendaEventInfos(tmpResultArray, accountMap);
    return uniqueArray;
  }
  const calendarCheck = queryInfo.calendarId !== undefined && queryInfo.calendarId !== null;

  // 处理数据
  for (let item of tmpResultArray) {
    if (calendarCheck && item.mCalendarId !== queryInfo.calendarId) {
      continue;
    }
    let account: CalendarContract.Accounts = accountMap.get(item.mCalendarId);
    // 过滤联系人无identifier的日程
    if (AccountUtils.isConcatAccount(account) && !item.identifier) {
      Log.warn(tag, 'concat agenda identifier is null, not show');
      continue;
    }
    if (calendarCheck || account?.visible) {
      item.mDisplayColor = account?.calendarColor ?? 0;
      // 设置生日标题
      const isBirthDay = AccountUtils.isBirthDayAccount(account);
      item.mTitle = isBirthDay ? setBirthDayTitle(item.mTitle) : item.mTitle;
      resultArray.push(item);
    } else if (queryInfo.keepImportantEvents &&
      (item.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
        item.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN)) {
      // “我的日历”账户不可见时，查询全部日程需保留重要日
      resultArray.push(item);
    }
  }
  return await deduplicateProcessor.reduceAgendaEventInfos(resultArray, accountMap);
}

export async function silentGetAgendaEventInfosByCalendarUuid(
  queryInfo: QueryInfo,
  accounts: CalendarContract.Accounts[],
  tmpResultArray: AgendaEventInfo[],
  deduplicateProcessor:DeduplicateProcessor,
  tag: string): Promise<AgendaEventInfo[]> {
  // 将查询的帐户结果 result 转化为帐户数组
  const accountMap: HashMap<string, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountByUuidMap(accounts);
  // 当日程的 calendar_uuid 为空时(如三方应用创建的日程未设置此字段), 回退用 calendar_id 查找日历账户
  const accountMapById: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);

  let resultArray: AgendaEventInfo[] = [];
  // 处理数据
  for (let item of tmpResultArray) {
    if (queryInfo.calendarUuid && item.mCalendarUuid !== queryInfo.calendarUuid) {
      continue;
    }

    let account = accountMap.get(item.mCalendarUuid);
    // calendar_uuid 为空时回退用 calendar_id 查找日历账户
    if (!account && item.mCalendarId) {
      account = accountMapById.get(item.mCalendarId);
    }
    // 过滤联系人无identifier的日程
    if (AccountUtils.isConcatAccount(account) && !item.identifier) {
      Log.warn(tag, 'concat agenda identifier is null, not show');
      continue;
    }
    if (!account || account.visible || !EmptyUtils.isEmptyString(queryInfo.calendarUuid, true)) {
      item.mDisplayColor = account?.calendarColor ?? 0;
      if (account) {
        item.mCalendarId = account.id;
      }
      // 设置生日标题
      const isBirthDay = AccountUtils.isBirthDayAccount(account);
      item.isBirthDay = isBirthDay;
      item.mTitle = isBirthDay ? setBirthDayTitle(item.mTitle) : item.mTitle;
      resultArray.push(item);
    } else if (queryInfo.keepImportantEvents &&
      (item.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
        item.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN)) {
      // “我的日历”账户不可见时，查询全部日程需保留重要日
      resultArray.push(item);
    }
  }
  return await deduplicateProcessor.reduceAgendaEventInfosByCalendarUuid(resultArray, accountMap);
}

export async function getAgendaEventInfos(
  queryInfo: QueryInfo,
  accounts: CalendarContract.Accounts[],
  resultArray: AgendaEventInfo[],
  deduplicateProcessor:DeduplicateProcessor,
  resultSet: InnerResultSet,
  tag: string): Promise<AgendaEventInfo[]> {
  // 将查询的帐户结果 result 转化为帐户数组
  const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);

  const calendarCheck = queryInfo.calendarId !== undefined && queryInfo.calendarId !== null;

  let eventIdSet = new Set<number>();
  const holidaySet = new Set<string>();
  try {
    while (resultSet && resultSet.goToNextRow()) {
      const accId: number = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.EventsColumns.CALENDAR_ID));
      if (calendarCheck && accId !== queryInfo.calendarId) {
        continue;
      }
      const item: AgendaEventInfo = new AgendaEventInfo();
      item.parseFromCursor(resultSet);
      let account = accountMap.get(accId);
      item.mDisplayColor = account?.calendarColor ?? 0;
      if (calendarCheck || account?.visible) {
        if (queryInfo?.filterRepeat && eventIdSet.has(item.mId)) {
          continue; // 重复日程过滤
        }
        // 过滤联系人无identifier的日程
        if (AccountUtils.isConcatAccount(account) && !item.identifier) {
          Log.warn(tag, 'concat agenda identifier is null, not show');
          continue;
        }
        // 过滤重复节日
        if (item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
          if (holidaySet.has(item.mTitle + '-' + item.mStartDay)) {
            continue;
          }
          holidaySet.add(item.mTitle + '-' + item.mStartDay);
        }
        // 设置生日标题
        const isBirthDay = AccountUtils.isBirthDayAccount(account);
        item.mTitle = isBirthDay ? setBirthDayTitle(item.mTitle) : item.mTitle;
        eventIdSet.add(item.mId);
        resultArray.push(item);
      } else if (queryInfo.keepImportantEvents &&
        (item.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
          item.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN)) {
        // “我的日历”账户不可见时，查询全部日程需保留重要日
        resultArray.push(item);
      }
    }
  } catch (err) {
    Log.logErrorMsg(tag, 'queryInstance', err);
    SqlFaultHandle.querySqlFail(err?.message, 'InstancesService');
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  const uniqueArray = await deduplicateProcessor.reduceAgendaEventInfos(resultArray, accountMap);
  return uniqueArray;
}

export async function getAgendaEventInfosByCalendarUuid(
  queryInfo: QueryInfo,
  accounts: CalendarContract.Accounts[],
  resultArray: AgendaEventInfo[],
  deduplicateProcessor:DeduplicateProcessor,
  resultSet: InnerResultSet,
  tag: string): Promise<AgendaEventInfo[]> {
  // 将查询的帐户结果 result 转化为帐户数组
  const accountMap: HashMap<string, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountByUuidMap(accounts);
  // 当日程的 calendar_uuid 为空时(如三方应用创建的日程未设置此字段), 回退用 calendar_id 查找日历账户
  const accountMapById: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);

  let eventIdSet = new Set<number>();
  const holidaySet = new Set<string>();
  try {
    while (resultSet && resultSet.goToNextRow()) {
      const accId: number = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.EventsColumns.CALENDAR_ID));
      if (queryInfo.calendarId && accId !== queryInfo.calendarId) {
        continue;
      }
      const accUuid: string =
        resultSet.getString(resultSet.getColumnIndex(CalendarContract.EventsColumns.CALENDAR_UUID));
      if (queryInfo.calendarUuid && accUuid !== queryInfo.calendarUuid) {
        continue;
      }

      const item: AgendaEventInfo = new AgendaEventInfo();
      item.parseFromCursor(resultSet);
      let account = accountMap.get(accUuid);
      // calendar_uuid 为空时回退用 calendar_id 查找日历账户
      if (!account && accId) {
        account = accountMapById.get(accId);
      }
      item.mDisplayColor = account?.calendarColor ?? 0;
      if (!account || account.visible || !EmptyUtils.isEmptyString(queryInfo.calendarUuid, true)) {
        if (queryInfo?.filterRepeat && eventIdSet.has(item.mId)) {
          continue; // 重复日程过滤
        }
        // 过滤联系人无identifier的日程
        if (AccountUtils.isConcatAccount(account) && !item.identifier) {
          Log.warn(tag, 'concat agenda identifier is null, not show');
          continue;
        }
        // 过滤重复节日
        if (item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
          if (holidaySet.has(item.mTitle + '-' + item.mStartDay)) {
            continue;
          }
          holidaySet.add(item.mTitle + '-' + item.mStartDay);
        }
        // 设置生日标题
        const isBirthDay = AccountUtils.isBirthDayAccount(account);
        item.isBirthDay = isBirthDay;
        item.mTitle = isBirthDay ? setBirthDayTitle(item.mTitle) : item.mTitle;
        eventIdSet.add(item.mId);
        resultArray.push(item);
      } else if (queryInfo.keepImportantEvents &&
        (item.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
          item.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN)) {
        // “我的日历”账户不可见时，查询全部日程需保留重要日
        resultArray.push(item);
      }
    }
  } catch (err) {
    Log.logErrorMsg(tag, 'queryInstance', err);
    SqlFaultHandle.querySqlFail(err?.message, 'InstancesService');
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  const uniqueArray = await deduplicateProcessor.reduceAgendaEventInfosByCalendarUuid(resultArray, accountMap);
  return uniqueArray;
}


export enum ServiceAction {

  // AttendeeService
  QUERY_ATTENDEE_BY_EVENT_ID,
  QUERY_ATTENDEE_INFO_BY_EVENT_ID,

  // CalendarService
  QUERY_CALENDAR_LIST,
  INSERT_CALENDAR,
  DELETE_CALENDAR_BY_ID,
  UPDATE_CALENDAR_BY_ID,


  // EventService
  QUERY_EVENT_BY_ID,
  QUERY_EVENTS_IN_FUSION_SEARCH, // 通过智慧搜索能力实现日程查询
  UPDATE_EVENT_AND_REMINDER,
  DELETE_EVENT_BY_ID,
  DELETE_EVENTS_BY_IDS,
  INSERT_EVENT_AND_REMINDER,
  QUERY_EVENTS,
  QUERY_EVENT_BY_EVENT_ID,
  INSERT_EVENT,
  UPDATE_BY_EVENT_ID,
  DELETE_EVENTS_BY_EVENT_IDS,

  // InstanceService
  QUERY_INSTANCE_BY_CONDITION,
  QUERY_INSTANCE,
  QUERY_INSTANCE_GROUP,

  // ReminderService
  UPDATE_REMINDER_BY_REPLACE,
  INSERT_REMINDERS,
  QUERY_REMINDER_INFO_BY_EVENT_ID,
  INSERT_REMINDER,
  DELETE_REMINDER_BY_ID,
  DELETE_REMINDER_BY_EVENT_ID,
  UPDATE_REMINDER_BY_ID,
  QUERY_REMINDER_BY_EVENT_ID,

  // OneLinkDataService
  INSERT_ONE_LINK_DATA

}