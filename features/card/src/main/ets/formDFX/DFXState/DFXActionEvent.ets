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

/**
 * 卡片DFX 状态传递的字段
 */
export class DFXActionEvent {
  private _actionType: ActionType = ActionType.NORMAL;
  private _recordTime: number | undefined;

  public set actionType(actionType: ActionType) {
    this._actionType = actionType;
  }

  public get actionType() {
    return this._actionType;
  }

  public set recordTime(recordTime: number | undefined) {
    this._recordTime = recordTime;
  }

  public get recordTime() {
    if (this._recordTime === undefined) {
      throw new Error('RecordTime is Undefined.');
    }
    return this._recordTime;
  }
}


/**
 * 记录卡片正在执行的动作
 */
export enum ActionType {
  ERROR = 0, // 卡片上的 错误场景
  NORMAL = 1, // 卡片上的 普通行为记录
  ACTION = 2, // 卡片上的 交互行为记录
  DATA = 3, // 卡片上的 数据刷新记录
}
