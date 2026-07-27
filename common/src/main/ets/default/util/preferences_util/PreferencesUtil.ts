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

import type preferences from '@ohos.data.preferences';
import data_preferences from '@ohos.data.preferences';
import { Log } from '../../common/Log';
import LightWeightMap from '@ohos.util.LightWeightMap';
import { EmptyUtils } from '../../../util/EmptyUtils';
import { TypeUtils } from '../../../util/TypeUtils';
import { Result } from '../../../templates/Result';
import type common from '@ohos.app.ability.common';
import type { Callback } from '@kit.BasicServicesKit';
import lazy { FileIoUtil } from './FileIoUtil';

const DEFAULT_PREFERENCES_NAME = 'Preferences';
const TAG = 'PreferencesUtil';

export type SupportValueRawType = number | string | boolean;

export type SupportValueType = PreferencesValueType.NUMBER | PreferencesValueType.BOOLEAN | PreferencesValueType.STRING;

export const supportTypeNames = ['number', 'string', 'boolean'];

export const supportTypeMap: LightWeightMap<string, PreferencesValueType> = new LightWeightMap();

/**
 * 错误码
 */
export enum ErrorCode {
  CODE_PREFERENCES_NULL = -1100_001_001,
  CODE_HAS_NOT_SYNC = -1100_001_002,
  CODE_CONTEXT_NULL = -1100_001_003,
  CODE_VALUE_NULL = -1100_001_004,
  CODE_TYPE_ILLEGAL = -1100_001_005,
  CODE_TYPE_NOT_MATCH = -1100_001_006,
}


/**
 * PreferencesUtil 不能把PreferencesUtil实例暴露,也不能把PreferencesUtil里的preferences暴露
 */
export class PreferencesUtil {
  private static readonly preferencesMap: LightWeightMap<string, PreferencesUtil> = new LightWeightMap();
  private static context: common.Context | null;
  private preferences: data_preferences.Preferences;
  private preferencesFileName: string;

  constructor(preferencesFileName: string, preferences: data_preferences.Preferences) {
    this.preferencesFileName = preferencesFileName;
    this.preferences = preferences;
  }

  static init(context: common.Context): void {
    this.context = context;
    supportTypeMap.set('number', PreferencesValueType.NUMBER);
    supportTypeMap.set('string', PreferencesValueType.STRING);
    supportTypeMap.set('boolean', PreferencesValueType.BOOLEAN);
  }

  static async getNumberValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: number = 0): Promise<number> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getNumberValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getNumberValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: number = 0): number {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getNumberValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getPreferencesValue<T extends SupportValueRawType>(preferencesName: string,
                                                            key: string, defaultValue: T,
                                                            checkHasSync: boolean = false,
                                                            valueType: SupportValueType): Result<T> {
    let checkTypeResult = PreferencesUtil.checkType(defaultValue, valueType);
    if (!checkTypeResult.isSuccess()) {
      Log.warn(TAG, `getPreferencesValue preferencesName ${preferencesName} key ${key} check defaultValue fail ${checkTypeResult.toString()}`);
      return Result.copyResult(checkTypeResult, defaultValue);
    }
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      Log.warn(TAG, `getPreferencesValue preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
      return new Result(ErrorCode.CODE_PREFERENCES_NULL, 'preferencesUtil is null', defaultValue);
    }
    if (checkHasSync && !PreferencesUtil.queryHasSyncBySync(preferencesName, key)) {
      return new Result(ErrorCode.CODE_HAS_NOT_SYNC, 'value has not Sync', defaultValue);
    }
    try {
      const value = preferencesUtil.preferences.getSync(key, defaultValue) as T;
      checkTypeResult = PreferencesUtil.checkType(value, valueType);
      if (!checkTypeResult.isSuccess()) {
        Log.warn(TAG, `getPreferencesValue preferencesName ${preferencesName} key ${key} check value fail ${checkTypeResult.toString()}`);
        return Result.copyResult(checkTypeResult, defaultValue);
      }
      return Result.buildSuccessResult(value);
    } catch (error) {
      Log.logErrorMsg(TAG, 'getPreferencesValue', error);
      return Result.buildByErrorWithData(error, defaultValue);
    }
  }

  private static checkType(value: SupportValueRawType,
                           valueType: SupportValueType): Result<boolean> {
    if (EmptyUtils.isUndefinedOrNull(value)) {
      Log.warn(TAG, `checkType valueType ${valueType} value is null`);
      return new Result(ErrorCode.CODE_VALUE_NULL, 'value can not be null', false);
    }
    const type: string = typeof value;
    if (!supportTypeNames.includes(type)) {
      Log.warn(TAG, `checkType type is ${type} type illegal`);
      return new Result(ErrorCode.CODE_TYPE_ILLEGAL, 'type illegal', false);
    }
    if (supportTypeMap.get(type) !== valueType) {
      Log.warn(TAG, `checkType type type is ${type} valueType is ${valueType} not match`);
      return new Result(ErrorCode.CODE_TYPE_NOT_MATCH, 'type not match', false);
    }
    return Result.buildSuccessResult(true);
  }


  static async getStringValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: string = ''): Promise<string> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getStringValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getStringValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: string = ''): string {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getStringValue(key, defaultValue);
    }
    Log.warn(TAG, `getStringValueSync preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
    return defaultValue;
  }

  static async getBooleanValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: boolean = false): Promise<boolean> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getBooleanValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getBooleanValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: boolean = false): boolean {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getBooleanValue(key, defaultValue);
    }
    Log.warn(TAG, `getBooleanValueSync preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
    return defaultValue;
  }

  static async getNumberArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<number> = new Array()): Promise<Array<number>> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getNumberArrayValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getNumberArrayValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<number> = new Array()): Array<number> {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getNumberArrayValue(key, defaultValue);
    }
    Log.warn(TAG, `getNumberArrayValueSync preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
    return defaultValue;
  }

  static async getStringArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<string> = new Array()): Promise<Array<string>> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getStringArrayValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getStringArrayValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<string> = new Array()): Array<string> {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getStringArrayValue(key, defaultValue);
    }
    Log.warn(TAG, `getStringArrayValueSync preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
    return defaultValue;
  }

  static async getBooleanArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<boolean> = new Array()): Promise<Array<boolean>> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getBooleanArrayValue(key, defaultValue);
    }
    return defaultValue;
  }

  static getBooleanArrayValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<boolean> = new Array()): Array<boolean> {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.getBooleanArrayValue(key, defaultValue);
    }
    Log.warn(TAG, `getBooleanArrayValueSync preferencesName ${preferencesName} key ${key} failed preferencesUtil is null`);
    return defaultValue;
  }

  static getAllValueSync(preferencesName: string,): Result<Object | undefined> {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      Log.warn(TAG, `getAllValueSync preferencesName ${preferencesName} failed preferencesUtil is null`);
      return new Result(ErrorCode.CODE_PREFERENCES_NULL, `${preferencesName} preferencesUtil is null`, undefined);
    }
    try {
      return Result.buildSuccessResult(preferencesUtil.getAllValue());
    } catch (error) {
      return Result.buildByError(error);
    }
  }

  static async putNumberValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: number = 0, isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (preferencesUtil) {
      preferencesUtil.putNumberValue(key, value, isFlush);
    } else {
      Log.warn(TAG, `putNumberValue preferencesName ${preferencesName} key ${key} ` +
        `value ${value} failed preferencesUtil is null`);
    }
  }

  static putNumberValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: number = 0, isFlush: boolean = true): boolean {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.putNumberValue(key, value, isFlush);
    } else {
      Log.warn(TAG, `putNumberValueSync preferencesName ${preferencesName} key ${key} ` +
        `value ${value} failed preferencesUtil is null`);
      return false;
    }
  }

  static async putStringValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: string | null, isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    preferencesUtil?.putStringValue(key, value, isFlush);
  }

  static clearValueSync(preferencesName: string): void {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      Log.warn(TAG, `clearValueSync preferencesName ${preferencesName} failed preferencesUtil is null`);
    }
    preferencesUtil.clearValue();
  }

  static putStringValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: string | null, isFlush: boolean = true): boolean {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.putStringValue(key, value, isFlush);
    }
    Log.warn(TAG, `putStringValueSync preferencesName ${preferencesName} key ${key} ` +
      `value ${value} failed preferencesUtil is null`);
    return false;
  }

  static async putBooleanValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: boolean, isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    preferencesUtil?.putBooleanValue(key, value, isFlush);
  }

  static putBooleanValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: boolean, isFlush: boolean = true): boolean {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      Log.info(TAG, 'has preferencesUtil putBooleanValueSync');
      return preferencesUtil.putBooleanValue(key, value, isFlush);
    }
    Log.warn(TAG, `putBooleanValueSync preferencesName ${preferencesName} key ${key} ` +
      `value ${value} failed preferencesUtil is null`);
    return false;
  }

  static async putNumberArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<number> = new Array(), isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    preferencesUtil?.putNumberArrayValue(key, defaultValue, isFlush);
  }

  static putNumberArrayValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: Array<number>, isFlush: boolean = true): boolean {
    const preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.putNumberArrayValue(key, value, isFlush);
    }
    Log.warn(TAG, `putNumberArrayValueSync preferencesName ${preferencesName} key ${key} ` +
      `value ${value} failed preferencesUtil is null`);
    return false;
  }

  static async putStringArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<string> = new Array(), isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    preferencesUtil?.putStringArrayValue(key, defaultValue, isFlush);
  }

  static putStringArrayValueSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: Array<string>, isFlush: boolean = true): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.putStringArrayValue(key, value, isFlush);
    }
    Log.warn(TAG, `putStringArrayValueSync preferencesName ${preferencesName} key ${key} ` +
      `value ${value} failed preferencesUtil is null`);
    return false;
  }

  static async putBooleanArrayValue(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, defaultValue: Array<boolean> = new Array(), isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    preferencesUtil?.putBooleanArrayValue(key, defaultValue, isFlush);
  }

  static putBooleanArraySync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string, value: Array<boolean>, isFlush: boolean = true): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (preferencesUtil) {
      return preferencesUtil.putBooleanArrayValue(key, value, isFlush);
    }
    Log.warn(TAG, `putBooleanArraySync preferencesName ${preferencesName} key ${key} ` +
      `value ${value} failed preferencesUtil is null`);
    return false;
  }

  static async putBatch(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    editor: Editor, isFlush: boolean = true): Promise<void> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    await preferencesUtil?.putBatch(editor, isFlush);
  }

  static async hasSync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string): Promise<boolean> {
    let preferencesUtil: PreferencesUtil | null = await PreferencesUtil.getPreferences(preferencesName);
    if (!preferencesUtil) {
      Log.warn(TAG, `hasSync preferencesName is ${preferencesName} preferencesUtil is null`);
      return false;
    }
    return (preferencesUtil as PreferencesUtil).hasSync(key);
  }

  static queryHasSyncBySync(preferencesName: string = DEFAULT_PREFERENCES_NAME,
    key: string): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      Log.warn(TAG, `queryHasSyncBySync preferencesName is ${preferencesName} preferencesUtil is null`);
      return false;
    }
    try {
      return preferencesUtil.hasSync(key);
    } catch (error) {
      Log.logErrorMsg(TAG, 'queryHasSyncBySync', error);
      return false;
    }
  }

  /**
   * 注册本进程的首选项变化监听
   * @param preferencesName
   * @param callback
   * @returns
   */
  static registerPreferencesChangedListener(preferencesName: string, callback: Callback<string>): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      return false;
    }
    try {
      preferencesUtil.preferences.on('change', callback);
    } catch (error) {
      Log.logErrorMsg(TAG, 'registerPreferencesChangedListener', error);
      return false;
    }
    return true;
  };

  /**
   * 注册多进程的首选项变化监听,本进程的变化也会回调
   * @param preferencesName
   * @param callback
   * @returns
   */
  static registerCrossProcessChangedListener(preferencesName: string, callback: Callback<string>): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      return false;
    }
    try {
      preferencesUtil.preferences.on('multiProcessChange', callback);
    } catch (error) {
      Log.logErrorMsg(TAG, 'registerCrossProcessChangedListener', error);
      return false;
    }
    return true;
  }

  static unRegisterPreferencesChangedListener(preferencesName: string, callback: Callback<string>): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      return false;
    }
    try {
      preferencesUtil.preferences.off('change', callback);
    } catch (error) {
      Log.logErrorMsg(TAG, 'unRegisterPreferencesChangedListener', error);
      return false;
    }
    return true;
  };

  static unRegisterCrossProcessPreferencesChangedListener(preferencesName: string, callback: Callback<string>): boolean {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.getPreferencesSync(preferencesName);
    if (!preferencesUtil) {
      return false;
    }
    try {
      preferencesUtil.preferences.off('multiProcessChange', callback);
    } catch (error) {
      Log.logErrorMsg(TAG, 'unRegisterCrossProcessPreferencesChangedListener', error);
      return false;
    }
    return true;
  };

  /**
   * db 格式的 Preferences 不调用removePreferencesFromCacheSync,会导致dbClose
   * @param preferencesName
   * @returns
   */
  public static removePreferencesFromCacheSync(preferencesName: string = DEFAULT_PREFERENCES_NAME): boolean {
    PreferencesUtil.preferencesMap.remove(preferencesName);
    const context: common.Context | null = PreferencesUtil.context;
    if (!context) {
      Log.warn(TAG, 'removePreferencesFromCacheSync context is null');
      return false;
    }
    let isPreferencesExist = PreferencesUtil.isFileExist(context.preferencesDir + '/' + preferencesName);
    let isPreferencesDbExist = PreferencesUtil.isFileExist(context.preferencesDir + '/' + preferencesName + '.db');
    if (!isPreferencesExist && !isPreferencesDbExist) {
      Log.info(TAG, `removePreferencesFromCacheSync isFormBaseInfoExist false isFormBaseInfoDbExist false`);
      return true;
    }
    // xml格式的preferences 文件
    if (isPreferencesExist) {
      try {
        data_preferences.removePreferencesFromCacheSync(context, { name: preferencesName });
      } catch (error) {
        Log.error(TAG, `removePreferencesFromCacheSync error msg ${error?.message} code ${error?.code}`);
        return false;
      }
    } else {
      Log.info(TAG, `removePreferencesFromCacheSync is db type Preferences no need remove`);
      return true;
    }
    return true;
  }

  public static async deletePreferences(preferencesName: string): Promise<Result<boolean>> {
    PreferencesUtil.preferencesMap.remove(preferencesName);
    const context: common.Context | null = PreferencesUtil.context;
    if (!context) {
      Log.warn(TAG, 'deletePreferences context is null');
      return new Result(ErrorCode.CODE_CONTEXT_NULL, 'deletePreferences context is null', false);
    }
    try {
      await data_preferences.deletePreferences(context, { name: preferencesName });
      return Result.buildSuccessResult(true);
    } catch (error) {
      Log.logErrorMsg(TAG, 'deletePreferences', error);
      return Result.buildByErrorWithData(error, false);
    }
  }

  /**
   * 异步调用
   * @param preferencesName
   * @returns
   */
  private static async getPreferences(preferencesName: string = DEFAULT_PREFERENCES_NAME): Promise<PreferencesUtil | null> {
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.preferencesMap.get(preferencesName);
    if (!preferencesUtil) {
      const context: common.Context | null = PreferencesUtil.context;
      if (!context) {
        Log.warn(TAG, 'getPreferences context is null');
        return null;
      }
      let preferences: data_preferences.Preferences | undefined = undefined;
      try {
        preferences = await data_preferences.getPreferences(context, { name: preferencesName });
      } catch (error) {
        Log.error(TAG, `getPreferences preferencesName ${preferencesName} failed msg is ${error?.message}`);
        return null;
      }
      if (preferences) {
        preferencesUtil = new PreferencesUtil(preferencesName, preferences);
        PreferencesUtil.preferencesMap.set(preferencesName, preferencesUtil);
        Log.info(TAG, `getPreferences ${preferencesName} new and set`);
      } else {
        Log.warn(TAG, `getPreferences preferencesName ${preferencesName} failed`);
        return null;
      }
    }
    return preferencesUtil;
  }


  /**
   * 获取preferencesName对应的Preferences,返回是否获取成功
   * @param preferencesName
   * @returns
   */
  public static getPreferencesResult(preferencesName: string): boolean {
    return !EmptyUtils.isUndefinedOrNull(PreferencesUtil.getPreferencesSync(preferencesName));
  }

  private static isFileExist(filePath: string): boolean {
    try {
      return FileIoUtil.accessSync(filePath);
    } catch (err) {
      Log.logErrorMsg(TAG, 'isFileExist', err);
      return false;
    }
  }

  /**
   * 同步调用
   * @param preferencesName
   * @returns
   */
  private static getPreferencesSync(preferencesName: string = DEFAULT_PREFERENCES_NAME): PreferencesUtil | null {
    if (!TypeUtils.isString(preferencesName)) {
      Log.warn(TAG, `getPreferencesSync preferencesName is ${preferencesName} not string`);
      return null;
    }
    if (EmptyUtils.isEmptyString(preferencesName)) {
      Log.warn(TAG, `getPreferencesSync preferencesName is empty`);
      return null;
    }
    let preferencesUtil: PreferencesUtil | null = PreferencesUtil.preferencesMap.get(preferencesName);
    if (!preferencesUtil) {
      const context: common.Context | null = PreferencesUtil.context;
      if (!context) {
        Log.warn(TAG, 'getPreferences context is null');
        return null;
      }
      let preferences: data_preferences.Preferences | undefined = undefined;
      try {
        preferences = data_preferences.getPreferencesSync(context, { name: preferencesName });
      } catch (error) {
        Log.error(TAG, `getPreferencesSync preferencesName ${preferencesName} failed msg is ${error?.message}`);
        return null;
      }
      if (preferences) {
        preferencesUtil = new PreferencesUtil(preferencesName, preferences);
        PreferencesUtil.preferencesMap.set(preferencesName, preferencesUtil);
        Log.info(TAG, `getPreferences ${preferencesName} new and set`);
      } else {
        Log.warn(TAG, `getPreferences preferencesName ${preferencesName} failed`);
        return null;
      }
    }
    return preferencesUtil;
  }

  /**
   * return value as number 也是可以正确的展示为number,
   * @param key
   * @param defaultValue
   * @returns
   */
  private getNumberValue(key: string, defaultValue: number = 0): number {
    try {
    let value = this.preferences.getSync(key, defaultValue);
    Log.info(TAG, `getNumberValue key is ${key} value is ${value} `);
    const numberValue: Number = Number(value);
    
      if (Number.isNaN(numberValue)) {
        Log.error(TAG, `getNumberValue key is ${key} value is ${value} diry number`);
        return defaultValue;
      }
    return numberValue.valueOf();
    } catch (error) {
      Log.logErrorMsg(TAG, 'getNumberValue', error);
      return defaultValue;
    }
  }

  private getStringValue(key: string, defaultValue: string = ''): string {
    try {
      let value = this.preferences.getSync(key, defaultValue);
      return value as string;
    } catch (error) {
      Log.logErrorMsg(TAG, 'getStringValue', error);
      return defaultValue;
    }
  }

  private getBooleanValue(key: string, defaultValue: boolean = false): boolean {
    try {
      let value = this.preferences.getSync(key, defaultValue);
      return value as boolean;
    } catch (error) {
      Log.logErrorMsg(TAG, 'getBooleanValue', error);
      return defaultValue;
    }
  }

  private getBooleanArrayValue(key: string, defaultValue: Array<boolean> = new Array()): Array<boolean> {
    try {
      let value = this.preferences.getSync(key, defaultValue);
      if (this.isNullOrUndefined(value)) {
        return defaultValue;
      }
      if (typeof value === 'string') {
        return JSON.parse(value) as Array<boolean>;
      }
      Log.warn(TAG, `getBooleanArrayValue key is ${key} value type is ${typeof value} illegal`);
      return defaultValue;
    } catch (error) {
      Log.logErrorMsg(TAG, 'getBooleanArrayValue', error);
      return defaultValue;
    }
  }

  private getStringArrayValue(key: string, defaultValue: Array<string> = new Array()): Array<string> {
    try {
      let value = this.preferences.getSync(key, defaultValue);
      if (this.isNullOrUndefined(value)) {
        return defaultValue;
      }
      if (value === defaultValue) {
        return defaultValue;
      }
      if (typeof value === 'string') {
        return JSON.parse(value) as Array<string>;
      }
      Log.warn(TAG, `getStringArrayValue key is ${key} value type is ${typeof value} illegal`);
      return defaultValue;
    } catch (error) {
      Log.logErrorMsg(TAG, 'getStringArrayValue', error);
      return defaultValue;
    }
  }

  private getNumberArrayValue(key: string, defaultValue: Array<number> = new Array()): Array<number> {
    try {
    let value = this.preferences.getSync(key, defaultValue);
      if (this.isNullOrUndefined(value)) {
        return defaultValue;
      }
      if (typeof value === 'string') {
        return JSON.parse(value) as Array<number>;
      }
      if (value === defaultValue) {
        return defaultValue;
      }
      Log.warn(TAG, `getNumberArrayValue key is ${key} value type is ${typeof value} illegal`);
      return defaultValue;
    } catch (error) {
      Log.logErrorMsg(TAG, 'getNumberArrayValue', error);
      return defaultValue;
    }
  }

  private getAllValue(): Object {
    try {
      let value = this.preferences.getAllSync();
      return value;
    } catch (error) {
      Log.logErrorMsg(TAG, `getAllValue error`, error);
      throw error as Error;
    }
  }

  private clearValue(): void {
    try {
      this.preferences.clearSync();
    } catch (error) {
      Log.logErrorMsg(TAG, `clearValue error`, error);
      throw error as Error;
    }
  }

  private putNumberValue(key: string, value: number, isFlush: boolean = true): boolean {
    Log.info(TAG, `putNumberValue key is ${key} value is ${value} `);
    return this.doPutValue(value, key, isFlush);
  }

  private putStringValue(key: string, value: string | null, isFlush: boolean = true): boolean {
    return this.doPutValue(value, key, isFlush);
  }

  private putBooleanValue(key: string, value: boolean | null, isFlush: boolean = true): boolean {
    return this.doPutValue(value, key, isFlush);
  }

  private putBooleanArrayValue(key: string, value: Array<boolean> | null, isFlush: boolean = true): boolean {
    return this.doPutJsonArray(value, key, isFlush);
  }

  /**
   * 如果put的是Array<string> 存储的是以","分割,getString的时候需要转化而且,如果字符串中含有"," 会导致异常
   * @param key
   * @param value
   * @param isFlush
   */
  private putStringArrayValue(key: string, value: Array<string> | null, isFlush: boolean = true): boolean {
    return this.doPutJsonArray(value, key, isFlush);
  }

  private putNumberArrayValue(key: string, value: Array<number> | null, isFlush: boolean = true): boolean {
    return this.doPutJsonArray(value, key, isFlush);
  }

  private doPutJsonArray(value: preferences.ValueType | null, key: string, isFlush: boolean): boolean {
    const jsonValue = this.isNullOrUndefined(value) ? value : JSON.stringify(value);
    return this.doPutValue(jsonValue, key, isFlush);
  }

  private doPutValue(value: preferences.ValueType | null, key: string, isFlush: boolean): boolean {
    try {
      if (value !== null && value !== undefined) {
        this.preferences.putSync(key, value);
      } else {
        this.preferences.deleteSync(key);
      }
      if (isFlush) {
        this.preferences.flushSync();
      }
      return true;
    } catch (error) {
      Log.logErrorMsg(TAG, `doPutValue key is ${key} value is ${value}`, error);
      return false;
    }
  }

  private async putBatch(editor: Editor, isFlush: boolean = false): Promise<void> {
    const values: LightWeightMap<string, Pair<preferences.ValueType | null, PreferencesValueType> | null> = editor.getValues();
    if (EmptyUtils.isEmptyArray(values)) {
      Log.warn(TAG, 'putBatch editor values is empty');
      return;
    }
    for (let i = 0; i < values.length; i++) {
      const key: string = values.getKeyAt(i);
      const pair: Pair<preferences.ValueType | null, PreferencesValueType> | null = values.get(key);
      if (!pair) {
        continue;
      }
      const value: preferences.ValueType | null = pair.getFirst();
      const type: PreferencesValueType = pair.getSecond();
      // subscription_config_share_preference <string name="notifyDataTimePoint">1,10,22</string> 这个不能解析？
      // HAGData <long value="1697591833063" name="lastChangedTime"/> 这个不能解析？
      try {
        // if (value) {} else {}  value 是number 0 1 的时候会误判 无法判空
        if (value !== null && value !== undefined) {
          Log.debug(TAG, `putBatch put fileName is ${this.preferencesFileName} key is ${key} value is ${value} type is ${type}`);
          this.putPreferencesSyncValue(key, value, type);
        } else {
          this.preferences.deleteSync(key);
          Log.debug(TAG, `putBatch delete fileName is ${this.preferencesFileName} key is ${key} value is ${value} type is ${type} `);
        }
      } catch (err) {
        Log.logErrorMsg(TAG, `putBatch error fileName is ${this.preferencesFileName} key is ${key} value is ${value} type is ${type}`, err);
      }
    }
    if (isFlush) {
      await this.preferences.flush();
    }
  }

  private putPreferencesSyncValue(key: string, value: preferences.ValueType | null, type: PreferencesValueType): void {
    if (type === PreferencesValueType.STRING_ARRAY) {
      this.preferences.putSync(key, JSON.stringify(value));
    } else {
      this.preferences.putSync(key, value);
    }
  }

  private hasSync(key: string): boolean {
    return this.preferences.hasSync(key);
  }

  private isNullOrUndefined<T>(value: T): boolean {
    return value === null || value === undefined;
  }
}

export class Editor {
  private readonly values: LightWeightMap<string, Pair<preferences.ValueType | null, PreferencesValueType> | null> = new LightWeightMap();

  public putKeyValue(key: string, valuePair: Pair<preferences.ValueType | null, PreferencesValueType> | null): Editor {
    this.values.set(key, valuePair);
    return this;
  }

  getValues(): LightWeightMap<string, Pair<preferences.ValueType | null, PreferencesValueType> | null> {
    return this.values;
  }
}


export class Pair<F, S> {
  private first: F;
  private second: S;

  constructor(first: F, second: S) {
    this.first = first;
    this.second = second;
  }

  getFirst(): F {
    return this.first;
  }

  getSecond(): S {
    return this.second;
  }
}

export class PreferencesValuePair<F extends preferences.ValueType | null, S extends PreferencesValueType> extends Pair<F, S> {
}

/**
 * 单框架首选项值的类型枚举
 */
export enum PreferencesValueType {
  NUMBER,
  BOOLEAN,
  STRING,
  NUMBER_ARRAY,
  BOOLEAN_ARRAY,
  STRING_ARRAY,
}