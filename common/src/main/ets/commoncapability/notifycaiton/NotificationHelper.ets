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

import Notification from '@ohos.notificationManager';
import { Callback } from '@ohos.base';
import { GlobalThis } from '../../data/GlobalThis';
import { NotificationRequestState } from '../../default/common/declare';
import { PreferencesUtil } from '../../default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '../../default/util/preferences_util/PreferencesFiles';
import { NotificationPreferencesKeys } from '../../default/util/preferences_util/NotificationPreferencesKeys';
import { Log } from '../../default/common/Log';
import { ReportHiEventParams, ReportUtil } from '../../default/util/ReportUtil';
import { behaviorEvents } from '../../default/common/HiEvents';
import { wait } from '../../util/CommonUtils';
import { AbilityStateHelper } from '../../../../..';
import { GlobalData, GlobalDataKeys} from '../../../../..';
import { ModeUtil } from '../../util/ModeUtil';

export enum TriggerSource {
  NOTHING,
  // 在应用内停留
  BROWSE_APP,
  // 触发了需要通知权限的业务
  TRIGGER_NOTIFICATION_BUSINESS,
}

const TAG: string = `NotificationHelper`;
const preferencesFileName: string = PreferencesFiles.NOTIFICATION;
const requestStateKey: string = NotificationPreferencesKeys.REQUEST_NOTIFICATION_PERMISSION_STATE;

export type PermissionChangedCall = (isNotificationGranted: boolean) => void;


/*
 * 通知权限请求弹窗Helper
 * 首次进入停留10s弹出 优先级最低；
 * 首次进入马上退出后再次进入弹出（进入应用后立马退出应用，再进入应用）优先级第二；
 * 有进入需要通知权限的业务的操作立刻弹出 优先级最高；
 * 应用在启动到杀掉只能弹一次，除非下次用户再启动
 */
export class NotificationHelper {
  private static sInstance: NotificationHelper | null = null;
  private readonly permissionChangedListeners: PermissionChangedCall[] = [];
  private notificationGranted: boolean = false;
  private requestNotificationBreak: boolean = false;

  constructor() {
    this.notificationGranted = !this.isNeedRequestNotification();
  }

  static getInstance(): NotificationHelper {
    if (!NotificationHelper.sInstance) {
      NotificationHelper.sInstance = new NotificationHelper();
    }
    return NotificationHelper.sInstance;
  }

  public readonly mainAbilityForegroundChangedCall: Callback<boolean> = (isMainAbilityForeground: boolean) => {
    if (isMainAbilityForeground && this.requestNotificationBreak) {
      this.doRequestNotification();
    }
  }

  public isNotificationGranted() {
    return this.notificationGranted;
  }

  /**
   * 查询系统通知权限状态
   * @returns 通知权限状态
   */
  public async queryNotificationGranted() {
    return await Notification.isNotificationEnabled();
  }

  /**
   * 请求通知权限弹窗
   */
  async requestNotification(): Promise<boolean> {
    Log.debug(TAG, `doRequestNotification isNeedRequestNotification is ${this.notificationGranted}`);
    if (this.notificationGranted) {
      return true;
    }
    return this.doRequestNotification();
  }

  addNotificationPermissionChangedListener(permissionChangedCall: PermissionChangedCall): boolean {
    if (!permissionChangedCall) {
      Log.warn(TAG, 'addNotificationPermissionChangedListener permissionChangedListener is null');
      return false;
    }
    if (this.permissionChangedListeners.includes(permissionChangedCall)) {
      return false;
    }
    this.permissionChangedListeners.push(permissionChangedCall);
    permissionChangedCall(this.notificationGranted);
    return true;
  }

  removeNotificationPermissionChangedListener(permissionChangedCall: PermissionChangedCall): boolean {
    if (!permissionChangedCall) {
      Log.warn(TAG, 'removeNotificationPermissionChangedListener permissionChangedListener is null');
      return false;
    }
    const index = this.permissionChangedListeners.indexOf(permissionChangedCall);
    if (index < 0 || index >= this.permissionChangedListeners.length) {
      return false;
    }
    this.permissionChangedListeners.splice(index, 1);
    return true;
  }

  // 设置桌面角标数量
  public async setBadgeNumber(badgeNumber: number): Promise<boolean> {
    if (badgeNumber < 0) {
      Log.warn(TAG, 'badge number error');
      return false;
    }
    try {
      await Notification.setBadgeNumber(badgeNumber);
      Log.info(TAG, 'displayBadge success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'displayBadge fail', err);
      return false;
    }
  }

  protected updateRequestNotificationState(notificationRequestState: NotificationRequestState) {
    Log.info(TAG, `updateRequestNotificationState: ${notificationRequestState}`);
    PreferencesUtil.putNumberValueSync(PreferencesFiles.NOTIFICATION, requestStateKey, notificationRequestState);
    let params: ReportHiEventParams = {
      IS_ON: notificationRequestState === NotificationRequestState.REQUEST_SUCCESS ? 1 : 0
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.calendarReminderPopup, params);
    this.notificationGranted = notificationRequestState === NotificationRequestState.REQUEST_SUCCESS;
    this.dispatchPermissionChanged();
  }

  private isNeedRequestNotification(): boolean {
    if (ModeUtil.isRetailMode()) {
      PreferencesUtil.putNumberValueSync(preferencesFileName,
        requestStateKey, NotificationRequestState.REQUEST_SUCCESS);
    }
    const requestNotificationState: number = PreferencesUtil
      .getNumberValueSync(preferencesFileName, requestStateKey, NotificationRequestState.NOT_REQUEST);
    Log.info(TAG, `isNeedRequestNotification requestNotificationState is ${requestNotificationState}`);
    return requestNotificationState != NotificationRequestState.REQUEST_SUCCESS;
  }

  /**
   * 请求过一次,如果拒绝后,后续再请求,不会再弹窗,而是直接回调失败
   * @returns
   */
  private async doRequestNotification(): Promise<boolean> {
    const isForeground = await this.checkForeground();
    if (!isForeground) {
      this.requestNotificationBreak = true;
      return false;
    }
    let requestResult: boolean = false;
    try {
      await Notification.requestEnableNotification(GlobalThis.getInstance().mainAbilityContext);
      requestResult = await Notification.isNotificationEnabled();
      Log.info(TAG, 'isNotificationEnabled requestResult:' + requestResult);
      GlobalData.instance().set(GlobalDataKeys.IS_NOTIFICATION_GRANTED, requestResult);
    } catch (err) {
      requestResult = false;
      Log.error(TAG, `requestEnableNotification failed msg is ${err?.message} code is ${err?.code}`);
    }
    this.requestNotificationBreak = false;
    this.updateRequestNotificationState(requestResult ?
    NotificationRequestState.REQUEST_SUCCESS : NotificationRequestState.REQUEST_FAILED);
    return requestResult;
  }

  private async checkForeground(): Promise<boolean> {
    const mainAbilityContext = GlobalThis.getInstance().mainAbilityContext;
    if (!AbilityStateHelper.getInstance().isAbilityForeground(mainAbilityContext)) {
      Log.warn(TAG, `doRequestNotification isMainAbilityForeground false`);
      return false;
    }
    await wait(200);
    if (!AbilityStateHelper.getInstance().isAbilityForeground(mainAbilityContext)) {
      Log.warn(TAG, `doRequestNotification isMainAbilityForeground false again`);
      return false;
    }
    return true;
  }

  private dispatchPermissionChanged() {
    for (let listener of this.permissionChangedListeners) {
      listener(this.notificationGranted);
    }
  }
}