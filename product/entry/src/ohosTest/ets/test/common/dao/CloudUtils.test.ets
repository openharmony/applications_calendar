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
import { isNewSyncAbleAccount } from '@app/common/src/main/ets/dao/CloudUtils';
import { CalendarAccountType } from '@app/common/src/main/ets/account/AccountConst';
import { describe, expect, it } from '@ohos/hypium';

export default function CloudUtilsTest() {
  describe('CloudUtilsTest', () => {
    it('validate_allAccount', 0, () => {
      const result = isNewSyncAbleAccount(CalendarAccountType.ALL_ACCOUNT_TYPE)
      expect(result).assertTrue();
    });

    it('validate_birthdayAccount', 0, () => {
      const result = isNewSyncAbleAccount(CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE)
      expect(result).assertFalse();
    });

    it('validate_holidayAccount', 0, () => {
      const result = isNewSyncAbleAccount(CalendarAccountType.HOLIDAY_ACCOUNT_TYPE)
      expect(result).assertFalse();
    });
  });
}