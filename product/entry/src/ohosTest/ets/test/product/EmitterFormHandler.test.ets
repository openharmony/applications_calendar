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
import { EmitterFormHandler, ParametersInter } from '../../../../main/ets/pages/EmitterFormHandler';
import { TestUtil } from '../utils/TestUtil';
import { Want } from '@kit.AbilityKit';
import {
  AgendaEventInfo,
  EventService,
  NavPathManager,
  ServiceEnum,
  ServiceManager
} from '@app/common';
import { ImportExportService } from '@app/feature.importexport';

export default function EmitterFormHandlerTest() {
  describe('EmitterFormHandlerTest', () => {
    const mockParameters: ParametersInter = {
      year: 2023,
      month: 11,
      day: 24,
      action: '',
      id: 1,
      faType: '',
      dimension: '',
      holidayInfo: '',
      instanceStartMills: 1,
      instanceEndMills: 1,
    };
    const mockAgendaEventInfo: AgendaEventInfo = new AgendaEventInfo();

    it('jumpToMonth_undefinedParameters_returnFalse', 0, async () => {
      let jumpToMonth = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToMonth');
      if (jumpToMonth) {
        const result: boolean = await jumpToMonth(undefined);
        expect(result).assertFalse();
      }
    });

    it('jumpToMonth_definedParameters_returnTrue', 0, async () => {
      let jumpToMonth = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToMonth');
      if (jumpToMonth) {
        const result: boolean = await jumpToMonth(mockParameters);
        expect(result).assertTrue();
      }
    });

    it('testTryHandleShare', 0, async () => {
      let abilityWant: Want | null = null;
      let tryHandleShare = TestUtil.getPrivateFunction(EmitterFormHandler, 'tryHandleShare');
      if (tryHandleShare) {
        let res: boolean = tryHandleShare(abilityWant);
        expect(res).assertFalse();

        abilityWant = new Want();
        res = tryHandleShare(abilityWant);
        expect(res).assertFalse();

        abilityWant.uri = 'test.text'
        res = tryHandleShare(abilityWant);
        expect(res).assertFalse();

        abilityWant.uri = 'test.vcs';
        res = tryHandleShare(abilityWant);
        expect(res).assertTrue();
      }
    });

    it('testDoImportSuccess', 0, async () => {
      let mocker = new MockKit();
      let service: ImportExportService | undefined = await ServiceManager.getInstance()
        .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
      let mockFunc = mocker.mockFunc(service, service?.import);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(Promise.resolve());

      let doImport = TestUtil.getPrivateFunction(EmitterFormHandler, 'doImport');
      if (doImport) {
        const res: boolean = await doImport('');
        expect(res).assertTrue();
      }
    });

    it('testDoImportFail', 0, async () => {
      let mocker = new MockKit();
      let service: ImportExportService | undefined = await ServiceManager.getInstance()
        .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
      let mockFunc = mocker.mockFunc(service, service?.import);
      when(mockFunc)(ArgumentMatchers.any).afterThrow('Import failed');

      let doImport = TestUtil.getPrivateFunction(EmitterFormHandler, 'doImport');
      if (doImport) {
        const res: boolean = await doImport('');
        expect(res).assertFalse();
      }
    });

    it('jumpToAgendaDetail_invalidUri_returnFalse', 0, async () => {
      let abilityWant: Want = {};
      abilityWant.uri = '';

      let jumpToAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToAgendaDetail');
      if (jumpToAgendaDetail) {
        const res: boolean = await jumpToAgendaDetail(abilityWant);
        expect(res).assertFalse();
      }
    });

    it('jumpToAgendaDetail_nullUri_returnFalse', 0, async () => {
      let abilityWant: Want = {};
      abilityWant.uri = undefined;

      let jumpToAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToAgendaDetail');
      if (jumpToAgendaDetail) {
        const res: boolean = await jumpToAgendaDetail(abilityWant);
        expect(res).assertFalse();
      }
    });

    it('jumpToAgendaDetail_invalidScheme_returnFalse', 0, async () => {
      let abilityWant: Want = {};
      abilityWant.uri = 'https://www.baidu.com';

      let jumpToAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToAgendaDetail');
      if (jumpToAgendaDetail) {
        const res: boolean = await jumpToAgendaDetail(abilityWant);
        expect(res).assertFalse();
      }
    });

    it('jumpToAgendaDetail_invalidHost_returnFalse', 0, async () => {
      let abilityWant: Want = {};
      abilityWant.uri = 'calendar://com.openharmony.calendar';

      let jumpToAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToAgendaDetail');
      if (jumpToAgendaDetail) {
        const res: boolean = await jumpToAgendaDetail(abilityWant);
        expect(res).assertFalse();
      }
    });

    it('jumpToAgendaDetail_validUri_returnTrue', 0, async () => {
      let abilityWant: Want = {};
      abilityWant.uri = 'calendar://com.openharmony.calendar';

      let jumpToAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpToAgendaDetail');
      if (jumpToAgendaDetail) {
        const res: boolean = await jumpToAgendaDetail(abilityWant);
        expect(res).assertTrue();
      }
    });

    it('jumpAgendaDetail_01', 0, async () => {
      let jumpAgendaDetail = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpAgendaDetail');
      if (jumpAgendaDetail) {
        const res: boolean = await jumpAgendaDetail({});
        expect(res).assertFalse();
      }
    });

    it('jumpCustomAgenda', 0, async () => {
      let mocker = new MockKit();
      let mockFunc = mocker.mockFunc(NavPathManager.getInstance(), NavPathManager.getInstance().replacePath);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      let jumpCustomAgenda = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpCustomAgenda');
      if (jumpCustomAgenda) {
        const res: boolean = await jumpCustomAgenda(mockParameters);
        expect(res).assertTrue();
      }
    });

    it('jumpShareAgenda', 0, () => {
      let jumpShareAgenda = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpShareAgenda');
      if (jumpShareAgenda) {
        const res: boolean = jumpShareAgenda(mockParameters);
        expect(res).assertTrue();
      }
    });

    it('jumpShareAgenda_switchOff', 0, () => {
      TestUtil.setPrivateAttribute(EmitterFormHandler, 'syncSwitchStatus', 0);
      let jumpShareAgenda = TestUtil.getPrivateFunction(EmitterFormHandler, 'jumpShareAgenda');
      if (jumpShareAgenda) {
        const res: boolean = jumpShareAgenda(mockParameters);
        expect(res).assertFalse();
      }
    });
  })
}

