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
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { Driver, ON, MatchPattern } from '@ohos.UiTest';
import { Log } from '@app/common';
import { TestUtil } from '../utils/TestUtil';
import { WeekTitleViewModel } from '@app/feature.sidebar/src/main/ets/monthview/model/WeekTitleViewModel';

const TAG = 'SideBarWeekTitleViewModel.test';

export default function SideBarWeekTitleViewModelTest() {
  describe('SideBarWeekTitleViewModelTest', () => {
    it('SideBarWeekTitleViewModelTest_001', 0, async (done: Function) => {
      Log.info(TAG, `${TAG}SideBarWeekTitleViewModelTest_001 begin`);

      let weekTitles = WeekTitleViewModel.getInstance().getWeekTitle('zh-CN');
      expect(weekTitles.length).assertEqual(7);
      expect(weekTitles.includes('日')).assertTrue();
      expect(weekTitles.includes('六')).assertTrue();
      WeekTitleViewModel.getInstance().onStartOfWeekChange(1);
      weekTitles = WeekTitleViewModel.getInstance().weekTitles;
      expect(weekTitles[0]).assertEqual('一');
      done()
    })
  })
}