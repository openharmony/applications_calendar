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

import { AgendaEventInfo, EventService, Log } from '@app/common';
import { ExportListener } from '../../ExportListener';
import { BaseProcessor, TaskState } from '../../core/BaseProcessor';
import { ExportTextRequest } from './ExportTextRequest';
import common from '@ohos.app.ability.common';
import { buildTextByEventInfo } from './ExportVcsProcessor';
import { ShareEventTextBean } from '../../interface/ShareEventTextBean';
import { ExportType, ImportExportErrorCode } from '../../interface/BusinessConstant';

const TAG = 'ExportTextProcessor'

/*
 * 导出日程为Text处理器
 */
export class ExportTextProcessor extends BaseProcessor {
  private mExportRequest: ExportTextRequest;
  private mListener: ExportListener<ShareEventTextBean>;

  constructor(exportRequest: ExportTextRequest, context: common.UIAbilityContext | null, listener: ExportListener<ShareEventTextBean>, jobId: number) {
    super();
    this.mExportRequest = exportRequest;
    this.mContext = context;
    this.mListener = listener;
    this.mJobId = jobId;
  }

  public getType(): number {
    return 0;
  }

  public isImportType(): boolean {
    return false;
  }

  public async run(): Promise<boolean> {
    if (this.mExportRequest.isCanceled()) {
      Log.warn(TAG, `run task isCanceled`);
      return false;
    }
    if (!this.mExportRequest.isWaiting()) {
      Log.warn(TAG, `run unexpect state ${this.mExportRequest.getStatus()}`);
      return false;
    }
    this.mExportRequest.setStatus(TaskState.STATE_RUNNING);
    return await this.runInternal();
  }

  public cancel(isMayInterruptIfRunning: boolean): boolean {
    this.mExportRequest.setStatus(TaskState.STATE_CANCELLED);
    return true;
  }

  public isCancelled(): boolean {
    return this.mExportRequest.isCanceled();
  }

  public isDone(): boolean {
    return this.mExportRequest.isInSuchState(TaskState.STATE_SUCCESS);
  }

  public isWaitingState(): boolean {
    return this.mExportRequest.isWaiting();
  }

  public setRequestStatus(status: TaskState): void {
    this.mExportRequest.setStatus(status);
  }

  private async runInternal(): Promise<boolean> {
    Log.info(TAG, "runInternal: start export");
    if (ExportType.EVENT_TEXT_EXPORT != this.mExportRequest.exportType) {
      Log.warn(TAG, `runInternal: no exportType match to ${this.mExportRequest.exportType}`);
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_TYPE_NO_MATCH);
      return false;
    }
    const event: AgendaEventInfo = await EventService.INSTANCE.queryEventById(this.mExportRequest.eventId);
    if (!event) {
      Log.warn(TAG, `runInternal: no event match to ${this.mExportRequest.eventId}`);
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_NO_SUCH_EVENT);
      return false;
    }
    const exportEventString: string = buildTextByEventInfo(event);
    this.mListener.onExportProcessed(this.mExportRequest, this.mJobId, new ShareEventTextBean(exportEventString, event));
    this.mListener.onExportFinished(this.mExportRequest, this.mJobId);
    return true;
  }
}