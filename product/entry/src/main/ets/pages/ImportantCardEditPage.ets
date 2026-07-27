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

import { ImportantCardEdit } from '@app/feature.card/src/main/ets/importantCard/view/pages/ImportantCardEdit';
import { ImportantCardSelect } from '@app/feature.card/src/main/ets/importantCard/view/pages/ImportantCardSelect';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import {
  AppContinueManager,
  checkIsPermissionsGranted, DeviceConfig,
  GlobalDataKeys,
  GlobalThis, Log, NotificationTriggerHelper,
  PermissionState,
  TriggerSource } from '@app/common';
import { CustomTransition, AnimateCallback } from '../Utils/CustomNavigationUtils';
import { common, Permissions } from '@kit.AbilityKit';
import { requestPermissionsFromUser } from '@app/common/src/main/ets/util/PermissionUtil';
import { NetWorkManger } from '@app/service.network';
import { mediaquery } from '@kit.ArkUI';
import { WindowManager } from './StatusBarManager';

const TAG: string = 'ImportantCardEditPage';

let storage = LocalStorage.getShared();

/**
 * 重要日卡片编辑界面
 */
@Entry(storage)
@Component
struct ImportantCardEditPage {
  @Provide navPathStack: NavPathStack = new NavPathStack();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(dark-mode: true)');

  private listenerHandler: (mediaQueryResult: mediaquery.MediaQueryResult) => void =
    (mediaQueryResult: mediaquery.MediaQueryResult) => {
    this.onDarkMode(mediaQueryResult)
  };

  @Builder
  initItemFunc() {
  };

  build() {
    Navigation(this.navPathStack) {
      ImportantCardEdit()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.naviRoute)
    .hideBackButton(true)
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
      Log.info(TAG, `customNavContentTransition: ${this.needCommerce}-${from.name}-${to.name}`);
      if (!this.needCommerce) {
        return undefined;
      }
      if (from.name !== NavPathName.IMPORTANT_CARD_SELECT && to.name !== NavPathName.IMPORTANT_CARD_SELECT) {
        return undefined;
      }

      Log.info(TAG, `customNavContentTransition`);
      CustomTransition.getInstance().operation = operation;
      let customAnimation: NavigationAnimatedTransition = {
        timeout: 50,
        transition: (transitionProxy: NavigationTransitionProxy) => {
          if (!from.navDestinationId || !to.navDestinationId) {
            return;
          }
          let fromParam: AnimateCallback | undefined = CustomTransition.getInstance()
            .getAnimateParam(from.navDestinationId);
          let toParam: AnimateCallback | undefined = CustomTransition.getInstance()
            .getAnimateParam(to.navDestinationId);
          if (operation == NavigationOperation.POP || operation == NavigationOperation.PUSH) {
            if (toParam.start) {
              toParam.start(true, false);
            }
            animateTo({
              duration: 50, onFinish: () => {
                transitionProxy.finishTransition();
              }
            }, () => {
              if (toParam?.finish) {
                toParam.finish(true, false);
              }
            })
          } else {
            if (fromParam.start) {
              fromParam.start(true, true);
            }
            animateTo({
              duration: 50, onFinish: () => {
                transitionProxy.finishTransition();
              }
            }, () => {
              if (fromParam?.finish) {
                fromParam.finish(true, true);
              }
            })
          }
        }
      };
      return customAnimation;
    })
  }

  @Builder
  naviRoute(path: string, params: Object) {
    if (NavPathName.IMPORTANT_CARD_SELECT === path) {
      ImportantCardSelect();
    }
  }

  async aboutToAppear() {
    Log.info(TAG, 'ImportantCardEditPage: aboutToAppear');
    // 监听深色模式切换
    this.listener.on('change', this.listenerHandler);
    this.requestPermissionsMaybe();
    // 开源版本默认同意隐私协议，启用接续
    AppContinueManager.getInstance().setAppContinueState(true, getContext() as common.UIAbilityContext);
    NetWorkManger.getInstance().updateUserNetWorkState(PermissionState.CONFIRMED);
  }

  aboutToDisappear(): void {
    this.listener.off('change', this.listenerHandler);
  }

  onDarkMode(mediaQueryResult: mediaquery.MediaQueryResult) {
    WindowManager.getInstance().setSystemBarProperties(mediaQueryResult.matches);
    AppStorage.setOrCreate(GlobalDataKeys.IS_DARKMODE, mediaQueryResult.matches);
    Log.info(TAG, `onDarkMode ${mediaQueryResult.matches}`);
  }

  /**
   * 条件成立下请求日历权限
   */
  private requestPermissionsMaybe() {
    const permissions: Permissions[] = ['ohos.permission.READ_WHOLE_CALENDAR', 'ohos.permission.WRITE_WHOLE_CALENDAR'];
    checkIsPermissionsGranted(permissions)
      .then((isAllPerGranted: boolean): Promise<boolean> => {
        if (!isAllPerGranted) {
          Log.warn(TAG, `checkIsPermissionsGranted isAllPerGranted false`);
          return this.requestPermissionsFromUser();
        }
        return new Promise((resolve) => {
          resolve(true)
        });
      })
      .catch((err: Error): Promise<boolean> => {
        Log.logErrorMsg(TAG, `queryPermissionsState`, err);
        return this.requestPermissionsFromUser();
      })
      .then((finalResult: boolean | void) => {
        Log.info(TAG, `requestPermissionsFromUser finalResult is ${finalResult}`);
      })
      .catch((err: Error) => {
        Log.logErrorMsg(TAG, `requestPermissionsFromUser`, err);
      });
  }

  /**
   * 请求日历权限弹窗
   */
  private async requestPermissionsFromUser(): Promise<boolean> {
    if (!GlobalThis.getInstance().context) {
      Log.warn(TAG, `requestPermissionsFromUser context is null`);
      return false;
    }
    const permissions: Permissions[] = ['ohos.permission.READ_WHOLE_CALENDAR', 'ohos.permission.WRITE_WHOLE_CALENDAR'];
    return requestPermissionsFromUser(permissions, GlobalThis.getInstance().context as common.UIAbilityContext);
  }

  }

export {
  ImportantCardEditPage
}
