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

import {
  addButtonTypeText,
  addExpandStatusAndButton,
  addExpandStatusText,
  addImageText,
  addSelectStatusAndButton,
  addSelectStatusText,
  addSwitchText,
  addSelectStatusTextParms,
  addSelectStatusAndButtonParams,
  addOnlySelectStatusText,
  addTodayText} from '@app/common/src/main/ets/util/AccessibilityUtil';
import { describe, expect, it } from '@ohos/hypium'

export default function AccessibilityUtilTest() {
  describe('AccessibilityUtilTest', () => {
    it('addButtonTypeText', 0, () => {
      expect(addButtonTypeText('test')).assertEqual('test按钮');
    });

    it('addExpandStatusText', 0, () => {
      expect(addExpandStatusText('test', true)).assertEqual('已展开test');
      expect(addExpandStatusText('test', false)).assertEqual('已收起test');
    });

    it('addExpandStatusAndButton', 0, () => {
      expect(addExpandStatusAndButton('test', true)).assertEqual('已展开test按钮');
      expect(addExpandStatusAndButton('test', false)).assertEqual('已收起test按钮');
    });

    it('addSelectStatusTextParms', 0, () => {
      expect(addSelectStatusTextParms($r('app.string.five_minutes_before'), true, 5)).assertEqual('已选中5 分钟前');
      expect(addSelectStatusTextParms($r('app.string.five_minutes_before'), false, 5)).assertEqual('未选中5 分钟前');
    });

    it('addSelectStatusText', 0, () => {
      expect(addSelectStatusText('test', true)).assertEqual('已选中test');
      expect(addSelectStatusText('test', false)).assertEqual('未选中test');
    });

    it('addOnlySelectStatusText', 0, () => {
      expect(addOnlySelectStatusText('test', true)).assertEqual('已选中test');
      expect(addOnlySelectStatusText('test', false)).assertEqual('test');
    });

    it('addSelectStatusAndButton', 0, () => {
      expect(addSelectStatusAndButton('test', true)).assertEqual('已选中test按钮');
      expect(addSelectStatusAndButton('test', false)).assertEqual('未选中test按钮');
    });

    it('addSelectStatusAndButtonParams', 0, () => {
      expect(addSelectStatusAndButtonParams($r('app.string.five_minutes_before'), true, 5)).assertEqual('已选中5 分钟前按钮');
      expect(addSelectStatusAndButtonParams($r('app.string.five_minutes_before'), false, 5)).assertEqual('未选中5 分钟前按钮');
    });

    it('addImageText', 0, () => {
      expect(addImageText('test')).assertEqual('test，图片');
      expect(addImageText('test')).assertEqual('test，图片');
    });

    it('addSwitchText', 0, () => {
      expect(addSwitchText('test', true)).assertEqual('开启，test，开关');
      expect(addSwitchText('test', false)).assertEqual('关闭，test，开关');
    });

    it('addTodayText', 0, () => {
      expect(addTodayText('test', true)).assertEqual('今天test');
      expect(addTodayText('test', false)).assertEqual('test');
    });
  })
}