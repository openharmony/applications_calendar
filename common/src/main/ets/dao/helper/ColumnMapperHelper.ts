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

import { LightWeightMap } from '@kit.ArkTS';
import { EmptyUtils } from '../../util/EmptyUtils';
import { ColumnConfig } from '../ColumnConfig';
import { Log } from '../../default/common/Log';
import { Prototype, SupportedDbValueType } from '../annotation/d';
import { Mapper } from '../mapper/Mapper';

const TAG = 'ColumnMapperHelper';

export class ColumnMapperHelper {
  static readonly INSTANCE: ColumnMapperHelper = new ColumnMapperHelper();
  /**
   * 一级key 原型对象,二级key 模型的属性对应的表的列名
   */
  private readonly columnMapperByColumnName:
    LightWeightMap<Prototype, LightWeightMap<string, Mapper<SupportedDbValueType[keyof SupportedDbValueType], ESObject>>> =
    new LightWeightMap();


  /**
   * 填充列的配置
   * @param target 原型对象
   * @param propertyName
   * @param config
   */
  public fillColumnMapper(target: Prototype, propertyName: string,
                          config: ColumnConfig<keyof SupportedDbValueType>,
                          mapper: Mapper<keyof SupportedDbValueType, ESObject>): void {
    const targetConstructor = this.getConstructorName(target);
    let tableMappersByColumnName = this.columnMapperByColumnName.get(target);
    if (!tableMappersByColumnName) {
      tableMappersByColumnName = new LightWeightMap();
      this.columnMapperByColumnName.set(target, tableMappersByColumnName);
    }
    const columnName = config.columnName;
    if (EmptyUtils.isNotOrEmptyString(columnName)) {
      throw new Error(`target is ${targetConstructor} propertyName is ${propertyName} columnName isNotOrEmptyString`);
    }
    if (tableMappersByColumnName.get(columnName)) {
      throw new Error(`target is ${targetConstructor} columnName is ${columnName} has exist`);
    }
    tableMappersByColumnName.set(columnName, mapper);
  }

  private getConstructorName(targetPrototype: Prototype): string {
    if (!targetPrototype) {
      return '';
    }
    const constructor = Reflect.get(targetPrototype, 'constructor');
    if (!constructor) {
      return '';
    }
    const constructorName = Reflect.get(constructor, 'name');
    return constructorName ?? '';
  }

  public getColumnMappers(prototype: Prototype): LightWeightMap<string, Mapper<SupportedDbValueType[keyof SupportedDbValueType], ESObject>> {
    return this.columnMapperByColumnName.get(prototype);
  }
}
