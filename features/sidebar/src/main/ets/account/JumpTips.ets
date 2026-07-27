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
import bundleManager from '@ohos.bundle.bundleManager';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import util from '@ohos.util';
import { GlobalThis, Log } from '@app/common';

const TAG = 'TipsJump';
const APP_BUNDLE_NAME = 'com.openharmony.tips';
const ATOMIC_SERVICE_BUNDLE_NAME = APP_BUNDLE_NAME + '.widget';
const ATOMIC_SERVICE_ABILITY_NAME = 'FormEntryAbility';
const MODULE_NAME_PHONE = 'phone_widget';
const MODULE_NAME_PC = 'pc_widget';
const CODE_BUNDLE_NAME_NOT_FOUND = 17700001;
const CODE_SUCCESS_ERROR = 0;
const FUN_NUM_HOME = 'SF-20005936_f101';
type startAbleContext = common.UIAbilityContext | common.ServiceExtensionContext;

/**
 * 内嵌帮助接入玩机技巧
 *
 * @author liyang
 * @since 2023-11-14
 */
export class TipsJumpUtils {
  /**
   * 跳转到玩机技巧首页
   *
   * @param startAbleContext 上下文,类型要求：common.UIAbilityContext |
   common.ServiceExtensionContext
   * @param type 入口类型ID，用于打点
   * @param moduleName phone_widget:跳转手机，pc_widget：跳转PC
   */
  public static jumpHome(context: startAbleContext, type: string, moduleName: string =
  MODULE_NAME_PHONE) {
    TipsJumpUtils.jumpTips(context, FUN_NUM_HOME, type, moduleName ?? MODULE_NAME_PHONE);
  }

  /**
   * 跳转到玩机技巧指定页面
   *
   * @param startAbleContext 上下文,类型要求：common.UIAbilityContext |
   common.ServiceExtensionContext
   * @param funNum:页面FunNum
   * @param type 入口类型ID，用于打点
   * @param moduleName phone_widget:跳转手机，pc_widget：跳转PC
   */
  public static jumpTips(context: startAbleContext, funNum: string, type: string,
                         moduleName: string = MODULE_NAME_PHONE) {
    let uri = util.format(GlobalThis.getResourceStr($r('app.string.uri_formatter')), funNum, type);
    TipsJumpUtils.jumpTipsByUri(context, uri, moduleName ?? MODULE_NAME_PHONE);
  }

  /**
   * 跳转到玩机技巧指定页面，使用uri方式
   *
   * @param startAbleContext 上下文,类型要求：common.UIAbilityContext |
   common.ServiceExtensionContext
   * @param uri uri格式：hwtips://com.openharmony.tips.app?funNum=xxx&type=xxx
   * @param moduleName phone_widget:跳转手机，pc_widget：跳转PC
   */
  public static jumpTipsByUri(context: startAbleContext, uri: string, moduleName:
    string = MODULE_NAME_PHONE) {
    if (moduleName !== MODULE_NAME_PHONE && moduleName !== MODULE_NAME_PC) {
      Log.error(TAG, `unknown moduleName ${moduleName}, supported value:"${MODULE_NAME_PHONE}" or "${MODULE_NAME_PC}"`);
      return;
    }
    TipsJumpUtils.isAppInstalled().then((isAppInstalled: boolean) => {
      if (isAppInstalled) {
        TipsJumpUtils.jumpAppByUri(context, uri);
      } else {
        TipsJumpUtils.jumpAppGallery(context);
      }
    })
  }

  /**
   * 跳转到应用市场页面，使用uri方式
   */
  private static jumpAppGallery(context: startAbleContext) {
    Log.info(TAG, 'try jump to AppGallery');
    const want: Want = {
      bundleName: GlobalThis.getResourceStr($r('app.string.moudle_name_appgallery')),
      uri: GlobalThis.getResourceStr($r('app.string.uri_appgallery'))
    };
    context.startAbility(want).then(() => {
      Log.info(TAG, 'jump appgallery success');
    }).catch(() => {
      Log.info(TAG, 'jump appgallery error');
    })
  }

  /**
   * 跳转到鸿蒙应用的指定页面，使用uri方式
   */
  private static jumpAppByUri(context: startAbleContext, uri: string) {
    Log.info(TAG, 'try jump to app');
    let want: Want = {
      bundleName: APP_BUNDLE_NAME,
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri
    };
    context.startAbility(want, (err: BusinessError) => {
      if (err?.code !== CODE_SUCCESS_ERROR) {
        Log.logErrorMsg(TAG, 'jump to [tips app] failed', err);
      } else {
        Log.info(TAG, 'jump to [tips app] success');
      }
    });
  }

  private static isAppInstalled(): Promise<boolean> {
    return bundleManager.getBundleInfo(APP_BUNDLE_NAME,
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO).then((info) => {
      if (GlobalThis.getResourceStr($r('app.string.tpis_app_id')) === info.signatureInfo.appId) {
        Log.info(TAG, 'tips app is installed');
        return true;
      } else {
        Log.info(TAG, 'tips app is forged');
        return false;
      }
    }).catch((err: BusinessError) => {
      if (err.code === CODE_BUNDLE_NAME_NOT_FOUND) {
        Log.info(TAG, 'tips app is not installed');
      } else {
        Log.logErrorMsg(TAG, 'failed to check if tips app is installed', err);
      }
      return false;
    })
  }
}