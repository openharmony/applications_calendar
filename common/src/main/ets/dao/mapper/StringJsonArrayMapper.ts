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
import { TableEntity } from '../model/TableEntity';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Mapper } from './Mapper';
import { EmptyUtils } from '../../util/EmptyUtils';

const TAG = 'StringJsonArrayMapper';

/*
 * StringJsonArrayMapper
 */
export class StringJsonArrayMapper<T> implements Mapper<string, T[]> {
  columnToProperty(columnName: string, propertyName: string, model: TableEntity, columnValue: string): void {
    if (EmptyUtils.isNotOrEmptyString(columnValue)) {
      Log.warn(TAG, `columnToProperty columnName is ${columnName} propertyName is ${propertyName} columnValue not string`);
      Reflect.set(model, propertyName, []);
      return;
    }
    Reflect.set(model, propertyName, JSON.parse(columnValue) as T[]);
  }

  propertyToColumn(columnName: string, propertyName: string, model: TableEntity, valueBucket: ValuesBucket): void {
    const date: T[] | undefined = model[propertyName];
    if (EmptyUtils.isEmptyArray(date)) {
      valueBucket[columnName] = '[]';
      Log.warn(TAG, `propertyToColumn columnName is ${columnName} propertyName is ${propertyName} propertyValue isEmptyArray`);
    } else {
      valueBucket[columnName] = JSON.stringify(date);
    }
  }
}