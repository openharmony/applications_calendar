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

import { PreferencesFiles } from '../default/util/preferences_util/PreferencesFiles';
import { PreferencesUtil } from '../default/util/preferences_util/PreferencesUtil';
import { MigrateFromEventDataKeys } from '../default/util/preferences_util/MigrateEventDataKeys';
import { EmptyUtils } from '../util/EmptyUtils';
import { Log } from '../default/common/Log';
import { DoubleFormBaseInfo } from './DoubleFormBaseInfo';
import { getLatestStorage, getStorage } from './CardStorage';

const TAG: string = 'DoubleFormInfoManager';

/**
 * 双框架卡片基本信息缓存管理工具类
 */
class DoubleFormInfoManager {
  private static SP_FILE_NAME = 'double_form_base_info';

  static saveAllDoubleFormInfo(migrateType: number) {
    const statementState = PreferencesUtil.getNumberValueSync(PreferencesFiles.DOUBLE_SP_STATE,
      MigrateFromEventDataKeys.MIGRATE_IS_AGREE);
    const formIds = PreferencesUtil.getStringArrayValueSync(PreferencesFiles.MIGRATE_BASE_FORM,
      MigrateFromEventDataKeys.MIGRATE_BASE_FORM_INFO_KEY);
    if (EmptyUtils.isEmptyArray(formIds)) {
      Log.warn(TAG, `saveAllDoubleFormInfo formIds is invalid`);
      return;
    }

    for (let formId of formIds) {
      DoubleFormInfoManager.saveDoubleFormInfo(formId, statementState, migrateType)
    }
  }

  static saveDoubleFormInfo(formId: string, statementState: number, migrateType: number) {
    if (!formId && !migrateType && !statementState) {
      Log.warn(TAG, `saveDoubleFormInfo get invalid params: ${formId}`);
      return;
    }

    const info: DoubleFormBaseInfo = new DoubleFormBaseInfo(formId);
    info.formId = formId;
    info.migrateType = migrateType;
    info.statementState = statementState;
    DoubleFormInfoManager.getStorage().set<DoubleFormBaseInfo>(formId, info);
  }

  static getFormInfo(formId: string): DoubleFormBaseInfo | undefined {
    const formInfo = DoubleFormInfoManager.getLatestStorage().get<DoubleFormBaseInfo>(formId);

    Log.info(TAG, `getFormInfo from preference ${formInfo?.formId}`);
    return formInfo;
  }

  private static getStorage() {
    return getStorage(DoubleFormInfoManager.SP_FILE_NAME);
  }

  private static getLatestStorage() {
    return getLatestStorage(DoubleFormInfoManager.SP_FILE_NAME);
  }
}

export {
  DoubleFormInfoManager
}