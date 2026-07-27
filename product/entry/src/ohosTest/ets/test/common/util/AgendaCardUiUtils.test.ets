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
import { CalendarDate } from '@app/common';
import { CardUiUtils } from '@app/feature.card/src/main/ets/utils/CardUiUtils';
import { describe, expect, it } from '@ohos/hypium';

export default function AgendaCardUiUtils() {
  describe('AgendaCardUiUtils', () => {
    // getLunarDayString
    it("getLunarDayString-0101", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 0, 1).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('腊月初二');
    })

    it("getLunarDayString-0130", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 0, 30).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('正月初二');
    })

    it("getLunarDayString-0301", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 2, 1).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('二月初二');
    })

    it("getLunarDayString-0330", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 2, 30).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('三月初二');
    })

    it("getLunarDayString-0429", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 3, 29).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('四月初二');
    })

    it("getLunarDayString-0528", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 4, 28).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('五月初二');
    })

    it("getLunarDayString-0626", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 5, 26).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('六月初二');
    })

    it("getLunarDayString-0726", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 6, 26).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('闰六月初二');
    })

    it("getLunarDayString-0824", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 7, 24).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('七月初二');
    })

    it("getLunarDayString-0923", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 8, 23).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('八月初二');
    })

    it("getLunarDayString-1022", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 9, 22).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('九月初二');
    })

    it("getLunarDayString-1121", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 10, 21).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('十月初二');
    })

    it("getLunarDayString-1221", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 11, 21).getJulianDay();
      const lunarDayString = CardUiUtils.getLunarDayString(julianDayOfNow);

      expect(lunarDayString).assertEqual('冬月初二');
    })

    it("getLunarDayString-0", 0, () => {
      const lunarDayString = CardUiUtils.getLunarDayString(0);

      expect(lunarDayString).assertEqual('');
    })

    // getMonthTitle
    it("getMonthTitle", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(-1);

      expect(monthTitle).assertEqual('');
    })

    it("getMonthTitle0", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(0);

      expect(monthTitle).assertEqual('1月');
    })

    it("getMonthTitle1", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(1);

      expect(monthTitle).assertEqual('2月');
    })

    it("getMonthTitle2", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(2);

      expect(monthTitle).assertEqual('3月');
    })

    it("getMonthTitle3", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(3);

      expect(monthTitle).assertEqual('4月');
    })

    it("getMonthTitle4", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(4);

      expect(monthTitle).assertEqual('5月');
    })

    it("getMonthTitle5", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(5);

      expect(monthTitle).assertEqual('6月');
    })

    it("getMonthTitle6", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(6);

      expect(monthTitle).assertEqual('7月');
    })

    it("getMonthTitle7", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(7);

      expect(monthTitle).assertEqual('8月');
    })

    it("getMonthTitle8", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(8);

      expect(monthTitle).assertEqual('9月');
    })

    it("getMonthTitle9", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(9);

      expect(monthTitle).assertEqual('10月');
    })

    it("getMonthTitle10", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(10);

      expect(monthTitle).assertEqual('11月');
    })

    it("getMonthTitle11", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(11);

      expect(monthTitle).assertEqual('12月');
    })

    it("getMonthTitle12", 0, () => {
      const monthTitle = CardUiUtils.getMonthTitle(12);

      expect(monthTitle).assertEqual('');
    })

    // getFestivalText
    it("getFestivalText-0101", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 0, 1).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('');
    })

    it("getFestivalText-0105", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 0, 5).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('小寒');
    })

    it("getFestivalText-0120", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 0, 20).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('大寒');
    })

    it("getFestivalText-0203", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 1, 3).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('立春');
    })

    it("getFestivalText-0212", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 1, 12).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('');
    })

    it("getFestivalText-0218", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 1, 18).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('雨水');
    })

    it("getFestivalText-0305", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 2, 5).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('惊蛰');
    })

    it("getFestivalText-0320", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 2, 20).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('春分');
    })

    it("getFestivalText-0404", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 3, 4).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('清明节');
    })

    it("getFestivalText-0420", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 3, 20).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('谷雨');
    })

    it("getFestivalText-0501", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 4, 1).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('');
    })

    it("getFestivalText-0505", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 4, 5).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('立夏');
    })

    it("getFestivalText-0521", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 4, 21).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('小满');
    })

    it("getFestivalText-0605", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 5, 5).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('芒种');
    })

    it("getFestivalText-0621", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 5, 21).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('夏至');
    })

    it("getFestivalText-0707", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 6, 7).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('小暑');
    })

    it("getFestivalText-0722", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 6, 22).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('大暑');
    })

    it("getFestivalText-0807", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 7, 7).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('立秋');
    })

    it("getFestivalText-0823", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 7, 23).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('处暑');
    })

    it("getFestivalText-0907", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 8, 7).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('白露');
    })

    it("getFestivalText-0923", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 8, 23).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('秋分');
    })

    it("getFestivalText-1001", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 9, 1).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('');
    })

    it("getFestivalText-1008", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 9, 8).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('寒露');
    })

    it("getFestivalText-1023", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 9, 23).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('霜降');
    })

    it("getFestivalText-1107", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 10, 7).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('立冬');
    })

    it("getFestivalText-1122", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 10, 22).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('小雪');
    })

    it("getFestivalText-1207", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 11, 7).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('大雪');
    })

    it("getFestivalText-1221", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 11, 21).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('冬至');
    })

    it("getFestivalText-1225", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 11, 25).getJulianDay();
      const festivalText = CardUiUtils.getFestivalText(julianDayOfNow);

      expect(festivalText).assertEqual('');
    })

    it("getFestivalText-0", 0, () => {
      const festivalText = CardUiUtils.getFestivalText(0);

      expect(festivalText).assertEqual('');
    })

    // getLunarText
    it("getLunarText-0203", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 1, 3).getJulianDay();
      const lunarText = CardUiUtils.getLunarText(julianDayOfNow);

      expect(lunarText).assertEqual('正月初六 立春');
    })

    it("getLunarText-0320", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 2, 20).getJulianDay();
      const lunarText = CardUiUtils.getLunarText(julianDayOfNow);

      expect(lunarText).assertEqual('二月廿一 春分');
    })

    it("getLunarText-0501", 0, () => {
      const julianDayOfNow = new CalendarDate(2025, 4, 1).getJulianDay();
      const lunarText = CardUiUtils.getLunarText(julianDayOfNow);

      expect(lunarText).assertEqual('四月初四');
    })

    it("getLunarText-0", 0, () => {
      const lunarText = CardUiUtils.getLunarText(0);

      expect(lunarText).assertEqual('');
    })
  })
}