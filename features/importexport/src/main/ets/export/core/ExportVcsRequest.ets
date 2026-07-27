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

import { GlobalThis, Log } from '@app/common';
import { TaskState } from '../../core/BaseProcessor';
import { ExportType, ShareType } from '../../interface/BusinessConstant';
import { Request } from '../../import/Request';
import { SimpleAccount } from '../../interface/SimpleAccount';

const TAG = 'ExportRequest'

/**
 * 导出Vcs文件格式请求
 */
export class ExportVcsRequest extends Request {
  public readonly mPath: string;
  public readonly mIcsPath: string;
  public readonly simpleAccount: SimpleAccount | undefined;
  public readonly eventIds: Array<number>;
  public readonly exportType: ExportType;
  public readonly shareType: ShareType;

  public constructor(simpleAccount: SimpleAccount | undefined,
                     eventIds: Array<number>,
                     path: string, icsPath: string,status: TaskState,
                     exportType: ExportType, jobId: number, shareType: ShareType) {
    super(status, jobId)
    this.exportType = exportType;
    this.mPath = path;
    this.mIcsPath = icsPath;
    this.simpleAccount = simpleAccount;
    this.eventIds = eventIds;
    this.shareType = shareType;
  }

  public getAccountId(): number {
    if (this.simpleAccount) {
      return this.simpleAccount.mAccountId;
    }
    return 0
  }

  public getEventIds(): Array<number> {
    return this.eventIds;
  }

  public getPath(): string {
    return this.mPath;
  }

  public getIcsPath(): string {
    return this.mIcsPath;
  }

  public getDescription(context: Context, resourceId: Resource): string {
    if (!context) {
      Log.warn(TAG, `getDescription context is null`);
      return ''
    }
    return GlobalThis.getResourceStr(resourceId);
  }
}