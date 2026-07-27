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

import { InnerResultSet } from '../util/InnerResultSet';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { EmptyUtils } from '../../util/EmptyUtils';
import { ColumnConfigHelper } from '../helper/ColumnConfigHelper';
import { DbValueType } from '../DbValueType';
import LightWeightMap from '@ohos.util.LightWeightMap';
import { Log } from '../../default/common/Log';
import { DataShareResultUtil } from '../util/DataShareResultSetUtil';
import { ColumnConfig } from '../ColumnConfig';
import { ModelConverter } from './ModelConverter';
import { TableEntity } from '../model/TableEntity';
import { Constructor, Prototype, SupportedDbValueType } from '../annotation/d';
import { ColumnMapperHelper } from '../helper/ColumnMapperHelper';

export type ReadonlyColumnConfig = Readonly<ColumnConfig<DbValueType.DB_LONG>>;

/*
 * BaseModelConverter
 */
export class BaseModelConverter<T extends TableEntity> implements ModelConverter<T> {
  private readonly tableName: string;
  private readonly logTag: string;
  private allColumns: string[];
  protected property: Prototype;
  private modelConstructor: Constructor<T>;
  private idColumnConfig: ColumnConfig<DbValueType.DB_LONG> | undefined;
  private columnConfigs: LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>> | undefined;

  constructor(tableName: string, property: Prototype, logTag: string, modelConstructor: Constructor<T>) {
    this.tableName = tableName;
    this.logTag = logTag;
    this.property = property;
    this.modelConstructor = modelConstructor;
    this.idColumnConfig = ColumnConfigHelper.INSTANCE.getIdColumnConfig(this.property);
    this.columnConfigs = ColumnConfigHelper.INSTANCE.getColumnNameKeyColumnConfigs(this.property);
  }

  parseToModel(resultSet: InnerResultSet, columns?: string[]): T {
    const columnConfigs = this.columnConfigs;
    if (!columnConfigs) {
      throw new Error(`parseToModel table ${this.tableName} no columnConfigs`);
    }
    const columnMapperConfigs = ColumnMapperHelper.INSTANCE.getColumnMappers(this.property);
    const model = this.buildModel();
    const finalColumns = EmptyUtils.isNotEmptyArray(columns) ? columns! : this.getAllColumns(columnConfigs);
    for (let column of finalColumns) {
      const columnConfig: ColumnConfig<keyof SupportedDbValueType> = columnConfigs.get(column);
      if (EmptyUtils.isUndefinedOrNull(columnConfig)) {
        const msg = `parseToModel column ${column} no columnConfig`;
        Log.error(this.logTag, msg);
        throw new Error(msg);
      }
      // 目前实际已有的数据库的字段type只有这两种,后续新增了在这扩展
      let defaultValue = columnConfig.defaultValue;
      if (columnConfig.columnValueType === DbValueType.DB_STRING) {
      } else if (columnConfig.columnValueType === DbValueType.DB_LONG) {
      } else if (columnConfig.columnValueType === DbValueType.DB_FLOAT) {
      } else {
        const msg = `parseToModel columnValueType ${columnConfig.columnValueType} not support`;
        Log.error(this.logTag, msg);
        throw new Error(msg);
      }
      const columnValue =
        DataShareResultUtil.getColumnData(resultSet, column, defaultValue, columnConfig.columnValueType, true);
      const columnMapper = columnMapperConfigs?.get(column);
      if (columnMapper) {
        columnMapper.columnToProperty(column, columnConfig.modelPropertyName, model, columnValue);
      } else {
        const setResult = Reflect.set(model, columnConfig.modelPropertyName, columnValue);
        if (!setResult) {
          const msg = `parseToModel setProperty column ${column} value ${columnValue} fail`;
          Log.error(this.logTag, msg);
          throw new Error(msg);
        }
      }
    }
    return model;
  }

  public getIdColumnConfig(): ReadonlyColumnConfig | undefined {
    return this.idColumnConfig as ReadonlyColumnConfig;
  }


  private getAllColumns(columnConfigs: LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>>): string[] {
    if (EmptyUtils.isEmptyArray(this.allColumns)) {
      this.allColumns = Array.from(columnConfigs.keys());
    }
    if (EmptyUtils.isEmptyArray(this.allColumns)) {
      throw new Error(`allColumns is empty illegal`);
    }
    return this.allColumns;
  }

  protected buildModel(): T {
    return Reflect.construct(this.modelConstructor, []);
  };

  /**
   * 如果includeColumns不为空,就只处理includeColumns,如果includeColumns为空且excludeColumns不为空,就从全部列排除excludeColumns
   * 如果includeColumns和excludeColumns都为空,就使用全部
   * @param model 内存模型
   * @param includeColumns 需要被包含的列 如果includeColumns不为空,就只处理includeColumns
   * @param excludeColumns 需要被排除的列
   * @returns ValuesBucket
   */
  buildValuesBucket(model: T, includeColumns: string[] = [], excludeColumns?: string[]): ValuesBucket {
    const columnConfigs = this.columnConfigs;
    if (!columnConfigs) {
      throw new Error(`buildValuesBucket table ${this.tableName} no columnConfigs`);
    }
    if (!this.idColumnConfig) {
      throw new Error(`buildValuesBucket table ${this.tableName} no idColumnConfig`);
    }
    const columnMapperConfigs = ColumnMapperHelper.INSTANCE.getColumnMappers(this.property);
    const finalColumns = this.getBucketColumns(columnConfigs, includeColumns, excludeColumns);
    const valuesBucket = {};
    for (let column of finalColumns) {
      if (column === this.idColumnConfig.columnName) {
        continue;
      }
      const columnConfig: ColumnConfig<keyof SupportedDbValueType> = columnConfigs.get(column);
      if (EmptyUtils.isUndefinedOrNull(columnConfig)) {
        const msg = `buildValuesBucket column ${column} no columnConfig`;
        Log.error(this.logTag, msg);
        throw new Error(msg);
      }
      const value = model[columnConfig.modelPropertyName];
      if (((!columnConfig.isNullEnable) && EmptyUtils.isUndefinedOrNull(value))) {
        const msg = `buildValuesBucket column ${column} isNullEnable false but value isUndefinedOrNull`;
        Log.error(this.logTag, msg);
        throw new Error(msg);
      }
      const columnMapper = columnMapperConfigs?.get(column);
      if (columnMapper) {
        columnMapper.propertyToColumn(column, columnConfig.modelPropertyName, model, valuesBucket);
      } else {
        valuesBucket[column] = value;
      }
    }
    return valuesBucket;
  }

  private getBucketColumns(columnConfigs: LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>>,
                           includeColumns?: string[],
                           excludeColumns?: string[]): string[] {
    if (EmptyUtils.isNotEmptyArray(includeColumns)) {
      return includeColumns!;
    }
    if (EmptyUtils.isEmptyArray(includeColumns) && EmptyUtils.isEmptyArray(excludeColumns)) {
      return this.getAllColumns(columnConfigs);
    }
    const allColumns = this.getAllColumns(columnConfigs);
    const finalColumns = allColumns.filter((column) => {
      return !(excludeColumns?.includes(column));
    });
    if (EmptyUtils.isEmptyArray(finalColumns)) {
      const msg = `getBucketColumns excludeColumns equals allColumns illegal`;
      Log.error(this.logTag, msg);
      throw new Error(msg);
    }
    return finalColumns;
  }
}