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
import { CustomTime } from '@app/feature.repeatrule/src/main/ets/time/CustTime';
import { i18n } from '@kit.LocalizationKit';

export default function CustomTimeTest() {
  describe('CustomTimeTest', () => {
    let mCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale());
    it('constructor_without_timezone', 0, () => {
      let time = new CustomTime();
      expect(time.getTimeZone()).assertEqual(mCalendar.getTimeZone());
    });

    it('constructor_with_timezone', 0, () => {
      const tiemZone = 'Asia/Shanghai';
      let time = new CustomTime(tiemZone);
      expect(time.getTimeZone()).assertEqual(tiemZone);
    });

    it('setTimeZone', 0, () => {
      const tiemZone = 'America/New_York';
      let time = new CustomTime('UTC');
      time.setTimeZone(tiemZone)
      expect(time.getTimeZone()).assertEqual(tiemZone);
    });

    it('setTime', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      expect(time.getTimeInMills()).assertEqual(1633070400000);
    });

    it('getYear', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getYear();
      expect(result).assertEqual(2021);
    });

    it('getMonth', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getMonth();
      expect(result).assertEqual(9);
    });

    it('getDate', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getDate();
      expect(result).assertEqual(1);
    });

    it('getDayOfWeek', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getDayOfWeek();
      expect(result).assertEqual(6);
    });

    it('getWeekOfMonth', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getWeekOfMonth();
      expect(result).assertEqual(1);
    });

    it('getDayOfYear', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getDayOfYear();
      expect(result).assertEqual(274);
    });

    it('getWeekOfYear', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getWeekOfYear();
      expect(result).assertEqual(40);
    });

    it('getHour', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getHour();
      expect(result).assertEqual(2);
    });

    it('getHourOfDay', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getHourOfDay();
      expect(result).assertEqual(14);
    });

    it('getMinute', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getMinute();
      expect(result).assertEqual(40);
    });

    it('getSecond', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getSecond();
      expect(result).assertEqual(0);
    });

    it('getJulianDay', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getJulianDay();
      expect(result).assertEqual(2459489);
    });

    it('getTimeZoneOffset', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getTimeZoneOffset();
      expect(result).assertEqual(28800000);
    });

    it('getTimeInMills', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      let result = time.getTimeInMills();
      expect(result).assertEqual(1633070400000);
    });

    it('set_invalid_year', 0, () => {
      let time = new CustomTime();
      let result = time.set(-1, 0, 0);
      expect(result).assertFalse();
      result = time.set(10000, 0, 0);
      expect(result).assertFalse();
    });

    it('set_invalid_month', 0, () => {
      let time = new CustomTime();
      let result = time.set(1991, -1, 0);
      expect(result).assertFalse();
      result = time.set(1991, 14, 0);
      expect(result).assertFalse();
    });

    it('set_invalid_day', 0, () => {
      let time = new CustomTime();
      let result = time.set(1991, 1, 0);
      expect(result).assertFalse();
      result = time.set(1991, 1, 32);
      expect(result).assertFalse();
    });

    it('set_invalid_hour', 0, () => {
      let time = new CustomTime();
      let result = time.set(1991, 1, 1, -1);
      expect(result).assertFalse();
      result = time.set(1991, 1, 1, 24);
      expect(result).assertFalse();
    });

    it('set_invalid_minute', 0, () => {
      let time = new CustomTime();
      let result = time.set(1991, 1, 1, 1, -1);
      expect(result).assertFalse();
      result = time.set(1991, 1, 1, 1, 60);
      expect(result).assertFalse();
    });

    it('addMonth', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      time.addMonth(2);
      expect(time.getMonth()).assertEqual(11);
    });

    it('addDate', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      time.addDate(10);
      expect(time.getDate()).assertEqual(11);
    });

    it('addHour', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      time.addHour(10);
      expect(time.getHour()).assertEqual(0);
    });

    it('addMinute', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      time.addMinute(10);
      expect(time.getMinute()).assertEqual(24);
    });

    it('addSecond', 0, () => {
      let time = new CustomTime();
      time.setTime(1633070400000);
      time.addSecond(10);
      expect(time.getSecond()).assertEqual(24);
    });
  })
}