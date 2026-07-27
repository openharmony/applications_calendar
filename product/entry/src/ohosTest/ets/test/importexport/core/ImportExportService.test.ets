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


import { afterEach, beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { ImportExportServiceImpl } from '@app/feature.importexport/src/main/ets/core/ImportExportService';
import { TaskState } from '@app/feature.importexport/src/main/ets/core/BaseProcessor';
import { Request } from '@app/feature.importexport/src/main/ets/import/Request';
import { TestUtil } from '../../utils/TestUtil';
import { GlobalThis, Log } from '@app/common';
import { ShareEventVcsBean } from '@app/feature.importexport/src/main/ets/interface/ShareEventVcsBean';
import { ExportType, ShareType } from '@app/feature.importexport/src/main/ets/interface/BusinessConstant';
import { ImportRequest } from '@app/feature.importexport/src/main/ets/import/ImportRequest';
import { i18n } from '@kit.LocalizationKit';
import {
  ExportCallBack,
  ImportCallBack, ImportData,
  ImportExportErrorCode,
  ShareEventTextBean, SimpleAccount } from '@app/feature.importexport';

const TAG = 'ImportExportServiceTest';

class ImportCallBackMock implements ImportCallBack {
  onImportTaskBuild(jobId: number): void {
  }

  onImportStarted(): void {
  }

  onSomeEventsParseFailed(): boolean {
    return false
  }

  onImportParsed(importData: ImportData, saveAction: (isSave: boolean, simpleAccount?: SimpleAccount | undefined) => void): void {
  }

  onImportFailed(errorCode: number): void {
  }

  onImportFinished(): void {
  }

  onSaveStart(): void {
  }

  onSaveFailed(errorCode: number): void {
  }

  onSaveSuccess(): void {
  }
}

class ExportCallBackMock implements ExportCallBack<ShareEventTextBean> {
  onExportProgressChanged(totalEventCount: number, processedEventCount: number): void {
  }
  onExportTaskBuild(jobId: number): void {
  }

  onExportStarted(): void {
  }

  onExportFailed(errorCode: number): void {
  }

  onExportFinished(exportContent: ShareEventTextBean): void {
  }
}

class ExportCallBackVcsMock implements ExportCallBack<ShareEventVcsBean> {
  onExportProgressChanged(totalEventCount: number, processedEventCount: number): void {
  }
  onExportTaskBuild(jobId: number): void {
  }

  onExportStarted(): void {
  }

  onExportFailed(errorCode: number): void {
  }

  onExportFinished(exportContent: ShareEventVcsBean): void {
  }
}

export default function ImportExportServiceTest() {
  describe('ImportExportServiceTest', () => {
    let instance = new ImportExportServiceImpl();
    let addImportCallBack = TestUtil.getPrivateFunction(instance, 'addImportCallBack');
    let removeImportCallBacks = TestUtil.getPrivateFunction(instance, 'removeImportCallBacks');
    let addExportCallBacks = TestUtil.getPrivateFunction(instance, 'addExportCallBacks');
    let removeExportCallBacks = TestUtil.getPrivateFunction(instance, 'removeExportCallBacks');
    let clearImportCallBacks = TestUtil.getPrivateFunction(instance, 'clearImportCallBacks');
    let clearExportCallBacks = TestUtil.getPrivateFunction(instance, 'clearExportCallBacks');
    let mocker: MockKit;
    let request = new Request(TaskState.STATE_WAITING, 1);
    beforeEach(() => {
      mocker = new MockKit;
    })

    afterEach(() => {
      if (clearImportCallBacks) {
        clearImportCallBacks();
      }
      if (clearExportCallBacks) {
        clearExportCallBacks();
      }
    })

    it('getInstance', 0, () => {
      expect(instance).not().assertUndefined()
    })

    it('onSaveStart_1', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveStart);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      instance.onSaveStart(request, jobId);
      if (removeImportCallBacks) {
        removeImportCallBacks(jobId)
      }
      mocker.verify('onSaveStart', []).once();
    })

    it('onSaveStart_2', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveStart);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      instance.onSaveStart(request, 2);
      mocker.verify('onSaveStart', []).times(0);
    })

    it('onSaveFailed_01', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveFailed);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      const errCode = 1001;
      instance.onSaveFailed(request, jobId, errCode);
      mocker.verify('onSaveFailed', [errCode]).once();
    })

    it('onSaveFailed_02', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveFailed);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      const errCode = 1001;
      instance.onSaveFailed(request, 2, errCode)
      mocker.verify('onSaveFailed', [errCode]).times(0);
    })

    it('onSaveSuccess_01', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveSuccess);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      instance.onSaveSuccess(request, jobId)
      mocker.verify('onSaveSuccess', []).once();
    })

    it('onSaveSuccess_02', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onSaveSuccess);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      instance.onSaveSuccess(request, 2)
      mocker.verify('onSaveSuccess', []).times(0);
    })

    it('onExportStarted_01', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportStarted);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      instance.onExportStarted(request, jobId)
      mocker.verify('onExportStarted', []).once();
    })

    it('onExportStarted_02', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportStarted);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      instance.onSaveSuccess(request, 2)
      mocker.verify('onExportStarted', []).times(0);
    })

    it('onExportProcessed_01', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportFinished);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      let exportContent = new ShareEventVcsBean(ShareType.ONLY_TEXT);
      instance.onExportProcessed(request, jobId, exportContent);
      mocker.verify('onExportFinished', [exportContent]).once();
    })

    it('onExportProcessed_02', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportFinished);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      let exportContent = new ShareEventVcsBean(ShareType.ONLY_TEXT);
      instance.onExportProcessed(request, jobId + 1, exportContent);
      mocker.verify('onExportFinished', [exportContent]).times(0);
    })

    it('onExportFailed_01', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportFailed);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      const errCode = 1001;
      instance.onExportFailed(request, jobId, errCode);
      mocker.verify('onExportFailed', [errCode]).once();
    })

    it('onExportFailed_02', 0, () => {
      const jobId = 1;
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportFailed);
      if (addExportCallBacks) {
        addExportCallBacks(jobId, mockClass)
      }
      const errCode = 1001;
      instance.onExportFailed(request, jobId + 1, errCode);
      mocker.verify('onExportFailed', [errCode]).times(0);
    })

    it('onImportStarted_01', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock();
      mocker.mockFunc(mockClass, mockClass.onImportStarted);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      let request = new ImportRequest('', TaskState.STATE_WAITING, 1);
      instance.onImportStarted(request, jobId)
      mocker.verify('onImportStarted', []).once();
    })

    it('onImportStarted_02', 0, () => {
      const jobId = 1;
      let mockClass = new ImportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onImportStarted);
      if (addImportCallBack) {
        addImportCallBack(jobId, mockClass)
      }
      let request = new ImportRequest('', TaskState.STATE_WAITING, 1);
      instance.onImportStarted(request, 2)
      mocker.verify('onImportStarted', []).times(0);
    })

    it('exportTextByEvent_eventId_invalid', 0, () => {
      let mockClass = new ExportCallBackMock;
      mocker.mockFunc(mockClass, mockClass.onExportFailed);
      instance.exportTextByEvent(0, mockClass)
      mocker.verify('onExportFailed', [ImportExportErrorCode.EXPORT_EVENT_ID_ILLEGAL]).once();
    })

    it('exportVcsByCalendarAccount_accountId_invalid', 0, () => {
      let account = new SimpleAccount(0);
      let mockClass = new ExportCallBackVcsMock;
      mocker.mockFunc(mockClass, mockClass.onExportFailed);
      let runTaskMock = TestUtil.getPrivateMockFunction(mocker, instance, 'runTask')
      instance.exportVcsByCalendarAccount(account, mockClass);
      mocker.verify('onExportFailed', [ImportExportErrorCode.ACCOUNT_ID_ILLEGAL]).once();
    })

    it('testGetVcsFIleName', 0, () => {
      Log.warn(TAG, `testGetVcsFIleName start`);
      const vcsFileName = GlobalThis.getResourceStr($r('app.string.openharmony_calendar'), i18n.System.getSystemLanguage()) + '.vcs';
      let account = new SimpleAccount(0, 'xxagjksl');
      const getVcsFIleName = TestUtil.getPrivateFunction(instance, 'getVcsFIleName');
      if (!getVcsFIleName) {
        expect(getVcsFIleName).assertNull();
      } else {
        expect(getVcsFIleName(ExportType.EVENTS_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_VCS_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_TEXT_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.ACCOUNT_EXPORT, account) === 'xxagjksl.vcs').assertTrue();
        expect(getVcsFIleName(ExportType.EVENTS_EXPORT, undefined) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_VCS_EXPORT, undefined) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_TEXT_EXPORT, undefined) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.ACCOUNT_EXPORT, undefined) === vcsFileName).assertTrue();
        account = new SimpleAccount(0, 'a\\a<a\\哇|啊>a****???');
        expect(getVcsFIleName(ExportType.EVENTS_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_VCS_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.EVENT_TEXT_EXPORT, account) === vcsFileName).assertTrue();
        expect(getVcsFIleName(ExportType.ACCOUNT_EXPORT, account) === 'aaa哇啊a.vcs').assertTrue();
        account = new SimpleAccount(0, '\\<\\|>****???');
        expect(getVcsFIleName(ExportType.ACCOUNT_EXPORT, account) === vcsFileName).assertTrue();
      }
    })

    it('test_createExportFile', 0, () => {
      Log.warn(TAG, `createExportFile start`);
      const vcsFileName = GlobalThis.getResourceStr($r('app.string.openharmony_calendar'), i18n.System.getSystemLanguage()) + '.vcs';
      let account = new SimpleAccount(0, 'xxagjksl', 1, true);
      const createExportFile = TestUtil.getPrivateFunction(instance, 'createExportFile');
      if (!createExportFile) {
        expect(createExportFile).assertNull();
      } else {
        expect(createExportFile(ExportType.EVENTS_EXPORT, account).includes('el2')).assertTrue();
        expect(GlobalThis.getInstance().context?.filesDir.includes('el2')).assertTrue();
      }
    })
  })
}