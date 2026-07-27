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

import { CardService } from '@app/common/src/main/ets/service/implements/card/CardService';
import {
  CommonInnerEvent,
  EmitterCollector,
  factory,
  GlobalDataKeys,
  Log,
  PreferencesFiles,
  PreferencesUtil,
  RefreshConfig,
  ServiceEnum
} from '@app/common';
import lazy { MonthCardHandler } from '../controller/MonthCardHandler';
import { emitter } from '@kit.BasicServicesKit';
import { ImportantCardConfig } from '@app/common/src/main/ets/card/ImportantCardConfig';
import lazy { notifyImportantCardRefresh } from '../../importantCard/view/pages/ImportantCardEdit';
import { FormConfigManager } from '@app/common/src/main/ets/card/FormConfigManager';
import { EventIdFinder } from '../../importantCard/EventIdFinder';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { runTaskAsync } from '@app/common/src/main/ets/util/TaskPool';

const TAG = 'CardService';
/**
 * 对外提供服务的实现
 */
@factory(ServiceEnum.CARD_SERVICE)
export class CardServiceImpl extends CardService {

  private emitterCollector = new EmitterCollector;
  /**
   * 刷新单个卡片
   * @param formId
   */
  refreshCard(formId: string): void {
    MonthCardHandler.instance().refreshCards(formId);
  }

  /**
   * 刷新所有卡片
   */
  refreshAllCards(refreshConfig?: RefreshConfig): void {
    MonthCardHandler.instance().refreshCards(undefined, refreshConfig);
  }

  /**
   * 初始化卡片
   */
  initAllCards(): void {
    MonthCardHandler.instance().initAllCards();
  }

  /**
   * 刷新双升单豁免权限
   */
  refreshAllCardsDoubleUpSingleAgreeStatement(): void {
    MonthCardHandler.instance().refreshAllCardsDoubleUpSingleAgreeStatement();
  }

  /**
   * 刷新重要日卡片
   * @param formId 卡片id
   * @param config 重要日卡片配置信息
   */
  refreshImportantCard(
    context: Context,
    formId: string,
    isCard2x2?: boolean | undefined,
    config?: ImportantCardConfig,
    refreshConfig?: RefreshConfig,
  ): void {
    notifyImportantCardRefresh(context, formId, isCard2x2, config, refreshConfig);
  }

  /**
   * 保存重要日配置信息
   * @param formId 卡片id
   * @param formConfig 重要日配置信息
   */
  saveImportantCardConfig(formId: string, formConfig: ImportantCardConfig): void {
    FormConfigManager.saveImportantCardConfig(formId, formConfig);
  }

  /**
   * 克隆、升级场景查找单上对应的eventId
   * @param migrateType 克隆/升级
   * @param fromId 卡片Id
   */
  findEventId(migrateType: number, formId: string): number | undefined {
    return new EventIdFinder().findEventId(migrateType, formId);
  }

  /**
   *   刷新所有含农历卡片
   */
  refreshTermCards(): void {
    MonthCardHandler.instance().refreshTermCards();
  }

  private startOfWeekChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `start_of_week changes to refresh the monthcard`);
    MonthCardHandler.instance().refreshCards();
  };
  private weekendsChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `start_of_week changes to refresh the monthcard`);
    MonthCardHandler.instance().refreshCards();
  };
  private otherCalendarChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `other_calendar changes to refresh the monthcard`);
    this.refreshTermCards();
    MonthCardHandler.instance().refreshCards();
  };
  private chineseFestivalsChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `chinese festivals changes to refresh the monthcard`);
    if (data.data?.code !== 'CN' && data.data?.code !== 'CN_CUSTOM') {
      Log.info(TAG, `festivals changes not need to refresh the monthcard`);
      return;
    }
    this.refreshTermCards();
  };
  private agreeAuthorizedChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `agree_authorized changes to refresh the monthcard`);
    this.initAllCards();
  };

  private systemDateChangeHandler: Callback<emitter.EventData> = () => {
    Log.info(TAG, `systemDateChangeHandler changes to refresh the monthcard`);
    MonthCardHandler.instance().refreshCards();
  };

  /**
   * 清除form_base_info中的脏数据
   */
  private async cleanFormBaseInfoDirtyData() {
    runTaskAsync(deleteDirtyCardInfoTask);
  }

  async doStart(): Promise<void> {
    Log.info(TAG, 'doStart begin');
    // 监听日历设置一周开始日变化
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_START_OF_WEEK }, this.startOfWeekChangeHandler);
    // 监听日历设置周末变化
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_WEEKENDS }, this.weekendsChangeHandler);
    // 监听日历设置其它历法
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_OTHER_CALENDAR }, this.otherCalendarChangeHandler);
    // 监听日历设置中国节假日开关
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_NATIONAL_HOLIDAY }, this.chineseFestivalsChangeHandler);
    // 监听开屏页是否同意授权
    this.emitterCollector.on({ eventId: CommonInnerEvent.AGREE_AUTHORIZED }, this.agreeAuthorizedChangeHandler);
    // 监听内部锁定时区变化导致的日期变化
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.systemDateChangeHandler);
    // 监听系统日期变化，触发桌面卡片刷新
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.systemDateChangeHandler);
    // 监听系统时间变化，触发桌面卡片刷新
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.systemDateChangeHandler);
    this.cleanFormBaseInfoDirtyData();
    Log.info(TAG, 'doStart end');
  }

  async doStop(): Promise<void> {
    Log.info(TAG, 'doStop begin');
    this.emitterCollector.off();
    Log.info(TAG, 'doStop end');
  }
}

@Concurrent
async function deleteDirtyCardInfoTask() {
  FormInfoManager.deleteDirtyCardData();
}
 