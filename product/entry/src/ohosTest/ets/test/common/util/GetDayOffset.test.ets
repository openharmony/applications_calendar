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
import { CalendarContract, CalendarDate, DateUtil, MILLS_PER_DAY, MILLS_PER_HOUR } from '@app/common/index';
import { describe, expect, it } from '@ohos/hypium';

export default function GetDayOffset() {

  describe('GetDayOffsetTest', () => {

    it('Anniversaries1', 0, () => {
      // 时间小于当前时间
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) - MILLS_PER_DAY;
      const result = DateUtil.getDayOffset(timeStamp)

      // 纪念日昨天到今天记为两天
      expect(result.dayOffset).assertEqual(2);
    });

    it('Countdown1', 0, () => {
      // 时间比当前时间还多3天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 3 * MILLS_PER_DAY;
      const result = DateUtil.getDayOffset(timeStamp)

      // 对于今天是3天后的倒数日
      expect(result.dayOffset).assertEqual(3);
    })

    it("Countdown2", 0, () => {
      // 当天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 12 * MILLS_PER_HOUR;
      const result = DateUtil.getDayOffset(timeStamp, CalendarContract.EventImportantType.COUNTDOWN)

      // 当天的倒数日
      expect(result.dayOffset).assertEqual(0);
    })

    it("Anniversaries2", 0, () => {
      // 当天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 12 * MILLS_PER_HOUR;
      const result = DateUtil.getDayOffset(timeStamp)

      // 当天的纪念日
      expect(result.dayOffset).assertEqual(1);
    })
  })
}