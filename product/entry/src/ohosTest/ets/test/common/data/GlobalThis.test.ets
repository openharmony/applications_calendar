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
import { GlobalThis } from '@app/common/index';

export default function GlobalThisTest() {
  describe('GlobalThisTest', () => {

    const FONT_COLOR_1_VAL = 4291907898;
    const FONT_COLOR_2_VAL = 4292244792;
    const BG_COLOR_1_VAL = 4294768115;
    const BG_COLOR_2_VAL = 4294834421;

    it('getResourceStr', 0, () => {
      expect(GlobalThis.getResourceStr($r('app.string.today'))).assertEqual('今天');
      expect(GlobalThis.getResourceStr($r('app.string.today'))).assertEqual('今天');
    });

    it('getResourceStrParms', 0, () => {
      expect(GlobalThis.getResourceStrParms($r('app.string.first_day_of_week_each_month'), '星期一')).assertEqual('第一个星期一');
      expect(GlobalThis.getResourceStrParms($r('app.string.first_day_of_week_each_month'), '星期二')).assertEqual('第一个星期二');
    });

    it('getBasicContext', 0, () => {
      expect(GlobalThis.getInstance().getBasicContext()).not().assertNull();
    });

    it('getDbContext', 0, () => {
      expect(GlobalThis.getInstance().getDbContext()).not().assertNull();
    });

    it('getBundleInfoSync', 0, () => {
      expect(GlobalThis.getInstance().getBundleInfoSync()).not().assertNull();
    });

    it('getBundleInfo', 0, async () => {
      expect(await GlobalThis.getInstance().getBundleInfo()).not().assertNull();
    });
  });
}