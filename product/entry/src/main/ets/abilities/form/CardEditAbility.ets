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
  behaviorEvents,
  DeviceConfig,
  deviceType,
  EmptyUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ReportHiEventParams,
  ReportUtil,
  traceEvents
} from '@app/common';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { SYSTEM_BAR_PROPERTIES_WHITE } from '../../pages/StatusBarManager';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { ConfigurationConstant } from '@kit.AbilityKit';

const TAG: string = 'CardEditAbility';

/**
 * 卡片编辑界面
 */
export default class CardEditAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage();

  /** 折叠屏收起展开监听函数 */
  private foldStatusChangeListener: (foldStatus: display.FoldStatus) => void = (foldStatus: display.FoldStatus) => {};

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hiTraceMeter.startTrace(traceEvents.cardAbilityCreate, 0);
    super.onCreate(want, launchParam);
    GlobalThis.getInstance().context = this.context;
    GlobalData.instance().init();
    DeviceConfig.instance().init();
    const parameter = want.parameters;
    let formId: string | null = null;
    let isParaOk: boolean = true;
    if (!parameter) {
      Log.error(TAG, 'onCreate parameter is null')
      isParaOk = false;
    } else {
      try {
        formId = parameter['formId'] as string;
      } catch (err) {
        isParaOk = false;
        Log.logErrorMsg(TAG, `onCreate error`, err);
      }
      if (EmptyUtils.isEmptyString(formId)) {
        isParaOk = false;
      }
    }
    if (!isParaOk) {
      GlobalThis.getInstance().context?.terminateSelf();
      return;
    }
    AppStorage.setOrCreate('editing_formId', formId);
    hiTraceMeter.finishTrace(traceEvents.cardAbilityCreate, 0);
  }


  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onNewWant(want, launchParam)
    const parameter = want.parameters;
    let formId: string | null = null;
    let isParaOk: boolean = true;
    if (!parameter) {
      Log.error(TAG, 'onNewWant parameter is null')
      isParaOk = false;
    } else {
      try {
        formId = parameter['formId'] as string;
      } catch (err) {
        isParaOk = false;
        Log.logErrorMsg(TAG, `onNewWant error `, err);
      }
      if (EmptyUtils.isEmptyString(formId)) {
        isParaOk = false;
      }
    }
    if (!isParaOk) {
      GlobalThis.getInstance().context?.terminateSelf();
      return;
    }
    AppStorage.setOrCreate('editing_formId', formId);

    // 编辑在后台不会走aboutToAppear ->OnFormIdChange ->loadData
    // 需要手动触发一次，否则eventId无法刷新，从而桌面卡片和编辑页面重要日不一致
    AppStorage.setOrCreate('editing_refreshId', Math.random().toString());
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    try {
      hiTraceMeter.startTrace(traceEvents.cardAbilityWindowStage, 0);
      super.onWindowStageCreate(windowStage);

      windowStage.loadContent('pages/ImportantCardEditPage', this.storage, (err, data) => {
        if (err.code) {
          Log.logErrorMsg(TAG, 'Failed to load the content', err);
          return;
        }
        Log.info(TAG, 'Succeeded in loading the content. Data:');
        const windowObj: window.Window = windowStage.getMainWindowSync();
        // 修改状态栏色值为白色(因为重要日编辑页背景恒为深色背景，故状态栏需为白色，不能随深浅色模式切换)
        this.setWindowSystemBarColor(windowStage, SYSTEM_BAR_PROPERTIES_WHITE);
        if (DeviceConfig.instance().deviceType !== deviceType.PC) {
          this.setImmersiveWindow(windowObj);
        } else {
          windowObj.setWindowBackgroundColor('#ccffffff');
          windowObj.getWindowProperties().isTransparent = true;

          // 设置沉浸式体验
          windowObj.setWindowDecorVisible(false);
          windowObj.setWindowDecorHeight(70); // 该值是文档示例
          windowObj.setDecorButtonStyle({
            colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          });
        }
        // 初始化窗口监听
        this.initWindowsSize(windowObj);

        let avoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const topHeight = Math.floor(px2vp(avoidArea.topRect.height));
        if (DeviceConfig.instance().config.needChangeAreaHeight) {
          AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', topHeight);
        }

        this.initAvoidArea(windowObj);

        this.initWindowsModeChange(windowObj);
      });

      // 初始化设备方向
      this.initDeviceOrientation(windowStage);

      hiTraceMeter.finishTrace(traceEvents.cardAbilityWindowStage, 0);
    } catch (err) {
      Log.logErrorMsg(TAG, 'onWindowStageCreate window get error', err);
    }
  }

  /**
   * 修改状态栏色值
   * 注意事项：windowStage.getMainWindowSync().setWindowSystemBarProperties改状态栏色值不成功，可能是api有问题，
   * 而使用.getMainWindow().then可正常修改
   */
  private setWindowSystemBarColor(windowStage: window.WindowStage, color: window.SystemBarProperties) {
    windowStage.getMainWindow().then((window: window.Window) => {
      const promise = window.setWindowSystemBarProperties(color);
      promise.then(() => {
        Log.info(TAG, 'setSystemBarProperties success');
      }).catch((err: Error) => {
        Log.error(TAG, 'setSystemBarProperties error, message:' + err?.message);
      })
    }).catch((err: Error) => {
      Log.error(TAG, 'setWindowSystemBarColor getMainWindow error, message:' + err?.message);
    })
  }

  updateWindowAvoidAreaHeight(height: number): void {
    height = px2vp(height);
    AppStorage.setOrCreate('windowAvoidAreaHeight', height);
  }

  /**
   * 初始化设备方向，手机竖屏|折叠手机跟随系统|平板跟随系统
   * @param windowStage
   */
  initDeviceOrientation(windowStage: window.WindowStage) {
    try {
      windowStage.getMainWindow().then((windowObj) => {
        // 手机-非折叠使用竖屏
        if (DeviceConfig.instance().deviceType === deviceType.PHONE) {
          // 双折叠、三折叠的枚举值不一样，需要额外判断
          let orientation = display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED ||
            display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED ?
            window.Orientation.AUTO_ROTATION_RESTRICTED : window.Orientation.PORTRAIT;
          windowObj?.setPreferredOrientation(orientation);

          // 监听折叠屏的展开态或折叠态
          this.foldStatusChangeListener = (foldStatus: display.FoldStatus) => {
            orientation = foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ?
              window.Orientation.AUTO_ROTATION_RESTRICTED : window.Orientation.PORTRAIT;
            try {
              windowObj?.setPreferredOrientation(orientation, (err: BusinessError) => {
                const errCode: number = err.code;
                if (errCode) {
                  Log.error(TAG, `Failed to set window orientation. Cause code: ${err.code}, message: ${err.message}`);
                  return;
                }
                Log.info(TAG, 'Succeeded in setting window orientation.');
              });
            } catch (exception) {
              Log.error(TAG, `Failed to set window orientation. Cause code: ${exception.code}, message: ${exception.message}`);
            }
          };
          display.on('foldStatusChange', this.foldStatusChangeListener);
        } else {
          // 平板|电脑 自动
          windowObj?.setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED);
        }
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'initDeviceOrientation', err);
    }
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
      Log.logErrorMsg(TAG, 'initWindowsSize window properties get error', err);
    }
  }

  updateWindowSize(width: number, height: number): void {
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_WIDTH_IN_PX, width);
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_HEIGHT_IN_PX, height);
    width = Math.round(px2vp(width));
    height = Math.round(px2vp(height));
    this.storage.setOrCreate('windowWidth', width);
    this.storage.setOrCreate('windowHeight', height);

    // 视图层实时响应高度变化
    AppStorage.setOrCreate('windowHeight', height);
  }

  /**
   * 对应用窗口规避区的初始化及监听
   * @param windowObj
   */
  initAvoidArea(windowObj: window.Window) {
    // 小键盘规避
    windowObj.on('keyboardHeightChange', (data) => {
      const keyBoardHeightVp = px2vp(data);
      AppStorage.setOrCreate<number>('keyBoardHeight', keyBoardHeightVp);
    });

    try {
      let avoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      Log.debug(TAG, 'avoidArea:' + JSON.stringify(avoidArea));

      this.updateWindowAvoidAreaHeight(avoidArea.topRect.height + avoidArea.bottomRect.height);

      // 顶部及底部导航栏规避判断
      const needChangeAreaHeight = DeviceConfig.instance().config.needChangeAreaHeight;
      if (needChangeAreaHeight) {
        // 顶部导航栏
        const topHeight = Math.floor(px2vp(avoidArea.topRect.height));
        AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', topHeight);
        Log.info(TAG, 'windowAvoidAreaTopRectHeight:' + topHeight);

        // 底部导航栏
        let navigationArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        const navigationHeight = Math.floor(px2vp(navigationArea.bottomRect.height));
        AppStorage.setOrCreate<number>('windowAvoidAreaNavigationRectHeight', navigationHeight);
        Log.info(TAG, 'windowAvoidAreaNavigationRectHeight:' + navigationHeight);
      }
    } catch (exception) {
      Log.error(TAG, 'Failed to obtain the area. Cause:' + exception?.message);
    }

    // 规避区监听
    windowObj.on('avoidAreaChange', (data) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) { // 系统规避区
        this.updateWindowAvoidAreaHeight(data.area.topRect.height + data.area.bottomRect.height);
        const topHeight = Math.floor(px2vp(data.area.topRect.height));
        if (DeviceConfig.instance().config.needChangeAreaHeight) {
          AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', topHeight);
        }
        Log.info(TAG, 'windowAvoidAreaTopRectHeight change:' + topHeight);
      } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) { // 导航栏规避区
        if (DeviceConfig.instance().config.needChangeAreaHeight) {
          const navigationHeight = Math.floor(px2vp(data.area.bottomRect.height));
          AppStorage.setOrCreate<number>('windowAvoidAreaNavigationRectHeight', navigationHeight);
          Log.info(TAG, 'windowAvoidAreaNavigationRectHeight change:' + navigationHeight);
        }
      }
    });
  }

  // 初始化窗口状态变更监听
  initWindowsModeChange(windowObj: window.Window) {
    try {
      windowObj.on('windowStatusChange', (windowStatusType) => {
        Log.info(TAG, `windowStatusChange: ${windowStatusType}`);
        let params: ReportHiEventParams = {
          WINDOW_MODE: windowStatusType
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.changeWindowMode, params);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed to enable the listener for window status changes', err);
    }
  }

  // 沉浸式设置
  setImmersiveWindow(windowObj: window.Window) {
    windowObj.setWindowLayoutFullScreen(true);
    const systemBarProperties: window.SystemBarProperties = {
      statusBarColor: '#00000000',
      isStatusBarLightIcon: false,
      statusBarContentColor: '#ff000000',
      navigationBarColor: '#00000000',
      navigationBarContentColor: '#ff000000',
    };
    windowObj.setWindowSystemBarProperties(systemBarProperties);
  }

  onDestroy() {
    try {
      display.off('foldStatusChange', this.foldStatusChangeListener);
    } catch (err) {
      Log.logErrorMsg(TAG, `onDestroy failed, error code:${err.code}, error message: ${err.message}.`);
    }
  }
}