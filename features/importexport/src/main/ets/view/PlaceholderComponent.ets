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

import { CommonInnerEvent, EmitterCollector, Log } from '@app/common';
import { ProgressDialog } from './dialog/ProgressDialog';
import emitter from '@ohos.events.emitter';
import { ExportProgress } from '../model/ExportProgress';

const TAG = 'ExportImportPlaceholderComponent';

/*
 * PlaceholderComponent
 */
@Component
export struct PlaceholderComponent {
  private emitterCollector: EmitterCollector = new EmitterCollector();

  @State
  private currentProgressText: string = '0%';

  @State
  private currentProgress: number = 0;

  private progressDialogController: CustomDialogController | undefined = new CustomDialogController({
    builder: ProgressDialog({
      currentProgress:this.currentProgress,
      currentProgressText: this.currentProgressText,
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.importexport_hide'),
      onCancelClick: () => {
        this.cancelExportTask();
      },
      onConfirmClick: () => {
      },
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
  });

  aboutToAppear(): void {
    Log.info(TAG, `aboutToAppear`);
    this.registerEvent();
  }

  private registerEvent(): void {
    this.emitterCollector.on({
      eventId: CommonInnerEvent.VCS_EXPORT_SHOW_PROGRESS_DIALOG
    }, (data: emitter.EventData) => {
      Log.info(TAG, `on recevier show dialog`);
      this.showProgressDialog(data);
    });
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_EXPORT_CLOSE_PROGRESS_DIALOG }, () => {
      Log.info(TAG, `on recevier close dialog`);
      this.closeProgressDialog();
    });
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_EXPORT_UPDATE_PROGRESS }, (data: emitter.EventData) => {
      this.updateExportProgress(data);
    });
  }

  private updateExportProgress(data: emitter.EventData): void {
    if (!this.progressDialogController) {
      return;
    }
    this.extractExportProgress(data);
  }

  private extractExportProgress(data: emitter.EventData): void {
    const exportProgress: ExportProgress = data.data?.['exportProgress'];
    if (!exportProgress) {
      Log.warn(TAG, `extractExportProgress exportProgress is undefined`);
      return;
    }
    this.currentProgressText = exportProgress.currentProgressText
    this.currentProgress = exportProgress.currentProgress;
  }

  private closeProgressDialog(): void {
    this.progressDialogController?.close();
  }

  private showProgressDialog(data: emitter.EventData): void {
    this.extractExportProgress(data);
    this.progressDialogController?.open();
  }

  private unregisterEvent(): void {
    this.emitterCollector.off();
  }

  build() {
    Row().width(0).height(0);
  }

  aboutToDisappear(): void {
    Log.info(TAG, `aboutToDisappear`);
    this.unregisterEvent();
    this.progressDialogController = undefined;
  }

  private async cancelExportTask(): Promise<void> {
    emitter.emit({ eventId: CommonInnerEvent.VCS_EXPORT_CANCEL_TASK });
  }
}