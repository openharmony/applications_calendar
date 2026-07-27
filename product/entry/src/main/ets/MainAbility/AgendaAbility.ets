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

import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import {
  AgendaAbilityManager,
  AgendaEventInfo,
  CommonEventHubCode,
  DeviceConfig,
  EmptyUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  traceEvents
} from '@app/common';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { display } from '@kit.ArkUI';
import { EmitterFormHandler } from '../pages/EmitterFormHandler';
import { uri } from '@kit.ArkTS';

const TAG: string = 'AgendaAbility';

/**
 * PC多实例日程详情ability
 */
export default class AgendaAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage();
  private key: string = ''; // 用于跳转ability的key值,不同的ability key值正常不相等

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam);
    Log.info(TAG, `onCreate new AgendaAbility`);

    GlobalData.instance().initLanguageAndDate(false);

    this.checkAndSetContext();

    if (!this.checkAndSetParameter(want)) {
      this.context.terminateSelf();
      return;
    }
    this.storage.setOrCreate('uiAbilityContext', this.context);

    AgendaAbilityManager.getInstance().registerAgendaContext(this.key, this.context);
  }


  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onNewWant(want, launchParam)
    try {
      Log.info(TAG, `onNewWant AgendaAbility`);
      this.checkAndSetContext();

      if (!this.checkAndSetParameter(want)) {
        this.context.terminateSelf();
        return;
      }
      this.storage.setOrCreate('uiAbilityContext', this.context);

      const updateInfo = this.getAgendaInfoForEventHub();

      // 发送context广播
      this.context.eventHub.emit(CommonEventHubCode.EVENT_UPDATE_AGENDA_NEW_PAGE, updateInfo);

    } catch (err) {
      Log.logErrorMsg(TAG, 'onNewWant want stringify error', err);
    }
  }

  // 因日程查询需要context,在context为空时需要注册
  checkAndSetContext() {
    if (GlobalThis.getInstance().context === null) {
      GlobalThis.getInstance().context = this.context;
    }
    if (GlobalThis.getInstance().mainAbilityContext === null) {
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
      GlobalThis.getInstance().mainAbilityContext = this.context;
    }
  }

  checkAndSetParameter(want: Want): boolean {
    const parameter = want.parameters;
    let eventId: number = -1;
    let instanceStartMills: number = -1;
    let instanceEndMills: number = -1;
    let isHoliday: boolean = false;
    let holidayTitle: string = '';
    let instanceKey: string = '';
    // 先判断是否能从uri获取跳转参数
    if (this.checkUriParameter(want)) {
      return true;
    }
    if (!parameter) {
      Log.error(TAG, 'onCreate parameter is null')
      return false;
    }

    try {
      eventId = Number(parameter['eventId']);
      if (isNaN(eventId)) {
        throw new Error(`invalid parameter eventId ${parameter['eventId']}`);
      }
      instanceStartMills = Number(parameter['instanceStartMills']);
      if (isNaN(instanceStartMills)) {
        throw new Error(`invalid parameter instanceStartMills ${parameter['instanceStartMills']}`);
      }
      instanceEndMills = Number(parameter['instanceEndMills']);
      if (isNaN(instanceEndMills)) {
        throw new Error(`invalid parameter instanceEndMills ${parameter['instanceEndMills']}`);
      }
      isHoliday = Boolean(parameter['isHoliday']);
      holidayTitle = String(parameter['holidayTitle']);
      instanceKey = String(parameter['instanceKey']);
    } catch (err) {
      Log.logErrorMsg(TAG, `onCreate error`, err);
      return false;
    }
    if (eventId === -1 && !isHoliday) {
      return false;
    }

    this.key = instanceKey;
    if (EmptyUtils.isEmptyString(this.key, true)) {
      return false;
    }

    this.storage.setOrCreate('editing_eventId', eventId);
    this.storage.setOrCreate('editing_context', this.context);
    this.storage.setOrCreate('editing_instanceStartMills', instanceStartMills);
    this.storage.setOrCreate('editing_instanceEndMills', instanceEndMills);
    this.storage.setOrCreate('editing_isHoliday', isHoliday);
    this.storage.setOrCreate('editing_holidayTitle', holidayTitle);
    this.storage.setOrCreate('editing_instanceKey', instanceKey);
    return true;
  }

  // 拼装更新用AgendaEventInfo参数
  getAgendaInfoForEventHub(): AgendaEventInfo {
    const agendaInfo: AgendaEventInfo = new AgendaEventInfo();
    agendaInfo.mId = this.storage.get<number>('editing_eventId') ?? -1;
    agendaInfo.mBegin = this.storage.get<number>('editing_instanceStartMills') ?? -1;
    agendaInfo.mEnd = this.storage.get<number>('editing_instanceEndMills') ?? -1;
    agendaInfo.mIsHoliday = this.storage.get<boolean>('editing_isHoliday') ?? false;
    agendaInfo.mTitle = this.storage.get<string>('editing_holidayTitle') ?? '';

    return agendaInfo;
  }

  // 存在uri即通知跳转时拼装打开日程详情子窗参数
  checkUriParameter(want: Want): boolean {
    if (!want?.uri || EmptyUtils.isEmptyString(want?.uri, true)) {
      Log.info(TAG, `want uri is empty`);
      return false;
    }
    try {
      const agendaUri: uri.URI = new uri.URI(want?.uri);
      // calendarDate 通知里的uri 的协议格式
      if ('calendar' != agendaUri.scheme || 'com.openharmony.calendar' != agendaUri.host) {
        Log.info(TAG, `want uri scheme or host is fail`);
        return false;
      }
      const urlParams: string[] = agendaUri.query.split('&');
      const jumpParam: Record<string, number | string> = {};
      // 从uri分割的urlParams中拼装跳转用参数放入jumpParam中
      EmitterFormHandler.instance().parseJumpEventDetailParams(urlParams, jumpParam);
      if (!jumpParam.id) {
        Log.error(TAG, `want uri check id fail`);
        return false;
      }
      this.key = `${jumpParam.id ?? ''}`;
      if (EmptyUtils.isEmptyString(this.key, true)) {
        return false;
      }

      this.storage.setOrCreate('editing_eventId', jumpParam.id);
      this.storage.setOrCreate('editing_context', this.context);
      this.storage.setOrCreate('editing_instanceStartMills', jumpParam.instanceStartMills);
      this.storage.setOrCreate('editing_instanceEndMills', jumpParam.instanceEndMills);
      this.storage.setOrCreate('editing_isHoliday', false);
      this.storage.setOrCreate('editing_holidayTitle', '');
      this.storage.setOrCreate('editing_instanceKey', this.key);
    } catch (error) {
      Log.logErrorMsg(TAG, 'Failed to checkUriParameter', error);
    }
    return true;
  }

  /**
   * 对窗口尺寸进行初始化设置及监听
   * @param windowObj
   */
  initWindowsSize(windowObj: window.Window) {
    try {
      let properties: window.WindowProperties = windowObj.getWindowProperties();
      Log.log(TAG, 'getWindowProperties:' + JSON.stringify(properties));
      this.updateWindowSize(properties.windowRect.width, properties.windowRect.height);

      windowObj.on('windowSizeChange', (data) => {
        Log.log(TAG, 'windowSizeChange' + JSON.stringify(data));
        this.updateWindowSize(data.width, data.height);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'window properties get error', err);
    }
  }

  updateWindowSize(width: number, height: number): void {
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_WIDTH_IN_PX, width);
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_HEIGHT_IN_PX, height);
    width = Math.round(px2vp(width));
    height = Math.round(px2vp(height));
    this.storage.setOrCreate('windowWidth', width);
    this.storage.setOrCreate('windowHeight', height);
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    try {
      hiTraceMeter.startTrace(traceEvents.cardAbilityWindowStage, 0);
      super.onWindowStageCreate(windowStage);

      windowStage.loadContent('pages/AgendaDetailPage', this.storage, (err, data) => {
        if (err.code) {
          Log.logErrorMsg(TAG, 'Failed to load the content', err);
          return;
        }
        Log.info(TAG, 'Succeeded in loading the content. Data:');
        try {
          const windowObj: window.Window = windowStage.getMainWindowSync();
          // 当前只有PC存在多实例
          windowObj.setWindowBackgroundColor('#ccffffff');
          windowObj.getWindowProperties().isTransparent = true;

          // 初始化窗口监听
          this.initWindowsSize(windowObj);

          if (DeviceConfig.instance().config.needCommerce) {
            // 设置沉浸式状态栏
            windowObj.setWindowDecorVisible(false);
            windowObj.setWindowDecorHeight(70); // 该值是文档示例
            AppStorage.setOrCreate('titleButtonWidth', 160); // 当前无法通过windowAPI获取右上按钮宽度,暂时写死
            windowObj.setDecorButtonStyle({ buttonBackgroundSize: 40 });
          }

          // 初始化设备方向
          windowObj?.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
        } catch (error) {
          Log.logErrorMsg(TAG, `loadContent error:`, error);
        }
      });

      hiTraceMeter.finishTrace(traceEvents.cardAbilityWindowStage, 0);
    } catch (err) {
      Log.logErrorMsg(TAG, `windowObj get error`, err);
    }
  }

  onDestroy() {
    Log.info(TAG, `onDestroy`);
    AgendaAbilityManager.getInstance().unRegisterAgendaContext(this.key);
  }
}