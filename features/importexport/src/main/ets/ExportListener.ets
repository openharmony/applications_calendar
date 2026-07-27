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
 * 导出回调
 *
 */
import { Request } from './import/Request';

export interface ExportListener<T> {

  onExportStarted(request: Request, jobId: number): void;

  onExportProgressChanged(jobId: number, totalEventCount: number, processedEventCount: number): void;

  onExportProcessed(request: Request, jobId: number, exportData: T): void;

  onExportFailed(request: Request, jobId: number, errorCode: number): void;

  onExportFinished(request: Request, jobId: number): void;

}