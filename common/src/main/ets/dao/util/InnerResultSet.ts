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
import { DataShareResultSet, DataType } from '@kit.ArkData';
import { Log } from '../../default/common/Log';

const TAG = 'InnerResultSet';

export class ResultSetLeakTracker {
  private static resultList : string[] = [];

  public static dumpResultList(): void {
    Log.info(TAG, `ResultSet count: ${ResultSetLeakTracker.resultList.length}`);
    for (const tag of ResultSetLeakTracker.resultList) {
      Log.error(TAG, `ResultSet leak tag: ${tag}`);
    }
  }

  public static register(tag: string): void {
    const maxCount = 32;
    const warnCount = 5;
    Log.info(TAG, `register ${tag}`);
    ResultSetLeakTracker.resultList.push(tag);
    if (ResultSetLeakTracker.resultList.length >= maxCount) {
      Log.error(TAG, 'ResultSet count over 30!');
    } else if (ResultSetLeakTracker.resultList.length >= warnCount) {
      Log.warn(TAG, 'ResultSet count over 5!');
      ResultSetLeakTracker.dumpResultList();
    }
  }

  public static unregister(tag: string): void {
    Log.info(TAG, `unregister ${tag}`);
    const index = ResultSetLeakTracker.resultList.indexOf(tag);
    if (index > -1) {
      ResultSetLeakTracker.resultList.splice(index, 1);
    }
  }
}

export class InnerResultSet implements DataShareResultSet {
  private data : DataShareResultSet;
  private tag : string = '';

  constructor(data : DataShareResultSet, creator : string) {
    this.data = data;
    this.tag = creator + '_' + Date.now();
    ResultSetLeakTracker.register(this.tag);
  }

  public getTag(): string {
    return this.tag;
  }

  get columnNames(): string[] {
    return this.data.columnNames;
  }

  get columnCount(): number {
    return this.data.columnCount;
  }

  get rowCount(): number {
    return this.data.rowCount;
  }

  get isClosed(): boolean {
    return this.data.isClosed;
  }

  goToFirstRow(): boolean {
    return this.data.goToFirstRow();
  }

  goToLastRow(): boolean {
    return this.data.goToLastRow();
  }

  goToNextRow(): boolean {
    return this.data.goToNextRow();
  }

  goToPreviousRow(): boolean {
    return this.data.goToPreviousRow();
  }

  goTo(offset: number): boolean {
    return this.data.goTo(offset);
  }

  goToRow(position: number): boolean {
    return this.data.goToRow(position);
  }

  getBlob(columnIndex: number): Uint8Array {
    return this.data.getBlob(columnIndex);
  }

  getString(columnIndex: number): string {
    return this.data.getString(columnIndex);
  }

  getLong(columnIndex: number): number {
    return this.data.getLong(columnIndex);
  }

  getDouble(columnIndex: number): number {
    return this.data.getDouble(columnIndex);
  }

  close(): void {
    this.data.close();
    ResultSetLeakTracker.unregister(this.tag);
  }

  getColumnIndex(columnName: string): number {
    return this.data.getColumnIndex(columnName);
  }

  getColumnName(columnIndex: number): string {
    return this.data.getColumnName(columnIndex);
  }

  getDataType(columnIndex: number): DataType {
    return this.data.getDataType(columnIndex);
  }

}
