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
import { MINUTES_PER_DAY, MINUTES_PER_HOUR, ReminderUtil } from '@app/common';
import { i18n } from '@kit.LocalizationKit';

export default function ReminderUtilTest() {
  describe('ReminderUtilTest', () => {
    const is24Hour: boolean = i18n.System.is24HourClock();
    it('getReminderText01', 0, () => {
      const tag = ReminderUtil.getReminderText(0, false, 'zh-CN')
      expect(tag).assertEqual('准时');
    });
    it('getReminderText02', 0, () => {
      expect(ReminderUtil.getReminderText(0, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (9:00)' : '当天 (上午09:00)');
    });
    it('getReminderText03', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY + 1, false, 'zh-CN')).assertEqual('1441 分钟前');
    });
    it('getReminderText04', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 7, false, 'zh-CN'))
        .assertEqual('1 周前');
    });
    it('getReminderText05', 0, () => {
      expect(ReminderUtil.getReminderText(-(MINUTES_PER_DAY * 7), false, 'zh-CN')).assertEqual('1 周后');
    });
    it('getReminderText06', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_DAY, false, 'zh-CN')).assertEqual('1 天后');
    });
    it('getReminderText07', 0, () => {
      expect(ReminderUtil.getReminderText(15, false, 'zh-CN')).assertEqual('15 分钟前');
    });
    it('getReminderText08', 0, () => {
      expect(ReminderUtil.getReminderText(-15, false, 'zh-CN')).assertEqual('15 分钟后');
    });
    it('getReminderText09', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_HOUR, false, 'zh-CN')).assertEqual('1 小时前');
    });
    it('getReminderText10', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_HOUR, false, 'zh-CN')).assertEqual('1 小时后');
    });
    it('getReminderText11', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 2, false, 'zh-CN')).assertEqual('2 天前');
    });
    it('getReminderText12', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 7, false, 'zh-CN'))
        .assertEqual('1 周前');
    });
    it('getReminderText13', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY, true, 'zh-CN')).assertEqual(is24Hour ?
        '1 天前 (9:00)' : '1 天前 (上午09:00)');
    });
    it('getReminderText14', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_DAY, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天后 (9:00)' : '1 天后 (上午09:00)');
    });
    it('getReminderText15', 0, () => {
      expect(ReminderUtil.getReminderText(1, true, 'zh-CN')).assertEqual(is24Hour ? '当天 (8:59)' : '当天 (早上08:59)');
    });
    it('getReminderText16', 0, () => {
      expect(ReminderUtil.getReminderText(-2, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (9:02)' : '当天 (上午09:02)');
    });
    it('getReminderText17', 0, () => {
      expect(ReminderUtil.getReminderText(61, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (7:59)' : '当天 (早上07:59)');
    });
    it('getReminderText18', 0, () => {
      expect(ReminderUtil.getReminderText(-61, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (10:01)' : '当天 (上午10:01)');
    });
    it('getReminderText19', 0, () => {
      expect(ReminderUtil.getReminderText(120, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (7:00)' : '当天 (早上07:00)');
    });
    it('getReminderText20', 0, () => {
      expect(ReminderUtil.getReminderText(-120, true, 'zh-CN'))
        .assertEqual(is24Hour ? '当天 (11:00)' : '当天 (中午11:00)');
    });
    it('getReminderText21', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天前 (9:00)' : '1 天前 (上午09:00)');
    });
    it('getReminderText22', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_DAY, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天后 (9:00)' : '1 天后 (上午09:00)');
    });
    it('getReminderText23', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY + 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天前 (8:59)' : '1 天前 (早上08:59)');
    });
    it('getReminderText24', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_DAY + 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天后 (8:59)' : '1 天后 (早上08:59)');
    });
    it('getReminderText25', 0, () => {
      expect(ReminderUtil.getReminderText(-MINUTES_PER_DAY - 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 天后 (9:01)' : '1 天后 (上午09:01)');
    });
    it('getReminderText26', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 7, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 周前 (9:00)' : '1 周前 (上午09:00)');
    });
    it('getReminderText27', 0, () => {
      expect(ReminderUtil.getReminderText(-(MINUTES_PER_DAY * 7), true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 周后 (9:00)' : '1 周后 (上午09:00)');
    });
    it('getReminderText28', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 7 + 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 周前 (8:59)' : '1 周前 (早上08:59)');
    });
    it('getReminderText29', 0, () => {
      expect(ReminderUtil.getReminderText(-(MINUTES_PER_DAY * 7) + 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 周后 (8:59)' : '1 周后 (早上08:59)');
    });
    it('getReminderText30', 0, () => {
      expect(ReminderUtil.getReminderText(-(MINUTES_PER_DAY * 7) - 1, true, 'zh-CN'))
        .assertEqual(is24Hour ? '1 周后 (9:01)' : '1 周后 (上午09:01)');
    });
    it('getReminderText31', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 11, true, 'zh-CN'))
        .assertEqual(is24Hour ? '11 天前 (9:00)' : '11 天前 (上午09:00)');
    });
    it('getReminderText32', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 11 + 65, true, 'zh-CN'))
        .assertEqual(is24Hour ? '11 天前 (7:55)' : '11 天前 (早上07:55)');
    });
    it('getReminderText33', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 29, true, 'zh-CN'))
        .assertEqual(is24Hour ? '29 天前 (9:00)' : '29 天前 (上午09:00)');
    });
    it('getReminderText34', 0, () => {
      expect(ReminderUtil.getReminderText(MINUTES_PER_DAY * 29 - 125, true, 'zh-CN'))
        .assertEqual(is24Hour ? '29 天前 (11:05)' : '29 天前 (中午11:05)');
    });
    it('generateAllDayReminderMinute01', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 9, 0)).assertEqual(0);
    });
    it('generateAllDayReminderMinute02', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 8, 0)).assertEqual(60);
    });
    it('generateAllDayReminderMinute03', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 7, 55)).assertEqual(65);
    });
    it('generateAllDayReminderMinute04', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 8, 59)).assertEqual(1);
    });
    it('generateAllDayReminderMinute05', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 9, 5)).assertEqual(-5);
    });
    it('generateAllDayReminderMinute06', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(0, 10, 40)).assertEqual(-100);
    });
    it('generateAllDayReminderMinute07', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 9, 0)).assertEqual(1440 + 0);
    });
    it('generateAllDayReminderMinute08', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 8, 0)).assertEqual(1440 + 60);
    });
    it('generateAllDayReminderMinute09', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 7, 55)).assertEqual(1440 + 65);
    });
    it('generateAllDayReminderMinute10', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 8, 59)).assertEqual(1440 + 1);
    });
    it('generateAllDayReminderMinute11', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 9, 5)).assertEqual(1440 + -5);
    });
    it('generateAllDayReminderMinute12', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(1, 10, 40)).assertEqual(1440 + -100);
    });
    it('generateAllDayReminderMinute13', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 9, 0)).assertEqual(1440 * 8 + 0);
    });
    it('generateAllDayReminderMinute14', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 8, 0)).assertEqual(1440 * 8 + 60);
    });
    it('generateAllDayReminderMinute15', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 7, 55)).assertEqual(1440 * 8 + 65);
    });
    it('generateAllDayReminderMinute16', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 8, 59)).assertEqual(1440 * 8 + 1);
    });
    it('generateAllDayReminderMinute17', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 9, 5)).assertEqual(1440 * 8 + -5);
    });
    it('generateAllDayReminderMinute18', 0, () => {
      expect(ReminderUtil.generateAllDayReminderMinute(8, 10, 40)).assertEqual(1440 * 8 + -100);
    });
    it('parseAllDayReminderMinute01', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 9, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute02', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 8, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute03', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 7, 55);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(7);
      expect(result.minute).assertEqual(55);
    });
    it('parseAllDayReminderMinute04', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 8, 59);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(59);
    });
    it('parseAllDayReminderMinute05', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 9, 5);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(5);
    });
    it('parseAllDayReminderMinute06', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(0, 10, 40);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(0);
      expect(result.hour).assertEqual(10);
      expect(result.minute).assertEqual(40);
    });
    it('parseAllDayReminderMinute07', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 9, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute08', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 8, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute09', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 7, 55);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(7);
      expect(result.minute).assertEqual(55);
    });
    it('parseAllDayReminderMinute10', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 8, 59);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(59);
    });
    it('parseAllDayReminderMinute11', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 9, 5);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(5);
    });
    it('parseAllDayReminderMinute12', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(1, 10, 40);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(1);
      expect(result.hour).assertEqual(10);
      expect(result.minute).assertEqual(40);
    });
    it('parseAllDayReminderMinute13', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 9, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute14', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 8, 0);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(0);
    });
    it('parseAllDayReminderMinute15', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 7, 55);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(7);
      expect(result.minute).assertEqual(55);
    });
    it('parseAllDayReminderMinute16', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 8, 59);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(8);
      expect(result.minute).assertEqual(59);
    });
    it('parseAllDayReminderMinute17', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 9, 5);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(9);
      expect(result.minute).assertEqual(5);
    });
    it('parseAllDayReminderMinute18', 0, () => {
      const minute = ReminderUtil.generateAllDayReminderMinute(8, 10, 40);
      const result = ReminderUtil.parseAllDayReminderMinute(minute);
      expect(result.dayOffset).assertEqual(8);
      expect(result.hour).assertEqual(10);
      expect(result.minute).assertEqual(40);
    });
  })
}