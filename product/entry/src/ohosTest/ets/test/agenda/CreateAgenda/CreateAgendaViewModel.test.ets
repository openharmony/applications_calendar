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

import { beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CreateAgendaViewModel } from '@app/feature.agenda/src/main/ets/CreateAgenda/viewmodel/CreateAgendaViewModel';
import { SaveTimeType } from '@app/feature.agenda';
import { CalendarDate, MILLS_PER_MINUTE } from '@app/common';


export default function CreateAgendaViewModelTest() {
  describe('CreateAgendaViewModelTest', () => {
    let viewModel: CreateAgendaViewModel;

    beforeEach(() => {
      viewModel = new CreateAgendaViewModel();
    })


    it('getStartDateByCombine_SAVE_START_TIME_1', 0, () => {
      const curDate = new CalendarDate('2024-04-28 17:42');
      const result = viewModel.getStartDateByCombine(curDate.getTime(), SaveTimeType.SAVE_START_TIME);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getHours()).assertEqual(curDate.getHours());
      // 42 - 30 = 12  12 % 30 = 12 > 1 下一个整点或半点即 30
      expect(resultDate.getMinutes()).assertEqual(30);
    });

    it('getStartDateByCombine_SAVE_START_TIME_2', 0, () => {
      const curDate = new CalendarDate('2024-04-28 17:22');
      const result = viewModel.getStartDateByCombine(curDate.getTime(), SaveTimeType.SAVE_START_TIME);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getHours()).assertEqual(curDate.getHours());
      // 22 - 30 = (60) - 8 = 52  52 % 30 = 22 下一个整点或半点即 52 -> 0
      expect(resultDate.getMinutes()).assertEqual(0);
    });

    it('getStartDateByCombine_SAVE_START_TIME_3', 0, () => {
      const curDate = new CalendarDate('2024-04-28 00:42');
      const result = viewModel.getStartDateByCombine(curDate.getTime(), SaveTimeType.SAVE_START_TIME);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getHours()).assertEqual(curDate.getHours());
      // 42 - 30 = 12  12 % 30 = 12 下一个整点或半点即 12 -> 30
      expect(resultDate.getMinutes()).assertEqual(30);
    });

    it('getStartDateByCombine_SAVE_START_TIME_4', 0, () => {
      const curDate = new CalendarDate('2024-04-28 23:42');
      const result = viewModel.getStartDateByCombine(curDate.getTime(), SaveTimeType.SAVE_START_TIME);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getHours()).assertEqual(curDate.getHours());
      // 42 - 30 = 12  12 % 30 = 12 下一个整点或半点即 12 -> 30
      expect(resultDate.getMinutes()).assertEqual(30);
    });

    it('Get_Start_Date_Default_Over_30min', 0, () => {
      const inputDate = new CalendarDate('2025-12-28 17:42');
      const curDate = new CalendarDate();
      const result = viewModel.getStartDateByCombine(inputDate.getTime(), SaveTimeType.DEFAULT);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getFullYear()).assertEqual(inputDate.getFullYear());
      // 2025-12-28 + 当前时分
      expect(resultDate.getMonth()).assertEqual(inputDate.getMonth());
      const isNeedFloor: boolean = curDate.getHours() < 23;
      expect(resultDate.getHours()).assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? curDate.getHours() + 1 : curDate.getHours());
      expect(resultDate.getMinutes()).assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? 0 : 30);
    });

    it('Get_Start_Date_Default_Less_30min', 0, () => {
      const inputDate = new CalendarDate('2025-12-28 17:22');
      const curDate = new CalendarDate();
      const result = viewModel.getStartDateByCombine(inputDate.getTime(), SaveTimeType.DEFAULT);
      const resultDate = new CalendarDate(result);
      expect(resultDate.getFullYear()).assertEqual(inputDate.getFullYear());
      expect(resultDate.getMonth()).assertEqual(inputDate.getMonth());
      const isNeedFloor: boolean = curDate.getHours() < 23;
      expect(resultDate.getHours())
        .assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? curDate.getHours() + 1 : curDate.getHours());
      expect(resultDate.getMinutes()).assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? 0 : 30);
    });

    it('Get_Start_Date_Off_3', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 00:42').getTime();
      const result = viewModel.getStartDateByCombine(inputTime, SaveTimeType.DEFAULT);
      const curDate = new CalendarDate();
      const resultDate = new CalendarDate(result);
      expect(resultDate.getFullYear()).assertEqual(curDate.getFullYear());
      expect(resultDate.getMonth()).assertEqual(11);
      const isNeedFloor: boolean = curDate.getHours() < 23;
      expect(resultDate.getHours())
        .assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? curDate.getHours() + 1 : curDate.getHours());
      expect(resultDate.getMinutes()).assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? 0 : 30);
    });

    it('Get_Start_Date_Off_4', 0, () => {
      const inputTime = new CalendarDate('2025-12-28 23:42');
      const result = viewModel.getStartDateByCombine(inputTime.getTime(), SaveTimeType.DEFAULT);
      const curDate = new CalendarDate();
      const resultDate = new CalendarDate(result);
      expect(resultDate.getFullYear()).assertEqual(inputTime.getFullYear());
      expect(resultDate.getMonth()).assertEqual(inputTime.getMonth());
      const isNeedFloor: boolean = curDate.getHours() < 23;
      expect(resultDate.getHours())
        .assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? curDate.getHours() + 1 : curDate.getHours());
      expect(resultDate.getMinutes()).assertEqual(curDate.getMinutes() > 30 && isNeedFloor ? 0 : 30);
    });

  });
}