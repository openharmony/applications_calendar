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
import { AttachmentServiceImpl } from '@app/service.attachment/src/main/ets/impl/AttachmentServiceImpl';
import { TestUtil } from '../../utils/TestUtil';
import { CalendarDataFeatureHelper, DBUtils, GlobalThis, InnerResultSet } from '@app/common';
import { common } from '@kit.AbilityKit';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { DataShareResultSetMock } from '../../common/dao/DataShareHelperMock';
import { DataShareResultSet } from '@kit.ArkData';

export default function AttachmentServiceImplTest() {
  describe('AttachmentServiceImplTest', () => {
    it('test_addAttachment_feature_not_support', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
      const result: ESObject = await attachmentserviceimpl.addAttachment('test');
      expect(result).assertEqual('');
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      done();
    });

    it('test_acquireAttachmentUri_feature_not_supported', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockIsSupport: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockIsSupport)(ArgumentMatchers.any).afterReturn(false);
      const result: ESObject = await attachmentserviceimpl.acquireAttachmentUri('test');
      expect(result).assertEqual('');
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      done();
    });

    it('test_connectService_context_is_null', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      TestUtil.setPrivateAttribute(GlobalThis.getInstance(), 'context', null);
      let connectService = TestUtil.getPrivateFunction(attachmentserviceimpl, 'connectService');
      if (connectService) {
        const result: ESObject = await connectService();
        expect(result).assertEqual(false);
      }
      done();
    });

    it('test_disConnectService_context_is_null', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      TestUtil.setPrivateAttribute(GlobalThis.getInstance(), 'context', null);
      let disConnectService = TestUtil.getPrivateFunction(attachmentserviceimpl, 'disConnectService');
      if (disConnectService) {
        const result: ESObject = await disConnectService();
        expect(result).assertEqual(false);
      }
      done();
    });

    it('test_disConnectService_disconnectServiceExtensionAbility_succeeds', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let globalThis: GlobalThis = GlobalThis.getInstance();
      TestUtil.setPrivateAttribute(globalThis, 'context', getContext() as common.UIAbilityContext);
      if (globalThis.context) {
        let mocker: MockKit = new MockKit();
        let mockShareExternalController = mocker.mockFunc(globalThis.context, globalThis.context.disconnectServiceExtensionAbility);
        when(mockShareExternalController)(ArgumentMatchers.any).afterReturnNothing();
        let disConnectService = TestUtil.getPrivateFunction(attachmentserviceimpl, 'disConnectService');
        if (disConnectService) {
          const result: ESObject = await disConnectService();
          expect(result).assertEqual(true);
        }
        mocker.ignoreMock(globalThis.context, globalThis.context.disconnectServiceExtensionAbility);
      }
      done();
    });

    it('test_disConnectService_disconnectServiceExtensionAbility_throws_error', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let globalThis: GlobalThis = GlobalThis.getInstance();
      TestUtil.setPrivateAttribute(globalThis, 'context', getContext() as common.UIAbilityContext);

      if (globalThis.context) {
        let mocker: MockKit = new MockKit();
        let mockShareExternalController = mocker.mockFunc(globalThis.context, globalThis.context.disconnectServiceExtensionAbility);
        when(mockShareExternalController)().afterThrow('disconnectServiceExtensionAbility failed');
        let disConnectService = TestUtil.getPrivateFunction(attachmentserviceimpl, 'disConnectService');
        if (disConnectService) {
          const result: ESObject = await disConnectService();
          expect(result).assertEqual(true);
        }
        mocker.ignoreMock(globalThis.context, globalThis.context.disconnectServiceExtensionAbility);
      }
      done();
    });

    it('test_delayAutoReleaseService', 0, async () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let disConnectService = TestUtil.getPrivateFunction(attachmentserviceimpl, 'disConnectService');
      if (disConnectService) {
        let mockfunc: Function = mocker.mockFunc(attachmentserviceimpl, disConnectService);
        when(mockfunc)().afterReturn(Promise.resolve(true));
        TestUtil.setPrivateAttribute(attachmentserviceimpl, 'timeoutId', 1);
        let result: ESObject = attachmentserviceimpl.delayAutoReleaseService();
        expect(result).assertUndefined();
        mocker.ignoreMock(attachmentserviceimpl, disConnectService);
      }
    });

    it('test_batchInsertAttachments', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let infos = [new AttachmentInfo()];
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
      expect(await attachmentserviceimpl.batchInsertAttachments([], 'AAAAAA')).assertEqual(-1);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(true);
      expect(await attachmentserviceimpl.batchInsertAttachments([], 'AAAAAA')).assertEqual(-1);
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.batchInsert);
      when(mockfunc1)(ArgumentMatchers.any).afterReturn(1);
      expect(await attachmentserviceimpl.batchInsertAttachments(infos, 'AAAAAA')).assertEqual(1);
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      mocker1.ignoreMock(DBUtils.INSTANCE, DBUtils.INSTANCE.batchInsert);
      done();
    });

    it('test_insertAttachment', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
      expect(await attachmentserviceimpl.insertAttachment(undefined, 'AAAAAA')).assertEqual(-1);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(true);
      expect(await attachmentserviceimpl.insertAttachment(undefined, 'AAAAAA')).assertEqual(-1);
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.insert);
      when(mockfunc1)(ArgumentMatchers.any).afterReturn(3);
      expect(await attachmentserviceimpl.insertAttachment(new AttachmentInfo(), 'AAAAAA')).assertEqual(3);
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      mocker1.ignoreMock(DBUtils.INSTANCE, DBUtils.INSTANCE.insert);
      done();
    });

    it('test_deleteAttachment', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
      expect(await attachmentserviceimpl.deleteAttachment([123456])).assertEqual(-1);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(true);
      expect(await attachmentserviceimpl.deleteAttachment([])).assertEqual(-1);
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.delete);
      when(mockfunc1)(ArgumentMatchers.any).afterReturn(2);
      expect(await attachmentserviceimpl.deleteAttachment([123456])).assertEqual(2);
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      mocker1.ignoreMock(DBUtils.INSTANCE, DBUtils.INSTANCE.delete);
      done();
    });

    it('test_queryAttachmentList', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
      expect((await attachmentserviceimpl.queryAttachmentList('AAA')).length).assertEqual(0);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(true);
      expect((await attachmentserviceimpl.queryAttachmentList('')).length).assertEqual(0);
      let mocker1: MockKit = new MockKit();
      let mockfunc1: Function = mocker1.mockFunc(DBUtils.INSTANCE, DBUtils.INSTANCE.query);
      when(mockfunc1)(ArgumentMatchers.any).afterReturn(undefined);
      expect((await attachmentserviceimpl.queryAttachmentList('AAA')).length).assertEqual(0);
      mocker.ignoreMock(CalendarDataFeatureHelper, CalendarDataFeatureHelper.isSupportFeature);
      mocker1.ignoreMock(DBUtils.INSTANCE, DBUtils.INSTANCE.query);
      done();
    });

    it('test_parseAttachments', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let result: InnerResultSet | undefined = undefined;
      let parseAttachments = TestUtil.getPrivateFunction(attachmentserviceimpl, 'parseAttachments');
      if (parseAttachments) {
        expect(parseAttachments(result).length).assertEqual(0);
        let baseResultSet: DataShareResultSet = new DataShareResultSetMock();
        baseResultSet.rowCount = 0;
        result = new InnerResultSet(baseResultSet, '');
        expect(parseAttachments(result).length).assertEqual(0);
        baseResultSet.rowCount = 1;
        result = new InnerResultSet(baseResultSet, '');
        let mocker: MockKit = new MockKit();
        let mockfunc: Function = mocker.mockFunc(AttachmentInfo, AttachmentInfo.buildAttachmentInfo);
        when(mockfunc)(ArgumentMatchers.any).afterThrow('buildAttachmentInfo error');
        expect(parseAttachments(result).length).assertEqual(0);
        mocker.ignoreMock(AttachmentInfo, AttachmentInfo.buildAttachmentInfo);
      }
    });

    it('test_isAttachmentListChange_new_and_old_list_are_empty', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let newList: AttachmentInfo[] = [];
      let oldList: AttachmentInfo[] = [];
      let result: ESObject = attachmentserviceimpl.isAttachmentListChange(newList, oldList, true, '123');
      expect(result).assertEqual(false);
    });

    it('test_isAttachmentListChange_insertList_is_not_empty', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let newList: AttachmentInfo[] = [new AttachmentInfo(), new AttachmentInfo()];
      let oldList: AttachmentInfo[] = [];
      let result: ESObject = attachmentserviceimpl.isAttachmentListChange(newList, oldList, true, '123');
      expect(result).assertEqual(true);
    });

    it('test_isAttachmentListChange_deleteList_is_not_empty', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let newList: AttachmentInfo[] = [];
      let oldList: AttachmentInfo[] = [new AttachmentInfo(), new AttachmentInfo()];
      let result: ESObject = attachmentserviceimpl.isAttachmentListChange(newList, oldList, true, '123');
      expect(result).assertEqual(true);
    });

    it('test_isAttachmentListChange_needUpdate_is_false', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let newList: AttachmentInfo[] = [new AttachmentInfo()];
      let oldList: AttachmentInfo[] = [new AttachmentInfo()];
      let result: ESObject = attachmentserviceimpl.isAttachmentListChange(newList, oldList, false, '123');
      expect(result).assertEqual(false);
    });

    it('test_isAttachmentListChange_needUpdate_is_true', 0, () => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let newList: AttachmentInfo[] = [new AttachmentInfo()];
      let oldList: AttachmentInfo[] = [new AttachmentInfo()];
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(attachmentserviceimpl, attachmentserviceimpl.updateAttachmentList);
      when(mockfunc)(ArgumentMatchers.any).afterReturnNothing();
      let result: ESObject = attachmentserviceimpl.isAttachmentListChange(newList, oldList, true, '123');
      expect(result).assertEqual(false);
      mocker.ignoreMock(attachmentserviceimpl, attachmentserviceimpl.updateAttachmentList);
    });

    it('test_updateAttachmentList_insertList_is_not_empty', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockBatchInsertAttachments: Function = mocker.mockFunc(attachmentserviceimpl, attachmentserviceimpl.batchInsertAttachments);
      when(mockBatchInsertAttachments)(ArgumentMatchers.any).afterReturn(Promise.resolve(1));
      let insertList: AttachmentInfo[] = [new AttachmentInfo()];
      let deleteList: number[] = [];
      let eventUuid: string = "123";
      let result: ESObject = await attachmentserviceimpl.updateAttachmentList(insertList, deleteList, eventUuid);
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentserviceimpl, attachmentserviceimpl.batchInsertAttachments);
      done();
    });

    it('test_updateAttachmentList_deleteList_is_not_empty', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockDeleteAttachment: Function = mocker.mockFunc(attachmentserviceimpl, attachmentserviceimpl.deleteAttachment);
      when(mockDeleteAttachment)(ArgumentMatchers.any).afterReturn(Promise.resolve(1));
      let insertList: AttachmentInfo[] = [];
      let deleteList: number[] = [1];
      let eventUuid: string = "123";
      let result: ESObject = await attachmentserviceimpl.updateAttachmentList(insertList, deleteList, eventUuid);
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentserviceimpl, attachmentserviceimpl.deleteAttachment);
      done();
    });

    it('test_updateAttachmentList_both_insertList_and_deleteList_are_not_empty', 0, async (done: Function) => {
      let attachmentserviceimpl: AttachmentServiceImpl = new AttachmentServiceImpl();
      let mocker: MockKit = new MockKit();
      let mockBatchInsertAttachments: Function = mocker.mockFunc(attachmentserviceimpl, attachmentserviceimpl.batchInsertAttachments);
      let mockDeleteAttachment: Function = mocker.mockFunc(attachmentserviceimpl, attachmentserviceimpl.deleteAttachment);
      when(mockBatchInsertAttachments)(ArgumentMatchers.any).afterReturn(Promise.resolve(1));
      when(mockDeleteAttachment)(ArgumentMatchers.any).afterReturn(Promise.resolve(1));
      let insertList: AttachmentInfo[] = [new AttachmentInfo()];
      let deleteList: number[] = [1];
      let eventUuid: string = "123";
      let result: ESObject = await attachmentserviceimpl.updateAttachmentList(insertList, deleteList, eventUuid);
      expect(result).assertUndefined();
      mocker.ignoreMock(attachmentserviceimpl, attachmentserviceimpl.batchInsertAttachments);
      mocker.ignoreMock(attachmentserviceimpl, attachmentserviceimpl.deleteAttachment);
      done();
    });

  });
}