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



import ohosDataRdb from '@ohos.data.relationalStore';
import relationalStore from '@ohos.data.relationalStore';
import data_rdb from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { dataSharePredicates } from '@kit.ArkData';
import { GlobalThis } from '../data/GlobalThis';
import { Parser } from '../dao/Parser';
import { Log } from '../default/common/Log';
import { Result } from '../templates/Result';
import { ErrorCode } from '../../../..';

// 涉数据库调用，屏蔽DT覆盖率校验
/* instrument ignore file */

/**
 * 初始化rdb实例的Hooker
 */
export interface DbInitHooker {
  getName():string;

  isNeedHook(): Promise<boolean>;

  provideHookPromise(): Promise<boolean>;
}

const TAG = 'BaseDBHelper';

/**
 * DBHelper 基类,封装了获取rdb实例
 * initParas方法 子类初始化自己的配置
 *
 */
export abstract class BaseDBHelper {
  // 全局拦截器
  private static sGlobalDbInitHookers: DbInitHooker[] = [];
  private static hasInitDbInitHookers: boolean = false;
  // rdb实例
  protected rdbStore: ohosDataRdb.RdbStore | undefined = undefined;
  // logTag
  protected logTag: string = 'BaseDBHelper';
  // 数据库名称
  protected dbName: string = '';
  // 是否初始化成功
  protected isInisSuccess: boolean = false;
  // 数据库最新版本 这个变量应该只能定义在BaseVersionDbHelper里的,但是如果不定义在顶层父类,调用initParas 方法子类里设置的值不会生效
  protected dbLatestVersion: number = 0;
  // 数据库存储在Preferences 的版本key 这个变量应该只能定义在BaseVersionDbHelper里的,但是如果不定义在顶层父类,调用initParas 方法子类里设置的值不会生效
  protected dbVersionPreferencesKey: string = '';
  // StoreConfig
  protected config: ohosDataRdb.StoreConfig;
  // 是否是正在初始化中
  private isInitializing: boolean = false;
  // 异步等待初始化的Resolve,初始化完毕后,通知唤醒
  private waitInitOverResolves: Function[] = [];
  // 初始化拦截器
  private initInterceptors: DbInitHooker[] = [];

  public static initGlobalDbInitHookers(globalDbInitHookers: DbInitHooker[]) {
    if (BaseDBHelper.hasInitDbInitHookers) {
      Log.warn(TAG, `initGlobalDbInitHookers hasInitInterceptors no init again`);
      return;
    }
    BaseDBHelper.hasInitDbInitHookers = true;
    BaseDBHelper.sGlobalDbInitHookers = globalDbInitHookers;
  }

  constructor(config: ohosDataRdb.StoreConfig, logTag: string, dbInitHookers?: DbInitHooker[]) {
    this.config = config;
    this.dbName = config.name;
    this.logTag = logTag;
    if (dbInitHookers !== undefined && dbInitHookers !== null) {
      this.initInterceptors = BaseDBHelper.sGlobalDbInitHookers.concat(dbInitHookers);
    }
  }

  /**
   * Obtains the database version number in the cache
   * @returns database version
   */
  async getDb(): Promise<ohosDataRdb.RdbStore | undefined> {
    if (this.isInisSuccess) {
      return this.rdbStore;
    }
    await this.getInnerDb();
    return this.rdbStore;
  }

  /**
   *
   * @param tableName
   * @param parser 解析器
   * @param predicates
   * @param columns 需要解析的列名
   * @returns T 返回的model泛型T
   */
  async queryTabItems<T>(tableName: string, parser: Parser<T>,
                         predicates: dataSharePredicates.DataSharePredicates,
                         columns?: string[]): Promise<Result<T[]>> {
    const tableAllItems: T[] = [];
    const resultSetResult = await this.getResultSetResult(tableName, predicates, columns);
    if (!resultSetResult.isSuccess()) {
      return Result.copyResult(resultSetResult, []);
    }
    const checkResult = this.checkAndPreProcessResultSet(resultSetResult.data);
    if (!checkResult.isSuccess()) {
      return Result.copyResult(resultSetResult, []);
    }
    if (checkResult.isSuccess() && !checkResult.data) {
      return Result.buildSuccessResult([]);
    }
    const resultSet: data_rdb.ResultSet = resultSetResult.data!;
    try {
      do {
        const tableItem = parser.parseToModel(resultSet, columns);
        if (!tableItem) {
          continue;
        }
        tableAllItems.push(tableItem);
      } while (resultSet.goToNextRow());
      Log.debug(this.logTag, `getTabAllItems table is ${tableName} item count is ${tableAllItems.length}`);
      return Result.buildSuccessResult(tableAllItems);
    } catch (err) {
      Log.logErrorMsg(TAG, `getTabAllItems table is ${tableName}`, err);
      return Result.buildByErrorWithData(err, []);
    } finally {
      resultSet.close();
    }
  }

  /**
   * 获取表的所有item
   *
   */
  async getTabAllItems<T>(tableName: string, parser: Parser<T>, columns?: string[]): Promise<Result<T[]>> {
    return this.queryTabItems(tableName, parser, new dataSharePredicates.DataSharePredicates(), columns);
  }

  /**
   * 第一次获取到db实例的钩子方法
   * @param rdbStore
   * @returns
   */
  protected async doOnFirstGetDb(rdbStore: ohosDataRdb.RdbStore): Promise<void> {

  }

  protected async initOver(isInisSuccess: boolean) {
    this.isInisSuccess = isInisSuccess;
    this.isInitializing = false;
    this.notifyAll();
  }

  private async getInnerDb() {
    Log.info(this.logTag, `getInnerDb getCallingTokenId`);
    if (this.isInitializing) {
      Log.info(this.logTag, 'getInnerDb isInitializing please wait');
      return new Promise<void>((resolve) => {
        this.waitInitOverResolves.push(resolve);
      });
    }
    this.isInitializing = true;
    Log.log(this.logTag, 'getInnerDb call initOrUpdateRdbStore start');
    for (let initInterceptor of this.initInterceptors) {
      if (await initInterceptor.isNeedHook()) {
        Log.info(this.logTag, `getInnerDb initInterceptor ${initInterceptor.getName()} hook`);
        await initInterceptor.provideHookPromise();
        Log.info(this.logTag, `getInnerDb initInterceptor ${initInterceptor.getName()} done`);
      }
    }
    const baseContext: common.Context | null = GlobalThis.getInstance().getBasicContext();
    if (!baseContext) {
      Log.error(this.logTag, 'getInnerDb baseContext is null');
      this.initOver(false);
      return;
    }
    try {
      Log.log(this.logTag, 'fusionSearch getRdbStore Start');
      hiTraceMeter.startTrace('getRdbStore', 0);
      this.rdbStore = await ohosDataRdb.getRdbStore(baseContext, this.config);
      hiTraceMeter.finishTrace('getRdbStore', 0);
      Log.log(this.logTag, 'fusionSearch getRdbStore End');
    } catch (error) {
      // Inner error. Inner code is 18 这又是代表什么错误
      // Failed to open database by database corrupted 数据库腐化,什么鬼错误信息
      Log.error(this.logTag, `getInnerDb getRdbStore error ${error?.message} dBName is ${this.dbName}`)
    }
    if (!this.rdbStore) {
      Log.error(this.logTag, `getInnerDb getRdbStore result is rdb is null`);
      this.initOver(false);
      return;
    }
    Log.log(this.logTag, 'call getInnerDb, rdbStore_ = ' + this.rdbStore);
    await this.doOnFirstGetDb(this.rdbStore);
    await this.initOver(true);
  }

  /**
   * 通知等待数据库初始化的异步callBack
   */
  private notifyAll() {
    Log.info(this.logTag, `notifyAll waitInitOverResolve count is ${this.waitInitOverResolves.length}`);
    for (let waitInitOverResolve of this.waitInitOverResolves) {
      waitInitOverResolve();
    }
  }

  /**
   * 检查查询的resultSet并预处理跳到第一行,如果有数据返回true
   * @param resultSet
   * @returns
   */
  private checkAndPreProcessResultSet(resultSet?: relationalStore.ResultSet): Result<boolean> {
    if (!resultSet) {
      return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet undefined', false);
    }
    if (resultSet.rowCount <= 0) {
      return Result.buildSuccessResult(false);
    }
    try {
      if (!resultSet.goToFirstRow()) {
        return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet cannot goToFirstRow', false);
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'checkAndPreProcessResultSet', error);
      return Result.buildByErrorWithData(error, false);
    }
    return Result.buildSuccessResult(true);
  }

  private async getResultSetResult(tableName: string,
                                   predicates: dataSharePredicates.DataSharePredicates, columns?: string[]): Promise<Result<data_rdb.ResultSet | undefined>> {
    try {
      await this.getDb();
      if (!this.rdbStore) {
        Log.error(this.logTag, `getResultSet table is ${tableName} rdbStore is null`);
        return new Result(ErrorCode.NO_DB, 'no db', undefined);
      }
      const resultSet: data_rdb.ResultSet = await this.rdbStore.query(tableName, predicates, columns);
      if (!resultSet) {
        Log.warn(this.logTag, `getResultSet table is ${tableName} resultSet is undefined`);
        return new Result(ErrorCode.ILLEGAL_CODE, 'resultSet undefined', undefined);
      }
      return Result.buildSuccessResult(resultSet);
    } catch (err) {
      Log.logErrorMsg(TAG, `getTableAllItem table name is ${tableName}`, err);
      return Result.buildByError(err);
    }
  }

  /**
   * 危险api,谨慎使用
   */
  async destroySelf(): Promise<boolean> {
    try {
      const baseContext: common.Context | null = GlobalThis.getInstance().getBasicContext();
      if (!baseContext) {
        Log.error(this.logTag, 'destroySelf delete db failed baseContext is null');
        return false;
      }
      this.rdbStore?.close();
      await relationalStore.deleteRdbStore(baseContext, this.config);
      Log.info(this.logTag, `destroySelf delete db ${this.dbName} successfully!`);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'destroySelf deleteRdbStore failed', err);
      return false;
    }
  }
}
