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
import { CalendarDate, CalendarUtils } from '@app/common/index'


export default function CalendarUtilsTest() {
  describe('CalendarUtilsTest', () => {
    it('getLastDayOfWeekByCurrentDate_01', 0, () => {
      let date = CalendarUtils.getLastDayOfWeekByCurrentDate(new CalendarDate(2023, 0, 1), 0);
      expect(date.getFullYear()).assertEqual(2023);
      expect(date.getMonth()).assertEqual(0);
      expect(date.getDate()).assertEqual(7);
    })

    it('isSameDay_01', 0, () => {
      let date1 = new CalendarDate()
      let date2 = new CalendarDate()
      expect(CalendarUtils.isSameDay(date1.getTime(), date2.getTime())).assertTrue();
    })

    it('isSameDay_02', 0, () => {
      let date1 = new CalendarDate()
      let date2 = new CalendarDate()
      date2.setDate(date2.getDate() + 1)
      expect(CalendarUtils.isSameDay(date1.getTime(), date2.getTime())).assertFalse();
    })

  })
}