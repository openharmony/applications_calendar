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

import { ImportantCardConfig } from '../../../card/ImportantCardConfig';
import { Service } from '../../framework/Service';

export interface RefreshConfig {
  refreshTriggerType?: number;
}

/**
 * 卡片公共数据刷新
 */
export abstract class CardService extends Service {
  abstract refreshCard(formId: string): void;

  abstract refreshAllCards(refreshConfig?: RefreshConfig): void;

  abstract initAllCards(): void;

  abstract refreshAllCardsDoubleUpSingleAgreeStatement(): void;


  abstract refreshImportantCard(
    context: Context | null,
    formId: string,
    isCard2x2?: boolean,
    config?: ImportantCardConfig,
    refreshConfig?: RefreshConfig,
  ): void;

  abstract saveImportantCardConfig(formId: string, formConfig: ImportantCardConfig);

  abstract findEventId(migrateType: number, formId: string);
}