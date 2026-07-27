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

import { beforeAll, describe, expect, it } from '@ohos/hypium';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Log, PreferencesFiles, PreferencesUtil, SettingPreferencesKeys } from '@app/common/index';

import { Driver } from '@ohos.UiTest';
import { TestUtil } from '../../utils/TestUtil';
import { UIAbility } from '@kit.AbilityKit';
import { ErrorCode, PreferencesValueType } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator()


const TAG = 'PreferencesUtilTest';
const driver = Driver.create();

type simpleArray = (string | boolean | number)[];

const checkArrSame = (arr1: simpleArray, arr2: simpleArray): boolean => {
  if (arr1 === null && arr2 === null) {
    return true;
  }
  if (arr1 === undefined && arr2 === undefined) {
    return true;
  }
  if (arr1 === null || arr1 === undefined) {
    return false;
  }
  if (arr2 === null || arr2 === undefined) {
    return false;
  }
  if (arr1.length !== arr2.length) {
    return false;
  }
  for (let i = 0; i < arr1.length; i++) {
    if (arr1[i] != arr2[i]) {
      return false;
    }
  }
  return true;
};

/*
 * PreferencesUtilTest
 */
export default function PreferencesUtilTest() {

  describe('PreferencesUtilTest', () => {

    beforeAll(async (done: Function) => {
      await TestUtil.clickToMainPage(driver, false);
      let ability: UIAbility;
      try {
        ability = await delegator.getCurrentTopAbility();
        PreferencesUtil.init(ability.context);
      } catch (error) {
        Log.error(TAG, `getCurrentTopAbility error for ${error?.message}`);
      }
      done();
    })

    it('putGet', 0, async (done: Function) => {
      await PreferencesUtil.putNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 1);
      let value = await PreferencesUtil.getNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(1);
      value = await PreferencesUtil.getNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON);
      expect(value).assertEqual(1);

      await PreferencesUtil.putNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 2);
      value = await PreferencesUtil.getNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(2);
      value = await PreferencesUtil.getNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON);
      expect(value).assertEqual(2);
      value = PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(2);
      await PreferencesUtil.putBooleanValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, false);
      let booleanValue = await PreferencesUtil.getBooleanValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, true);
      expect(booleanValue).assertEqual(false);
      await PreferencesUtil.putBooleanValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, true);
      booleanValue = await PreferencesUtil.getBooleanValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, false);
      expect(booleanValue).assertEqual(true);
      const stringKey = 'stringKey';
      await PreferencesUtil.putStringValue(PreferencesFiles.SETTINGS,
        stringKey, 'xxx');
      let stringValue = await PreferencesUtil.getStringValue(PreferencesFiles.SETTINGS,
        stringKey);
      expect(stringValue).assertEqual('xxx');
      stringValue = await PreferencesUtil.getStringValue(PreferencesFiles.SETTINGS, stringKey, '');
      expect(stringValue).assertEqual('xxx');
      done();
    })

    it('putGetArray', 0, async (done: Function) => {
      const numberArrayKey = 'numberArrayKey';
      const originalNumberArrayValue = [1, 2];
      await PreferencesUtil.putNumberArrayValue(PreferencesFiles.SETTINGS,
        numberArrayKey, originalNumberArrayValue);

      let numberArrayValue = await PreferencesUtil.getNumberArrayValue(PreferencesFiles.SETTINGS,
        numberArrayKey);
      expect(checkArrSame(originalNumberArrayValue, numberArrayValue)).assertEqual(true);
      numberArrayValue = await PreferencesUtil.getNumberArrayValue(PreferencesFiles.SETTINGS,
        numberArrayKey, [1, 3]);
      expect(checkArrSame(originalNumberArrayValue, numberArrayValue)).assertEqual(true);

      const booleanArrayKey = 'booleanArrayKey';
      const originalBooleanArrayValue = [true, true];
      await PreferencesUtil.putBooleanArrayValue(PreferencesFiles.SETTINGS,
        booleanArrayKey, originalBooleanArrayValue);
      let booleanArrayValue = await PreferencesUtil.getBooleanArrayValue(PreferencesFiles.SETTINGS,
        booleanArrayKey);
      expect(checkArrSame(booleanArrayValue, originalBooleanArrayValue)).assertEqual(true);
      booleanArrayValue = await PreferencesUtil.getBooleanArrayValue(PreferencesFiles.SETTINGS,
        booleanArrayKey, [true, false]);
      expect(checkArrSame(booleanArrayValue, originalBooleanArrayValue)).assertEqual(true);

      const stringArrayKey = 'stringArrayKey';
      const originalStringArrayValue = ['a', 'b'];
      await PreferencesUtil.putStringArrayValue(PreferencesFiles.SETTINGS,
        stringArrayKey, originalStringArrayValue);
      let stringArrayValue = await PreferencesUtil.getStringArrayValue(PreferencesFiles.SETTINGS,
        stringArrayKey);
      expect(checkArrSame(stringArrayValue, originalStringArrayValue)).assertEqual(true);
      booleanArrayValue = await PreferencesUtil.getBooleanArrayValue(PreferencesFiles.SETTINGS,
        booleanArrayKey, [true, false]);
      expect(checkArrSame(stringArrayValue, originalStringArrayValue)).assertEqual(true);

      done();
    })

    it('putGetSync', 0, (done: Function) => {
      const testFile = 'putGetSync';
      PreferencesUtil.putNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 1);
      let value = PreferencesUtil.getNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(1);
      value = PreferencesUtil.getNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON);
      expect(value).assertEqual(1);

      PreferencesUtil.putNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 2);
      value = PreferencesUtil.getNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(2);
      value = PreferencesUtil.getNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON);
      expect(value).assertEqual(2);
      value = PreferencesUtil.getNumberValueSync(testFile,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0);
      expect(value).assertEqual(2);
      PreferencesUtil.putBooleanValueSync(testFile,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, false);
      let booleanValue = PreferencesUtil.getBooleanValueSync(testFile,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, true);
      expect(booleanValue).assertEqual(false);
      PreferencesUtil.putBooleanValueSync(testFile,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, true);
      booleanValue = PreferencesUtil.getBooleanValueSync(testFile,
        SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, false);
      expect(booleanValue).assertEqual(true);
      const stringKey = 'stringKey';
      PreferencesUtil.putStringValueSync(testFile,
        stringKey, 'xxx');
      let stringValue = PreferencesUtil.getStringValueSync(testFile,
        stringKey);
      expect(stringValue).assertEqual('xxx');
      stringValue = PreferencesUtil.getStringValueSync(testFile, stringKey, '');
      expect(stringValue).assertEqual('xxx');
      done();
    })

    it('putGetArraySync', 0, (done: Function) => {
      const fileName = 'putGetArraySync';
      const numberArrayKey = 'numberArrayKey';
      const originalNumberArrayValue = [1, 2];
      PreferencesUtil.putNumberArrayValueSync(fileName,
        numberArrayKey, originalNumberArrayValue);
      let numberArrayValue = PreferencesUtil.getNumberArrayValueSync(fileName,
        numberArrayKey);
      expect(checkArrSame(originalNumberArrayValue, numberArrayValue)).assertEqual(true);
      numberArrayValue = PreferencesUtil.getNumberArrayValueSync(fileName,
        numberArrayKey, [1, 3]);
      expect(checkArrSame(originalNumberArrayValue, numberArrayValue)).assertEqual(true);

      const booleanArrayKey = 'booleanArrayKey';
      const originalBooleanArrayValue = [true, true];
      PreferencesUtil.putBooleanArraySync(fileName,
        booleanArrayKey, originalBooleanArrayValue);
      let booleanArrayValue = PreferencesUtil.getBooleanArrayValueSync(fileName,
        booleanArrayKey);
      expect(checkArrSame(booleanArrayValue, originalBooleanArrayValue)).assertEqual(true);
      booleanArrayValue = PreferencesUtil.getBooleanArrayValueSync(fileName,
        booleanArrayKey, [true, false]);
      expect(checkArrSame(booleanArrayValue, originalBooleanArrayValue)).assertEqual(true);

      const stringArrayKey = 'stringArrayKey';
      const originalStringArrayValue = ['a', 'b'];
      PreferencesUtil.putStringArrayValueSync(fileName,
        stringArrayKey, originalStringArrayValue);
      let stringArrayValue = PreferencesUtil.getStringArrayValueSync(fileName,
        stringArrayKey);
      expect(checkArrSame(stringArrayValue, originalStringArrayValue)).assertEqual(true);
      stringArrayValue = PreferencesUtil.getStringArrayValueSync(fileName,
        stringArrayKey, ['a', 'c']);
      expect(checkArrSame(stringArrayValue, originalStringArrayValue)).assertEqual(true);
      done();
    })

    it('test_getPreferencesValue', 0, async () => {
      const fileName = 'test_getPreferencesValue';
      const numberKey = 'test_getPreferencesNumberValue';
      const stringKey = 'test_getPreferencesStringValue';
      const booleanKey = 'test_getPreferencesBooleanValue';
      await PreferencesUtil.deletePreferences(fileName);
      expect(PreferencesUtil.getPreferencesValue<number>(fileName, numberKey, 0, true, PreferencesValueType.NUMBER).code === ErrorCode.CODE_HAS_NOT_SYNC)
        .assertTrue();
      expect(PreferencesUtil.getPreferencesValue<number>(fileName, numberKey, 0, false, PreferencesValueType.NUMBER).data === 0).assertTrue();
      expect(PreferencesUtil.getPreferencesValue<number>(fileName, numberKey, 0, false, PreferencesValueType.STRING).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue();
      PreferencesUtil.putNumberValueSync(fileName, numberKey, 1, true);
      let value = PreferencesUtil.getPreferencesValue<number>(fileName, numberKey, 0, false, PreferencesValueType.NUMBER).data;
      expect(value === 1).assertTrue();
      expect(PreferencesUtil.getPreferencesValue<number>(fileName, numberKey, 0, false, PreferencesValueType.STRING).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue();

      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '', true, PreferencesValueType.STRING).code === ErrorCode.CODE_HAS_NOT_SYNC)
        .assertTrue();
      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '', false, PreferencesValueType.STRING).data === '').assertTrue();
      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '0', false, PreferencesValueType.NUMBER).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue();
      PreferencesUtil.putStringValueSync(fileName, stringKey, '1', true);
      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '0', false, PreferencesValueType.STRING).data === '1')
        .assertTrue();
      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '0', true, PreferencesValueType.NUMBER).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue()
      expect(PreferencesUtil.getPreferencesValue<string>(fileName, stringKey, '0', true, PreferencesValueType.STRING).data === '1')
        .assertTrue();

      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, false, true, PreferencesValueType.BOOLEAN).code === ErrorCode.CODE_HAS_NOT_SYNC)
        .assertTrue();
      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, true, false, PreferencesValueType.BOOLEAN).data === true).assertTrue();
      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, false, false, PreferencesValueType.NUMBER).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue();
      PreferencesUtil.putBooleanValueSync(fileName, booleanKey, true, true);
      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, false, false, PreferencesValueType.STRING).code === ErrorCode.CODE_TYPE_NOT_MATCH)
        .assertTrue();
      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, false, true, PreferencesValueType.BOOLEAN).data)
        .assertTrue()
      expect(PreferencesUtil.getPreferencesValue<boolean>(fileName, booleanKey, false, true, PreferencesValueType.BOOLEAN).data)
        .assertTrue();
    })

    it('test_checkType', 0, async () => {
      const checkType = TestUtil.getPrivateFunction(PreferencesUtil, 'checkType');
      if (!checkType) {
        expect(checkType).assertNull();
      } else {
        expect(checkType('0', PreferencesValueType.STRING).isSuccess()).assertTrue();
        expect(checkType('0', PreferencesValueType.NUMBER).isSuccess()).assertFalse();
        expect(checkType('0', PreferencesValueType.NUMBER).code === ErrorCode.CODE_TYPE_NOT_MATCH).assertTrue();
        expect(checkType(false, PreferencesValueType.BOOLEAN).isSuccess()).assertTrue();
        expect(checkType(false, PreferencesValueType.NUMBER).code === ErrorCode.CODE_TYPE_NOT_MATCH).assertTrue();
        expect(checkType(undefined, PreferencesValueType.NUMBER).code === ErrorCode.CODE_VALUE_NULL).assertTrue();
        expect(checkType(undefined, PreferencesValueType.BOOLEAN_ARRAY).code === ErrorCode.CODE_VALUE_NULL)
          .assertTrue();
        expect(checkType(1, PreferencesValueType.BOOLEAN_ARRAY).code === ErrorCode.CODE_TYPE_NOT_MATCH).assertTrue();
      }
    })


    it('putGetArraySyncNullContext', 0, (done: Function) => {
      PreferencesUtil.init(null);
      const emptyArray = [];
      const fileName = 'putGetArraySyncNullContext';
      const numberArrayKey = 'numberArrayKey';
      const originalNumberArrayValue = [1, 2];
      PreferencesUtil.putNumberArrayValueSync(fileName,
        numberArrayKey, originalNumberArrayValue);
      let numberArrayValue = PreferencesUtil.getNumberArrayValueSync(fileName,
        numberArrayKey);
      expect(checkArrSame(emptyArray, numberArrayValue)).assertEqual(true);
      numberArrayValue = PreferencesUtil.getNumberArrayValueSync(fileName,
        numberArrayKey, [1, 3]);
      expect(checkArrSame(emptyArray, numberArrayValue)).assertEqual(false);

      const booleanArrayKey = 'booleanArrayKey';
      const originalBooleanArrayValue = [true, true];
      PreferencesUtil.putBooleanArraySync(fileName,
        booleanArrayKey, originalBooleanArrayValue);
      let booleanArrayValue = PreferencesUtil.getBooleanArrayValueSync(fileName,
        booleanArrayKey);
      expect(checkArrSame(booleanArrayValue, emptyArray)).assertEqual(true);
      booleanArrayValue = PreferencesUtil.getBooleanArrayValueSync(fileName,
        booleanArrayKey, [true, false]);
      expect(checkArrSame(booleanArrayValue, emptyArray)).assertEqual(false);

      const stringArrayKey = 'stringArrayKey';
      const originalStringArrayValue = ['a', 'b'];
      PreferencesUtil.putStringArrayValueSync(fileName,
        stringArrayKey, originalStringArrayValue);
      let stringArrayValue = PreferencesUtil.getStringArrayValueSync(fileName,
        stringArrayKey);
      expect(checkArrSame(stringArrayValue, emptyArray)).assertEqual(true);
      stringArrayValue = PreferencesUtil.getStringArrayValueSync(fileName,
        stringArrayKey, ['a', 'c']);
      expect(checkArrSame(stringArrayValue, emptyArray)).assertEqual(false);
      done();
    })

    it('putGetArrayNullContext', 0, async (done: Function) => {
      PreferencesUtil.init(null);
      const emptyArray = [];
      const fileName = 'putGetArrayNullContext';
      const numberArrayKey = 'numberArrayKey';
      const originalNumberArrayValue = [1, 2];
      await PreferencesUtil.putNumberArrayValue(fileName,
        numberArrayKey, originalNumberArrayValue);
      let numberArrayValue = await PreferencesUtil.getNumberArrayValue(fileName,
        numberArrayKey);
      expect(checkArrSame(emptyArray, numberArrayValue)).assertEqual(true);
      numberArrayValue = await PreferencesUtil.getNumberArrayValue(fileName,
        numberArrayKey, [1, 3]);
      expect(checkArrSame(emptyArray, numberArrayValue)).assertEqual(false);

      const booleanArrayKey = 'booleanArrayKey';
      const originalBooleanArrayValue = [true, true];
      await PreferencesUtil.putBooleanArrayValue(fileName,
        booleanArrayKey, originalBooleanArrayValue);
      let booleanArrayValue = await PreferencesUtil.getBooleanArrayValue(fileName,
        booleanArrayKey);
      expect(checkArrSame(booleanArrayValue, emptyArray)).assertEqual(true);
      booleanArrayValue = await PreferencesUtil.getBooleanArrayValue(fileName,
        booleanArrayKey, [true, false]);
      expect(checkArrSame(booleanArrayValue, emptyArray)).assertEqual(false);

      const stringArrayKey = 'stringArrayKey';
      const originalStringArrayValue = ['a', 'b'];
      await PreferencesUtil.putStringArrayValue(fileName,
        stringArrayKey, originalStringArrayValue);
      let stringArrayValue = await PreferencesUtil.getStringArrayValue(fileName,
        stringArrayKey);
      expect(checkArrSame(stringArrayValue, emptyArray)).assertEqual(true);
      stringArrayValue = await PreferencesUtil.getStringArrayValue(fileName,
        stringArrayKey, ['a', 'c']);
      expect(checkArrSame(stringArrayValue, emptyArray)).assertEqual(false);
      done();
    })

    it('testQueryHasSyncBySync', 0, () => {
      const fileName = 'testQueryHasSyncBySync';
      const fileName1 = 'testQueryHasSyncBySync1';
      const key = 'testQueryHasSyncBySync';
      expect(PreferencesUtil.queryHasSyncBySync(fileName, key)).assertFalse();
      PreferencesUtil.putNumberValueSync(fileName, key, 1, true);
      let hasSync = PreferencesUtil.queryHasSyncBySync(fileName, key);
      Log.info(TAG, `testQueryHasSyncBySync hasSync ${hasSync}`);
      expect(hasSync).assertFalse();
      PreferencesUtil.init(null);
      expect(PreferencesUtil.queryHasSyncBySync(fileName1, key)).assertFalse();
    })
  })
}