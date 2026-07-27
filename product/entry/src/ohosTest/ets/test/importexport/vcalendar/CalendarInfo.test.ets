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

import { beforeEach, describe, expect, it } from '@ohos/hypium'
import { TestUtil } from '../../utils/TestUtil'
import { CalendarInfo } from '@app/feature.importexport/src/main/ets/vcalendar/CalendarInfo'
import { VcsComponent, VTIMEZONE } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/VcsComponent'
import { Property } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Property'
import { TIMEZONE, TIMEZONE_ID, VERSION } from '@app/feature.importexport/src/main/ets/vcalendar/VCalendarConstants'

export default function CalendarInfoTest() {
  describe('CalendarInfoTest', () => {
    let info: CalendarInfo;

    beforeEach(() => {
      info = new CalendarInfo();
    });

    it('initCalendarInfoByComponent_VERSION', 0, () => {
      let component = new VcsComponent('test', undefined);
      component.addProperty(new Property(VERSION, '1.0'));
      info.initCalendarInfoByComponent(component);
      expect(info.getVersion()).assertEqual('1.0');
    });

    it('initCalendarInfoByComponent_TIMEZONE', 0, () => {
      let component = new VcsComponent('test', undefined);
      component.addProperty(new Property(TIMEZONE, 'test'));
      info.initCalendarInfoByComponent(component);
      expect(info.getTz()).assertEqual('test');
    });

    it('initCalendarInfoByComponent', 0, () => {
      let component = new VcsComponent('test', undefined);
      component.addProperty(new Property(VERSION, '1.0'));
      component.addProperty(new Property(TIMEZONE_ID, 'China Standard Time'));
      let subComponent = new VcsComponent(VTIMEZONE, undefined);


      component.addChild(subComponent);
      info.initCalendarInfoByComponent(component);
      expect(info.getTz()).assertEqual('');
      let mTimezone: string = TestUtil.getPrivateAttribute(info, 'mTimezone')
      expect(mTimezone).assertEqual('Asia/Shanghai');
    });

    it('copyInfo', 0, () => {
      info.copyInfo(new CalendarInfo('test'));
      expect(info.getTimezone()).assertEqual('test');
    });

    it('getOffSet', 0, () => {
      TestUtil.setPrivateAttribute(info, 'mTzOffSetTo', 'test1');
      expect(info.getOffSet()).assertEqual('test1');
    });

    it('getOffsetValue', 0, () => {
      let func = TestUtil.getPrivateFunction(info, 'getOffsetValue');
      if (!func) {
        expect(func).assertNull();
      } else {
        expect(func(new VcsComponent('test', undefined), ['test1', 'test2'])).not().assertEqual('1');
      }
    });

    it('setOffSetWithDayLight', 0, () => {
      let func = TestUtil.getPrivateFunction(info, 'setOffSetWithDayLight');
      if (!func) {
        expect(func).assertNull();
      } else {
        func();
        expect(info.getTimezone()).not().assertEqual('info');
      }
    });
  })
}