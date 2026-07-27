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

import { EventService } from '../dao/service/EventService';
import { AgendaEventInfo } from '../agenda/AgendaEventInfo';
import { Log } from '../default/common/Log';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';
import { AbilityConstant, common } from '@kit.AbilityKit';
import { maskString } from '../util/SensitiveStrUtils';

const TAG = 'appContinueManager';

export class PageParam {
  public pageName = '';
  public event: AgendaEventInfo | undefined = undefined;
  public calendarType = '';
}

export enum ContinueParam {
  continuePageName = 'continuePageName',
  continueEventUUID = 'continueEventUUID',
  continueAccountSync = 'continueAccountSync'
}

export enum ContinueType { // 接续类型,区分发送端和接收端
  SEND, // 发送端
  RECEIVE // 接收端
}

export class AppContinueManager {
  private map: Map<string, PageParam[]> = new Map();
  private static CONTINUE_PAGE = 'continue_page';

  public static getInstance() {
    return SingleInstanceHelper.createOrGet(AppContinueManager, TAG);
  }

  // 设置是否启用接续
  public setAppContinueState(enable: boolean, context: common.UIAbilityContext) {
    let param = enable ? AbilityConstant.ContinueState.ACTIVE : AbilityConstant.ContinueState.INACTIVE;
    context.setMissionContinueState(param, (err) => {
      Log.info(TAG, `setAppContinue ${enable} result: ${err.message}`);
    })
    return true;
  }

  // 获取当前 CONTINUE PAGE 的栈顶
  public getContinuePage(type: ContinueType = ContinueType.SEND): PageParam | undefined {
    if (this.map.has(this.getContinueMapName(type))) {
      let continuePageArr = this.map.get(this.getContinueMapName(type));
      if (!continuePageArr) {
        return undefined;
      }
      Log.info(TAG, `getContinuePage ${continuePageArr[0]?.pageName}`);
      return continuePageArr.length > 0 ? continuePageArr[0] : undefined;
    }
    return undefined;
  }

  // CONTINUE PAGE 入栈
  public async addContinuePage(param: PageParam, type: ContinueType = ContinueType.SEND) {
    Log.info(TAG, `addContinuePage ${param.pageName}`);
    Log.info(TAG, `addContinuePage mId:${param?.event?.mId} uuid:${maskString(param.event?.uuid)}`);
    let continuePageArr = this.map.get(this.getContinueMapName(type));
    if (!continuePageArr) {
      Log.info(TAG, `addContinuePage no CONTINUE_PAGE`);
      this.map.set(this.getContinueMapName(type), [param]);
      return
    }
    // 静默查询时没有UUID
    if (param.event?.uuid.length == 0) {
      param.event.uuid = (await EventService.INSTANCE.queryEventById(param.event.mId)).uuid;
    }
    let index = continuePageArr.findIndex(page => {
      return page.event?.uuid === param.event?.uuid
    })
    // update
    if (index >= 0) {
      Log.info(TAG, `addContinuePag updated`);
      continuePageArr.splice(index, 1, param)
      return;
    }
    // push front
    Log.info(TAG, `addContinuePag inserted`);
    continuePageArr.splice(0, 0, param);
    this.map.set(this.getContinueMapName(type), continuePageArr);
  }

  // 在 CONTINUE PAGE 中 移除pageName
  public removeContinuePage(pageName: string, type: ContinueType = ContinueType.SEND) {
    Log.info(TAG, `removeContinuePage ${pageName}`);
    if (this.map.has(this.getContinueMapName(type))) {
      let continuePageArr = this.map.get(this.getContinueMapName(type));
      if (!continuePageArr) {
        return;
      }
      continuePageArr = continuePageArr.filter(page => page.pageName != pageName);
      this.map.set(this.getContinueMapName(type), continuePageArr);
    }
  }

  private getContinueMapName(type: ContinueType) {
    return `${AppContinueManager.CONTINUE_PAGE}-${type}`;
  }
}