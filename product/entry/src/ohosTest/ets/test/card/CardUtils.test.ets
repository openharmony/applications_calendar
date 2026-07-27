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
import { describe, expect, it } from '@ohos/hypium';
import { CardSingleDayViewModel, CompressedDayData } from '@app/feature.card/src/main/ets/monthCard/viewModel/components/CardSingleDayViewModel';
import { compressData, decompressData, getAccountColor } from '@app/feature.card/src/main/ets/utils/CardUtils';
import { AccountColor } from '@app/common/src/main/ets/account/AccountColor';

export default function CardUtilsTest() {
  describe('CardUtilsTest', () => {
    it('compressDataTest', 0, async () => {
      const dayData = new CardSingleDayViewModel(2024, 10, 1, false, 1, true, false, true, "国庆节", true, false, true, 0, true, 'CN');
      const result: CompressedDayData = compressData(dayData);
      expect(result).assertDeepEquals([2024, 10, 1, 0, 1, 1, 0, 1, "国庆节", 1, 0, 1, 0, 1, 'CN']);
    });

    it('decompressDataTest', 0, async () => {
      const dayData: CompressedDayData = [2024, 10, 1, 0, 1, 1, 0, 1, "国庆节", 1, 0, 1, 0, 1, 'CN'];
      const result: CardSingleDayViewModel = decompressData(dayData);
      expect(result.year).assertEqual(2024);
      expect(result.month).assertEqual(10);
      expect(result.day).assertEqual(1);
      expect(result.isToday).assertFalse();
      expect(result.mark).assertEqual(1);
      expect(result.isCurrentMonth).assertTrue();
      expect(result.isWeekends).assertFalse();
      expect(result.showTagText).assertTrue();
      expect(result.tagText).assertEqual("国庆节");
      expect(result.showRecessData).assertTrue();
      expect(result.showLunarLine).assertFalse();
      expect(result.hasFestivals).assertTrue();
      expect(result.subscriptionCalendar).assertEqual(0);
      ;
      expect(result.showChineseFestival).assertTrue();
    });

    it('cardGetAccountColorTest', 0, () => {
      expect(getAccountColor(-43956)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-1686170)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-565179)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-6678784)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-3059398)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-3059398)).assertEqual(AccountColor.RED);
      expect(getAccountColor(-2722504)).assertEqual(AccountColor.DARK_ORANGE);
    })
  })
}