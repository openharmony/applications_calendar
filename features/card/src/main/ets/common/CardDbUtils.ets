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
import { Log } from '@app/common/src/main/ets/default/common/Log';
import rpc from '@ohos.rpc';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { InnerResultSet } from '@app/common/src/main/ets/dao/util/InnerResultSet';
import { AgendaCardInfo } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { DateUtil, MILLS_PER_DAY } from '@app/common/src/main/ets/util/DateUtil';
import { AccountUtils } from '@app/common/src/main/ets/account/AccountUtils';
import HashMap from '@ohos.util.HashMap';
import { CommonService } from '@app/common/src/main/ets/dao/CommonService';
import { CardDeduplicateProcessor } from '../agendaCard/common/CardDeduplicateProcessor';

const TAG: string = 'CardDbUtils';

/**
 * 卡片数据库调用工具类。
 * 卡片依赖卡片框架，大部分类无法调用，故此添加本类，注意要最小化引入依赖，避免引入无法调用的类导致卡片崩溃。
 * 此类不能在卡片初始化时调用
 */
export class CardDbUtils {
  private static readonly QUERY_INSTANCE_PROJECTIONS: string[] = [
    'Instances._id',
    CalendarContract.InstancesColumns.EVENT_ID,
    CalendarContract.InstancesColumns.INSTANCE_BEGIN,
    CalendarContract.InstancesColumns.INSTANCE_END,
    CalendarContract.InstancesColumns.INSTANCE_START_DAY,
    CalendarContract.InstancesColumns.INSTANCE_END_DAY,
    CalendarContract.InstancesColumns.INSTANCE_START_MINUTE,
    CalendarContract.InstancesColumns.INSTANCE_END_MINUTE,
    CalendarContract.EventsColumns.TITLE,
    CalendarContract.EventsColumns.ALL_DAY,
    CalendarContract.EventsColumns.EVENT_LOCATION,
    CalendarContract.EventsColumns.CALENDAR_ID,
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
    'Events.creator',
    CalendarContract.EventsColumns.UUID,
    CalendarContract.EventsColumns.CALENDAR_UUID
  ];

  private static readonly QUERY_CALENDAR_PROJECTIONS: Array<string> = [
    CalendarContract.BaseColumns.ID,
    CalendarContract.SyncColumns.ACCOUNT_NAME,
    CalendarContract.SyncColumns.ACCOUNT_TYPE,
    CalendarContract.AccountColumns.NAME,
    CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME,
    CalendarContract.AccountColumns.CALENDAR_COLOR,
    CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL,
    CalendarContract.AccountColumns.VISIBLE,
    CalendarContract.AccountColumns.CAN_REMINDER,
    CalendarContract.AccountColumns.CREATOR,
    CalendarContract.AccountSyncColumns.CAL_SYNC1,
    CalendarContract.AccountSyncColumns.CAL_SYNC2,
    CalendarContract.AccountSyncColumns.CAL_SYNC3,
    CalendarContract.AccountSyncColumns.CAL_SYNC4,
    CalendarContract.AccountSyncColumns.CAL_SYNC5,
    CalendarContract.AccountSyncColumns.CAL_SYNC6,
    CalendarContract.AccountSyncColumns.CAL_SYNC7,
    CalendarContract.AccountSyncColumns.CAL_SYNC8,
    CalendarContract.AccountColumns.UUID
  ];

  private static dsHelper: dataShare.DataShareHelper | null = null;

  /**
   * 获取dataShareHelper
   * @returns
   */
  private static async getDsHelper(context: Context): Promise<dataShare.DataShareHelper> {
    if (CardDbUtils.dsHelper) {
      return CardDbUtils.dsHelper;
    }
    CardDbUtils.dsHelper = await dataShare.createDataShareHelper(context, 'datashare:///calendardata');
    return CardDbUtils.dsHelper;
  }

  /**
   * 查询指定天的日程
   * @param context
   * @param julianDay 儒略日
   * @returns
   */
  public static async queryAgendaByDay(context: Context, julianDay: number, limit: number): Promise<AgendaCardInfo[]> {
    if (limit <= 0) {
      Log.warn(TAG, `queryAgendaByDay get invalid limit ${limit}`);
      return [];
    }
    let activeDate = DateUtil.julianDay2Date(julianDay);
    let begin: number = DateUtil.getStartMillsOfDate(activeDate);
    let end: number = begin + MILLS_PER_DAY;
    // 对查询出的整天日程列表，返回给卡片前，需要进行限量处理
    const originalAgendaList: AgendaCardInfo[] = await CardDbUtils.queryRangeAgenda(context, begin, end);
    if (!originalAgendaList || originalAgendaList.length === 0) {
      return [];
    }
    // 对原始日程数据进行去重
    const agendaList = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(originalAgendaList);
    // 1.按照日程开始时间排序
    agendaList.sort((itemA: AgendaCardInfo, itemB: AgendaCardInfo) => {
      if (!itemA || !itemB) {
        return 0;
      }
      return itemA.mBegin - itemB.mBegin;
    });
    // 2.过滤一下，只返回前N条数据
    const resultList: AgendaCardInfo[] = [];
    for (let index = 0, len = agendaList.length; index < len; index++) {
      const item: AgendaCardInfo = agendaList[index];
      if (!item) {
        continue;
      }
      resultList.push(item);
      if (resultList.length > limit) {
        break;
      }
    }
    return resultList;
  }

  /**
   * 根据时间范围查询卡片列表日程
   * @param context
   * @param begin
   * @param end
   */
  public static async queryRangeAgenda(context: Context, begin: number, end: number): Promise<AgendaCardInfo[]> {
    Log.info(TAG, `queryRangeAgenda start,begin:${begin},end:${end} `);
    let resultSet: InnerResultSet | null = null;
    try {
      let dsHelper = await CardDbUtils.getDsHelper(context);
      let predicates = new dataSharePredicates.DataSharePredicates();
      let uri = `datashare:///calendardata/Instances?bundleName=com.ohos.calendar&tokenId=${rpc.IPCSkeleton.getCallingTokenId()}&begin=${begin}&end=${end}&orderByAsc=startDay`;
      let oriResultSet = await dsHelper.query(uri, predicates, CardDbUtils.QUERY_INSTANCE_PROJECTIONS);
      resultSet = new InnerResultSet(oriResultSet, TAG);
      if (!resultSet || resultSet.rowCount <= 0) {
        Log.warn(TAG, 'queryRangeAgenda is no data');
        return [];
      }
      const resultArray: AgendaCardInfo[] = [];
      const accountMap: HashMap<number, CalendarContract.Accounts> = await CardDbUtils.queryAllCalendarsMap(context);
      while (resultSet && resultSet.goToNextRow()) {
        const accId: number = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.EventsColumns.CALENDAR_ID));
        const importantEventType: number =
          resultSet.getLong(resultSet.getColumnIndex(CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE));
        if (importantEventType != 0) {
          continue;
        }
        const item: AgendaCardInfo = new AgendaCardInfo();
        item.parseFromCursor(resultSet);
        item.mDisplayColor = accountMap.get(accId)?.calendarColor;
        item.mCalendarType = accountMap.get(accId)?.accountType;
        if (accountMap.get(accId)?.visible == 1) {
          resultArray.push(item);
        }
      }
      return resultArray;
    } catch (e) {
      Log.logErrorMsg(TAG, 'queryRangeAgenda', e)
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return [];
  }

  /**
   * 获取全部日历账户的map
   * @param context
   */
  public static async queryAllCalendarsMap(context: Context) {
    const predicates = new dataSharePredicates.DataSharePredicates();
    let uri = `datashare:///calendardata/Calendars?bundleName=com.ohos.calendar&tokenId=${rpc.IPCSkeleton.getCallingTokenId()}`;
    let dsHelper = await CardDbUtils.getDsHelper(context);
    let oriResultSet = await dsHelper.query(uri, predicates, CardDbUtils.QUERY_CALENDAR_PROJECTIONS);
    let resultSet: InnerResultSet = new InnerResultSet(oriResultSet, TAG);
    if (!resultSet || resultSet.rowCount <= 0) {
      Log.warn(TAG, 'queryAllCalendarsMap is no data');
      return new HashMap<number, CalendarContract.Accounts>();
    }
    const accounts: CalendarContract.Accounts[] = CardDbUtils.parseCalendars(resultSet)
    // 将查询的帐户结果 result 转化为帐户数组
    const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
    return accountMap;
  }


  /**
   * 将查询的帐户结果 result 转化为帐户数组
   *
   * @param resultSet
   * @return 帐户数组
   */
  private static parseCalendars(resultSet: InnerResultSet | undefined,
                                columns?: string[]): CalendarContract.Accounts[] {
    const accounts: CalendarContract.Accounts[] = [];
    try {
      if (!resultSet) {
        Log.error(TAG, 'ResultSet invalid');
        return accounts;
      }
      if (!resultSet.goToFirstRow()) {
        Log.error(TAG, 'ResultSet go To first row failed');
        return accounts;
      }
      do {
        let account = CalendarContract.Accounts.parseAccountByResultSet(resultSet, columns);
        if (!account) {
          Log.warn(TAG, `parseCalendars error`)
          return [];
        }
        CardDbUtils.mapAccountColor(account);
        accounts.push(account);
      } while (resultSet.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseCalendars', err);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return accounts;
  }

  // 兼容旧账户颜色用转换函数
  private static mapAccountColor(account: CalendarContract.Accounts) {
    account.calendarColor = AccountUtils.getOldAccountMapNowAccount(account.calendarColor);
  }
}