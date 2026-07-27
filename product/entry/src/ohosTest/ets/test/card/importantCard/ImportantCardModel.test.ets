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

import { describe, expect, it, Level } from '@ohos/hypium';
import { ImportantCardModel } from '@app/feature.card/src/main/ets/importantCard/model/ImportantCardModel';
import { EventMode } from '@app/common/src/main/ets/card/ImportantCardConfig';

export default function ImportantCardModelTest() {
  describe('ImportantCardModelTest', () => {
    it('parseImportant', Level.LEVEL1, () => {
      const model = new ImportantCardModel();
      const event: ESObject = {
        '_id': 1,
        'dtstart': Date.now(),
        'important_event_type': 1
      };
      model.bindMode(EventMode.FIXED_IMPORTANT);
      model.updateFixedImportant([event]);
      const entity = model.getShowImportantEntity();
      expect(entity !== null).assertTrue();
      expect(entity?.eventId).assertEqual(1);
    });
    it('parseBirthday', Level.LEVEL1, () => {
      const model = new ImportantCardModel();
      const event: ESObject = {
        '_id': 2,
        'dtstart': Date.now(),
        'important_event_type': 0,
        'account_type': 'birthday'
      };
      model.bindMode(EventMode.FIXED_BIRTHDAY);
      model.updateFixedBirthday([event]);
      const entity = model.getShowImportantEntity();
      expect(entity !== null).assertTrue();
      expect(entity?.eventId).assertEqual(2);
    });
    it('parseHoliday', Level.LEVEL1, () => {
      const model = new ImportantCardModel();
      const event: ESObject = {
        '_id': 3,
        'dtstart': Date.now(),
        'important_event_type': 10,
        'title': '国庆节'
      };
      model.bindMode(EventMode.RECENT_HOLIDAY);
      model.updateRecentHoliday([event]);
      model.updateFixedHoliday([]);
      const entity = model.getShowImportantEntity();
      expect(entity !== null).assertTrue();
      expect(entity?.eventId).assertEqual(3);
    });
    it('parseIsExpiredHoliday2', Level.LEVEL1, () => {
      const model = new ImportantCardModel();
      const isExpiredEvent: ESObject = {
        '_id': 3,
        'title': '国庆节',
        'dtstart': new Date(1 - 1 - 1).getTime(),
        'important_event_type': 10
      };
      const event: ESObject = {
        '_id': 6,
        'title': '国庆节',
        'dtstart': Date.now(),
        'important_event_type': 10
      };
      model.bindMode(EventMode.RECENT_HOLIDAY);
      model.updateRecentHoliday([event]);
      model.updateFixedHoliday([isExpiredEvent]);
      const entity = model.getShowImportantEntity();
      expect(entity !== null).assertTrue();
      expect(entity?.eventId).assertEqual(6);
    });
  });
}