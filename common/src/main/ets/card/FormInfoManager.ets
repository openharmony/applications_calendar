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

import lazy formInfo from '@ohos.app.form.formInfo';

import { FormBaseInfo } from './FormBaseInfo';

import data_preferences from '@ohos.data.preferences';
import { CardStorage, getStorage } from './CardStorage';
import HashMap from '@ohos.util.HashMap';
import { Log } from '../default/common/Log';
import { GlobalThis } from '../data/GlobalThis';
import lazy { FileUtils } from '../util/FileUtils';
import { maskString } from '../util/SensitiveStrUtils';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReportHiEventParams, ReportUtil } from '../default/util/ReportUtil';
import { faultEvents } from '../default/common/HiEvents';

// 涉卡框，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG: string = 'FormInfoManager';
const storageMap: HashMap<string, CardStorage> = new HashMap<string, CardStorage>();

function getLatestStorage(name: string): CardStorage {
  let storage = new CardStorage(name);
  Log.info(TAG, `getLatestStorage: name is ${name}`);
  storageMap.set(name, storage);
  return storage;
}

/**
 * 卡片基本信息缓存管理工具类
 */
class FormInfoManager {
  private static SP_FILE_NAME = 'form_base_info';

  static saveFormInfo(formId: string, formName: string, formDimension: number) {
    if (!formId && !formName) {
      Log.warn(TAG, `saveFormInfo get invalid params: ${formId}, ${formName}`);
      return;
    }
    if (formDimension < 0 || formDimension === undefined) {
      Log.error(TAG, `saveFormInfo get invalid formDimension: ${formDimension}`);
      return;
    }
    Log.warn(TAG, `saveFormInfo formId: ${formId}`);
    const info: FormBaseInfo = new FormBaseInfo(formId);
    info.formName = formName;
    info.formDimension = formDimension;
    FormInfoManager.getStorage().set<FormBaseInfo>(formId, info);
  }

  static removeFormInfoByFormID(formId: string) {
    if (!formId) {
      Log.warn(TAG, `removeFormInfoByFormID get invalid params: ${formId}`);
      return;
    }
    Log.info(TAG, `removeFormInfoByFormID ${formId}`);
    FormInfoManager.getStorage().delete(formId);
  }

  static getFormInfo(formId: string): FormBaseInfo | undefined {
    const formInfo = FormInfoManager.getStorage().get<FormBaseInfo>(formId);
    Log.info(TAG, `getFormInfo from preference ${formInfo?.formName} ${formInfo?.formId}`);
    return formInfo;
  }

  static getFormName(formId: string): string {
    const info: FormBaseInfo | undefined = FormInfoManager.getFormInfo(formId);
    if (info) {
      return info.formName;
    }
    return '';
  }

  static getFormDimension(formId: string): number {
    const info: FormBaseInfo | undefined = FormInfoManager.getFormInfo(formId);
    if (info) {
      return info.formDimension;
    }
    return 0;
  }

  /**
   * 获取所有的卡片信息
   *
   * @returns 持久化缓存内的所有卡片信息
   */
  static getAllFormInfo(): FormBaseInfo[] {
    const abilityStageContext = GlobalThis.getInstance().abilityStageContext;
    if (abilityStageContext === null || abilityStageContext === undefined) {
      Log.error(TAG, `getAllFormInfo cardContext is null or undefined!`)
      return [];
    }
    const preferencesDir = abilityStageContext.preferencesDir ?? '';
    Log.info(TAG, `getAllFormInfo preferencesDir = ${maskString(preferencesDir)}`)
    let isFormBaseInfoExist = FileUtils.isFileExist(preferencesDir + '/' + FormInfoManager.SP_FILE_NAME);
    let isFormBaseInfoDbExist = FileUtils.isFileExist(preferencesDir + '/' + FormInfoManager.SP_FILE_NAME + '.db');
    Log.warn(TAG, `getAllFormInfo isFormBaseInfoExist ${isFormBaseInfoExist}, isFormBaseInfoDbExist ${isFormBaseInfoDbExist}`);

    if (!isFormBaseInfoExist && !isFormBaseInfoDbExist) {
      Log.error(TAG, `getAllFormInfo isFormBaseInfoExist false, isFormBaseInfoDbExist false`);
      return [];
    }

    // xml格式的preferences 文件
    if (isFormBaseInfoExist) {
      data_preferences.removePreferencesFromCacheSync(abilityStageContext, FormInfoManager.SP_FILE_NAME);
    }
    const allFormJson: string | undefined = FormInfoManager.getLatestStorage().getAllSync() ?? '';
    let resInfo: FormBaseInfo[] = [];
    try {
      Object.keys(allFormJson).forEach(key => {
        resInfo.push(JSON.parse(allFormJson[key]) as FormBaseInfo);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'getAllFormInfo', err);
    }
    return resInfo;
  }

  /**
   * 根据卡片的名称获取所有卡片信息
   *
   * @param formName 卡片名称
   * @returns 持久化缓存内的所有卡片信息
   */
  static getFormsByFromName(formName: string): FormBaseInfo[] {
    const info: FormBaseInfo[] | undefined = FormInfoManager.getAllFormInfo();
    let resInfo: FormBaseInfo[] = [];
    if (info) {
      info.forEach((formInfo: FormBaseInfo) => {
        if (formInfo.formName === formName) {
          resInfo.push(formInfo);
        }
      })
    }
    return resInfo;
  }

  /**
   * 根据卡片的名称获取所有卡片的formId
   * @param formName 卡片名称
   * @returns 符合条件的formId
   */
  static getFormIdsByFromName(formName: string): string[] {
    const info: FormBaseInfo[] | undefined = FormInfoManager.getAllFormInfo();
    let resIds: string[] = [];
    if (info) {
      info.forEach((formInfo: FormBaseInfo) => {
        if (formInfo.formName === formName) {
          resIds.push(formInfo.formId);
        }
      })
    }
    return resIds;
  }

  static isCard2x2(formId?: string, formDimension?: number): boolean {
    if (formDimension !== null && formDimension !== undefined) {
      return formDimension === formInfo.FormDimension.Dimension_2_2;
    }
    if (!formId) {
      Log.warn(TAG, `isCard2x2 Both formId and formDimension are invalid.`);
      return false;
    }
    return FormInfoManager.getFormDimension(formId) === formInfo.FormDimension.Dimension_2_2;
  }

  static isCard2x4(formId?: string, formDimension?: number): boolean {
    if (formDimension !== null && formDimension !== undefined) {
      return formDimension === formInfo.FormDimension.Dimension_2_4;
    }
    if (!formId) {
      Log.warn(TAG, `isCard2x4 Both formId and formDimension are invalid.`);
      return false;
    }
    return FormInfoManager.getFormDimension(formId) === formInfo.FormDimension.Dimension_2_4;
  }

  static isCard4x4(formId?: string, formDimension?: number): boolean {
    if (formDimension !== null && formDimension !== undefined) {
      return formDimension === formInfo.FormDimension.Dimension_4_4;
    }
    if (!formId) {
      Log.warn(TAG, `isCard4x4 Both formId and formDimension are invalid.`);
      return false;
    }
    return FormInfoManager.getFormDimension(formId) === formInfo.FormDimension.Dimension_4_4;
  }

  private static getStorage() {
    return getStorage(FormInfoManager.SP_FILE_NAME);
  }

  private static getLatestStorage() {
    return getLatestStorage(FormInfoManager.SP_FILE_NAME);
  }

  /**
   * 清理form_base_info文件中的卡片脏数据
   */
  static deleteDirtyCardData() {
    const cardInfos: FormBaseInfo[] = FormInfoManager.getAllFormInfo();
    if (cardInfos.length < 50) {
      Log.warn(TAG, `deleteDirtyCardData cardInfos.length: ${cardInfos.length}`);
      return;
    }
    try {
      // 获取桌面所有卡片信息
      formProvider.getPublishedRunningFormInfos().then((runningFormInfos: formInfo.RunningFormInfo[]) => {
        Log.info(TAG, `deleteDirtyCardData runningFormInfos: ${runningFormInfos.length}`);
        let removeCount: number = 0;
        // 循环遍历cardInfos，若桌面不存在某个id则从sp文件中删除
        cardInfos.forEach((cardInfo: FormBaseInfo) => {
          const formId: string = cardInfo.formId;
          const isExist: boolean = runningFormInfos.some(runningFormInfo => runningFormInfo.formId === formId);
          if (isExist) {
            Log.info(TAG, `deleteDirtyCardData ${formId} is exist.`);
          } else {
            Log.error(TAG, `deleteDirtyCardData ${formId} is not exist, need to remove.`);
            FormInfoManager.removeFormInfoByFormID(formId);
            removeCount++;
          }
        });
        // 上报故障打点
        if (removeCount > 0) {
          let params: ReportHiEventParams = {
            DELETE_DIRTY_CARD_COUNT: removeCount
          }
          ReportUtil.reportFaultEvent(faultEvents.removeDirtyCardInfo, params);
        }
      }).catch((error: BusinessError) => {
        Log.logErrorMsg(TAG, 'getPublishedRunningFormInfos', error);
      })
    } catch (error) {
      Log.logErrorMsg(TAG, 'deleteDirtyCardData', error);
    }
  }
}

export {
  FormInfoManager
}