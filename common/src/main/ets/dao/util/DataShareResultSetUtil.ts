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
import { Log } from '../../default/common/Log';
import { EmptyUtils } from '../../util/EmptyUtils';
import { TypeUtils } from '../../util/TypeUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';
import { DbValueType, DbValueTypeMapping } from '../DbValueType';
import { InnerResultSet } from './InnerResultSet';

const TAG = 'DataShareResultUtil';


export class DataShareResultUtil {
  public static getColumnData<P extends keyof DbValueTypeMapping>(ds: InnerResultSet, column: string,
                                                                  defaultValue: DbValueTypeMapping[P],
                                                                  dbValueType: P, throwOnNoSuchColumn?: boolean): DbValueTypeMapping[P] {
    if (dbValueType === DbValueType.DB_STRING) {
      return DataShareResultUtil.getColumnStringData(ds, column, defaultValue as string, throwOnNoSuchColumn) as DbValueTypeMapping[P];
    }
    if (dbValueType === DbValueType.DB_LONG) {
      return DataShareResultUtil.getColumnLongData(ds, column, defaultValue as number, throwOnNoSuchColumn) as DbValueTypeMapping[P];
    }
    if (dbValueType === DbValueType.DB_BLOB) {
      return DataShareResultUtil.getColumnBlobData(ds, column, defaultValue as Uint8Array, throwOnNoSuchColumn) as DbValueTypeMapping[P];
    }
    if (dbValueType === DbValueType.DB_FLOAT) {
      return DataShareResultUtil.getColumnFloatData(ds, column, defaultValue as number, throwOnNoSuchColumn) as DbValueTypeMapping[P];
    }
    const msg = `getColumnData column ${column} dbValueType ${dbValueType} no case match`;
    Log.error(TAG, msg);
    throw {
      code: ErrorCode.ILLEGAL_CODE,
      message: msg,
      name: 'BusinessError'
    };
  }

  public static getColumnStringData(ds: InnerResultSet, column: string, defaultValue: string, throwOnNoSuchColumn?: boolean): string {
    const index = DataShareResultUtil.queryColumnIndex(column, ds, throwOnNoSuchColumn);
    if (index < 0) {
      return defaultValue;
    }
    try {
      const value: string = ds.getString(index);
      if (EmptyUtils.isUndefinedOrNull(value)) {
        return defaultValue;
      }
      if (TypeUtils.isString(value)) {
        return value;
      } else {
        Log.warn(TAG, `type ${typeof value} not match, expect string`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: `type ${typeof value} not match, expect string`,
          name: 'BusinessError'
        };
        throw error as Error;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getColumnStringData', error);
      throw error as Error;
    }
  }

  public static getColumnLongData(ds: InnerResultSet, column: string, defaultValue: number, throwOnNoSuchColumn?: boolean): number {
    const index = DataShareResultUtil.queryColumnIndex(column, ds, throwOnNoSuchColumn);
    if (index < 0) {
      return defaultValue;
    }
    try {
      const value: number = ds.getLong(index);
      if (EmptyUtils.isUndefinedOrNull(value)) {
        return defaultValue;
      }
      if (TypeUtils.isNumber(value)) {
        return value;
      } else {
        Log.warn(TAG, `type ${typeof value} not match, expect number`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: `type ${typeof value} not match, expect number`,
          name: 'BusinessError'
        };
        throw error as Error;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getColumnLongData', error);
      throw error as Error;
    }
  }

  /**
   * 解析带浮点数类型
   * @param ds
   * @param column
   * @param defaultValue
   * @param throwOnNoSuchColumn 是否有该列
   * @returns
   */
  public static getColumnFloatData(ds: InnerResultSet, column: string, defaultValue: number, throwOnNoSuchColumn?: boolean): number {
    const index = DataShareResultUtil.queryColumnIndex(column, ds, throwOnNoSuchColumn);
    if (index < 0) {
      return defaultValue;
    }
    try {
      const value: number = ds.getDouble(index);
      if (EmptyUtils.isUndefinedOrNull(value)) {
        return defaultValue;
      }
      if (TypeUtils.isNumber(value)) {
        return value;
      } else {
        Log.warn(TAG, `type ${typeof value} not match, expect number`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: `type ${typeof value} not match, expect number`,
          name: 'BusinessError'
        };
        throw error as Error;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getColumnFloatData', error);
      throw error as Error;
    }
  }

  public static getColumnBlobData(ds: InnerResultSet, column: string, defaultValue: Uint8Array, throwOnNoSuchColumn?: boolean): Uint8Array {
    const index = DataShareResultUtil.queryColumnIndex(column, ds, throwOnNoSuchColumn);
    if (index < 0) {
      return defaultValue;
    }
    try {
      const value: Uint8Array = ds.getBlob(index);
      if (EmptyUtils.isUndefinedOrNull(value)) {
        return defaultValue;
      }
      if (TypeUtils.isObject(value) && value instanceof Uint8Array) {
        return value;
      } else {
        Log.warn(TAG, `type ${typeof value} not match, expect Blob`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: `type ${typeof value} not match, expect Blob`,
          name: 'BusinessError'
        };
        throw error as Error;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getColumnBlobData', error);
      throw error as Error;
    }
  }

  public static getColumnDoubleData(ds: InnerResultSet, column: string, defaultValue: number, throwOnNoSuchColumn?: boolean): number {
    const index = DataShareResultUtil.queryColumnIndex(column, ds, throwOnNoSuchColumn);
    if (index < 0) {
      return defaultValue;
    }
    try {
      const value: number = ds.getDouble(index);
      if (EmptyUtils.isUndefinedOrNull(value)) {
        return defaultValue;
      }
      if (TypeUtils.isNumber(value)) {
        return value;
      } else {
        Log.warn(TAG, `type ${typeof value} not match, expect number`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: `type ${typeof value} not match, expect number`,
          name: 'BusinessError'
        };
        throw error as Error;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getColumnDoubleData', error);
      throw error as Error;
    }
  }

  public static queryColumnIndex(column: string, ds: InnerResultSet, throwOnNoSuchColumn?: boolean): number {
    const index: number = ds.getColumnIndex(column);
    if (index >= 0) {
      return index;
    }
    if (throwOnNoSuchColumn) {
      const msg = `queryColumnIndex no cuch column ${column}`;
      Log.error(TAG, msg);
      throw {
        code: ErrorCode.ILLEGAL_CODE,
        message: msg,
        name: 'BusinessError'
      };
    }
    return -1;
  }
}