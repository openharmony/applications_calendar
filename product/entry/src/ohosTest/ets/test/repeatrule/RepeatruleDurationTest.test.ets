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

import { describe, expect, it, Level, TestType } from '@ohos/hypium';
import { Duration } from '@app/feature.repeatrule';
import { MILLS_PER_DAY, MILLS_PER_HOUR, MILLS_PER_MINUTE, MILLS_PER_SECOND, MILLS_PER_WEEK } from '@app/common';

/**
 * Duration测试类
 */
export default function RepeatruleDurationTest() {
  describe('RepeatruleDurationTest', () => {
    it('defaultDuration', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.defaultDuration()).assertEqual(MILLS_PER_HOUR);
    });

    it('parseBySecond_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('P3600S');
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(3600);
      expect(duration.getMills()).assertEqual(3600 * MILLS_PER_SECOND);
      expect(duration.isValid()).assertTrue();

    });

    it('parseByMinute_02', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('-P1800S');
      expect(duration.sign).assertEqual(-1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(1800);
      expect(duration.getMills()).assertEqual(-1800 * MILLS_PER_SECOND);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByMinute_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('+P120M');
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(120);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(120 * MILLS_PER_MINUTE);
      expect(duration.isValid()).assertTrue();

    });

    it('parseByMinute_03', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('-P30M');
      expect(duration.sign).assertEqual(-1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(30);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(-30 * MILLS_PER_MINUTE);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByHour_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('P3H');
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(3);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(3 * MILLS_PER_HOUR);
      expect(duration.isValid()).assertTrue();

    });

    it('parseByHour_02', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('-P1H');
      expect(duration.sign).assertEqual(-1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(1);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(-1 * MILLS_PER_HOUR);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByDay_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('P2D');
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(2);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(2 * MILLS_PER_DAY);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByDay_02', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('-P1D');
      expect(duration.sign).assertEqual(-1);
      expect(duration.weeks).assertEqual(0);
      expect(duration.days).assertEqual(1);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(-1 * MILLS_PER_DAY);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByWeek_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('P2W');
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(2);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(2 * MILLS_PER_WEEK);
      expect(duration.isValid()).assertTrue();
    });

    it('parseByWeek_02', Level.LEVEL1 | TestType.FUNCTION, () => {
      const duration: Duration = Duration.parse('-P1W');
      expect(duration.sign).assertEqual(-1);
      expect(duration.weeks).assertEqual(1);
      expect(duration.days).assertEqual(0);
      expect(duration.hours).assertEqual(0);
      expect(duration.minutes).assertEqual(0);
      expect(duration.seconds).assertEqual(0);
      expect(duration.getMills()).assertEqual(-1 * MILLS_PER_WEEK);
      expect(duration.isValid()).assertTrue();
    });

    it('parseMixed', Level.LEVEL1 | TestType.FUNCTION, () => {
      const durationStr: string = 'P1W2DT3H4M5S';
      const duration: Duration = Duration.parse(durationStr);
      expect(duration.sign).assertEqual(1);
      expect(duration.weeks).assertEqual(1);
      expect(duration.days).assertEqual(2);
      expect(duration.hours).assertEqual(3);
      expect(duration.minutes).assertEqual(4);
      expect(duration.seconds).assertEqual(5);
      expect(duration.getMills()).assertEqual(1 * MILLS_PER_WEEK + 2 * MILLS_PER_DAY
        + 3 * MILLS_PER_HOUR + 4 * MILLS_PER_MINUTE + 5 * MILLS_PER_SECOND);
      expect(duration.isValid()).assertTrue();
    });

    it('parseIllegal_01', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('').isValid()).assertFalse();
    });

    it('parseIllegal_02', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('+').isValid()).assertFalse();
    });

    it('parseIllegal_03', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('P').isValid()).assertFalse();
    });

    it('parseIllegal_04', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('+PT').isValid()).assertFalse();
    });

    it('parseIllegal_05', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('3600S').isValid()).assertFalse();
    });

    it('parseIllegal_06', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('++P3600S').isValid()).assertFalse();
    });

    it('parseIllegal_07', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('--P3600S').isValid()).assertFalse();
    });

    it('parseIllegal_08', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('+-P3600S').isValid()).assertFalse();
    });

    it('parseIllegal_09', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('-+P3600S').isValid()).assertFalse();
    });

    it('parseIllegal_10', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('=P3600S').isValid()).assertFalse();
    });

    it('parseIllegal_11', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('P3600').isValid()).assertFalse();
    });

    it('parseIllegal_12', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('P60m').isValid()).assertFalse();
    });

    it('parseIllegal_13', Level.LEVEL1 | TestType.FUNCTION, () => {
      expect(Duration.parse('P3600s').isValid()).assertFalse();
    });
  });
}