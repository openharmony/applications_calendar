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

import { AgendaEventInfo, SingleInstanceHelper, } from '@app/common';

/**
 * 用于存放冷启过程中的三个月的日程数据（上个月，当月，下个月）
 */
export class MonthlyViewTemporaryAgendaData {
  public agendaList: Array<AgendaEventInfo[]> = []; // 存放缓存数据
  public flagList: Array<boolean> = [false, false, false]; // 标识数据是否查询完成（0：上个月，1：当前月，2：下个月）
  public notUseCache: boolean = false; // true:不使用该类中的缓存
  public cnt: number = 0; // 标记agendaList被使用的次数，使用三次后表示冷启过程中agendaList已被使用，后续不从该缓存中取数据

  static getInstance(): MonthlyViewTemporaryAgendaData {
    return SingleInstanceHelper.createOrGet(MonthlyViewTemporaryAgendaData, 'MonthlyViewTmp');
  }

  // 提供一个方法供外部等待标志位
  public waitForReady(index: number): Promise<void> {
    return new Promise((resolve) => {
      const checkReady = () => {
        if (this.flagList[index]) {
          resolve();
        } else {
          setTimeout(checkReady, 10); // 每 10ms 检查一次
        }
      };
      checkReady();
    });
  }

  /**
   * 回收内存空间
   * @param index
   */
  public recycleData(index: number) {
    const tmp = MonthlyViewTemporaryAgendaData.getInstance();
    const flagList = tmp.flagList;
    if (index < flagList.length) {
      tmp.agendaList[index].length = 0;
    }
  }

  public cntPlus() {
    const tmpAgendaData = MonthlyViewTemporaryAgendaData.getInstance();
    if (!tmpAgendaData.notUseCache) {
      tmpAgendaData.cnt += 1;
      if (tmpAgendaData.cnt >= 3) { // 超过三次设置不再使用缓存
        tmpAgendaData.notUseCache = true;
      }
    }
  }
}

