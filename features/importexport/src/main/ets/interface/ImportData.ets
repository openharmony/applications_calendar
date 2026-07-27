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

import { AgendaEventInfo } from '@app/common/src/main/ets/agenda/AgendaEventInfo';
import { ImportType } from './BusinessConstant';
import { SimpleAccount } from './SimpleAccount';

/**
 * 导入文件解析结果数据
 */
export class ImportData {
  public readonly simpleAccount: SimpleAccount;
  public readonly importType: ImportType = ImportType.ACCOUNT_IMPORT;
  public readonly mEventsCount: number = 0;
  // 解析的预览日程,最多三个
  public readonly mHeadEvents: AgendaEventInfo[];
  // 解析的所有日程
  public readonly mAllEvents: AgendaEventInfo[];

  constructor(simpleAccount: SimpleAccount, importType: ImportType, eventsCount: number,
              headEvents: AgendaEventInfo[], allEvents: AgendaEventInfo[]) {
    this.simpleAccount = simpleAccount;
    this.importType = importType;
    this.mEventsCount = eventsCount;
    this.mHeadEvents = headEvents;
    this.mAllEvents = allEvents;
  }
}