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
import { Log } from '../default/common/Log';
import { BaseVersionDBHelper, DbInitParas } from './BaseVersionDBHelper';
import { DbStoreKeys } from '../default/util/preferences_util/DbStoreKeys';

const TAG = 'CalendarDBHelper';
const DB_NAME: string = 'calendar.db';


const config: ohosDataRdb.StoreConfig = {
  name: DB_NAME,
  securityLevel: ohosDataRdb.SecurityLevel.S1,
  isSearchable: false,
};

const DB_LATEST_VERSION: number = 1;

/**
 * 单框架 DataBaseHelper
 *
 */
export class CalendarDBHelper extends BaseVersionDBHelper {
  private static instance: CalendarDBHelper

  constructor(dbInitParas: DbInitParas) {
    super(dbInitParas);
  }

  /**
   * get the instance of CalendarDataHelper class
   */
  public static getInstance() {
    if (!CalendarDBHelper.instance) {
      Log.log(TAG, 'call getInstance init');
      const dbInitParas: DbInitParas = {
        logTag: TAG,
        config: config,
        dbLatestVersion: DB_LATEST_VERSION,
        dbVersionPreferencesKey: DbStoreKeys.CALENDAR_DB_VERSION_KEY,
      }
      CalendarDBHelper.instance = new CalendarDBHelper(dbInitParas);
    }
    return CalendarDBHelper.instance;
  }

  protected async onDownGradeDataBase(fromVersion: number, toVersion: number,
                                      rdbStore: ohosDataRdb.RdbStore): Promise<void> {
    Log.info(this.logTag, `onDownGradeDataBase`);
  }

  protected async onUpdateDataBase(fromVersion: number, toVersion: number,
                                   rdbStore: ohosDataRdb.RdbStore): Promise<void> {
    Log.info(this.logTag, `onUpdateDataBase no operation needed`);
  }

  protected async onInitDataBase(rdbStore: ohosDataRdb.RdbStore): Promise<void> {
    Log.log(TAG, 'call initRdbStore start');
    Log.log(TAG, 'initRdbStore executeSql end');
  }
}