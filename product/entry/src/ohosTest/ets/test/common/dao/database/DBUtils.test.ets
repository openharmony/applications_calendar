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

import { CalendarContract, DBUtils, ErrorCode, InnerResultSet, Log, Parser, Result, ResultSetToArrayConverter } from '@app/common/index';
import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

import { Driver } from '@ohos.UiTest';
import { dataSharePredicates, DataShareResultSet } from '@kit.ArkData';
import { DataShareHelper } from '../DataShareHelperMock';
import { TestUtil } from '../../../utils/TestUtil';
import { DataShareResultSetMock } from '../../../common/dao/DataShareHelperMock';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator()


const driver = Driver.create();


const TAG = 'DBUtilsTest';


export default function DBUtilsTest() {

  let getDsHelper: Function;

  describe('DBUtilsTest', () => {

    it('DBUtilsTest', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.getDsHelper);
      const noDbPromise = new Promise<null>((resolve) => {
        resolve(null);
      });
      when(mockFunc)(ArgumentMatchers.any).afterReturn(noDbPromise);
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      let deleteResult = await DBUtils.INSTANCE.deleteData('', predicates, TAG);
      expect(deleteResult.code === ErrorCode.NO_DB).assertTrue();
      done();
    });

    it('DBUtilsNormalTest', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let dsHelper: DataShareHelper = new DataShareHelper();
      getDsHelper = mocker.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.getDsHelper);
      when(getDsHelper)(ArgumentMatchers.any).afterReturn(dsHelper);
      Log.info(TAG, `DBUtilsNormalTest has dsHelper`);
      let mockFunc: Function = mocker.mockFunc(dsHelper, dsHelper.delete);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(1);
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      let deleteResult = await DBUtils.INSTANCE.deleteData('', predicates, TAG);
      expect(deleteResult.data === 1).assertTrue();
      when(mockFunc)(ArgumentMatchers.any).afterThrow('para error');
      deleteResult = await DBUtils.INSTANCE.deleteData('', predicates, TAG);
      expect(deleteResult.isSuccess()).assertFalse();
      done();
    });


    it('testCheckAndPreProcessResultSet', 0, () => {
      testCheckAndPreProcessResultSet();
    });

    it('testGetResultSetResult', 0, (done: Function) => {
      testGetResultSetResult();
      done();
    });

    it('testQueryItemByCondition', 0, (done: Function) => {
      testQueryItemByCondition();
      done();
    });

    it('testInsertItem', 0, (done: Function) => {
      testInsertItem()
      done();
    });

    it('testUpdateByCondition', 0, (done: Function) => {
      testUpdateByCondition()
      done();
    });

  });
}

async function testUpdateByCondition() {
  let mocker = new MockKit();
  let getDsHelper: Function = mocker.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.getDsHelper);
  when(getDsHelper)(ArgumentMatchers.any).afterReturn(undefined);
  const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  let result: Result<number> = await DBUtils.INSTANCE.updateByCondition(CalendarContract.Tables.CALENDAR_CACHE, predicates, {});
  expect(result.message === `insertItem no dsHelper`);
  when(getDsHelper)(ArgumentMatchers.any).afterReturn(new Object());
  result = await DBUtils.INSTANCE.updateByCondition('' as CalendarContract.Tables.CALENDAR_CACHE, predicates, {});
  expect(result.message === `updateByCondition uri illegal`);
  result = await DBUtils.INSTANCE.updateByCondition(() => {
    return '';
  }, predicates, {});
  expect(result.message === `updateByCondition Function build url illegal`);
  result = await DBUtils.INSTANCE.updateByCondition(CalendarContract.Tables.CALENDAR_CACHE, predicates, {});
  expect(result.isSuccess()).assertFalse();
}

async function testInsertItem() {
  let mocker = new MockKit();
  let getDsHelper: Function = mocker.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.getDsHelper);
  when(getDsHelper)(ArgumentMatchers.any).afterReturn(undefined);
  let result: Result<number> = await DBUtils.INSTANCE.insertItem(CalendarContract.Tables.CALENDAR_CACHE, {});
  expect(result.message === `insertItem no dsHelper`);
  when(getDsHelper)(ArgumentMatchers.any).afterReturn(new Object());
  result = await DBUtils.INSTANCE.insertItem('' as CalendarContract.Tables.CALENDAR_CACHE, {});
  expect(result.message === `insert uri illegal`);
  result = await DBUtils.INSTANCE.insertItem(() => {
    return '';
  }, {});
  expect(result.message === `insert Function build url illegal`);
  result = await DBUtils.INSTANCE.insertItem(CalendarContract.Tables.CALENDAR_CACHE, {});
  expect(result.isSuccess()).assertFalse();
}

function testCheckAndPreProcessResultSet() {
  const checkAndPreProcessResultSet = TestUtil.getPrivateFunction(DBUtils.INSTANCE, 'checkAndPreProcessResultSet');
  if (!checkAndPreProcessResultSet) {
    return;
  }
  let result: Result<boolean> = checkAndPreProcessResultSet(undefined);
  expect(result.code === ErrorCode.ILLEGAL_CODE).assertTrue();
  const baseResultSet: DataShareResultSet = new DataShareResultSetMock();
  const innerResultSet = new InnerResultSet(baseResultSet, TAG);
  baseResultSet.rowCount = -1;
  result = checkAndPreProcessResultSet(innerResultSet);
  expect(result.isSuccess() && !result.data).assertTrue();
  baseResultSet.rowCount = 0;
  result = checkAndPreProcessResultSet(baseResultSet);
  expect(result.isSuccess() && !result.data).assertTrue();
  baseResultSet.rowCount = 1;
  let mocker = new MockKit();
  let goToFirstRow: Function = mocker.mockFunc(baseResultSet, baseResultSet.goToFirstRow);
  when(goToFirstRow)().afterReturn(false);
  result = checkAndPreProcessResultSet(baseResultSet);
  expect(result.message === 'resultSet cannot goToFirstRow').assertTrue();
  when(goToFirstRow)().afterReturn(true);
  result = checkAndPreProcessResultSet(baseResultSet);
  expect(result.isSuccess()).assertTrue();
  when(goToFirstRow)().afterThrow('goToFirstRow error');
  result = checkAndPreProcessResultSet(baseResultSet);
  expect(result.isSuccess()).assertFalse();
}

async function testGetResultSetResult() {
  let mocker = new MockKit();
  const getResultSetResult = TestUtil.getPrivateFunction(DBUtils.INSTANCE, 'getResultSetResult');
  if (!getResultSetResult) {
    return;
  }
  const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  let result: Result<DataShareResultSet | undefined> = Result.buildSuccessResult(undefined);
  result = getResultSetResult('', predicates, false);
  expect(result.message === 'getResultSetResult tableName notOrEmptyString');
  result = getResultSetResult(CalendarContract.Tables.CALENDAR_CACHE, predicates, false);
  let getDsHelper: Function = mocker.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.getDsHelper);
  when(getDsHelper)(ArgumentMatchers.any).afterReturn(undefined);
  expect(result.message === `getResultSetResult table is ${CalendarContract.Tables.CALENDAR_CACHE} rdbStore is null`);
}

class ParserImpl implements Parser<number> {
  parseToModel(resultSet: DataShareResultSet, columns?: string[]): number {
    return 1;
  }
}

async function testQueryItemByCondition() {
  let mocker = new MockKit();
  let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  const getResultSetResult = TestUtil.getPrivateFunction(DBUtils.INSTANCE, 'getResultSetResult');
  if (!getResultSetResult) {
    return;
  }
  const converter = new ResultSetToArrayConverter(new ParserImpl());
  when(getResultSetResult)(ArgumentMatchers.any).afterReturn(new Result(ErrorCode.ILLEGAL_CODE, 'error', undefined));
  let queryResult = await DBUtils.INSTANCE.queryTabItemsByCondition(CalendarContract.Tables.CALENDAR_CACHE, converter, predicates, false);
  expect(queryResult.message === 'error').assertTrue();
  const baseResultSet: DataShareResultSet = new DataShareResultSetMock();
  when(getResultSetResult)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(baseResultSet));
  const checkAndPreProcessResultSet = TestUtil.getPrivateFunction(DBUtils.INSTANCE, 'checkAndPreProcessResultSet');
  if (!checkAndPreProcessResultSet) {
    return;
  }
  when(checkAndPreProcessResultSet)(ArgumentMatchers.any).afterReturn(new Result(ErrorCode.ILLEGAL_CODE, 'error', false));
  queryResult = await DBUtils.INSTANCE.queryTabItemsByCondition(CalendarContract.Tables.CALENDAR_CACHE, converter, predicates, false);
  expect(queryResult.message === 'error').assertTrue();
  when(checkAndPreProcessResultSet)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(false));
  expect(queryResult.data.length === 0).assertTrue();
  when(checkAndPreProcessResultSet)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(true));
  expect(queryResult.data.length === 0).assertTrue();
}