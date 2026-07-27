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

import { describe, expect, it, MockKit, when } from '@ohos/hypium';
import { getWeekOfDate } from '@app/feature.repeatrule/src/main/ets/utils/TimeUtil';
import { Weeks } from '@app/feature.repeatrule/src/main/ets/Constants';
import { CalendarDate } from '@app/common';

export default function TimeUtilTest() {
  describe('TimeUtilTest', () => {
    it('should_return_MON_when_date_is_MONDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(1);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.MON);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_TUE_when_date_is_TUESDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(2);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.TUE);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_WED_when_date_is_WEDNESDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(3);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.WED);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_THUR_when_date_is_THURSDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(4);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.THUR);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_FRI_when_date_is_FRIDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(5);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.FRI);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_SAT_when_date_is_SATURDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(6);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.SAT);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_SUN_when_date_is_SUNDAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(0);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.SUN);
      mocker.ignoreMock(date, date.getDay);
    });

    it('should_return_undefined_when_date_is_OTHER_DAY', 0, () => {
      let date: CalendarDate = new CalendarDate();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(date, date.getDay);
      when(mockfunc)().afterReturn(7);
      const result = getWeekOfDate(date);
      expect(result).assertEqual(Weeks.UNDEFINED);
      mocker.ignoreMock(date, date.getDay);
    });
  })
}