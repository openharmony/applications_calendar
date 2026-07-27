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

import { CalendarRepository } from '../repo/CalendarRepository';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { Log } from '../../default/common/Log';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { EmptyUtils } from '../../util/EmptyUtils';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '../../default/common/TraceEvents';
import { Result } from '../../templates/Result';
import { dataSharePredicates } from '@kit.ArkData';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';
import { AccountUtils } from '../../account/AccountUtils';
import { InnerResultSet } from '../util/InnerResultSet';
import { CALENDAR_BUNDLE_NAME } from '../../constants/Constants';
import { CalendarAccountType } from '../../account/AccountConst';
import deviceInfo from '@ohos.deviceInfo';
import { CommonStatusHelper } from '../helper/CommonStatusHelper';

const TAG = 'CalendarService';

export class CalendarService {
  static readonly INSTANCE: CalendarService = new CalendarService();
  public repo: CalendarRepository;

  private constructor() {
    this.repo = new CalendarRepository;
  }

  // 兼容旧账户颜色用转换函数
  private mapAccountColor(account: CalendarContract.Accounts) {
    account.calendarColor = AccountUtils.getOldAccountMapNowAccount(account.calendarColor);
  }

  /**
   * 查询数据库，获取帐户列表数组
   *
   * @return 帐户数组
   */
  async queryCalendarList(): Promise<CalendarContract.Accounts[]> {
    // 删除异常的帐户
    const resultAccounts: CalendarContract.Accounts[] = [];
    const deleteAccountIds: number[] = [];
    let resultSet: InnerResultSet | undefined = undefined;
    try {
      // 查询所有calendar
      resultSet = await this.repo.queryCalendars();
      // 解析=>  账户 - calendar
      const accounts: CalendarContract.Accounts[] = this.parseCalendars(resultSet);
      accounts.forEach((account: CalendarContract.Accounts) => {
        if (!account) {
          return;
        }
        // 联系人生日账户去重
        if (AccountUtils.isBirthDayAccount(account)) {
          let duplicateAcc = resultAccounts.find(acc => acc.uuid === account.uuid);
          if (duplicateAcc !== undefined) {
            duplicateAcc.id = Math.min(duplicateAcc.id, account.id);
            Log.info(TAG, `duplicateAccountId: ${duplicateAcc.id}`);
            return;
          }
        }
        if (this.isExceptionAccount(account) && deviceInfo.deviceType !== 'wearable') {
          Log.warn(TAG, `delete exception account: ${account.id}, ${account.accountType}/${account.creator}`);
          deleteAccountIds.push(account.id);
        } else {
          resultAccounts.push(account);
        }
      });
      if (deleteAccountIds.length > 0) {
        const isFirst = CommonStatusHelper.INSTANCE.getIsFirstCheckExceptionAccount();
        Log.warn(TAG, `delete exception account isFirst: ${isFirst}`);
        if (isFirst) {
          CommonStatusHelper.INSTANCE.setIsFirstCheckExceptionAccount(false);
          this.deleteCalendarByIds(deleteAccountIds);
        }
      }
      return resultAccounts;
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryCalendarList err', err);
      return resultAccounts;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private isExceptionAccount(account: CalendarContract.Accounts): boolean {
    if (account.creator === CALENDAR_BUNDLE_NAME && account.accountType !== CalendarAccountType.CUSTOM_ACCOUNT_TYPE &&
      account.calendarDisplayName?.startsWith('WeLink')) {
      // displayName以WeLink开头，creator为日历，accountType不为custom类型，表示这是一个由近端同步异常创建的WeLink帐户，属于异常产生的帐户，应该移除
      return true;
    }
    return false;
  }

  /**
   * 查询数据库，获取帐户列表数组
   *
   * @return 帐户数组
   */
  async queryCalendarById(calendarId: number): Promise<CalendarContract.Accounts | undefined> {
    const resultSet = await this.repo.queryCalendarById(calendarId);
    if (!resultSet) {
      return undefined;
    }
    const accountList: CalendarContract.Accounts[] = this.parseCalendarResToList(resultSet);
    if (EmptyUtils.isEmptyArray(accountList)) {
      Log.warn(TAG, `queryCalendarById id is ${calendarId} result is null `);
      return undefined;
    }
    // 解析=>  账户 - calendar
    return accountList[0];
  }

  /**
   * 通过uuid 查询日历账户
   *
   * @return 帐户数组
   */
  async queryCalendarByUuids(calendarUuids: string[]): Promise<Result<CalendarContract.Accounts[]>> {
    if (EmptyUtils.isEmptyArray(calendarUuids)) {
      Log.warn(TAG, `queryCalendarByUuids calendarUuids is empty`);
      return Result.buildSuccessResult([]);
    }
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(CalendarContract.AccountColumns.UUID, calendarUuids);
    const columns = [CalendarContract.BaseColumns.ID, CalendarContract.AccountColumns.UUID];
    const resultSet = await this.repo.queryCalendarByCondition(predicates, columns);
    const accountList: CalendarContract.Accounts[] = this.parseCalendars(resultSet);
    if (EmptyUtils.isEmptyArray(accountList)) {
      Log.warn(TAG, `queryCalendarByUuids error`);
      return new Result(ErrorCode.NO_DB, 'queryCalendarByUuids error', []);
    }
    return Result.buildSuccessResult(accountList);
  }

  /**
   * 通过calendarName查询账户
   * @param CalendarName 账户名称
   * @returns
   */
  async queryCalendarByCalendarName(calendarName: string[]): Promise<number> {
    const accountId = -1;
    const resultSet = await this.repo.queryCalendarByName(calendarName);
    if (!resultSet) {
      return accountId;
    }
    try {
      const accountList: CalendarContract.Accounts[] = this.parseCalendarResToList(resultSet);
      if (EmptyUtils.isEmptyArray(accountList)) {
        Log.warn(TAG, `queryCalendarByCalendarName accountList is null `);
        return accountId;
      }

      return accountList[0].id;
    } catch (err) {
      Log.logErrorMsg(TAG, `queryqueryCalendarByCalendarName err`, err);
    } finally {
      resultSet.close();
    }
    return accountId;
  }

  async insertCalendar(calendar: ValuesBucket, uri?: string): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.insertCalendar, 0);
    let result = await this.repo.insertCalendar(calendar, uri);
    hiTraceMeter.finishTrace(traceEvents.insertCalendar, 0);
    return result;
  }

  async deleteCalendarById(calendarId: number): Promise<number> {
    hiTraceMeter.startTrace(traceEvents.deleteCalendarById, 0);
    let result = await this.repo.deleteCalendarById(calendarId);
    hiTraceMeter.finishTrace(traceEvents.deleteCalendarById, 0);
    return result;
  }

  async updateCalendarById(calendarId: number, calendarUpdate: ValuesBucket, uri?: string): Promise<number> {
    Log.info(TAG, 'updateCalendarById calendarId ' + calendarId);
    hiTraceMeter.startTrace(traceEvents.updateCalendarById, 0);
    let result = await this.repo.updateCalendarById(calendarId, calendarUpdate, uri);
    hiTraceMeter.finishTrace(traceEvents.updateCalendarById, 0)
    return result;
  }

  async deleteCalendarByIds(calendarIds: number[]): Promise<number> {
    const result = await this.repo.deleteCalendarByIds(calendarIds);
    return result;
  }

  async deleteCalendarByUuids(calendarUuids: string[]): Promise<Result<number>> {
    return this.repo.deleteCalendarByUuids(calendarUuids);
  }

  /**
   * 将查询的帐户结果 result 转化为帐户数组
   *
   * @param resultSet
   * @return 帐户数组
   */
  private parseCalendarResToList(resultSet: InnerResultSet | undefined): CalendarContract.Accounts[] {
    let accountList: CalendarContract.Accounts[] = [];
    try {
      if (!resultSet) {
        Log.error(TAG, 'ResultSet invalid');
        return accountList;
      }
      if (!resultSet.goToFirstRow()) {
        Log.error(TAG, 'ResultSet go To first row failed');
        return accountList;
      }
      do {
        let account = new CalendarContract.Accounts();
        account.parseAccounts(resultSet);
        this.mapAccountColor(account);
        accountList.push(account);
      } while (resultSet.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseCalendarResToList', err);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return accountList;
  }

  /**
   * 将查询的帐户结果 result 转化为帐户数组
   *
   * @param resultSet
   * @return 帐户数组
   */
  private parseCalendars(resultSet: InnerResultSet | undefined, columns?: string[]): CalendarContract.Accounts[] {
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
        this.mapAccountColor(account);
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
}
