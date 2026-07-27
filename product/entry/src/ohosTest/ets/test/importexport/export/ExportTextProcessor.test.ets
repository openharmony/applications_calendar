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


import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ExportTextProcessor } from '@app/feature.importexport/src/main/ets/export/core/ExportTextProcessor';
import { ExportTextRequest } from '@app/feature.importexport/src/main/ets/export/core/ExportTextRequest';
import { TaskState } from '@app/feature.importexport/src/main/ets/core/BaseProcessor';
import { AgendaEventInfo, EventService } from '@app/common';
import { ExportListener } from '@app/feature.importexport/src/main/ets/ExportListener';
import { Request } from '@app/feature.importexport/src/main/ets/import/Request';
import { ExportType, ShareEventTextBean } from '@app/feature.importexport';

export class ExportServiceMock implements ExportListener<ShareEventTextBean> {
  onExportProgressChanged(jobId: number, totalEventCount: number, processedEventCount: number): void {
  }

  onExportStarted(request: Request, jobId: number): void {
    return;
  }

  onExportProcessed(request: Request, jobId: number, exportData: ShareEventTextBean): void {
    return;
  }

  onExportFailed(request: Request, jobId: number, errorCode: number): void {
    return;
  }

  onExportFinished(request: Request, jobId: number): void {
    return;
  }
}

export default function ExportTextProcessorTest() {
  describe('ExportTextProcessorTest', () => {
    let instance: ExportTextProcessor;
    let service = new ExportServiceMock;
    let request = new ExportTextRequest(1, TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1);
    let mocker: MockKit = new MockKit();
    let eventService = EventService.INSTANCE;
    beforeEach(() => {
      request.setStatus(TaskState.STATE_WAITING);
      instance = new ExportTextProcessor(request, null, service, 1)
    })

    it('getType', 0, () => {
      expect(instance.getType()).assertEqual(0);
    })

    it('cancel', 0, () => {
      expect(instance.cancel(false)).assertTrue();
    })

    it('isCancelled', 0, () => {
      expect(instance.isCancelled()).assertFalse();
    })

    it('isDone', 0, () => {
      expect(instance.isDone()).assertFalse();
    })

    it('isWaitingState', 0, () => {
      expect(instance.isWaitingState()).assertTrue();
    })

    it('isImportType', 0, () => {
      expect(instance.isImportType()).assertFalse();
    })

    it('run_Request_isCanceled', 0, async (done: Function) => {
      request.setStatus(TaskState.STATE_CANCELLED);
      expect(await instance.run()).assertFalse();
      done()
    })

    it('run_Request_isWaiting', 0, async (done: Function) => {
      request.setStatus(TaskState.STATE_RUNNING);
      expect(await instance.run()).assertFalse();
      done()
    })

    it('run_exportType_invalid', 0, async (done: Function) => {
      let request = new ExportTextRequest(1, TaskState.STATE_WAITING, ExportType.ACCOUNT_EXPORT, 1);
      instance = new ExportTextProcessor(request, null, service, 1)
      expect(await instance.run()).assertFalse();
      done()
    })

    it('run_queryEventById_failed', 0, async (done: Function) => {
      let queryEventById: Function = mocker.mockFunc(eventService, eventService.queryEventById);
      when(queryEventById)(ArgumentMatchers.any).afterReturn(undefined);
      let request = new ExportTextRequest(1, TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1);
      instance = new ExportTextProcessor(request, null, service, 1)
      expect(await instance.run()).assertFalse();
      mocker.ignoreMock(eventService, queryEventById)
      done()
    })

    it('run_queryEventById_success', 0, async (done: Function) => {
      let queryEventById: Function = mocker.mockFunc(eventService, eventService.queryEventById);
      when(queryEventById)(ArgumentMatchers.any).afterReturn(new AgendaEventInfo());
      let request = new ExportTextRequest(1, TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1);
      instance = new ExportTextProcessor(request, null, service, 1)
      expect(await instance.run()).assertTrue();
      mocker.ignoreMock(eventService, queryEventById)
      done()
    })
  })
}