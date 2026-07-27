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
import { beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import { Log } from '@app/common/index';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { SingleMonthlyViewModel } from '@app/feature.monthview/src/main/ets/viewmodel/SingleMonthlyViewModel';
import { MonthViewLayoutModel } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutModel';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';
import { TestUtil } from '../../utils/TestUtil';

const TAG = 'SingleMonthlyViewModelTest';

let viewModel: SingleMonthlyViewModel;


function updateIsCanScroll() {
  viewModel.isWeekShow = true;
  viewModel.updateNowMonthHeight(200, 100)
  expect(viewModel.agendaListModel.canScroll).assertTrue();
  viewModel.updateNowMonthHeight(600, 100)
  expect(viewModel.agendaListModel.canScroll).assertFalse();
  viewModel.isWeekShow = false;
  viewModel.updateNowMonthHeight(200, 50)
  expect(viewModel.agendaListModel.canScroll).assertTrue();
  viewModel.updateNowMonthHeight(600, 20)
  expect(viewModel.agendaListModel.canScroll).assertFalse();
}

function weekAnimationUpdate(isWeekShow: boolean) {
  viewModel.isWeekShow = isWeekShow;
  viewModel.isFullShow = false;
  TestUtil.setPrivateAttribute(viewModel, 'canFullShow', false);
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = false;
  viewModel.initMonthHeight();
  const oldHeight = viewModel.editHeight - (isWeekShow ? 0 : 1);
  viewModel.updateWeekHeightByOffsetY(-1);
  expect(viewModel.editHeight).assertEqual(oldHeight);
  viewModel.updateWeekHeightByOffsetY(1);
  expect(viewModel.editHeight).assertEqual(oldHeight + 1);
}

function fullAnimationUpdate(isFullShow: boolean) {
  viewModel.isFullShow = isFullShow;
  viewModel.isWeekShow = false;
  TestUtil.setPrivateAttribute(viewModel, 'canFullShow', true);
  MonthlyViewStateManager.getInstance().weekState.isFullShow = isFullShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = false;
  viewModel.updateWeekAgendaHeight(1000, 50, true);
  viewModel.initMonthHeight();
  const oldHeight = viewModel.editHeight - (isFullShow ? 1 : 0);
  viewModel.updateWeekHeightByOffsetY(1);
  expect(viewModel.editHeight).assertEqual(oldHeight + 1);
  viewModel.updateWeekHeightByOffsetY(-1);
  expect(viewModel.editHeight).assertEqual(oldHeight);
}

async function weekAnimationFinish(isWeekShow: boolean) {
  viewModel.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = false;
  viewModel.initMonthHeight();
  viewModel.finishWeekHeightUpdate(isWeekShow ? -1 : 1, false, 0);
  await TestUtil.sleep(50);
  expect(viewModel.isWeekShow).assertEqual(isWeekShow);
}

async function weekAnimationFinishUpdate(isWeekShow: boolean) {
  viewModel.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = false;
  viewModel.initMonthHeight();
  viewModel.updateWeekHeightByOffsetY(-1);
  const monthWeekHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
  viewModel.finishWeekHeightUpdate(isWeekShow ? monthWeekHeight : -monthWeekHeight, false, 0);
  await TestUtil.sleep(50);
  expect(viewModel.isWeekShow).assertEqual(!isWeekShow);
}

function weekRestoreMonthShow(isWeekShow: boolean) {
  viewModel.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = false;
  viewModel.initMonthHeight();
  viewModel.restoreMonthShow();
  expect(viewModel.isWeekShow).assertFalse();
}

function fullRestoreMonthShow(isFullShow: boolean) {
  viewModel.isFullShow = isFullShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = isFullShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = false;
  viewModel.initMonthHeight();
  viewModel.restoreMonthShow();
  expect(viewModel.isFullShow).assertFalse();
}

function finishWeekUpdateByButton(isWeekShow: boolean) {
  viewModel.isWeekShow = isWeekShow;
  viewModel.isFullShow = false;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = isWeekShow;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = false;
  viewModel.finishWeekUpdateByButton(false, 0);
  expect(MonthlyViewStateManager.getInstance().weekState.isWeekShow).assertFalse();
}

function finishFullUpdateByButton(isFullShow: boolean) {
  viewModel.isFullShow = isFullShow;
  viewModel.isWeekShow = false;
  MonthlyViewStateManager.getInstance().weekState.isFullShow = isFullShow;
  MonthlyViewStateManager.getInstance().weekState.isWeekShow = false;
  viewModel.finishWeekUpdateByButton(false, 0);
  expect(viewModel.isFullShow).assertFalse();
}

function updateCalendar() {
  MonthlyViewStateManager.getInstance().state.isAgendaRowMini = false;
  viewModel.updateTagShowCalendar(true);
  const calendar = viewModel.weekViewModels[0].dayViewModels[0].calendar;
  const holiday = viewModel.weekViewModels[0].dayViewModels[0].holiday;
  expect(viewModel.weekViewModels[0].dayViewModels[0].tagText).assertEqual(calendar);
  MonthlyViewStateManager.getInstance().state.isAgendaRowMini = true;
  viewModel.updateTagShowCalendar(true);
  expect(viewModel.weekViewModels[0].dayViewModels[0].tagText).assertEqual(holiday);
}

function updateCurrentVolume() { // 0 54 5*54
  TestUtil.setPrivateAttribute(viewModel, 'maxHeight', 400);
  viewModel.updateCurrentVolume(0)
  expect(viewModel.currentVolume).assertEqual(50);
  viewModel.updateCurrentVolume(54)
  expect(viewModel.currentVolume).assertEqual(0);
  viewModel.updateCurrentVolume(54 * 5)
  expect(viewModel.currentVolume).assertEqual(50);
  viewModel.updateCurrentVolume(400)
  expect(viewModel.currentVolume).assertEqual(100);
  viewModel.updateCurrentVolume(401)
  expect(viewModel.currentVolume).assertEqual(100);
}

export default function SingleMonthlyViewModelTest() {
  describe('SingleMonthlyViewModelTest', () => {
    beforeAll(async (done: Function) => {
      viewModel = new SingleMonthlyViewModel(new DateInfo(2023, 1, 1, 1));
      done();
    })
    beforeEach(async (done: Function) => {
      const monthWeekHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
      if (viewModel.isWeekShow) {
        viewModel.allFinishAnimationUpdate(false, monthWeekHeight);
      } else if (viewModel.isFullShow) {
        viewModel.finishMonthFullAni(0, true, 0);
      }
      done();
    })

    // UX建模规则：日期颜色：单月 默认颜色
    it('onDarkModeChange', 0, () => {
      let hasError: boolean = true;
      Log.info(TAG, `onDarkModeChange begin`);
      viewModel.onDarkModeChange();
      hasError = false;
      expect(hasError).assertFalse();
    })

    // 动效开始
    it('weekAnimationStart', 0, () => {
      viewModel.initMonthHeight();
      expect(viewModel.isPanEdit).assertTrue();
    })

    // 动效执行过程 非周视图
    it('weekAnimationUpdateNoWeek', 0, () => {
      weekAnimationUpdate(false);
    })

    // 动效执行过程 周视图
    it('weekAnimationUpdateWeek', 0, () => {
      weekAnimationUpdate(true);
    })

    // 动效执行过程 非全屏视图
    it('fullAnimationUpdateNoFull', 0, () => {
      fullAnimationUpdate(false);
    })

    // 动效执行过程 全屏视图
    it('fullAnimationUpdateFull', 0, () => {
      fullAnimationUpdate(true);
    })

    // 动效执行结束 非周视图不变
    it('weekAnimationFinishNoWeek', 0, async () => {
      await weekAnimationFinish(false);
    })

    // 动效执行结束 非周视图变周视图
    it('weekAnimationFinishNoWeekUpdate', 0, async () => {
      await weekAnimationFinishUpdate(false);
    })

    // 动效执行结束 周视图不变
    it('weekAnimationFinishWeek', 0, async () => {
      await weekAnimationFinish(true);
    })

    // 动效执行结束 周视图不变
    it('weekAnimationFinishWeekUpdate', 0, async () => {
      await weekAnimationFinishUpdate(true);
    })

    // 更新是否能够滚动
    it('updateIsCanScroll', 0, () => {
      updateIsCanScroll();
    })

    // 还原周视图
    it('weekRestoreMonthShow', 0, () => {
      weekRestoreMonthShow(true);
      weekRestoreMonthShow(false);
    })

    // 还原全屏视图
    it('fullRestoreMonthShow', 0, () => {
      fullRestoreMonthShow(true);
      fullRestoreMonthShow(false);
    })

    // 按钮还原周视图
    it('finishWeekUpdateByButton', 0, () => {
      finishWeekUpdateByButton(true);
      finishWeekUpdateByButton(false);
    })

    // 按钮还原全屏视图
    it('finishFullUpdateByButton', 0, () => {
      finishFullUpdateByButton(true);
      finishFullUpdateByButton(false);
    })

    // 更新日程标点
    it('updateTagCalendar', 0, () => {
      updateCalendar();
    })

    // 更新视图的高度变更率
    it('updateCurrentVolume', 0, () => {
      updateCurrentVolume();
    })
  })
}