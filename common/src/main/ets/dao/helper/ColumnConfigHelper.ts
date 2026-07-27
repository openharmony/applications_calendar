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

import { DbValueType } from '../DbValueType';
import { LightWeightMap } from '@kit.ArkTS';
import { EmptyUtils } from '../../util/EmptyUtils';
import { ColumnConfig } from '../ColumnConfig';
import { Log } from '../../default/common/Log';
import { TableEntity } from '../model/TableEntity';
import { Constructor, Prototype, SupportedDbValueType } from '../annotation/d';

const TAG = 'ColumnConfigHelper';

const TopParentName = 'TableEntity';

const ID_PROPERTY_NAME = 'id';

export class ColumnConfigHelper {
  static readonly INSTANCE: ColumnConfigHelper = new ColumnConfigHelper();
  /**
   * 一级key 原型对象,二级key 模型的属性对应的表的列名
   */
  private readonly columnConfigsByColumnName:
    LightWeightMap<Prototype, LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>>> =
    new LightWeightMap();

  private readonly tableConfigs: LightWeightMap<Constructor<TableEntity>, string> = new LightWeightMap();

  /**
   * 一级key 原型对象
   */
  private readonly idColumnConfigs:
    LightWeightMap<Prototype, ColumnConfig<DbValueType.DB_LONG>> =
    new LightWeightMap();

  /**
   * 填充列的配置
   * @param target 原型对象
   * @param propertyName
   * @param config
   */
  public fillColumnConfig(target: Prototype, propertyName: string, config: ColumnConfig<keyof SupportedDbValueType>): void {
    const targetConstructor = this.getConstructorName(target);
    let tableColumnsByColumnName: LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>> = this.columnConfigsByColumnName.get(target);
    if (!tableColumnsByColumnName) {
      tableColumnsByColumnName = new LightWeightMap();
      this.columnConfigsByColumnName.set(target, tableColumnsByColumnName);
    }
    const columnName = config.columnName;
    if (EmptyUtils.isNotOrEmptyString(columnName)) {
      throw new Error(`target is ${targetConstructor} propertyName is ${propertyName} columnName isNotOrEmptyString`);
    }
    if (tableColumnsByColumnName.get(columnName)) {
      throw new Error(`target is ${targetConstructor} columnName is ${columnName} has exist`);
    }
    tableColumnsByColumnName.set(columnName, config);
  }

  /**
   * TableEntity 的子类有Table装饰器,在属性装饰器执行完后再执行
   * @param target
   * @param tableName
   */
  public fillTableConfig<T extends TableEntity>(target: Constructor<T>, tableName: string): void {
    Log.info(TAG, `fillTableConfig target is ${target.name} tableName is ${tableName}`);
    if (this.tableConfigs.get(target)) {
      throw new Error(`fillTableConfig tableName is ${tableName} target ${target.name} has exist`);
    }
    this.tableConfigs.set(target, tableName);
    this.mergeColumnConfigs(target);
    this.fillIdColumnConfig(target);
  }

  private fillIdColumnConfig<T extends TableEntity>(target: Constructor<T>): void {
    const constructorName = target.name;
    const columnConfigs = this.getColumnNameKeyColumnConfigs(target.prototype);
    if (EmptyUtils.isEmptyArray(columnConfigs)) {
      Log.warn(TAG, `fillIdColumnConfig target is ${constructorName} ColumnConfigs is empty`);
      return;
    }
    for (let columnConfig of columnConfigs.values()) {
      if (columnConfig.modelPropertyName === ID_PROPERTY_NAME) {
        Log.info(TAG, `fillIdColumnConfig target is ${constructorName} id column hit`);
        this.idColumnConfigs.set(target.prototype, columnConfig as ColumnConfig<DbValueType.DB_LONG>);
        return;
      }
    }
    Log.warn(TAG, `fillIdColumnConfig target is ${constructorName} id column not hit`);
  }

  /**
   * 合并可能的父类的列配置到子类中
   * @param target
   */
  private mergeColumnConfigs<T extends TableEntity>(target: Constructor<T>): void {
    Log.info(TAG, `mergeColumnConfigs target is ${target.name}`);
    const targetPrototype = target.prototype;
    let selfConfigs: LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>> = this.columnConfigsByColumnName.get(targetPrototype);
    if (!selfConfigs) {
      Log.warn(TAG, `mergeColumnConfigs target is ${target.name} ColumnConfigs is null then build`);
      selfConfigs = new LightWeightMap();
      this.columnConfigsByColumnName.set(targetPrototype, selfConfigs);
    }
    const allParent = this.findAllParent(targetPrototype);
    for (let parent of allParent) {
      const parentName = this.getConstructorName(parent);
      if (parent === targetPrototype) {
        Log.info(TAG, `mergeColumnConfigs findAllParent target.prototype ${parentName} is self continue`);
        continue;
      }
      const parentConfigs = this.columnConfigsByColumnName.get(parent);
      if (EmptyUtils.isEmptyArray(parentConfigs)) {
        Log.info(TAG, `mergeColumnConfigs findAllParent parent ${parentName} parentConfigs is emtpy`);
        continue;
      }
      for (let parentConfig of parentConfigs.entries()) {
        const [parentKey, parentValue] = parentConfig;
        if (selfConfigs.get(parentKey)) {
          Log.info(TAG, `mergeColumnConfigs parentKey is ${parentKey} self config exist no need parent`);
          continue;
        }
        selfConfigs.set(parentKey, parentValue);
      }
    }
    Log.info(TAG, `mergeColumnConfigs final value is ${selfConfigs.length}`);
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

  private findAllParent(targetPrototype: Prototype): Set<Prototype> {
    const allParent: Set<Prototype> = new Set();
    Log.info(TAG, `targetConstructor COLUMN_CONFIGS length is ${this.columnConfigsByColumnName.length}`);
    for (let prototype of this.columnConfigsByColumnName.keys()) {
      if (prototype === targetPrototype) {
        Log.info(TAG, `mergeColumnConfigs targetPrototype is self continue`);
        continue;
      }
      this.findParentByRecursion(targetPrototype, prototype, allParent);
    }
    return allParent;
  }


  /**
   * 查到Parent 查到最顶层父类是TableEntity 终止
   * @param targetPrototype
   * @param allParent
   * @returns
   */
  private findParentByRecursion(selfPrototype: Prototype, mayParentPrototype: Prototype, allParent: Set<Prototype>): void {
    if (!selfPrototype || !mayParentPrototype) {
      Log.info(TAG, `findParentByRecursion selfPrototype or mayParentPrototype is null`);
      return;
    }
    try {
      const selfName = this.getConstructorName(selfPrototype);
      if (selfName === TopParentName) {
        Log.debug(TAG, `findParentByRecursion self constructor is ${selfName} top parent`);
        return;
      }
      // 返回指定对象的原型（即，内部的 [[Prototype]] 属性的值）。
      const superClass = Reflect.getPrototypeOf(selfPrototype);
      if (!superClass) {
        Log.info(TAG, `findParentByRecursion superClass is null`);
        return;
      }
      const parentName = this.getConstructorName(superClass);
      if (mayParentPrototype === superClass) {
        allParent.add(superClass);
        Log.debug(TAG, `findParentByRecursion superClass constructor is ${parentName} hit parent`);
        return;
      }
      if (parentName === TopParentName) {
        Log.debug(TAG, `findParentByRecursion parentName constructor is ${parentName} top parent`);
        return;
      }
      this.findParentByRecursion(superClass, mayParentPrototype, allParent);
    } catch (error) {
      Log.logErrorMsg(TAG, 'findParentByRecursion getPrototypeOf', error);
    }
  }

  public getColumnNameKeyColumnConfigs(prototype: Prototype): LightWeightMap<string, ColumnConfig<keyof SupportedDbValueType>> {
    return this.columnConfigsByColumnName.get(prototype);
  }

  public getIdColumnConfig(prototype: Prototype): ColumnConfig<DbValueType.DB_LONG> | undefined {
    return this.idColumnConfigs.get(prototype);
  }
}
