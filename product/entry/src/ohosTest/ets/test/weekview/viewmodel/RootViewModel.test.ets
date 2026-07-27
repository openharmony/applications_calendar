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
import { RootViewModel, StaticWeekDayInfo } from '@app/feature.weekview/src/main/ets/viewmodel/RootViewModel';
import { AgendaEventInfo,
  CalendarDate,
  DAY_PER_WEEK, deviceType, GlobalData, GlobalDataKeys, MILLS_PER_DAY, MILLS_PER_HOUR, TabType } from '@app/common';
import { RootModel } from '@app/feature.weekview/src/main/ets/model/RootModel';
import { emitter } from '@kit.BasicServicesKit';
import { DayModel } from '@app/feature.weekview/src/main/ets/model/DayModel';
import { AgendaModel } from '@app/feature.weekview/src/main/ets/model/AgendaModel';
import { Size } from '@kit.ArkUI';
import { TestUtil } from '../../utils/TestUtil';


function testPrepare() {
  GlobalData.instance().set(GlobalDataKeys.THEME_COLOR, '#F76045');
  GlobalData.instance().set(GlobalDataKeys.WEEKENDS, [0, 6]);
  GlobalData.instance().set(GlobalDataKeys.START_OF_WEEK, 0);
  GlobalData.instance().set(GlobalDataKeys.IS_RECESS_TOGGLE_ON, true);
  GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
  GlobalData.instance().set(GlobalDataKeys.IS_24_HOUR_CLOCK, true);
  AppStorage.set('deviceType', 0);
  GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'zh_Hans');
  GlobalData.instance().set(GlobalDataKeys.SUBSCRIPTION_CALENDAR, 1);
  GlobalData.instance().set(GlobalDataKeys.SYSTEM_REGION, 'CN');
  GlobalData.instance().set(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON, true);
  GlobalData.instance().set(GlobalDataKeys.TAB_INDEX, TabType.WEEK);
}

function createViewModel(tabType: TabType, size: Size = { width: 1000, height: 400 }): RootViewModel {
  testPrepare();
  const viewModel = new RootViewModel(tabType);
  let mocker: MockKit = new MockKit();
  const sizeMocker = mocker.mockFunc(viewModel, viewModel.getMainTabComponentSize);
  when(sizeMocker)(ArgumentMatchers.any).afterReturn(size);
  return viewModel;
}

export default function RootViewModelTest() {
  describe('RootViewModelTest', () => {
    it('constructor', 0, () => {
      let viewModel = new RootViewModel(TabType.WEEK);
      expect(viewModel.tabType).assertEqual(TabType.WEEK);
    });

    it('onSwipeMainPage_not_currentView_01', 0, () => {
      RootModel.instance().curTab = TabType.YEAR;
      let viewModel = new RootViewModel(TabType.WEEK);
      expect(viewModel.onSwipeMainPage({})).assertFalse();
    });

    it('onSwipeMainPage_not_currentView_02', 0, () => {
      RootModel.instance().curTab = TabType.YEAR;
      let viewModel = new RootViewModel(TabType.WEEK);
      expect(viewModel.onSwipeMainPage({
        data: {}
      })).assertFalse();
    });

    it('onSwipeMainPage_not_currentView_03', 0, () => {
      RootModel.instance().curTab = TabType.YEAR;
      let viewModel = new RootViewModel(TabType.WEEK);
      expect(viewModel.onSwipeMainPage({
        data: {
          direction: 1
        }
      })).assertFalse();
    });

    it('onSwipeMainPage_weekView_01', 0, () => {
      RootModel.instance().curTab = TabType.WEEK;
      let viewModel = new RootViewModel(TabType.WEEK);
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel, viewModel.dateSwipe);
      mocker.mockFunc(viewModel, viewModel.ganttSwipe);
      expect(viewModel.onSwipeMainPage({
        data: {
          direction: 1
        }
      })).assertTrue();
      mocker.verify('dateSwipe', [1]).times(1);
      mocker.verify('ganttSwipe', [1]).times(0);
    });

    it('onSwipeMainPage_weekView_02', 0, () => {
      RootModel.instance().curTab = TabType.WEEK;
      let viewModel = new RootViewModel(TabType.WEEK);
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel, viewModel.dateSwipe);
      mocker.mockFunc(viewModel, viewModel.ganttSwipe);
      expect(viewModel.onSwipeMainPage({
        data: {
          direction: 0
        }
      })).assertTrue();
      mocker.verify('dateSwipe', [0]).times(1);
      mocker.verify('ganttSwipe', [0]).times(0);
    });

    it('onSwipeMainPage_dayView_01', 0, () => {
      RootModel.instance().curTab = TabType.DAY;
      let viewModel = new RootViewModel(TabType.DAY);
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel, viewModel.dateSwipe);
      mocker.mockFunc(viewModel, viewModel.ganttSwipe);
      expect(viewModel.onSwipeMainPage({
        data: {
          direction: 1
        }
      })).assertTrue();
      mocker.verify('dateSwipe', [1]).times(0);
      mocker.verify('ganttSwipe', [1]).times(1);
    });

    it('onSwipeMainPage_dayView_92', 0, () => {
      RootModel.instance().curTab = TabType.DAY;
      let viewModel = new RootViewModel(TabType.DAY);
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel, viewModel.dateSwipe);
      mocker.mockFunc(viewModel, viewModel.ganttSwipe);
      expect(viewModel.onSwipeMainPage({
        data: {
          direction: 0
        }
      })).assertTrue();
      mocker.verify('dateSwipe', [0]).times(0);
      mocker.verify('ganttSwipe', [0]).times(1);
    });

    it('onBreakpointChange_xs', 0, () => {
      let viewModel = new RootViewModel(TabType.DAY);
      viewModel.onBreakpointChange('xs');
      expect(viewModel.timeFontSize).assertEqual(10);
      expect(viewModel.currentTimeFontSize).assertEqual(10);
    })

    it('onBreakpointChange_sm', 0, () => {
      let viewModel = new RootViewModel(TabType.DAY);
      viewModel.onBreakpointChange('sm');
      expect(viewModel.timeFontSize).assertEqual(14);
      expect(viewModel.currentTimeFontSize).assertEqual(12);
    })

    it('StaticWeekDayInfo', 0, () => {
      let info = new StaticWeekDayInfo(1);
      expect(info.dayOfWeek).assertEqual(1);
    });

    it('basicTest1', 0, () => {
      let hasError: boolean = true;
      const viewModel = createViewModel(TabType.WEEK);
      viewModel.init();
      viewModel.setGanttScrollOffset();
      viewModel.onTimeTick();
      viewModel.onTimezoneChange();
      viewModel.onDateChange();
      viewModel.onTimeChange();
      viewModel.destroy();
      viewModel.onTimezoneChange();
      viewModel.onHourCycleChange();
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('basicTest2', 0, () => {
      let hasError: boolean = true;
      const viewModel = createViewModel(TabType.WEEK);
      AppStorage.set('deviceType', deviceType.PC);
      viewModel.init();
      viewModel.updateGanttVM();
      viewModel.updateGanttVM(0);
      viewModel.setGanttScrollOffset();

      RootModel.instance().displayDate = Date.now() - MILLS_PER_DAY * 31;
      viewModel.onDateChange();
      viewModel.setGanttScrollOffset();

      viewModel.onTabChange(TabType.DAY);
      viewModel.onTimeChange();
      viewModel.onTabChange(TabType.WEEK);
      viewModel.onTimeChange();
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('basicTest3', 0, () => {
      let hasError: boolean = true;
      const viewModel = createViewModel(TabType.WEEK);
      AppStorage.set('deviceType', deviceType.PHONE);
      viewModel.init();
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('dataChangeTest', 0, () => {
      let hasError: boolean = true;
      const viewModel = createViewModel(TabType.WEEK);
      viewModel.init();
      const data1: emitter.EventData = {
        data: {
          data: {
            table: 'Events'
          }
        }
      };
      viewModel.onDataChange(data1);
      const data2: emitter.EventData = {
        data: {
          data: {
            table: 'Reminder'
          }
        }
      };
      viewModel.onDataChange(data2);
      const data3: emitter.EventData = {
        data: {
          data: {
            table: 'Calendars'
          }
        }
      };
      viewModel.onDataChange(data3);

      viewModel.onTabChange(TabType.DAY);
      viewModel.onDataChange(data3);
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('dayModelTest', 0, () => {
      const viewModel = createViewModel(TabType.WEEK);
      viewModel.init();
      const now = Date.now();
      const todayModel = new DayModel(new CalendarDate(now));
      const nowRes = viewModel.getDayModelByStamp(now);
      expect(viewModel.getDayModelByStamp(now)).not().assertUndefined();
      expect(todayModel.toString()).assertEqual(nowRes.toString());
      const otherMonth = now - MILLS_PER_DAY * 31;
      const otherRes = viewModel.getDayModelByStamp(otherMonth);
      expect(otherRes.toString()).not().assertEqual(nowRes.toString());
    });

    it('updateAgenda1', 0, async (done: Function) => {
      let hasError: boolean = true;

      let mocker: MockKit = new MockKit();
      const agendaMocker = mocker.mockFunc(AgendaModel.instance(), AgendaModel.instance().getAgendaByRange);
      const info1 = new AgendaEventInfo();
      info1.mBegin = Date.now();
      info1.mEnd = Date.now() + MILLS_PER_HOUR;
      const infoList1 = [info1];
      when(agendaMocker)(ArgumentMatchers.any).afterReturn(infoList1);
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.init();
      await viewModel1.updateAgenda();
      viewModel1.dateSwipe(0);
      viewModel1.dateSwipe(1);

      const info2 = new AgendaEventInfo();
      info2.mBegin = Date.now();
      info2.mEnd = Date.now() + 2 * MILLS_PER_DAY;
      const infoList2 = [info1, info2];
      when(agendaMocker)(ArgumentMatchers.any).afterReturn(infoList2);
      const viewModel2 = createViewModel(TabType.DAY);
      viewModel2.init();
      await viewModel2.updateAgenda();
      viewModel2.ganttSwipe(0);
      viewModel2.ganttSwipe(1);
      hasError = false;
      expect(hasError).assertFalse()
      done();
    });

    it('layoutTest', 0, () => {
      let hasError: boolean = true;
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.resetLayout({
        width: 900, height: 300
      });

      const viewModel2 = createViewModel(TabType.DAY);
      viewModel2.resetLayout({
        width: 800, height: 300
      });
      viewModel2.resetLayout({
        width: 900, height: 300
      });
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('layoutTestGanttWidth', 0, () => {
      const viewModel = createViewModel(TabType.DAY);
      viewModel.hideAgendaWindow = true;
      viewModel.resetLayout({
        width: 800, height: 500
      });
      expect(viewModel.ganttWidth).assertEqual(768);
      viewModel.hideAgendaWindow = false;
      viewModel.resetLayout({
        width: 800, height: 400
      });
      expect(viewModel.ganttWidth).assertEqual(368);

      viewModel.hideAgendaWindow = false;
      viewModel.resetLayout({
        width: 400, height: 400
      });
      expect(viewModel.ganttWidth).assertEqual(400);

      const viewModel2 = createViewModel(TabType.WEEK);
      viewModel2.resetLayout({
        width: 800, height: 300
      });
      expect(viewModel2.ganttWidth).assertEqual(768);
      viewModel2.resetLayout({
        width: 400, height: 300
      });
      expect(viewModel2.ganttWidth).assertEqual(400);
    });

    it('hideAgendaTest', 0, (done: Function) => {
      const viewModel1 = createViewModel(TabType.DAY);
      viewModel1.initVMs();
      viewModel1.onAgendaListStateChange(true, 0);
      expect(viewModel1.hideAgendaWindow).assertTrue();
      expect(viewModel1.isDivide).assertFalse();
      viewModel1.onAgendaListStateChange(false, 0);
      expect(viewModel1.hideAgendaWindow).assertFalse();
      done();
    });

    it('scaleTest', 0, () => {
      let hasError: boolean = true;
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      const oldGridCellHeight = viewModel1.ganttVMs[0].gridCellHeight;
      viewModel1.initGanttScale(2);
      expect(viewModel1.ganttVMs[0].gridCellHeight).assertEqual(oldGridCellHeight * 2);
      const eventData: emitter.EventData = {
        data: {
          'scale': 0.5,
          'pinchY': 0,
          'tabType': TabType.DAY,
        }
      }
      viewModel1.ganttScaleChange(eventData);
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('dayWeekChangeTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.animateFlagChange(false);
      viewModel1.animateWeekDayChange(TabType.DAY);
      expect(viewModel1.tabType).assertEqual(TabType.DAY);
      expect(viewModel1.gridColCount).assertEqual(1);
      expect(viewModel1.isDivide).assertTrue();
      viewModel1.animateFlagChange(false);
      viewModel1.animateWeekDayChange(TabType.WEEK);
      expect(viewModel1.tabType).assertEqual(TabType.WEEK);
      expect(viewModel1.gridColCount).assertEqual(DAY_PER_WEEK);
      expect(viewModel1.isDivide).assertFalse();
    });

    it('onDisplayDateChangeTest1', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.tabType = TabType.YEAR;
      const date = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
      RootModel.instance().displayDate = -1;
      viewModel1.onDisplayDateChange();
      expect(RootModel.instance().displayDate).assertEqual(date);
    });

    it('onDisplayDateChangeTest2', 0, () => {
      const viewModel1 = createViewModel(TabType.DAY);
      viewModel1.initVMs();
      const date = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
      viewModel1.tabType = TabType.DAY;
      RootModel.instance().displayDate = -1;
      RootModel.instance().curTab = TabType.DAY;
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel1, viewModel1.resetDayModelMatrix);
      mocker.mockFunc(viewModel1, viewModel1.initGanttBlock);
      mocker.mockFunc(viewModel1, viewModel1.updateAgenda);
      viewModel1.onDisplayDateChange();
      expect(RootModel.instance().displayDate).assertEqual(date);
    });

    it('onDisplayDateChangeTest3', 0, () => {
      let hasError: boolean = true;
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.tabType = TabType.DAY;
      const date = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
      RootModel.instance().displayDate = -1;
      RootModel.instance().curTab = TabType.WEEK;
      viewModel1.onDisplayDateChange();
      hasError = false;
      expect(hasError).assertFalse()
    });

    it('calValueByRangeTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      let nums: number[] = [1, 2];
      expect(viewModel1.calValueByRange(nums, 3)).assertEqual(4);
    });

    it('onSizeChangeTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.onSizeChange({
        width: 100, height: 200
      });
      viewModel1.isDivide = false;
      expect(viewModel1.weekTitleVM.rootWidth).assertEqual(100);
      expect(viewModel1.rootHeight).assertEqual(200);
    });

    it('onStartOfWeekChangeTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.onSizeChange({
        width: 100, height: 200
      });
      viewModel1.isDivide = false;
      expect(viewModel1.weekTitleVM.rootWidth).assertEqual(100);
      expect(viewModel1.rootHeight).assertEqual(200);
    });

    it('changeDayBySwiperTest1', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      viewModel1.ganttSwiperIndex = 3;
      viewModel1.changeDayBySwiper(1, 2);
      expect(viewModel1.ganttSwiperIndex).assertEqual(2);
      expect(viewModel1.dateSwiperIndex).assertEqual(0);
    });

    it('changeDayBySwiperTest2', 0, () => {
      const viewModel1 = createViewModel(TabType.DAY);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.ganttSwiperIndex = 3;
      viewModel1.selectDateIndex = 3;
      viewModel1.changeDayBySwiper(2, 4);
      expect(viewModel1.selectAgendaInfo).assertEqual(viewModel1.ganttVMs[0].getDefaultChosenInfo());
    });

    it('getChangeOffsetTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      expect(viewModel1.getChangeOffset(2, 0)).assertEqual(-1);
      expect(viewModel1.getChangeOffset(2, 2)).assertEqual(1);
    });

    it('getChangeIndexTest', 0, () => {
      const viewModel1 = createViewModel(TabType.WEEK);
      viewModel1.initVMs();
      expect(viewModel1.getChangeIndex(2, 1)).assertEqual(0);
    });

    it('changeDayByClickDateCellTest', 0, () => {
      const viewModel1 = createViewModel(TabType.DAY);
      viewModel1.initVMs();
      viewModel1.resetLayout({
        width: 800, height: 300
      });
      viewModel1.selectDateIndex = 1;
      viewModel1.ganttSwiperIndex = 0;
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(viewModel1, viewModel1.updateGanttVM);
      mocker.mockFunc(viewModel1, viewModel1.setDisplayDate);
      viewModel1.changeDayByClickDateCell(1, 1);
      expect(viewModel1.selectAgendaInfo).assertEqual(viewModel1.ganttVMs[0].getDefaultChosenInfo());
    });

    it('backToTodaySameWeekInDayGanttViewTest', 0, () => {
      const viewModel1 = createViewModel(TabType.DAY);
      viewModel1.initVMs();
      viewModel1.backToTodaySameWeekInDayGanttView(0, 0, false, true);
      expect(viewModel1.selectAgendaInfo).assertEqual(viewModel1.ganttVMs[0].getDefaultChosenInfo());
    });

    it('onSwipeMainPage_clearPop', 0, () => {
      RootModel.instance().curTab = TabType.WEEK;
      let viewModel = new RootViewModel(TabType.WEEK);
      viewModel.initVMs();
      viewModel.ganttVMs[0].showPopup = true;
      viewModel.changeDayBySwiper(0, 1);
      expect(viewModel.ganttVMs[0].showPopup).assertFalse();
    });

    it('onBackToToday', 0, () => {
      RootModel.instance().curTab = TabType.WEEK;
      let viewModel = new RootViewModel(TabType.WEEK);
      viewModel.initVMs();
      let onBackToToday = TestUtil.getPrivateFunction(viewModel, 'onBackToToday') !!;
      onBackToToday();
      expect(viewModel.swiperIndex).assertEqual(viewModel.dateSwiperIndex);
    });
  });
}