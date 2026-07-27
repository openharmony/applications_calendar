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
import { Log, MILLS_PER_DAY, MILLS_PER_HOUR, MILLS_PER_MINUTE } from '@app/common'
import { Duration } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Duration'

const TAG = 'DurationTest'

export default function DurationTest() {
  describe('DurationTest', () => {
    /*
     * 通过duration获取毫秒值
     */
    it('Duration_getMillis', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} Duration_getMillis begin`);
      const duration: Duration = new Duration();
      expect(duration.parse('')).assertEqual(false)
      Log.info(TAG, `${TAG} Duration_getMillis ''`);
      expect(duration.parse('xx')).assertEqual(false);
      Log.info(TAG, `${TAG} Duration_getMillis xx`);
      duration.parse('P1D');
      expect(duration.getMillis()).assertEqual(MILLS_PER_DAY);
      Log.info(TAG, `${TAG} Duration_getMillis P1D`);
      duration.parse('-P1D');
      expect(duration.getMillis()).assertEqual(-MILLS_PER_DAY);
      Log.info(TAG, `${TAG} Duration_getMillis -P1D`);
      duration.parse('PT1H');
      expect(duration.getMillis()).assertEqual(MILLS_PER_HOUR);
      Log.info(TAG, `${TAG} Duration_getMillis PT1H`);
      duration.parse('P3600S');
      expect(duration.getMillis()).assertEqual(MILLS_PER_HOUR);
      Log.info(TAG, `${TAG} Duration_getMillis P3600S`);
      duration.parse('P60S');
      expect(duration.getMillis()).assertEqual(MILLS_PER_MINUTE);
      Log.info(TAG, `${TAG} Duration_getMillis P60S`);
      duration.parse('P2W');
      expect(duration.getMillis()).assertEqual(MILLS_PER_DAY * 14);
      Log.info(TAG, `${TAG} Duration_getMillis P2W`);
      done();
    })
  })
}