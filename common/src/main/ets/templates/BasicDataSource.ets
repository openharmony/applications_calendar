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

import { Log } from '../default/common/Log';


const TAG = 'BasicDataSource';

/**
 * 基础数据源模板类，实现IDataSource接口
 * @class
 * @template T - 泛型参数，表示数据源中的数据类型
 * @implements {IDataSource}
 */
export class DataSourceTemplate<T> implements IDataSource {
  protected mDataSource: T[] = [];
  // 数据改变监听器
  private listeners: DataChangeListener[] = [];

  constructor(dataList: T[]) {
    this.mDataSource = dataList;
  }

  public totalCount(): number {
    return this.mDataSource == null ? 0 : this.mDataSource.length;
  }

  /**
   * 获取指定索引的数据
   * @param {number} index - 需要获取数据的索引
   * @return {T | null} - 如果索引在有效范围内，返回对应的数据，否则返回null
   */
  public getData(index: number): T | null {
    return index >= 0 && index < this.totalCount() ? this.mDataSource[index] : null;
  }

  /**
   * 设置数据的方法
   * @param {T[]} data - 需要设置的数据，数据类型为T的数组
   * @return {void}
   */
  public setData(data: T[]): void {
    this.mDataSource = data;
    this.notifyDataReload();
  }

  /**
   * 注册数据变化监听器
   * @param {DataChangeListener} listener - 数据变化监听器
   * @return {void}
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      Log.info(TAG, 'Add listener');
      this.listeners.push(listener);
    }
  }

  /**
   * 注销数据变化监听器
   * @param {DataChangeListener} listener - 需要注销的监听器
   * @return {void}
   */
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      Log.info(TAG, 'Remove listener');
      this.listeners.splice(pos, 1);
    }
  }

  /**
   * 通知组件重新加载所有数据
   */
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to)
    })
  }
}