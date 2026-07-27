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

import { CityTimeZone } from '@app/common';
import { TimeZoneViewModel } from '@app/feature.settings/src/main/ets/routerPages/TimeZoneViewModel';
import { describe, beforeEach, afterEach, it, expect, MockKit, } from '@ohos/hypium';
import { TestUtil } from '../../utils/TestUtil';

export default function TimeZoneViewModelTest() {
  describe('TimeZoneViewModelTest', () => {

    beforeEach(() => {
    });

    afterEach(() => {
    });

    it('should_filter_timeZoneList_and_set_searchResultCount_and_isShowSearchResult_when_value_is_not_empty', 0, async (done: Function) => {
      let viewModel = new TimeZoneViewModel();
      const city1: CityTimeZone = new CityTimeZone();
      city1.cityDisplayName = 'Tokyo (Japan)';
      city1.timezoneId = 'Asia/Tokyo';
      city1.offset = 'GMT+9:00';
      city1.cityId = 'Tokyo';
      const city2: CityTimeZone = new CityTimeZone();
      city2.cityDisplayName = 'New York (United States)';
      city2.timezoneId = 'America/New_York';
      city2.offset = 'GMT-5:00';
      city2.cityId = 'New_York';
      const mockTimeZoneList: CityTimeZone[] = [city1, city2];
      TestUtil.setPrivateAttribute(viewModel, 'originalTimeZoneList', mockTimeZoneList);
      viewModel.searchChange('Tokyo');
      expect(viewModel.searchResultCount).assertEqual(1);
      expect(viewModel.isShowSearchResult).assertTrue();
      done();
    });

    it('should_reset_searchResultCount_and_isShowSearchResult_and_call_resetTimeZoneList_when_value_is_empty', 0, async (done: Function) => {
      let viewModel = new TimeZoneViewModel();
      let mocker = new MockKit();
      let mockFunc = mocker.mockFunc(viewModel, viewModel.resetTimeZoneList);
      viewModel.searchChange('');
      expect(viewModel.searchResultCount).assertEqual(0);
      expect(viewModel.isShowSearchResult).assertFalse();
      mocker.verify('resetTimeZoneList', []).atLeast(1);
      mocker.ignoreMock(viewModel, viewModel.resetTimeZoneList);
      done();
    });
  });
}
