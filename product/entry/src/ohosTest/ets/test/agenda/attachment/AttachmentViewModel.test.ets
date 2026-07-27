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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import {
  AttachmentInfoDataSource,
  AttachmentViewModel
} from '@app/feature.agenda/src/main/ets/AgendaAttachment/viewmodel/AttachmentViewModel';
import { GlobalThis, ServiceManager } from '@app/common';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { AttachmentServiceImpl } from '@app/service.attachment/src/main/ets/impl/AttachmentServiceImpl';
import { AttachmentErrorCode, FileObj } from '@app/feature.agenda/src/main/ets/AgendaAttachment/viewmodel/FileObj';
import { FilePickerUtil } from '@app/common/src/main/ets/util/FilePickerUtil';
import { fileUri } from '@kit.CoreFileKit';
import { EXT_VS_MIME_DICT } from '@app/common/src/main/ets/util/FileConst';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';

export default function AttachmentViewModelTest() {
  describe('AttachmentViewModelTest', () => {
    it('test_init_eventUuid_is_empty', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.getAttachmentList);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let result: ESObject = await attachmentviewmodel.init('');
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.getAttachmentList);
      done();
    });

    it('test_init_eventUuid_is_not_empty', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfuncGetAttachmentList: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.getAttachmentList);
      let mockfuncUpdateSizeAndCount: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.updateSizeAndCount);
      when(mockfuncGetAttachmentList)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockfuncUpdateSizeAndCount)().afterReturnNothing();
      let result: ESObject = await attachmentviewmodel.init('validEventUuid');
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.getAttachmentList);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.updateSizeAndCount);
      done();
    });

    it('test_getAttachmentList_eventUuid_is_empty', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let result: ESObject = await attachmentviewmodel.getAttachmentList('');
      expect(result).assertUndefined();
      done();
    });

    it('test_getAttachmentList_result_is_Undefined', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      const serviceManager = ServiceManager.getInstance();
      let mockFunc: Function = mocker.mockFunc(serviceManager, serviceManager.getService);
      const attachmentService: AttachmentServiceImpl = new AttachmentServiceImpl();
      when(mockFunc)(ArgumentMatchers.any).afterReturn(attachmentService);

      let mocker2: MockKit = new MockKit();
      let mockfunc2: Function = mocker2.mockFunc(attachmentService, attachmentService.queryAttachmentList);
      when(mockfunc2)(ArgumentMatchers.anyString).afterReturn(undefined);
      let result: ESObject = await attachmentviewmodel.getAttachmentList('validEventUuid');
      expect(result).assertUndefined();
      mocker.ignoreMock(serviceManager, serviceManager.getService);
      mocker2.ignoreMock(attachmentService, attachmentService.queryAttachmentList);
      done();
    });

    it('test_getAttachmentList_valid_data', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      const serviceManager = ServiceManager.getInstance();
      let mockFunc: Function = mocker.mockFunc(serviceManager, serviceManager.getService);
      const attachmentService: AttachmentServiceImpl = new AttachmentServiceImpl();
      when(mockFunc)(ArgumentMatchers.any).afterReturn(attachmentService);

      let mocker2: MockKit = new MockKit();
      let mockfunc2: Function = mocker2.mockFunc(attachmentService, attachmentService.queryAttachmentList);

      let info = new AttachmentInfo();
      info.displayName = 'ABC';
      let mockAttachments: AttachmentInfo[] = [info];
      when(mockfunc2)(ArgumentMatchers.anyString).afterReturn(mockAttachments);
      let result: ESObject = await attachmentviewmodel.getAttachmentList('validEventUuid');
      expect(result).assertUndefined();
      expect(attachmentviewmodel.originalAttachmentList).assertDeepEquals(mockAttachments);
      mocker.ignoreMock(serviceManager, serviceManager.getService);
      mocker2.ignoreMock(attachmentService, attachmentService.queryAttachmentList);
      done();
    });

    it('test_previewAttachment_server_is_undefined', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(ServiceManager.getInstance(), ServiceManager.getInstance()
        .getDynamicService);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(undefined);
      const result: ESObject = await attachmentviewmodel.previewAttachment(GlobalThis.getInstance().context!, new AttachmentInfo());
      expect(result).assertEqual(AttachmentErrorCode.ATTACHMENT_NOT_EXIST);
      mocker.ignoreMock(ServiceManager.getInstance(), ServiceManager.getInstance().getDynamicService);
      done();
    });

    it('test_previewAttachment_acquireAttachmentUri_fails', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(ServiceManager.getInstance(), ServiceManager.getInstance()
        .getDynamicService);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({
        acquireAttachmentUri: async (filePath: string): Promise<string> => {
          return JSON.stringify({ resultCode: AttachmentErrorCode.ATTACHMENT_NOT_EXIST });
        }
      });
      const result: ESObject = await attachmentviewmodel.previewAttachment(GlobalThis.getInstance().context!, new AttachmentInfo());
      expect(result).assertEqual(AttachmentErrorCode.ATTACHMENT_NOT_EXIST);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({
        acquireAttachmentUri: async (filePath: string): Promise<string> => {
          return JSON.stringify({ resultCode: AttachmentErrorCode.SUCCESS });
        }
      });
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(FileUtils, FileUtils.previewAttachment);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(true);
      const result1: ESObject = await attachmentviewmodel.previewAttachment(GlobalThis.getInstance().context!, new AttachmentInfo());
      expect(result1).assertEqual(AttachmentErrorCode.ATTACHMENT_NOT_EXIST);
      mocker.ignoreMock(ServiceManager.getInstance(), ServiceManager.getInstance().getDynamicService);
      done();
    });

    it('test_previewAttachment_exception_occurs', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(ServiceManager.getInstance(), ServiceManager.getInstance()
        .getDynamicService);
      when(mockfunc)(ArgumentMatchers.anyString).afterThrow('Error');
      const result: ESObject = await attachmentviewmodel.previewAttachment(GlobalThis.getInstance().context!, new AttachmentInfo());
      expect(result).assertEqual(AttachmentErrorCode.ATTACHMENT_NOT_EXIST);
      mocker.ignoreMock(ServiceManager.getInstance(), ServiceManager.getInstance().getDynamicService);
      done();
    });

    it('test_addAttachment_maxSelectCount', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);

      const result: ESObject = await attachmentviewmodel.addAttachment(getContext(), 'themeColor');
      expect(result).assertEqual(AttachmentErrorCode.MAX_COUNT);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      done();
    });

    it('test_addAttachment_data_is_empty', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(0);

      let mockfunc2: Function = mocker.mockFunc(FilePickerUtil, FilePickerUtil.getDocumentUri);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn([]);

      const result: ESObject = await attachmentviewmodel.addAttachment(getContext(), 'themeColor');
      expect(result).assertEqual(AttachmentErrorCode.SUCCESS);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(FilePickerUtil, FilePickerUtil.getDocumentUri);
      done();
    });

    it('test_addAttachment_handleUri_returns_error', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(0);

      let mockfunc2: Function = mocker.mockFunc(FilePickerUtil, FilePickerUtil.getDocumentUri);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn([fileUri.getUriFromPath('/path/to/file')]);

      let mockfunc3: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.handleUri);
      when(mockfunc3)(ArgumentMatchers.anyString).afterReturn(AttachmentErrorCode.FAILED);

      const result: ESObject = await attachmentviewmodel.addAttachment(getContext(), 'themeColor');
      expect(result).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(FilePickerUtil, FilePickerUtil.getDocumentUri);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.handleUri);
      done();
    });

    it('test_addAttachment_handleUri_returns_success', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(0);

      let mockfunc2: Function = mocker.mockFunc(FilePickerUtil, FilePickerUtil.getDocumentUri);
      when(mockfunc2)(ArgumentMatchers.any).afterReturn([fileUri.getUriFromPath('/path/to/file'), '']);

      let mockfunc3: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.handleUri);
      when(mockfunc3)(ArgumentMatchers.anyString).afterReturn(AttachmentErrorCode.SUCCESS);

      const result: ESObject = await attachmentviewmodel.addAttachment(getContext(), 'themeColor');
      expect(result).assertEqual(AttachmentErrorCode.SUCCESS);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(FilePickerUtil, FilePickerUtil.getDocumentUri);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.handleUri);
      done();
    });

    it('test_calculateAllAttachmentSize_dataSource_hasData_is_false', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfuncHasData: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
      when(mockfuncHasData)([]).afterReturn(false);
      attachmentviewmodel.calculateAllAttachmentSize();
      expect(attachmentviewmodel.allAttachmentsSize).assertEqual(0);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
    });

    it('test_calculateAllAttachmentSize_dataSource_hasData_is_true', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfuncHasData: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
      let mockfuncGetDataList: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getDataList);
      let info = new AttachmentInfo();
      info.displayName = 'AAA';
      let attachmentInfoList: AttachmentInfo[] = [info];
      when(mockfuncHasData)().afterReturn(true);
      when(mockfuncGetDataList)().afterReturn(attachmentInfoList);
      attachmentviewmodel.calculateAllAttachmentSize();
      expect(attachmentviewmodel.allAttachmentsSize).assertEqual(0);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getDataList);
    });


    it('test_handleUri_fileObj_errorCode_is_not_success', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(new AttachmentInfo());
      let fileObj: FileObj = new FileObj();
      fileObj.errorCode = AttachmentErrorCode.FAILED;
      let result: ESObject = await attachmentviewmodel.handleUri("testUri");
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(fileObj);
      expect(result).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      mocker1.ignoreMock(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      done();
    });

    it('test_handleUri_error_when_server_is_undefined', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(new AttachmentInfo());
      let fileObj: FileObj = new FileObj();
      fileObj.errorCode = AttachmentErrorCode.SUCCESS;
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(fileObj);

      let mocker2: MockKit = new MockKit();
      let mockfunc2: Function = mocker2.mockFunc(ServiceManager.getInstance(), ServiceManager.getInstance()
        .getDynamicService);
      when(mockfunc2)(ArgumentMatchers.anyString).afterReturn(undefined);

      let result: ESObject = await attachmentviewmodel.handleUri("testUri");
      expect(result).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      mocker1.ignoreMock(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      mocker2.ignoreMock(ServiceManager.getInstance(), ServiceManager.getInstance().getDynamicService);
      done();
    });

    it('test_handleUri_grantUriPermission_fails', 0, async (done: Function) => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(new AttachmentInfo());
      let fileObj: FileObj = new FileObj();
      fileObj.errorCode = AttachmentErrorCode.SUCCESS;
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(fileObj);
      let mocker2: MockKit = new MockKit();
      let mockfunc2: Function = mocker2.mockFunc(ServiceManager.getInstance(), ServiceManager.getInstance()
        .getDynamicService);
      when(mockfunc2)(ArgumentMatchers.anyString).afterThrow('Error');
      let result: ESObject = await attachmentviewmodel.handleUri("testUri");
      expect(result).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.setAttachmentInfo);
      mocker1.ignoreMock(attachmentviewmodel, attachmentviewmodel.handleUriCly);
      mocker2.ignoreMock(ServiceManager.getInstance(), ServiceManager.getInstance().getDynamicService);
      done();
    });

    it('test_handleUriCly_sourceUri_is_empty', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let result: ESObject = attachmentviewmodel.handleUriCly("", 10);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
    });

    it('test_handleUriCly_attachment_count_exceeds_limit', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 10);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.MAX_COUNT);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_file_size_exceeds_limit', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 104857600 + 1);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_total_size_exceeds_limit', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 104857600 * 10 + 1);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_attachment_is_valid', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 10);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_file_open_fails', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("invalidUri", 10);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_file_close_fails', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 10);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_file_size_exceeds_limit_2', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 104857600 * 10 + 1);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_handleUriCly_total_size_exceeds_limit_2', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(9);
      let result: ESObject = attachmentviewmodel.handleUriCly("validUri", 104857600 * 10 + 1);
      expect(result.errorCode).assertEqual(AttachmentErrorCode.FAILED);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });


    it('test_setAttachmentInfo_uri_is_valid', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE]);
    });

    it('test_setAttachmentInfo_valid_file_type', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri.txt';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT.txt);
    });

    it('test_setAttachmentInfo_uri_has_query_param', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri.txt?param=value';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT['unknown']);
    });

    it('test_setAttachmentInfo_uri_has_fragment', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri.txt#fragment';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT['unknown']);
    });

    it('test_setAttachmentInfo_uri_has_invalid_extension', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri.invalid';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE]);
    });

    it('test_setAttachmentInfo_uri_has_no_extension', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'valid/uri';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE]);
    });

    it('test_setAttachmentInfo_uri_is_invalid', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = 'invalid/uri';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual(EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE]);
    });

    it('test_setAttachmentInfo_uri_is_empty', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let uri: ESObject = '';
      let result: ESObject = attachmentviewmodel.setAttachmentInfo(uri);
      expect(result.displayName).assertEqual(uri.substring(uri.lastIndexOf('/') + 1));
      expect(result.fileType).assertEqual('');
    });

    it('test_deleteAttachmentByIndex_index_is_invalid', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);
      const result: ESObject = attachmentviewmodel.deleteAttachmentByIndex(-1);
      expect(result).assertEqual(false);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_deleteAttachmentByIndex_attachment_is_undefined', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);
      let mockfunc2: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
      when(mockfunc2)().afterReturn(null);
      const result: ESObject = attachmentviewmodel.deleteAttachmentByIndex(0);
      expect(result).assertEqual(false);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
    });

    it('test_deleteAttachmentByIndex_deleteDataByIndex_fails', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);
      let mockfunc2: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
      let attachment: AttachmentInfo = new AttachmentInfo();
      attachment.fileSize = 100;
      when(mockfunc2)().afterReturn(attachment);
      let mockfunc3: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.deleteDataByIndex);
      when(mockfunc3)(ArgumentMatchers.anyNumber).afterThrow("error");
      const result: ESObject = attachmentviewmodel.deleteAttachmentByIndex(0);
      expect(result).assertEqual(false);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.deleteDataByIndex);
    });

    it('test_deleteAttachmentByIndex_hasData_is_false', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockfunc)().afterReturn(10);
      let mockfunc2: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
      let attachment: AttachmentInfo = new AttachmentInfo();
      attachment.fileSize = 100;
      when(mockfunc2)().afterReturn(attachment);
      let mockfunc3: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.deleteDataByIndex);
      when(mockfunc3)(ArgumentMatchers.anyNumber).afterReturnNothing();
      let mockfunc4: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
      when(mockfunc4)().afterReturn(false);
      const result: ESObject = attachmentviewmodel.deleteAttachmentByIndex(0);
      expect(result).assertEqual(false);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.getData);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.deleteDataByIndex);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.hasData);
    });

    it('test_deleteAttachmentByIndex_all_operations_succeed', 0, () => {
      let viewModel: AttachmentViewModel = new AttachmentViewModel();
      let attachment1: AttachmentInfo = new AttachmentInfo();
      attachment1.fileSize = 100;
      viewModel.dataSource = new AttachmentInfoDataSource([attachment1]);
      expect(viewModel.deleteAttachmentByIndex(0)).assertEqual(false);
      let attachment2: AttachmentInfo = new AttachmentInfo();
      attachment2.fileSize = 10;
      viewModel.dataSource = new AttachmentInfoDataSource([attachment1, attachment2]);
      expect(viewModel.deleteAttachmentByIndex(0)).assertEqual(false);
    });

    it('test_deleteAllAttachment_dataSource_is_empty', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockTotalCount: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      when(mockTotalCount)().afterReturn(0);
      let result: ESObject = attachmentviewmodel.deleteAllAttachment();
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
    });

    it('test_deleteAllAttachment_dataSource_is_not_empty', 0, () => {
      let attachmentviewmodel: AttachmentViewModel = new AttachmentViewModel();
      let mocker: MockKit = new MockKit();
      let mockTotalCount: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      let mockSetData: Function = mocker.mockFunc(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.setData);
      let mockUpdateSizeAndCount: Function = mocker.mockFunc(attachmentviewmodel, attachmentviewmodel.updateSizeAndCount);
      when(mockTotalCount)().afterReturn(1);
      when(mockSetData)([ArgumentMatchers.anyObj]).afterReturnNothing();
      when(mockUpdateSizeAndCount)().afterReturnNothing();
      attachmentviewmodel.deleteAllAttachment();
      expect(attachmentviewmodel.attExpand).assertEqual(false);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.totalCount);
      mocker.ignoreMock(attachmentviewmodel.dataSource, attachmentviewmodel.dataSource.setData);
      mocker.ignoreMock(attachmentviewmodel, attachmentviewmodel.updateSizeAndCount);
    });

    it('test_empty_path', 0, () => {
      const result = FileUtils.isTrustedPath('');
      expect(result).assertTrue();
    });

    it('test_contains_special_characters', 0, () => {
      const specialCharacters = ['./', '../', '.\\.\\', '%08', '%0a', '%0b', '%0c', '%0d', '%7f', '%00'];
      specialCharacters.forEach(char => {
        const result = FileUtils.isTrustedPath(`path${char}path`);
        expect(result).assertFalse();
      });
    });

    // 多层路径嵌套测试
    it('should return true for a deeply nested valid path', 0, () => {
      const result = FileUtils.isTrustedPath('user/files/documents/2024/04/report.txt');
      expect(result).assertTrue();
    });

    // 混合非法字符与合法路径
    it('should return false when path contains both valid and invalid parts', 0, () => {
      const result = FileUtils.isTrustedPath('user/files%0a/../report.txt');
      expect(result).assertFalse();
    });

    // 多层编码绕过尝试
    it('should detect multi-level encoded traversal', 0, () => {
      const result = FileUtils.isTrustedPath('%252e%252e%252f%75%73%65%72%2f%66%69%6c%65%73%2f%64%6f%63%75%6d%65%6e%74%2e%74%78%74');
      expect(result).assertTrue();
    });

    // 非法路径组合测试
    it('should return false when path contains multiple invalid patterns', 0, () => {
      const result = FileUtils.isTrustedPath('user%0a/../files/*.txt');
      expect(result).assertFalse();
    });

    // 边界值测试 - 空字符串
    it('should return true for empty string input', 0, () => {
      const result = FileUtils.isTrustedPath('');
      expect(result).assertTrue();
    });

    // 极长路径测试
    it('should return true for a very long valid path', 0, () => {
      const longPath = 'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z/';
      const result = FileUtils.isTrustedPath(longPath);
      expect(result).assertTrue();
    });

    // 特殊字符组合测试
    it('should return false when path contains multiple control characters', 0, () => {
      const result = FileUtils.isTrustedPath('user%0a%0d%08/files/document.txt');
      expect(result).assertFalse();
    });

    // 合法路径中包含合法空格
    it('should return true for a path with encoded space', 0, () => {
      const result = FileUtils.isTrustedPath('user%20/files/document.txt');
      expect(result).assertTrue();
    });

    // 合法路径中包含合法点号
    it('should return true for a path with multiple dots but no traversal', 0, () => {
      const result = FileUtils.isTrustedPath('user.files.documents.2024.04.report.txt');
      expect(result).assertTrue();
    });

    // 非法路径中包含合法路径部分
    it('should return false when path has valid parts but also invalid ones', 0, () => {
      const result = FileUtils.isTrustedPath('user/files/..%2freport.txt');
      expect(result).assertFalse();
    });
  });
}