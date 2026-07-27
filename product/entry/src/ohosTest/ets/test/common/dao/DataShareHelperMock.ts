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
import { dataSharePredicates, ValuesBucket, DataType, DataShareResultSet } from '@kit.ArkData';

/**
 * 用于mock底层传出的数据库对象
 */
export class DataShareResultSetMock implements DataShareResultSet {
  rowCount: number = 0;
  private flag = false;
  public columnNames: Array<string> = [];

  constructor() {
  }

  get columnCount(): number {
    return 0;
  }

  isClosed : boolean = false;

  goToLastRow(): boolean {
    return false;
  }

  goToPreviousRow(): boolean {
    return false;
  }

  goTo(offset: number): boolean {
    return false;
  }

  goToFirstRow(): boolean {
    return false;
  }

  goToNextRow(): boolean {
    this.flag = !this.flag;
    return this.flag;
  }

  close() {
    this.isClosed = true;
  }

  public static getColumnStringData(ds: DataShareResultSet, column: string, defaultValue: string): string {
    return defaultValue;
  }

  public static getColumnLongData(ds: DataShareResultSet, column: string, defaultValue: number): number {
    return defaultValue;
  }

  goToRow(position: number): boolean {
    return false;
  }

  getBlob(columnIndex: number): Uint8Array {
    return new Uint8Array;
  }

  getString(columnIndex: number): string {
    return '';
  }

  getLong(columnIndex: number): number {
    return 0;
  }

  getDouble(columnIndex: number): number {
    return 0;
  }

  getColumnIndex(columnName: string): number {
    return 0;
  }

  getColumnName(columnIndex: number): string {
    return '';
  }

  getDataType(columnIndex: number): DataType {
    return DataType.TYPE_NULL;
  }
}

export class DataShareHelper {
  async insert(uri: string, value: ValuesBucket): Promise<number> {
    return 0;
  }

  async delete(uri: string, predicates: dataSharePredicates.DataSharePredicates): Promise<number> {
    return 0;
  }

  async query(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: string[]): Promise<DataShareResultSet> {
    return new DataShareResultSetMock();
  };

  async update(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: ValuesBucket): Promise<number> {
    return 0;
  }

  async batchInsert(uri: string, values: ValuesBucket[]): Promise<number> {
    return 0;
  }
}