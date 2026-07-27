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
  AccountColor,
  AccountItemData,
  AccountUtils,
  behaviorEvents,
  BigFontSize,
  CalendarAccessLevel,
  CalendarAccountName,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  EmptyUtils,
  FeatureType,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  HolidayUtil,
  I18nUtil,
  Log,
  NavPathManager,
  NavPathName,
  PreferencesFiles,
  PreferencesUtil,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  SettingPreferencesKeys,
  SourceTypeEnum,
  statisticEvents,
  ThrottleFunction
} from '@app/common';
import { CommonTextDialog, SubTitle } from '@app/common.components';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import emitter from '@ohos.events.emitter';
import { addSwitchText, broadcastSwitchStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { addSelectStatusAndButton, broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'AccountDetailContent';
const DEFAULT_NUM: number = -1;
const DEFAULT_STR: string = '';

export class myAccountNameClass {
  CH: string = '';
  EN: string = '';
}

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

let storage = new LocalStorage();

/**
 * 帐户详情界面——账户信息展示内容
 */
@Component
export struct AccountDetailContent {
  @Consume navPathStack: NavPathStack;

  @Prop shareType: number;

  @Link isShowAccountDetailPage: boolean;

  // 新建及账户详情页动画完成,开始弹popup
  @Consume isAccountAniShowFinish: boolean;

  @State initiatorAccountShareListPopup: boolean = false;

  // 是否是编辑态
  @Prop editMode: boolean = false;

  // 帐户ID
  @Prop accountId: number = DEFAULT_NUM;

  // 帐户uuid
  @Prop accountUuid: string = '';

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('bgColor') bgColor: string = '';

  @State @Watch('viewDataChange') calendarDisplayName: string = DEFAULT_STR;

  @State @Watch('viewDataChange') calendarColor: number = DEFAULT_NUM;

  @State isArrowDown: boolean = true;

  @State showBottomDeleteItem: boolean = false;

  @State @Watch('viewDataChange') reminderState: number = 1;

  @Link confirmStatus: boolean;

  @Link @Watch('onConfirmButtonSucceed') confirmButtonSucceed: boolean;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp('language') @Watch('onLanguageChange') language: string = 'zh';

  // 目前接受到的共享账户不允许更改
  @Prop isAcceptAccount: boolean;

  private firstEnter: boolean = true;

  /**
   * 默认帐户信息。用户输入帐户名为 “” 时，需要保存默认账户信息到数据库
   * 使用默认账户的资源的string值作为数据的话，系统语言切换后，默认账户信息不会切换语言，目前使用语言常量值来规避
   */
  private myAccountName: myAccountNameClass = {
    CH: '我的日历',
    EN: 'My Calendar'
  }

  // 帐户类型
  private accountType: string = DEFAULT_STR;

  // 帐户名
  private accountName: string = DEFAULT_STR;

  // 账户创建者
  private creator: string = DEFAULT_STR;

  // Radio 组名
  private radioGroup: string = 'RadioGroup';

  // 初始的帐户显示的名字
  @State initCalendarDisplayName: ResourceStr = DEFAULT_STR;

  // 初始的帐户颜色
  private initCalendarColor: number = DEFAULT_NUM;

  // 滑动 scroller
  private scroller: Scroller = new Scroller();

  // 账户可以选择的所有颜色
  private allAccountColor: number[] = [
    AccountColor.RED,
    AccountColor.DARK_ORANGE,
    AccountColor.LIGHT_ORANGE,
    AccountColor.GREEN,
    AccountColor.TURQUOISE,
    AccountColor.PURPLE,
    AccountColor.BLUE
  ];

  // 帐户输入栏默认填充信息
  private accNamePlaceholder: ResourceStr = $r('app.string.please_input_account_name');

  // 帐户栏初始显示信息
  private accNamePlaceText: ResourceStr = DEFAULT_STR;

  private radioPreName: string = 'colorRadio';

  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 300;

  private isAccountPage: boolean = true;

  /**
   * 如果是新建,为空对象,如果是编辑,存储原始的账户信息
   */
  private originalAccount: AccountItemData = new AccountItemData(); // EMPTY_ACCOUNT

  // 是否需要默认获焦拉起键盘
  private needKeyBoardFocus: boolean = DeviceConfig.instance().config.needKeyBoardFocus;

  private cardBorderRadiusOnPC: boolean = DeviceConfig.instance().config.cardBorderRadiusOnPC;

  @State private isToggleOn: boolean = true;

  async aboutToAppear() {
    if (!this.editMode) {
      this.accNamePlaceText = DEFAULT_STR;
      this.calendarDisplayName = DEFAULT_STR;
      this.initCalendarDisplayName = DEFAULT_STR;
      this.initCalendarColor = AccountColor.RED;
      this.calendarColor = AccountColor.RED;
      return;
    }
    this.initOrUpdateAccountDisplayName();
    this.calendarColor = AccountUtils.getAdaptedAccountColorValue(this.calendarColor);
    this.initCalendarColor = this.calendarColor;
    if (AccountUtils.isNotInCalendarColors(this.initCalendarColor)) {
      this.allAccountColor.push(this.initCalendarColor);
    }
    this.originalAccount = new AccountItemData();
    this.originalAccount.calendarDisplayName = this.initCalendarDisplayName as string;
    this.originalAccount.calendarColor = this.calendarColor;
    this.originalAccount.canReminder = this.reminderState;
  }

  initOrUpdateAccountDisplayName() {
    const account: CalendarContract.Accounts = new CalendarContract.Accounts();
    account.accountType = this.accountType;
    account.creator = this.creator;
    if (AccountUtils.isDefaultAccount(account)) {
      this.accNamePlaceText = GlobalThis.getResourceStr($r('app.string.my_calendar'));
      this.initCalendarDisplayName = GlobalThis.getResourceStr($r('app.string.my_calendar'));
      this.originalAccount.calendarDisplayName = this.initCalendarDisplayName;
    } else if (AccountUtils.isBirthDayAccount(account)) {
      this.accNamePlaceText = $r('app.string.contact_birthday');
      this.initCalendarDisplayName = getContext().resourceManager.getStringSync($r('app.string.contact_birthday'));
    } else if (AccountUtils.isHolidayAccount(account)) {
      const holidayCalendarDisplayName: ResourceStr = getContext().resourceManager.getStringSync($r('app.string.country_holiday'),
        HolidayUtil.getDisplayCountry(this.accountName));
      this.accNamePlaceText = holidayCalendarDisplayName;
      this.initCalendarDisplayName = holidayCalendarDisplayName;
    } else {
      this.accNamePlaceText = this.calendarDisplayName;
      this.initCalendarDisplayName = this.calendarDisplayName;
    }
  }

  onLanguageChange() {
    this.initOrUpdateAccountDisplayName();
  }

  @Styles
  itemBackgroundColor(){
    .backgroundColor(Color.Transparent)
  }

  @Styles
  containerBackgroundColor(){
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  aboutToDisappear() {
  }

  /**
   * 帐户视图有数据变化
   */
  viewDataChange() {
    if (EmptyUtils.isEmptyString(this.calendarDisplayName, true)) {
      this.confirmStatus = false;
      return;
    }
    const temConfirmStatus: boolean =
      (!AccountUtils.checkIsSameColor(this.originalAccount.calendarColor, this.calendarColor)) ||
        (this.originalAccount.canReminder !== this.reminderState) ||
        (this.originalAccount.calendarDisplayName !== this.calendarDisplayName);
    Log.info(TAG, 'viewDataChange pre ConfirmStatus is ' +
    this.confirmStatus.valueOf() + ' current ConfirmStatus is ' + temConfirmStatus);
    this.confirmStatus = temConfirmStatus;
  }

  /**
   * 帐户数据需要更新到数据库的回调
   */
  onConfirmButtonSucceed() {
    if (this.confirmButtonSucceed) {
      let params: ReportHiEventParams = {
        COLOR: this.calendarColor
      }
      if (this.editMode) {
        this.updateAccount();
        ReportUtil.reportStatisticEvent(statisticEvents.editAccount, params);
      } else {
        this.createNewAccount();
        ReportUtil.reportStatisticEvent(statisticEvents.createAccount, params);
      }
    }
  }

  /**
   * 新建帐户
   */
  async createNewAccount() {
    const accountCreated: ValuesBucket = {};
    accountCreated[CalendarContract.SyncColumns.ACCOUNT_NAME] =
      CalendarAccountName.CUSTOM_ACCOUNT_NAME_PRE + new Date().getTime().toString();
    accountCreated[CalendarContract.SyncColumns.ACCOUNT_TYPE] =
      CalendarAccountType.CUSTOM_ACCOUNT_TYPE;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME] =
      this.calendarDisplayName.length > 0 ? this.calendarDisplayName : '';
    accountCreated[CalendarContract.AccountColumns.CALENDAR_COLOR] = this.calendarColor;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL] = CalendarAccessLevel.CAL_ACCESS_OWNER;
    accountCreated[CalendarContract.AccountColumns.VISIBLE] = 1;
    accountCreated[CalendarContract.AccountColumns.CAN_REMINDER] = this.reminderState;
    let params: ReportHiEventParams = {
      IS_ON: this.reminderState
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.createAccountClickNotice, params);
    const accountId: number = await CalendarService.INSTANCE.insertCalendar(accountCreated) as number;
    if (accountId > 0) {
      Log.info(TAG, 'Add a new account succeed');
      // 退出半模态
      this.isShowAccountDetailPage = false;
    }
  }

  /**
   * 更新帐户
   */
  async updateAccount() {
    const accountUpdate: ValuesBucket = {};
    if (((this.editMode) && this.accountType === (CalendarAccountType.CUSTOM_ACCOUNT_TYPE)) || (!this.editMode)) {
      accountUpdate[CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME] =
        this.calendarDisplayName.length > 0 ? this.calendarDisplayName : '';
    }
    accountUpdate[CalendarContract.AccountColumns.CALENDAR_COLOR] = this.calendarColor;
    if (this.originalAccount.canReminder !== this.reminderState) {
      accountUpdate[CalendarContract.AccountColumns.CAN_REMINDER] = this.reminderState;
    }
    let updateSum: number = await CalendarService.INSTANCE.updateCalendarById(this.accountId, accountUpdate) as number;
    if (updateSum > 0) {
      Log.info(TAG, 'Update a new account succeed, sum = ' + updateSum);

      // 退出半模态
      this.isShowAccountDetailPage = false;
    } else {
      Log.info(TAG, 'Update a new account failed');
    }
  }

  getDefaultAccountName() {
    const isChineseLanguage: boolean = I18nUtil.isSystemChineseLanguage();
    return isChineseLanguage ? this.myAccountName.CH : this.myAccountName.EN;
  }

  onChangePadding(needStateStylesPadding: boolean = false): number {
    if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_3X) {
      return 24;
    }
    if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_2X) {
      return 20;
    }
    if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE) {
      return 16;
    }
    return needStateStylesPadding ? 4 : 0;
  }

  needFocus(): boolean {
    return this.needKeyBoardFocus || !this.editMode;
  }

  @Builder
  NameBuilder() {
    Row() {
      Column() {
        TextInput({ placeholder: this.accNamePlaceholder, text: this.accNamePlaceText })
          .placeholderColor($r('sys.color.font_secondary'))
          .caretColor(this.themeColor)
          .selectedBackgroundColor(this.themeColor)
          .placeholderFont({
            size: FontSizeScaleUtils.getLimitFontSizeVp(
              GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
              16), weight: FontWeight.Medium
          })
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            16
          ))
          .fontWeight(FontWeight.Medium)
          .constraintSize({ minHeight: 48 })// 拉高文本框
          .maxLines(2)
          .itemBackgroundColor()
          .maxLength(64)
          .enableKeyboardOnFocus(this.needFocus())
          .defaultFocus(this.needFocus())
          .padding({
            left: 8,
            right: 8,
            top: 2,
            bottom: 2
          })
          .enabled(((this.editMode &&
              this.accountType === CalendarAccountType.CUSTOM_ACCOUNT_TYPE) ||
            (!this.editMode)) && !this.isAcceptAccount)
          .onChange((value: string) => {
            this.calendarDisplayName = value;
            this.accNamePlaceText = value;
          })
          .id(CompId.ACCOUNT_NAME)
      }
    }
    .padding({
      left: 4,
      right: 4,
      top: this.onChangePadding(),
      bottom: this.onChangePadding()
    })
    .containerBackgroundColor()
    .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
  }

  //颜色选择
  @Builder
  buildColorRadio() {
    Row() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center
      }) {
        ForEach(this.allAccountColor, (item: number, index) => {
          RadioButton({
            radioColor: item,
            editMode: this.editMode,
            calendarColor: $calendarColor
          })
        })
      }
    }
    .height(48)
    .padding({ left: 8, right: 8 })
    .width('100%')
    .visibility(this.isArrowDown ? Visibility.None : Visibility.Visible)
  }

  /**
   * 颜色选择器组件
   */
  @Builder
  ColorBuilder() {
    Column() {
      Row() {
        Row() {
          Circle()
            .width(16)
            .height(16)
            .fill(this.calendarColor)
          Text(AccountUtils.getAccountColorName(this.calendarColor))
            .fontColor($r('sys.color.font_primary'))
            .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
              GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
              16
            ))
            .fontWeight(FontWeight.Medium)
            .margin({ start: LengthMetrics.vp(8) })
        }

        Blank()

        SymbolGlyph(this.isArrowDown ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
      }
      .padding({ left: 8, right: 8 })
      .constraintSize({ minHeight: 48 })
      .width('100%')
      .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .onClick(() => {
        this.isArrowDown = !this.isArrowDown;
      })
      .id(CompId.EXPAND_AND_COLLAPSE_COLOR)
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor(Color.Transparent)
        }
      })

      this.buildColorRadio()
    }
    .padding({
      left: 4,
      right: 4,
      top: this.onChangePadding(true),
      bottom: this.onChangePadding(true)
    })
    .containerBackgroundColor()
    .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
  }

  //  通知
  @Builder
  InformBuilder() {
    Row() {
      Column() {
        Text($r('app.string.schedule_reminder'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('sys.color.comp_background_list_card'))
      }
      .flexShrink(1)
      .padding({
        left: 4,
        right: 4,
        top: 8,
        bottom: 8
      })

      Row() {
        Toggle({ type: ToggleType.Switch, isOn: this.reminderState === 1 })
          .selectedColor(this.themeColor)
          .switchPointColor($r('sys.color.comp_background_primary_contrary'))
          .onChange((isOn: boolean) => {
            Log.info(TAG, 'reminder Toggle status:' + isOn);
            this.reminderState = isOn ? 1 : 0;
          })
      }
      .flexShrink(0)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .constraintSize({
      minHeight: 48
    })
    .height(56)
    .containerBackgroundColor()
    .borderRadius(16)
    .padding({
      top: 8,
      bottom: 8,
      left: 8,
      right: 8
    })
  }

  build() {
    Row() {
      Scroll(this.scroller) {
        Column() {
          SubTitle({ title: $r('app.string.custom_account_name_title'), compId: CompId.NAME })
          this.NameBuilder()

          SubTitle({ title: $r('app.string.selected_color_cvaa'), compId: CompId.COLOR })
          this.ColorBuilder()

          if (this.editMode) {
            SubTitle({ title: $r('app.string.view_schedule') })
            this.buildViewAllAgendasButton()
          }
        }
        .padding({ top: 0, bottom: 8 })
        .constraintSize({ minHeight: '100%' })
        .width('100%')
        .padding({ start: LengthMetrics.vp(16) })
        .backgroundColor(Color.Transparent)
      }
      .width('calc(100% - 16vp)')
      .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level8')
        : $r('sys.float.corner_radius_level10'))
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .width(16)
        .margin({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildViewAllAgendasButton() {
    Column() {
      Row() {
        Text($r('app.string.show_all_agenda'))
          .align(Alignment.Start)
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            16
          ))
          .width('90%')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: 4 })
      }
      .width('100%')
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .hoverEffect(HoverEffect.Highlight)
      .constraintSize({ minHeight: 48 })
      .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .onClick(() => {
        ThrottleFunction.instance().throttle(TAG, (): void => {
          const params: Record<string, number | boolean | ResourceStr> = {};
          params['calendarUuid'] = this.accountUuid;
          params['calendarName'] = this.initCalendarDisplayName;
          params['accountType'] = this.accountType;
          NavPathManager.getInstance().pushPath({
            builderName: NavPathName.AGENDA_LIST,
            routerName: RouterName.ENTRY_HAP,
            param: params
          });
          this.isShowAccountDetailPage = false;
        }, this.DELAY);
        ReportUtil.reportBehaviorEvent(behaviorEvents.checkAccountAgendas);
      })
      .padding({ left: 8, right: 8 })
    }
    .padding({
      left: 4,
      right: 4,
      top: this.onChangePadding(true),
      bottom: this.onChangePadding(true)
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.cardBorderRadiusOnPC ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
  }
}

/**
 * 颜色选中框子组件
 */
@Component
struct RadioButton {
  @Prop editMode: boolean;

  @Link calendarColor: number;

  private radioColor: number = 0;

  build() {
    Circle()
      .height(20)
      .width(20)
      .fill(AccountUtils.checkIsSameColor(this.calendarColor, this.radioColor) ? $r('app.color.default_background') : this.radioColor)
      .stroke(this.radioColor)
      .strokeLineJoin(LineJoinStyle.Round)
      .strokeWidth(AccountUtils.checkIsSameColor(this.calendarColor, this.radioColor) ? 7 : 4)
      .responseRegion({ width: 28, height: 28 })
      .accessibilityText(addSelectStatusAndButton(GlobalThis.getResourceStr(
        AccountUtils.getAccountColorName(this.radioColor)),
        AccountUtils.checkIsSameColor(this.calendarColor, this.radioColor)))
      .onClick(() => {
        this.calendarColor = this.radioColor;
        let params: ReportHiEventParams = {
          COLOR: this.calendarColor
        }
        if (this.editMode) {
          ReportUtil.reportStatisticEvent(statisticEvents.editAccountClickColor, params);
        } else {
          ReportUtil.reportStatisticEvent(statisticEvents.createAccountClickColor, params);
        }
        broadcastSelectStatus(AccountUtils.checkIsSameColor(this.calendarColor, this.radioColor));
      })
      .id(CompId.SELECT_COLOR)
  }
}
