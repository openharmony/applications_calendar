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

import { AgendaEventInfo, AgendaListItemViewModel } from '@app/common';
import {
  AgendaListBaseModel,
  ListScrollDir
} from '@app/feature.agenda/src/main/ets/AgendaList/viewmodel/AgendaListBaseModel';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { TestUtil } from '../utils/TestUtil';

export default function AgendaListBaseModelTest() {
  describe('AgendaListBaseModelTest', () => {
    const testFingerInfo: FingerInfo = {
      id: 991,
      globalX: 0,
      globalY: 0,
      localX: 0,
      localY: 0,
      displayX: 0,
      displayY: 0
    };
    const mockEventInfo = new AgendaEventInfo();

    it('getIndex01', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc)(ArgumentMatchers.anyNumber).afterReturn(2);
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(1);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
    });

    it('getIndex02', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc)(ArgumentMatchers.anyNumber).afterReturn(-1);
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(-1);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
    });

    it('getIndex03', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      baseModel.autoScroll(testFingerInfo);
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc)(ArgumentMatchers.anyNumber).afterReturn(-1);
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(-1);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
    });

    it('getIndex04', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc1: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc1)(ArgumentMatchers.anyNumber).afterReturn(-1);
      let mockFunc2: Function = mocker.mockFunc(scroller, scroller.getItemRect);
      let rectResult: RectResult = {
        x: 0,
        y: 0,
        width: 0,
        height: 0
      };
      when(mockFunc2)(ArgumentMatchers.anyNumber).afterReturn(rectResult);
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(0);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
      mocker.ignoreMock(scroller, scroller.getItemRect);
    });

    it('getIndex05', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc1: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc1)(ArgumentMatchers.anyNumber).afterReturn(-1);
      let mockFunc2: Function = mocker.mockFunc(scroller, scroller.getItemRect);
      let rectResult: RectResult = {
        x: 10,
        y: 20,
        width: 50,
        height: 50
      };
      when(mockFunc2)(ArgumentMatchers.anyNumber).afterReturn(rectResult);
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(0);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
      mocker.ignoreMock(scroller, scroller.getItemRect);
    });

    it('getIndex06', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      let mocker: MockKit = new MockKit();
      let scroller: Scroller = new Scroller();
      let mockFunc: Function = mocker.mockFunc(scroller, scroller.getItemIndex);
      when(mockFunc)(ArgumentMatchers.anyNumber).afterThrow("Error");
      baseModel.mScroller = scroller;
      const result = baseModel.getIndex(testFingerInfo);
      expect(result).assertEqual(-1);
      mocker.ignoreMock(scroller, scroller.getItemIndex);
    });


    it('slideActionStart01', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      baseModel.slideActionStart(-1);
      expect(baseModel.nowSelectCount).assertEqual(0);
    });

    it('slideActionStart02', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      baseModel.slideActionStart(0);
      expect(baseModel.nowSelectCount).assertEqual(0);
    });

    it('slideActionStart03', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      mockEventModel.mTitle = 'test';
      mockEventModel.mIsHoliday = true;
      baseModel.dataSources.setData([mockEventModel]);
      baseModel.slideActionStart(0);
      expect(baseModel.nowSelectCount).assertEqual(0);
    });

    it('slideActionStart04', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      mockEventModel.isSelected = true;
      baseModel.dataSources.setData([mockEventModel]);
      baseModel.slideActionStart(0);
      expect(baseModel.nowSelectCount).assertEqual(-1);
    });

    it('slideActionStart05', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      mockEventModel.isSelected = false;
      baseModel.dataSources.setData([mockEventModel]);
      baseModel.slideActionStart(0);
      expect(baseModel.nowSelectCount).assertEqual(1);
    });

    it('slideActionUpdate01', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      const mockEventModel2 = new AgendaListItemViewModel(mockEventInfo);
      baseModel.dataSources.setData([mockEventModel, mockEventModel2]);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel.isSelected).assertEqual(true);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel2.isSelected).assertEqual(false);
      baseModel.slideActionUpdate(1);
      expect(mockEventModel2.isSelected).assertEqual(true);
    });

    it('slideActionUpdate02', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      const mockEventModel2 = new AgendaListItemViewModel(mockEventInfo);
      baseModel.dataSources.setData([mockEventModel, mockEventModel2]);
      baseModel.updateCanSlideSelect(false);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel2.isSelected).assertEqual(false);
    });

    it('slideActionUpdate03', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      const mockEventModel2 = new AgendaListItemViewModel(mockEventInfo);
      const mockEventModel3 = new AgendaListItemViewModel(mockEventInfo);
      baseModel.dataSources.setData([mockEventModel, mockEventModel2, mockEventModel3]);
      TestUtil.setPrivateAttribute(baseModel, 'scrollDirection', ListScrollDir.BOTTOM);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel.isSelected).assertEqual(true);
      baseModel.slideActionUpdate(1);
      expect(mockEventModel2.isSelected).assertEqual(true);
      expect(mockEventModel3.isSelected).assertEqual(false);
      baseModel.slideActionUpdate(2);
      expect(mockEventModel2.isSelected).assertEqual(true);
      expect(mockEventModel3.isSelected).assertEqual(true);
      TestUtil.setPrivateAttribute(baseModel, 'scrollDirection', ListScrollDir.TOP);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel2.isSelected).assertEqual(false);
      expect(mockEventModel3.isSelected).assertEqual(false);
    });

    it('slideActionUpdate04', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      const mockEventModel = new AgendaListItemViewModel(mockEventInfo);
      const mockEventModel2 = new AgendaListItemViewModel(mockEventInfo);
      mockEventModel2.mTitle = 'test';
      mockEventModel2.mIsHoliday = true;
      const mockEventModel3 = new AgendaListItemViewModel(mockEventInfo);
      baseModel.dataSources.setData([mockEventModel, mockEventModel2, mockEventModel3]);
      TestUtil.setPrivateAttribute(baseModel, 'scrollDirection', ListScrollDir.BOTTOM);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel.isSelected).assertEqual(true);
      baseModel.slideActionUpdate(1);
      expect(mockEventModel2.isSelected).assertEqual(false);
      expect(mockEventModel3.isSelected).assertEqual(false);
      baseModel.slideActionUpdate(2);
      expect(mockEventModel2.isSelected).assertEqual(false);
      expect(mockEventModel3.isSelected).assertEqual(true);
      TestUtil.setPrivateAttribute(baseModel, 'scrollDirection', ListScrollDir.TOP);
      baseModel.slideActionUpdate(0);
      expect(mockEventModel2.isSelected).assertEqual(false);
      expect(mockEventModel3.isSelected).assertEqual(false);
    });

    it('slideActionEnd01', 0, () => {
      let baseModel: AgendaListBaseModel = new AgendaListBaseModel();
      TestUtil.setPrivateAttribute(baseModel, 'isAutoScroll', true);
      baseModel.slideActionEnd();
      const isAutoScroll = TestUtil.getPrivateAttribute<boolean>(baseModel, 'isAutoScroll');
      expect(isAutoScroll).assertEqual(false);
    });
  });
}
