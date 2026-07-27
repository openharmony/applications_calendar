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

import { CardService, Log, ServiceEnum, ServiceManager } from '@app/common';
import StaticSubscriberExtensionAbility from '@ohos.application.StaticSubscriberExtensionAbility';
import commonEventManager from '@ohos.commonEventManager';

const TAG: string = 'StaticSubscriber';

/**
 * 静态监听系统时间改变/时区变化刷新所有卡片
 */
export default class StaticSubscriber extends StaticSubscriberExtensionAbility {
  async onReceiveEvent(event: commonEventManager.CommonEventData): Promise<void> {
    Log.info(TAG, `system_date changes to refresh cards`);
    const cardService = await ServiceManager.getInstance().getDynamicService<CardService>(ServiceEnum.CARD_SERVICE);
    cardService?.refreshAllCards();
  }
}