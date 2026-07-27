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



import type Want from '@ohos.app.ability.Want';
import HashMap from '@ohos.util.HashMap';
import type common from '@ohos.app.ability.common';
import type resourceManager from '@ohos.resourceManager';
import lazy bundleManager from '@ohos.bundle.bundleManager';
import type { BusinessError } from '@ohos.base';
import { Log } from '../default/common/Log';
import { BigFontSize } from '../constants/BigFontSize';
import type { WorkSchedulerExtensionContext } from '@kit.BackgroundTasksKit';
import type BackupExtensionContext from '@ohos.file.BackupExtensionContext';
import { i18n } from '@kit.LocalizationKit';
// import { systemShare } from '@kit.ShareKit'; // ShareKit 注释

const TAG = 'getGlobalThis';

export class GlobalThis {
  // 是否常规模式(非自测试模式)，自测试用例下context不在应用包内
  static regularMode: boolean = true;
  /**
   * 获取资源串
   *
   * @param resource 资源
   * @return 资源文本
   */
  static resourceStrMap: HashMap<string, string> = new HashMap();
  static pluralStrMap: HashMap<string, string> = new HashMap();
  static colorMap: HashMap<string, number> = new HashMap();
  private static ins: GlobalThis;
  abilityWant: Want | null = null;
  // shareData: systemShare.SharedData | null = null; // ShareKit 注释
  fileDir: string = '';
  context: common.UIAbilityContext | null = null;
  abilityStageContext: common.AbilityStageContext | null = null;
  mainAbilityContext: common.UIAbilityContext | null = null;
  shareAbilityContext: common.UIAbilityContext | null = null; // 用于在多实例下开启分享弹窗的context
  tokenId: number = -1;
  extensionContext: common.Context | null = null;
  workSchedulerExtensionContext: WorkSchedulerExtensionContext | undefined = undefined;
  objectMap: HashMap<string, Object> = new HashMap();
  beforeAgendaAction: string | undefined = undefined;
  serviceType: Array<string> = new Array<string>();
  bundleInfo: bundleManager.BundleInfo | null = null;
  shareAnchorViewId: string = '';
  shareMemberMaxCount: number = 150;
  isAutoRotation: boolean = true;
  // 克隆,双升单context
  backupExtensionContext: BackupExtensionContext | undefined = undefined;
  // 大字体变更
  fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;
  //true：侧滑返回桌面
  sideslipBack: boolean = false;
  // 设置DataShare超时时间为3s
  timeoutInterval: number = 3;

  public static getInstance(): GlobalThis {
    if (!GlobalThis.ins) {
      GlobalThis.ins = new GlobalThis();
    }
    return GlobalThis.ins;
  }

  public static getResourceStr(resource: resourceManager.Resource, language?: string): string {
    if (!language) {
      language = i18n.System.getSystemLanguage();
    }
    if (!resource) {
      Log.error(TAG, 'No Valid resource when getResourceStrParms');
      return '';
    }
    if (resource.id && (GlobalThis.resourceStrMap.hasKey((language || '') + resource.id))) {
      return GlobalThis.resourceStrMap.get((language || '') + resource.id);
    }
    const context = GlobalThis.getInstance().getFromContext();
    if (!context) {
      Log.error(TAG, 'getResourceStr context is null');
      return '';
    }
    let str: string = '';
    if (GlobalThis.regularMode && resource.id) {
      str = context.resourceManager.getStringSync(resource?.id);
    } else {
      str = context.resourceManager.getStringSync(resource);
    }
    GlobalThis.resourceStrMap.set((language || '') + resource.id, str);
    return str;
  }

  public static getResourceColor(resource: resourceManager.Resource): number {
    if (!resource) {
      Log.error(TAG, 'No Valid resource when getResourceColor');
      return -1;
    }
    const isDarkMode = !!AppStorage.get('isDarkMode');
    const colorId = `${resource.id}_${isDarkMode}`;
    if (resource.id && GlobalThis.colorMap.hasKey(colorId)) {
      return GlobalThis.colorMap.get(colorId);
    }
    const context = GlobalThis.getInstance().getFromContext();
    if (!context) {
      Log.error(TAG, 'getResourceColor context is null');
      return -1;
    }
    let colorValue: number = -1; // 资源ID值对应的颜色值（十进制）
    if (GlobalThis.regularMode && resource.id) {
      colorValue = context.resourceManager.getColorSync(resource?.id);
    } else {
      colorValue = context.resourceManager.getColorSync(resource);
    }
    GlobalThis.colorMap.set(colorId, colorValue);
    return colorValue;
  }


  public static getResourceStrParms(resource: resourceManager.Resource, ...args: Array<string | number>): string {
    if (!resource) {
      Log.error(TAG, 'No Valid resource when getResourceStrParms');
      return '';
    }
    const context = GlobalThis.getInstance().getFromContext();
    if (!context) {
      Log.error(TAG, 'getResourceStrParms context is null');
      return '';
    }
    let str: string = '';
    if (GlobalThis.regularMode && resource.id ) {
      str = context.resourceManager.getStringSync(resource.id, ...args);
    } else {
      str = context.resourceManager.getStringSync(resource, ...args);
    }
    return str;
  }

  public static getPluralStr(resource: resourceManager.Resource, num: number, language?: string): string {
    if (!language) {
      language = i18n.System.getSystemLanguage();
    }
    if (!resource) {
      Log.error(TAG, 'No valid resource when getPluralStr.');
      return '';
    }
    let key = language + resource.id + num;
    if (GlobalThis.pluralStrMap.hasKey(key)) {
      return this.pluralStrMap.get(key);
    }
    const context = GlobalThis.getInstance().getFromContext();
    if (context) {
      let str: string = '';
      if (GlobalThis.regularMode) {
        str = context.resourceManager.getPluralStringValueSync(resource.id, num);
      } else {
        str = context.resourceManager.getPluralStringValueSync(resource, num);
      }
      GlobalThis.pluralStrMap.set(key, str);
      return str;
    }
    return '';
  }

  /**
   * 获取基础context能力
   *
   * @return 资源文本
   */
  public getBasicContext(): common.Context | null {
    if (this.context) {
      return this.context;
    }
    if (this.extensionContext) {
      return this.extensionContext;
    }
    if (this.workSchedulerExtensionContext) {
      return this.workSchedulerExtensionContext;
    }
    return null;
  }

  /**
   * 获取context能力
   *
   * @return 资源文本
   */
  public getFromContext(): common.Context | null {
    if (this.mainAbilityContext) {
      Log.info(TAG, `getFromContext mainAbilityContext`);
      return this.mainAbilityContext;
    }
    if (this.backupExtensionContext) {
      Log.info(TAG, `getFromContext backupExtensionContext`);
      return this.backupExtensionContext;
    }
    if (this.extensionContext) {
      Log.info(TAG, `getFromContext extensionContext`);
      return this.extensionContext;
    }
    Log.info(TAG, `getFromContext abilityStageContext`);
    return this.abilityStageContext;
  }

  /**
   * 获取db context application 级别的上下文获取db失败,需要Ability级别或extension级别
   *
   * @return 资源文本
   */
  public getDbContext(): common.Context | null {
    if (this.extensionContext) {
      return this.extensionContext;
    }
    if (this.workSchedulerExtensionContext) {
      return this.workSchedulerExtensionContext;
    }
    if (this.backupExtensionContext) {
      return this.backupExtensionContext;
    }
    if (this.context) {
      return this.context;
    }
    return null;
  }

  /**
   * 获取BundleInfo
   *
   */
  public getBundleInfoSync(): bundleManager.BundleInfo | null {
    if (this.bundleInfo) {
      return this.bundleInfo;
    }
    try {
      this.bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    } catch (error) {
      Log.logErrorMsg(TAG, 'getBundleInfoSync', error);
    }
    return this.bundleInfo;
  }

  /**
   * 获取BundleInfo
   *
   * @return 资源文本
   */
  public async getBundleInfo(): Promise<bundleManager.BundleInfo | null> {
    return new Promise((resolve) => {
      if (!this.bundleInfo) {
        bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
          this.bundleInfo = bundleInfo;
          resolve(this.bundleInfo);
        }).catch((error: BusinessError) => {
          Log.error(TAG, 'get bundleInfo failed,error is ' + error?.message);
          resolve(null);
        });
      } else {
        resolve(this.bundleInfo);
      }
    });
  }

  /**
   * 设置DataShare超时时间
   * @param interval
   */
  public setTimeoutInterval(interval: number): void {
    this.timeoutInterval = interval;
  }
}