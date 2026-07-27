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

import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { DBUtils } from '../DBUtils';
import { Result } from '../../templates/Result';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { ResultSetToArrayConverter, ResultSetToModelConverter } from '../Converter';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';
import { Log } from '../../default/common/Log';
import { TableEntity } from '../model/TableEntity';
import { EmptyUtils } from '../../util/EmptyUtils';
import { BaseModelConverter } from '../modelconverter/BaseModelConverter';

const TAG = 'BaseRepository';

export class BaseRepository<Model extends TableEntity> {
  protected readonly mTableName: CalendarContract.Tables;
  private columnOfId: string = '';
  private modelConverter: BaseModelConverter<Model>;

  constructor(tableName: CalendarContract.Tables, modelConverter: BaseModelConverter<Model>) {
    this.mTableName = tableName;
    this.modelConverter = modelConverter
  }

  private getColumnOfId(): string {
    if (EmptyUtils.isStringAndNotEmpty(this.columnOfId)) {
      return this.columnOfId;
    }
    const idColumnConfig = this.modelConverter.getIdColumnConfig();
    this.columnOfId = idColumnConfig?.columnName ?? '';
    if (EmptyUtils.isNotOrEmptyString(this.columnOfId)) {
      const msg = `getColumnOfId table ${this.mTableName} idColumnConfig is null`;
      Log.warn(TAG, msg);
    }
    return this.columnOfId;
  }

  async insertItem(model: Model): Promise<Result<number>> {
    const valuesBucket = this.modelConverter.buildValuesBucket(model);
    return DBUtils.INSTANCE.insertItem(this.mTableName, valuesBucket);
  }

  async insertItems(models: Model[]): Promise<Result<number>> {
    if (EmptyUtils.isEmptyArray(models)) {
      const msg = `insertItems table ${this.mTableName} models is empty`;
      Log.warn(TAG, msg);
      return Result.buildSuccessResult(0);
    }
    const valuesBuckets: ValuesBucket[] = [];
    for (let model of models) {
      const valuesBucket = this.modelConverter.buildValuesBucket(model);
      valuesBuckets.push(valuesBucket);
    }
    const insertedCount = await DBUtils.INSTANCE.batchInsert(
            DBUtils.INSTANCE.concatenateUri(this.mTableName.toString()), valuesBuckets, 'insertItems');
    if (insertedCount <= -1) {
      return Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'insertItems error', insertedCount);
    }
    if (insertedCount < models.length) {
      const msg = `insertItems table ${this.mTableName} insertedCount is ${insertedCount} totalCount is ${models.length} no match`;
      Log.warn(TAG, msg);
    }
    return Result.buildSuccessResult(insertedCount);
  }

  async deleteByCondition(predicates: dataSharePredicates.DataSharePredicates): Promise<Result<number>> {
    return DBUtils.INSTANCE.deleteByCondition(this.mTableName, predicates);
  }

  async deleteById(id: number): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(this.getColumnOfId(), id);
    return DBUtils.INSTANCE.deleteByCondition(this.mTableName, predicates);
  }

  async deleteByEqual(columnName: string, value: string | number): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(columnName, value);
    return this.deleteByCondition(predicates);
  }

  async deleteByIn(columnName: string, values: (number | string)[]): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(columnName, values);
    return this.deleteByCondition(predicates);
  }

  async deleteByIds(ids: number[]): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(this.getColumnOfId(), ids);
    return this.deleteByCondition(predicates);
  }

  async updateById(id: number, model: Model, includeColumns: string[] = [], excludeColumns?: string[])
    : Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(this.getColumnOfId(), id);
    return this.updateByCondition(predicates, model, includeColumns, excludeColumns);
  }

  async updateByEqual(columnName: string, value: string | number, model: Model,
                      includeColumns: string[] = [], excludeColumns?: string[]): Promise<Result<number>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(columnName, value);
    return this.updateByCondition(predicates, model, includeColumns, excludeColumns);
  }

  async updateByCondition(predicates: dataSharePredicates.DataSharePredicates,
                          model: Model, includeColumns: string[] = [],
                          excludeColumns?: string[]): Promise<Result<number>> {
    const valueBucket = this.modelConverter.buildValuesBucket(model, includeColumns, excludeColumns);
    return DBUtils.INSTANCE.updateByCondition(this.mTableName, predicates, valueBucket);
  }

  async queryById(id: number, isUseProxy: boolean = false, columns?: string[]): Promise<Result<Model | undefined>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(this.getColumnOfId(), id);
    const converter = new ResultSetToModelConverter(this.modelConverter);
    return DBUtils.INSTANCE
      .queryTabItemsByCondition(this.mTableName, converter, predicates, isUseProxy, columns);
  }

  async queryOneByEqual(columnName: string, value: string | number,
                        isUseProxy: boolean = false,
                        columns?: string[]): Promise<Result<Model | undefined>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(columnName, value);
    return this.queryOneByCondition(predicates, isUseProxy, columns);
  }

  async queryByIn(columnName: string, values: (string | number)[],
                  isUseProxy: boolean = false,
                  columns?: string[]): Promise<Result<Model[]>> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(columnName, values);
    return this.queryByCondition(predicates, isUseProxy, columns);
  }

  async queryOneByCondition(predicates: dataSharePredicates.DataSharePredicates,
                            isUseProxy: boolean = false,
                            columns?: string[]): Promise<Result<Model | undefined>> {
    const converter = new ResultSetToModelConverter(this.modelConverter);
    return DBUtils.INSTANCE
      .queryTabItemsByCondition(this.mTableName, converter, predicates, isUseProxy, columns);
  }

  async queryByCondition(predicates: dataSharePredicates.DataSharePredicates,
                         isUseProxy: boolean = false,
                         columns?: string[]): Promise<Result<Model[]>> {
    const converter = new ResultSetToArrayConverter(this.modelConverter);
    return DBUtils.INSTANCE
      .queryTabItemsByCondition(this.mTableName, converter, predicates, isUseProxy, columns);
  }
}