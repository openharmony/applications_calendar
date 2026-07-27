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
import { ImportantEntity } from '@app/feature.card/src/main/ets/importantCard/model/ImportantEntity';
import { CardUiUtils } from '@app/feature.card/src/main/ets/importantCard/util/CardUiUtils';
import { describe, expect, it } from '@ohos/hypium';

export default function GetYearDayOffset() {

  let important: ImportantEntity = new ImportantEntity();

  describe('GetYearDayOffsetTest', () => {
    it("Anniversaries1", 0, () => {
      // 当天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0);
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 当天的纪念日
      expect(result.dayOffset).assertEqual(1);
    })

    it('Anniversaries2', 0, () => {
      // 纪念日1天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) - MILLS_PER_DAY;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 纪念日昨天到今天记为两天
      expect(result.dayOffset).assertEqual(2);
    });

    it("Anniversaries3", 0, () => {
      // 一周年
      const lastDate = new CalendarDate();
      lastDate.setFullYear(lastDate.getFullYear() - 1);
      const timeStamp = new CalendarDate(lastDate.setHours(0, 0, 0, 0)).getTime();
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 去年的纪念日
      expect(result.yearOffset).assertEqual(1);
    })

    it("Anniversaries4", 0, () => {
      // 一周年一天
      const lastDate = new CalendarDate();
      lastDate.setFullYear(lastDate.getFullYear() - 1);
      lastDate.setDate(lastDate.getDate() - 1);
      const timeStamp = new CalendarDate(lastDate.setHours(0, 0, 0, 0)).getTime();
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 去年一天的纪念日
      expect(result.remainingDays).assertEqual(1);
    })

    it("Countdown1", 0, () => {
      // 当天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 12 * MILLS_PER_HOUR;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 当天的倒数日
      expect(result.dayOffset).assertEqual(0);
    })

    it("Countdown2", 0, () => {
      // 第二天
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 36 * MILLS_PER_HOUR;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 对于今天是1.5天后的倒数日
      expect(result.dayOffset).assertEqual(1);
    })

    it('Countdown3', 0, () => {
      // 第4天凌晨，整点
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 3 * MILLS_PER_DAY;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 对于今天是3天后的倒数日
      expect(result.dayOffset).assertEqual(3);
    })

    it('Countdown4', 0, () => {
      // 第4天凌晨，整点过1s
      const timeStamp = new CalendarDate().setHours(0, 0, 0, 0) + 3 * MILLS_PER_DAY + 1;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 对于今天是3天后的倒数日
      expect(result.dayOffset).assertEqual(3);
    })

    it("Countdown5", 0, () => {
      // 2周年
      const lastDate = new CalendarDate();
      lastDate.setFullYear(lastDate.getFullYear() - 2);
      const timeStamp = new CalendarDate(lastDate.setHours(0, 0, 0, 0)).getTime() + MILLS_PER_HOUR;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 两年后
      expect(result.yearOffset).assertEqual(2);
    })

    it("Countdown6", 0, () => {
      // 2周年多1天
      const lastDate = new CalendarDate();
      lastDate.setFullYear(lastDate.getFullYear() - 2);
      const timeStamp = new CalendarDate(lastDate.setHours(0, 0, 0, 0)).getTime() - MILLS_PER_DAY + MILLS_PER_HOUR;
      important.begin = timeStamp;
      important.originalBegin = timeStamp;
      important.importantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      important.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;
      const result = CardUiUtils.getYearDayOffset(important);

      // 两年零一天
      expect(result.remainingDays).assertEqual(1);
    })
  })
}