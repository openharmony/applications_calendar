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
import { CombineAnimateParam, YearAnimateParam } from '@app/common/index';

export default function CombineAnimateParamTest() {
  describe('CombineAnimateParamTest', () => {
    it('default', 0, () => {
      const obj = new CombineAnimateParam;
      expect(obj.visibility).assertFalse();
    })

    it('yearAnimateParamChange', 0, () => {
      const obj = new YearAnimateParam();
      obj.componentWidth = 120;
      obj.componentHeight = 120;
      obj.changeYearAnimationParam(1704038400000, 6, 20, true); // 2024/1/1
      expect(obj.centerX).assertEqual(10);
      expect(obj.centerY).assertEqual(30);

      obj.changeYearAnimationParam(1704038400000, 2, 20, true); // 2024/1/1
      expect(obj.centerX).assertEqual(30);
      expect(obj.centerY).assertEqual(10);

      obj.changeYearAnimationParam(1704038400000, 2, 60, true); // 2024/1/1
      expect(obj.centerX).assertEqual(30);
      expect(obj.centerY).assertEqual(30);

      obj.changeYearAnimationParam(1717171200000, 6, 20, true); // 2024/6/1
      expect(obj.centerX).assertEqual(110);
      expect(obj.centerY).assertEqual(30);

      obj.changeYearAnimationParam(1717171200000, 4, 20, true); // 2024/6/1
      expect(obj.centerX).assertEqual(45);
      expect(obj.centerY).assertEqual(60);

    })
  });
}