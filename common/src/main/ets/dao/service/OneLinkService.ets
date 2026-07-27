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

import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Log } from '../../default/common/Log';
import { SqlFaultHandle } from '../../default/util/ReportUtil';
import { OneLinkRepository } from '../repo/OneLinkRepository';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '../../default/common/TraceEvents';

const TAG = 'OneLinkService';

export class OneLinkService {
  static readonly INSTANCE: OneLinkService = new OneLinkService();
  public repo: OneLinkRepository;

  private constructor() {
    this.repo = new OneLinkRepository
  }

  /**
   *插入 OneLink数据
   * @param onLinkData
   * @returns
   */
  async insertOneLinkDataArray(onLinkData: Array<ValuesBucket>): Promise<boolean> {
    if (!onLinkData) {
      Log.error(TAG, 'CheckValuesArray is null');
      return false;
    }
    try {
      hiTraceMeter.startTrace(traceEvents.insertOneLink, 0);
      let oneLinkIds = await this.repo.batchInsertOneLink(onLinkData);
      hiTraceMeter.finishTrace(traceEvents.insertOneLink, 0);
      if (oneLinkIds <= 0) {
        return false;
      }
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'insertOneLinkDataArray', err);
      SqlFaultHandle.insertSqlFail(err?.message, TAG)
      return false;
    }
  }
}