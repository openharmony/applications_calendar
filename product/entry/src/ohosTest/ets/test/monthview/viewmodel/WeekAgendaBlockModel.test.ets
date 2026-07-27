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
import { WeekAgendaBlockModel, AgendaBlockInfo } from '@app/feature.monthview/src/main/ets/viewmodel/WeekAgendaBlockModel';
import { SingleWeekViewModel } from '@app/feature.monthview/src/main/ets/viewmodel/SingleWeekViewModel';
import { AgendaEventInfo, CalendarContract, CalendarDate, DateManager, DayData, MILLS_PER_DAY } from '@app/common';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { TestUtil } from '../../utils/TestUtil';
import { MonthlyViewState, MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';

const TAG = 'SingleWeekDataModel';

export default function WeekAgendaBlockModelTest() {
  describe('WeekAgendaBlockModelTest', () => {
    let model: WeekAgendaBlockModel;
    beforeAll(() => {
      const dateInfo = new DateInfo(2023, 1, 1, 1);
      const datArr: DayData[] = [];
      for (let i = 0; i < 7; i++) {
        datArr.push(new DayData(2023, 1, i + 1));
      }
      let viewModel = new SingleWeekViewModel(0, datArr, dateInfo);
      model = new WeekAgendaBlockModel(viewModel, 0);
    })

    it('SingleWeekDataModel_001', 0, (done: Function) => {
      const newBlocks: AgendaBlockInfo[] = [];
      const agenda1 = new AgendaEventInfo();
      model.onWeekAgendaRowsChange(2);

      model.constructBlock(newBlocks, agenda1, [0, 1], 0);
      model.onBlocksChange(newBlocks);
      expect(model.blocks.length).assertEqual(1);
      const agenda2 = new AgendaEventInfo();
      model.constructBlock(newBlocks, agenda2, [0, 4], 1);
      model.onBlocksChange(newBlocks);
      expect(model.blocks.length).assertEqual(2);

      done()
    })

    it('SingleWeekDataModel_002', 0, (done: Function) => {
      let dayDataArr: DayData[] = [];
      const dateInfo = new DateInfo(2020, 10, 40, 1);
      for (let index = 0; index < 7; ++index) {
        const dayData = DateManager.getInstance().getDayData(2020, 10, 1 + index);
        dayDataArr.push(dayData ?? new DayData(2020, 10, 1 + index));
      }
      MonthlyViewStateManager.getInstance().dayState.showCalendar = true;
      MonthlyViewStateManager.getInstance().state.systemRegion = 'CN';
      let viewModel = new SingleWeekViewModel(0, dayDataArr, dateInfo);
      model = new WeekAgendaBlockModel(viewModel, 0);
      model.onWeekAgendaRowsChange(4);
      const agenda1 = new AgendaEventInfo();
      agenda1.mId = 1;
      agenda1.mTitle = '国庆节';
      agenda1.mImportantEventType =  CalendarContract.EventImportantType.HOLIDAY;
      const agenda2 = new AgendaEventInfo();
      agenda2.mId = 2;
      agenda2.mTitle = '不是节日';
      agenda2.mBegin = new DayData(2020, 10, 1).getDate().getTime();
      agenda2.mEnd = new DayData(2020, 10, 1).getDate().getTime() + MILLS_PER_DAY - 1;
      model.onSigWeekAgendaChange([agenda1, agenda2]);
      const holidayAgenda: string[] = TestUtil.getPrivateAttribute(model, 'sigWeekHoliday');
      expect(holidayAgenda.length).assertEqual(1);
      expect(model.blocks.length).assertEqual(3);
      const agenda3 = new AgendaEventInfo();
      agenda3.mId = 3;
      agenda3.mTitle = '国庆节';
      agenda3.mBegin = new DayData(2020, 10, 1).getDate().getTime();
      agenda3.mEnd = new DayData(2020, 10, 1).getDate().getTime() + MILLS_PER_DAY - 1;
      model.onSigWeekAgendaChange([agenda3, agenda2]);
      const holidayAgenda2: string[] = TestUtil.getPrivateAttribute(model, 'sigWeekHoliday');
      expect(holidayAgenda2.length).assertEqual(0);
      expect(model.blocks.length).assertEqual(4);
      done();
    })

    it('SingleWeekDataModel_003', 0, (done: Function) => {
      let dayDataArr: DayData[] = [];
      const dateInfo = new DateInfo(2024, 4, 15, 7);
      for (let index = 0; index < 7; ++index) {
        const dayData = DateManager.getInstance().getDayData(2024, 4, 7 + index);
        dayDataArr.push(dayData ?? new DayData(2024, 4, 7 + index));
      }
      MonthlyViewStateManager.getInstance().dayState.showCalendar = true;
      MonthlyViewStateManager.getInstance().state.systemRegion = 'CN';
      let viewModel = new SingleWeekViewModel(0, dayDataArr, dateInfo);
      model = new WeekAgendaBlockModel(viewModel, 0);
      const agenda1 = new AgendaEventInfo();
      agenda1.mId = 1000;
      agenda1.mBegin = new CalendarDate(2024, 3, 7, 8, 0, 0, 0).getTime();
      agenda1.mEnd = new CalendarDate(2024, 3, 7, 9, 0, 0, 0).getTime();
      agenda1.mTitle = '1';
      const agenda2 = new AgendaEventInfo();
      agenda2.mId = 1001;
      agenda2.mBegin = new CalendarDate(2024, 3, 7, 9, 0, 0, 0).getTime();
      agenda2.mEnd = new CalendarDate(2024, 3, 7, 10, 0, 0, 0).getTime();
      agenda2.mTitle = '2';
      const agenda3 = new AgendaEventInfo();
      agenda3.mId = 1002;
      agenda3.mBegin = new CalendarDate(2024, 3, 7, 8, 0, 0, 0).getTime();
      agenda3.mEnd = new CalendarDate(2024, 3, 7, 12, 0, 0, 0).getTime();
      agenda3.mTitle = '3';
      agenda3.eventTimeZone = 'Asia/Shanghai';
      agenda3.mIsAllDay = true;
      model.onWeekAgendaRowsChange(2);

      model.onSigWeekAgendaChange([agenda1, agenda2, agenda3]);

      expect(model.blocks.length).assertEqual(2);
      expect(model.blocks[1]?.titleString).assertEqual('+2');
      expect(model.blocks[1]?.blockAgendas.length).assertEqual(2);

      done();
    })

    it('SingleWeekDataModel_004', 0, (done: Function) => {
      let hasError: boolean = true;
      let dayDataArr: DayData[] = [];
      const dateInfo = new DateInfo(2024, 4, 15, 7);
      for (let index = 0; index < 7; ++index) {
        const dayData = DateManager.getInstance().getDayData(2024, 4, 7 + index);
        dayDataArr.push(dayData ?? new DayData(2024, 4, 7 + index));
      }
      MonthlyViewStateManager.getInstance().dayState.showCalendar = true;
      MonthlyViewStateManager.getInstance().state.systemRegion = 'CN';
      let viewModel = new SingleWeekViewModel(0, dayDataArr, dateInfo);
      model = new WeekAgendaBlockModel(viewModel, 0);
      const agenda1 = new AgendaEventInfo();
      agenda1.mId = 1000;
      agenda1.mBegin = new CalendarDate(2024, 3, 7, 8, 0, 0, 0).getTime();
      agenda1.mEnd = new CalendarDate(2024, 3, 7, 9, 0, 0, 0).getTime();
      agenda1.mTitle = '1';
      let newBlocks: AgendaBlockInfo[] = [];
      model.processAbbreviation(newBlocks , agenda1, [0, 6]);
      hasError = false;
      expect(hasError).assertFalse();
      done();
    })

    it('SingleWeekDataModel_005', 0, (done: Function) => {
      let hasError: boolean = true;
      let dayDataArr: DayData[] = [];
      const dateInfo = new DateInfo(2024, 4, 15, 7);
      for (let index = 0; index < 7; ++index) {
        const dayData = DateManager.getInstance().getDayData(2024, 4, 7 + index);
        dayDataArr.push(dayData ?? new DayData(2024, 4, 7 + index));
      }
      let viewModel = new SingleWeekViewModel(0, dayDataArr, dateInfo);
      model = new WeekAgendaBlockModel(viewModel, 0);
      model.onWeekAgendaRowsChange(0);
      model.buildSingleBlock([], new AgendaEventInfo());
      hasError = false;
      expect(hasError).assertFalse();
      done();
    })

    it('SingleWeekDataModel_006', 0, (done: Function) => {
      const newBlocks: AgendaBlockInfo[] = [];
      const agenda1 = new AgendaEventInfo();
      model.onWeekAgendaRowsChange(2);

      model.constructBlock(newBlocks, agenda1, [0, 1], 0);
      model.onBlocksChange(newBlocks);
      expect(model.blocks.length).assertEqual(1);
      const block = model.blocks[0];
      block.clearPreview();
      expect(block.blockPop).assertFalse();
      expect(block.hoverPop).assertFalse();
      block.blockPop = true;
      block.hoverPop = true;
      block.clearPreview();
      expect(block.blockPop).assertFalse();
      expect(block.hoverPop).assertFalse();
      done()
    })
  })
}