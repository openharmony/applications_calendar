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

import { CalendarContract } from '../default/calendar/CalendarContract';

/**
 * 帐户组 item
 */
export class AccountItemData extends CalendarContract.Accounts {
  // 帐户类组标题
  public groupName: string = '';
  // 是否编辑模式
  public editMode: boolean = false;
  // 是否是发送端共享账户
  public isShareAccount: boolean = false;
  // 是否是接收端共享账户
  public isShareRecAccount: boolean = false;
}
