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

import { CompId } from '@app/common';
import { eventAction, IsSettingData } from './declare';
import settingKeys from '../settingKeys';
import { objectFreeze } from '@app/common/src/main/ets/default/common/ObjectFreeze';

const TAG: string = 'Network Service';

/**
 * 设置 - 联网操作
 *
 * @since 2023-07-24
 */
const network: IsSettingData = {
  groupName: $r('app.string.preferences_network_title'),
  compId: CompId.SETTING_NETWORK,
  hide: true,
  items: [
    {
      compId: CompId.SETTINGS_NETWORK,
      title: $r('app.string.preferences_customer_service_title'),
      action: eventAction.SWITCH,
      hide: true,
      settingKey: settingKeys.isAllowNetwork,
      defaultVal: 0,
      event() {
      }
    }
  ]
};

objectFreeze(network);

export default network;
