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
  AccountUtils,
  BigFontSize,
  CalendarContract,
  CalendarService,
  CommonInnerEvent,
  CommonService,
  GlobalThis,
  Log,
  NavPathManager,
  RouterName,
  SafeUtil
} from '@app/common/index';
import HashMap from '@ohos.util.HashMap';
import { ValueType } from '@ohos.data.ValuesBucket';
import dataStorage from '@ohos.data.storage';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { emitter } from '@kit.BasicServicesKit';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'ImportAgendaAccount';
const DEFAULT_NUM: number = -1;
const DEFAULT_STR: string = '';

@Component
export struct ImportAgendaAccount {
  @Consume navPathStack: NavPathStack;

  // 帐户颜色
  @State accountColor: number = DEFAULT_NUM;

  // 帐户展示名
  @State accountDisName: string = DEFAULT_STR;

  // 选中的帐户 id 值
  @Link @Watch('onCheckedAccountChange') checkedAccId: number;

  // 显示半模态
  @Link isShowImportPage: boolean;

  // 是否跳转到了账户列表页
  @Link isJumpToAccount: boolean;

  @Link allEventsAreImportant: boolean;

  // 所有帐户列表
  private accountList: CalendarContract.Accounts[] = [];

  // 帐户 MAP 映射：帐户ID ——> 帐户信息
  private accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap<number, CalendarContract.Accounts>();

  // storage 本地持久化账户
  private storage = dataStorage.getStorageSync(GlobalThis.getInstance().fileDir + '/account');

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  aboutToAppear() {
    this.getShowAccount();
  }

  /**
   * 获取需要展示的帐户信息
   */
  async getShowAccount() {
    let accounts: CalendarContract.Accounts[] = await CalendarService
      .INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    this.accountList = AccountUtils.sortAccountListInAccPage(accounts);
    this.accountMap = CommonService.INSTANCE.getAccountMap(this.accountList);
    const value: ValueType = this.storage.getSync('checkedAccId', DEFAULT_NUM);
    const storeId: number = Number.parseInt(value.toString());
    let defaultAccountId = this.accountList[0].id;
    this.checkedAccId = this.checkedAccId === 0 ? (this.accountMap.get(storeId) ? storeId : defaultAccountId)
      : (this.allEventsAreImportant ? defaultAccountId
        : (this.accountMap.hasKey(this.checkedAccId) ? this.checkedAccId : defaultAccountId));
    this.accountColor = this.accountMap.get(this.checkedAccId).calendarColor;
    this.accountDisName = this.accountMap.get(this.checkedAccId).calendarDisplayName;
  }

  /**
   * 选中的帐户改变回调
   */
  onCheckedAccountChange() {
    if (this.accountMap.length > 0) {
      this.accountColor = this.accountMap.get(this.checkedAccId)?.calendarColor;
      this.accountDisName = this.accountMap.get(this.checkedAccId)?.calendarDisplayName;
    }
  }

  build() {
    Row() {
      Row() {
        this.buildContent()
      }
      .padding({
        left: 8,
        right: 8
      })
      .borderRadius($r('sys.float.corner_radius_level8'))
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor(this.allEventsAreImportant ? Color.Transparent : $r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .constraintSize({ minHeight: 56 })
    }
    .padding(4)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .onClick(this.allEventsAreImportant ? null : () => {
      this.jumpToAccountPage();
    })
  }

  @Builder
  buildContent() {
    this.verticalLayout();
    Row() {
      Text($r('app.string.calendar'))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ end: LengthMetrics.vp(8) });

      Row() {
        Circle()
          .height(4)
          .width(4)
          .strokeWidth(4)
          .stroke(this.accountColor)
          .margin({ end: LengthMetrics.vp(8) });
        Text(
          AccountUtils.getAccountResourceMap().get(this.accountDisName)
            ? AccountUtils.getAccountResourceMap().get(this.accountDisName) : this.accountDisName
        )
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'))
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity($r('sys.float.alpha_tertiary'))
          .margin({ end: this.allEventsAreImportant ? LengthMetrics.vp(12) : LengthMetrics.vp(0) });
        if (!this.allEventsAreImportant) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_fourth')])
            .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End);
    }
    .visibility(this.accountColor !== -1 && this.accountDisName !== '' && !this.isChangeLayout()
      ? Visibility.Visible : Visibility.None)
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
  }

  @Builder
  verticalLayout() {
    Column() {
      Text($r('app.string.calendar'))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ end: LengthMetrics.vp(8) });

      Row() {
        Circle()
          .height(4)
          .width(4)
          .strokeWidth(4)
          .stroke(this.accountColor)
          .margin({ end: LengthMetrics.vp(8) });
        Text(
          AccountUtils.getAccountResourceMap().get(this.accountDisName)
            ? AccountUtils.getAccountResourceMap().get(this.accountDisName) : this.accountDisName
        )
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'))
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity($r('sys.float.alpha_tertiary'))
          .margin({ end: this.allEventsAreImportant ? LengthMetrics.vp(12) : LengthMetrics.vp(0) });
        if (!this.allEventsAreImportant) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_fourth')])
            .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
        }
      }
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .visibility(this.accountColor !== -1 && this.accountDisName !== '' && this.isChangeLayout()
      ? Visibility.Visible : Visibility.None)
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SCALE;
  }

  private async jumpToAccountPage() {
    emitter.emit({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG })

    // 解决日程详情退出一镜到底动画导致闪一下
    SafeUtil.setTimeout(async () => {
      const params: Record<string, number> = {};
      params.checkedAccId = this.checkedAccId;
      const jumpResult = NavPathManager.getInstance().pushPath({
        builderName: NavPathName.IMPORT_ACCOUNT,
        routerName: RouterName.ENTRY_HAP,
        param: params
      });
      if (!jumpResult) {
        Log.warn(TAG, `jumpToAccountPage jumpResult false`);
        return;
      }
      this.isShowImportPage = false;
      this.isJumpToAccount = true;
    }, 200);
  }
}