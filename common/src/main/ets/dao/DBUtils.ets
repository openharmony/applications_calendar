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

import rpc from '@ohos.rpc';
import dataShare from '@ohos.data.dataShare';
import { Log } from '../default/common/Log';
import { GlobalThis } from '../data/GlobalThis';
import { BaseInitialize } from '../commoncapability/init/BaseInitialize';
import { SqlFaultHandle } from '../default/util/ReportUtil';
import ArrayList from '@ohos.util.ArrayList';
import { dataSharePredicates, ValuesBucket } from '@kit.ArkData';
import { Result } from '../templates/Result';
import { ErrorCode } from '../commoncapability/error/ErrorCode';
import { emitter } from '@kit.BasicServicesKit';
import { CommonInnerEvent } from '../event/CommonInnerEvent';
import { ThrottleFunction } from '../util/FunctionUtil';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { ProxyDBUtils } from './ProxyDBUtils';
import { EmptyUtils } from '../util/EmptyUtils';
import { InnerResultSet } from './util/InnerResultSet';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { Converter } from './Converter';
import { closeDataShareResultSet } from './util/DbExtensionUtils';
import { TypeUtils } from '../util/TypeUtils';
import { CalendarDataFeature, CalendarDataFeatureHelper} from '../util/CalendarDataFeatureHelper';

const TAG: string = 'DBUtils';
const EXCEPTION_APP_ABNORMAL = 2097204;

export class DBUtils extends BaseInitialize {
  public static readonly INSTANCE: DBUtils = new DBUtils();
  //异步等待初始化的Resolve,初始化完毕后,通知唤醒
  private waitInitOverResolves: ArrayList<Function> = new ArrayList();
  private readonly dseUri: string = 'datashare:///calendardata_whole';
  private readonly bundleNameTokenId = `?bundleName=com.ohos.calendar&tokenId=${rpc.IPCSkeleton.getCallingTokenId()}`;
  public readonly URI_CALENDAR: string = 'datashare:///calendardata_whole/Calendars' + this.bundleNameTokenId;
  public readonly URI_EVENT: string = 'datashare:///calendardata_whole/Events' + this.bundleNameTokenId;
  public readonly URI_REMINDER: string = 'datashare:///calendardata_whole/Reminders' + this.bundleNameTokenId;
  public readonly URI_ATTENDEE: string = 'datashare:///calendardata_whole/Attendees' + this.bundleNameTokenId;
  public readonly URI_ONELINK: string = 'datashare:///calendardata_whole/OneLinkData' + this.bundleNameTokenId;
  public readonly URI_EVENT_ATTACHMENTS: string = 'datashare:///calendardata_whole/event_attachments' + this.bundleNameTokenId;
  public readonly URI_CALENDAR_CACHE: string = 'datashare:///calendardata_whole/CalendarCache' + this.bundleNameTokenId;
  private dsHelper: dataShare.DataShareHelper | null = null;

  public concatenateUri(tableName: string): string {
    return this.dseUri + '/' + tableName + this.bundleNameTokenId;
  }

  getTag(): string {
    return TAG;
  }

  async doInit(): Promise<boolean> {
    this.dsHelper = await this.initDsHelper();
    return this.dsHelper ? true : false;
  };

  isInitted(): boolean {
    return this.dsHelper ? true : false;
  };

  /**
   *
   * @returns
   */
  async getDsHelper(): Promise<dataShare.DataShareHelper | null> {
    if (this.dsHelper) {
      return this.dsHelper;
    }
    if (this.isInitializing) {
      Log.info(this.getTag(), 'getDsHelper isInitializing please wait');
      return new Promise<dataShare.DataShareHelper>((resolve) => {
        this.waitInitOverResolves.add(resolve);
      });
    }
    if (!await this.isCanInit()) {
      Log.warn(this.getTag(), 'getDsHelper isCanInit false');
      return this.dsHelper;
    }
    await this.init();
    return this.dsHelper;
  }

  /**
   * query
   * @param { CalendarContract.Tables } table.
   * @param { dataSharePredicates.DataSharePredicates } predicates - Indicates filter criteria.
   * @param { Array<string> } columns - Indicates the columns to query.
   * @param { string } tag - LOG TAG
   * @param { boolean } proxy - use proxy dataShare
   * @returns { Promise<InnerResultSet | undefined> } {InnerResultSet}: the query result.
   */
  async query(table: CalendarContract.Tables, predicates: dataSharePredicates.DataSharePredicates,
              columns: string[], tag: string, proxy : boolean = true): Promise<InnerResultSet | undefined> {
    const isSupportProxyFeature = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.DB_PROXY);
    if (!proxy || !isSupportProxyFeature) {
      Log.info(TAG, `query unProxy`);
      return await DBUtils.INSTANCE.queryWithExtraUrl(table, predicates, columns, tag);
    }
    return await ProxyDBUtils.INSTANCE.query(table, predicates, columns, tag);
  }

  /**
   * queryWithExtraUrl
   * @param { CalendarContract.Tables } table.
   * @param { dataSharePredicates.DataSharePredicates } predicates - Indicates filter criteria.
   * @param { Array<string> } columns - Indicates the columns to query.
   * @param { string } tag - LOG TAG
   * @param { string } extraUri
   * @returns { Promise<InnerResultSet | undefined> } {InnerResultSet}: the query result.
   */
  async queryWithExtraUrl(table: CalendarContract.Tables, predicates: dataSharePredicates.DataSharePredicates,
              columns: string[], tag: string, extraUri?: string): Promise<InnerResultSet | undefined> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return undefined;
    }
    Log.info(TAG, `query, tag: ${tag}, table: ${table}`)
    try {
      let uri = this.dseUri + '/' + table + this.bundleNameTokenId; // Indicates the path of data to query.
      if (EmptyUtils.isNotEmptyString(extraUri)) {
        uri += extraUri;
      }
      hiTraceMeter.startTrace(tag, 0);
      let oriResultSet = await dsHelper.query(uri, predicates, columns);
      hiTraceMeter.finishTrace(tag, 0);
      if (oriResultSet) {
        return new InnerResultSet(oriResultSet, tag);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryWithExtraUrl', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.querySqlFail(err?.message, tag);
    }
    return undefined;
  }

  async insert(uri: string, values: ValuesBucket, tag: string): Promise<number> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return -1;
    }
    try {
      return await dsHelper.insert(uri, values);
    } catch (err) {
      Log.logErrorMsg(TAG, 'insert catch', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.insertSqlFail(err?.message, tag);
    }
    return -1;
  }


  async insertItem(tableName: CalendarContract.Tables | Function, values: ValuesBucket): Promise<Result<number>> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return new Result(ErrorCode.NO_DB, 'insertItem no dsHelper', -1);
    }
    let uri: string = '';
    if (EmptyUtils.isStringAndNotEmpty(tableName)) {
      uri = this.dseUri + '/' + tableName + this.bundleNameTokenId;
    } else if (TypeUtils.isFunction(tableName)) {
      uri = (tableName as Function)();
      if (EmptyUtils.isNotOrEmptyString(uri)) {
        return new Result(ErrorCode.ILLEGAL_CODE, 'insert Function build url illegal', -1);
      }
    } else {
      return new Result(ErrorCode.ILLEGAL_CODE, 'insert uri illegal', -1);
    }
    try {
      const rowId = await dsHelper.insert(uri, values);
      if (rowId <= 0) {
        const msg = `insertItem tableName ${tableName} rowId is ${rowId} illegal`;
        Log.warn(TAG, msg);
        return new Result(ErrorCode.ILLEGAL_CODE, msg, -1);
      }
      Log.info(TAG, `insertItem tableName ${tableName} success rowId is ${rowId}`);
      return Result.buildSuccessResult(rowId);
    } catch (err) {
      Log.logErrorMsg(TAG, `insert tableName ${tableName}`, err);
      this.handleDbException(err?.code);
      SqlFaultHandle.insertSqlFail(err?.message, `insertItem_${tableName}`);
      return Result.buildByErrorWithData(err, -1);
    }
  }

  async batchInsert(uri: string, values: Array<ValuesBucket>, tag: string): Promise<number> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return -1;
    }
    try {
      return await dsHelper.batchInsert(uri, values);
    } catch (err) {
      Log.logErrorMsg(TAG, 'batchInsert', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.insertSqlFail(err?.message, tag);
    }
    return -1;
  }

  async update(uri: string,
               predicates: dataSharePredicates.DataSharePredicates,
               values: ValuesBucket,
               tag: string): Promise<number> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return -1;
    }
    try {
      return await dsHelper.update(uri, predicates, values);
    } catch (err) {
      Log.logErrorMsg(TAG, 'update catch', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.updateSqlFail(err?.message, tag);
    }
    return -1;
  }


  async updateByCondition(tableName: string | Function,
                          predicates: dataSharePredicates.DataSharePredicates,
                          values: ValuesBucket): Promise<Result<number>> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return new Result(ErrorCode.NO_DB, 'updateByCondition no dsHelper', -1);
    }
    let uri: string = '';
    if (EmptyUtils.isStringAndNotEmpty(tableName)) {
      uri = this.dseUri + '/' + tableName + this.bundleNameTokenId;
    } else if (TypeUtils.isFunction(tableName)) {
      uri = (tableName as Function)();
      if (EmptyUtils.isNotOrEmptyString(uri)) {
        return new Result(ErrorCode.ILLEGAL_CODE, 'updateByCondition Function build url illegal', -1);
      }
    } else {
      return new Result(ErrorCode.ILLEGAL_CODE, 'updateByCondition uri illegal', -1);
    }
    try {
      const updatedCount = await dsHelper.update(uri, predicates, values);
      if (updatedCount < 0) {
        const msg = `updateByCondition tableName ${tableName} updatedCount is ${updatedCount} illegal`;
        Log.error(TAG, msg);
        return new Result(ErrorCode.ILLEGAL_CODE, msg, -1);
      }
      Log.info(TAG, `updateByCondition tableName ${tableName} success updatedCount is ${updatedCount}`);
      return Result.buildSuccessResult(updatedCount);
    } catch (err) {
      Log.logErrorMsg(TAG, `updateByCondition tableName ${tableName}`, err);
      this.handleDbException(err?.code);
      SqlFaultHandle.updateSqlFail(err?.message, `updateByCondition_${tableName}`);
      return Result.buildByErrorWithData(err, -1);
    }
  }

  async delete(uri: string, predicates: dataSharePredicates.DataSharePredicates, tag: string): Promise<number> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return -1;
    }
    try {
      return await dsHelper.delete(uri, predicates);
    } catch (err) {
      Log.logErrorMsg(TAG, 'delete catch', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.deleteSqlFail(err?.message, tag);
    }
    return -1;
  }

  async deleteData(uri: string, predicates: dataSharePredicates.DataSharePredicates, tag: string): Promise<Result<number>> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return new Result(ErrorCode.NO_DB, 'delete no db', -1);
    }
    try {
      const deleteCount = await dsHelper.delete(uri, predicates);
      return Result.buildSuccessResult(deleteCount);
    } catch (err) {
      Log.logErrorMsg(TAG, 'delete catch', err);
      this.handleDbException(err?.code);
      SqlFaultHandle.deleteSqlFail(err?.message, tag);
      return Result.buildByErrorWithData(err, -1);
    }
  }

  async deleteByCondition(tableName: string | Function, predicates: dataSharePredicates.DataSharePredicates)
    : Promise<Result<number>> {
    const dsHelper = await DBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return new Result(ErrorCode.NO_DB, 'deleteByCondition no dsHelper', -1);
    }
    let uri: string = '';
    if (EmptyUtils.isStringAndNotEmpty(tableName)) {
      uri = this.dseUri + '/' + tableName + this.bundleNameTokenId;
    } else if (TypeUtils.isFunction(tableName)) {
      uri = (tableName as Function)();
      if (EmptyUtils.isNotOrEmptyString(uri)) {
        return new Result(ErrorCode.ILLEGAL_CODE, 'deleteByCondition Function build url illegal', -1);
      }
    } else {
      return new Result(ErrorCode.ILLEGAL_CODE, 'deleteByCondition uri illegal', -1);
    }
    try {
      const deleteCount = await dsHelper.delete(uri, predicates);
      return Result.buildSuccessResult(deleteCount);
    } catch (err) {
      Log.logErrorMsg(TAG, `deleteByCondition`, err);
      this.handleDbException(err?.code);
      SqlFaultHandle.deleteSqlFail(err?.message, `deleteByCondition_${tableName}`);
      return Result.buildByErrorWithData(err, -1);
    }
  }

  /**
   * 根据获取表的item
   */
  async queryTabItemsByCondition<SingleItem, FinalResult>(tableName: CalendarContract.Tables,
                                                          converter: Converter<SingleItem, FinalResult>,
                                                          predicates: dataSharePredicates.DataSharePredicates,
                                                          isUseProxy: boolean = true,
                                                          columns?: string[]): Promise<Result<FinalResult>> {
    const resultSetResult: Result<InnerResultSet | undefined> = await this
      .getResultSetResult(tableName, predicates, isUseProxy, columns);
    if (!resultSetResult.isSuccess()) {
      return Result.copyResult(resultSetResult, converter.buildErrorData());
    }
    const checkResult = this.checkAndPreProcessResultSet(resultSetResult.data);
    if (!checkResult.isSuccess()) {
      return Result.copyResult(resultSetResult, converter.buildErrorData());
    }
    if (checkResult.isSuccess() && !checkResult.data) {
      return Result.buildSuccessResult(converter.buildEmptyData());
    }
    const resultSet: InnerResultSet = resultSetResult.data!;
    try {
      return Result.buildSuccessResult(converter.parseResultSetToModel(resultSet, columns));
    } catch (err) {
      Log.logErrorMsg(TAG, `queryTabItemsByCondition table is ${tableName}`, err);
      SqlFaultHandle.querySqlFail(err?.message, `queryTabItemsByCondition_${tableName}`);
      return Result.buildByErrorWithData(err, converter.buildErrorData());
    } finally {
      closeDataShareResultSet(resultSet);
    }
  }

  /**
   * 检查查询的resultSet并预处理跳到第一行,如果有数据返回true
   * @param resultSet
   * @returns
   */
  private checkAndPreProcessResultSet(resultSet?: InnerResultSet): Result<boolean> {
    if (!resultSet) {
      return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet undefined', false);
    }
    if (resultSet.rowCount <= 0) {
      Log.info(TAG, `checkAndPreProcessResultSet rowCount is ${resultSet.rowCount}`);
      closeDataShareResultSet(resultSet);
      return Result.buildSuccessResult(false);
    }
    try {
      if (!resultSet.goToFirstRow()) {
        closeDataShareResultSet(resultSet);
        return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet cannot goToFirstRow', false);
      }
    } catch (error) {
      Log.logErrorMsg(TAG, `checkAndPreProcessResultSet`, error);
      SqlFaultHandle.querySqlFail(error?.message, 'checkAndPreProcessResultSet');
      closeDataShareResultSet(resultSet);
      return Result.buildByErrorWithData(error, false);
    }
    return Result.buildSuccessResult(true);
  }

  private async getResultSetResult(tableName: CalendarContract.Tables
    , predicates: dataSharePredicates.DataSharePredicates,
                                   isUseProxy: boolean = true,
                                   columns?: string[]): Promise<Result<InnerResultSet | undefined>> {
    if (EmptyUtils.isNotOrEmptyString(tableName)) {
      return new Result(ErrorCode.ILLEGAL_CODE, 'getResultSetResult tableName notOrEmptyString', undefined);
    }
    if (isUseProxy) {
      const resultSet = await ProxyDBUtils.INSTANCE.query(tableName, predicates, columns ?? [], '');
      if (resultSet) {
        return Result.buildSuccessResult(resultSet);
      }
      Log.error(TAG, `getResultSetResult by Proxy table is ${tableName} rdbStore is null`);
      return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet undefined', undefined);
    }
    try {
      await this.getDsHelper();
      if (!this.dsHelper) {
        Log.error(TAG, `getResultSetResult table is ${tableName} rdbStore is null`);
        return new Result(ErrorCode.NO_DB, 'no db', undefined);
      }
      let uri = this.dseUri + '/' + tableName + this.bundleNameTokenId; // Indicates the path of data to query.
      const resultSet = await this.dsHelper.query(uri, predicates, columns);
      if (!resultSet) {
        Log.warn(TAG, `getResultSetResult table is ${tableName} resultSet is undefined`);
        return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet undefined', undefined);
      }
      return Result.buildSuccessResult(new InnerResultSet(resultSet, TAG));
    } catch (err) {
      Log.logErrorMsg(TAG, `getResultSetResult table name is ${tableName}`, err);
      SqlFaultHandle.querySqlFail(err?.message, `getResultSetResult_${tableName}`);
      return Result.buildByError(err);
    }
  }


  private async initDsHelper(): Promise<dataShare.DataShareHelper | null> {
    Log.info(this.getTag(), `initDsHelper`);
    if (this.dsHelper) {
      return this.dsHelper;
    }
    try {
      const dbContext = GlobalThis.getInstance().getDbContext() as Context;
      if (!dbContext) {
        Log.warn(TAG, 'initDsHelper context is null.');
        return this.dsHelper;
      }
      this.dsHelper = await dataShare.createDataShareHelper(dbContext, this.dseUri,
        { isProxy: false, waitTime: GlobalThis.getInstance().timeoutInterval });
      this.notifyAll()
    } catch (err) {
      Log.warn(TAG, `initDsHelper error msg is ${err?.message}`);
      this.handleDbException(err?.code);
      SqlFaultHandle.initSqlFail(err?.message, TAG);
    }
    Log.info(TAG, 'initDsHelper success');
    return this.dsHelper;
  }

  /**
   * 通知等待数据库初始化的异步callBack
   */
  private notifyAll() {
    Log.info(this.getTag(), `notifyAll waitInitOverResolve count is ${this.waitInitOverResolves.length}`);
    for (let i = 0; i < this.waitInitOverResolves.length; i++) {
      const func: Function = this.waitInitOverResolves[i];
      func(this.dsHelper);
    }

    this.waitInitOverResolves.clear();
  }

  private handleDbException(code: number) {
    switch (code) {
      case EXCEPTION_APP_ABNORMAL:
        ThrottleFunction.instance().throttle(TAG, (): void => {
          emitter.emit({ eventId: CommonInnerEvent.EVENT_DB_EXCEPTION });
          Log.info(TAG, `notify db exception`);
        }, 30000); // 30s 防抖
        break;
    }
  }

  async isColumnNameExist(table: CalendarContract.Tables, columnNames: string[]): Promise<boolean> {
    const tag = 'isColumnNameExist';
    const predicate = new dataSharePredicates.DataSharePredicates();
    let resultSet: InnerResultSet | undefined = undefined;
    try {
      predicate.limit(1, 0);
      resultSet = await DBUtils.INSTANCE.query(table, predicate, columnNames, tag, false);
      if (!resultSet || resultSet.columnNames?.length !== columnNames.length) {
        Log.info(TAG, `isColumnNameExist false, ${table} ${columnNames}`);
        return false;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `isColumnNameExist false, ${table} ${columnNames}`, err);
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    Log.info(TAG, `isColumnNameExist true, ${table} ${columnNames}`);
    return true;
  }
}
