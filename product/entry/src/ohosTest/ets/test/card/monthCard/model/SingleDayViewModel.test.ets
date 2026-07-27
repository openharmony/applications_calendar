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
import { FestivalDay, FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { SingleDayViewModel } from '@app/feature.card/src/main/ets/monthCard/model/SingleDayViewModel';
import { SettingsDataModel } from '@app/feature.card/src/main/ets/monthCard/model/SettingsDataModel';

export default function SingleDayViewModelTest() {
  describe('SingleDayViewModelTest', () => {
    // 华为账号下的item排序 1.'local' 2.'birthday'  2.'custom' 3.'others'
    it('checkIsChineseFestival', 0, () => {
      const day: FestivalDay = {
        type: FestivalType.OFFICIAL_CHINA,
        name: 'festival',
        resource: $r('app.string.spring_festival')
      };
      const viewModel = new SingleDayViewModel(new SettingsDataModel());
      let result = viewModel.checkIsChineseFestival(day);
      expect(result).assertFalse();
      day.type = FestivalType.OFFICIAL_TAIWAN;
      result = viewModel.checkIsChineseFestival(day);
      expect(result).assertFalse();
      day.type = FestivalType.OFFICIAL_HONGKONG;
      result = viewModel.checkIsChineseFestival(day);
      expect(result).assertFalse();
      day.type = FestivalType.LUNAR_CHINA;
      result = viewModel.checkIsChineseFestival(day);
      expect(result).assertFalse();
      day.type = FestivalType.INTER;
      result = viewModel.checkIsChineseFestival(day);
      expect(result).assertFalse();
    })

    it('checkIsTerm', 0, () => {
      const day: FestivalDay = {
        type: FestivalType.SOLAR_TERM,
        name: 'festival',
        resource: $r('app.string.spring_festival')
      };
      const viewModel = new SingleDayViewModel(new SettingsDataModel());
      let result = viewModel.checkIsChineseFestival(day);
      expect(result).assertTrue();
    })
  })
}