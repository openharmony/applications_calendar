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

import { describe, expect, it, Level } from '@ohos/hypium';
import { CardUiUtils } from '@app/feature.card/src/main/ets/importantCard/util/CardUiUtils';

export default function CardUiUtilsTest() {
  describe('CardUiUtilsTest', () => {
    it('dateDiff2YearDayOffset_lunar1', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 5).getTime(),
      new Date(2025, 5, 5).getTime(), 1);
      expect(yearDayOffset.yearOffset).assertEqual(3);
      expect(yearDayOffset.remainingDays).assertEqual(3);
    });
    it('dateDiff2YearDayOffset_lunar2', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 5).getTime(),
        new Date(2025, 10, 5).getTime(), 1);
      expect(yearDayOffset.yearOffset).assertEqual(3);
      expect(yearDayOffset.remainingDays).assertEqual(156);
    });
    it('dateDiff2YearDayOffset_lunar3', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 5).getTime(),
        new Date(2025, 2, 5).getTime(), 1);
      expect(yearDayOffset.yearOffset).assertEqual(2);
      expect(yearDayOffset.remainingDays).assertEqual(266);
    });
    it('dateDiff2YearDayOffset_lunar4', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(1977, 1, 2).getTime(),
        new Date(2025, 2, 5).getTime(), 1);
      expect(yearDayOffset.yearOffset).assertEqual(48);
      expect(yearDayOffset.remainingDays).assertEqual(50);
    });
    it('dateDiff2YearDayOffset_lunar5', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(1956, 0, 11).getTime(),
        new Date(2025, 2, 5).getTime(), 1);
      expect(yearDayOffset.yearOffset).assertEqual(69);
      expect(yearDayOffset.remainingDays).assertEqual(66);
    });
    it('dateDiff2YearDayOffset_solar1', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 1).getTime(),
        new Date(2025, 5, 1).getTime(), 0);
      expect(yearDayOffset.yearOffset).assertEqual(3);
      expect(yearDayOffset.remainingDays).assertEqual(0);
    });
    it('dateDiff2YearDayOffset_solar2', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 1).getTime(),
        new Date(2025, 4, 1).getTime(), 0);
      expect(yearDayOffset.yearOffset).assertEqual(2);
      expect(yearDayOffset.remainingDays).assertEqual(334);
    });
    it('dateDiff2YearDayOffset_solar3', Level.LEVEL1, () => {
      const yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(new Date(2022, 5, 1).getTime(),
        new Date(2025, 6, 1).getTime(), 0);
      expect(yearDayOffset.yearOffset).assertEqual(3);
      expect(yearDayOffset.remainingDays).assertEqual(30);
    });
  });
}