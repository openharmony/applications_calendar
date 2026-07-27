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

import { DataSourceTemplate, EmptyUtils, Log, ServiceEnum, ServiceManager, traceEvents } from '@app/common';
import fs from '@ohos.file.fs';
import { AttachmentErrorCode, FileObj } from './FileObj';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { AcquireAttachmentUriResult, AddAttachmentResult, AgendaAttachmentService } from '@app/service.attachment';
import { EXT_VS_MIME_DICT } from '@app/common/src/main/ets/util/FileConst';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { FilePickerUtil } from '@app/common/src/main/ets/util/FilePickerUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { fileUri } from '@kit.CoreFileKit';
import lazy { common, uriPermissionManager, wantConstant } from '@kit.AbilityKit';
import { unifiedDataChannel, uniformDataStruct, uniformTypeDescriptor } from '@kit.ArkData';

const TAG = 'AttachmentViewModel';
const SINGLE_FILE_MAX_SIZE = 104857600; //100MB
const MAX_ATTACHMENT_COUNT: number = 10;

@Observed
export class AttachmentInfoDataSource extends DataSourceTemplate<AttachmentInfo> {
  constructor(attachmentInfo: AttachmentInfo[]) {
    super(attachmentInfo);
  }

  public getDataList(): AttachmentInfo[] {
    return this.mDataSource;
  }

  public addDataInfo(info: AttachmentInfo) {
    this.mDataSource.push(info);
    this.notifyDataReload();
  }

  public deleteDataByIndex(index: number) {
    if (this.totalCount() <= index) {
      return;
    }
    this.mDataSource.splice(index, 1);
    this.notifyDataReload();
  }

  public hasData(): boolean {
    return this.totalCount() > 0;
  }
}

@Observed
export class AttachmentViewModel {
  private static readonly PREVIEW_BUNDLE_NAME = 'com.openharmony.hipreview';
  private static readonly CALENDAR_DATA_BUNDLE_NAME = 'com.ohos.calendardata';
  public originalAttachmentList: AttachmentInfo[] = [];
  public allAttachmentsSize: number = 0; // 记录附件总大小
  @Track public dataSource: AttachmentInfoDataSource = new AttachmentInfoDataSource([]);
  @Track public attachmentCount: number = 0; // 当前附件的个数，需刷新界面显示
  @Track public attExpand: boolean = true; //附件是否展开

  async init(eventUuid: string) {
    if (!EmptyUtils.isStringAndNotEmpty(eventUuid)) {
      Log.info(TAG, 'init isEmpty eventUuid');
      return;
    }
    await this.getAttachmentList(eventUuid);
    this.updateSizeAndCount();
  }

  public async getAttachmentList(eventUuid: string) {
    if (!EmptyUtils.isStringAndNotEmpty(eventUuid)) {
      Log.info(TAG, 'getAttachmentList isEmpty eventUuid');
      return;
    }
    const server = ServiceManager.getInstance().getService<AgendaAttachmentService>(ServiceEnum.ATTACHMENT_SERVICE);
    const result: AttachmentInfo[] | undefined = await server?.queryAttachmentList(eventUuid);
    if (!result) {
      this.originalAttachmentList = [];
      this.dataSource.setData([]);
      return;
    }
    this.originalAttachmentList = [...result];
    this.dataSource.setData(result);
  }

  /**
   * 预览附件
   */
  public async previewAttachment(context: common.UIAbilityContext, attachment: AttachmentInfo): Promise<number> {
    try {
      const server = await ServiceManager.getInstance()
        .getDynamicService<AgendaAttachmentService>(ServiceEnum.ATTACHMENT_SERVICE);
      if (!server) {
        Log.error(TAG, `previewAttachment server is undefined`);
        return AttachmentErrorCode.ATTACHMENT_NOT_EXIST;
      }
      hiTraceMeter.startTrace(traceEvents.acquireAttachmentUri, 0);
      const result = await server?.acquireAttachmentUri(attachment?.filePath);
      let resultJson: AcquireAttachmentUriResult = JSON.parse(result);
      if (resultJson.resultCode !== AttachmentErrorCode.SUCCESS) {
        Log.error(TAG, `previewAttachment acquireAttachmentUri failed`);
        return AttachmentErrorCode.ATTACHMENT_NOT_EXIST;
      }
      const fileUri = resultJson.fileUri;
      hiTraceMeter.finishTrace(traceEvents.acquireAttachmentUri, 0);
      if (!FileUtils.isTrustedPath(fileUri)) {
        Log.error(TAG, "uri is not trusted path");
        return AttachmentErrorCode.ATTACHMENT_NOT_EXIST;
      }
      await uriPermissionManager.grantUriPermission(fileUri,
        wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
        AttachmentViewModel.PREVIEW_BUNDLE_NAME);
      FileUtils.previewAttachment(context, fileUri, attachment?.displayName, attachment?.fileType);
      return AttachmentErrorCode.SUCCESS;
    } catch (err) {
      Log.hilogError(TAG, 'clickAttachment', err);
    }
    return AttachmentErrorCode.ATTACHMENT_NOT_EXIST;
  }

  /**
   * 点击添加附件
   */
  public async addAttachment(context: Context, themeColor: string): Promise<number> {
    const maxSelectCount = MAX_ATTACHMENT_COUNT - this.dataSource.totalCount();
    if (maxSelectCount <= 0) {
      Log.info(TAG, `itemOnClick attachments more then max count`);
      return AttachmentErrorCode.MAX_COUNT;
    }
    let data: string[] = await FilePickerUtil.getDocumentUri(context, maxSelectCount, themeColor);
    if (data.length === 0) {
      Log.info(TAG, 'itemOnClick data is empty.')
      return AttachmentErrorCode.SUCCESS;
    }
    Log.info(TAG, `uris length:${data.length}`);
    let code = AttachmentErrorCode.FAILED;
    for (let uri of data) {
      if (EmptyUtils.isNotOrEmptyString(uri)) {
        Log.warn(TAG, `empty uri. itemOnClick`);
        continue;
      }
      // 调用存储去复制文件
      code = await this.handleUri(uri);
      if (code !== AttachmentErrorCode.SUCCESS) {
        Log.error(TAG, `itemOnClick errorCode:${code}`);
        break;
      }
    }
    Log.info(TAG, `itemOnClick attachmentCount:${this.attachmentCount}`);
    return code;
  }

  /**
   * 拖拽添加附件
   */
  public async fileOnDrop(dragEvent: DragEvent, extraParams?: string): Promise<number> {
    let code = AttachmentErrorCode.FAILED;
    let dragData: UnifiedData = dragEvent?.getData();
    if (!dragData) {
      Log.info(TAG, `fileOnDrop dragData is undefined`);
      return code;
    }
    let records: unifiedDataChannel.UnifiedRecord[] = dragData.getRecords();
    if (!records || records.length <= 0) {
      Log.info(TAG, `fileOnDrop records?.length <= 0`);
      return code;
    }
    for (let i = 0; i < records.length; i++) {
      let types = records[i]?.getTypes();
      if (EmptyUtils.isEmptyArray(types) || !types.includes(uniformTypeDescriptor.UniformDataType.FILE_URI)) {
        continue;
      }
      const fileUri =
        records[i]?.getEntry(uniformTypeDescriptor.UniformDataType.FILE_URI) as uniformDataStruct.FileUri;
      if (EmptyUtils.isNotOrEmptyString(fileUri?.oriUri)) {
        continue;
      }
      // 调用存储去复制文件
      code = await this.handleUri(fileUri.oriUri);
      if (code !== AttachmentErrorCode.SUCCESS) {
        Log.error(TAG, `fileOnDrop errorCode:${code}`);
        break;
      }
    }
    Log.info(TAG, `fileOnDrop attachmentCount:${this.attachmentCount}`);
    return code;
  }

  /**
   * 计算附件总大小
   */
  public calculateAllAttachmentSize() {
    this.allAttachmentsSize = 0;
    if (!this.dataSource.hasData()) {
      Log.info(TAG, 'calculateAllAttachmentSize attachmentsInfos is null');
      return;
    }
    this.dataSource.getDataList().forEach(item => {
      this.allAttachmentsSize = this.allAttachmentsSize + item.fileSize;
    })
  }

  /**
   * 根据uri存到存储本地沙箱
   * @param uri uri资源路径
   * @param type 附件类型
   * @returns
   */
  public async handleUri(uri: string): Promise<number> {
    Log.info(TAG, 'start handleUri');
    let attachment = this.setAttachmentInfo(uri);
    let fileObj = this.handleUriCly(uri, this.allAttachmentsSize);
    if (fileObj.errorCode !== AttachmentErrorCode.SUCCESS) {
      Log.error(TAG, `handleUri errorCode:${fileObj.errorCode}`);
      return fileObj.errorCode;
    }
    attachment.fileSize = fileObj.size;
    attachment.displayName = fileObj.name;
    this.allAttachmentsSize += fileObj.size;
    try {
      const server = await ServiceManager.getInstance()
        .getDynamicService<AgendaAttachmentService>(ServiceEnum.ATTACHMENT_SERVICE);
      if (!server) {
        Log.error(TAG, `handleUri server is undefined`);
        fileObj.errorCode = AttachmentErrorCode.FAILED;
        return fileObj.errorCode;
      }
      hiTraceMeter.startTrace(traceEvents.copyAttachment, 0);
      if (!FileUtils.isTrustedPath(uri)) {
        Log.error(TAG, "uri is not trusted path");
        fileObj.errorCode = AttachmentErrorCode.ATTACHMENT_NOT_EXIST;
        return fileObj.errorCode;
      }
      await uriPermissionManager.grantUriPermission(fileUri.getUriFromPath(uri),
        wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION, AttachmentViewModel.CALENDAR_DATA_BUNDLE_NAME);
      const result = await server.addAttachment(uri);
      let recessJson: AddAttachmentResult = JSON.parse(result);
      fileObj.errorCode = recessJson.resultCode;
      attachment.filePath = recessJson.filePath;
      hiTraceMeter.finishTrace(traceEvents.copyAttachment, 0);
    } catch (err) {
      Log.hilogError(TAG, 'grantUriPermission', err);
      fileObj.errorCode = AttachmentErrorCode.FAILED;
    }
    if (fileObj.errorCode === AttachmentErrorCode.SUCCESS) {
      this.dataSource.addDataInfo(attachment);
      this.attExpand = true;
      this.updateSizeAndCount();
    }
    return fileObj.errorCode;
  }

  public handleUriCly(sourceUri: string, curSize: number): FileObj {
    Log.info(TAG, 'start handleUriCly');
    let fileObj = new FileObj();
    if (sourceUri.length === 0) {
      fileObj.errorCode = AttachmentErrorCode.FAILED;
      Log.info(TAG, 'handleUri targetUri is empty');
      return fileObj;
    }
    if (this.dataSource.totalCount() >= MAX_ATTACHMENT_COUNT) {
      fileObj.errorCode = AttachmentErrorCode.MAX_COUNT;
      Log.info(TAG, 'attachment count is more then 10.');
      return fileObj;
    }
    let sysFile: fs.File | undefined;
    try {
      sysFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      Log.info(TAG, 'openSync success');
      let size = fs.statSync(sysFile.fd).size;
      if (size > SINGLE_FILE_MAX_SIZE) {
        fileObj.errorCode = AttachmentErrorCode.SIZE_OVER_LOAD;
        Log.info(TAG, 'attachment single size is larger then 100MB.');
        return fileObj;
      }
      if (curSize + size > SINGLE_FILE_MAX_SIZE * MAX_ATTACHMENT_COUNT) {
        fileObj.errorCode = AttachmentErrorCode.MAX_SIZE;
        Log.info(TAG, 'attachment all size is larger then 1000MB.');
        return fileObj;
      }
      let fileName = sysFile.name;
      fileObj.name = fileName;
      fileObj.size = size;
      fileObj.targetUri = sourceUri;
    } catch (err) {
      Log.logErrorMsg(TAG, `handleUriCly`, err);
      fileObj.errorCode = AttachmentErrorCode.FAILED;
    } finally {
      if (sysFile) {
        fs.close(sysFile);
      }
    }
    return fileObj;
  }

  /**
   * 获取文件信息
   */
  public setAttachmentInfo(uri: string): AttachmentInfo {
    Log.info(TAG, 'setAttachmentInfo');
    let attachmentInfo = new AttachmentInfo();
    if (!uri) {
      return attachmentInfo;
    }
    // 以文件最后/结尾为文件名
    attachmentInfo.displayName = uri.substring(uri.lastIndexOf('/') + 1);
    // 文件类型
    attachmentInfo.fileType = EXT_VS_MIME_DICT[uri.substring(uri.lastIndexOf('.') + 1)];
    if (!attachmentInfo.fileType) {
      attachmentInfo.fileType = EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE];
    }
    return attachmentInfo;
  }

  public deleteAttachmentByIndex(index: number): boolean {
    Log.info(TAG, `deleteAttachmentByIndex: ${index}`);
    if (index >= this.dataSource.totalCount() || index < 0) {
      Log.error(TAG, `index invalid: ${index}`);
      return false;
    }
    let attachment = this.dataSource.getData(index);
    if (!attachment) {
      Log.error(TAG, `attachment is undefined`);
      return false;
    }
    this.allAttachmentsSize = this.allAttachmentsSize - attachment.fileSize;
    this.dataSource.deleteDataByIndex(index);
    if (!this.dataSource.hasData()) {
      this.attExpand = false;
    }
    this.attachmentCount = this.dataSource.totalCount();
    return false;
  }

  // 新建页面 删除所有附件
  public deleteAllAttachment(): void {
    if (this.dataSource.totalCount() <= 0) {
      Log.info(TAG, 'deleteAllAttachment --> attachmentInfos is empty');
      return;
    }
    this.attExpand = false;
    this.dataSource.setData([]);
    this.updateSizeAndCount();
  }

  /**
   * 重置数据源
   */
  public removeAttachmentsOnPage(): void {
    this.dataSource.setData([]);
    this.attExpand = false;
    this.updateSizeAndCount();
  }

  public async updateSizeAndCount() {
    this.calculateAllAttachmentSize();
    this.attachmentCount = this.dataSource.totalCount();
  }

  public getMaxSelectCount(): number {
    return MAX_ATTACHMENT_COUNT - this.dataSource.totalCount();
  }
}