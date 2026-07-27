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

import { beforeAll, describe, expect, it } from '@ohos/hypium';
import { FormName } from '@app/feature.card/src/main/ets/utils/FormName';
import { CalendarDate, Log } from '@app/common';
import { MonthCardVM4x4 } from '@app/feature.card/src/main/ets/monthCard/viewModel/pages/MonthCardVM4x4';
import { CardSingleDayViewModel } from '@app/feature.card/src/main/ets/monthCard/viewModel/components/CardSingleDayViewModel';

const TAG = 'MonthCardVM4x4Test';
const curDate: Date = new Date(2024, 1, 14);

let viewModel: MonthCardVM4x4;
const curMonthVM: string = "[[[2024,9,29,0,0,0,1,1,\"廿七\",0,0,0,0,1],[2024,9,30,0,0,0,0,1,\"廿八\",0,0,0,0,1]," +
  "[2024,10,1,0,0,1,0,1,\"国庆节\",0,0,1,0,1],[2024,10,2,0,0,1,0,1,\"三十\",0,0,0,0,1]," +
  "[2024,10,3,0,0,1,0,1,\"九月\",0,1,0,0,1],[2024,10,4,0,0,1,0,1,\"初二\",0,0,0,0,1]," +
  "[2024,10,5,0,0,1,1,1,\"初三\",0,0,0,0,1],[2024,10,6,0,0,1,1,1,\"初四\",0,0,0,0,1]," +
  "[2024,10,7,0,0,1,0,1,\"初五\",0,0,0,0,1],[2024,10,8,0,0,1,0,1,\"寒露\",0,0,1,0,1]," +
  "[2024,10,9,0,0,1,0,1,\"初七\",0,0,0,0,1],[2024,10,10,0,0,1,0,1,\"初八\",0,0,0,0,1]," +
  "[2024,10,11,0,0,1,0,1,\"重阳节\",0,0,1,0,1],[2024,10,12,0,0,1,1,1,\"初十\",0,0,0,0,1]," +
  "[2024,10,13,0,0,1,1,1,\"十一\",0,0,0,0,1],[2024,10,14,0,0,1,0,1,\"十二\",0,0,0,0,1]," +
  "[2024,10,15,0,0,1,0,1,\"十三\",0,0,0,0,1],[2024,10,16,0,0,1,0,1,\"十四\",0,0,0,0,1]," +
  "[2024,10,17,0,0,1,0,1,\"十五\",0,0,0,0,1],[2024,10,18,0,0,1,0,1,\"十六\",0,0,0,0,1]," +
  "[2024,10,19,0,0,1,1,1,\"十七\",0,0,0,0,1],[2024,10,20,0,0,1,1,1,\"十八\",0,0,0,0,1]," +
  "[2024,10,21,0,0,1,0,1,\"十九\",0,0,0,0,1],[2024,10,22,0,0,1,0,1,\"二十\",0,0,0,0,1]," +
  "[2024,10,23,0,0,1,0,1,\"霜降\",0,0,1,0,1],[2024,10,24,0,0,1,0,1,\"廿二\",0,0,0,0,1]," +
  "[2024,10,25,0,0,1,0,1,\"廿三\",0,0,0,0,1],[2024,10,26,0,0,1,1,1,\"廿四\",0,0,0,0,1]," +
  "[2024,10,27,0,0,1,1,1,\"廿五\",0,0,0,0,1],[2024,10,28,0,0,1,0,1,\"廿六\",0,0,0,0,1]," +
  "[2024,10,29,0,0,1,0,1,\"廿七\",0,0,0,0,1],[2024,10,30,0,0,1,0,1,\"廿八\",0,0,0,0,1]," +
  "[2024,10,31,0,0,1,0,1,\"万圣夜\",0,0,1,0,1],[2024,11,1,0,0,0,0,1,\"十月\",0,1,0,0,1]," +
  "[2024,11,2,0,0,0,1,1,\"初二\",0,0,0,0,1]],[[2024,10,27,0,0,0,1,1,\"廿五\",0,0,0,0,1]," +
  "[2024,10,28,0,0,0,0,1,\"廿六\",0,0,0,0,1],[2024,10,29,0,0,0,0,1,\"廿七\",0,0,0,0,1]," +
  "[2024,10,30,0,0,0,0,1,\"廿八\",0,0,0,0,1],[2024,10,31,0,0,0,0,1,\"万圣夜\",0,0,1,0,1]," +
  "[2024,11,1,0,0,1,0,1,\"十月\",0,1,0,0,1],[2024,11,2,0,0,1,1,1,\"初二\",0,0,0,0,1]," +
  "[2024,11,3,1,0,1,1,1,\"初三\",0,0,0,0,1],[2024,11,4,0,0,1,0,1,\"初四\",0,0,0,0,1]," +
  "[2024,11,5,0,0,1,0,1,\"初五\",0,0,0,0,1],[2024,11,6,0,0,1,0,1,\"初六\",0,0,0,0,1]," +
  "[2024,11,7,0,0,1,0,1,\"立冬\",0,0,1,0,1],[2024,11,8,0,0,1,0,1,\"初八\",0,0,0,0,1]," +
  "[2024,11,9,0,0,1,1,1,\"初九\",0,0,0,0,1],[2024,11,10,0,0,1,1,1,\"初十\",0,0,0,0,1]," +
  "[2024,11,11,0,0,1,0,1,\"十一\",0,0,0,0,1],[2024,11,12,0,0,1,0,1,\"十二\",0,0,0,0,1]," +
  "[2024,11,13,0,0,1,0,1,\"十三\",0,0,0,0,1],[2024,11,14,0,0,1,0,1,\"十四\",0,0,0,0,1]," +
  "[2024,11,15,0,0,1,0,1,\"十五\",0,0,0,0,1],[2024,11,16,0,0,1,1,1,\"十六\",0,0,0,0,1]," +
  "[2024,11,17,0,0,1,1,1,\"十七\",0,0,0,0,1],[2024,11,18,0,0,1,0,1,\"十八\",0,0,0,0,1]," +
  "[2024,11,19,0,0,1,0,1,\"十九\",0,0,0,0,1],[2024,11,20,0,0,1,0,1,\"二十\",0,0,0,0,1]," +
  "[2024,11,21,0,0,1,0,1,\"廿一\",0,0,0,0,1],[2024,11,22,0,0,1,0,1,\"小雪\",0,0,1,0,1]," +
  "[2024,11,23,0,0,1,1,1,\"廿三\",0,0,0,0,1],[2024,11,24,0,0,1,1,1,\"廿四\",0,0,0,0,1]," +
  "[2024,11,25,0,0,1,0,1,\"廿五\",0,0,0,0,1],[2024,11,26,0,0,1,0,1,\"廿六\",0,0,0,0,1]," +
  "[2024,11,27,0,0,1,0,1,\"廿七\",0,0,0,0,1],[2024,11,28,0,0,1,0,1,\"感恩节\",0,0,1,0,1]," +
  "[2024,11,29,0,0,1,0,1,\"廿九\",0,0,0,0,1],[2024,11,30,0,0,1,1,1,\"三十\",0,0,0,0,1]]," +
  "[[2024,12,1,0,0,1,1,1,\"冬月\",0,1,0,0,1],[2024,12,2,0,0,1,0,1,\"初二\",0,0,0,0,1]," +
  "[2024,12,3,0,0,1,0,1,\"初三\",0,0,0,0,1],[2024,12,4,0,0,1,0,1,\"初四\",0,0,0,0,1]," +
  "[2024,12,5,0,0,1,0,1,\"初五\",0,0,0,0,1],[2024,12,6,0,0,1,0,1,\"大雪\",0,0,1,0,1]," +
  "[2024,12,7,0,0,1,1,1,\"初七\",0,0,0,0,1],[2024,12,8,0,0,1,1,1,\"初八\",0,0,0,0,1]," +
  "[2024,12,9,0,0,1,0,1,\"初九\",0,0,0,0,1],[2024,12,10,0,0,1,0,1,\"初十\",0,0,0,0,1]," +
  "[2024,12,11,0,0,1,0,1,\"十一\",0,0,0,0,1],[2024,12,12,0,0,1,0,1,\"十二\",0,0,0,0,1]," +
  "[2024,12,13,0,0,1,0,1,\"国家公...\",0,0,1,0,1],[2024,12,14,0,0,1,1,1,\"十四\",0,0,0,0,1]," +
  "[2024,12,15,0,0,1,1,1,\"十五\",0,0,0,0,1],[2024,12,16,0,0,1,0,1,\"十六\",0,0,0,0,1]," +
  "[2024,12,17,0,0,1,0,1,\"十七\",0,0,0,0,1],[2024,12,18,0,0,1,0,1,\"十八\",0,0,0,0,1]," +
  "[2024,12,19,0,0,1,0,1,\"十九\",0,0,0,0,1],[2024,12,20,0,0,1,0,1,\"二十\",0,0,0,0,1]," +
  "[2024,12,21,0,0,1,1,1,\"冬至\",0,0,1,0,1],[2024,12,22,0,0,1,1,1,\"廿二\",0,0,0,0,1]," +
  "[2024,12,23,0,0,1,0,1,\"廿三\",0,0,0,0,1],[2024,12,24,0,0,1,0,1,\"平安夜\",0,0,1,0,1]," +
  "[2024,12,25,0,0,1,0,1,\"圣诞节\",0,0,1,0,1],[2024,12,26,0,0,1,0,1,\"廿六\",0,0,0,0,1]," +
  "[2024,12,27,0,0,1,0,1,\"廿七\",0,0,0,0,1],[2024,12,28,0,0,1,1,1,\"廿八\",0,0,0,0,1]," +
  "[2024,12,29,0,0,1,1,1,\"廿九\",0,0,0,0,1],[2024,12,30,0,0,1,0,1,\"二九\",0,0,1,0,1]," +
  "[2024,12,31,0,0,1,0,1,\"腊月\",0,1,0,0,1],[2025,1,1,0,0,0,0,1,\"元旦\",0,0,1,0,1]," +
  "[2025,1,2,0,0,0,0,1,\"初三\",0,0,0,0,1],[2025,1,3,0,0,0,0,1,\"初四\",0,0,0,0,1]," +
  "[2025,1,4,0,0,0,1,1,\"初五\",0,0,0,0,1]]]"


function init() {
  Log.info(TAG, `MonthlyViewModelTest beforeAll`);
  viewModel = new MonthCardVM4x4(FormName.MONTH_CARD_4X4);
  expect(viewModel.getFormName()).assertEqual(FormName.MONTH_CARD_4X4);
}

export default function MonthCardVM4x4Test() {
  beforeAll(async (done: Function) => {
    init();
    done();
  })
  describe('MonthCardVM4x4Test', () => {
    // 新建一个VM
    it('TestNormalBuilder_4x4', 0, () => {
      expect(viewModel.getFormName()).assertEqual(FormName.MONTH_CARD_4X4);
    })

    // 使用 onDisplayDateChange 接口
    it('Test_onDisplayDateChange', 0, () => {
      viewModel.onDisplayDateChange(new CalendarDate(curDate));
      expect(viewModel.displayDate.toString()).assertEqual(new CalendarDate(curDate).toString());
    })

    // 使用 onIsButtonBannedChange 接口
    it('Test_onIsButtonBannedChange', 0, () => {
      viewModel.onDisplayDateChange(new CalendarDate(curDate));
      expect(viewModel.displayDate.toString()).assertEqual(new CalendarDate(curDate).toString());
    })


    // 使用 onCurMonthVM 接口 = 正常创建
    it('Test_onCurMonthVM_Build', 0, () => {
      viewModel = new MonthCardVM4x4(FormName.MONTH_CARD_4X4);
      expect(viewModel.isDataProcessedFirstTime).assertEqual(false);
      viewModel.onMonthVMChange(curMonthVM);
      expect(viewModel.isDataProcessedFirstTime).assertEqual(true);
    })

    // 使用 onCurMonthVM 接口 = 异常分支处理
    it('Test_onCurMonthVM_Error', 0, () => {
      viewModel = new MonthCardVM4x4(FormName.MONTH_CARD_4X4);
      expect(viewModel.isDataProcessedFirstTime).assertEqual(false);
      const isFreshDone = viewModel.onMonthVMChange("");
      expect(viewModel.isDataProcessedFirstTime).assertEqual(false);
      expect(isFreshDone).assertEqual(false);
    })

    // 使用 onCurMonthVM 接口 = 正常解析
    it('Test_onCurMonthVM_Analysis', 0, () => {
      viewModel = new MonthCardVM4x4(FormName.MONTH_CARD_4X4);
      viewModel.onMonthVMChange(curMonthVM);
      const logDate_curMonth:CardSingleDayViewModel[] = viewModel.monthViewModel.cardSingleMonthVMArr[1];
      expect(logDate_curMonth.length).assertEqual(35);
      const logDate_0 = logDate_curMonth[7]
      expect(logDate_0.year).assertEqual(2024);
      expect(logDate_0.month).assertEqual(11);
      expect(logDate_0.day).assertEqual(3);
      expect(logDate_0.isToday).assertEqual(true);
      expect(logDate_0.isCurrentMonth).assertEqual(true);
      expect(logDate_0.isWeekends).assertEqual(true);
      expect(logDate_0.tagText).assertEqual("初三");
      const logDate_1 = logDate_curMonth[0]
      expect(logDate_1.year).assertEqual(2024);
      expect(logDate_1.month).assertEqual(10);
      expect(logDate_1.day).assertEqual(27);
      expect(logDate_1.isToday).assertEqual(false);
      expect(logDate_1.isCurrentMonth).assertEqual(false);
      expect(logDate_1.isWeekends).assertEqual(true);
      expect(logDate_1.tagText).assertEqual("廿五");
    })
  })
}