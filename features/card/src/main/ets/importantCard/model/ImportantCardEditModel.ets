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

import { EventMode, ImportantCardConfig } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { CommonInnerEvent, Log, ThrottleFunction } from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { ImportantEntity } from './ImportantEntity';
import { DataSource } from '../DataSource';
import { ImportantCardModel } from './ImportantCardModel';

const TAG: string = 'ImportantCardEditModel';

/**
 * 重要日卡片编辑数据模型
 */
export class ImportantCardEditModel {
  private dataModel: ImportantCardModel = new ImportantCardModel();

  private formConfig?: ImportantCardConfig;

  // 处理系统时间变化
  private timeChangeHandler: () => void = (): void => {
  };

  private importantChangedListener?: (entity: ImportantEntity | undefined) => void;

  init() {
    this.timeChangeHandler = (): void => {
      ThrottleFunction.instance().throttle(TAG + 'time', (): void => {
        // 系统时间改变后需要重新计算
        this.loadData();
      }, 200);
    }
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.timeChangeHandler);
  }

  unInit() {
    emitter.off(CommonInnerEvent.SYSTEM_TIME_CHANGED, this.timeChangeHandler);
  }

  setFormConfig(config: ImportantCardConfig): void {
    this.formConfig = config;
    if (this.formConfig) {
      this.dataModel.bindMode(config.eventMode);
    }
  }

  updateFormConfig(config: ImportantCardConfig): void {
    if (this.formConfig) {
      ImportantCardConfig.setFixedEventIds(this.formConfig, config.fixedEventIds);
      this.formConfig.eventMode = config.eventMode;
      this.formConfig.eventTitle = config.eventTitle;
      this.formConfig.importantType = config.importantType;
      this.dataModel.bindMode(config.eventMode);
    }
  }

  public listenImportantChange(listener: (entity: ImportantEntity | undefined) => void) {
    this.importantChangedListener = listener;
  }

  public async loadData() {
    Log.info(TAG, `loadData start: ${this.formConfig?.eventMode}, ${this.formConfig?.fixedEventIds}`);
    const fixedEventIds = this.formConfig?.fixedEventIds ?? [];
    const hasFixedId: boolean = fixedEventIds && fixedEventIds.length > 0 && fixedEventIds[0] > 0;
    if (this.formConfig?.eventMode === EventMode.RECENT_HOLIDAY) {
      this.dataModel.updateRecentHoliday(await DataSource.queryRecentHoliday());
    } else if (this.formConfig?.eventMode === EventMode.FIXED_IMPORTANT && hasFixedId) {
      this.dataModel.updateFixedImportant(await DataSource.queryFixedImportant(this.formConfig.fixedEventIds));
    } else if (this.formConfig?.eventMode === EventMode.FIXED_BIRTHDAY && hasFixedId) {
      this.dataModel.updateFixedBirthday(await DataSource.queryFixedBirthday(this.formConfig.fixedEventIds));
    } else if (this.formConfig?.eventMode === EventMode.FIXED_HOLIDAY && hasFixedId) {
      this.dataModel.updateFixedHoliday(await DataSource.queryFixedHoliday(this.formConfig.fixedEventIds));
    } else {
      Log.warn(TAG, 'loadData in default mode');
    }
    this.calculateShowEvent();
    Log.info(TAG, 'loadData done');
  }

  public updateSelectFromConfig(config: ImportantCardConfig): void {
    if (!config) {
      Log.warn(TAG, `updateSelectFromConfig get invalid param`);
      return;
    }
    Log.info(TAG, `updateSelect to ${config.fixedEventIds}, ${config.eventMode}`);
    this.updateFormConfig(config);
    this.loadData();
  }

  /**
   * 计算需要展示的重要日
   */
  private calculateShowEvent() {
    const entity = this.dataModel.getShowImportantEntity();
    this.notifyChange(entity ?? undefined);
  }

  private notifyChange(entity: ImportantEntity | undefined): void {
    if (this.importantChangedListener) {
      this.importantChangedListener(entity);
    }
  }
}