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

import { Service } from '../../framework/Service';

export interface BlockUser {
  blockedAccount: string;
  blockedTime: number;
}
/**
 * 共享服务
 */
export abstract class ShareService extends Service {
  abstract updateEnableReceiveShareDataSwitch(enableReceiveShareDataSwitch: boolean,
                                              needUpdateCloudState: boolean): void;

  abstract isShareSupport(): Promise<boolean>;

  /*
  * 获取共享状态
  */
  abstract isShareEnable(): Promise<boolean>;

  /*
  * 删除黑名单用户
  */
  abstract deleteBlockUsers(accountList: string[]): Promise<Boolean>;

  /*
  * 获取黑名单用户
  */
  abstract queryBlockUsers(): Promise<BlockUser[]>;
}