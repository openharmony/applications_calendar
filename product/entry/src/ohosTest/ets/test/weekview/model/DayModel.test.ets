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

import { afterEach, beforeAll, describe, expect, it } from '@ohos/hypium/src/main/interface';
import { ArgumentMatchers, MockKit, when } from '@ohos/hypium';
import { DayModel } from '@app/feature.weekview/src/main/ets/model/DayModel';
import { DateManager } from '@app/common/src/main/ets/date/DateManager';
import { CalendarDate, FestivalDay } from '@app/common';
import { FestivalType } from '@app/common/src/main/ets/date/FestivalData';

export default function DayModelTest() {
  describe('WeekView_DayModelTest', () => {
    let mocker: MockKit;

    beforeAll(() => {
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('resetDate', 0, () => {
      const date1 = new CalendarDate(2024, 9, 26);
      const date2 = new CalendarDate(-1, 9, 27);
      const dayModel = new DayModel(date1);
      dayModel.resetDate(date2);
      expect(dayModel.getDate().getDate()).assertEqual(27);
    })

    it('getShowFestival', 0, () => {
      const dayModel = new DayModel(new CalendarDate());
      dayModel.showFestivals = [];
      const showFestival: string = dayModel.getShowFestival();
      expect(showFestival.length).assertEqual(0);
    })

    it('isPastDay', 0, () => {
      const dayModel = new DayModel(new CalendarDate(1900, 1, 1));
      expect(dayModel.isPastDay()).assertTrue();
    })
  })
}