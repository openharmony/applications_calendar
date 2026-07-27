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
import { DeviceConfig, deviceType } from '@app/common/index';
import { PcConfig, TabletConfig } from '@app/common/src/main/ets/data/DeviceConfig';

export default function DeviceConfigTest() {
  describe('DeviceConfigTest', () => {
    it('devTypeStr2Enum_01', 0, () => {
      const res = DeviceConfig.devTypeStr2Enum('phone');
      expect(res).assertEqual(deviceType.PHONE);
    })
    it('devTypeStr2Enum_02', 0, () => {
      const res = DeviceConfig.devTypeStr2Enum('tablet');
      expect(res).assertEqual(deviceType.TABLET);
    })
    it('devTypeStr2Enum_03', 0, () => {
      const res = DeviceConfig.devTypeStr2Enum('2in1');
      expect(res).assertEqual(deviceType.PC);
    })
    it('devTypeStr2Enum_04', 0, () => {
      const res = DeviceConfig.devTypeStr2Enum('pc');
      expect(res).assertEqual(deviceType.PC);
    })
    it('devTypeStr2Enum_05', 0, () => {
      const res = DeviceConfig.devTypeStr2Enum('');
      expect(res).assertEqual(deviceType.PHONE);
    })
    it('TabletConfig', 0, () => {
      const res = new TabletConfig;
      expect(res.isShowBtBackGround).assertFalse();
    })
    it('PcConfig', 0, () => {
      const res = new PcConfig;
      expect(res.isShowBtBackGround).assertTrue();
    })

    it('init', 0, () => {
      DeviceConfig.instance().init();
      expect(DeviceConfig.instance().deviceType).not().assertNull();
    })
  });
}