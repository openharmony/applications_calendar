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

import { TaskState } from '../core/BaseProcessor';

/**
 * 请求参数
 */
export class Request {
  public readonly jobId: number;
  protected mStatus: TaskState = TaskState.STATE_WAITING;

  public constructor(status: TaskState, jobId: number) {
    this.mStatus = status;
    this.jobId = jobId;
  }

  /**
   * 设置状态
   *
   * @param status 状态
   * @see ProcessorBase#STATE_WAITING
   * @see ProcessorBase#STATE_RUNNING
   * @see ProcessorBase#STATE_FAILED
   * @see ProcessorBase#STATE_SUCCESS
   * @see ProcessorBase#STATE_WAITING_CANCELLED
   * @see ProcessorBase#STATE_RUNNING_CANCELLED
   */
  public setStatus(status: TaskState) {
    this.mStatus = status;
  }

  /**
   * 获取状态
   *
   * @return 状态
   */
  public getStatus(): TaskState {
    return this.mStatus;
  }

  /**
   * 是否waiting状态
   *
   * @return 是否waiting状态
   */
  public isWaiting(): boolean {
    return this.mStatus == TaskState.STATE_WAITING;
  }

  /**
   * 状态是否一致
   *
   * @param status 状态
   * @return 是否一致
   */
  public isInSuchState(status: TaskState): boolean {
    return this.mStatus == status;
  }

  public isCanceled(): boolean {
    return this.mStatus == TaskState.STATE_CANCELLED;
  }
}