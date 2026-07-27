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

import { TableEntity } from '../model/TableEntity';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Log } from '../../default/common/Log';
import { Mapper } from './Mapper';
import { TypeUtils } from '../../util/TypeUtils';


const NEGATIVE_NUM = 0;
const POSITIVE_NUM = 1;

const TAG = 'BooleanNumberMapper';

/*
 * BooleanNumberMapper
 */
export class BooleanNumberMapper implements Mapper<number, boolean> {
  columnToProperty(columnName: string, propertyName: string, model: TableEntity, columnValue: number): void {
    const propertyValue: boolean = columnValue === POSITIVE_NUM;
    if (columnValue !== NEGATIVE_NUM && columnValue !== POSITIVE_NUM) {
      Log.warn(TAG, `columnToProperty columnName is ${columnName} propertyName is ${propertyName} columnValue is ${columnValue}`);
    }
    Reflect.set(model, propertyName, propertyValue);
  }

  propertyToColumn(columnName: string, propertyName: string, model: TableEntity, valueBucket: ValuesBucket): void {
    const propertyValue = model[propertyName];
    const columnValue: number = model[propertyName] ? POSITIVE_NUM : NEGATIVE_NUM;
    if (!TypeUtils.isBoolean(propertyValue)) {
      Log.warn(TAG, `propertyToColumn columnName is ${columnName} propertyName is ${propertyName} propertyValue is ${columnValue} not booblean`);
    }
    valueBucket[columnName] = columnValue;
  }
}

export const BOOLEAN_NUMBER_MAPPER: BooleanNumberMapper = new BooleanNumberMapper();