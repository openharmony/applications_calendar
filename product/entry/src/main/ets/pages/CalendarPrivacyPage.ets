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

import { GlobalData, GlobalDataKeys, Log } from '@app/common';
import {
  NavPageBuilderFactory,
  NavPathManager,
  NavPathName,
  RouterName
} from '@app/common';
import { mediaquery } from '@kit.ArkUI';
import { WindowManager } from './StatusBarManager';

const TAG: string = 'CalendarPrivacyPage:';

const SYSTEM_SETTING_PRIVACY: string = 'SYSTEM_SETTING_PRIVACY';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct CalendarPrivacyPage {
  @Provide navPathStack: NavPathStack = new NavPathStack();
  private listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(dark-mode: true)');

  private listenerHandler: (mediaQueryResult: mediaquery.MediaQueryResult) => void =
    (mediaQueryResult: mediaquery.MediaQueryResult) => {
    this.onDarkMode(mediaQueryResult)
  };


  aboutToAppear() {
    Log.info(TAG, 'aboutToAppear.');
    NavPathManager.getInstance().createRouter(RouterName.SYSTEM_SETTING_PRIVACY, this.navPathStack);
    this.listener.on('change', this.listenerHandler);
  }

  aboutToDisappear() {
    Log.info(TAG, 'aboutToDisappear.');
    this.listener.off('change', this.listenerHandler);
  }

  onPageShow() {
    Log.info(TAG, 'onPageShow.');
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  onDarkMode(mediaQueryResult: mediaquery.MediaQueryResult) {
    WindowManager.getInstance().setSystemBarProperties(mediaQueryResult.matches);
    if (GlobalData.instance().get(GlobalDataKeys.IS_DARKMODE) !== mediaQueryResult.matches) {
      AppStorage.setOrCreate(GlobalDataKeys.IS_DARKMODE, mediaQueryResult.matches);
    }
    Log.info(TAG, `is dark mode: ${mediaQueryResult.matches}`);
  }

  build() {
    Navigation(this.navPathStack) {
      Column().onAttach(() => {
        const params: Record<string, number | boolean | string> = {};
        params.sourcePage = SYSTEM_SETTING_PRIVACY;
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.PAF_PRIVACY_PAGE,
          routerName: RouterName.SYSTEM_SETTING_PRIVACY,
          param: params
        });
      }).backgroundColor($r('sys.color.background_secondary'));
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.navRoute)
    .titleMode(NavigationTitleMode.Mini);
  }
}