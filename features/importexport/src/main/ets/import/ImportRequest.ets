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
import { TaskState } from '../core/BaseProcessor';
import { Request } from './Request';

/*
 * 导入请求
 */
export class ImportRequest extends Request {
  private mFileUri: string;

  /**
   * 构造函数
   *
   * @param path 路径
   * @param status 状态
   */
  public constructor(fileUri: string, status: TaskState, jobId: number) {
    super(status, jobId)
    this.mFileUri = fileUri;
  }

  public getFileUri(): string {
    return this.mFileUri
  }
}