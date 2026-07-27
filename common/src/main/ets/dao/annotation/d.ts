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

import { DbValueType, DbValueTypeMapping } from '../DbValueType';

export type Constructor<T> = new (...args: ESObject[]) => T;

// 原型类型
export type Prototype = ESObject;

// 当前支持的类型
export type SupportedDbValueType = Pick<DbValueTypeMapping, DbValueType.DB_LONG | DbValueType.DB_STRING | DbValueType.DB_FLOAT>;