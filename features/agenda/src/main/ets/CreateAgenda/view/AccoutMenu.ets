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

import { RadioListDialog, RadioListStyle } from '@app/common.components';
import { AccountUtils, CalendarContract, ThrottleFunction } from '@app/common';
import { RadioListOption } from '@app/common.components/src/main/ets/radioList/RadioList';

const TAG = 'AccountMenu';

/**
 * 帐户弹窗
 */
@Component
export struct AccountMenu {

  private accountList: CalendarContract.Accounts[] = [];

  private groupName: string = 'create_agenda_account_group';

  @State defaultSelect: number = 0;

  @State options: RadioListOption[] = [];

  @Link checkValue: number;

  private onChange: (value: number) => void = (value: number): void => {
  };

  aboutToAppear(): void {
    this.accountList.forEach((account) => {
      let builtInName: ResourceStr = AccountUtils.getAccountResourceStr(account);
      this.options.push({ label: builtInName || account.calendarDisplayName, value: account.id });
    })
  }

  build() {
    RadioListDialog({
      title: $r('app.string.title_account'),
      options: this.options,
      radioGroup: this.groupName,
      cancel: () => {},
      checkValue: $checkValue,
      multiSelect: false,
      showConfirm: false,
      style: RadioListStyle.Menu,
      onChange: (value: number) => {
        ThrottleFunction.instance().debounce(TAG + 'onChange', ()=>{
          this.onChange(value);
          this.checkValue = value;
        }, 50)
      }
    })
  }
}