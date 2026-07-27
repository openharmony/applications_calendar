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

import { afterAll, beforeAll, describe, expect, it } from '@ohos/hypium'
import {
  CalendarDate,
  DateManager, DayData, LunarTermInfo, MonthInfo, SolarLunarInfo, YearLunarData } from '@app/common/index'

export default function DateManagerTest() {
  describe('DateManagerTest', () => {
    beforeAll(() => {
      DateManager.getInstance().init();
    })
    afterAll(() => {
      DateManager.getInstance().unInit();
    })

    it('buildMonthLunarData_01', 0, () => {
      let yearLunarInfo = new YearLunarData(2023);
      yearLunarInfo._solarLunarDays.push(new SolarLunarInfo(1, 1, 12, 10));
      yearLunarInfo._solarLunarDays.push(new SolarLunarInfo(1, 22, 1, 1));
      let monthInfo = new MonthInfo(2023, 1);
      DateManager.getInstance().buildMonthLunarData(monthInfo, yearLunarInfo._solarLunarDays);
      let afterDaysInfo = monthInfo.getDaysInfo()
      // 1.1
      let index = 0
      for (let day = 10; day <= 30; ++day) {
        expect(afterDaysInfo[index].lunaMonth).assertEqual(12);
        expect(afterDaysInfo[index].lunarDay).assertEqual(day);
        index += 1;
      }
      for (let day = 1; day < 10; ++day, ++index) {
        expect(afterDaysInfo[index].lunaMonth).assertEqual(1);
        expect(afterDaysInfo[index].lunarDay).assertEqual(day);
      }
    })

    it('buildMonthLunarData_02', 0, () => {
      let yearLunarInfo = new YearLunarData(2024);
      yearLunarInfo._solarLunarDays.push(new SolarLunarInfo(1, 1, 12, 10));
      yearLunarInfo._solarLunarDays.push(new SolarLunarInfo(1, 22, 1, 1));
      let monthInfo = new MonthInfo(2024, 1);
      DateManager.getInstance().buildMonthLunarData(monthInfo, yearLunarInfo._solarLunarDays);
      let afterDaysInfo = monthInfo.getDaysInfo()
      // 1.1
      let index = 0
      for (let day = 10; day <= 30; ++day) {
        expect(afterDaysInfo[index].lunaMonth).assertEqual(12);
        expect(afterDaysInfo[index].lunarDay).assertEqual(day);
        index += 1;
      }
      for (let day = 1; day < 10; ++day, ++index) {
        expect(afterDaysInfo[index].lunaMonth).assertEqual(1);
        expect(afterDaysInfo[index].lunarDay).assertEqual(day);
      }
    })

    it('getYearLunarData_01', 0, () => {
      let lunarData = DateManager.getInstance().getYearLunarData(2023);
      if (!lunarData) {
        expect(lunarData).not().assertUndefined();
      } else {
        expect(lunarData.year).assertEqual(2023);
        expect(lunarData._solarLunarDays.length).assertLarger(0);
        expect(lunarData.lunarTermInfos.length).assertLarger(0);

        let index = 0
        expect(JSON.stringify(lunarData._solarLunarDays[index]))
          .assertEqual(JSON.stringify(new SolarLunarInfo(1, 1, 12, 10)));
        expect(JSON.stringify(lunarData._solarLunarDays[++index]))
          .assertEqual(JSON.stringify(new SolarLunarInfo(1, 22, 1, 1)));
        index = 0
        expect(JSON.stringify(lunarData.lunarTermInfos[index])).assertEqual(JSON.stringify(new LunarTermInfo(1, 5, 0)));
      }
    })

    it('SolarLunarInfo_toHexData', 0, () => {
      let info = new SolarLunarInfo(1, 1, 12, 10);
      let data = info.toHexData()
      expect(data.toString(16)).assertEqual('1010c0a');
    })

    it('SolarLunarInfo_toHexStr', 0, () => {
      let info = new SolarLunarInfo(1, 1, 12, 10);
      expect(info.toHexStr()).assertEqual('0x1010c0a');
    })

    it('SolarLunarInfo_fromHexData', 0, () => {
      let info = new SolarLunarInfo(1, 1, 12, 10);
      expect(info.toHexStr()).assertEqual('0x1010c0a');
      let newInfo = SolarLunarInfo.fromHexData(Number.parseInt(info.toHexStr(), 16))
      expect(JSON.stringify(info)).assertEqual(JSON.stringify(newInfo));
    })

    it('LunarTermInfo_toHexData', 0, () => {
      let info = new LunarTermInfo(1, 1, 12);
      let data = info.toHexData()
      expect(data.toString(16)).assertEqual('1010c');
    })

    it('LunarTermInfo_fromHexData', 0, () => {
      let info = new LunarTermInfo(1, 1, 12);
      let data = info.toHexData()
      expect(data.toString(16)).assertEqual('1010c');
      let newInfo = LunarTermInfo.fromHexData(data)
      expect(info.solarMonth).assertEqual(newInfo.solarMonth);
      expect(info.solarDay).assertEqual(newInfo.solarDay);
      expect(info.termIndex).assertEqual(newInfo.termIndex);
    })

    it('DayData_lunar', 0, () => {
      let dayData = DateManager.getInstance()?.getYearData(2026)?.getMonthInfo(8)?.getDayData(12) as DayData;
      expect(dayData?.lunaMonth).assertEqual(6);
      expect(dayData?.lunarDay).assertEqual(30);
      dayData = DateManager.getInstance()?.getYearData(2026)?.getMonthInfo(8)?.getDayData(13) as DayData;
      expect(dayData?.lunaMonth).assertEqual(7);
      expect(dayData?.lunarDay).assertEqual(1);
    })

    it('DayData_lunar_02', 0, () => {
      let dayData = DateManager.getInstance()?.getYearData(2023)?.getMonthInfo(3)?.getDayData(22) as DayData;
      expect(dayData?.lunaMonth).assertEqual(12 + 2); // 闰二月
      expect(dayData?.lunarDay).assertEqual(1);
    })

    it('Today_base_01', 0, () => {
      let dayData = DateManager.getInstance().today;
      expect(dayData.isToday).assertTrue();
    })

    it('Today_set_other_day', 0, () => {
      let dayData = DateManager.getInstance().today;
      expect(dayData.isToday).assertTrue();
      let newDayData = DateManager.getInstance()?.getYearData(2023)?.getMonthInfo(3)?.getDayData(22) as DayData;
      newDayData.isToday = true;
      DateManager.getInstance().today = newDayData;
      let newTodayData = DateManager.getInstance().today;
      expect(newTodayData.isToday).assertTrue();
    })

    it('Today_onSystemDateChange', 0, () => {
      DateManager.getInstance().onSystemDateChange();
      let dayData = DateManager.getInstance().today;
      expect(dayData.isToday).assertTrue();
    })

    it('updateCurrentDate', 0, () => {
      const nowDate = new CalendarDate();
      DateManager.getInstance().updateCurrentDate(nowDate);
      expect(DateManager.getInstance().isCurDateNeedRefresh()).assertFalse();
      DateManager.getInstance().updateCurrentDate(
              new CalendarDate(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - 1));
      expect(DateManager.getInstance().isCurDateNeedRefresh()).assertTrue();
      DateManager.getInstance().updateCurrentDate(
              new CalendarDate(nowDate.getFullYear(), nowDate.getMonth() + 1, nowDate.getDate()));
      expect(DateManager.getInstance().isCurDateNeedRefresh()).assertTrue();
      DateManager.getInstance().updateCurrentDate(
              new CalendarDate(nowDate.getFullYear() - 1, nowDate.getMonth(), nowDate.getDate()));
      expect(DateManager.getInstance().isCurDateNeedRefresh()).assertTrue();
    })
  })
}