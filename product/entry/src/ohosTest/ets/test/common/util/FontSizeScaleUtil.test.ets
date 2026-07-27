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

import { describe, expect, it } from '@ohos/hypium'
import { FontSizeScaleUtils, Log } from '@app/common/index'

const TAG = 'FontSizeScaleUtilsTest'

export default function FontSizeScaleUtilsTest() {
  describe('FontSizeScaleUtilsTest', () => {
    it('FontSizeScaleUtils_isGreaterThanStandard', 0, (done: Function) => {
      Log.info(TAG, `${TAG} FontSizeScaleUtils_isGreaterThanStandard begin`);
      expect(FontSizeScaleUtils.isGreaterThanStandard(-1)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanStandard(0.9)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanStandard(1.0)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanStandard(1.1)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThanStandard(2)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThanStandard(3)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThanStandard(100)).assertEqual(true);
      done();
    })

    it('FontSizeScaleUtils_isGreaterThan2X', 0, (done: Function) => {
      Log.info(TAG, `${TAG} FontSizeScaleUtils_isGreaterThan2X begin`);
      expect(FontSizeScaleUtils.isGreaterThan2X(-1)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThan2X(1.9)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThan2X(2.0)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThan2X(2.1)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThan2X(3)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThan2X(100)).assertEqual(true);
      done();
    })

    it('FontSizeScaleUtils_isGreaterThanSpecial', 0, (done: Function) => {
      Log.info(TAG, `${TAG} FontSizeScaleUtils_isGreaterThanSpecial begin`);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(-1)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(0)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(1)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(1.44)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(1.45)).assertEqual(false);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(1.46)).assertEqual(true);
      expect(FontSizeScaleUtils.isGreaterThanSpecial(100)).assertEqual(true);
      done();
    })

    it('FontSizeScaleUtils_getLimitFontSizeNum', 0, (done: Function) => {
      Log.info(TAG, `${TAG} FontSizeScaleUtils_getLimitFontSizeNum begin`);
      expect(FontSizeScaleUtils.getLimitFontSizeNum(1, 1.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitFontSizeNum(2, 1.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitFontSizeNum(1, 2.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitFontSizeNum(1.5, 2.0, 10)).assertEqual(15);
      done();
    })

    it('FontSizeScaleUtils_getLimitHeightNum', 0, (done: Function) => {
      Log.info(TAG, `${TAG} FontSizeScaleUtils_getLimitHeightNum begin`);
      expect(FontSizeScaleUtils.getLimitHeightNum(1, 1.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitHeightNum(2, 1.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitHeightNum(1, 2.0, 10)).assertEqual(10);
      expect(FontSizeScaleUtils.getLimitHeightNum(1.5, 2.0, 10)).assertEqual(15);
      done();
    })
  })
}