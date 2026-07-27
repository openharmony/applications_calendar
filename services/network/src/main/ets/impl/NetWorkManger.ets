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

import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesFiles';
import { SettingPreferencesKeys } from '@app/common/src/main/ets/default/util/preferences_util/SettingPreferencesKeys';
import { PermissionState } from '@app/common/src/main/ets/default/common/declare';
import { SingleInstanceHelper } from '@app/common/src/main/ets/templates/SingleInstanceHelper';
import { GlobalData } from '@app/common/src/main/ets/data/GlobalData';
import { HiEventParamsConfirm, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { statisticEvents } from '@app/common/src/main/ets/default/common/HiEvents';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { HAGHelper } from '../onelink/HAGHelper';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { PermissionService } from '@app/common/src/main/ets/service/implements/permissionservice/PermissionService';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { emitter } from '@kit.BasicServicesKit';
import { CommonInnerEvent } from '@app/common/src/main/ets/event/CommonInnerEvent';
import { GlobalDataKeys } from '@app/common/src/main/ets/data/GlobalDataKeys';
import { ModeUtil, StatementStateKeys } from '@app/common';

const TAG = 'NetWorkManger'

type PermissionChangedCall = (isUserAgreeNetWork: boolean) => void;

/**
 * 用户请求网络管理
 */
export class NetWorkManger {
  private userNetWorkState: PermissionState = PermissionState.UNCONFIRMED;
  private permissionChangedListeners: PermissionChangedCall[] = [];
  private isUserNetWorkGranted: boolean = false;

  constructor() {
    this.init();
  }

  static getInstance(): NetWorkManger {
    return SingleInstanceHelper.createOrGet(NetWorkManger, TAG);
  }

  public isUserAgreeNetWorkSync(): boolean {
    return this.isUserNetWorkGranted;
  }

  async isUserAgreeNetWork(): Promise<boolean> {
    return this.isUserNetWorkGranted;
  }

  async updateUserNetWorkState(userNetWorkState: PermissionState) {
    const isAllowNetWork: boolean = userNetWorkState == PermissionState.CONFIRMED;
    this.userNetWorkState = userNetWorkState;
    this.isUserNetWorkGranted = isAllowNetWork;
    await PreferencesUtil.putNumberValue(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_ALLOW_NETWORK, userNetWorkState);
    // 如果首选项文件里没有这个key,表示没有通过克隆等方式克隆过这个key
    if (!PreferencesUtil.queryHasSyncBySync(PreferencesFiles.SETTINGS, SettingPreferencesKeys.IS_RECESS_TOGGLE_ON)) {
      // 变更设置页面的对应的开关状态
      const recessToggleState: number = isAllowNetWork ? 1 : 0;
      await PreferencesUtil.putNumberValue(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, recessToggleState);
      GlobalData.instance().set(GlobalDataKeys.IS_RECESS_TOGGLE_ON, recessToggleState);
      if (isAllowNetWork) {
        if (GlobalData.instance().get(GlobalDataKeys.IS_RECESS_TOGGLE_ON)) {
          emitter.emit({
            eventId: CommonInnerEvent.UPDATE_RECESS
          });
        }
      }
    } else {
      Log.info(TAG, `updateUserNetWorkState queryHasSyncBySync true`);
      const enableRecess = PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, 0) === 1;
      if (enableRecess && isAllowNetWork) {
        GlobalData.instance().set(GlobalDataKeys.IS_RECESS_TOGGLE_ON, true);
        emitter.emit({
          eventId: CommonInnerEvent.UPDATE_RECESS
        });
      }
    }
    if (isAllowNetWork) {
      HAGHelper.instance().init();
    }
    let eventData: emitter.EventData = {
      data: {
        'isAllowNetWork': isAllowNetWork
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.PERMISSION_NETWORK}, eventData);
    let params: ReportHiEventParams = {
      IS_ON: isAllowNetWork ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE
    }
    this.dispatchPermissionChanged();
    ReportUtil.reportStatisticEvent(statisticEvents.networkingPopup, params);
  }

  addNetWorkPermissionChangedListener(permissionChangedCall: PermissionChangedCall): boolean {
    if (!permissionChangedCall) {
      Log.warn(TAG, 'addNetWorkPermissionChangedListener permissionChangedListener is null');
      return false;
    }
    if (this.permissionChangedListeners.includes(permissionChangedCall)) {
      return false;
    }
    this.permissionChangedListeners.push(permissionChangedCall);
    return true;
  }

  removeNetWorkPermissionChangedListener(permissionChangedCall: PermissionChangedCall): boolean {
    if (!permissionChangedCall) {
      Log.warn(TAG, 'removeNetWorkPermissionChangedListener permissionChangedListener is null');
      return false;
    }
    const index = this.permissionChangedListeners.indexOf(permissionChangedCall);
    if (index < 0 || index >= this.permissionChangedListeners.length) {
      return false;
    }
    this.permissionChangedListeners.splice(index, 1);
    return true;
  }

  public init() {
    this.isUserNetWorkGranted = PreferencesUtil.getBooleanValueSync(PreferencesFiles.STATEMENT_STATE,
      StatementStateKeys.KEY_IS_AGREE_STATEMENT, true);
    PreferencesUtil.putNumberValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_ALLOW_NETWORK,
      this.isUserNetWorkGranted ? PermissionState.CONFIRMED : PermissionState.UNCONFIRMED);
  }

  private dispatchPermissionChanged() {
    for (let listener of this.permissionChangedListeners) {
      listener(this.isUserNetWorkGranted);
    }
  }
}
