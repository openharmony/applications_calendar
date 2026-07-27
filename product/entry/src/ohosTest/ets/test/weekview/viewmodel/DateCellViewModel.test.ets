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
import { RootViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/RootViewModel';
import { DateCellViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/DateCellViewModel';
import { DayModel } from '@app/feature.weekview/src/main/ets/model/DayModel';
import { TestUtil } from '../../utils/TestUtil';
import { CalendarDate, CHINESE_HOLIDAY_STATE_VALUE, GlobalData, GlobalDataKeys } from '@app/common';

export default function DateCellViewModelTest() {
  describe('DateCellViewModelTest', () => {
    it('DateCellViewModelTest_001', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      const dayModel: DayModel = new DayModel(new CalendarDate(2024, 1, 14));
      dayModel.resetDate(new CalendarDate(2024, 1, 14));
      dayModel.updateShowFestivals(true, true, CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN);
      dateCellVm.updateDayModel(dayModel);
      expect(dateCellVm.solarDateStr).assertEqual('14');
      expect(dateCellVm.extraInfoStr).assertEqual('情人节');
      TestUtil.ExpectResourceColor(String(dateCellVm.solarDateColor), String($r('sys.color.ohos_id_color_text_primary')));
      TestUtil.ExpectResourceColor(String(dateCellVm.extraInfoColor), String($r('app.color.red_common')));
      dayModel.resetDate(new CalendarDate());
      dayModel.updateShowFestivals(true, true, CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN);
      dateCellVm.updateDayModel(dayModel);
      dateCellVm.setSelect(true);
      TestUtil.ExpectResourceColor(String(dateCellVm.solarDateColor), String($r('sys.color.ohos_id_color_background')));
      TestUtil.ExpectResourceColor(String(dateCellVm.extraInfoColor), String($r('sys.color.ohos_id_color_background')));
      done();
    });

    it('resetLayoutAdapt', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      dateCellVm.resetLayoutAdapt();
      expect(dateCellVm.agendaDotMarkAnchor.x).assertEqual(0);
      done();
    })

    it('resetLayoutPhone', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      let mock: MockKit = new MockKit();
      let isShowCalendar: Function = mock.mockFunc(rootVM, rootVM.isShowCalendar);
      when(isShowCalendar)(ArgumentMatchers.any).afterReturn(false);
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      dateCellVm.resetLayoutPhone();
      expect(dateCellVm.solarDateMarkAnchor.x).assertEqual('50%');
      done();
    })

    it('updateExtraInfo', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      let mock: MockKit = new MockKit();
      let isShowCalendar: Function = mock.mockFunc(rootVM, rootVM.isShowCalendar);
      when(isShowCalendar)(ArgumentMatchers.any).afterReturn(true);
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      dateCellVm.updateExtraInfo();
      expect(dateCellVm.extraInfoStr).assertEqual('初');
      done();
    })

    it('updateExtraInfo_isFirstDayOfMonth', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      const dayModel: DayModel = new DayModel(new CalendarDate(2024, 3, 9));
      dayModel.resetDate(new CalendarDate(2024, 3, 9));
      dayModel.updateShowFestivals(true, true, CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN);
      dateCellVm.updateDayModel(dayModel);
      dateCellVm.updateExtraInfo();
      expect(dateCellVm.showLunarMonthUnderline).assertEqual(true);
      expect(dateCellVm.extraInfoStr).assertEqual('三月');
      done();
    })

    it('updateExtraInfo_isFestivalFirstDayOfMonth', 0, async (done: Function) => {
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      const dayModel: DayModel = new DayModel(new CalendarDate(2024, 1, 10));
      dayModel.resetDate(new CalendarDate(2024, 1, 10));
      dayModel.updateShowFestivals(true, true, CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN);
      dateCellVm.updateDayModel(dayModel);
      dateCellVm.updateExtraInfo();
      expect(dateCellVm.showLunarMonthUnderline).assertEqual(true);
      expect(dateCellVm.extraInfoStr).assertEqual('春节');
      done();
    })

    it('getAccessibilityText', 0, async (done: Function) => {
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'zh-Hans');
      const rootVM: RootViewModel = new RootViewModel(0);
      rootVM.extraInfoRight = true;
      const dateCellVm: DateCellViewModel = new DateCellViewModel(0, rootVM);
      const dayModel: DayModel = new DayModel(new CalendarDate(2024, 3, 9));
      dateCellVm.updateDayModel(dayModel);
      dateCellVm.isSelect = true;
      expect(dateCellVm.getAccessibilityText()).assertEqual('2024年3月9日星期六农历正月廿九');
      done();
    })
  });
}