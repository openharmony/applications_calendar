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

import { GlobalThis, Log, PreferencesUtil } from '@app/common/index';
import { describe, expect, it } from '@ohos/hypium';
import { BaseVersionDBHelper, DbInitParas, DbVersionAction } from '@app/common/src/main/ets/database/BaseVersionDBHelper';
import ohosDataRdb from '@ohos.data.relationalStore';


const TAG = 'MockCalendarDBHelper';
const DB_NAME: string = 'mock_versioncalendar.db';
const MOCK_DB_KEY: string = 'mock_db_key';

const config: ohosDataRdb.StoreConfig = {
  name: DB_NAME,
  securityLevel: ohosDataRdb.SecurityLevel.S1,
  isSearchable: false,
};


/**
 * 单框架 DataBaseHelper
 *
 */
export class MockCalendarDBHelper extends BaseVersionDBHelper {
  constructor(dbInitParas: DbInitParas) {
    super(dbInitParas);
  }

  public getDbVersionAction(dataBaseVersion: number): DbVersionAction {
    return super.getDbVersionAction(dataBaseVersion);
  }

  public getDbLastVersion(): number {
    return super.getDbLastVersion();
  }

  protected async onDownGradeDataBase(fromVersion: number, toVersion: number,
                                      rdbStore: ohosDataRdb.RdbStore): Promise<void> {
    Log.info(this.logTag, `onDownGradeDataBase`);
  }

  protected async onUpdateDataBase(fromVersion: number, toVersion: number,
                                   rdbStore: ohosDataRdb.RdbStore): Promise<void> {
  }

  protected async onInitDataBase(rdbStore: ohosDataRdb.RdbStore): Promise<void> {

  }

  private async updateTo(fromVersion: number, toVersion: number) {

  }
}


export default function BaseVersionDBHelperTest() {
  describe('BaseVersionDBHelperTest', () => {
    const dbInitParas: DbInitParas = {
      logTag: TAG,
      config: config,
      dbLatestVersion: 1,
      dbVersionPreferencesKey: MOCK_DB_KEY,
    }

    it('BaseVersionDBHelperTest', 0, async (done: Function) => {
      expect(new MockCalendarDBHelper(dbInitParas).getDbVersionAction(0) === DbVersionAction.INIT).assertTrue();
      expect(new MockCalendarDBHelper(dbInitParas).getDbVersionAction(1) === DbVersionAction.NO_THING).assertTrue();
      expect(new MockCalendarDBHelper(dbInitParas).getDbVersionAction(2) === DbVersionAction.DOWNGRADE).assertTrue();
      dbInitParas.dbLatestVersion = 3;
      expect(new MockCalendarDBHelper(dbInitParas).getDbVersionAction(2) === DbVersionAction.UPDATE).assertTrue();
      try {
        PreferencesUtil.init(GlobalThis.getInstance().context);
        dbInitParas.dbLatestVersion = 1;
        let dbHelper = new MockCalendarDBHelper(dbInitParas);
        let db = await dbHelper.getDb();
        expect(db !== undefined).assertTrue();
        expect(dbHelper.getDbVersionAction(dbHelper.getDbLastVersion()) === DbVersionAction.NO_THING).assertTrue();
        dbInitParas.dbLatestVersion = 2;
        dbHelper = new MockCalendarDBHelper(dbInitParas);
        expect(dbHelper.getDbVersionAction(dbHelper.getDbLastVersion()) === DbVersionAction.UPDATE).assertTrue();
        db = await dbHelper.getDb();
        expect(db !== undefined).assertTrue();
        expect(dbHelper.getDbVersionAction(dbHelper.getDbLastVersion()) === DbVersionAction.NO_THING).assertTrue();
      } catch (error) {

      }

      done();
    });

  });
}