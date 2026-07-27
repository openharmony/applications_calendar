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

import { EmptyUtils, Log, MigrateEventDataKeys, PreferencesFiles, PreferencesUtil, TypeUtils } from '@app/common';

const TAG = 'EventIdFinder';

/*
 * MigrateType 迁移类型
 */
export enum MigrateType {
  SINGLE_CLONE_SINGLE = 1000,
  DOUBLE_CLONE_SINGLE = 1001,
  DOUBLE_UPDATE_SINGLE = 1002,
}

export class FormInfo {
  public readonly eventUuid: string;
  public readonly eventId: number;
  public readonly formId: string;

  constructor(eventUuid: string, eventId: number, formId: string) {
    this.eventUuid = eventUuid;
    this.eventId = eventId;
    this.formId = formId;
  }

  public isValid(): boolean {
    if (EmptyUtils.isEmptyString(this.formId)) {
      Log.warn(TAG, `isValid false formId is empty`);
      return false;
    }
    if (EmptyUtils.isEmptyString(this.eventUuid)) {
      Log.warn(TAG, `isValid false eventUuid is empty`);
      return false;
    }
    if (EmptyUtils.isUndefinedOrNull(this.eventId) || this.eventId < 1) {
      Log.warn(TAG, `isValid false formInfo is eventId is ${this.eventId} illeagl`);
      return false;
    }
    return true;
  }
}

export class EventIdInfo {
  public readonly newEventId: number;
  public readonly oldEventId: number;

  constructor(newEventId: number, oldEventId: number) {
    this.newEventId = newEventId;
    this.oldEventId = oldEventId;
  }

  public isValid(): boolean {
    if (EmptyUtils.isUndefinedOrNull(this.newEventId) || this.newEventId < 1) {
      Log.warn(TAG, `isValid false formInfo is newEventId is ${this.newEventId} illeagl`);
      return false;
    }
    if (EmptyUtils.isUndefinedOrNull(this.oldEventId) || this.oldEventId < 1) {
      Log.warn(TAG, `isValid false formInfo is oldEventId is ${this.oldEventId} illeagl`);
      return false;
    }
    return true;
  }
}

export class EventIdFinder {
  /**
   * 双升单是新旧的formId 和EventId 都是 没有变化的
   * @param fromId
   * @returns
   */
  public findEventId(migrateType: number, formId: string): number | undefined {
    Log.info(TAG, `findEventId migrateType is ${migrateType} fromId is ${formId}`);
    const isValidMigrateType = this.isValidMigrateType(migrateType);
    if (!isValidMigrateType) {
      Log.warn(TAG, `findEventId isValidMigrateType false`);
      return undefined;
    }
    const allFormInfoJsonString = PreferencesUtil.getStringValueSync(PreferencesFiles.IMPORTANT_DAY_FROM_CARD_INFO, MigrateEventDataKeys.MIGRATE_FORM_INFO_KEY, '');
    if (EmptyUtils.isEmptyString(allFormInfoJsonString) || !TypeUtils.isString(allFormInfoJsonString)) {
      Log.warn(TAG, `findEventId getAllValueSync fail ${allFormInfoJsonString.toString()}`);
      return undefined;
    }
    let formInfos: FormInfo[] = [];
    try {
      formInfos = JSON.parse(allFormInfoJsonString);
    } catch (error) {
      Log.logErrorMsg(TAG, `parse from json failed: ${error?.message}`);
    }
    let targetFormInfo: FormInfo | undefined = undefined;
    for (let formInfo of formInfos) {
      if (formInfo.formId === formId) {
        targetFormInfo = formInfo;
        break
      }
    }
    if (!targetFormInfo) {
      Log.warn(TAG, `findEventId no targetFormInfo find`);
      return undefined;
    }
    if (migrateType == MigrateType.DOUBLE_UPDATE_SINGLE) {
      Log.info(TAG, `findEventId hit target eventId ${targetFormInfo.eventId}`);
      return targetFormInfo.eventId;
    }
    if (migrateType === MigrateType.DOUBLE_CLONE_SINGLE || migrateType === MigrateType.SINGLE_CLONE_SINGLE) {
      const cachedEventIdInfos = this.getCachedEventIdInfos();
      const oldEventId = targetFormInfo.eventId;
      for (let cachedEventIdInfo of cachedEventIdInfos) {
        if (cachedEventIdInfo.oldEventId === oldEventId) {
          Log.info(TAG, `findEventId hit oldEventId ${oldEventId} newId is ${cachedEventIdInfo.newEventId}`);
          return cachedEventIdInfo.newEventId;
        }
      }
      Log.info(TAG, `findEventId oldEventId ${oldEventId} not hit`);
      return undefined;
    }
    Log.info(TAG, `findEventId migrateType is ${migrateType} not support`);
    return undefined;
  }

  private isValidMigrateType(migrateType: number): boolean {
    if (migrateType !== MigrateType.SINGLE_CLONE_SINGLE &&
      migrateType !== MigrateType.DOUBLE_CLONE_SINGLE &&
      migrateType !== MigrateType.DOUBLE_UPDATE_SINGLE) {
      return false;
    }
    return true;
  }

  private getCachedEventIdInfos(): EventIdInfo[] {
    const migrateData = PreferencesUtil.getStringValueSync(PreferencesFiles.IMPORTANT_DAY_FROM_CARD_INFO, MigrateEventDataKeys.MIGRATE_EVENT_DATA_KEY, '');
    if (EmptyUtils.isEmptyString(migrateData)) {
      Log.info(TAG, `getCachedEventIdInfos migrateData is empty`);
      return [];
    }
    try {
      return JSON.parse(migrateData) ?? [];
    } catch (error) {
      Log.logErrorMsg(TAG, `getCachedEventIdInfos parse error `, error);
    }
    return [];
  }
}