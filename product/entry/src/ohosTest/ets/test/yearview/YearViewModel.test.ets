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
import {
  CalendarDate,
  DateManager,
  DayData,
  GlobalData,
  GlobalDataKeys,
} from '@app/common';
import { YearViewModel } from '@app/feature.yearview';
import { SingleYearViewModel, YearInfo } from '@app/feature.yearview/src/main/ets/viewmodel/SingleYearViewModel';

const curDate: Date = new Date(2024, 8, 10);


function getYearInfos(viewModel: YearViewModel): number[] {
  let result: number [] = [];
  const curData = viewModel.getData(viewModel.curIndex) as SingleYearViewModel;
  const previousYear = curData.getPrevious() as SingleYearViewModel;
  let info = previousYear?.info as YearInfo;
  result.push(info.year);
  info = curData?.info as YearInfo;
  result.push(info.year);
  const nextYear = curData.getNext() as SingleYearViewModel;
  info = nextYear?.info as YearInfo;
  result.push(info.year);
  return result;
}

export default function YearViewModelTest() {
  let viewModel: YearViewModel;
  describe('YearViewModelTest', () => {
    beforeEach(() => {
      viewModel = new YearViewModel(2024);
      viewModel.init();
    })

    it('initState', 0, () => {
      expect(viewModel.solarYear).assertEqual(2024);
      expect(viewModel.singleVMs.length).assertEqual(3);
      const years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    })

    it('onShowNextOnce', 0, () => {
      viewModel.onShowNext();
      //  2     0   [1]
      // 2026  2024  2025
      expect(viewModel.curIndex).assertEqual(1);
      const curData = viewModel.getData(viewModel.curIndex) as SingleYearViewModel;
      let info = curData?.info as YearInfo;
      expect(info.year).assertEqual(2025);
      const nextData = curData.getNext() as SingleYearViewModel;
      expect(nextData.index).assertEqual(2);
      info = nextData?.info as YearInfo;
      expect(info.year).assertEqual(2026);
    });

    it('onShowNextMultiTimes', 0, () => {
      //  2      0   [1]
      // 2026   2024  2025
      viewModel.onShowNext();
      //  [2]    0   1
      // 2026   2027  2025
      viewModel.onShowNext();
      expect(viewModel.curIndex).assertEqual(2);
      const curData = viewModel.getData(viewModel.curIndex) as SingleYearViewModel;
      let info = curData?.info as YearInfo;
      expect(info.year).assertEqual(2026);
      const nextData = curData.getNext() as SingleYearViewModel;
      info = nextData?.info as YearInfo;
      expect(info.year).assertEqual(2027);
    });

    it('onShowPrevious', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      viewModel.onShowPrevious();
      expect(viewModel.curIndex).assertEqual(2);
      const years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2022, 2023, 2024]);
    });

    it('onShowPreviousMultiTime', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      viewModel.onShowPrevious();
      //  2       0    [1]
      // 2023   2021  2022
      viewModel.onShowPrevious();
      expect(viewModel.curIndex).assertEqual(1);
      const years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2021, 2022, 2023]);
    });

    it('onShowMix', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      viewModel.onShowPrevious();
      //  2      [0]   [1]
      // 2023   2024  2025
      viewModel.onShowNext();
      expect(viewModel.curIndex).assertEqual(0);
      const years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    });

    // PC 回到今天场景 在当前年视图, 预期不会
    it('onSelectedDayChange_001', 0, () => {
      const curDate: Date = new Date(2024, 8, 10);
      // 模拟年视图滑动
      viewModel.onShowPrevious();
      viewModel.onShowPrevious();
      viewModel.onShowPrevious();
      expect(viewModel.curIndex).assertEqual(0);
      let years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2020, 2021, 2022]);
      // 回到今天
      let newSelectDay = DayData.buildByDate(new CalendarDate(curDate));
      DateManager.getInstance().selectedDay = newSelectDay;
      viewModel.onSelectedDayChange(newSelectDay, true);

      years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    })

    it('onSelectedDayChange_002', 0, () => {
      // PC 回到今天场景 在当前年视图, 预期不会
      viewModel.onShowNext(); // last year
      viewModel.onShowNext();
      viewModel.onShowNext();
      expect(viewModel.curIndex).assertEqual(0);
      let newSelectDay = DayData.buildByDate(new CalendarDate(curDate));
      DateManager.getInstance().selectedDay = newSelectDay;
      viewModel.onSelectedDayChange(newSelectDay, true);
      const years = getYearInfos(viewModel);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    })

    it('onStartOfWeekChange', 0, () => {
      viewModel.onStartOfWeekChange(1);
      const year1 = viewModel.singleVMs[0] as SingleYearViewModel;
      const month1 = year1.monthViewModels[0];
      expect(month1.startOfWeek).assertEqual(1);
      viewModel.onStartOfWeekChange(1);
      expect(month1.startOfWeek).assertEqual(1);
    })

    it('onSubCalendarChange', 0, () => {
      viewModel.onSubCalendarChange(false);
      const year1 = viewModel.singleVMs[0] as SingleYearViewModel;
      const month1 = year1.monthViewModels[0];
      expect(month1.showLunarInfo).assertFalse();
      viewModel.onSubCalendarChange(true);
      expect(month1.showLunarInfo).assertTrue();
    })

    it('onWeekendsChange', 0, () => {
      viewModel.onWeekendsChange([1, 2]);
      const year1 = viewModel.singleVMs[0] as SingleYearViewModel;
      const month1 = year1.monthViewModels[0];
      expect(month1.weekends[0]).assertEqual(1);
      viewModel.onWeekendsChange([0, 6]);
      expect(month1.weekends[0]).assertEqual(0);
    })

    it('onLanguageChange', 0, () => {
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'zh-Hans-CN');
      viewModel.onLanguageChange('zh-Hans-CN');
      const year1 = viewModel.singleVMs[0] as SingleYearViewModel;
      const month1 = year1.monthViewModels[0];
      expect(month1.monthTitle).assertEqual('1月');
    })
  })
}