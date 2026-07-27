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
  behaviorEvents,
  BigFontSize,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  HolidayUtil,
  Log,
  maskString,
  NavPathManager,
  NavPathName,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ThrottleFunction,
  SafeUtil
} from '@app/common';
import { TipsPopup } from '@app/common.components';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import measure from '@ohos.measure';
import emitter from '@ohos.events.emitter';
import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';

// 避免循环依赖问题
import { AccountDetail } from '@app/feature.account';
import { CACHE_SYNC_SWITCH_STATUS, CloudUtils } from '@app/common/src/main/ets/dao/CloudUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { barText, sendAccessibilityEvent } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { AccountMenu, AccountMenuOpt } from './AccountMenu';

const SWITCH_ON: number = 1;

const TAG: string = 'SideBarAccountItem';

const ACCOUNT_NAME_WIDTH: number = 90; // 账户卡片名称区域的边距

const NORMAL_ACCOUNT_OPT: AccountMenuOpt[] = [ // 普通日程右键菜单选项
  AccountMenuOpt.VIEW,
  AccountMenuOpt.DELETE
];
const DEFAULT_ACCOUNT_OPT: AccountMenuOpt[] = [ // 无法删除的默认日程右键菜单选项
  AccountMenuOpt.VIEW
];

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 帐户组单个帐户
 */
@Component
export struct AccountItem {
  @Consume navPathStack: NavPathStack;

  @State isHoverShow: boolean = false;

  @State shareText: ResourceStr = $r('app.string.preferences_share_title');

  @State shareTextWidth: number = 0;

  @StorageLink('language') @Watch('onLanguageChanges') language: string = '';

  @StorageLink(CACHE_SYNC_SWITCH_STATUS) syncSwitchStatus: number = 0;

  // 模态窗动画结束标识
  @Provide isAccountAniShowFinish: boolean = false;

  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

  @StorageProp('fontSizeScale') @Watch('onFontSizeChange') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  private deleteAccountHandler: (accountId: number, uuid: string) => void = (accountId: number, uuid: string) => {
  };

  shareSwitchDialogController: CustomDialogController | null = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.share_clound_switch'),
      primaryButton: {
        value: $r('app.string.cancel_dialog_button'),
        action: () => {
        },
        fontColor: this.themeColor
      },
      secondaryButton: {
        value: $r('app.string.share_open'),
        action: () => {
          CloudUtils.jumpCloudDrivePage();
        },
        fontColor: this.themeColor
      },
    }),
    alignment: this.dialogControllerOptions.alignment,
    autoCancel: this.dialogControllerOptions.autoCancel,
  });

  @State isShowAccountDetailPage: boolean = false;

  private accountId: number = -1

  private accountName: string = '';

  private accountType: string = '';

  private calendarDisplayName: string = '';

  private calendarColor: number = -1;

  @State private visible: number = -1;

  private isSelect: boolean = true;

  private canReminder: number = 1;

  private creator: string = '';

  private showFloatButton: boolean = DeviceConfig.instance().config.showFloatButton;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  @StorageProp(GlobalDataKeys.SIDEBAR_WIDTH) sidebarWidth: number = DeviceConfig.instance().config.deviceLayout.sidebarWidth;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private uuid: string = '';

  private sheetIsClose: boolean = false;

  @State discardFlag: boolean = false;

  private nowSpringAction: SpringBackAction | undefined = undefined;

  private needTips: boolean = false;

  @State showPopup: boolean = false;

  private onDialogCancel: () => void = () => {
    if (this.nowSpringAction) {
      // 弹窗直接取消的情况下要回弹新建日程弹窗并将action设为空以防止出错
      this.nowSpringAction.springBack();
      this.nowSpringAction = undefined;
    }
  };

  private sheetOption: SheetOptions = {
    height: SheetSize.LARGE,
    detents: [SheetSize.LARGE, 0, 0],
    dragBar: false,
    showClose: false,
    preferType: SheetType.CENTER,
    backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
    onAppear: () => {
      this.isAccountAniShowFinish = true;
      Log.debug(TAG, 'AccountDetailPage BindSheet onAppear.');
    },
    onDisappear: () => {
      Log.debug(TAG, 'AccountDetailPage BindSheet onDisappear.');
    },
    onWillAppear: () => {
      this.sheetIsClose = false;
      Log.debug(TAG, 'AccountDetailPage BindSheet onWillAppear.');
    },
    shouldDismiss: (sheetDismiss: SheetDismiss) => {
      this.sheetDismissCheck(sheetDismiss);
    },
    onWillSpringBackWhenDismiss: ((springBackAction: SpringBackAction) => {
      this.nowSpringAction = springBackAction;
      // 没有注册springBackAction.springBack(), 下拉半模态页面无回弹行为
    }),
  };

  onLanguageChanges() {
    this.calculateShareTextWidth();
    this.calculateMainTextWidth();
  }

  onFontSizeChange() {
    this.calculateShareTextWidth();
    this.calculateMainTextWidth();
  }

  //计算宽度
  calculateShareTextWidth() {
    let shareText = measure.measureTextSize({
      textContent: this.shareText,
      fontSize: 10,
      fontWeight: FontWeight.Regular
    });
    const textWidth = shareText?.width ?? 0;
    this.shareTextWidth = px2vp(Number(textWidth)) + 12;
  }

  //计算是否需要显示tips
  calculateMainTextWidth() {
    const textWidth = this.sidebarWidth - ACCOUNT_NAME_WIDTH - this.shareTextWidth;

    const mainText = measure.measureTextSize({
      textContent: this.getFormatDisplayName(),
      fontSize: FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_SCALE_2X,
        16),
      fontWeight: FontWeight.Medium
    });
    const mainTextWidth = mainText?.width ?? 0;
    this.needTips = px2vp(Number(mainTextWidth)) > textWidth;
  }

  /**
   * 更新帐户显隐
   */
  async updateAccountVisible(visible: boolean) {
    let accountUpdate: ValuesBucket = {};
    accountUpdate[CalendarContract.AccountColumns.VISIBLE] = visible;
    let updateSum: number = await CalendarService.INSTANCE.updateCalendarById(this.accountId, accountUpdate) as number;
    if (updateSum > 0) {
      Log.info(TAG, 'Update a new account succeed, sum = ' + updateSum);
    }
  }

  aboutToAppear(): void {
    this.isSelect = this.visible === 1;
    this.accountDetailShowHandler = (data: emitter.EventData): void => this.accountDetailShow(data);
    emitter.on({ eventId: CommonInnerEvent.EVENT_ACCOUNT_DETAIL_PAGE_OPEN }, this.accountDetailShowHandler);
    this.calculateShareTextWidth();
    this.calculateMainTextWidth();
    Log.info(TAG, `account name:${maskString(this.calendarDisplayName)} uuid:${maskString(this.uuid)}, ` +
      `account creator:${maskString(this.creator)}`);
  }

  aboutToDisappear(): void {
    emitter.off(CommonInnerEvent.EVENT_ACCOUNT_DETAIL_PAGE_OPEN, this.accountDetailShowHandler);
    this.shareSwitchDialogController = null;
  }

  @Builder
  buildAccountDetailPage(params: AccountItemData) {
    Column() {
      AccountDetail({
        isShowAccountDetailPage: $isShowAccountDetailPage,
        editMode: params.editMode,
        creator: params.creator,
        accountId: params.id,
        accountName: params.accountName,
        accountType: params.accountType,
        calendarDisplayName: params.calendarDisplayName,
        calendarColor: params.calendarColor,
        reminderState: params.canReminder,
        uuid: params.uuid,
        discardFlag: this.discardFlag,
        onDialogCancel: this.onDialogCancel,
      })
    }
    .height('100%')
  }

  //账户勾选
  @Builder
  buildSidebarSelect() {
    Checkbox()
      .select(this.isSelect)
      .selectedColor(this.calendarColor)
      .unselectedColor(this.calendarColor)
      .width(22)
      .height(22)
      .shape(CheckBoxShape.CIRCLE)
      .id(`${CompId.SELECT_ACCOUNT}-${this.accountId}`)
      .hoverEffect(HoverEffect.None)
      .onChange((value: boolean) => {
        Log.info(TAG, `buildSidebarSelect Checkbox value:${value}`);
        this.visible = (value ? 1 : 0);
        const phoneAccount: string[] = [
          CalendarAccountType.LOCAL_ACCOUNT_TYPE,
          CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE,
          CalendarAccountType.CUSTOM_ACCOUNT_TYPE
        ];
        let params: ReportHiEventParams = {
          IS_ON: this.visible,
          ACCOUNT_TYPE: Number(phoneAccount.includes(this.accountType))
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.editAccountSwitch, params);
        this.updateAccountVisible(value);

        // 无障碍播报专用
        SafeUtil.setTimeout(() => {
          sendAccessibilityEvent(`${CompId.SELECT_ACCOUNT}-${this.accountId}`);
          // 时延太短会不生效
        }, SafeUtil.TIMER);
      })
      .accessibilityLevel('yes')
      .margin({ end: LengthMetrics.vp(8), start: LengthMetrics.vp(8) })
      .hitTestBehavior(HitTestMode.Block)
      .focusable(false)
      .accessibilityText(this.getAccountNameStr())
  }

  getAccountNameStr() {
    let accountName = this.getFormatDisplayName();
    if (typeof accountName === 'string') {
      return accountName;
    }
    return GlobalThis.getResourceStr(accountName);
  }

  //账户名称
  @Builder
  buildAccountName() {
    Row() {
      Text(this.getFormatDisplayName())
        .fontSize(
          FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale,
            BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            16
          )
        )
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
  }

  //共享账户发送端
  @Builder
  builderShareAccountSend() {
    Row() {
      Text(this.getFormatDisplayName())
        .fontSize(
          FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale,
            BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            16
          )
        )
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SIX)
      Text(this.shareText)
        .fontSize(10)
        .maxLines(1)
        .fontColor('FFFFFF')
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .backgroundColor($r('sys.color.interactive_click'))
        .textAlign(TextAlign.Center)
        .margin({ left: 4 })
        .padding({left: 4, right: 4, top: 2, bottom: 2 })
        .borderRadius(4)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
    }.padding({ end: LengthMetrics.vp(this.shareTextWidth) })
    .layoutWeight(1)
  }

  //右箭头
  @Builder
  builderRightArrow() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
        24
      ))
      .visibility((this.showFloatButton || this.isHoverShow) ? Visibility.Visible : Visibility.Hidden)
      .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  @Builder
  existMenu() {
    AccountMenu({
      menuOpts: this.accountMenuCheck(this.accountId, this.accountType),
      onViewHandle: () => {
        this.onAccountItemClick();
      },
      onDeleteHandle: () => {
        this.deleteAccountHandler(this.accountId, this.uuid);
      }
    })
  }

  build() {
    Row() {
      this.buildSidebarSelect();
      this.buildAccountName();
      this.builderRightArrow();
    }
    .accessibilityGroup(true)
    .accessibilityText(barText(this.getFormatDisplayName()))
    .accessibilityRole(5)
    .constraintSize({ minHeight: this.needCommerce ? 40 : 48 })
    .padding({ end: LengthMetrics.vp(8) })
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.ohos_fa_click_effect'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .bindContextMenu(this.existMenu(), ResponseType.RightClick)
    .bindSheet($$this.isShowAccountDetailPage, this.buildAccountDetailPage(this.parseAccountParams()), this.sheetOption)
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level8'))
    .onClick((event => {
      this.onAccountItemClick();
    }))
    .bindPopup(this.needTips && this.isHoverShow, {
      builder: this.PopupComp(this.getFormatDisplayName()),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: false,
    })
    .hoverEffect(HoverEffect.Highlight)
    .onHover((isHover) => {
      this.onRowHover(isHover)
    })
    .id(CompId.CLICK_ON_ACCOUNTS)
    .focusBox({ margin: LengthMetrics.vp(-2) })
  }

  accountMenuCheck(accountId: number, accountType: string): AccountMenuOpt[] {
    const account: CalendarContract.Accounts = new CalendarContract.Accounts();
    account.accountType = accountType;
    account.creator = this.creator;
    account.id = accountId

    if (AccountUtils.isBirthDayAccount(account)) { // 生日日程不允许删除
      return DEFAULT_ACCOUNT_OPT;
    }
    if (AccountUtils.isDefaultAccount(account)) { // 默认日程不允许删除
      return DEFAULT_ACCOUNT_OPT;
    }

    return NORMAL_ACCOUNT_OPT;
  }

  onAccountItemClick() {
    this.isShowAccountDetailPage = true;
    this.reportClickAccount();
  }

  sheetDismissCheck(sheetDismiss: SheetDismiss) {
    Log.info(TAG, `AccountDetailPage BindSheet shouldDismiss ${this.sheetIsClose}`);
    // 临时方案,添加标志位用于防止半模态点击蒙层退出触发两次动效导致异常
    if (this.sheetIsClose) {
      return;
    }
    this.discardFlag = !this.discardFlag;
  }

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
    if (AccountUtils.isBirthDayAccount(account)) {
      return $r('app.string.contact_birthday');
    }
    if (AccountUtils.isHolidayAccount(account)) {
      return getContext().resourceManager.getStringSync($r('app.string.country_holiday'),
        HolidayUtil.getDisplayCountry(this.accountName));
    }
    return this.calendarDisplayName;
  }

  private accountDetailShowHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  /**
   * 用于转化对应的账户参数组
   *
   * @returns 账户参数
   */
  private parseAccountParams(): AccountItemData {
    const params: AccountItemData = new AccountItemData();
    params.creator = this.creator;
    params.editMode = true;
    params.id = this.accountId;
    params.accountName = this.accountName;
    params.accountType = this.accountType;
    params.calendarDisplayName = this.calendarDisplayName;
    params.calendarColor = this.calendarColor;
    params.canReminder = this.canReminder;
    params.uuid = this.uuid;
    return params;
  }

  /**
   * 用于点击账户动作后报点
   *
   * @returns 账户参数
   */
  private reportClickAccount() {
    if (this.accountType === 'local') {
      let param: ReportHiEventParams = {
        ACCOUNT_TYPE: 0
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.accountGoToMyCalendar, param);
    } else {
      let param: ReportHiEventParams = {
        ACCOUNT_TYPE: 1
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.accountGoToMyCalendar, param);
    }
  }

  /**
   * 用于悬浮帐户效果
   *
   * @params 是否悬浮
   */
  private onRowHover(isHover: boolean): void {
    this.isHoverShow = isHover;
  }

  private accountDetailShow(data: emitter.EventData) {
    if (!data.data) {
      return;
    }
    const calendarUuid = data.data.calendarUuid as string;
    if (calendarUuid !== this.uuid) {
      return;
    }
    this.isShowAccountDetailPage = true;
  }
}
