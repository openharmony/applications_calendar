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

import { ErrorCode, Log, Result, SimpleDBHelper } from '@app/common/index';
import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import ohosDataRdb from '@ohos.data.relationalStore';
import data_rdb from '@ohos.data.relationalStore';
import { Driver } from '@ohos.UiTest';
import { TestUtil } from '../../../utils/TestUtil';
import { dataSharePredicates } from '@kit.ArkData';

const driver = Driver.create();


const TAG = 'MockCalendarDBHelper';
const DB_NAME: string = 'mock_calendar.db';

const config: ohosDataRdb.StoreConfig = {
  name: DB_NAME,
  securityLevel: ohosDataRdb.SecurityLevel.S1,
  isSearchable: false,
};


export default function BaseDBHelperTest() {
  describe('BaseDBHelperTest', () => {

    it('BaseDBHelperTest', 0, async (done: Function) => {
      const simpleDBHelper = new SimpleDBHelper(config, '');
      let db = await simpleDBHelper.getDb();
      expect(db === undefined).assertFalse();
      await TestUtil.clickToMainPage(driver, false);
      try {
        simpleDBHelper.getDb();
        let db = await simpleDBHelper.getDb();
        expect(db !== undefined).assertTrue();
        await testCheckAndPreProcessResultSet(simpleDBHelper);
        await testGetResultSetResult(simpleDBHelper);
      } catch (error) {
        Log.error(TAG, `BaseDBHelperTest error ${JSON.stringify(error)}`);
      }
      done();
    });

  });
}

async function testCheckAndPreProcessResultSet(simpleDBHelper: SimpleDBHelper) {
  const checkAndPreProcessResultSet = TestUtil.getPrivateFunction(simpleDBHelper, 'checkAndPreProcessResultSet');
  if (!checkAndPreProcessResultSet) {
    return;
  }
  let result: Result<boolean> = await checkAndPreProcessResultSet(undefined);
  expect(result.code === ErrorCode.ILLEGAL_CODE).assertTrue();
}

async function testGetResultSetResult(simpleDBHelper: SimpleDBHelper) {
  const getResultSetResult = TestUtil.getPrivateFunction(simpleDBHelper, 'getResultSetResult');
  if (!getResultSetResult) {
    return;
  }
  const predicates = new dataSharePredicates.DataSharePredicates();
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(simpleDBHelper, simpleDBHelper.getDb);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
  let result: Result<data_rdb.ResultSet | undefined> = await getResultSetResult('', predicates, []);
  expect(result !== undefined).assertTrue();
}