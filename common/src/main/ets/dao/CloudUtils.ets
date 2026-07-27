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

import dataShare from '@ohos.data.dataShare';
import { Log } from '../default/common/Log';
import lazy { GlobalThis } from '../data/GlobalThis';
import { HiEventParamsConfirm, ReportHiEventParams, ReportUtil, SqlFaultHandle } from '../default/util/ReportUtil';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { CALENDAR_BUNDLE_NAME, CLOUD_DRIVE_BUNDLE_NAME } from '../constants/Constants';
import { CalendarAccountType } from '../account/AccountConst';
import { behaviorEvents } from '../../../..';
import Want from '@ohos.app.ability.Want';
import lazy { bundleManager } from '@kit.AbilityKit';

const TAG: string = 'CloudUtils';

// 云空间同步开关订阅uri
const SUBSCRIBE_URI: string = 'datashareproxy://com.openharmony.clouddrive/sync_switch?bundleName=com.openharmony.calendar';

// 云空间同步开关查询uri
const QUERY_URI: string = 'datashareproxy://com.openharmony.clouddrive/sync_switch';

// 云空间同步开关字段名
const COLUMN_SWITCH = 'isSwitchOn';

export const CACHE_SYNC_SWITCH_STATUS: string = 'cloudSyncState';

const SWITCH_ON: number = 1;

export const IS_SUPPORT_CLOUD_SYNC: string = 'isSupportCloudSync';

export class CloudUtils {
  public static readonly INSTANCE: CloudUtils = new CloudUtils();
  private CloudDsHelper: dataShare.DataShareHelper | null = null;
  private static hasSubscriberSyncSwitchStatus = false;

  private constructor() {
  }

  /*
   * 订阅云空间开关状态
   */
  static async subscribedSyncSwitchStatus(): Promise<void> {
    PersistentStorage.persistProp(CACHE_SYNC_SWITCH_STATUS, false);
    PersistentStorage.persistProp(IS_SUPPORT_CLOUD_SYNC, false);
    if (!CloudUtils.isCloudAppExist()) {
      Log.warn(TAG, `subscribedSyncSwitchStatus isCloudAppExist false no need subscriber`);
      return;
    }
    const cloudDsHelper: dataShare.DataShareHelper | null = await CloudUtils.INSTANCE.getCloudDsHelper();
    if (!cloudDsHelper) {
      Log.warn(TAG, `subscribedSyncSwitchStatus getCloudDsHelper err ${cloudDsHelper}`);
      PersistentStorage.persistProp(IS_SUPPORT_CLOUD_SYNC, false);
      return;
    }
    CloudUtils.hasSubscriberSyncSwitchStatus = true;
    cloudDsHelper.on('dataChange', SUBSCRIBE_URI, () => CloudUtils.fetchCloudSyncSwitch());
    CloudUtils.fetchCloudSyncSwitch();
  }

  /**
   * 云app是否存在
   */
  public static isCloudAppExist(): boolean {
    let isCloudAppExist = true;
    const cloudBundleName = 'com.openharmony.clouddrive';
    try {
      isCloudAppExist = bundleManager.isApplicationEnabledSync(cloudBundleName);
    } catch (error) {
      Log.logErrorMsg(TAG, `isCloudAppExist isApplicationEnabledSync`, error);
      isCloudAppExist = false;
    }
    return isCloudAppExist;
  }

  /*
   * 取消订阅云空间开关状态
   */
  static async unSubscribedSyncSwitchStatus(): Promise<void> {
    if (!CloudUtils.hasSubscriberSyncSwitchStatus) {
      Log.warn(TAG, `unSubscribedSyncSwitchStatus hasSubscriberSyncSwitchStatus false no need unSubscriber`);
      return;
    }
    const cloudDsHelper: dataShare.DataShareHelper | null = await CloudUtils.INSTANCE.getCloudDsHelper();
    if (!cloudDsHelper) {
      Log.warn(TAG, `unSubscribedSyncSwitchStatus getCloudDsHelper err ${cloudDsHelper}`);
      return;
    }
    cloudDsHelper.off('dataChange', SUBSCRIBE_URI);
  }

  static jumpCloudDrivePage() {
    const want: Want = {
      'bundleName': CLOUD_DRIVE_BUNDLE_NAME,
      'action': 'action.system.home',
      'entities': ['entity.system.home'],
      'parameters': { 'channelRefer': 1 }
    };
    try {
      const context = GlobalThis.getInstance().context;
      if (context) {
        context.startAbility(want);
      } else {
        Log.warn(TAG, `jumpCloudDrivePage get invalid context`);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'jumpCloudDrivePage', err);
    }
  }

  static isSupportCloudSync(): boolean {
    return AppStorage.get(IS_SUPPORT_CLOUD_SYNC) ?? false;
  }

  static isCloudSyncOpened(): boolean {
    return AppStorage.get(CACHE_SYNC_SWITCH_STATUS) ?? false;
  }

  private static reportCloudSyncStatus(status: number) {
    let params: ReportHiEventParams = {
      IS_ON: status
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.clickCalendarCloudSync, params);
  }

  /*
   * 获取云空间开关状态
   */
  private static async fetchCloudSyncSwitch() {
    const cloudDsHelper: dataShare.DataShareHelper | null = await CloudUtils.INSTANCE.getCloudDsHelper();
    if (!cloudDsHelper) {
      Log.warn(TAG, `getCloudDsHelper err ${cloudDsHelper}`);
      AppStorage.setOrCreate(IS_SUPPORT_CLOUD_SYNC, false);
      CloudUtils.reportCloudSyncStatus(HiEventParamsConfirm.FALSE);
      return;
    }
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo('bundleName', CALENDAR_BUNDLE_NAME);
    const resultSet = await cloudDsHelper.query(QUERY_URI, predicates, [COLUMN_SWITCH]);
    if (!resultSet || !resultSet.goToFirstRow()) {
      Log.info(TAG, `fetchCloudSyncSwitch get invalid resultset`);
      CloudUtils.reportCloudSyncStatus(HiEventParamsConfirm.FALSE);
      AppStorage.setOrCreate(IS_SUPPORT_CLOUD_SYNC, false);
      return;
    }
    AppStorage.setOrCreate(IS_SUPPORT_CLOUD_SYNC, true);
    CloudUtils.reportCloudSyncStatus(HiEventParamsConfirm.TRUE);
    try {
      const index: number = resultSet.getColumnIndex(COLUMN_SWITCH);
      if (index < 0) {
        Log.info(TAG, `fetchCloudSyncSwitch no such column`);
        return;
      }
      const value: string = resultSet.getString(index);
      if (Number.isInteger(value)) {
        Log.warn(TAG, `fetchCloudSyncSwitch not integer`);
        return;
      }
      const isSwitchOn: Boolean = Number.parseInt(value) === SWITCH_ON;
      Log.info(TAG, 'fetchCloudSyncSwitch result = ' + isSwitchOn);
      AppStorage.setOrCreate(CACHE_SYNC_SWITCH_STATUS, isSwitchOn);
    } catch (err) {
      Log.info(TAG, `fetchCloudSyncSwitch get err ${err}`);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  private async getCloudDsHelper(): Promise<dataShare.DataShareHelper | null> {
    const context = GlobalThis.getInstance().context;
    if (!context) {
      Log.warn(TAG, `getCloudDsHelper context null`);
      return null;
    }
    try {
      if (!this.CloudDsHelper) {
        this.CloudDsHelper = await dataShare.createDataShareHelper(context,
          QUERY_URI, { isProxy: true, waitTime: 3 });
      }
    } catch (err) {
      Log.warn(TAG, `createDataShareHelper err ${err}`)
      SqlFaultHandle.initSqlFail(err?.message, TAG)
    }
    Log.info(TAG, 'getDsHelper CloudDsHelper is ' + this.CloudDsHelper);
    return new Promise((resolve) => {
      resolve(this.CloudDsHelper)
    });
  }
}

/**
 * 判断帐户是否支持上云，支持上云的帐户删除时需提示从云删除，反之不提示从云删除
 *
 * @param accountName 帐户name
 * @param accountType 帐户type
 * @returns 是否支持云同步的帐户类型
 */
export function isSyncAbleAccount(accountName: string, accountType: string) {
  return accountType === CalendarAccountType.LOCAL_ACCOUNT_TYPE;
}

/**
 * 判断帐户是否支持上云，支持上云的帐户显示 【开启日历云同步】提示
 * 开启云同步提示语跟账户不建立联系；此提示语只在全部日程列表显示
 *
 * @param accountType 帐户type
 * @returns 是否显示提示的帐户类型
 */
export function isNewSyncAbleAccount(accountType: string) {
  return accountType === CalendarAccountType.ALL_ACCOUNT_TYPE;
}
