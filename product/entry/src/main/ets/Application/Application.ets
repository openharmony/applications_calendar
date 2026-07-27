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

import {
  CalendarLayoutManager,
  I18nUtil,
  Log,
  PreferencesFiles,
  ServiceManager,
  ServiceGlobalEnv,
  GlobalThis,
  DeviceConfig,
  GlobalData,
  EmptyUtils,
  DBUtils,
} from '@app/common';

import { Configuration } from '@ohos.app.ability.Configuration';
import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { AbilityConstant, AbilityStage, contextConstant, Want } from '@kit.AbilityKit';
import { ServiceEnvEvent } from '@app/common/src/main/ets/service/framework/ServiceConsts';
import { g_serviceConfig } from '../config/GlobalServiceConfig';
import { uri } from '@kit.ArkTS';
import { EmitterFormHandler } from '../pages/EmitterFormHandler';
import { ProxyDBUtils } from '@app/common/src/main/ets/dao/ProxyDBUtils';
import { NetConnectionUtil, NetWorkManger } from '@app/service.network';
import { DBInitializeInterceptor } from '@app/common/src/main/ets/commoncapability/init/DBInitializeInterceptor';

const TAG = 'CalendarApplication';

/**
 * Application 提供全局context
 */
export default class Application extends AbilityStage {
  // 注册订阅系统环境变化的ID
  private callbackId: number = 0;

  // 用于区分是否创建ability还是走onNewWant唤起ability 的校验
  onAcceptWant(want: Want): string {
    // 在被调用方的AbilityStage中，针对启动模式为specified的UIAbility返回一个UIAbility实例对应的一个Key值
    if (want.abilityName === 'AgendaAbility') {
      // 返回的字符串KEY标识为自定义拼接的字符串内容
      let instanceKey = String(want.parameters?.instanceKey ?? '');
      if (EmptyUtils.isEmptyString(instanceKey, true)) {
        instanceKey = this.assembleParameter(want);
      }
      Log.info(TAG, `jump to agenda ability ${instanceKey}`);
      return `AgendaAbilityInstance_${instanceKey}`;
    }
    // 默认单例
    return want.abilityName ?? 'Application';
  }

  // 存在uri即通知跳转时拼装打开日程详情子窗参数
  assembleParameter(want: Want): string {
    let instanceKey = '';
    if (!want?.uri || EmptyUtils.isEmptyString(want?.uri, true)) {
      Log.info(TAG, `want uri is empty`);
      return instanceKey;
    }
    try {
      const agendaUri: uri.URI = new uri.URI(want?.uri);
      // calendarDate 通知里的uri 的协议格式
      if ('calendar' != agendaUri.scheme || 'com.openharmony.calendar' != agendaUri.host) {
        Log.info(TAG, `want uri scheme or host is fail`);
        return instanceKey;
      }
      const urlParams: string[] = agendaUri.query.split('&');
      const jumpParam: Record<string, number | string> = {};
      // 从uri分割的urlParams中拼装跳转用参数放入jumpParam中
      EmitterFormHandler.instance().parseJumpEventDetailParams(urlParams, jumpParam);
      instanceKey = `${jumpParam.id ?? ''}`;

    } catch (err) {
      Log.hilogError(TAG, `checkUriErr`, err)
    }
    return instanceKey;
  }

  onCreate() {
    Log.log(TAG, "Application onCreate");
    this.context.area = contextConstant.AreaMode.EL2;
    GlobalThis.getInstance().abilityStageContext = this.context;
    PreferencesUtil.init(this.context);
    DeviceConfig.instance().init();
    CalendarLayoutManager.getInstance().init();
    NetWorkManger.getInstance().init();
    GlobalData.instance().init();
    ServiceManager.getInstance().init(g_serviceConfig);
    I18nUtil.initSelfOnce();
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.ABILITY_STAGE_CREATE);
    DBUtils.INSTANCE.setInitializeInterceptor(new DBInitializeInterceptor());
    ProxyDBUtils.INSTANCE.setInitializeInterceptor(new DBInitializeInterceptor());
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    Log.info(TAG, `onMemoryLevel level: ${level}`);
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.ABILITY_STAGE_MEMORY_LEVEL_CHANGE);
  }

  onConfigurationUpdate(newConfig: Configuration) {
    Log.info(TAG, `newConfig: ${JSON.stringify(newConfig)}`)
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.ABILITY_STAGE_CONFIG_UPDATE);
    I18nUtil.updatePropertyOnConfigurationUpdated(newConfig);
  }

  // Note: onDestroy接口中的日志已经无法打印出来了
  onDestroy() {
    Log.log(TAG, "Application onDestroy");
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.ABILITY_STAGE_DESTROY);
    const applicationContext = this.context.getApplicationContext();
    applicationContext.off('environment', this.callbackId);
    ServiceManager.getInstance().deInit();
    NetConnectionUtil.unSubscribe();
  }
};
