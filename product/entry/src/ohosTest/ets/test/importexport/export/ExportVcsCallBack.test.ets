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


import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { ExportVcsCallBack } from '@app/feature.importexport';
import { TestUtil } from '../../utils/TestUtil';


export default function ExportVcsCallBackTest() {
  describe('ExportVcsCallBackTest', () => {
    let instance: ExportVcsCallBack;
    let mocker: MockKit = new MockKit();
    beforeEach(() => {
      instance = new ExportVcsCallBack()
    })

    it('test_updateProgress', 0, () => {
      const updateProgress = TestUtil.getPrivateFunction(instance, 'updateProgress');
      if (!updateProgress) {
        expect(updateProgress).assertNull();
      } else {
        expect(updateProgress(0, 1)).assertEqual(false);
        expect(updateProgress(-1, 1)).assertEqual(false);
        expect(updateProgress(1, 1)).assertEqual(true);
        expect(updateProgress(10, 10)).assertEqual(true);
        TestUtil.setPrivateAttribute(instance, 'lastUpdateTime', Date.now() - 500);
        expect(updateProgress(10, 9)).assertEqual(true);
        TestUtil.setPrivateAttribute(instance, 'lastUpdateTime', Date.now());
        expect(updateProgress(10, 9)).assertEqual(false);
        expect(updateProgress(10, 10)).assertEqual(true);
      }
    })

    it('test_tryShowDialog', 0, () => {
      const tryShowDialog = TestUtil.getPrivateFunction(instance, 'tryShowDialog');
      if (!tryShowDialog) {
        expect(tryShowDialog).assertNull();
      } else {
        TestUtil.setPrivateAttribute(instance, 'hasDialogOnceShowed', true);
        expect(tryShowDialog(10, 5)).assertFalse();
        TestUtil.setPrivateAttribute(instance, 'hasDialogOnceShowed', false);
        TestUtil.setPrivateAttribute(instance, 'lastUpdateTime', Date.now() - 500);
        expect(tryShowDialog(10, 4)).assertTrue();
        expect(tryShowDialog(10, 6)).assertFalse();
        TestUtil.setPrivateAttribute(instance, 'hasDialogOnceShowed', false);
        expect(tryShowDialog(10, 6)).assertFalse();
      }
    })

    it('test_showProgressDialog', 0, () => {
      const showProgressDialog = TestUtil.getPrivateFunction(instance, 'showProgressDialog');
      if (!showProgressDialog) {
        expect(showProgressDialog).assertNull();
      } else {
        expect(showProgressDialog()).assertTrue();
        expect(showProgressDialog()).assertFalse();
      }
    })

    it('test_closeDialog', 0, () => {
      const closeDialog = TestUtil.getPrivateFunction(instance, 'closeDialog');
      if (!closeDialog) {
        expect(closeDialog).assertNull();
      } else {
        expect(closeDialog()).assertFalse();
        TestUtil.setPrivateAttribute(instance, 'isDialogShowing', true);
        expect(closeDialog()).assertTrue();
      }
    })

    it('test_tryShowDialog_001', 0, () => {
      const tryShowDialog = TestUtil.getPrivateFunction(instance, 'tryShowDialog');
      if (!tryShowDialog) {
        expect(tryShowDialog).assertNull();
      } else {
        expect(tryShowDialog(0,0)).assertFalse();
      }
    })

    it('test_onExportTaskBuild', 0, () => {
      let ExportVcsCallBackTest: ExportVcsCallBack = new ExportVcsCallBack();
      ExportVcsCallBackTest.onExportTaskBuild(123);
      const jobId: number = TestUtil.getPrivateAttribute(ExportVcsCallBackTest, 'jobId');
      expect(jobId).assertEqual(123);
    })

    it('test_onExportProgressChanged_001', 0, () => {
      let ExportVcsCallBackTest: ExportVcsCallBack = new ExportVcsCallBack();
      ExportVcsCallBackTest.onExportProgressChanged(1,1);
      const totalCount: number = TestUtil.getPrivateAttribute(ExportVcsCallBackTest, 'totalCount');
      expect(totalCount).assertEqual(1);
    })

    it('test_onExportProgressChanged_002', 0, () => {
      let ExportVcsCallBackTest: ExportVcsCallBack = new ExportVcsCallBack();
      ExportVcsCallBackTest.onExportProgressChanged(0,1);
      const totalCount: number = TestUtil.getPrivateAttribute(ExportVcsCallBackTest, 'totalCount');
      expect(totalCount).assertEqual(0);
    })
  })
}