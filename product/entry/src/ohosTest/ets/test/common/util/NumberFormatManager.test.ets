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
import { Log, NumberFormatManager } from '@app/common/index'
import { intl } from '@kit.LocalizationKit'

const TAG = 'NumberFormatManagerTest'

export default function NumberFormatManagerTest() {

  describe('NumberFormatManagerTest', () => {
    it('normal_Init', 0, (done: Function) => {
      Log.info(TAG, `${TAG} NumberFormatManagerTest begin`);
      let text = '';
      text = NumberFormatManager.instance().numberFormat(1);
      expect(text).assertEqual('1');
      text = NumberFormatManager.instance().numberFormat(2);
      expect(text).assertEqual('2');
      text = NumberFormatManager.instance().numberFormat(3);
      expect(text).assertEqual('3');
      text = NumberFormatManager.instance().numberFormat(4);
      expect(text).assertEqual('4');
      text = NumberFormatManager.instance().numberFormat(5);
      expect(text).assertEqual('5');
      text = NumberFormatManager.instance().numberFormat(6);
      expect(text).assertEqual('6');
      text = NumberFormatManager.instance().numberFormat(7);
      expect(text).assertEqual('7');
      text = NumberFormatManager.instance().numberFormat(8);
      expect(text).assertEqual('8');
      text = NumberFormatManager.instance().numberFormat(9);
      expect(text).assertEqual('9');
      text = NumberFormatManager.instance().numberFormat(10);
      expect(text).assertEqual('10');
      text = NumberFormatManager.instance().numberFormat(11);
      expect(text).assertEqual('11');
      text = NumberFormatManager.instance().numberFormat(12);
      expect(text).assertEqual('12');
      text = NumberFormatManager.instance().numberFormat(13);
      expect(text).assertEqual('13');
      text = NumberFormatManager.instance().numberFormat(14);
      expect(text).assertEqual('14');
      text = NumberFormatManager.instance().numberFormat(15);
      expect(text).assertEqual('15');
      text = NumberFormatManager.instance().numberFormat(16);
      expect(text).assertEqual('16');
      text = NumberFormatManager.instance().numberFormat(17);
      expect(text).assertEqual('17');
      text = NumberFormatManager.instance().numberFormat(18);
      expect(text).assertEqual('18');
      text = NumberFormatManager.instance().numberFormat(19);
      expect(text).assertEqual('19');
      text = NumberFormatManager.instance().numberFormat(29);
      expect(text).assertEqual('29');
      text = NumberFormatManager.instance().numberFormat(30);
      expect(text).assertEqual('30');
      text = NumberFormatManager.instance().numberFormat(31);
      expect(text).assertEqual('31');


      done();
    })

    it('normal_onLanChange', 0, (done: Function) => {
      Log.info(TAG, `${TAG} NumberFormatManagerTest begin`);
      NumberFormatManager.instance().onLanguageChange('ar-AE');
      let numberOptions: intl.NumberOptions = {};
      numberOptions.style = 'decimal';
      numberOptions.numberingSystem = 'arab';
      const intlTest = new intl.NumberFormat('zh-Hans-AE',numberOptions);
      let text = '';
      text = NumberFormatManager.instance().numberFormat(1);
      expect(text).assertEqual(intlTest.format(1));
      text = NumberFormatManager.instance().numberFormat(2);
      expect(text).assertEqual(intlTest.format(2));
      text = NumberFormatManager.instance().numberFormat(3);
      expect(text).assertEqual(intlTest.format(3));
      text = NumberFormatManager.instance().numberFormat(4);
      expect(text).assertEqual(intlTest.format(4));
      text = NumberFormatManager.instance().numberFormat(5);
      expect(text).assertEqual(intlTest.format(5));
      text = NumberFormatManager.instance().numberFormat(6);
      expect(text).assertEqual(intlTest.format(6));
      text = NumberFormatManager.instance().numberFormat(7);
      expect(text).assertEqual(intlTest.format(7));
      text = NumberFormatManager.instance().numberFormat(8);
      expect(text).assertEqual(intlTest.format(8));
      text = NumberFormatManager.instance().numberFormat(9);
      expect(text).assertEqual(intlTest.format(9));
      done();
    })
  })
}