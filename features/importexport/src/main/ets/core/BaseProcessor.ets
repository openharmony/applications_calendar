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

import { Log } from '@app/common/index';
import { Request } from '../import/Request';
import common from '@ohos.app.ability.common';

export enum ShareIntentType {
  IMPORT_TYPE = 1,
  EXPORT_TYPE = 2,
}


export enum TaskState {
  // 构建了请求,还没开始执行,在等待
  STATE_WAITING,
  // 正在执行
  STATE_RUNNING,
  // 失败
  STATE_FAILED,
  // 成功
  STATE_SUCCESS,
  // 任务被取消
  STATE_CANCELLED
}


/*
 * BaseProcessor 支持取消
 */
const TAG = 'BaseProcessor'

export abstract class BaseProcessor {
  /**
   * waiting state
   */
  protected mStatus: TaskState = TaskState.STATE_WAITING;
  /**
   * context
   */
  protected mContext: common.UIAbilityContext | null = null;
  /**
   * job id
   */
  protected mJobId: number = 0;
  /**
   * job id
   */
  protected mRequest: Request | undefined;

  /**
   * run
   */
  public abstract run(): Promise<boolean>;

  /**
   * judgment is cancel
   *
   * @param isMayInterruptIfRunning can interrupt if run
   * @return is cancel
   */
  public cancel(isMayInterruptIfRunning: boolean): boolean {
    if (!this.isSupportCancel()) {
      Log.info(TAG, `cancel not support`);
      return false;
    }
    if (this.mStatus == TaskState.STATE_WAITING || this.mStatus == TaskState.STATE_RUNNING) {
      this.mStatus = TaskState.STATE_CANCELLED;
      this.setRequestStatus(TaskState.STATE_CANCELLED);
      this.onTaskCanceled();
      Log.info(TAG, `cancel success`);
      return true;
    }
    Log.warn(TAG, `cancel not support for taskState is ${this.mStatus}`);
    return false;
  }

  protected onTaskCanceled(): void {

  }

  public isCancelled(): boolean {
    return this.mStatus == TaskState.STATE_CANCELLED;
  }

  /**
   * judgment is done
   *
   * @return is done
   */
  public isDone(): boolean {
    return this.mStatus == TaskState.STATE_SUCCESS || this.mStatus == TaskState.STATE_FAILED;
  };

  /**
   * judgment is waiting state
   *
   * @param state waiting state
   * @return is waiting state
   */
  public isWaitingState(): boolean {
    return this.mStatus == TaskState.STATE_WAITING;
  };

  /**
   * set request status
   *
   * @param status request status
   */
  public setRequestStatus(status: TaskState) {
    this.mRequest?.setStatus(status);
  };

  public isSupportCancel(): boolean {
    return true;
  };

  public isAfterState(status: TaskState): boolean {
    return this.mStatus > status;
  };

  public isAtLeastState(status: TaskState): boolean {
    return this.mStatus >= status;
  };

  public getJobId(): number {
    return this.mJobId;
  }

  public isCanDoOtherTask(): boolean {
    return true;
  }

  /**
   * get type
   *
   * @return type
   */
  protected abstract getType(): number;

  /**
   * get import type
   *
   * @return import type
   */
  protected abstract isImportType(): boolean;
}