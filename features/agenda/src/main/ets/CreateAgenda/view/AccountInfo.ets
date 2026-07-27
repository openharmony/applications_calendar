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
  AccountKeys,
  AccountUtils,
  AgendaEventInfo,
  behaviorEvents,
  BigFontSize,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  CommonService,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  FontSizeScaleUtils,
  GlobalThis,
  Log,
  PreferencesFiles,
  PreferencesUtil,
  ReportUtil,
  SourceTypeEnum
} from '@app/common';

import { HashMap } from '@kit.ArkTS';

import {
  ACCOUNT_CIRCLE_LEFT_MARGIN,
  ACCOUNT_CIRCLE_WIDTH,
  DEFAULT_NUM,
  DEFAULT_STR,
  MORE_IMAGE_WIDTH
} from '../Constants';

import measure from '@ohos.measure';
import { AccountDialog } from './AccountDialog';
import { LengthMetrics } from '@kit.ArkUI';
import { AccountMenu } from './AccoutMenu';

const TAG: string = 'AccountInfo';

/**
 * 帐户信息
 */
@Component
export struct AccountInfo {
  // 帐户颜色
  @State accountColor: number = DEFAULT_NUM;

  // 帐户展示名
  @State accountDisName: ResourceStr = DEFAULT_STR;

  @State @Watch('onRowWidthChanged') rowWidth: number = 0;

  @State rowLinesBeyondOne: boolean = false;

  @State bSizeConfirmed: boolean = false;

  @State marginTop: number = 0;

  // 日程信息
  @Link eventInfo: AgendaEventInfo;

  // 选中的帐户 id 值
  @Link @Watch('onCheckedAccountChange') checkedAccId: number;

  // 用户进页面时默认的帐户 id 值
  @Link oldCheckedAccId: number;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否编辑态
  private isEditMode: boolean = false;

  //账户是否可编辑
  private isAccountEdit: boolean = true;

  // 所有帐户列表
  private accountList: CalendarContract.Accounts[] = [];

  // 帐户 MAP 映射：帐户ID ——> 帐户信息
  private accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap<number, CalendarContract.Accounts>();

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 帐户弹框控制器
  private dialogController: CustomDialogController | null = new CustomDialogController({
    builder: AccountDialog({
      checkedAccId: $checkedAccId,
      accountList: this.accountList,
      changeCheckedAccValue: ($checkedAccId: number): Promise<void> => this.changeCheckedAccValue($checkedAccId)
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
    customStyle: this.dialogControllerOptions.customStyle
  });

  aboutToAppear() {
    this.getShowAccount();
  }

  aboutToDisappear(): void {
    this.dialogController = null;
  }

  onRowWidthChanged() {
    this.bSizeConfirmed = false;
    const accountName: ResourceStr = this.accountDisName;

    let accountNameStr: string = '';
    if (typeof accountName === 'string') {
      accountNameStr = String(accountName);
    } else {
      accountNameStr = GlobalThis.getResourceStr(accountName);
    }

    const renderTextWidthPx: number = measure.measureText(
      { textContent: accountNameStr, fontSize: 14, fontWeight: FontWeight.Regular }
    );
    const renderTextWidth = px2vp(renderTextWidthPx);
    const calculatedTextWidth: number = this.isEditMode
      ? this.rowWidth - ACCOUNT_CIRCLE_WIDTH - ACCOUNT_CIRCLE_LEFT_MARGIN
      : this.rowWidth - ACCOUNT_CIRCLE_WIDTH - ACCOUNT_CIRCLE_LEFT_MARGIN - MORE_IMAGE_WIDTH;
    this.rowLinesBeyondOne = renderTextWidth > calculatedTextWidth ? true : false;
    Log.debug(TAG,
      `onRowWidthChanged, rowWidth = ${this.rowWidth}, lines of row beyonds one = ${this.rowLinesBeyondOne}`);
    this.bSizeConfirmed = true;
  }

  /**
   * 修改选中的帐户 ID
   * @param checkedAccId 选中的 ID 值
   */
  async changeCheckedAccValue(checkedAccId: number) {
    Log.info(TAG, `Choose Calendar, id = ${checkedAccId}`)
    ReportUtil.reportBehaviorEvent(behaviorEvents.createAgendaSelectAccount);
    const checkAccStringId: string = checkedAccId.toString(); // 当前无法通过number类型存储preferences
    PreferencesUtil.putStringValue(
      PreferencesFiles.ACCOUNT, AccountKeys.DEFAULT_SELECT_ACCOUNT, checkAccStringId);
    this.checkedAccId = checkedAccId;
    this.eventInfo.mCalendarId = checkedAccId;
  }

  /**
   * 获取需要展示的帐户信息
   */
  async getShowAccount() {
    let accountList: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList();
    let sortAccountList = AccountUtils.sortAccountListInAccPopup(accountList);
    //添加账户编辑过滤逻辑
    this.accountList = this.filterAccountList(sortAccountList);

    this.accountMap = CommonService.INSTANCE.getAccountMap(this.accountList);
    if (!this.isEditMode) {
      // 从缓存中读取创建日程使用的账户
      const storeId: number =
        PreferencesUtil.getNumberValueSync(PreferencesFiles.ACCOUNT, AccountKeys.DEFAULT_SELECT_ACCOUNT, DEFAULT_NUM);
      this.checkedAccId = this.accountMap.get(storeId) ? storeId : 1
      this.oldCheckedAccId = this.checkedAccId
    } else {
      this.checkedAccId = this.eventInfo.mCalendarId;
      this.oldCheckedAccId = this.checkedAccId
    }
    const account: CalendarContract.Accounts = this.accountMap.get(this.checkedAccId);
    this.accountColor = account.calendarColor;
    this.accountDisName = AccountUtils.getAccountResourceStr(account);
  }

  filterAccountList(accountList: CalendarContract.Accounts[]): CalendarContract.Accounts[] {
    let showAccountList: CalendarContract.Accounts[] = [];

    //个人账户
    const keys: string[] = [
      CalendarAccountType.LOCAL_ACCOUNT_TYPE,
      CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE,
      CalendarAccountType.CUSTOM_ACCOUNT_TYPE
    ];
    accountList.forEach((value, index) => {
      this.filtSigAccount(keys, value, showAccountList);
    });

    return showAccountList;
  }

  /**
   * 选中的帐户改变回调
   */
  onCheckedAccountChange() {
    if (this.accountMap.length > 0) {
      const account: CalendarContract.Accounts = this.accountMap.get(this.checkedAccId);
      this.accountColor = account.calendarColor;
      this.accountDisName = AccountUtils.getAccountResourceStr(account);
      this.eventInfo.mCalendarUuid = account.uuid;
      if (this.rowWidth !== 0) {
        this.onRowWidthChanged();
      }
    }
  }

  @Builder
  BuildAccountLabel() {
    Row() {
      Row() {
        Circle()
          .height(4)
          .width(4)
          .strokeWidth(4)
          .stroke(this.accountColor)
          .id(CompId.ADD_AGENDA_SELECTED_ACCOUNT_CIRCLE)
          .margin({
            end: LengthMetrics.vp(8),
            start: this.isChangeLayout() ? LengthMetrics.vp(8) : LengthMetrics.vp(0)
          })

        Text(this.accountDisName)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(0.6)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(this.rowLinesBeyondOne ? 1 : 0)
          .visibility(this.bSizeConfirmed ? Visibility.Visible : Visibility.Hidden)
          .margin({ end: LengthMetrics.vp(this.isEditMode ? 12 : 0) })
          .id(CompId.ADD_AGENDA_SELECTED_ACCOUNT_TEXT)
      }
      .layoutWeight(1)
      .justifyContent(this.isChangeLayout() ? FlexAlign.Start : FlexAlign.End)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
        .visibility(this.isEditMode ? Visibility.None : Visibility.Visible)
        .align(Alignment.Center)
    }
    .layoutWeight(this.isChangeLayout() ? 0 : 1)
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.End)
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
      if (ov.width === nv.width) {
        return;
      }
      this.rowWidth = nv.width as number;
    })
  }

  @Builder
  BuildCalendarText() {
    Text($r('app.string.calendar'))
      .fontColor($r('sys.color.font_primary'))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .margin({ end: LengthMetrics.vp(8) })
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  AccountInfoVerticalLayout() {
    Column() {
      this.BuildCalendarText();

      this.BuildAccountLabel();
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      left: 12,
      right: 0,
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)
    })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(this.isEditMode ? HoverEffect.None : HoverEffect.Highlight)
    .bindMenu(this.isAccountEdit ? this.buildAccountMenu() : undefined, {
      placement: Placement.TopRight
    })
    .id(CompId.ADD_AGENDA_SELECT_ACCOUNT)
    .constraintSize({ minHeight: 56 })
    .visibility(this.accountColor !== -1 && this.accountDisName !== '' && this.isChangeLayout()
      ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildAccountMenu() {
    AccountMenu({
      accountList: this.accountList,
      checkValue: this.checkedAccId,
      defaultSelect: this.oldCheckedAccId,
      onChange: this.changeCheckedAccValue,
    }).width(224)
  }

  build() {
    Row() {
      this.AccountInfoVerticalLayout();

      Row() {
        this.BuildCalendarText();

        this.BuildAccountLabel();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({
        start: LengthMetrics.vp(8),
        end: LengthMetrics.vp(0),
        top: 4,
        bottom: 4
      })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .hoverEffect(this.isEditMode ? HoverEffect.None : HoverEffect.Highlight)
      .bindMenu(this.isAccountEdit ? this.buildAccountMenu() : undefined, {
        placement: Placement.BottomRight
      })
      .id(CompId.ADD_AGENDA_SELECT_ACCOUNT)
      .constraintSize({ minHeight: 56 })
      .visibility(this.accountColor !== -1 && this.accountDisName !== '' && !this.isChangeLayout()
        ? Visibility.Visible : Visibility.None)
    }
    .id(CompId.ACCOUNT_INFO)
    .constraintSize({ minHeight: 56 })
    .padding({
      left: 4,
      right: 4,
      top: 4,
      bottom: 4
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
    .margin({ top: this.marginTop })
  }

  /**
   * 对进行单个账户过滤
   * @param keys 个人账户类型
   * @param value 账户类型
   * @param showAccountList 需要展示的账户列表
   */
  private filtSigAccount(
    keys: string[],
    value: CalendarContract.Accounts,
    showAccountList: CalendarContract.Accounts[]
  ) {
    if (keys.indexOf(value.accountType) !== -1) {
      showAccountList.push(value);
    } else if (this.eventInfo.mCalendarId === value.id) {
      //三方账户不可修改
      this.isAccountEdit = false;
    }
  }
}