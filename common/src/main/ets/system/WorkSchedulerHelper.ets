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

import lazy { workScheduler } from '@kit.BackgroundTasksKit';
import { Log } from '../default/common/Log';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';

const TAG = 'WorkSchedulerHelper';

type WorkInfo = workScheduler.WorkInfo;

export interface WorkHandler {
  canHandle(workInfo: workScheduler.WorkInfo): boolean;

  onWorkStart(workInfo: workScheduler.WorkInfo): void;

  onWorkStop(workInfo: workScheduler.WorkInfo): void;
}

export interface WorkInfoWarp {
  readonly workName: string;
  readonly rawWork: WorkInfo;
}

/*
 * WorkSchedulerHelper
 * wiki http://3ms.OpenHarmony.com/km/blogs/details/12516649?l=zh-cn
 */
export class WorkSchedulerHelper {
  private readonly workHandlers: WorkHandler[] = [];

  static getInstance(): WorkSchedulerHelper {
    return SingleInstanceHelper.createOrGet(WorkSchedulerHelper, TAG);
  }

  startWork(workInfo: WorkInfoWarp): boolean {
    Log.info(TAG, `startWork workname is ${workInfo.workName} id is ${workInfo.rawWork.workId}`);
    try {
      workScheduler.startWork(workInfo.rawWork);
      Log.info(TAG, `startWork workname is ${workInfo.workName} is success`);
      return true;
    } catch (error) {
      Log.logErrorMsg(TAG, 'startWork', error);
      return false;
    }
  }


  stopWork(workInfo: WorkInfoWarp, needCancel?: boolean): boolean {
    Log.info(TAG, `stopWork workname is ${workInfo.workName}`);
    try {
      workScheduler.stopWork(workInfo.rawWork, needCancel);
      Log.info(TAG, `stopWork success`);
      return true;
    } catch (error) {
      Log.logErrorMsg(TAG, 'stopWork', error);
      return false
    }
  }


  async getWorkStatus(workInfo: WorkInfoWarp): Promise<WorkInfo | undefined> {
    Log.info(TAG, `getWorkStatus workname is ${workInfo.workName}`);
    try {
      return workScheduler.getWorkStatus(workInfo.rawWork.workId);
    } catch (error) {
      Log.logErrorMsg(TAG, 'getWorkStatus', error);
      return undefined;
    }
  }


  async obtainAllWorks(): Promise<Array<WorkInfo>> {
    Log.info(TAG, `obtainAllWorks`);
    try {
      return workScheduler.obtainAllWorks();
    } catch (error) {
      Log.logErrorMsg(TAG, 'obtainAllWorks', error);
      return [];
    }
  }

  stopAndClearWorks(): void {
    try {
      workScheduler.stopAndClearWorks();
    } catch (error) {
      Log.logErrorMsg(TAG, 'stopAndClearWorks', error);
    }
  }


  async isLastWorkTimeOut(workInfo: WorkInfoWarp): Promise<boolean> {
    Log.info(TAG, `isLastWorkTimeOut workname is ${workInfo.workName}`);
    try {
      return workScheduler.isLastWorkTimeOut(workInfo.rawWork.workId);
    } catch (error) {
      Log.logErrorMsg(TAG, 'isLastWorkTimeOut', error);
      return false
    }
  }

  // 延迟任务开始回调
  async onWorkStart(workInfo: workScheduler.WorkInfo): Promise<boolean> {
    const workHandler = this.findMatchedHandler(workInfo);
    if (!workHandler) {
      Log.info(TAG, `onWorkStart, no workHandler can handle`);
      return false;
    }
    workHandler.onWorkStart(workInfo);
    return true;
  }

  // 延迟任务结束回调
  onWorkStop(workInfo: workScheduler.WorkInfo): boolean {
    const workHandler = this.findMatchedHandler(workInfo);
    if (!workHandler) {
      Log.info(TAG, `onWorkStop, no workHandler can handle`);
      return false;
    }
    workHandler.onWorkStop(workInfo);
    return true;
  }

  addWorkHandler(workHandler: WorkHandler): boolean {
    if (!workHandler) {
      Log.warn(TAG, 'addWorkHandler workHandler is null');
      return false;
    }
    if (this.workHandlers.includes(workHandler)) {
      Log.warn(TAG, 'addWorkHandler workHandler is exit');
      return false;
    }
    this.workHandlers.push(workHandler);
    return true;
  }

  removeWorkHandler(workHandler: WorkHandler): boolean {
    if (!workHandler) {
      Log.warn(TAG, 'removeWorkHandler workHandler is null');
      return false;
    }
    const index = this.workHandlers.indexOf(workHandler);
    if (index < 0 || index >= this.workHandlers.length) {
      Log.warn(TAG, 'removeWorkHandler no that workHandler');
      return false;
    }
    this.workHandlers.splice(index, 1);
    return true;
  }

  private findMatchedHandler(workInfo: workScheduler.WorkInfo): WorkHandler | undefined {
    return this.workHandlers.find((workHandler) => {
      return workHandler.canHandle(workInfo);
    });
  }
}