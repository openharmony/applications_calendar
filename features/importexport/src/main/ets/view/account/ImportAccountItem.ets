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

import { AccountUtils, CalendarContract, CommonInnerEvent } from '@app/common/index';
import emitter from '@ohos.events.emitter';

const TAG: string = 'AccountItem';
type Value = string | number;

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 帐户组单个帐户
 */
@Component
export struct ImportAccountItem {
  @Consume navPathStack: NavPathStack;

  @StorageProp('themeColor') themeColor: string = '';

  @Link groupName: string;

  @Link checkedAccId: number;

  private accountId: number = -1

  private accountName: string = '';

  private accountType: string = '';

  private calendarDisplayName: string = '';

  private calendarColor: number = -1;

  private visible: number = -1;

  private canReminder: number = 1;

  private creator: string = '';

  selectAccount() {
    this.onChange(this.checkedAccId = this.accountId);
    let eventData: emitter.EventData = {
      data: {
        'checkedAccId': this.checkedAccId,
        'accountColor': this.calendarColor
      }
    };
    this.navPathStack.pop();
    emitter.emit({ eventId: CommonInnerEvent.VCS_ACCOUNT_CHANGE }, eventData)
  }

  build() {
    Row() {
      Row() {
        Circle()
          .height(20)
          .width(20)
          .fill(this.calendarColor)
          .margin({ right: 12 })
        Text(this.getFormatDisplayName())
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Radio({ value: this.checkedAccId + '', group: this.groupName })
          .radioStyle({
            checkedBackgroundColor: this.calendarColor,
            indicatorColor: $r('sys.color.comp_background_primary_contrary')
          })
          .checked(this.accountId == this.checkedAccId)
          .height(24)
          .width(24)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.selectAccount();
          })
      }
    }
    .width('100%')
    .height(64)
    .padding({ top: 4, bottom: 4, left: 12 })
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .onClick(() => {
      this.selectAccount();
    })
    .borderRadius(12)
  }

  // 选中项发生变化
  private onChange: (value: number) => void = (value: number) => {
  };

  private getFormatDisplayName(): string | Resource {
    const account: CalendarContract.Accounts = new CalendarContract.Accounts();
    account.accountType = this.accountType;
    account.creator = this.creator;
    if (AccountUtils.isDefaultAccount(account) && 'Phone' == this.calendarDisplayName) {
      return $r('app.string.my_calendar');
    }
    const calendarAccount: CalendarContract.Accounts = new CalendarContract.Accounts();
    calendarAccount.accountType = this.accountType;
    calendarAccount.accountName = this.accountName;
    if (AccountUtils.isExchangeAccount(calendarAccount)) {
      if (this.calendarDisplayName.endsWith('@outlook.com')) {
        const lastIndex: number = this.calendarDisplayName.lastIndexOf('@outlook.com');
        return this.calendarDisplayName.substring(0, lastIndex);
      }
    }
    return this.calendarDisplayName;
  }
}
