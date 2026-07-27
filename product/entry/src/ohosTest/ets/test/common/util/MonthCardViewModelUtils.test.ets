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
import { SubscriptionCalendar } from '@app/common';
import { ViewModelUtils } from '@app/feature.card/src/main/ets/monthCard/util/ViewModelUtils';
import {
  CardSingleDayViewModel
} from '@app/feature.card/src/main/ets/monthCard/viewModel/components/CardSingleDayViewModel';
import { describe, expect, it } from '@ohos/hypium';

export default function MonthCardViewModelUtils() {
  const viewModel = new CardSingleDayViewModel();

  describe('ViewModelUtils', () => {
    // updateDateTextOpacity
    it("updateDateTextOpacity1", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.showRecessData = true;
      viewModel.isWeekends = true;

      const opacity = ViewModelUtils.updateDateTextOpacity(viewModel);
      expect(opacity).assertEqual(0.5);
    })

    it("updateDateTextOpacity2", 0, () => {
      viewModel.isCurrentMonth = true;
      viewModel.showRecessData = true;
      viewModel.isWeekends = true;

      const opacity = ViewModelUtils.updateDateTextOpacity(viewModel);
      expect(opacity).assertEqual(1);
    })

    it("updateDateTextOpacity3", 0, () => {
      viewModel.isCurrentMonth = true;
      viewModel.showRecessData = false;
      viewModel.isWeekends = true;

      const opacity = ViewModelUtils.updateDateTextOpacity(viewModel);
      expect(opacity.toString()).assertEqual($r('sys.float.alpha_tertiary').toString());
    })

    it("updateDateTextOpacity4", 0, () => {
      viewModel.isCurrentMonth = true;
      viewModel.showRecessData = false;
      viewModel.isWeekends = false;

      const opacity = ViewModelUtils.updateDateTextOpacity(viewModel);
      expect(opacity).assertEqual(1);
    })

    // updateDateTextColor
    it("updateDateTextColor1", 0, () => {
      viewModel.isCurrentMonth = true;
      viewModel.isToday = true;
      viewModel.showRecessData = true;
      viewModel.mark = 1;

      const color = ViewModelUtils.updateDateTextColor(viewModel);
      expect(color.toString()).assertEqual($r('sys.color.ohos_fa_text_contrary').toString());
    })

    it("updateDateTextColor2", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = true;
      viewModel.showRecessData = true;
      viewModel.mark = 1;

      const color = ViewModelUtils.updateDateTextColor(viewModel);
      expect(color.toString()).assertEqual($r('app.color.blue_common').toString());
    })

    it("updateDateTextColor3", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = true;
      viewModel.showRecessData = true;
      viewModel.mark = 2;

      const color = ViewModelUtils.updateDateTextColor(viewModel);
      expect(color.toString()).assertEqual($r('app.color.red_common').toString());
    })

    it("updateDateTextColor4", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = true;
      viewModel.showRecessData = false;
      viewModel.mark = 2;

      const color = ViewModelUtils.updateDateTextColor(viewModel);
      expect(color.toString()).assertEqual($r('sys.color.font_primary').toString());
    })

    // updateCalOrHolTextColor
    it("updateCalOrHolTextColor1", 0, () => {
      viewModel.isCurrentMonth = true;
      viewModel.isToday = true;
      viewModel.hasFestivals = true;

      const color = ViewModelUtils.updateCalOrHolTextColor(viewModel);
      expect(color.toString()).assertEqual($r('sys.color.ohos_fa_text_contrary').toString());
    })

    it("updateCalOrHolTextColor2", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = true;
      viewModel.hasFestivals = true;

      const color = ViewModelUtils.updateCalOrHolTextColor(viewModel);
      expect(color.toString()).assertEqual($r('app.color.red_common').toString());
    })

    it("updateCalOrHolTextColor3", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = false;
      viewModel.hasFestivals = true;

      const color = ViewModelUtils.updateCalOrHolTextColor(viewModel);
      expect(color.toString()).assertEqual($r('app.color.red_common').toString());
    })

    it("updateCalOrHolTextColor4", 0, () => {
      viewModel.isCurrentMonth = false;
      viewModel.isToday = false;
      viewModel.hasFestivals = false;

      const color = ViewModelUtils.updateCalOrHolTextColor(viewModel);
      expect(color.toString()).assertEqual($r('sys.color.font_secondary').toString());
    })

    // getAccessibilityText
    it("getAccessibilityText1", 0, () => {
      viewModel.year = 2025;
      viewModel.month = 2;
      viewModel.day = 24;
      viewModel.isToday = true;
      viewModel.subscriptionCalendar = SubscriptionCalendar.CHINESE_CALENDAR;
      viewModel.hasFestivals = false;
      viewModel.tagText = '十七';

      const text = ViewModelUtils.getAccessibilityText(viewModel);
      expect(text).assertEqual(`今天,2025年2月24日星期一,农历十七`);
    })

    it("getAccessibilityText2", 0, () => {
      viewModel.year = 2025;
      viewModel.month = 2;
      viewModel.day = 24;
      viewModel.isToday = false;
      viewModel.subscriptionCalendar = SubscriptionCalendar.CHINESE_CALENDAR;
      viewModel.hasFestivals = false;
      viewModel.tagText = '十七';

      const text = ViewModelUtils.getAccessibilityText(viewModel);
      expect(text).assertEqual(`2025年2月24日星期一,农历十七`);
    })

    it("getAccessibilityText3", 0, () => {
      viewModel.year = 2025;
      viewModel.month = 2;
      viewModel.day = 24;
      viewModel.isToday = false;
      viewModel.subscriptionCalendar = SubscriptionCalendar.CHINESE_CALENDAR;
      viewModel.hasFestivals = true;
      viewModel.tagText = '十七';

      const text = ViewModelUtils.getAccessibilityText(viewModel);
      expect(text).assertEqual(`2025年2月24日星期一,十七`);
    })

    it("getAccessibilityText4", 0, () => {
      viewModel.year = 2025;
      viewModel.month = 2;
      viewModel.day = 24;
      viewModel.isToday = false;
      viewModel.subscriptionCalendar = SubscriptionCalendar.CHINESE_CALENDAR;
      viewModel.hasFestivals = true;
      viewModel.tagText = '';

      const text = ViewModelUtils.getAccessibilityText(viewModel);
      expect(text).assertEqual(`2025年2月24日星期一`);
    })
  })
}