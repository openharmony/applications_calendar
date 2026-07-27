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

import { ErrorCode } from '../commoncapability/error/ErrorCode';
import { BusinessError } from '@kit.BasicServicesKit';

const SUCCESS_CODE = 0;

/**
 * 结果
 */
export class Result<T> {
  public readonly code: number;
  public readonly data: T;
  public readonly message: string;

  constructor(code: number, message: string, data: T) {
    this.code = code;
    this.message = message;
    this.data = data;
  }

  static buildByError(error: Error): Result<undefined> {
    if (!error) {
      return UNKNOWN_ERROR_RESULT;
    }
    const code: number = (error as BusinessError).code ?? ErrorCode.UN_KNOWN;
    return new Result(code, error.message, undefined);
  }

  static buildByErrorWithData<DATA>(error: Error, data: DATA): Result<DATA> {
    if (!error) {
      return new Result(ErrorCode.UN_KNOWN, 'unknown error', data);
    }
    const code: number = (error as BusinessError).code ?? ErrorCode.UN_KNOWN;
    return new Result(code, error.message, data);
  }

  static buildSuccessResult<T>(data: T = undefined): Result<T> {
    return new Result(SUCCESS_CODE, 'success', data);
  }

  static buildFailResult<T>(code: number, message: string, data: T = undefined): Result<T> {
    return new Result(code, message, data);
  }

  static copyResult<T, F>(sourceResult: Result<F>, data: T): Result<T> {
    return new Result(sourceResult.code, sourceResult.message, data);
  }

  public isSuccess(): boolean {
    return this.code === SUCCESS_CODE;
  }

  toString(): string {
    return `code is ${this.code} message is ${this.message}`;
  }
}

const UNKNOWN_ERROR_RESULT = new Result<undefined>(ErrorCode.UN_KNOWN, 'unknown error', undefined);