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
 * DbValueType
 */
export enum DbValueType {
  DB_STRING = 'dbString',
  DB_LONG = 'dbLong',
  DB_BLOB = 'dbBlob',
  DB_FLOAT = 'dbFloat',
}

export class DbValueTypeMapping {
  'dbString': string = '';
  'dbLong': number = 0;
  'dbBlob': Uint8Array = new Uint8Array();
  'dbFloat': number = 0;
}