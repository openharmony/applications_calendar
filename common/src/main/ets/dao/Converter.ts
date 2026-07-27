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
import { BusinessError } from '@ohos.base';
import { ErrorCode } from '../commoncapability/error/ErrorCode';
import { InnerResultSet } from './util/InnerResultSet';

/*
 * Parser 将resultSet解析成对应的T
 */
export interface Parser<T> {

  /**
   * 解析成内存模型,不允许里面捕获异常不抛出
   * @param resultSet
   * @param columns
   * @returns
   */
  parseToModel(resultSet: InnerResultSet, columns?: string[]): T;
}

/*
 * Converter 将resultSet转换为期望的FinalResult
 */
export interface Converter<SingleItem, FinalResult> {
  parser: Parser<SingleItem>;

  buildErrorData(): FinalResult;

  buildEmptyData(): FinalResult;

  parseResultSetToModel(resultSet: InnerResultSet, columns?: string[]): FinalResult;
}

/*
 * BaseConverter,定义构造方法
 */
export abstract class BaseConverter<SingleItem, FinalResult> implements Converter<SingleItem, FinalResult> {
  public readonly parser: Parser<SingleItem>;

  constructor(parser: Parser<SingleItem>) {
    this.parser = parser;
  }

  abstract buildErrorData(): FinalResult;

  abstract buildEmptyData(): FinalResult;

  abstract parseResultSetToModel(resultSet: InnerResultSet, columns?: string[]): FinalResult;
}

const TAG = 'ResultSetToArrayConverter';

/*
 * ResultSetToArrayConverter 将ResultSet转化为数组,数组元素是SingleItem
 */
export class ResultSetToArrayConverter<SingleItem> extends BaseConverter<SingleItem, SingleItem[]> implements Converter<SingleItem, SingleItem[]> {
   constructor(parser: Parser<SingleItem>) {
    super(parser);
  }

  buildErrorData(): SingleItem[] {
    return [];
  }

  buildEmptyData(): SingleItem[] {
    return [];
  }

  parseResultSetToModel(resultSet: InnerResultSet, columns?: string[]): SingleItem[] {
    const allItem: SingleItem[] = [];
    do {
      const tableItem = this.parser.parseToModel(resultSet, columns);
      if (!tableItem) {
        Log.error(TAG, `parseResultSetToModel parsed tableItem is null`);
        const error: BusinessError = {
          code: ErrorCode.ILLEGAL_CODE,
          message: 'parseResultSetToModel parsed tableItem is null',
          name: 'BusinessError'
        };
        throw error;
      }
      allItem.push(tableItem);
    } while (resultSet.goToNextRow());
    return allItem;
  }
}

/*
 * ResultSetToModelConverter 将ResultSet转化为数据模型,数据模型是SingleItem
 */
export class ResultSetToModelConverter<SingleItem> extends BaseConverter<SingleItem, SingleItem> implements Converter<SingleItem, SingleItem> {
  constructor(parser: Parser<SingleItem>) {
    super(parser);
  }

  buildErrorData(): undefined {
    return undefined;
  };

  buildEmptyData(): undefined {
    return undefined;
  }

  parseResultSetToModel(resultSet: InnerResultSet, columns?: string[]): SingleItem {
    return this.parser.parseToModel(resultSet, columns);
  }
}