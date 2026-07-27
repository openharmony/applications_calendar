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
import {
  getCalendarBuilder,
  getCalendarParser
} from '@app/feature.importexport/src/main/ets/vcalendar/CalendarFactory';
import { CalendarInfo } from '@app/feature.importexport/src/main/ets/vcalendar/CalendarInfo';
import { TestUtil } from '../../utils/TestUtil';

const TAG = 'CalendarFactoryTest';

export default function CalendarFactoryTest() {
  describe('CalendarFactoryTest', () => {

    it('getCalendarBuilder', 0, () => {
      console.info(TAG, 'CalendarFactoryTest start');
      let calendarInfo: CalendarInfo = new CalendarInfo();
      expect(getCalendarBuilder(calendarInfo)).not().assertUndefined();

      TestUtil.setPrivateAttribute(calendarInfo, 'mVersion', '1.0');
      expect(getCalendarBuilder(calendarInfo)).not().assertUndefined();
    })

    it('getCalendarParser', 0, async () => {
      let calendarInfo: CalendarInfo = new CalendarInfo();
      expect(getCalendarParser(calendarInfo)).not().assertUndefined();

      TestUtil.setPrivateAttribute(calendarInfo, 'mVersion', '1.0');
      expect(getCalendarParser(calendarInfo)).not().assertUndefined();
    })
  })
}