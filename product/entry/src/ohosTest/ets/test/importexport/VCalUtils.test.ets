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
import { VCalUtils } from '@app/feature.importexport/src/main/ets/vcalendar/VCalUtils'

export default function VCalUtilTest() {
  describe('VCalUtilTest', () => {
    it('VCalUtilsTest_isLocalTime01', 0, () => {
      const time: string = '';
      const result: boolean = VCalUtils.isLocalTime(time);
      expect(result).assertEqual(false);
    })
    it('VCalUtilsTest_isLocalTime02', 0, () => {
      const time: string = '2023-04-15T17:13:00Z';
      const result: boolean = VCalUtils.isLocalTime(time);
      expect(result).assertEqual(false);
    })
    it('VCalUtilsTest_isLocalTime03', 0, () => {
      const time: string = '2023-04-15T17:30:00';
      const result: boolean = VCalUtils.isLocalTime(time);
      expect(result).assertEqual(true);
    })
    it('getTimezoneLabelTest1', 0, () => {
      let timeZoneLabel: string = VCalUtils.getTimezoneLabel('Asia/Shanghai');
      expect(timeZoneLabel).assertEqual('+08:00');
    });
    it('getTimezoneLabelTest2', 0, () => {
      let timeZoneLabel: string = VCalUtils.getTimezoneLabel('America/New_York');
      expect(timeZoneLabel).assertEqual('-04:00');
    });

    it('getTimezoneLabelTest3', 0, () => {
      let timeZoneLabel: string = VCalUtils.getTimezoneLabel('Pacific/Tahiti');
      expect(timeZoneLabel).assertEqual('-10:00');
    });

    it('getTimezoneLabelTest4', 0, () => {
      let timeZoneLabel: string = VCalUtils.getTimezoneLabel('Antarctica/McMurdo');
      expect(timeZoneLabel).assertEqual('+12:00');
    });

    it('getDtEndFromDurationTest1', 0, () => {
      const dtStart: number = 1735660800000; //2025-1-1 00:00:00
      const dtEnd: number = VCalUtils.getDtEndFromDuration(dtStart, 'P1H');
      expect(dtEnd).assertEqual(1735664400000); //2025-1-1 01:00:00
    });

    it('getSenderTimezoneTest1', 0, () => {
      const timezone: string = VCalUtils.getSenderTimezone('+08:00');
      expect(timezone).assertEqual('Antarctica/Casey');
    });

    it('getSenderTimezoneTest2', 0, () => {
      const timezone: string = VCalUtils.getSenderTimezone('-04:00');
      expect(timezone).assertEqual('America/Anguilla');
    });
  })
}