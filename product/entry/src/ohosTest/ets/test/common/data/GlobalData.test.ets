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

import { DateUtil, GlobalData, GlobalDataKeys, GlobalDataValueType } from '@app/common/index';

export default function GlobalDataTest() {
  describe('GlobalDataTest', () => {
    it('GlobalDataTest_DISPLAY_DATE', 0, () => {
      GlobalData.instance().init();
      const date: GlobalDataValueType = Date.now();
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, date);
      const expectData = DateUtil.getStartOfDayTimeStamp(date as number)
      expect(GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE)).assertEqual(expectData);
    });

    it('GlobalDataTest_CURRENT_DATE', 0, () => {
      GlobalData.instance().init();
      const date: GlobalDataValueType = Date.now();
      GlobalData.instance().set(GlobalDataKeys.CURRENT_DATE, date);
      const expectData = DateUtil.getStartOfDayTimeStamp(date as number)
      expect(GlobalData.instance().get(GlobalDataKeys.CURRENT_DATE)).assertEqual(expectData);
    });
  });
}