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
// ShareKit 注释 - start
// import lazy {
//   AnchorType,
//   createRecord,
//   createSharedData,
//   showSharePanel
// } from '@app/common/src/main/ets/default/util/ShareUtils';
// import fileUri from '@ohos.file.fileuri';
// import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
// import { ShareType, ShareFileFormat } from './BusinessConstant';
// import { i18n } from '@kit.LocalizationKit';
// import { AgendaEventInfo } from '@app/common/src/main/ets/agenda/AgendaEventInfo';
// import { AgendaService } from '@app/common/src/main/ets/service/implements/agenda/AgendaService';
// import { fileIo as fs } from '@kit.CoreFileKit';
// ShareKit 注释 - end
import { ExportCallBack } from './ExportCallBack';
import { ShareEventVcsBean } from './ShareEventVcsBean';
import { ImportExportErrorCode } from './BusinessConstant';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { ImportExportService } from './ImportExportService';
import { CommonInnerEvent, EmitterCollector } from '@app/common';
import emitter from '@ohos.events.emitter';
import { ExportProgress } from '../model/ExportProgress';

/**
 * 导出回调 <T> 导出数据
 */
const TAG = 'ExportVcsCallBack'

const SHOW_DIALOG_DELAY = 500;
const UPDATE_PROGRESS_TIME_INTERVAL = 50;
const TRIGGER_REMAINING_PERCENTAGE = 0.5;

export class ExportVcsCallBack implements ExportCallBack<ShareEventVcsBean> {
  private jobId: number | undefined;
  private lastUpdateTime = 0;
  private currentProgressText: string = '0%';
  private currentProgress: number = 0;
  private totalCount: number = 0;
  private isDialogShowing: boolean = false;
  private hasDialogOnceShowed: boolean = false;
  private startCountingTimeInMills: number = 0;
  private emitterCollector: EmitterCollector = new EmitterCollector();
  // private sharableTarget?: harmonyShare.SharableTarget; // ShareKit 注释

  // ShareKit 注释 - start
  // constructor(sharableTarget?: harmonyShare.SharableTarget) {
  //   this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_EXPORT_CANCEL_TASK }, () => {
  //     this.cancelTask();
  //   })
  //   this.sharableTarget = sharableTarget;
  // }
  // ShareKit 注释 - end
  constructor() {
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_EXPORT_CANCEL_TASK }, () => {
      this.cancelTask();
    })
  }

  onExportTaskBuild(jobId: number): void {
    this.jobId = jobId;
    this.startCountingTimeInMills = Date.now();
  }

  onExportStarted(): void {

  }

  onExportProgressChanged(totalEventCount: number, processedEventCount: number): void {
    this.totalCount = totalEventCount;
    if (totalEventCount <= 0) {
      Log.warn(TAG, `onExportProgressChanged totalEventCount is ${totalEventCount} illegal`);
      return;
    }
    this.updateProgress(totalEventCount, processedEventCount);
    this.tryShowDialog(totalEventCount, processedEventCount);
  }

  private updateProgress(totalEventCount: number, processedEventCount: number): boolean {
    if (totalEventCount <= 0) {
      Log.warn(TAG, `updateProgress totalEventCount is ${totalEventCount} illegal`);
      return false;
    }
    const timeNow = Date.now();
    if (timeNow - this.lastUpdateTime > UPDATE_PROGRESS_TIME_INTERVAL || processedEventCount >= totalEventCount) {
      this.lastUpdateTime = timeNow;
      this.currentProgress = (processedEventCount / totalEventCount) * 100
      this.currentProgressText = this.currentProgress.toFixed(0) + '%';
      Log.debug(TAG, `updateProgress percent is ${this.currentProgressText} totalEventCount is ${totalEventCount} processedEventCount is ${processedEventCount}`);
      this.emitUpdateEvent();
      return true;
    }
    return false;
  }

  private emitUpdateEvent(): void {
    const exportProgress: ExportProgress = {
      totalCount: this.totalCount,
      currentProgressText: this.currentProgressText,
      currentProgress: this.currentProgress,
    };
    emitter.emit({ eventId: CommonInnerEvent.VCS_EXPORT_UPDATE_PROGRESS }, {
      data: {
        exportProgress: exportProgress
      }
    });
  }

  private tryShowDialog(totalEventCount: number, processedEventCount: number) {
    if (totalEventCount <= 0) {
      Log.warn(TAG, `tryShowDialog totalEventCount is ${totalEventCount} illegal`);
      return false;
    }
    if (this.hasDialogOnceShowed) {
      return false;
    }
    if (Date.now() - this.startCountingTimeInMills > SHOW_DIALOG_DELAY) {
      if ((totalEventCount - processedEventCount) / totalEventCount >= TRIGGER_REMAINING_PERCENTAGE) {
        this.showProgressDialog();
        return true;
      }
    }
    return false;
  }

  private async cancelTask() {
    this.closeDialog();
    let service = await ServiceManager.getInstance()
      .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
    if (!service) {
      Log.warn(TAG, `cancelTask ImportExportService is undefinded`);
      return;
    }
    if (!this.jobId) {
      Log.warn(TAG, `cancelTask jobId is undefinded`);
      return;
    }
    service.cancelTaskByTaskId(this.jobId);
  }

  private showProgressDialog(): boolean {
    Log.info(TAG, `showProgressDialog start`);
    if (this.hasDialogOnceShowed) {
      Log.warn(TAG, `showProgressDialog hasDialogOnceShowed true`);
      return false;
    }
    if (this.isDialogShowing) {
      Log.warn(TAG, `showProgressDialog isDialogShowing true`);
      return false;
    }
    Log.info(TAG, `showProgressDialog do show`);
    emitter.emit({ eventId: CommonInnerEvent.VCS_EXPORT_SHOW_PROGRESS_DIALOG }, {
      data: {
        exportProgress: {
          totalCount: this.totalCount,
          currentProgressText: this.currentProgressText,
          currentProgress: this.currentProgress,
        }
      }
    });
    this.hasDialogOnceShowed = true;
    this.isDialogShowing = true;
    return true;
  }

  onExportFailed(errorCode: number): void {
    Log.error(TAG, `onExportFailed errorCode is ${errorCode}`);
    if (errorCode !== ImportExportErrorCode.EXPORT_USER_CANCEL) {
      showToast(GlobalThis.getResourceStr($r('app.string.export_failed')));
    }
    this.closeDialog();
    this.emitterCollector.off();
  }

  private closeDialog(): boolean {
    if (!this.isDialogShowing) {
      return false;
    }
    this.isDialogShowing = false;
    emitter.emit({ eventId: CommonInnerEvent.VCS_EXPORT_CLOSE_PROGRESS_DIALOG });
    return true;
  }

  async onExportFinished(shareEventVcsBean: ShareEventVcsBean) {
    Log.info(TAG, `onExportFinished`);
    this.closeDialog();
    this.emitterCollector.off();
    // ShareKit 注释 - start
    // try {
    //   this.shareVcsFile(shareEventVcsBean);
    // } catch (err) {
    //   Log.logErrorMsg(TAG, 'onExportFinished shareVcsFile error', err);
    // }
    // ShareKit 注释 - end
  }

  // ShareKit 注释 - start
  // private async shareVcsFile(shareEventVcsBean: ShareEventVcsBean) {
  //   let data: systemShare.SharedData | undefined = undefined;
  //   // 碰一碰分享
  //   if (this.sharableTarget) {
  //     if (canIUse('SystemCapability.Collaboration.HarmonyShare')) {
  //       let record = await this.buildVcsRecord(shareEventVcsBean, ShareFileFormat.VCS);
  //       data = createSharedData(record);
  //       this.sharableTarget.share(data);
  //     } else {
  //       Log.warn(TAG, 'HarmonyShare Not Support');
  //     }
  //     return;
  //   }
  //
  //   if (shareEventVcsBean.shareType == ShareType.ONLY_VCS) {
  //     let record = await this.buildVcsRecord(shareEventVcsBean, ShareFileFormat.VCS);
  //     let icsRecord = await this.buildVcsRecord(shareEventVcsBean, ShareFileFormat.ICS);
  //     data = createSharedData(record, icsRecord);
  //   } else if (shareEventVcsBean.shareType == ShareType.TEXT_AND_VCS) {
  //     let record = await this.buildVcsRecord(shareEventVcsBean, ShareFileFormat.VCS);
  //     let icsRecord = await this.buildVcsRecord(shareEventVcsBean, ShareFileFormat.ICS);
  //     let textRecord = createRecord(uniformTypeDescriptor.UniformDataType.TEXT);
  //     textRecord.content = (shareEventVcsBean.text as string);
  //     const server = await ServiceManager.getInstance().getDynamicService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
  //     if (server) {
  //       const agendaInfo = shareEventVcsBean.event as AgendaEventInfo;
  //       textRecord.title = agendaInfo.mTitle;
  //     } else {
  //       Log.warn(TAG, `shareVcsFile get null AgendaService!`);
  //     }
  //     data = createSharedData(record, icsRecord, textRecord);
  //   } else {
  //     Log.warn(TAG, `shareVcsFile shareType is ${shareEventVcsBean.shareType} not support`);
  //   }
  //   if (!data) {
  //     Log.warn(TAG, 'shareVcsFile sharedData is null or undefined');
  //     return;
  //   }
  //   showSharePanel(data, AnchorType.ANCHOR, GlobalThis.getInstance().shareAnchorViewId);
  // }
  //
  // private async buildVcsRecord(shareEventVcsBean: ShareEventVcsBean, fileFormat: string): Promise<systemShare.SharedRecord> {
  //   const dataType = fileFormat === ShareFileFormat.VCS ? uniformTypeDescriptor.UniformDataType.VCS
  //     : uniformTypeDescriptor.UniformDataType.ICS;
  //   let record = createRecord(dataType);
  //   record.title = shareEventVcsBean.shareTitle;
  //   record.description = shareEventVcsBean.description;
  //
  //   let file: fs.File | undefined = undefined;
  //   try {
  //     const context = GlobalThis.getInstance().context;
  //     if (!context) {
  //       Log.warn(TAG, `context null`);
  //       return record;
  //     }
  //
  //     if (this.sharableTarget) {
  //       let imageName = 'share_back.png';
  //       let imageResource = $r('app.media.share_back');
  //
  //       // 无法获取资源文件, 需要把资源文件转存到应用沙箱
  //       let filePath = context.filesDir + `/${imageName}`;
  //       const mediaContent = await context.resourceManager.getMediaContent(imageResource);
  //       file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  //       let writeLen = fs.writeSync(file.fd, mediaContent.buffer);
  //       Log.info(TAG, "write data to file succeed and size is:" + writeLen);
  //
  //       let uri = fileUri.getUriFromPath(filePath);
  //       record.thumbnailUri = uri;
  //     }
  //
  //
  //   } catch (err) {
  //     Log.warn(TAG, `buildVcsRecord thumbnail errorMsg is ${err?.message}`);
  //   } finally {
  //     if (file) {
  //       fs.closeSync(file);
  //     }
  //   }
  //   const filepath = fileFormat === ShareFileFormat.VCS ? shareEventVcsBean.fileUri : shareEventVcsBean.icsPath;
  //   record.uri = fileUri.getUriFromPath(filepath);
  //   record.label = GlobalThis.getResourceStr($r('app.string.calendar_agenda'),
  //     i18n.System.getSystemLanguage()) + `(${fileFormat})`;
  //   return record;
  // }
  // ShareKit 注释 - end
}