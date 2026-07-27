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
import { DFXContext } from './DFXContext';
import AbilityState from './DFXState/AbilityState';
import { ActionType, DFXActionEvent } from './DFXState/DFXActionEvent';
import { FormRecord } from './DFXState/DFXFormRecord';
import { DFXState } from './DFXState/DFXState';

/**
 * 卡片DFX状态机的接口
 */
export default class DFXFrame implements DFXContext {
  // 当前的状态
  private state: DFXState;
  // 当前卡片被记录的状态
  private curRecord: FormRecord;

  constructor() {
    this.state = AbilityState.getInstance();
    this.curRecord = new FormRecord();
  }

  getState(): DFXState {
    return this.state
  }

  public recordMsg(action: DFXActionEvent): boolean {
    if (action.actionType === ActionType.ERROR) {
      this.state.handleError(this);
    } else if (action.actionType === ActionType.NORMAL) {
      this.state.handleNormalEvent(this);
    } else if (action.actionType === ActionType.ACTION) {
      this.state.handleAction(this);
    } else if (action.actionType === ActionType.DATA) {
      this.state.handleDataRefresh(this);
    }
    return true;
  }

  changeState(state: DFXState): void {
    this.state = state
  }
}