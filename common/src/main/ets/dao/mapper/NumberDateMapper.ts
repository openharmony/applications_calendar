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
import { TypeUtils } from '../../util/TypeUtils';
import { TableEntity } from '../model/TableEntity';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Mapper } from './Mapper';

const TAG = 'BooleanNumberMapper';

/*
 * NumberDateMapper
 */
export class NumberDateMapper implements Mapper<number, Date> {
  columnToProperty(columnName: string, propertyName: string, model: TableEntity, columnValue: number): void {
    if (!TypeUtils.isNumber(columnValue)) {
      Log.warn(TAG, `columnToProperty columnName is ${columnName} propertyName is ${propertyName} columnValue not number`);
    }
    Reflect.set(model, propertyName, new Date(columnValue));
  }

  propertyToColumn(columnName: string, propertyName: string, model: TableEntity, valueBucket: ValuesBucket): void {
    const date: Date | undefined = model[propertyName];
    if (TypeUtils.isDateObject(date)) {
      valueBucket[columnName] = date.getTime();
    }
    Log.warn(TAG, `propertyToColumn columnName is ${columnName} propertyName is ${propertyName} propertyValue is not date`);
  }
}