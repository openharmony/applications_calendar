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

import { ColumnConfig } from '../ColumnConfig';

import { ColumnConfigHelper } from '../helper/ColumnConfigHelper';
import { RawColumnConfig } from '../RawColumnConfig';
import { Prototype, SupportedDbValueType } from './d';

/**
 * Column 装饰器
 * 对于静态成员来说是类的构造函数，对于实例成员是类的原型对象,这里是原型对象
 * @param columnConfig
 * @returns
 */
export function Column(rawColumnConfig: RawColumnConfig<keyof SupportedDbValueType>): Function {
  return function (target: Prototype, propertyName: string): void {
    const columnConfig = rawColumnConfig as ColumnConfig<keyof SupportedDbValueType>;
    columnConfig.modelPropertyName = propertyName;
    ColumnConfigHelper.INSTANCE.fillColumnConfig(target, propertyName, columnConfig);
  };
}

