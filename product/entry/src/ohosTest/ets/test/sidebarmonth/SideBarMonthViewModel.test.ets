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
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { Driver, ON, MatchPattern } from '@ohos.UiTest';
import { CalendarDate, DateManager, DayData, Log } from '@app/common';
import { TestUtil } from '../utils/TestUtil';
import { SideBarMonthViewModel } from '@app/feature.sidebar/src/main/ets/monthview/model/SideBarMonthViewModel';
import { SingleMonthViewModel } from '@app/feature.sidebar/src/main/ets/monthview/model/SingleMonthViewModel';
import { WeekTitleViewModel } from '@app/feature.sidebar/src/main/ets/monthview/model/WeekTitleViewModel';

const TAG = 'SideBarMonthViewModelTest.test';
let viewModel: SideBarMonthViewModel;
const curDate: Date = new Date(2023, 1, 14);
let index: number = 1;


export default function SideBarMonthViewModelTest() {
  describe('SideBarMonthViewModelTest', () => {
    beforeAll(async (done: Function) => {
      viewModel = new SideBarMonthViewModel(new CalendarDate(curDate));
      done();
    })

    beforeEach(async (done: Function) => {
      let newSelectDay = DayData.buildByDate(new CalendarDate(curDate));
      DateManager.getInstance().selectedDay = newSelectDay;
      index = viewModel.updateBySelectedDate();
      done();
    })


    it('SideBarMonthViewModelTest_001', 0, async (done: Function) => {
      expect(viewModel.singleMonthVMs.length).assertEqual(3);
      expect(viewModel.singleMonthVMs[0].month).assertEqual(1);
      expect(viewModel.singleMonthVMs[1].month).assertEqual(2);
      expect(viewModel.singleMonthVMs[2].month).assertEqual(3);
      let newSelectDay = DayData.buildByDate(new CalendarDate(2023, 0, 14));
      DateManager.getInstance().selectedDay = newSelectDay;
      index = viewModel.updateBySelectedDate();
      expect(index).assertEqual(0);
      done();
    })


    it('SideBarMonthViewModelTest_002', 0, async (done: Function) => {
      viewModel.updateBySwipe(index, 0);
      expect(viewModel.singleMonthVMs[0].month).assertEqual(1);
      expect(viewModel.singleMonthVMs[1].month).assertEqual(2);
      expect(viewModel.singleMonthVMs[2].month).assertEqual(12);
      done();
    })

    it('SideBarMonthViewModelTest_004', 0, async (done: Function) => {
      WeekTitleViewModel.getInstance().startOfWeek = 0;
      AppStorage.set<number>(`startOfWeek`, 0);
      const monthViewModel = new SingleMonthViewModel(2025,4); // 迷你月视图宽高272,186
      let displayMills = monthViewModel.getClickDisplayMills(0,0);
      expect(displayMills).assertEqual(-1);
      displayMills = monthViewModel.getClickDisplayMills(0,45);
      expect(displayMills).assertEqual(new CalendarDate(2025, 2, 30, 0, 0, 0, 0).getTime());
      displayMills = monthViewModel.getClickDisplayMills(82,47);
      expect(displayMills).assertEqual(new CalendarDate(2025, 3, 1, 0, 0, 0, 0).getTime());
      displayMills = monthViewModel.getClickDisplayMills(82,90);
      expect(displayMills).assertEqual(new CalendarDate(2025, 3, 8, 0, 0, 0, 0).getTime());
      displayMills = monthViewModel.getClickDisplayMills(260,185);
      expect(displayMills).assertEqual(new CalendarDate(2025, 4, 3, 0, 0, 0, 0).getTime());
      done();
    })
  })
}