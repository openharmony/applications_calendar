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

import { EmptyUtils } from '../../util/EmptyUtils';
import { ColumnConfigHelper } from '../helper/ColumnConfigHelper';
import { TableEntity } from '../model/TableEntity';
import { Constructor } from './d';


/**
 * Table 装饰器
 * 类的构造函数
 * @param tableName
 * @returns
 */
export function Table<T extends TableEntity>(tableName: string): Function {
  return function (target: Constructor<T>): void {
    if (EmptyUtils.isNotOrEmptyString(tableName)) {
      throw new Error(`Table tableName is isNotOrEmptyString`);
    }
    ColumnConfigHelper.INSTANCE.fillTableConfig(target, tableName);
  };
}

