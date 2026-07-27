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

/**
 * 导入账户或日程时,弹出的选择日程账户,用户保存后封装的账户信息,导入账户时,mAccountId 为0,导入日程时mAccountId为有效值
 *
 * 解析完导入的vcs文件后传递给弹出的账户信息,导入账户时才有
 */
export class SimpleAccount {
  public readonly mAccountId: number = 0;
  public readonly mAccountDisplayName: string = '';
  public readonly mAccountColor: number = 0;
  public readonly mAlarmEnable: boolean = true;

  constructor(accountId: number, accountDisplayName?: string, accountColor?: number, alarmEnable?: boolean) {
    this.mAccountId = accountId
    if (accountDisplayName !== undefined) {
      this.mAccountDisplayName = accountDisplayName
    }
    if (accountColor !== undefined) {
      this.mAccountColor = accountColor
    }
    if (alarmEnable !== undefined) {
      this.mAlarmEnable = alarmEnable
    }
  }
}