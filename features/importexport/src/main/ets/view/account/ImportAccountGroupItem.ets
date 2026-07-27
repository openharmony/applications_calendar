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

import { BigFontSize, CalendarContract, DataSourceTemplate, FontSizeScaleUtils, GlobalThis } from '@app/common';
import { AccountItemData } from '@app/common/index';
import { ImportAccountItem } from './ImportAccountItem';

const TAG: string = 'AccountGroupItem';
const DEFAULT_ACCOUNT_GROUP = 'defaultAccountGroup';
const CUSTOM_ACCOUNT_GROUP = GlobalThis.getResourceStr($r('app.string.account_custom'));

/**
 * 单个帐户组样式
 */
@Component
export struct AccountGroupItem {
  // 族的标题
  @State groupName: string = '';

  // 族数据
  @State items: AccountItemData[] = [];

  @State itemsDataSource: DataSourceTemplate<AccountItemData> = new DataSourceTemplate<AccountItemData>(this.items);

  // 选中的帐户id
  @Link checkedAccId: number;

  aboutToAppear() {
  }

  getGroupNameResource() {
    if (this.groupName === DEFAULT_ACCOUNT_GROUP) {
      return $r('app.string.local_account');
    }
    if (this.groupName === CUSTOM_ACCOUNT_GROUP) {
      return $r('app.string.account_custom');
    }
    return $r('app.string.third_app_event');
  }

  build() {
    Column() {
      Header({
        groupName: this.getGroupNameResource()
      })
      List() {
        ForEach(this.items, (item: CalendarContract.Accounts, index) => {
          ListItem() {
            ImportAccountItem({
              accountId: item.id,
              accountName: item.accountName,
              accountType: item.accountType,
              calendarDisplayName: item.calendarDisplayName,
              calendarColor: item.calendarColor,
              visible: item.visible,
              canReminder: item.canReminder,
              groupName: this.groupName,
              checkedAccId: this.checkedAccId,
              creator: item.creator
            })
          }
        })
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(16)
      .padding({
        top: 4,
        bottom: 4,
        left: 4,
        right: 4
      })
      .divider({
        strokeWidth: '1.5px',
        color: '#19000000',
        startMargin: 56,
        endMargin: 8
      })
    }
  }
}

@Component
struct Header {
  groupName: ResourceStr = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  build() {
    Row() {
      Text(this.groupName)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .fontColor($r('sys.color.font_secondary'))
        .padding({ left: 16 })
        .margin({ top: 28, bottom: $r('sys.float.padding_level4') })
    }
    .alignSelf(ItemAlign.Start)
  }
}