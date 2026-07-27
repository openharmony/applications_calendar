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

import { ImportantCardConfig, ImportantCardConfig2x2, ImportantCardConfig2x4, LayoutId } from './ImportantCardConfig';
import { getLatestStorage, getStorage } from './CardStorage';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import data_preferences from '@ohos.data.preferences';
import { maskString } from '../util/SensitiveStrUtils';

const IMPORTANT_CONFIG: string = 'important_card_config';
const TAG: string = 'FormConfigManager';

/**
 * 卡片配置缓存管理工具类
 */
class FormConfigManager {
  /**
   * 根据卡片ID获取重要日卡片配置
   *
   * @param formId 卡片ID
   * @returns 卡片配置
   */
  static getImportantCardConfig(formId: string, isCard2x2?: boolean): ImportantCardConfig {
    Log.info(TAG, `getImportantCardConfig: formId: ${formId} isCard2x2: ${isCard2x2}`);
    const abilityStageContext = GlobalThis.getInstance().abilityStageContext;
    if (abilityStageContext) {
      data_preferences.removePreferencesFromCacheSync(abilityStageContext, IMPORTANT_CONFIG);
    }
    let config: ImportantCardConfig | undefined = getLatestStorage(IMPORTANT_CONFIG).get(`${formId}`);
    let defaultConfig = isCard2x2 ? new ImportantCardConfig2x2(formId) : new ImportantCardConfig2x4(formId);

    // 卡片加桌，首次取默认值
    // 同时存入formName，用于卡片编辑区分
    if (!config) {
      Log.info(TAG, `getImportantCardConfig: config is null`);
      return defaultConfig;
    }

    // 枚举值取默认配置项，无需刷新
    const useDefaultKeys = ['supportLayoutIds'];
    // 版本升级，字段增改，需做兼容更新
    const isKeysChanged = Object.keys(config).length != Object.keys(defaultConfig).length;
    // 单双克隆，首次获取ImportantCardConfig存入SP，枚举类值为空；加桌获取2x2或2x4需更新
    const isUpdateEnumValue = FormConfigManager.isUpdateEnumValue(defaultConfig, config, useDefaultKeys);
    if (isKeysChanged || isUpdateEnumValue) {
      // 编辑页面加载，无法区分isCard2x2
      // 需根据config?.formName重新获取默认配置项
      if (isCard2x2 === undefined && config?.formName) {
        if (config?.formName === 'ImportantCardView2x2') {
          defaultConfig = new ImportantCardConfig2x2(formId);
        } else if (config?.formName === 'ImportantCardView2x4') {
          defaultConfig = new ImportantCardConfig2x4(formId);
        }
      }

      return FormConfigManager.updateConfig(defaultConfig, config, useDefaultKeys)
    }
    Log.info(TAG, `getImportantCardConfig: formId: ${formId} formName: ${config.formName}`);
    return config;
  }

  static updateConfig(
    defaultConfig: ImportantCardConfig,
    config: ImportantCardConfig,
    useDefaultKeys: string[]
  ): ImportantCardConfig {
    const configKeys = Object.keys(config);
    const defaultConfigKeys = Object.keys(defaultConfig);

    for (const key of defaultConfigKeys) {
      // 过滤掉强制使用defaultConfig的key
      // 旧的supportLayoutIds只有左右，新的为左中右，无需更新
      if (!useDefaultKeys.includes(key) && configKeys.includes(key)) {
        Reflect.set(defaultConfig, key, Reflect.get(config, key));
      }
    }

    FormConfigManager.adaptFixedEventId(defaultConfig);

    // 版式不匹配，需取默认值
    if (!Reflect.get(defaultConfig, 'supportLayoutIds').includes(defaultConfig.layoutId)) {
      if (defaultConfig?.formName === 'ImportantCardView2x2') {
        Reflect.set(defaultConfig, 'layoutId', LayoutId.CENTER);
      } else {
        Reflect.set(defaultConfig, 'layoutId', LayoutId.LEFT);
      }
    }

    Log.info(TAG, `updateConfig: newConfig`);
    return defaultConfig;
  }

  /**
   * 兼容历史单框架配置数据，迁移到新配置
   * 兼容单框架配置数据，克隆回老版本单框架设备
   * 目标：fixedEventIds和eventIds保持一致
   *
   * @param config 待处理配置数据
   */
  private static adaptFixedEventId(config: ImportantCardConfig): void {
    let hasFixEventIds: boolean = config.fixedEventIds && config.fixedEventIds.length > 0;
    if (hasFixEventIds) {
      // 清理历史数组中可能存在的脏数据（null/undefined）
      let purityFixedIds: number[] = [];
      config.fixedEventIds.forEach((id: number) => {
        if (id) {
          purityFixedIds.push(id);
        }
      });
      config.fixedEventIds = purityFixedIds;
      hasFixEventIds = config.fixedEventIds && config.fixedEventIds.length > 0;
    }

    let hasEventIds: boolean = config.eventIds && config.eventIds.length > 0;
    if (hasEventIds) {
      // 清理历史数组中可能存在的脏数据（null/undefined）
      let purityEventIds: number[] = [];
      config.eventIds.forEach((id: number) => {
        if (id) {
          purityEventIds.push(id);
        }
      });
      config.eventIds = purityEventIds;
      hasEventIds = config.eventIds && config.eventIds.length > 0;
    }

    if (hasFixEventIds && !hasEventIds) {
      // 如果fixedEventIds有值，eventIds无值，将fixedEventIds的值同步给eventIds
      config.eventIds = config.fixedEventIds;
    } else if (!hasFixEventIds && hasEventIds) {
      // 如果fixedEventIds无值，eventIds有值，将eventIds的值同步给fixedEventIds
      config.fixedEventIds = config.eventIds;
    } else {
      // 两者有无值状态相同，以fixedEventIds为准
      config.eventIds = config.fixedEventIds;
    }
  }

  static isUpdateEnumValue(oldConfig: ImportantCardConfig, newConfig: ImportantCardConfig, enumKeys: string[]) {
    let isUpdateEnumValue = false;
    for (let key of Object.keys(newConfig)) {
      // 比较枚举值是否相同，不同则有更新
      // 如：左右 =>左中右
      if (enumKeys.includes(key)) {
        const oldVal = JSON.stringify(Reflect.get(oldConfig, key));
        const newVal = JSON.stringify(Reflect.get(newConfig, key));
        if (oldVal !== newVal) {
          isUpdateEnumValue = true;
          break;
        }
      }
    }

    return isUpdateEnumValue;
  }

  /**
   * 持久化保存重要日卡片配置
   *
   * @param formId 卡片ID
   * @param config 卡片配置
   */
  static saveImportantCardConfig(formId: string, config: ImportantCardConfig): void {
    Log.info(TAG, `saveImportantCardConfig formId: ${formId} is set eventId:${config.fixedEventIds}`);
    getStorage(IMPORTANT_CONFIG).set(`${formId}`, config);
  }

  }

export {
  FormConfigManager
}