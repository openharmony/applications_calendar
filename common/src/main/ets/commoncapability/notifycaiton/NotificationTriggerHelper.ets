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

import { PreferencesUtil } from '../../default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '../../default/util/preferences_util/PreferencesFiles';
import { NotificationPreferencesKeys } from '../../default/util/preferences_util/NotificationPreferencesKeys';
import { Log } from '../../default/common/Log';
import { SingleInstanceHelper } from '../../templates/SingleInstanceHelper';
import { NotificationHelper } from './NotificationHelper';
import { EmptyUtils } from '../../util/EmptyUtils';
import { Callback } from '@ohos.base';
import { DateUtil } from '../../util/DateUtil';

const TAG: string = `NotificationTriggerHelper`;
const preferencesFileName: string = PreferencesFiles.NOTIFICATION;
const isFirstInAppKey: string = NotificationPreferencesKeys.IS_FIRST_IN_APP;
const requestTimesInAppKey: string = NotificationPreferencesKeys.REQUEST_TIMES_IN_APP_KEY;
const lastRequestTimeInAppKey: string = NotificationPreferencesKeys.LAST_REQUEST_TIME_IN_APP_KEY;

const DELAY_MILLS: number = 10 * 1000;
const REQUEST_AFTER_SECOND: number = 3;
const REQUEST_AFTER_THIRD: number = 7;
const REQUEST_AFTER_FOURTH: number = 15;

export enum TriggerSource {
  NOTHING,
  // 在应用内停留
  BROWSE_APP,
  // 触发了需要通知权限的业务
  TRIGGER_NOTIFICATION_BUSINESS,
}

/*
 * 通知权限请求弹窗TriggerHelper
 * 首次进入停留10s弹出 优先级最低；
 * 首次进入马上退出后再次进入弹出（进入应用后立马退出应用，再进入应用）优先级第二；
 * 有进入需要通知权限的业务的操作立刻弹出 优先级最高；
 * 应用在启动到杀掉只能弹一次，除非下次用户再启动
 */
export class NotificationTriggerHelper {
  private hasRequestNotification: boolean = false;
  private isFirstInApp: boolean = false;
  private timeOutId: number = -1;
  private triggerSource: TriggerSource = TriggerSource.NOTHING;
  //异步等待通知是否被授权的的Resolve,通知请求结果后,回调
  private waitResolves: Callback<boolean>[] = [];
  private notificationGranted: boolean | undefined = undefined;
  private requestTimesInApp: number = 0;
  private lastRequestTimeInApp: number = 0;
  private jumpToSetting: boolean = true;

  public constructor() {
    this.init();
  }

  static getInstance(): NotificationTriggerHelper {
    return SingleInstanceHelper.createOrGet(NotificationTriggerHelper, TAG);
  }

  /**
   * 请求通知权限
   * @param triggerSource
   * @param callBack 如果需要等待结果,promise 非undefined
   * @returns boolean 是否触发了通知请求意图
   */
  requestNotification(triggerSource: TriggerSource, callBack?: Callback<boolean>): boolean {
    Log.info(TAG, `requestNotification triggerSource is ${triggerSource}`);
    if (this.notificationGranted !== undefined) {
      callBack?.(NotificationHelper.getInstance().isNotificationGranted());
      return false;
    }
    if (callBack) {
      this.waitResolves.push(callBack);
    }
    if (triggerSource <= this.triggerSource) {
      Log.info(TAG, `requestNotification this.triggerSource <= triggerSource`);
      return false;
    }
    this.triggerRequest(triggerSource);
    PreferencesUtil.putBooleanValue(preferencesFileName, isFirstInAppKey, false);
    return true;
  }

  private init() {
    this.isFirstInApp = PreferencesUtil.getBooleanValueSync(preferencesFileName, isFirstInAppKey, true);
    // 获取请求通知权限弹窗次数
    this.requestTimesInApp = PreferencesUtil.getNumberValueSync(preferencesFileName, requestTimesInAppKey, 0);
    // 获取上次请求通知权限弹窗时间戳
    this.lastRequestTimeInApp =
      PreferencesUtil.getNumberValueSync(preferencesFileName, lastRequestTimeInAppKey, Date.now());

    if (this.requestTimesInApp === 0) {
      // 还没有弹出过使能弹窗，本次日历进程不弹出跳转通知设置弹窗
      this.jumpToSetting = false;
      // 通知权限使能弹窗接受或拒绝后，触发回调记录次数1
      this.waitResolves.push(() => {
        PreferencesUtil.putNumberValue(preferencesFileName, requestTimesInAppKey, 1);
      })
    }
  }

  private triggerRequest(triggerSource: TriggerSource): void {
    this.triggerSource = triggerSource;
    if (triggerSource === TriggerSource.TRIGGER_NOTIFICATION_BUSINESS) {
      this.clearInterval();
      this.doRequestNotification();
      return;
    }
    if (triggerSource === TriggerSource.BROWSE_APP && !this.isFirstInApp) {
      this.doRequestNotification();
      return;
    }
    Log.info(TAG, `requestNotification isFirstInApp true`);
    this.timeOutId = setTimeout(() => {
      this.doRequestNotification();
    }, DELAY_MILLS);
  }

  private async doRequestNotification() {
    if (this.hasRequestNotification) {
      return;
    }
    this.hasRequestNotification = true;
    this.notificationGranted = await NotificationHelper.getInstance().requestNotification();
    this.notifyResolve(this.notificationGranted);
  }

  private clearInterval() {
    if (this.timeOutId <= 0) {
      return;
    }
    clearInterval(this.timeOutId);
    this.timeOutId = -1;
  }

  private notifyResolve(isNotificationGranted: boolean) {
    if (EmptyUtils.isEmptyArray(this.waitResolves)) {
      return;
    }
    for (let waitResolve of this.waitResolves) {
      waitResolve(isNotificationGranted);
    }
    this.waitResolves = [];
  }

  /**
   * 是否弹出 供用户跳转设置打开通知权限的窗口
   * 弹出时机，第二次进入，之后间隔三天、七天、十五天打开弹窗。
   * @returns true 打开 false 不打开
   */
  isAboutToOpenDialog(): boolean {
    if (!this.jumpToSetting) {
      return false;
    }
    let current = Date.now();
    let diffDays: number = DateUtil.getDiffDays(this.lastRequestTimeInApp, current);
    Log.info(TAG, `isAboutToOpenDialog requestTimesInApp:${this.requestTimesInApp} diffDays:${diffDays}`);
    switch (this.requestTimesInApp) {
      case 1:
        // 已经跳出过请求通知权限弹窗，此次为第二次
        break;
      case 2:
        if (diffDays < REQUEST_AFTER_SECOND) {
          return false;
        }
        break;
      case 3:
        if (diffDays < REQUEST_AFTER_THIRD) {
          return false;
        }
        break;
      case 4:
        if (diffDays < REQUEST_AFTER_FOURTH) {
          return false;
        }
        break;
      default:
        return false;
    }
    this.requestTimesInApp = this.requestTimesInApp + 1;
    PreferencesUtil.putNumberValue(preferencesFileName, requestTimesInAppKey, this.requestTimesInApp);
    PreferencesUtil.putNumberValue(preferencesFileName, lastRequestTimeInAppKey, current);
    this.lastRequestTimeInApp = current;
    return true;
  }
}