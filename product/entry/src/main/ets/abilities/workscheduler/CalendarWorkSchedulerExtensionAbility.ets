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

import { GlobalThis, Log, WorkSchedulerHelper } from '@app/common';
import { workScheduler, WorkSchedulerExtensionAbility, WorkSchedulerExtensionContext } from '@kit.BackgroundTasksKit';

const TAG = 'CalendarWorkSchedulerExtensionAbility';

const deleteKeys = (workInfo: workScheduler.WorkInfo, keys: string[]) => {
  const obj = {} as workScheduler.WorkInfo
  Object.keys(workInfo).forEach((key) => {
    if (!keys.includes(key)) {
      obj[key] = workInfo[key]
    }
  })
  return obj
}

/*
 * 任务调度Ability,运行在com.openharmony.calendar:workScheduler进程
 * 会先拉起Application,可以共享日历的沙箱
 */
export default class CalendarWorkSchedulerExtensionAbility extends WorkSchedulerExtensionAbility {
  // 延迟任务开始回调
  onWorkStart(workInfo: workScheduler.WorkInfo) {
    const logInfo = deleteKeys(workInfo, ['parameters'])
    Log.info(TAG, `onWorkStart, workInfo = ${logInfo.workId}`);

    this.init(this.context);
    WorkSchedulerHelper.getInstance().onWorkStart(workInfo);
  }

  // 延迟任务结束回调
  onWorkStop(workInfo: workScheduler.WorkInfo) {
    const logInfo = deleteKeys(workInfo, ['parameters'])
    Log.info(TAG, `onWorkStart, workInfo = ${logInfo.workId}`);

    WorkSchedulerHelper.getInstance().onWorkStop(workInfo);
  }

  private init(context: WorkSchedulerExtensionContext) {
    GlobalThis.getInstance().workSchedulerExtensionContext = context;
  }
}