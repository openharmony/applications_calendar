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

import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import { wantConstant } from '@kit.AbilityKit';
import { behaviorEvents, Log, ReportUtil } from '@app/common';

const TAG = 'JumpUtils';
const APP_MARKET_DEEPLINK_PREFIX = 'store://enterprise/manifest';

export class JumpUtils {
  public static openBrowser(context: common.UIAbilityContext, uri: string): void {
    let callback = () => {
      ReportUtil.reportStatisticEvent(behaviorEvents.filingInformation);
    };
    JumpUtils.startApp(context, uri, callback);
  }

  /**
   * 根据链接指定打开App
   * @param url
   * @returns
   */
  private static getSpecificApp(url: string): string {
    return '';
  }

  /**
   * 启动其他应用（扒自浏览器）
   * 关键词：deeplink
   * @param context
   * @param url
   * @param callback
   */
  private static startApp(
    context: common.UIAbilityContext,
    url: string,
    callback: Function | undefined = undefined,
    parameters: Record<string, Object> | undefined = undefined,
    isSpecificApp: boolean = false
  ) {
    Log.info(TAG, `startApp whit url`);
    let want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
      wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION, // 必须要给读写权限，不然文本编辑器打开txt文件为空
      action: 'ohos.want.action.viewData',
      uri: url,
      parameters: parameters
    };
    if (isSpecificApp) {
      const bundleName = JumpUtils.getSpecificApp(url);
      if (bundleName) {
        want.bundleName = bundleName;
      }
    }
    context.startAbility(want).then(() => {
      Log.info(TAG, `startApp success`);
      callback && callback();
    }).catch((err: BusinessError) => {
      Log.error(TAG, `startApp fail, code: ${err.code}, message: ${err.message}`);
    });
  }
}