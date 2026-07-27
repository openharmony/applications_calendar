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

import { TimeZoneUtil } from '@app/common';
import { describe, expect, it } from '@ohos/hypium';

export default function TimeZoneUtilTest() {
  describe('timeParse', () => {
    it('timeParse_ISO8601Format', 0, () => {
      const timeStr = '20220228T123456';
      const result = TimeZoneUtil.timeParse(timeStr, true);
      expect(result).assertEqual(1646051696000);
    })

    it('timeParse_NotISO8601Format', 0, () => {
      const timeStr = '20220228123456';
      const result = TimeZoneUtil.timeParse(timeStr, false);
      expect(result).assertEqual(1646006400000);
    })

    it('timeParse_InvalidTimeFormat', 0, () => {
      const timeStr = '20220228';
      const result = TimeZoneUtil.timeParse(timeStr, false);
      expect(result).assertEqual(1646006400000);
    })

    it('timeParse_InvalidTimeFormat_WithT', 0, () => {
      const timeStr = '20220228';
      const result = TimeZoneUtil.timeParse(timeStr, false);
      expect(result).assertEqual(1646006400000);
    })

    it('should_return_correct_offset_when_timeZoneOffset_is_positive', 0, () => {
      let timeZoneOffset = 250;
      let result = TimeZoneUtil.processTimeZoneOffset(timeZoneOffset);
      expect(result).assertEqual("GMT+4:10");
    });

    it('should_return_correct_offset_when_timeZoneOffset_is_negative', 0, () => {
      let timeZoneOffset = -250;
      let result = TimeZoneUtil.processTimeZoneOffset(timeZoneOffset);
      expect(result).assertEqual("GMT-4:10");
    });

    it('should_return_correct_offset_when_timeZoneOffset_is_zero', 0, () => {
      let timeZoneOffset = 0;
      let result = TimeZoneUtil.processTimeZoneOffset(timeZoneOffset);
      expect(result).assertEqual("GMT+0:00");
    });
  })
}