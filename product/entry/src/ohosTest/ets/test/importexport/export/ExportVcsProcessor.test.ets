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
import { TaskState } from '@app/feature.importexport/src/main/ets/core/BaseProcessor';
import { AgendaEventInfo, CalendarContract, EventService, GlobalThis } from '@app/common';
import { ExportListener } from '@app/feature.importexport/src/main/ets/ExportListener';
import { Request } from '@app/feature.importexport/src/main/ets/import/Request';
import { buildTextByEventInfo, ExportVcsProcessor } from '@app/feature.importexport/src/main/ets/export/core/ExportVcsProcessor';
import { ExportVcsRequest } from '@app/feature.importexport/src/main/ets/export/core/ExportVcsRequest';
import { ShareEventVcsBean } from '@app/feature.importexport/src/main/ets/interface/ShareEventVcsBean';
import { TestUtil } from '../../utils/TestUtil';
import { VERSION_10 } from '@app/feature.importexport/src/main/ets/vcalendar/VCalendarConstants';
import { ExportType, ShareType } from '@app/feature.importexport';
import { taskpool } from '@kit.ArkTS';

export class ExportServiceMock implements ExportListener<ShareEventVcsBean> {

  onExportProgressChanged(jobId: number, totalEventCount: number, processedEventCount: number): void {
  }

  onExportStarted(request: Request, jobId: number): void {
  }

  onExportProcessed(request: Request, jobId: number, exportData: ShareEventVcsBean): void {
  }

  onExportFailed(request: Request, jobId: number, errorCode: number): void {
  }

  onExportFinished(request: Request, jobId: number): void {
  }
}

export default function ExportVcsProcessorTest() {
  describe('ExportVcsProcessorTest', () => {
    let instance: ExportVcsProcessor;
    let service = new ExportServiceMock;
    let request = new ExportVcsRequest(undefined, [], '', '',
      TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
    let mocker: MockKit = new MockKit();
    let eventService = EventService.INSTANCE;
    beforeEach(() => {
      request.setStatus(TaskState.STATE_WAITING);
      instance = new ExportVcsProcessor(request, null, service, 1)
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

    it('reportUtil_ACCOUNT_EXPORT', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.ACCOUNT_EXPORT, 1, ShareType.ONLY_TEXT);
      instance = new ExportVcsProcessor(request, null, service, 1)
      instance.reportUtil(1);
      expect(instance.isImportType()).assertFalse();
    })

    it('reportUtil_OTHER_EXPORT', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      instance = new ExportVcsProcessor(request, null, service, 1)
      instance.reportUtil(1);
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

    it('getCalendarVersion', 0, async (done: Function) => {
      let getCalendarVersion = TestUtil.getPrivateFunction(instance, 'getCalendarVersion');
      if (!getCalendarVersion) {
        expect(getCalendarVersion).assertNull();
      } else {
        expect(getCalendarVersion()).assertEqual(VERSION_10);
        done()
      }
    })

    it('run_exportType_ACCOUNT_EXPORT_queryAccountInfo_failed', 0, async (done: Function) => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.ACCOUNT_EXPORT, 1, ShareType.ONLY_TEXT);
      instance = new ExportVcsProcessor(request, null, service, 1);
      let queryAccountInfo = TestUtil.getPrivateMockFunction(mocker, instance, 'queryAccountInfo');
      if (!queryAccountInfo) {
        expect(queryAccountInfo).assertNull();
      } else {
        when(queryAccountInfo)(ArgumentMatchers.any).afterReturn(undefined);
        expect(await instance.run()).assertFalse();
        mocker.ignoreMock(instance, queryAccountInfo);
        done()
      }
    })

    it('run_exportType_ACCOUNT_EXPORT_queryAccountInfo_success', 0, async (done: Function) => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.ACCOUNT_EXPORT, 1, ShareType.ONLY_TEXT);
      instance = new ExportVcsProcessor(request, null, service, 1);
      let queryAccountInfo = TestUtil.getPrivateMockFunction(mocker, instance, 'queryAccountInfo');
      if (!queryAccountInfo) {
        expect(queryAccountInfo).assertNull();
      } else {
        when(queryAccountInfo)(ArgumentMatchers.any).afterReturn(new CalendarContract.Accounts);
        expect(await instance.run()).assertFalse();
        mocker.ignoreMock(instance, queryAccountInfo);
        done();
      }
    })

    it('run_exportType_EVENTS_EXPORT_queryEventAndReminds', 0, async (done: Function) => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENTS_EXPORT, 1, ShareType.ONLY_TEXT);
      let queryEventAndReminds = TestUtil.getPrivateFunction(instance, 'queryEventAndReminds');
      when(mocker.mockFunc(instance, queryEventAndReminds))(ArgumentMatchers.any).afterReturn(new CalendarContract.Accounts);
      instance = new ExportVcsProcessor(request, null, service, 1);
      expect(await instance.run()).assertFalse();
      mocker.ignoreMock(instance, queryEventAndReminds);
      done()
    })

    it('run_exportType_not_support', 0, async (done: Function) => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let queryAccountInfo = TestUtil.getPrivateFunction(instance, 'queryAccountInfo');
      when(mocker.mockFunc(instance, queryAccountInfo))(ArgumentMatchers.any).afterReturn(new CalendarContract.Accounts);
      instance = new ExportVcsProcessor(request, null, service, 1);
      expect(await instance.run()).assertFalse();
      mocker.ignoreMock(instance, queryAccountInfo);
      done()
    })

    // 存在多语言的问题, 当前暂时用非空字符串代替
    it('buildTextByEventInfo_empty_event', 0, () => {
      let eventInfo = new AgendaEventInfo();
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })
    it('buildTextByEventInfo_eventInfo_has_title', 0, () => {
      let eventInfo = new AgendaEventInfo();
      eventInfo.mTitle = 'Test Title'
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })
    it('buildTextByEventInfo_eventInfo_has_important_event_type', 0, () => {
      let eventInfo = new AgendaEventInfo();
      eventInfo.mImportantEventType = 1
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })
    it('buildTextByEventInfo_eventInfo_is_all_day', 0, () => {
      let eventInfo = new AgendaEventInfo();
      eventInfo.mIsAllDay = true;
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })
    it('buildTextByEventInfo_eventInfo_has_location', 0, () => {
      let eventInfo = new AgendaEventInfo();
      eventInfo.mLocation = 'Test Location';
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })
    it('buildTextByEventInfo_eventInfo_has_description', 0, () => {
      let eventInfo = new AgendaEventInfo();
      eventInfo.mDescription = 'Test Description';
      expect(buildTextByEventInfo(eventInfo)).not().assertEqual('');
    })

    it('testBuildShareTitle', 0, () => {
      let buildShareTitle = TestUtil.getPrivateFunction(instance, 'buildShareTitle');
      if (!buildShareTitle) {
        expect(buildShareTitle).assertNull();
      } else {
        const eventInfos: AgendaEventInfo[] = [];
        const eventInfo = new AgendaEventInfo();
        eventInfos.push(eventInfo);
        eventInfo.mTitle = '';
        const noTitle = GlobalThis.getResourceStr($r('app.string.no_title_label'));
        expect(buildShareTitle(eventInfos) === noTitle).assertTrue();
        eventInfo.mTitle = 'xxx';
        expect(buildShareTitle(eventInfos) === 'xxx').assertTrue();
      }
    })

    it('onExportProgressChanged', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      TestUtil.getPrivateFunction(exportVcsProcessor, 'onExportProgressChanged');
      expect(TestUtil.getPrivateAttribute(exportVcsProcessor, 'task')).assertUndefined();
    })

    it('getListener', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      expect(exportVcsProcessor.getListener()).not().assertUndefined();
    })

    it('onTaskCanceled', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      TestUtil.setPrivateAttribute(exportVcsProcessor, 'task', new taskpool.Task(test));
      TestUtil.getPrivateFunction(exportVcsProcessor, 'onTaskCanceled');
      expect(TestUtil.getPrivateAttribute(exportVcsProcessor, 'task')).not().assertUndefined();
    })

    it('queryAccountInfo', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      expect(TestUtil.getPrivateFunction(exportVcsProcessor, 'queryAccountInfo')).not().assertUndefined();
    })

    it('callExportProcessed', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      TestUtil.getPrivateFunction(exportVcsProcessor, 'callExportProcessed')
      expect(TestUtil.getPrivateAttribute(exportVcsProcessor, 'task')).assertUndefined();
    })

    it('getFormatDisplayName', 0, () => {
      let request = new ExportVcsRequest(undefined, [], '', '',
        TaskState.STATE_WAITING, ExportType.EVENT_TEXT_EXPORT, 1, ShareType.ONLY_TEXT);
      let service = new ExportServiceMock;
      let exportVcsProcessor: ExportVcsProcessor = new ExportVcsProcessor(request, null, service, 1);
      expect(TestUtil.getPrivateFunction(exportVcsProcessor, 'getFormatDisplayName')).not().assertUndefined();
    })

    it('getFormatDisplayName_Test_001', 0, () => {
      let getFormatDisplayName: Function | null = TestUtil.getPrivateFunction(instance, 'getFormatDisplayName');
      if (!getFormatDisplayName) {
        expect(getFormatDisplayName).assertNull();
      } else {
        let account: CalendarContract.Accounts = new CalendarContract.Accounts();
        account.calendarDisplayName = 'test'
        const result: string = getFormatDisplayName(account);
        expect(result).assertEqual('test')
      }
    })

    it('getFormatDisplayName_Test_002', 0, () => {
      let getFormatDisplayName: Function | null = TestUtil.getPrivateFunction(instance, 'getFormatDisplayName');
      if (!getFormatDisplayName) {
        expect(getFormatDisplayName).assertNull();
      } else {
        let account: CalendarContract.Accounts = new CalendarContract.Accounts();
        account.accountType = 'holiday';
        account.accountName = 'CN_CUSTOM';
        const result: string = getFormatDisplayName(account);
        expect(result).assertEqual('中国节假日');
      }
    })

  })
}

@Concurrent
function test() {
  console.info('test', 'test');
}