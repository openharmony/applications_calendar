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

import { LightWeightMap } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import { CommonEventHubCode } from '../event/CommonInnerEvent';
import { EmptyUtils } from '../util/EmptyUtils';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'AgendaAbilityManager';

/**
 * 相关代码：日程ability管理类
 */
export class AgendaAbilityManager {
  private readonly agendaAbilityMap: LightWeightMap<string, common.UIAbilityContext> = new LightWeightMap();

  public static getInstance(): AgendaAbilityManager {
    return SingleInstanceHelper.createOrGet(AgendaAbilityManager, TAG);
  }

  // 注册新ability
  public registerAgendaContext(key: string, context: common.UIAbilityContext): void {
    this.agendaAbilityMap.set(key, context)
  }

  // 注销ability
  public unRegisterAgendaContext(key: string): void {
    if (EmptyUtils.isEmptyString(key, true)) {
      return;
    }

    if (this.agendaAbilityMap.hasKey(key)) {
      this.agendaAbilityMap.remove(key);
    }
  }

  // 获取eventId对应的context
  public getAgendaContext(key: string): common.UIAbilityContext {
    return this.agendaAbilityMap.get(key);
  }

  // 退出页面销毁context并注销ability
  public exitAgendaContext(key: string): void {
    if (!this.agendaAbilityMap.hasKey(key)) {
      return;
    }
    const context = this.agendaAbilityMap.get(key);
    this.agendaAbilityMap.remove(key);
    if (!context) {
      return;
    }
    context.eventHub.off(CommonEventHubCode.EVENT_UPDATE_AGENDA_NEW_PAGE);
    context.terminateSelf();
  }

  /**
   *  通过eventId启动一个新的日程ability
   * @param eventId 日程id
   * @param begin 日程开始时间
   * @param end 日程结束时间
   * @param isHoliday 是否为本地节假日,本地节假日为本地封装故eventId为-1无法查询日程,需要额外处理
   * @param holidayTitle 本地节假日的标题
   */
  public startAbilityByEventId(eventId: number, begin: number, end: number, isHoliday: boolean = false,
    holidayTitle: string = '') {
    let nowContext = GlobalThis.getInstance().mainAbilityContext;
    // 判断当前context是否存在及已经销毁
    if (!nowContext || nowContext.isTerminating()) {
      nowContext = GlobalThis.getInstance().context;
    }
    if (!nowContext || nowContext.isTerminating()) {
      Log.error(TAG, `Start Agenda Ability Error No Context`);
      return;
    }
    // 拼装key值,用于ability的拉起,同样的key值会拉起同一个ability
    const key = isHoliday ? holidayTitle : eventId.toString();
    let wantInfo: Want = {
      bundleName: 'com.openharmony.calendar',
      abilityName: 'AgendaAbility',
      parameters: {
        instanceKey : key,
        // 自定义信息
        eventId: eventId,
        instanceStartMills: begin,
        instanceEndMills: end,
        isHoliday: isHoliday,
        holidayTitle: holidayTitle,
      },
    };
    try {
      Log.info(TAG, `start agenda window`);
      nowContext.startAbility(wantInfo).then(() => {
        Log.info(TAG, `start agenda window success`);
      }).catch((err: BusinessError) => {
        Log.logErrorMsg(TAG, `Start Agenda Ability Inner Error`, err);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, `Start Agenda Ability Error`, err);
    }
  }
}