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

import { Log } from '@app/common';
import { HashMap } from '@kit.ArkTS';

const TAG = 'AgendaCollapseStateRecord';

/**
 * 临时记录weLink日程详情的展开/收起态
 */
export class AgendaCollapseStateRecord {
  private static _instance: AgendaCollapseStateRecord = new AgendaCollapseStateRecord();
  private recordMap: HashMap<string, boolean> = new HashMap<string, boolean>();

  static instance(): AgendaCollapseStateRecord {
    return AgendaCollapseStateRecord._instance;
  }

  query(eventUuid: string) {
    if (eventUuid && this.recordMap.hasKey(eventUuid)) {
      return this.recordMap.get(eventUuid);
    }
    return true;
  }

  record(eventId: string, isAgendaCollapse: boolean) {
    if (!eventId) {
      Log.error(TAG, `eventId is null`);
      return;
    }
    this.recordMap.set(eventId, isAgendaCollapse);
  }
}