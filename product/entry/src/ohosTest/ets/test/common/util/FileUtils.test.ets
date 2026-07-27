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

import { ArgumentMatchers, beforeAll, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { Log } from '@app/common/index';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { TestUtil } from '../../utils/TestUtil';

import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

import { Driver } from '@ohos.UiTest';
import { UIAbility } from '@kit.AbilityKit';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator()


const TAG = 'PreferencesUtilTest';
const driver = Driver.create();


export default function FileUtilsTest() {
  let ability: UIAbility;
  describe('FileUtilsTest', () => {
    beforeAll(async (done: Function) => {
      await TestUtil.clickToMainPage(driver, false);
      try {
        ability = await delegator.getCurrentTopAbility();
      } catch (error) {
        Log.error(TAG, `getCurrentTopAbility error for ${error?.message}`);
      }
      done();
    })

    it('getFileSize_fileNotExist', 0, () => {
      let mocker = new MockKit();
      let isFile: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFile)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.getFileSize('/storage/media/test.txt')).assertEqual(-1);
    })

    it('getFileSize_not_isFile', 0, () => {
      let mocker = new MockKit();
      let isFile: Function = mocker.mockFunc(FileUtils, FileUtils.isFile);
      when(isFile)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.getFileSize('/storage/media/test.txt')).assertEqual(-1);
    })

    it('isDir', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.isDir('/storage/media/test.txt')).assertFalse();
    });

    it('isFile', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.isFile('/storage/media/test.txt')).assertFalse();
    });

    it('createFileSync_01', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(true);
      let isFile: Function = mocker.mockFunc(FileUtils, FileUtils.isFile);
      when(isFile)(ArgumentMatchers.any).afterReturn(true);
      expect(FileUtils.createFileSync('/storage/media/test.txt')).assertTrue();
    });

    it('createFileSync_02', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(true);
      let isFile: Function = mocker.mockFunc(FileUtils, FileUtils.isFile);
      when(isFile)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.createFileSync('/storage/media/test.txt')).assertFalse();
    });

    it('mkdirSync_01', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(true);
      let isDir: Function = mocker.mockFunc(FileUtils, FileUtils.isDir);
      when(isDir)(ArgumentMatchers.any).afterReturn(true);
      expect(FileUtils.mkdirSync('/storage/media/test.txt')).assertTrue();
    });

    it('mkdirSync_02', 0, () => {
      let mocker = new MockKit();
      let isFileExist: Function = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
      when(isFileExist)(ArgumentMatchers.any).afterReturn(true);
      let isDir: Function = mocker.mockFunc(FileUtils, FileUtils.isDir);
      when(isDir)(ArgumentMatchers.any).afterReturn(false);
      expect(FileUtils.mkdirSync('/storage/media/test.txt')).assertFalse();
    });

    it('getCleanFileName', 0, () => {
      expect(FileUtils.getCleanFileName('   ') == '').assertTrue();
      expect(FileUtils.getCleanFileName('') == '').assertTrue();
      expect(FileUtils.getCleanFileName('aaaa') == 'aaaa').assertTrue();
      expect(FileUtils.getCleanFileName('aaa哇啊a') == 'aaa哇啊a').assertTrue();
      expect(FileUtils.getCleanFileName('aaa<哇啊a') == 'aaa哇啊a').assertTrue();
      expect(FileUtils.getCleanFileName('aaa:哇啊a') == 'aaa哇啊a').assertTrue();
      expect(FileUtils.getCleanFileName('aaa/哇啊a') == 'aaa哇啊a').assertTrue();
      expect(FileUtils.getCleanFileName('aaa\\哇啊a') == 'aaa哇啊a').assertTrue();
      expect(FileUtils.getCleanFileName('a\\a<a\\哇|啊>a****???') == 'aaa哇啊a').assertTrue();
    });

    it('test_deleteDir', 0, () => {
      if (!ability || !ability.context) {
        expect(ability).assertUndefined();
      } else {
        expect(FileUtils.deleteDir('')).assertFalse();
        let path = ability.context.preferencesDir + '/hh.xml';
        FileUtils.createFileSync(path);
        expect(FileUtils.deleteDir(path)).assertFalse();
        path = ability.context.preferencesDir + '/hh';
        if (FileUtils.mkdirSync(path)) {
          expect(FileUtils.deleteDir(path)).assertTrue();
        }
      }
    });

    it('test_deleteChildren', 0, () => {
      let mocker = new MockKit();
      let getChildFiles: Function = mocker.mockFunc(FileUtils, FileUtils.getChildFiles);
      when(getChildFiles)(ArgumentMatchers.any).afterReturn([]);
      expect(FileUtils.deleteChildren('xx')).assertTrue();
      when(getChildFiles)(ArgumentMatchers.any).afterReturn(['xxx']);
      let isFile: Function = mocker.mockFunc(FileUtils, FileUtils.isFile);
      when(isFile)(ArgumentMatchers.any).afterReturn(true);
      let deleteFile: Function = mocker.mockFunc(FileUtils, FileUtils.deleteFile);
      when(deleteFile)(ArgumentMatchers.any).afterReturn(true);
      expect(FileUtils.deleteChildren('xx')).assertTrue();
    });
  })
}