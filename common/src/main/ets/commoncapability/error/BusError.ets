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

/**
 * 业务错误
 */
export class BusError<T = void> extends Error {
  public readonly code: number;
  public readonly data?: T;
  public readonly name: string;
  public readonly message: string;
  public readonly stack?: string;

  constructor(code: number, message: string, data?: T, name?: string, stack?: string) {
    super(message);
    this.code = code;
    this.message = message;
    this.name = name ?? '';
    this.stack = stack ?? '';
    this.data = data;
  }
}