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

import { afterEach, beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { AgendaEventInfo, GlobalData, GlobalDataKeys, GlobalDataValueType, Log } from '@app/common/index';
import {
  ClickPositionType,
  SingleWeekViewModel } from '@app/feature.monthview/src/main/ets/viewmodel/SingleWeekViewModel';
import { AgendaBlockInfo, BlockPosition,
  WeekAgendaBlockModel } from '@app/feature.monthview/src/main/ets/viewmodel/WeekAgendaBlockModel';
import { AgendaEditMenuOpt, CreateAgendaPageSource } from '@app/feature.agenda';
import Stack from '@ohos.util.Stack';
import { TestUtil } from '../../utils/TestUtil';

const TAG = 'SingleWeekViewModel';

export default function SingleWeekViewModelTest() {
  describe('SingleWeekViewModel', () => {
    let viewModel: SingleWeekViewModel;
    let originalLanguage: GlobalDataValueType | undefined;

    let guestEvent: GestureEvent = {
      repeat: false,
      fingerList: [],
      offsetX: 0,
      offsetY: 0,
      angle: 0,
      speed: 0,
      scale: 0,
      pinchCenterX: 0,
      pinchCenterY: 0,
      velocityX: 0,
      velocityY: 0,
      velocity: 0,
      target: {
        area: {
          width: 0,
          height: 0,
          position: {},
          globalPosition: {}
        }
      },
      timestamp: 0,
      source: SourceType.Unknown,
      pressure: 0,
      tiltX: 0,
      tiltY: 0,
      sourceTool: SourceTool.Unknown
    };
    beforeEach(() => {
      viewModel = new SingleWeekViewModel(1);
      viewModel.weekState.openOtherPage = false;
      viewModel.agendaBlockState.hoverBlock = undefined;
      viewModel.agendaBlockState.clickAgendaShow = true;
      viewModel.agendaBlockState.duringSwiperAnimation = true;
      originalLanguage = GlobalData.instance().get(GlobalDataKeys.LANGUAGE);
    })

    it('should_return_NONE_when_event_is_undefined', 0, async (done: Function) => {
      let singleWeekViewModel = new SingleWeekViewModel(1);
      const result = singleWeekViewModel.onLongPressAgendaArea(1);
      expect(result.getClickPositionType()).assertEqual(ClickPositionType.NONE);
      done();
    });

    it('should_return_NONE_when_fingerList_is_empty', 0, async (done: Function) => {
      let singleWeekViewModel = new SingleWeekViewModel(1);
      guestEvent.fingerList = [];
      const result = singleWeekViewModel.onLongPressAgendaArea(1, guestEvent);
      expect(result.getClickPositionType()).assertEqual(ClickPositionType.NONE);
      done();
    });

    it('should_return_CLICK_BLANK_AREA_TWICE_when_eventType_is_CLICK_BLANK_AREA_TWICE', 0, async (done: Function) => {
      let singleWeekViewModel = new SingleWeekViewModel(1);
      singleWeekViewModel.agendaBlockModel.cellWidth = 600;
      guestEvent.fingerList = [{
        id: 1,
        localX: 100,
        localY: 5,
        globalX: 100,
        globalY: 5,
        displayX: 100,
        displayY: 5
      }];
      const result = singleWeekViewModel.onLongPressAgendaArea(1, guestEvent);
      expect(result.getClickPositionType()).assertEqual(ClickPositionType.CLICK_BLANK_AREA_TWICE);
      done();
    });

    it('should_return_NONE_when_eventType_is_not_CLICK_BLANK_AREA_TWICE', 0, async (done: Function) => {
      let singleWeekViewModel = new SingleWeekViewModel(1);
      singleWeekViewModel.agendaBlockModel.cellWidth = 10;
      guestEvent.fingerList = [{
        id: 1,
        localX: 100,
        localY: 200,
        globalX: 100,
        globalY: 200,
        displayX: 100,
        displayY: 200
      }];
      const result = singleWeekViewModel.onLongPressAgendaArea(1, guestEvent);
      expect(result.getClickPositionType()).assertEqual(ClickPositionType.NONE);
      done();
    });

    it('openCreateAgendaPop', 0, async () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(1);
      singleWeekViewModel.jumpCreateAgendaPop(123456789);

      expect(singleWeekViewModel.createPageData).assertDeepEquals({
        data: {
          agendaDateParam: 123456789,
        }
      });
    });

    it('clickBlankArea_undefined', 0, async (done: Function) => {
      const singleWeekViewModel = new SingleWeekViewModel(1);
      expect(singleWeekViewModel.clickBlankArea(undefined)).assertEqual(false);
      done();
    });

    it('clickBlankArea_negative', 0, async (done: Function) => {
      const singleWeekViewModel = new SingleWeekViewModel(1);
      expect(singleWeekViewModel.clickBlankArea(-1)).assertEqual(false);
      done();
    });

    it('clickBlankArea_outOfRange', 0, async (done: Function) => {
      const singleWeekViewModel = new SingleWeekViewModel(1);
      expect(singleWeekViewModel.clickBlankArea(8)).assertEqual(false);
      done();
    });

    it('clickBlankArea_validIndex_0', 0, async (done: Function) => {
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'ug-CN');
      const singleWeekViewModel = new SingleWeekViewModel(1);
      expect(singleWeekViewModel.clickBlankArea(0)).assertEqual(true);
      done();
    });

    it('jumpEditAgendaPop_Err', 0, async (done: Function) => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let selectBlock: AgendaBlockInfo | undefined = undefined;
      let editType: number = AgendaEditMenuOpt.ONLY_THIS_AGENDA;
      await singleWeekViewModel.jumpEditAgendaPop(selectBlock, editType);
      expect(singleWeekViewModel.isCreatePopupShow).assertFalse();
      done();
    });

    it('jumpEditAgendaPop_01', 0, async (done: Function) => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true);
      let editType: number = AgendaEditMenuOpt.ONLY_THIS_AGENDA;
      await singleWeekViewModel.jumpEditAgendaPop(selectBlock, editType);
      expect(singleWeekViewModel.createPageData.data?.intent).assertEqual(CreateAgendaPageSource.EDIT_THIS_AGENDA);
      done();
    });

    it('jumpEditAgendaPop_02', 0, async (done: Function) => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true);
      let editType: number = AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA;
      await singleWeekViewModel.jumpEditAgendaPop(selectBlock, editType);
      expect(singleWeekViewModel.createPageData.data?.intent).assertEqual(CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND);
      done();
    });

    it('jumpEditAgendaPop_03', 0, async (done: Function) => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true);
      let editType: number = AgendaEditMenuOpt.ALL_AGENDA;
      await singleWeekViewModel.jumpEditAgendaPop(selectBlock, editType);
      expect(singleWeekViewModel.createPageData.data?.intent).assertEqual(CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE);
      done();
    });

    it('getBlockOpacity_01', 0, () => {
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true, false, 0, false);
      expect(selectBlock.getOpacityString(255, true)).assertEqual('#e6');
      expect(selectBlock.getOpacityString(153, true)).assertEqual('#99');
      expect(selectBlock.getOpacityString(15, true)).assertEqual('#0f');
    });

    it('getBlockOpacity_02', 0, () => {
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true);
      expect(selectBlock.getOpacityString(255, true)).assertEqual('#e6');
      expect(selectBlock.getOpacityString(153, true)).assertEqual('#b2');
      expect(selectBlock.getOpacityString(153, false)).assertEqual('#99');
    });

    it('getBlockOpacity_03', 0, () => {
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, false, false, 0, false);
      expect(selectBlock.getOpacityString(255, true)).assertEqual('#8a');
      expect(selectBlock.getOpacityString(153, true)).assertEqual('#5c');
    });

    it('getBlockOpacity_04', 0, () => {
      let selectBlock: AgendaBlockInfo =
        new AgendaBlockInfo(new AgendaEventInfo(), 1, new BlockPosition(0, 1, 0, 1), false, true);
      expect(selectBlock.getOpacityString(255, true, 170)).assertEqual('#aa');
      expect(selectBlock.getOpacityString(153, true, 170)).assertEqual('#aa');
      expect(selectBlock.getOpacityString(255, false, 170)).assertEqual('#ff');
      expect(selectBlock.getOpacityString(100, true, 170)).assertEqual('#7d');
    });

    it('computeXIndex_first_branch', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      expect(singleWeekViewModel.computeXIndex(99, 100)).assertEqual(1);
    });

    it('computeXIndex_second_branch', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      expect(singleWeekViewModel.computeXIndex(1, 0)).assertEqual(1);
    });

    it('computeXIndex_third_branch', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      expect(singleWeekViewModel.computeXIndex(1, 0.5)).assertEqual(2);
    });

    it('computeYIndex', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      expect(singleWeekViewModel.computeYIndex(18)).assertEqual(1);
    });

    it('judgeClicktype_click_agenda_block_once', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 100, 0))
        .assertEqual(ClickPositionType.CLICK_AGENDA_BLOCK_ONCE);
    });

    it('judgeClickType_click_blank_area_once', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 100, 1))
        .assertEqual(ClickPositionType.CLICK_BLANK_AREA_ONCE);
    });

    it('judgeClickType_click_agenda_block_twice', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      agendaClickEventStack.push(1000);
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 1200, 0))
        .assertEqual(ClickPositionType.CLICK_AGENDA_BLOCK_TWICE);
    });

    it('judgeClickType_click_blank_area_twice', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      agendaClickEventStack.push(1000);
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 1200, 1))
        .assertEqual(ClickPositionType.CLICK_BLANK_AREA_TWICE);
    });

    it('judgeClickType_click_agenda_block_once_2', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      agendaClickEventStack.push(1000);
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 1400, 0))
        .assertEqual(ClickPositionType.CLICK_AGENDA_BLOCK_ONCE);
    });

    it('judgeClickType_click_blank_area_once_2', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaClickEventStack: Stack<number> = new Stack();
      agendaClickEventStack.push(1000);
      expect(singleWeekViewModel.judgeClickType(agendaClickEventStack, 1400, 1))
        .assertEqual(ClickPositionType.CLICK_BLANK_AREA_ONCE);
    });

    it('computePopDirection_unfold_bottom', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaEventInfo: AgendaBlockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true);

      singleWeekViewModel.computePopDirection(0, agendaEventInfo, 30, 5);
      expect(singleWeekViewModel.popDirection).assertEqual(Placement.Bottom);
    });

    it('computePopDirection_unfold_top', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaEventInfo: AgendaBlockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true);

      singleWeekViewModel.computePopDirection(4, agendaEventInfo, 30, 5);
      expect(singleWeekViewModel.popDirection).assertEqual(Placement.Top);
    });

    it('computePopDirection_fold_bottom', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaEventInfo: AgendaBlockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true);
      agendaEventInfo.isAbbreviation = true;
      singleWeekViewModel.computePopDirection(0, agendaEventInfo, 30, 5);
      expect(singleWeekViewModel.popDirection).assertEqual(Placement.Bottom);
    });

    it('computePopDirection_fold_top', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      let agendaEventInfo: AgendaBlockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true);
      agendaEventInfo.isAbbreviation = true;
      singleWeekViewModel.computePopDirection(4, agendaEventInfo, 30, 5);
      expect(singleWeekViewModel.popDirection).assertEqual(Placement.Top);
    });

    it('setPopParameter', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      singleWeekViewModel.setPopParameter(1, 1);
      expect(singleWeekViewModel.popupPos.x).assertEqual(1);
      expect(singleWeekViewModel.popupPos.y).assertEqual(1);
    });

    it('clickBlankFocusSetting', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      singleWeekViewModel.clickBlankFocusSetting();
      expect(singleWeekViewModel.agendaBlockState.focusedAgendaX).assertEqual(-1);
      expect(singleWeekViewModel.agendaBlockState.focusedAgendaY).assertEqual(-1);
    });


    it('clickAgendaFocusSetting', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      singleWeekViewModel.clickAgendaFocusSetting(1, 1, 1);
      expect(singleWeekViewModel.agendaBlockState.focusedAgendaX).assertEqual(1);
      expect(singleWeekViewModel.agendaBlockState.focusedAgendaY).assertEqual(1);
    });

    it('setWeekFocus', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      singleWeekViewModel.setWeekFocus(1);
      expect(singleWeekViewModel.agendaBlockState.curFocusWeekIndex).assertEqual(1);
    });


    it('handleRightClick_click_agenda', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);

      const model = new WeekAgendaBlockModel(viewModel, 0);
      const blockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true)
      model.blocks.push(blockInfo);
      singleWeekViewModel.agendaBlockModel = model;
      expect(singleWeekViewModel.handleRightClick(0, 0, 1)?.uuid).assertEqual(blockInfo.uuid);
    });

    it('handleRightClick_not_click_agenda', 0, () => {
      let singleWeekViewModel: SingleWeekViewModel = new SingleWeekViewModel(0);

      const model = new WeekAgendaBlockModel(viewModel, 0);
      const blockInfo = new AgendaBlockInfo(new AgendaEventInfo(), 1,
        new BlockPosition(0, 1, 0, 1), false, true)
      model.blocks.push(blockInfo);
      singleWeekViewModel.agendaBlockModel = model;
      expect(singleWeekViewModel.handleRightClick(2, 2, 1)).assertEqual(undefined);
    });

    it('should_return_immediately_when_weekState_openOtherPage_is_true', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      weekModel.weekState.openOtherPage = true;
      weekModel.handleHover(0, 0, 0, 0);
      expect(weekModel.weekState.openOtherPage).assertEqual(false);
    });

    it('should_reset_agenda_hover_flag_when_agendaBlockState_clickAgendaShow_is_true', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      weekModel.agendaBlockState.clickAgendaShow = true;
      weekModel.handleHover(0, 0, 0, 0);
      const preTimeHoverOnBlankArea: number = TestUtil.getPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea');
      expect(preTimeHoverOnBlankArea).assertEqual(0);
    });

    it('should_reset_agenda_hover_flag_when_agendaBlockState_duringSwiperAnimation_is_true', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      weekModel.agendaBlockState.duringSwiperAnimation = true;
      weekModel.handleHover(0, 0, 0, 0);
      const preTimeHoverOnBlankArea: number = TestUtil.getPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea');
      expect(preTimeHoverOnBlankArea).assertEqual(0);
    });

    it('should_start_close_hover_pop_timer_wait', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      weekModel.agendaBlockState.clickAgendaShow = false;
      weekModel.agendaBlockState.duringSwiperAnimation = false;
      weekModel.handleHover(0, 0, 0, 0);
      const preTimeHoverOnBlankArea: number = TestUtil.getPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea');
      expect(preTimeHoverOnBlankArea).not().assertEqual(0);
    });

    it('should_start_close_hover_pop_timer', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      const agendaInfo = new AgendaEventInfo();
      weekModel.agendaBlockState.hoverBlock =
              new AgendaBlockInfo(agendaInfo, 1, new BlockPosition(0, 1, 0, 1), false, true);
      TestUtil.setPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea', 1);
      weekModel.handleHover(0, 0, 0, 0);
      expect(weekModel.agendaBlockState.hoverBlock).assertUndefined();
    });

    it('should_not_start_open_pop', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      const agendaInfo = new AgendaEventInfo();
      const agendaBlock =
        new AgendaBlockInfo(agendaInfo, 1, new BlockPosition(0, 1, 0, 1), false, true);
      weekModel.agendaBlockState.hoverBlock = agendaBlock;
      weekModel.agendaBlockModel.blocks = [agendaBlock]
      weekModel.handleHover(0, 0, 0, 0);
      expect(weekModel.agendaBlockState.openNewHoverPopTimer).assertEqual(0);
    });

    it('should_start_open_pop_wait', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      const agendaInfo = new AgendaEventInfo();
      const agendaBlock =
        new AgendaBlockInfo(agendaInfo, 1, new BlockPosition(0, 1, 0, 1), false, true);
      weekModel.agendaBlockState.hoverBlock = undefined;
      weekModel.agendaBlockModel.blocks = [agendaBlock]
      weekModel.handleHover(0, 0, 0, 0);
      expect(weekModel.agendaBlockState.timer).assertEqual(0);
    });

    it('should_start_open_pop_open_new_pop', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      const agendaInfo = new AgendaEventInfo();
      const agendaBlock =
        new AgendaBlockInfo(agendaInfo, 1, new BlockPosition(0, 1, 0, 1), false, true);
      weekModel.agendaBlockState.hoverBlock = undefined;
      weekModel.agendaBlockModel.blocks = [agendaBlock]
      weekModel.handleHover(0, 0, 0, 0);
      TestUtil.setPrivateAttribute(weekModel, 'preTimeHoverOnAgendaBlock', 1);
      expect(weekModel.agendaBlockState.timer).assertEqual(0);
    });

    it('hover_agenda_pop_clear_timer', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      TestUtil.setPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea', 1);
      weekModel.agendaPopHoverClearTimer();
      const preTimeHoverOnBlankArea: number = TestUtil.getPrivateAttribute(weekModel, 'preTimeHoverOnBlankArea');
      expect(preTimeHoverOnBlankArea).assertEqual(0);
    });

    it('hover_agenda_pop_out_set_close_timer', 0, () => {
      let weekModel: SingleWeekViewModel = new SingleWeekViewModel(0);
      weekModel.closeHoverPopTimerStart();
      expect(weekModel.agendaBlockState.closeHoverPopTimer).not().assertEqual(0);
    });

    afterEach(() => {
      if(originalLanguage) {
        GlobalData.instance().set(GlobalDataKeys.LANGUAGE, originalLanguage);
      }
    });
  })
}