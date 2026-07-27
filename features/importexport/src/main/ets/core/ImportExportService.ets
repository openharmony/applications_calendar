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

import { ExportVcsRequest } from '../export/core/ExportVcsRequest';
import { ImportRequest } from '../import/ImportRequest';
import { ExportListener } from '../ExportListener';
import { ImportListener } from '../ImportListener';
import PlainArray from '@ohos.util.PlainArray';
import {
  EmptyUtils,
  factory,
  GlobalThis,
  Log,
  ServiceEnum,
} from '@app/common';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { ExportVcsProcessor } from '../export/core/ExportVcsProcessor';
import { BaseProcessor, TaskState } from './BaseProcessor';
import { ImportProcessor } from '../import/ImportProcessor';
import { ExportTextRequest } from '../export/core/ExportTextRequest';
import { ExportTextProcessor } from '../export/core/ExportTextProcessor';
import { Request } from '../import/Request';
import { InsertListener } from '../import/InsertListener';
import { i18n } from '@kit.LocalizationKit';
import { PromptAction } from '@kit.ArkUI';
import { ImportExportService } from '../interface/ImportExportService';
import { ShareEventTextBean } from '../interface/ShareEventTextBean';
import { ShareEventVcsBean } from '../interface/ShareEventVcsBean';
import { ImportData } from '../interface/ImportData';
import { ImportCallBack } from '../interface/ImportCallBack';
import { ExportCallBack } from '../interface/ExportCallBack';
import { ExportType, ImportExportErrorCode, ShareType, ImportType, ShareFileFormat } from '../interface/BusinessConstant';
import { SimpleAccount } from '../interface/SimpleAccount';
import { ImportVcsCallBack } from '../interface/ImportVcsCallBack';

// 导出导入服务，涉及三方，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG = 'ImportExportService'
const BASE_ID = 10000


/**
 * 导出导入的服务
 */
@factory(ServiceEnum.IMPORT_EXPORT_SERVICE)
export class ImportExportServiceImpl extends ImportExportService
implements ExportListener<ShareEventVcsBean | ShareEventTextBean>,
ImportListener<ImportData>, InsertListener {
  private mRunningExport: BaseProcessor | undefined;
  private mRunningImport: BaseProcessor | undefined;
  private importCallBacks: PlainArray<ImportCallBack> = new PlainArray();
  private exportCallBacks: PlainArray<ExportCallBack<ShareEventVcsBean | ShareEventTextBean>> = new PlainArray();
  private mJobCount: number = 0;

  onSaveStart(request: Request, jobId: number): void {
    if (this.importCallBacks.get(jobId)) {
      this.importCallBacks.get(jobId).onSaveStart();
    } else {
      Log.warn(TAG, `onSaveStart jobId is ${jobId}  no match callBack`);
    }
  }

  onSaveFailed(request: Request, jobId: number, errorCode: number): void {
    Log.warn(TAG, `onSaveFailed jobId is ${jobId} `);
    if (this.importCallBacks.get(jobId)) {
      this.importCallBacks.get(jobId).onSaveFailed(errorCode);
    } else {
      Log.warn(TAG, `onSaveFailed jobId is ${jobId}  no match callBack`);
    }
    this.removeOnTaskOver(jobId);
  }

  onSaveSuccess(request: Request, jobId: number): void {
    Log.warn(TAG, `onSaveSuccess jobId is ${jobId} `);
    if (this.importCallBacks.get(jobId)) {
      this.importCallBacks.get(jobId).onSaveSuccess();
    } else {
      Log.warn(TAG, `onSaveSuccess jobId is ${jobId}  no match callBack`);
    }
    this.removeOnTaskOver(jobId);
  }

  onExportStarted(request: Request, jobId: number): void {
    if (this.exportCallBacks.get(jobId)) {
      this.exportCallBacks.get(jobId).onExportStarted();
    } else {
      Log.warn(TAG, `onExportStarted jobId is ${jobId}  no match callBack`);
    }
  }

  onExportProgressChanged(jobId: number, totalEventCount: number, processedEventCount: number): void {
    if (this.exportCallBacks.get(jobId)) {
      this.exportCallBacks.get(jobId).onExportProgressChanged(totalEventCount, processedEventCount);
    } else {
      Log.warn(TAG, `onExportProgressChanged jobId is ${jobId} no match callBack`);
    }
  }

  onExportProcessed(request: Request, jobId: number, exportContent: ShareEventVcsBean | ShareEventTextBean): void {
    if (this.exportCallBacks.get(jobId)) {
      this.exportCallBacks.get(jobId).onExportFinished(exportContent);
    } else {
      Log.warn(TAG, `onExportProcessed jobId is ${jobId} no match callBack`);
    }
  }

  onExportFailed(request: Request, jobId: number, errorCode: number) {
    if (this.exportCallBacks.get(jobId)) {
      this.exportCallBacks.get(jobId).onExportFailed(errorCode);
    } else {
      Log.warn(TAG, `onExportFailed jobId is ${jobId}  no match callBack`);
    }
    this.mRunningExport = undefined;
    this.removeOnTaskOver(jobId);
  }

  onExportFinished(request: Request, jobId: number): void {
    if (!this.exportCallBacks.get(jobId)) {
      Log.warn(TAG, `onExportFinished jobId is ${jobId} no match callBack`);
    }
    this.removeOnTaskOver(jobId);
  }

  onImportStarted(request: ImportRequest, jobId: number): void {
    if (this.importCallBacks.get(jobId)) {
      this.importCallBacks.get(jobId).onImportStarted()
    } else {
      Log.warn(TAG, `onImportStarted jobId is ${jobId}  no match callBack`);
    }
  }

  onImportParsed(request: ImportRequest, jobId: number, currentCount: number, totalCount: number): void {
    if (this.importCallBacks.get(jobId)) {

    } else {
      Log.warn(TAG, `onImportParsed jobId is ${jobId}  no match callBack`);
    }
  }

  onImportFinished(request: ImportRequest, jobId: number, parsedData: ImportData): void {
    Log.info(TAG, `onImportFinished jobId is ${jobId}`);
    if (!this.importCallBacks.get(jobId)) {
      Log.warn(TAG, `onImportFinished jobId is ${jobId} no importCallBacks handler`);
      return;
    }
    if (!this.mRunningImport || !(this.mRunningImport instanceof ImportProcessor)) {
      Log.warn(TAG, `onImportFinished mRunningImport is not exist`);
      return;
    }
    const currentImportProcessor: ImportProcessor = this.mRunningImport as ImportProcessor;
    this.importCallBacks.get(jobId).onImportParsed(parsedData, currentImportProcessor.mSaveAction);
    this.importCallBacks.get(jobId).onImportFinished();
  }

  onImportFailed(request: ImportRequest, jobId: number, errorCode: number): void {
    if (this.importCallBacks.get(jobId)) {
      this.importCallBacks.get(jobId).onImportFailed(errorCode);
    } else {
      Log.warn(TAG, `onImportFailed jobId is ${jobId}  no match callBack`);
    }
    this.removeOnTaskOver(jobId);
  }

  onSomeEventsImportFailed(request: ImportRequest, jobId: number): void {

  }

  /**
   * 导出单个日程的text
   * @param eventId
   * @param exportListener
   */
  exportTextByEvent(eventId: number, exportListener: ExportCallBack<ShareEventTextBean>) {
    if (!eventId || eventId < 1) {
      Log.warn(TAG, `exportTextByEvent exportTextByEvent is ${eventId} illeagl`);
      exportListener.onExportFailed(ImportExportErrorCode.EXPORT_EVENT_ID_ILLEGAL);
      return;
    }
    if (this.mRunningImport && this.mRunningImport.isWaitingState()) {
      exportListener.onExportFailed(ImportExportErrorCode.IMPORT_IS_RUNNING);
      return;
    }
    const newJobId: number = this.createJobId();
    this.addExportCallBacks(newJobId, exportListener);
    exportListener.onExportTaskBuild(newJobId);
    const exportRequest: ExportTextRequest = new ExportTextRequest(eventId, TaskState.STATE_WAITING,
      ExportType.EVENT_TEXT_EXPORT, newJobId);
    const exportProcessor: ExportTextProcessor = new ExportTextProcessor(exportRequest,
      GlobalThis.getInstance().context, this, newJobId);
    this.mRunningExport = exportProcessor;
    this.runTask(exportProcessor);
  }

  /**
   * 导出日程的Vcs
   * @param eventIds
   * @param exportListener<string> 返回构造的vcs文件路径
   */
  exportVcsByEvents(eventIds: Array<number>, exportListener: ExportCallBack<ShareEventVcsBean>, isBatch: boolean) {
    if (EmptyUtils.isEmptyArray(eventIds)) {
      Log.warn(TAG, `exportVcsByEvents eventIds is empty illeagl`);
      exportListener?.onExportFailed(ImportExportErrorCode.EXPORT_EVENTS_ILLEGAL);
      return;
    }
    if (!exportListener) {
      Log.warn(TAG, `exportVcsByEvents exportListener is null`);
    }
    if (this.mRunningImport && this.mRunningImport.isWaitingState()) {
      Log.warn(TAG, `exportVcsByEvents fail IMPORT_IS_RUNNING`);
      exportListener?.onExportFailed(ImportExportErrorCode.IMPORT_IS_RUNNING);
      return
    }
    const filePath: string = this.createExportFile(
            isBatch ? ExportType.EVENTS_EXPORT : ExportType.EVENT_VCS_EXPORT, ShareFileFormat.VCS);
    if (EmptyUtils.isEmptyString(filePath)) {
      Log.warn(TAG, `exportVcsByEvents fail EXPORT_FILE_PATH_INVALID`);
      exportListener?.onExportFailed(ImportExportErrorCode.EXPORT_FILE_PATH_INVALID);
      return
    }
    const icsPath: string = this.createExportFile(
      isBatch ? ExportType.EVENTS_EXPORT : ExportType.EVENT_VCS_EXPORT, ShareFileFormat.ICS);
    if (EmptyUtils.isEmptyString(icsPath)) {
      Log.warn(TAG, `exportVcsByEvents fail EXPORT_ICS_PATH_INVALID`);
      exportListener?.onExportFailed(ImportExportErrorCode.EXPORT_FILE_PATH_INVALID);
      return
    }
    const newJobId: number = this.createJobId();
    this.addExportCallBacks(newJobId, exportListener);
    exportListener.onExportTaskBuild(newJobId);
    const exportRequest: ExportVcsRequest = new ExportVcsRequest(undefined, eventIds, filePath, icsPath,
      TaskState.STATE_WAITING, isBatch ? ExportType.EVENTS_EXPORT : ExportType.EVENT_VCS_EXPORT,
      newJobId,
      isBatch ? ShareType.ONLY_VCS : ShareType.TEXT_AND_VCS);
    const exportProcessor: ExportVcsProcessor = new ExportVcsProcessor(exportRequest,
      GlobalThis.getInstance().context, this, newJobId);
    this.mRunningExport = exportProcessor;
    this.runTask(exportProcessor);
  }

  /**
   * 导出日历账户的Vcs
   * @param eventIds
   * @param exportListener<string> 返回构造的vcs文件路径
   */
  exportVcsByCalendarAccount(simpleAccount: SimpleAccount, exportListener: ExportCallBack<ShareEventVcsBean>) {
    if (simpleAccount.mAccountId < 1) {
      Log.warn(TAG, `exportVcsByCalendarAccount simpleAccount id is ${simpleAccount?.mAccountId} illeagl`);
      exportListener.onExportFailed(ImportExportErrorCode.ACCOUNT_ID_ILLEGAL);
      return;
    }
    if (this.mRunningImport && this.mRunningImport.isWaitingState()) {
      exportListener.onExportFailed(ImportExportErrorCode.IMPORT_IS_RUNNING);
      return;
    }
    const filePath: string = this.createExportFile(ExportType.ACCOUNT_EXPORT, ShareFileFormat.VCS, simpleAccount);
    if (EmptyUtils.isEmptyString(filePath)) {
      exportListener.onExportFailed(ImportExportErrorCode.EXPORT_FILE_PATH_INVALID);
      return;
    }
    const icsPath: string = this.createExportFile(ExportType.ACCOUNT_EXPORT, ShareFileFormat.ICS, simpleAccount);
    if (EmptyUtils.isEmptyString(icsPath)) {
      exportListener.onExportFailed(ImportExportErrorCode.EXPORT_FILE_PATH_INVALID);
      return;
    }
    const newJobId: number = this.createJobId();
    this.addExportCallBacks(newJobId, exportListener);
    const exportRequest: ExportVcsRequest = new ExportVcsRequest(simpleAccount, [],
      filePath, icsPath, TaskState.STATE_WAITING, ExportType.ACCOUNT_EXPORT, newJobId, ShareType.ONLY_VCS);
    const exportProcessor: ExportVcsProcessor = new ExportVcsProcessor(exportRequest,
      GlobalThis.getInstance().context, this, newJobId);
    this.mRunningExport = exportProcessor;
    exportListener.onExportTaskBuild(newJobId);
    this.runTask(exportProcessor);
  }

  /**
   * 导入日历账户或日程
   * @param uri vcs文件 或uri
   * @param importListener
   */
  import(uri: string, importCallBack: ImportCallBack, countryCode = '') {
    if (!importCallBack) {
      Log.warn(TAG, `import uri is ${uri} importCallBack is null`);
      return;
    }
    if (this.preHandleRepeatImport(importCallBack)) {
      Log.warn(TAG, `import uri pre import not done`);
      return;
    }
    if (EmptyUtils.isEmptyString(uri)) {
      Log.error(TAG, `import uri is empty`);
      importCallBack.onImportFailed(ImportExportErrorCode.IMPORT_FILE_URI_ILLEGAL);
      return;
    }
    const newJobId: number = this.createJobId();
    this.addImportCallBack(newJobId, importCallBack);
    const filePath = this.getSafeFilePath(uri);
    const importRequest: ImportRequest = new ImportRequest(filePath, TaskState.STATE_WAITING, newJobId);
    const importProcessor: ImportProcessor = new ImportProcessor(importRequest,
      GlobalThis.getInstance().context, this, this, newJobId, countryCode);
    this.mRunningImport = importProcessor;
    this.runTask(importProcessor);
  }

  private preHandleRepeatImport(importCallBack: ImportCallBack):boolean {
    if (!this.mRunningImport) {
      return false;
    }
    if (importCallBack !== ImportVcsCallBack.getInstance()) {
      importCallBack.onImportFailed(ImportExportErrorCode.IMPORT_IS_RUNNING);
      return true;
    }
    if (this.importCallBacks.get(this.mRunningImport.getJobId()) === ImportVcsCallBack.getInstance()) {
      Log.warn(TAG, 'pre import task not done');
      try {
        new PromptAction().showToast({
          message: GlobalThis.getResourceStr($r('app.string.import_in_progress'), i18n.System.getSystemLanguage())
        });
      } catch (error) {
        Log.error(TAG, `preHandleRepeatImport showToast error ${error.message}`);
      }
    }
    return true;
  }

  /**
   * 取消任务
   *
   * @param taskId 任务id
   */
  cancelTaskByTaskId(taskId: number) {
    if (this.mRunningExport && this.mRunningExport.getJobId() == taskId) {
      Log.info(TAG, `cancelTaskByTaskId ${taskId} hit export`)
      if (!this.mRunningExport.isSupportCancel()) {
        Log.info(TAG, `cancelTaskByTaskId the processor not support cancel`);
        return;
      }
      this.mRunningExport.cancel(true);
      this.mRunningExport = undefined;
      const callBack = this.exportCallBacks.remove(taskId);
      if (callBack) {
        callBack.onExportFailed(ImportExportErrorCode.EXPORT_USER_CANCEL);
      }
    }
    if (this.mRunningImport && this.mRunningImport.getJobId() == taskId) {
      Log.info(TAG, `cancelTaskByTaskId ${taskId} hit import`)
      if (!this.mRunningImport.isSupportCancel()) {
        Log.info(TAG, `cancelTaskByTaskId the processor not support cancle`)
        return
      }
      this.mRunningImport.cancel(true)
      this.mRunningImport = undefined
      this.importCallBacks.remove(taskId);
    }
  }

  private removeOnTaskOver(jobId: number) {
    Log.warn(TAG, `removeOnTaskOver jobId is ${jobId} `);
    this.importCallBacks.remove(jobId)
    this.exportCallBacks.remove(jobId)
    this.mRunningExport = undefined
    this.mRunningImport = undefined
  }

  private getSafeFilePath(uri: string): string {
    return decodeURI(uri)
  }

  private createJobId(): number {
    this.mJobCount++;
    return this.mJobCount + BASE_ID;
  }

  private async runTask(baseProcessor: BaseProcessor) {
    await baseProcessor.run()
  }

  private createExportFile(exportType: ExportType, fileFormat: string, simpleAccount?: SimpleAccount): string {
    const context = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `reportPageDrawn context undefined`);
      return '';
    }
    let buildFilePath: string = '';
    const filePath = context.cacheDir + `/${this.getFileName(exportType, fileFormat, simpleAccount)}`;
    if (FileUtils.createFileSync(filePath)) {
      buildFilePath = filePath;
    }
    return buildFilePath;
  }

  private getFileName(exportType: ExportType, fileFormat: string, simpleAccount?: SimpleAccount) {
    const fileName = GlobalThis.getResourceStr($r('app.string.openharmony_calendar'), i18n.System.getSystemLanguage()) + fileFormat;
    if (exportType !== ExportType.ACCOUNT_EXPORT) {
      return fileName;
    }
    if (!simpleAccount?.mAccountDisplayName) {
      return fileName;
    }
    const accountDisplayName = simpleAccount?.mAccountDisplayName;
    let cleanFilePath = FileUtils.getCleanFileName(accountDisplayName);
    // 检查并移除已有的扩展名
    if (cleanFilePath.toLowerCase().endsWith(fileFormat)) {
      cleanFilePath = cleanFilePath.substring(0, cleanFilePath.length - 4);
    }
    if (EmptyUtils.isEmptyString(cleanFilePath, true)) {
      cleanFilePath = fileName;
    } else {
      cleanFilePath = cleanFilePath + fileFormat;
    }
    return cleanFilePath;
  }

  private addExportCallBacks(newJobId: number,
                             exportListener: ExportCallBack<ShareEventVcsBean | ShareEventTextBean>) {
    this.exportCallBacks.add(newJobId, exportListener)
  }

  private removeExportCallBacks(newJobId: number) {
    this.exportCallBacks.remove(newJobId)
  }

  private addImportCallBack(newJobId: number, importCallBack: ImportCallBack) {
    this.importCallBacks.add(newJobId, importCallBack)
  }

  private removeImportCallBacks(newJobId: number) {
    this.importCallBacks.remove(newJobId)
  }

  private clearImportCallBacks() {
    this.importCallBacks.clear();
  }

  private clearExportCallBacks() {
    this.exportCallBacks.clear();
  }
}