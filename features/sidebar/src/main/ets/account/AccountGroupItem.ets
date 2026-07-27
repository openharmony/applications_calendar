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

import {
  AccountItemData,
  AccountUtils,
  BigFontSize,
  CompId,
  DataSourceTemplate,
  DeviceConfig,
  FeatureType,
  FontSizeScaleUtils,
  Log
} from '@app/common';

import lazy { AccountItem } from './AccountItem';
import { addExpandStatus, broadcastExpandStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'SideBarAccountGroupItem';

class AccountItemDataSource extends DataSourceTemplate<AccountItemData> {
}

/**
 * 单个帐户组样式
 */
@Component
export struct AccountGroupItem {
  // 族的标题
  @State groupName: string = '';

  // 族数据
  @State items: AccountItemData[] = [];

  @State isArrowDown: boolean = false;

  // 主题色
  @State themeColor: string = '';

  // 侧边栏是否为悬浮态
  @Prop sideBarOverlay: boolean;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private deleteAccountHandler: (accountId: number, uuid: string) => void = (accountId: number, uuid: string) => {
  };

  build() {
    Column() {
      Header({
        groupName: this.getFormatGroupName(),
        isArrowDown: this.isArrowDown,
        themeColor: this.themeColor,
        isDefaultAccounts: AccountUtils.DEFAULT_ACCOUNT_GROUP === this.groupName
      })
      CollapseAndExpand({
        items: this.items,
        isArrowDown: this.isArrowDown,
        sideBarOverlay: this.sideBarOverlay,
        deleteAccountHandler: this.deleteAccountHandler,
      })
    }
    .margin({
      bottom: this.needCommerce ? $r('sys.float.padding_level4') : $r('sys.float.padding_level0')
    })
  }

  private getFormatGroupName(): ResourceStr {
    Log.info(TAG, `getFormatGroupName`)
    if (AccountUtils.DEFAULT_ACCOUNT_GROUP === this.groupName) {
      return $r('app.string.local_calendar')
    }
    return this.groupName;
  }
}

@Component
struct Header {
  @Link isArrowDown: boolean;

  @State isHoverShow: boolean = false;

  // 主题色
  @State themeColor: string = '';

  @StorageLink('isAccountLogin') isAccountLogin: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  groupName: ResourceStr = '';

  @State buttonColor: ResourceColor = Color.Transparent;

  private showFloatButton: boolean = DeviceConfig.instance().config.showFloatButton;

  private isDefaultAccounts: boolean = false;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  //是否支持日历账户云同步
  private readonly isCloudSynchronization: boolean = DeviceConfig.instance().isSupport(FeatureType.CALENDAR_SHARE);

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onFontSizeScaleChange() {
    return FontSizeScaleUtils.getLimitFontSizeVp(
      this.fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_SCALE_2X,
      14
    );
  }

  @Builder
  buildGroupName() {
    Text(this.getAccountGroupName())
      .fontSize(this.onFontSizeScaleChange())
      .fontColor($r('sys.color.font_tertiary'))
      .fontWeight(FontWeight.Medium)
      .fontFamily('HarmonyHeiTi')
      .constraintSize({
        maxWidth: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ?
          160 : 120,
        minHeight: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL ?
          40 : 35
      })
      .maxLines(2)
      .align(Alignment.Bottom)
      .padding({ bottom: 4 })
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .id(this.isDefaultAccounts && this.isAccountLogin ?
      CompId.SIDEBAR_ACCOUNT_CALENDAR_LOGIN : CompId.LOCAL_CALENDAR)
  }

  private getAccountGroupName() {
    if (!this.isCloudSynchronization) {
      return $r('app.string.local_calendar');
    }
    return this.isDefaultAccounts && this.isAccountLogin ? $r('app.string.sidebar_account_calendar_login') : this.groupName;
  }

  build() {
    Row() {
      this.buildGroupName();
      Blank()
      Column() {
        SymbolGlyph(this.isArrowDown ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([this.themeColor])
          .visibility((this.showFloatButton || this.isHoverShow) ? Visibility.Visible : Visibility.None)
      }
      .constraintSize({ minHeight: 26, minWidth: 26 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : 26)
      .backgroundColor(this.buttonColor)
      .hoverEffect(HoverEffect.Highlight)
    }
    .accessibilityText(addExpandStatus(this.getAccountGroupName(), !this.isArrowDown))
    .accessibilityRole(5)
    .alignItems(VerticalAlign.Bottom)
    .padding({
      start: LengthMetrics.vp(8),
      end: LengthMetrics.vp(4),
      top: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? LengthMetrics.vp(10) : LengthMetrics.vp(0),
      bottom: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? LengthMetrics.vp(10) : LengthMetrics.vp(8)
    })
    .constraintSize({ minHeight: this.needCommerce ? 40 : 56 })
    .width('100%')
    .borderRadius(20)
    .onTouch((ev) => {
      if (ev.type === TouchType.Up || ev.type === TouchType.Cancel) {
        this.buttonColor = Color.Transparent
      } else if (ev.type === TouchType.Down) {
        this.buttonColor = $r('sys.color.interactive_click');
      }
    })
    .onClick(() => {
      this.onFlagChange()
      broadcastExpandStatus(!this.isArrowDown);
    })
    .onHover((isHover) => {
      if (isHover) {
        this.isHoverShow = true;
      } else {
        this.isHoverShow = false;
      }
    })
    .id(CompId.EXPAND_AND_COLLECTION_ACCOUNTS)
  }

  private onFlagChange = () => {
    this.isArrowDown = !this.isArrowDown;
  }
}

@Component
struct CollapseAndExpand {
  @Link isArrowDown: boolean;

  // 侧边栏是否为悬浮态
  @Prop sideBarOverlay: boolean;

  private items: AccountItemData[] = [];

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;
  private deleteAccountHandler: (accountId: number, uuid: string) => void = (accountId: number, uuid: string) => {
  };

  build() {
    List() {
      ForEach(this.items, (item: AccountItemData, index) => {
        ListItem() {
          AccountItem({
            creator: item.creator,
            accountId: item.id,
            accountName: item.accountName,
            accountType: item.accountType,
            calendarDisplayName: item.calendarDisplayName,
            calendarColor: item.calendarColor,
            visible: item.visible,
            canReminder: item.canReminder,
            uuid: item.uuid,
            deleteAccountHandler: this.deleteAccountHandler,
          })
        }
        .margin({
          top: this.needCommerce ? $r('sys.float.padding_level1') : $r('sys.float.padding_level0')
        })
      })
    }
    .scrollBar(BarState.Off)
    .backgroundColor(Color.Transparent)
    .width('100%')
    .clip(true)
    .visibility(this.isArrowDown ? Visibility.None : Visibility.Visible)
  }
}