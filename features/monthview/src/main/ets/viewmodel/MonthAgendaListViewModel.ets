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
import { AgendaEventInfo, DateInfo, GlobalData, GlobalDataKeys, Log } from '@app/common';
import { SlidingStackHelper } from '../utils/SlidingStackHelper';
import { SingleMonthAgendaManager } from './SingleMonthAgendaManager';

const TAG: string = '[MonthlyView][AgendaView]';

@Observed
export class MonthAgendaListViewModel {
  // 当月视图的选中时间（由于规格问题，存在系统选中时间和视图选中时间不一致的情况（当前需要在其他月份有默认选中态（当月一号）））
  public selectDate: DateInfo = new DateInfo();
  // 日程列表内是否初始化
  public isTodayAgendaReady: boolean = true;
  // 日程列表内是否存在日程
  public isTodayAgendaExist: boolean = true;

  public slidingStackHelper?: SlidingStackHelper;
  // 当前此视图绑定的 VM 在数组内的索引
  public arrayIndex: number | undefined = 0;

  public canScroll: boolean = false;

  public isWeekShow: boolean = false; // 是否处于周视图状态
  // 单月视图绑定的日程管理员
  public sigAgendaManager: SingleMonthAgendaManager;

  private _agendaScroller = new Scroller(); // 日程列表的滚动控制
  // 获取日程列表绑定的listScroll参数
  get agendaScroller(): Scroller {
    return this._agendaScroller;
  }

  // 通知绑定的视图页面刷新日程列表视图
  public onIsTodayAgendasChange = (isTodayAgendaExist: boolean, isTodayAgendaReady: boolean) => {
  }

  constructor(sigAgendaManager: SingleMonthAgendaManager, arrayIndex: number | undefined) {
    this.sigAgendaManager = sigAgendaManager;
    this.arrayIndex = arrayIndex ?? 0;
  }

  /**
   * 刷新日程数量及计算已过期日程数量，需要在各种日程变更时触发：日程增删改时均需要触发
   * @returns
   */
  refreshAgendaCounts(tag: string) {
    Log.info(TAG, 'refreshAgendaCounts by ' + tag);
    let count = 0;
    const currentTime = Date.now();
    // 自动折叠只折叠到第一个未过期的日程
    for (let i = 0; i < this.sigAgendaManager.normalAgendaDataSources.totalCount(); i++) {
      const agenda = this.sigAgendaManager.normalAgendaDataSources.getData(i);
      if (agenda && agenda.mEnd > currentTime) {
        count = i;
        break;
      }
    }
    // 刷新需折叠的过期日程数
    this.slidingStackHelper?.changeExpiredNums(count);
    // 刷新总日程数
    this.slidingStackHelper?.refreshNums([this.sigAgendaManager.normalAgendaDataSources.totalCount(),
      this.sigAgendaManager.importantAgendaDataSources.totalCount()]);
  }


  updateScrollToTop() {
    Log.info(TAG, 'updateScrollToTop');
    const displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE);
    const currentDate = GlobalData.instance().get(GlobalDataKeys.CURRENT_DATE);
    this.refreshAgendaCounts('updateScrollToTop');
    if (displayDate === currentDate) {
      // 滚动到过期卡片位置
      this.slidingStackHelper?.scrollToExpired();
    } else {
      this.slidingStackHelper?.scrollToTop();
    }
  }

  /**
   * 处理当月的日程信息变化
   */
  onAgendaChange(agendaResult: AgendaEventInfo[]) {
    // 变更选中时间的日程列表
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
    // 变更每周的日程列表
    this.sigAgendaManager.onSigWeekAgendaChange(agendaResult);

    // 触发月视图日程标点显示刷新
    this.sigAgendaManager.onInstancesFlagsChange(agendaResult);

    this.sigAgendaManager.onFestivalsChange(agendaResult);
  }
}
