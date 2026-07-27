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

import lazy abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import lazy bundleManager from '@ohos.bundle.bundleManager';
import { Log } from '../default/common/Log';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { GlobalThis } from '../data/GlobalThis';

// 涉及权限获取，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG = 'PermissionUtil';
const PERMISSION_READ_CONTACTS: Permissions = 'ohos.permission.READ_CONTACTS';

let sTokenId: number = -1;

export enum CommonGrantStatus {
  PERMISSION_DIALOG_SHOW_DENIED = 0,
  PERMISSION_DIALOG_NOT_SHOW_DENIED,
  PERMISSION_GRANTED
}

/**
 * 权限工具类
 */

export async function checkPermissionGrantedState(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
  // 获取应用程序的accessTokenID
  let tokenId: number = await getAppTokenID();
  if (tokenId == -1) {
    Log.warn(TAG, `checkPermissionGrantedState getAppTokenID failed`);
    return grantStatus;
  }
  // 校验应用是否被授予权限
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    Log.info(TAG, `checkPermissionGrantedState permission ${permission} grantStatus is ${grantStatus}`);
  } catch (err) {
    Log.error(TAG, `checkPermissionGrantedState failed, code is ${err.code}, message is ${err.message}`);
  }
  return grantStatus;
}


/**
 * 检查多个权限是否被授予
 * @param permissions
 * @returns
 */
export async function checkIsPermissionsGranted(permissions: Array<Permissions>): Promise<boolean> {
  return Promise.all(permissions.map((permission: Permissions) => {
    return checkPermissionGrantedState(permission);
  })).then((permissionResults: Array<abilityAccessCtrl.GrantStatus>) => {
    return permissionResults.every((singlePermissionResult: abilityAccessCtrl.GrantStatus) => {
      return abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED == singlePermissionResult;
    })
  })
}

/**
 * 请求权限
 */
export async function requestPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  return atManager.requestPermissionsFromUser(context, permissions).then((data: PermissionRequestResult) => {
    Log.info(TAG, 'requestPermissionsFromUser result start');
    if (!data) {
      Log.warn(TAG, 'requestPermissionsFromUser result data is null');
      return false;
    }
    return data.authResults.every((singleResult: number) => {
      if (abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED !== singleResult) {
        Log.warn(TAG, `requestPermissionsFromUser singlePermission deny`);
      }
      return abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED === singleResult;
    })
  }).catch((err: BusinessError) => {
    Log.logErrorMsg(TAG, 'requestPermissionsFromUser', err);
    return false;
  })
}

/**
 * 请求权限-区分系统授权弹窗是否显示
 */
export async function requestPermissionsFromUserDialogShow(
  permissions: Array<Permissions>, context: common.UIAbilityContext): Promise<CommonGrantStatus> {
  const atManager = abilityAccessCtrl.createAtManager();
  return atManager.requestPermissionsFromUser(context, permissions).then((data: PermissionRequestResult) => {
    Log.info(TAG, 'requestPermissionsFromUserDialogShow result start');
    if (!data) {
      Log.warn(TAG, 'requestPermissionsFromUserDialogShow result data is null');
      return CommonGrantStatus.PERMISSION_DIALOG_NOT_SHOW_DENIED;
    }
    let isGranted = data.authResults.every((singleResult: number) => {
      if (abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED !== singleResult) {
        Log.warn(TAG, `requestPermissionsFromUserDialogShow singlePermission deny`);
      }
      return abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED === singleResult;
    })

    if (isGranted) {
      return CommonGrantStatus.PERMISSION_GRANTED;
    }

    if (data.dialogShownResults && data.dialogShownResults.length > 0 && data.dialogShownResults[0]) {
      return CommonGrantStatus.PERMISSION_DIALOG_SHOW_DENIED;
    }

    return CommonGrantStatus.PERMISSION_DIALOG_NOT_SHOW_DENIED;
  }).catch((err: BusinessError) => {
    Log.logErrorMsg(TAG, 'requestPermissionsFromUserDialogShow', err);
    return CommonGrantStatus.PERMISSION_DIALOG_NOT_SHOW_DENIED;
  })
}


async function getAppTokenID(): Promise<number> {
  if (sTokenId != -1) {
    return sTokenId;
  }
  try {
    let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    sTokenId = appInfo.accessTokenId;
  } catch (err) {
    Log.error(TAG, `getBundleInfoForSelf failed, code is ${err?.code}, message is ${err?.message}`);
  }
  return sTokenId;
}

async function requestReadContactPermission(): Promise<boolean> {
  const context = GlobalThis.getInstance().context;
  if (!context) {
    return false;
  }
  const permissions: Permissions[] = [PERMISSION_READ_CONTACTS];
  let hasPermission: boolean = await requestPermissionsFromUser(permissions, context);
  if (hasPermission) {
    return true;
  }
  Log.warn(TAG, 'Do not have read contact permission!');
  return false;
}

async function requestReadContactPermissionDialogShow(): Promise<CommonGrantStatus> {
  const context = GlobalThis.getInstance().context;
  if (!context) {
    return CommonGrantStatus.PERMISSION_DIALOG_NOT_SHOW_DENIED;
  }
  const permissions: Permissions[] = ['ohos.permission.READ_CONTACTS'];
  let commonGrantStatus: CommonGrantStatus = await requestPermissionsFromUserDialogShow(permissions, context);
  return commonGrantStatus;
}

export async function checkReadContactPermission() {
  const permissions: Permissions[] = [PERMISSION_READ_CONTACTS];
  const hasPermission = await checkIsPermissionsGranted(permissions)
    .then((isAllPerGranted: boolean): Promise<boolean> => {
      if (!isAllPerGranted) {
        Log.warn(TAG, `checkIsPermissionsGranted isAllPerGranted false`);
        return requestReadContactPermission();
      }
      return new Promise((resolve) => {
        resolve(true)
      });
    })
    .catch((err: Error): Promise<boolean> => {
      Log.logErrorMsg(TAG, 'checkReadContactPermission->checkIsPermissionsGranted', err);
      return requestReadContactPermission();
    })

  return hasPermission;
}

export async function checkReadContactPermissionDialogShow() {
  const permissions: Permissions[] = ['ohos.permission.READ_CONTACTS'];
  return await checkIsPermissionsGranted(permissions)
    .then((isAllPerGranted: boolean): Promise<CommonGrantStatus> => {
      if (!isAllPerGranted) {
        Log.warn(TAG, `checkIsPermissionsGranted isAllPerGranted false`);
        return requestReadContactPermissionDialogShow();
      }
      return new Promise((resolve) => {
        resolve(CommonGrantStatus.PERMISSION_GRANTED)
      });
    })
    .catch((err: Error): Promise<CommonGrantStatus> => {
      Log.logErrorMsg(TAG, 'checkReadContactPermissionDialogShow->checkIsPermissionsGranted', err);
      return requestReadContactPermissionDialogShow();
    })
}

export async function redirectAuthContactsSetting(context: common.UIAbilityContext) {
  let atManager:abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  atManager.requestPermissionOnSetting(context, ['ohos.permission.READ_CONTACTS']).
    then((data:Array<abilityAccessCtrl.GrantStatus>)=>{
    Log.info(TAG, `requestPermissionOnSetting success`);
  }).catch((err:BusinessError)=>{
    Log.error(TAG, `errcode: ${err?.code} errmsg: ${err?.message}`);
  });
}