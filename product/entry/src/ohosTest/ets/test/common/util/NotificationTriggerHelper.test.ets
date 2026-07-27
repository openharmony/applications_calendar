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
import { Log, NotificationTriggerHelper, TriggerSource } from '@app/common/index'

const TAG = 'NotificationTriggerHelperTest'

export default function NotificationTriggerHelperTest() {

  describe('NotificationTriggerHelperTest', () => {
    it('requestNotification', 0, (done: Function) => {
      Log.info(TAG, `${TAG} NotificationTriggerHelper_requestNotification begin`);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.NOTHING)).assertEqual(false);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.BROWSE_APP)).assertEqual(true);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.BROWSE_APP)).assertEqual(false);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS)).assertEqual(true);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS)).assertEqual(false);
      expect(NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.BROWSE_APP)).assertEqual(false);
      done();
    })
  })
}