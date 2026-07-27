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
import { WorkHandler, WorkId, WorkSchedulerHelper } from '@app/common/';
import workScheduler from '@ohos.resourceschedule.workScheduler';
import { CALENDAR_BUNDLE_NAME } from '@app/common/src/main/ets/constants/Constants';

class MockWorkHandler implements WorkHandler {
  private readonly workId: number;

  constructor(workId: number) {
    this.workId = workId;
  }

  canHandle(workInfo: workScheduler.WorkInfo): boolean {
    return this.workId === workInfo.workId;
  }

  onWorkStart(workInfo: workScheduler.WorkInfo): void {
  }

  onWorkStop(workInfo: workScheduler.WorkInfo): void {
  }
}

const workHandlerA: WorkHandler = new MockWorkHandler(1);
const workHandlerB = new MockWorkHandler(1 + 1);
const workHandlerC = new MockWorkHandler(1 + 2);

const workInfo: workScheduler.WorkInfo = {
  workId: 1,
  bundleName: CALENDAR_BUNDLE_NAME,
  abilityName: 'CalendarWorkSchedulerExtensionAbility',
  // 不要添加 repeatCount, 否则 isRepeat 会无效
  isRepeat: true,
  repeatCycleTime: 20 * 60 * 1000,
}


export default function WorkSchedulerHelperTest() {
  describe('WorkSchedulerHelperTest', () => {

    it('addRemoveWorkHandler', 0, (done: Function) => {
      expect(WorkSchedulerHelper.getInstance().addWorkHandler(workHandlerA)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().addWorkHandler(workHandlerA)).assertEqual(false);
      expect(WorkSchedulerHelper.getInstance().addWorkHandler(workHandlerB)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerC)).assertEqual(false);
      expect(WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerA)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerB)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerA)).assertEqual(false);
      done();
    })

    it('dispatchWorkInfo', 0, async (done: Function) => {
      WorkSchedulerHelper.getInstance().addWorkHandler(workHandlerA);
      WorkSchedulerHelper.getInstance().addWorkHandler(workHandlerB);
      expect(await WorkSchedulerHelper.getInstance().onWorkStart(workInfo)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().onWorkStop(workInfo)).assertEqual(true);
      workInfo.workId = (workInfo.workId + 1);
      expect(await WorkSchedulerHelper.getInstance().onWorkStart(workInfo)).assertEqual(true);
      expect(WorkSchedulerHelper.getInstance().onWorkStop(workInfo)).assertEqual(true);
      workInfo.workId = (workInfo.workId + 1);
      expect(await WorkSchedulerHelper.getInstance().onWorkStart(workInfo)).assertEqual(false);
      expect(WorkSchedulerHelper.getInstance().onWorkStop(workInfo)).assertEqual(false);

      workInfo.workId = 2;
      WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerA);
      WorkSchedulerHelper.getInstance().removeWorkHandler(workHandlerB);

      expect(await WorkSchedulerHelper.getInstance().onWorkStart(workInfo)).assertEqual(false);
      expect(WorkSchedulerHelper.getInstance().onWorkStop(workInfo)).assertEqual(false);

      done();
    })
  })
}