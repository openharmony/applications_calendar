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
 * 导入回调
 *
 */
import { ImportRequest } from './import/ImportRequest';

export interface ImportListener<T> {

  onImportStarted(request: ImportRequest, jobId: number): void;

  onImportParsed(request: ImportRequest, jobId: number, currentCount: number, totalCount: number): void;

  onImportFinished(request: ImportRequest, jobId: number, parsedData: T): void;

  onImportFailed(request: ImportRequest, jobId: number, errorCode: number): void;

  onSomeEventsImportFailed(request: ImportRequest, jobId: number): void;

}