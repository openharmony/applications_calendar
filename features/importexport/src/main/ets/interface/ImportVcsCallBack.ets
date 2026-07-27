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

import emitter from '@ohos.events.emitter';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { CommonInnerEvent } from '@app/common/src/main/ets/event/CommonInnerEvent';
import { ImportExportErrorCode } from './BusinessConstant';
import { ImportCallBack } from './ImportCallBack';
import { ImportData } from './ImportData';
import { SimpleAccount } from './SimpleAccount';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { faultEvents, ReportHiEventParams, ReportUtil, statisticEvents } from '@app/common';

/**
 * 导入回调
 *
 */
const TAG = `ImportVcsCallBack`

export class ImportVcsCallBack implements ImportCallBack {
  private static sInstance: ImportVcsCallBack | undefined = undefined;

  private constructor() {

  }

  static getInstance(): ImportVcsCallBack {
    if (!ImportVcsCallBack.sInstance) {
      ImportVcsCallBack.sInstance = new ImportVcsCallBack();
    }
    return ImportVcsCallBack.sInstance;
  }

  public readonly defaultSaveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void =
    (isSave: boolean, simpleAccount?: SimpleAccount) => {
    };

  save(isSave: boolean, simpleAccount?: SimpleAccount) {
    this.saveAction(isSave, simpleAccount);
    Log.info(TAG, `save isSave ${isSave}`)
  }

  onImportParsed(importData: ImportData, saveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void) {
    Log.info(TAG, `onImportParsed importData mEventsCount is ${importData.mEventsCount}
    mHeadEvents is ${importData.mHeadEvents.length} mAllEvents is ${importData.mAllEvents.length}`);
    this.saveAction = saveAction;
    let eventData: emitter.EventData = {
      data: {
        'data': JSON.stringify(importData)
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.VCS_SHOW_PAGE }, eventData);
  }

  onSaveStart(): void {
    showToast(GlobalThis.getResourceStr($r('app.string.importing')))
    Log.info(TAG, 'On Save Start');
  }

  onSaveFailed(errorCode: number): void {
    this.saveAction = this.defaultSaveAction;
    if (errorCode === ImportExportErrorCode.IMPORT_USER_CANCEL) {
      showToast(GlobalThis.getResourceStr($r('app.string.cancel_import')))
    } else {
      showToast(GlobalThis.getResourceStr($r('app.string.import_failed')))
    }
    let params: ReportHiEventParams = {
      ERROR_CODE: errorCode
    }
    ReportUtil.reportStatisticEvent(statisticEvents.importAgendaFail, params);
    Log.info(TAG, 'On Save Failed');
  }

  onSaveSuccess(): void {
    ReportUtil.reportStatisticEvent(statisticEvents.importAgendaSuccess);
    this.saveAction = this.defaultSaveAction;
    showToast(GlobalThis.getResourceStr($r('app.string.import_success')))
    Log.info(TAG, 'On Save Success');
  }

  onImportTaskBuild(jobId: number): void {

  }

  onImportStarted(): void {

  }

  onImportFinished(): void {

  }

  onImportFailed(errorCode: number): void {
    this.saveAction = this.defaultSaveAction;
    showToast(GlobalThis.getResourceStr($r('app.string.import_failed')))
    Log.info(TAG, 'On Import Failed');
  }

  onSomeEventsParseFailed(): boolean {
    return false;
  }

  private saveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void =
    (isSave: boolean, simpleAccount?: SimpleAccount) => {
      Log.info(TAG, `saveAction isSave ${isSave}`)
    }
}