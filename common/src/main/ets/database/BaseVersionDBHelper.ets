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

import hiTraceMeter from '@ohos.hiTraceMeter';
import { Log, PreferencesFiles, PreferencesUtil } from '../../../..';
import { Constants } from './Constants';
import { BaseDBHelper, DbInitHooker } from './BaseDBHelper';

export interface DbInitParas {
  logTag: string;
  config: ohosDataRdb.StoreConfig;
  dbLatestVersion: number;
  dbVersionPreferencesKey: string;
}

export enum DbVersionAction {
  INIT,
  UPDATE,
  DOWNGRADE,
  NO_THING
}

/**
 * BaseVersionDBHelper 基类,封装了数据库的初始化和更新
 * initParas方法 子类初始化自己的配置
 *
 */
export abstract class BaseVersionDBHelper extends BaseDBHelper {
  constructor(dbInitParas: DbInitParas, dbInitHookers: DbInitHooker[] = []) {
    super(dbInitParas.config, dbInitParas.logTag, dbInitHookers);
    this.dbVersionPreferencesKey = dbInitParas.dbVersionPreferencesKey;
    this.dbLatestVersion = dbInitParas.dbLatestVersion;
  }

  /**
   * Obtains the database version number in the cache
   * @returns database version
   */
  protected getDbLastVersion(): number {
    const lastDbVersion = PreferencesUtil.getNumberValueSync(PreferencesFiles.DB_STORE, this.dbVersionPreferencesKey,
      Constants.DEFAULT_DATABASE_VERSION);
    Log.info(this.logTag, 'loadDataBaseVersion version in Store = ' + lastDbVersion);
    return lastDbVersion;
  }

  protected async doOnFirstGetDb(rdbStore: ohosDataRdb.RdbStore) {
    const dataBaseVersion: number = this.getDbLastVersion();
    await this.initOrUpdateRdbStoreMatch(dataBaseVersion, rdbStore);
    this.storeDbVersion(this.dbLatestVersion);
  }

  protected getDbVersionAction(dataBaseVersion: number): DbVersionAction {
    if (dataBaseVersion <= 0) {
      return DbVersionAction.INIT;
    }
    if (dataBaseVersion < this.dbLatestVersion) {
      return DbVersionAction.UPDATE;
    }
    if (dataBaseVersion > this.dbLatestVersion) {
      return DbVersionAction.DOWNGRADE;
    }
    return DbVersionAction.NO_THING;
  }

  /**
   * 数据库降级(一般如果数据库要回退,也不走降级处理,升级版本号走升级,回退数据库到低版本)
   * @param fromVersion 原来的数据库版本
   * @param toVersion 更新到的数据库版本
   * @returns
   */
  protected abstract onDownGradeDataBase(fromVersion: number, toVersion: number,
                                         rdbStore: ohosDataRdb.RdbStore): Promise<void>;

  /**
   *
   * @param fromVersion 原来的数据库版本
   * @param toVersion 更新到的数据库版本
   * @returns
   */
  protected abstract onUpdateDataBase(fromVersion: number, toVersion: number,
                                      rdbStore: ohosDataRdb.RdbStore): Promise<void>;

  protected abstract onInitDataBase(rdbStore: ohosDataRdb.RdbStore): Promise<void>;

  /**
   * Stores the database version number
   * @param new version of database
   */
  private storeDbVersion(databaseVersion: number) {
    Log.info(this.logTag, 'storeDataBaseVersion version = ' + databaseVersion + ' in store');
    PreferencesUtil.putNumberValueSync(PreferencesFiles.DB_STORE, this.dbVersionPreferencesKey, databaseVersion, true);
  }

  private async initOrUpdateRdbStoreMatch(dataBaseVersion: number, rdbStore: ohosDataRdb.RdbStore) {
    Log.info(this.logTag, `current version is ${dataBaseVersion} dbLatestVersion is ${this.dbLatestVersion}`);
    const dbAction: DbVersionAction = this.getDbVersionAction(dataBaseVersion);
    if (dbAction === DbVersionAction.INIT) {
      Log.log(this.logTag, 'db need init');
      hiTraceMeter.startTrace('initDataBase', 0);
      await this.onInitDataBase(rdbStore);
      hiTraceMeter.finishTrace('initDataBase', 0);
      return;
    }
    if (dbAction === DbVersionAction.UPDATE) {
      Log.log(this.logTag, `db need update from version ${dataBaseVersion} to version ${this.dbLatestVersion}`);
      hiTraceMeter.startTrace('updateDataBase', 0);
      await this.onUpdateDataBase(dataBaseVersion, this.dbLatestVersion, rdbStore);
      hiTraceMeter.finishTrace('updateDataBase', 0);
      return;
    }
    if (dbAction === DbVersionAction.DOWNGRADE) {
      hiTraceMeter.startTrace('downGradeDataBase', 0);
      await this.onDownGradeDataBase(dataBaseVersion, this.dbLatestVersion, rdbStore);
      hiTraceMeter.finishTrace('downGradeDataBase', 0);
    }
    Log.info(this.logTag, 'initOrUpdateRdbStore db version is Latest no need init or update');
  }
}
