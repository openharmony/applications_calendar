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
import { describe, expect, it, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { AgendaEventInfo, AgendaListItemViewModel, AgendaUtil, CompId } from '@app/common';

export default function AgendaUtilTest() {
  describe('AgendaUtilTest', () => {
    it('filterEmLabel01', 0, () => {
      expect(AgendaUtil.filterEmLabel('')).assertEqual('');
    });

    it('filterEmLabel02', 0, () => {
      expect(AgendaUtil.filterEmLabel('<em>test</em>')).assertEqual('test');
    });

    it('filterEmLabel03', 0, () => {
      expect(AgendaUtil.filterEmLabel('&#x2f;test')).assertEqual('/test');
    });

    it('getIRichTextArray01', 0, () => {
      expect(AgendaUtil.getIRichTextArray('<em>1</em>234', '1')).assertDeepEquals([{
        isHighLight: true, text: '1'
      }, {
        isHighLight: false, text: '234'
      }]);
    });

    it('transTitleMessage01', 0, () => {
      expect(AgendaUtil.transTitleMessage('', 'test')).assertDeepEquals([{
        isHighLight: false, text: $r('app.string.no_title_label')
      }]);
    });

    it('transTitleMessage02', 0, () => {
      expect(AgendaUtil.transTitleMessage('<em>1</em>234', '1')).assertDeepEquals([{
        isHighLight: true, text: '1'
      }, {
        isHighLight: false, text: '234'
      }]);
    });

    it('transTitleMessage03', 0, () => {
      expect(AgendaUtil.transTitleMessage('test', '')).assertDeepEquals([{
        isHighLight: false, text: 'test'
      }]);
    });

    it('testConflictAgenda', 0, async (done: Function) => {
      let event1 = new AgendaEventInfo();
      let event2 = new AgendaEventInfo();
      event1.mBegin = 1000;
      event1.mEnd = 2000;
      event2.mBegin = 2000; // 边缘重叠的日程不算冲突
      event2.mEnd = 2500;
      let events: AgendaEventInfo[] = [event1, event2];
      AgendaUtil.findConflictAgenda(events);
      expect(event1.isConflict).assertFalse();
      expect(event2.isConflict).assertFalse();
      event2.mBegin = 1999; // 重叠后为冲突日程
      events = [event1, event2];
      AgendaUtil.findConflictAgenda(events);
      expect(event1.isConflict).assertTrue();
      expect(event2.isConflict).assertTrue();
      done();
    });

    it('isMeetingService', 0, () => {
      let event = new AgendaEventInfo();
      event.mHwextServiceType = 'Meeting';
      event.mHwextServiceVerified = true;
      expect(AgendaUtil.isMeetingService(event)).assertTrue();
      event.mHwextServiceType = 'Trip';
      expect(AgendaUtil.isMeetingService(event)).assertFalse();
    })

    it('getLocationTest', 0, () => {
      let locationSource: string = 'aaaa\nbbbb'
      let location = AgendaUtil.getLocation(locationSource);
      expect(location).assertEqual('aaaa');
    })

    it('getFormatLocationTest', 0, () => {
      let locationSource: string = 'aaaa\nbbbb'
      let location = AgendaUtil.getFormatLocation(locationSource);
      expect(location).assertEqual('bbbb');
      let locationSource1: string = 'aaaabbbb'
      let location1 = AgendaUtil.getFormatLocation(locationSource1);
      expect(location1).assertEqual('');
    })

    it('getFormatAddressTest', 0, () => {
      let administrativeArea: string = 'a';
      let locality: string = 'b';
      let subLocality: string = 'c';
      let roadName: string = 'd';
      let location = AgendaUtil.getFormatAddress(administrativeArea,
        locality, subLocality, roadName);
      expect(location).assertEqual('abcd');
      let locality1: string = 'a';
      let location1 = AgendaUtil.getFormatAddress(administrativeArea,
        locality1, subLocality, roadName);
      expect(location1).assertEqual('acd');
    })

    it('locValidTest', 0, () => {
      let latitude: number = 0;
      let longitude: number = 0;
      let valid = AgendaUtil.isLocationValid(latitude, longitude);
      expect(valid).assertEqual(false);
      let latitude_2: number = -1;
      let longitude_2: number = -1;
      let valid_2 = AgendaUtil.isLocationValid(latitude_2, longitude_2);
      expect(valid_2).assertEqual(false);
    })

    it('locValidTest_', 0, () => {
      let latitude: number = 0;
      let longitude: number = 120;
      let valid = AgendaUtil.isLocationValid(latitude, longitude);
      expect(valid).assertEqual(true);
      let latitude_2: number = 30;
      let longitude_2: number = 122;
      let valid_2 = AgendaUtil.isLocationValid(latitude_2, longitude_2);
      expect(valid_2).assertEqual(true);
    })

    it('getShareIdByIndexAndInfoTest', 0, () => {
      let event1 = new AgendaEventInfo();
      let event2 = new AgendaEventInfo();
      event1.mId = 2;
      event1.mBegin = 1000;
      event1.mEnd = 2000;
      event2.mId = 5;
      event2.mBegin = 2000; // 边缘重叠的日程不算冲突
      event2.mEnd = 2500;
      expect(AgendaUtil.getShareIdByIndexAndInfo(event1, 1)).assertEqual(`${CompId.NORMAL_AGENDA_LIST_ITEM}-${1}-${event1.mId}-${event1.mBegin}`);
      expect(AgendaUtil.getShareIdByIndexAndInfo(event1, 0)).assertEqual(`${CompId.NORMAL_AGENDA_LIST_ITEM}-${0}-${event1.mId}-${event1.mBegin}`);
      expect(AgendaUtil.getShareIdByIndexAndInfo(event2, 0)).assertEqual(`${CompId.NORMAL_AGENDA_LIST_ITEM}-${0}-${event2.mId}-${event2.mBegin}`);
      expect(AgendaUtil.getShareIdByIndexAndInfo(event2)).assertEqual(`${CompId.NORMAL_AGENDA_LIST_ITEM}-${-1}-${event2.mId}-${event2.mBegin}`);
    })

    it('filterDupByEventIdTest1', 0, () => {
      let event1 = new AgendaEventInfo();
      let event2 = new AgendaEventInfo();
      event1.mId = 2;
      event1.mBegin = 1000;
      event1.mEnd = 2000;
      event2.mId = 5;
      event2.mBegin = 2000;
      event2.mEnd = 2500;
      let events: AgendaListItemViewModel[] = [
        new AgendaListItemViewModel(event1),
        new AgendaListItemViewModel(event2)
      ];
      let mocker: MockKit = new MockKit();
      let mockIsContactBirthday: Function = mocker.mockFunc(AgendaEventInfo, event1.isContactBirthday);
      let mockIsHoliday: Function = mocker.mockFunc(AgendaEventInfo, event1.isHoliday);

      when(mockIsContactBirthday)(ArgumentMatchers.any).afterReturn(true);
      when(mockIsHoliday)(ArgumentMatchers.any).afterReturn(true);

      const result = AgendaUtil.filterDupByEventId(events, false);
      expect(result.length).assertEqual(2);
    })

    it('filterDupByEventIdTest2', 0, () => {
      let event1 = new AgendaEventInfo();
      let event2 = new AgendaEventInfo();
      event1.mId = 2;
      event1.mBegin = 1000;
      event1.mEnd = 2000;
      event2.mId = 5;
      event2.mBegin = 2000;
      event2.mEnd = 2500;
      let events: AgendaListItemViewModel[] = [
        new AgendaListItemViewModel(event1),
        new AgendaListItemViewModel(event2)
      ];
      let mocker: MockKit = new MockKit();
      let mockIsContactBirthday: Function = mocker.mockFunc(AgendaEventInfo, event1.isContactBirthday);
      let mockIsHoliday: Function = mocker.mockFunc(AgendaEventInfo, event1.isHoliday);

      when(mockIsContactBirthday)(ArgumentMatchers.any).afterReturn(false);
      when(mockIsHoliday)(ArgumentMatchers.any).afterReturn(true);

      const result = AgendaUtil.filterDupByEventId(events, false);
      expect(result.length).assertEqual(2);
    })

    it('filterDupByEventIdTest3', 0, () => {
      let event1 = new AgendaEventInfo();
      let event2 = new AgendaEventInfo();
      event1.mId = 2;
      event1.mBegin = 1000;
      event1.mEnd = 2000;
      event2.mId = 5;
      event2.mBegin = 2000;
      event2.mEnd = 2500;
      let events: AgendaListItemViewModel[] = [
        new AgendaListItemViewModel(event1),
        new AgendaListItemViewModel(event2)
      ];
      let mocker: MockKit = new MockKit();
      let mockIsContactBirthday: Function = mocker.mockFunc(event1, event1.isContactBirthday);
      let mockIsHoliday: Function = mocker.mockFunc(event1, event1.isHoliday);

      when(mockIsContactBirthday)(ArgumentMatchers.any).afterReturn(true);
      when(mockIsHoliday)(ArgumentMatchers.any).afterReturn(false);

      const result = AgendaUtil.filterDupByEventId(events, false);
      expect(result.length).assertEqual(2);
    })
  })
}