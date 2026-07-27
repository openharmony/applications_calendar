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
import { LockTimeZoneInfo } from '@app/common/src/main/ets/dao/model/LockTimeZoneInfo';
import { describe, expect, it } from '@ohos/hypium';

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


export default function LockTimeZoneInfoTest() {
  describe('LockTimeZoneInfoTest', () => {

    it('test_isTimeZoneLocked', 0, () => {
      let lockTimeZoneInfo: LockTimeZoneInfo = LockTimeZoneInfo.buildLockTimeZoneSwitchInfo(false);
      expect(lockTimeZoneInfo.isTimeZoneLocked()).assertFalse();
      lockTimeZoneInfo = LockTimeZoneInfo.buildLockTimeZoneSwitchInfo(true)
      expect(lockTimeZoneInfo.isTimeZoneLocked()).assertTrue();
    });
  });
}