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
import { CHINA_SHANG_HAI, Log, TimeZoneUtil, UTC } from '@app/common'
import { CustomTime, FormatBit, FormatTime, SplitOption } from '@app/feature.repeatrule'

const TAG = 'FormatTimeTest'

export default function FormatTimeTest() {
  describe('FormatTimeTest', () => {
    /*
     * 2024-01-09 20:30:00 1704803400000 UTC+8
     */
    it('FormatTime_parseByTimeString', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} FormatTime_parseByTimeString begin`);
      expect(new FormatTime().parseByTimeString('20240105T000000Z', new CustomTime())).assertEqual(true);
      expect(new FormatTime().parseByTimeString('20240105', new CustomTime())).assertEqual(true);
      expect(new FormatTime().parseByTimeString('20240105T000000', new CustomTime())).assertEqual(true);

      expect(new FormatTime().parseByTimeString('20240105T000000Z', new CustomTime(TimeZoneUtil.getCurrentTimeZone()))).assertEqual(true);
      expect(new FormatTime().parseByTimeString('20240105', new CustomTime(TimeZoneUtil.getCurrentTimeZone()))).assertEqual(true);
      expect(new FormatTime().parseByTimeString('20240105T000000', new CustomTime(TimeZoneUtil.getCurrentTimeZone()))).assertEqual(true);

      expect(new FormatTime().parseByTimeString('', new CustomTime())).assertEqual(false);
      expect(new FormatTime().parseByTimeString('2024010', new CustomTime())).assertEqual(false);
      expect(new FormatTime().parseByTimeString('20240105T00000', new CustomTime())).assertEqual(false);
      expect(new FormatTime().parseByTimeString('21240105T00000', new CustomTime())).assertEqual(false);
      expect(new FormatTime().parseByTimeString('20241305T00000', new CustomTime())).assertEqual(false);
      expect(new FormatTime().parseByTimeString('202a0105T00c00', new CustomTime())).assertEqual(false);

      const formatTime: FormatTime = new FormatTime();
      formatTime.parseByTimeString('20240104T140000', new CustomTime(CHINA_SHANG_HAI));
      expect(formatTime.timeStamp).assertEqual(1704348000000);

      formatTime.parseByTimeString('20240109T203000', new CustomTime(CHINA_SHANG_HAI));
      expect(formatTime.timeStamp).assertEqual(1704803400000);
      done();
    })

    it('FormatTime_setByCustomTime', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} FormatTime_setByCustomTime begin`);
      expect(new FormatTime().getTimeInFormat2445(1704540600000, CHINA_SHANG_HAI)).assertEqual('20240106T193000');

      let customTime: CustomTime = new CustomTime(UTC);
      customTime.setTime(1704807000000);
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240109T133000Z');

      customTime = new CustomTime(TimeZoneUtil.getCurrentTimeZone());
      customTime.setTime(1704807000000);
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240109T213000');

      // 纪念日
      customTime = new CustomTime(CHINA_SHANG_HAI);
      customTime.setTime(1704816000000);
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240110T000000');

      customTime = new CustomTime(UTC);
      customTime.setTime(1704931200000);
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240111T000000Z');

      customTime = new CustomTime(UTC);
      customTime.setTime(1705017600000);
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240112T000000Z');

      customTime = new CustomTime(CHINA_SHANG_HAI);
      customTime.setTime(1705027299000);
      let splitOption: SplitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: ' ',
        hourSplit: ':',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.MINUTE, splitOption)).assertEqual('2024-01-12 10:41');

      splitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: ' ',
        hourSplit: ':',
        minuteSplit: ':',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS, splitOption)).assertEqual('2024-01-12 10:41:39');

      splitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: '',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.DAY, splitOption)).assertEqual('2024-01-12');
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.YEAR - 1, splitOption)).assertEqual('');
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS + 1, splitOption)).assertEqual('');

      splitOption = {
        yearSplit: '',
        monthSplit: '',
        daySplit: '',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.YEAR, splitOption)).assertEqual('2024');

      splitOption = {
        yearSplit: '-',
        monthSplit: '',
        daySplit: '',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.MONTH, splitOption)).assertEqual('2024-01');

      splitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: '',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.DAY, splitOption)).assertEqual('2024-01-12');

      splitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: ' ',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.HOUR, splitOption)).assertEqual('2024-01-12 10');

      splitOption = {
        yearSplit: '-',
        monthSplit: '-',
        daySplit: ' ',
        hourSplit: ':',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.MINUTE, splitOption)).assertEqual('2024-01-12 10:41');


      customTime = new CustomTime(UTC);
      customTime.setTime(1705017600000);
      splitOption = {
        yearSplit: '',
        monthSplit: '',
        daySplit: '',
        hourSplit: ':',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.DAY, splitOption)).assertEqual('20240112');

      splitOption = {
        yearSplit: '',
        monthSplit: '',
        daySplit: 'T',
        hourSplit: '',
        minuteSplit: '',
        secondSplit: '',
      };
      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS, splitOption)).assertEqual('20240112T000000');

      expect(new FormatTime().setByCustomTime(customTime, false).format(FormatBit.SECONDS)).assertEqual('20240112T000000Z');

      done();
    })

  })
}