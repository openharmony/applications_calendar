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
  CalendarAccountType,
  CalendarService,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  EventService,
  GlobalThis,
  Log,
  ServiceManager,
  ServiceEnum,
  ShareRole,
  SourceTypeEnum,
  statisticEvents,
  ViewProxy,
  FontSizeScaleUtils,
  BigFontSize,
  PreferencesUtil,
  PreferencesFiles,
  AccountUtils,
  EmitterCollector,
  CHINA_COUNTRY_CODE,
  USER_CHINA_COUNTRY_DEFAULT,
  MIN_WINDOW_SHEET_BOTTOM,
  GlobalDataKeys,
} from '@app/common';
import { CommonTextDialog, ImageButton } from '@app/common.components';
import { AccountDetailContent } from './AccountDetailContent';
import emitter from '@ohos.events.emitter';
import {
  HiEventParamsConfirm,
  ReportHiEventParams,
  ReportUtil
} from '@app/common/src/main/ets/default/util/ReportUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { ExportVcsCallBack, ImportExportService, SimpleAccount } from '@app/feature.importexport';
// import lazy { harmonyShare } from '@kit.ShareKit'; // ShareKit 注释

const TAG: string = 'AccountDetail';
const DEFAULT_NUM: number = -1;
const DEFAULT_STR: string = '';
const ACCOUNT_TYPE_EMAIL: string = 'email';
const ACCOUNT_TYPE_LOCAL: string = 'local';

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 帐户详情组件
 */
@Component
export struct AccountDetail {
  @Link isShowAccountDetailPage: boolean;

  // 目前接受到的共享账户不允许删除
  @State isAcceptAccount: boolean = false;

  // 联系人生日账户不允许删除
  @State isBirthdayAccount: boolean = false;

  // 右上角勾选按钮的显隐状态
  @State confirmStatus: boolean = false;

  // 右上角勾选按钮的显隐状态
  @State confirmButtonSucceed: boolean = false;

  // 右上角的删除图标是否显示
  @State showUpperRightDelete: boolean = true;

  // 右上角的分享图标是否显示
  @State showUpperRightShare: boolean = true;

  // 最下方的删除图标是否显示
  @State showBottomDelete: boolean = true;

  // 最下方的分享图标是否显示
  @State showBottomShare: boolean = true;

  // 账户删除样式hover颜色
  @State deleteHoverColor: Resource = $r('app.color.default_background');

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //image fillColor
  @State imgFillColor: string = '#000000';

  @State isNotExit: boolean = true;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 滑动 scroller
  private scroller: Scroller = new Scroller();

  // 子页面滑动 scroller
  private detailScroller: Scroller = new Scroller();

  // 是否是编辑页面
  private editMode: boolean = false;

  // 帐户ID
  private accountId: number = DEFAULT_NUM;

  // 账户创建者
  private creator: string = DEFAULT_STR;

  // 帐户名
  private accountName: string = DEFAULT_STR;

  // 帐户类型
  private accountType: string = DEFAULT_STR;

  // 帐户显示名
  private calendarDisplayName: string = DEFAULT_STR;

  // 帐户颜色
  private calendarColor: number = DEFAULT_NUM;

  // 是否能通知
  private reminderState: number = 1;

  // uuid
  private uuid: string = '';

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private shareAnchorViewId: string = '';

  @State dummyFlag: boolean = false;

  //svg模糊度
  private needShowUpperRightButton: boolean = DeviceConfig.instance().config.needShowUpperRightButton;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  @Prop @Watch('showDiscardDialog') discardFlag: boolean;

  @StorageProp('themeColor') themeColor: string = '';

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowAccountDetailPage = false;
    this.deleteDialogController?.close();
  };

  private closePageAndDialog: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowAccountDetailPage = false;
    this.deleteDialogController?.close();
  };

  private onDialogCancel: () => void = () => {
  };

  /**
   * 左上角返回弹窗
   */
  private discardDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.eu3_calendar_title_issaveevent'),
      cancelText: $r('app.string.discard_dialog_button'),
      confirmText: $r('app.string.save_dialog_button'),
      isFocusLeftButton: true,
      onCancelClick: (() => {
        this.isShowAccountDetailPage = false;
        this.reportPopupStatistic(HiEventParamsConfirm.FALSE)
      }),
      onConfirmClick: (() => {
        this.confirmButtonSucceed = true;
        this.reportPopupStatistic(HiEventParamsConfirm.TRUE)
      })
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle,
    cancel: () => {
      this.onDialogCancel();
      this.isNotExit = true;
    }
  });

  /**
   * 删除弹窗
   */
  private deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.custom_account_delete_message'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      onCancelClick: (() => {
        Log.info(TAG, 'click dialog cancel');
        this.deleteDialogController?.close()
      }),
      onConfirmClick: (() => {
        let params: ReportHiEventParams = {
          IS_SAVE: HiEventParamsConfirm.TRUE
        }
        ReportUtil.reportStatisticEvent(statisticEvents.deleteAccountSavePopup, params);
        this.deleteAccount();
      })
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  /**
   * 窗口尺寸判断
   */
  getPadding(): Length {
    // pc
    if (this.needCommerce) {
      return $r('sys.float.padding_level8');
    }
    // 底部显示
    if (this.windowWidth < MIN_WINDOW_SHEET_BOTTOM) {
      return this.windowAvoidAreaNavigationRectHeight;
    }
    return 0;
  }

  showDiscardDialog(changedPropertyName: string) {
    this.onBackPress();
  }

  /**
   * 删除帐户
   */
  async deleteAccount() {
    // 先删除该账户下的所有日程，避免外键约束导致删除失败
    const events = await EventService.INSTANCE.queryEventsByAccountIds([this.accountId]);
    if (events.length > 0) {
      const eventIds = new Set(events.map(event => event.mId));
      await EventService.INSTANCE.deleteEvents(eventIds);
    }
    let deleteSum: number = await CalendarService.INSTANCE.deleteCalendarById(this.accountId) as number;
    if (deleteSum > 0) {
      Log.info(TAG, 'Delete a new account succeed, sum = ' + deleteSum);
      this.isShowAccountDetailPage = false;
    }
  }

  reportPopupStatistic(isSave: HiEventParamsConfirm) {
    let params: ReportHiEventParams = {
      IS_SAVE: isSave
    }
    if (this.editMode) {
      ReportUtil.reportStatisticEvent(statisticEvents.editAccountSavePopup, params);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.createAccountSavePopup, params);
    }
  }

  async aboutToAppear() {
    this.judgeDeleteItemVisible();

    // 查询判断是否是联系人生日账户
    let isBirthdayAccount = await AccountUtils.isBirthDayAccountByIdAsync(this.accountId);
    if (isBirthdayAccount) {
      this.isBirthdayAccount = true;
    }
    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closePageAndDialog);

    // this.immersiveListening(); // ShareKit 注释
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
    this.discardDialogController = null;
    this.deleteDialogController = null;
    // this.immersiveDisablingListening(); // ShareKit 注释
  }

  /**
   * 判断最下面和最右上角删除按钮的显隐性
   */
  judgeDeleteItemVisible() {
    if (this.needShowUpperRightButton) {
      this.showUpperRightDelete = false;
      this.showUpperRightShare = false;
      this.showBottomDelete = this.editMode && this.checkIsNotDefaultAccount();
      this.showBottomShare = this.accountType !== ACCOUNT_TYPE_EMAIL && this.checkIsNotDefaultAccount() &&
        this.accountType !== CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE
    } else {
      this.showUpperRightDelete = this.editMode && this.checkIsNotDefaultAccount();
      this.showUpperRightShare = (this.accountType !== ACCOUNT_TYPE_EMAIL) && this.checkIsNotDefaultAccount();
      this.showBottomDelete = false;
      this.showBottomShare = false;
    }
  }

  checkIsNotDefaultAccount() {
    return this.accountType !== CalendarAccountType.LOCAL_ACCOUNT_TYPE ||
      this.creator !== AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR;
  }

  /**
   * 帐户详情左上角叉按钮
   */
  @Builder
  builderFork() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        buttonBackgroundColor: this.buttonBackgroundColor,
        image: $r('sys.symbol.xmark'),
        flagChanged: $dummyFlag,
        promptText: $r('app.string.cancel_dialog_button'),
        popUpColor: $r('sys.color.ohos_id_color_card_bg'),
        onButtonClick: () => {
          this.isNotExit = false;
          if (this.confirmStatus) {
            this.discardDialogController?.open();
          } else {
            this.isShowAccountDetailPage = false;
          }
        }
      })
        .width(40)
        .height(40)
        .id(CompId.CANCEL)
    }
    .height(56)
  }

  /**
   * 帐户详情标题栏
   */
  @Builder
  NaviTitle() {
    Row() {
      this.builderFork()
      Text(this.editMode ? $r('app.string.custom_account_modify') : $r('app.string.custom_account_create'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          20
        ))
        .fontWeight(FontWeight.Bold)
        .margin({ start: LengthMetrics.vp(8) })
        .layoutWeight(1)
        .id(this.editMode ? CompId.EDIT_ACCOUNT : CompId.CREATE_AN_ACCOUNT)
        .accessibilityLevel('yes')
      Blank()
      this.builderShare()
      this.BuilderDelete()
      this.builderConfirm()
    }
    .padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .height(56)
    .margin({ top: 8 })
    .width('100%')
  }

  /**
   * 帐户详情右上角分享按钮
   */
  @Builder
  builderShare() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      buttonBackgroundColor: this.buttonBackgroundColor,
      image: $r('sys.symbol.share'),
      flagChanged: $dummyFlag,
      promptText: $r('app.string.agenda_menu_item_share'),
      popUpColor: $r('sys.color.ohos_id_color_card_bg'),
      onButtonClick: () => {
        this.shareAnchorViewId = CompId.ACCOUNT_DETAIL_SHARE_TOP;
        this.tryShareAccount();
      }
    })
      .width(40)
      .height(40)
      .margin({ left: 4, right: 4 })
      .id(CompId.ACCOUNT_DETAIL_SHARE_TOP)
      .visibility((this.isAcceptAccount || (this.showUpperRightShare && this.editMode))
        ? Visibility.Visible : Visibility.None);
  }

  /**
   * 帐户详情右上角勾选按钮
   */
  @Builder
  builderConfirm() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      buttonBackgroundColor: this.buttonBackgroundColor,
      image: $r('sys.symbol.checkmark'),
      flagChanged: $dummyFlag,
      promptText: $r('app.string.account_details_complete_button'),
      popUpColor: $r('sys.color.ohos_id_color_card_bg'),
      onButtonClick: () => {
        this.confirmButtonSucceed = true;
      },
      buttonEnabled: this.confirmStatus
    })
      .width(40)
      .height(40)
      .margin({ left: 4, right: 4 })
      .id(CompId.CONFIRMS)
  }

  /**
   * 帐户详情右上角删除按钮
   */
  @Builder
  BuilderDelete() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      buttonBackgroundColor: this.buttonBackgroundColor,
      image: $r('sys.symbol.trash'),
      flagChanged: $dummyFlag,
      promptText: $r('app.string.delete_dialog_button'),
      popUpColor: $r('sys.color.ohos_id_color_card_bg'),
      onButtonClick: () => {
        this.deleteDialogController?.open();
      },
    })
      .width(40)
      .height(40)
      .margin({ left: 4, right: 4 })
      .visibility(this.showUpperRightDelete && !this.isAcceptAccount && !this.isBirthdayAccount
        ? Visibility.Visible : Visibility.None)
      .id(CompId.DELETE)
  }

  @Builder
  shareButton() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        SymbolGlyph($r('sys.symbol.share'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
        Text($r('app.string.agenda_menu_item_share'))
          .margin({ top: 3 })
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
    }
    .id(CompId.ACCOUNT_DETAIL_SHARE_BUTTON)
    .onClick(() => {
      this.shareAnchorViewId = CompId.ACCOUNT_DETAIL_SHARE_BUTTON;
      this.tryShareAccount();
    })
    .accessibilityGroup(true)
    .stateEffect(false) // 取消按压态
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ right: 2 })
    .layoutWeight(1)
    .backgroundColor(Color.Transparent)
    .visibility(this.showBottomShare && this.editMode && !this.isAcceptAccount ? Visibility.Visible : Visibility.None)
  }

  @Builder
  BottomBuilder() {
    Row() {
      this.shareButton()
      Blank()
      Button({ type: ButtonType.Normal }) {
        Column() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize('24vp')
            .fontColor([$r('sys.color.icon_primary')])
          Text($r('app.string.delete_label'))
            .margin({ top: 3 })
            .fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
      }
      .stateEffect(false) // 取消按压态
      .borderRadius($r('sys.float.corner_radius_level6'))
      .margin({ left: 2 })
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.deleteDialogController?.open();
      })
      .visibility(this.showBottomDelete && !this.isBirthdayAccount ? Visibility.Visible : Visibility.None)
    }
    .height(52)
    .padding({
      left: $r('sys.float.padding_level12'),
      right: $r('sys.float.padding_level12')
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildContent() {
    AccountDetailContent({
      creator: this.creator,
      editMode: this.editMode,
      accountId: this.accountId,
      accountUuid: this.uuid,
      accountName: this.accountName,
      isAcceptAccount: this.isAcceptAccount,
      accountType: this.accountType,
      calendarDisplayName: this.calendarDisplayName,
      calendarColor: this.calendarColor,
      confirmStatus: $confirmStatus,
      scroller: this.detailScroller,
      confirmButtonSucceed: $confirmButtonSucceed,
      reminderState: this.reminderState,
      shareType: SourceTypeEnum.ACCOUNT,
      isShowAccountDetailPage: $isShowAccountDetailPage
    })
      .layoutWeight(1)
      .focusable(this.isNotExit)
  }

  build() {
    NavDestination() {
      Column() {
        this.NaviTitle()
        this.buildContent()
        if (this.editMode && !this.isAcceptAccount &&
          (this.showBottomShare || this.showBottomDelete)) {
          this.BottomBuilder()
        }
      }
      .padding({
        bottom: this.getPadding()
      })
    }
    .onBackPressed(() => {
      return this.onBackPress()
    })
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .backgroundColor(this.isDarkMode ? $r('sys.color.gray_02') : $r('sys.color.background_secondary'))
    .hideTitleBar(true)
  }

  /**
   * 账户侧滑退出弹出保存窗口
   * @returns
   */
  onBackPress(): boolean {
    Log.debug(TAG, "onBackPress Callback in Creat Account View.");
    this.viewProxy.onBackPressed();
    if (this.confirmStatus) {
      this.discardDialogController?.open();
      return true;
    } else {
      this.isShowAccountDetailPage = false;
    }
    return false;
  }

  /**
   * 存在循环依赖,只能通过emitter发送到主页去导出账户
   */
  private tryShareAccount() {
    GlobalThis.getInstance().shareAnchorViewId = this.shareAnchorViewId;
    let eventData: emitter.EventData = {
      data: {
        "accountId": this.accountId,
        'calendarDisplayName': this.calendarDisplayName,
        'calendarColor': this.calendarColor,
      }
    };
    Log.log(TAG, `tryShareAccount dateSelected emit`);
    emitter.emit({ eventId: CommonInnerEvent.VCS_SHARE_ACCOUNT }, eventData);
  }

  // ShareKit 注释 - start
  // private async immersiveCallback(sharableTarget: harmonyShare.SharableTarget) {
  //   Log.info(TAG, `immersiveCallback enter`);
  //   let service = await ServiceManager.getInstance()
  //     .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
  //   service?.exportVcsByCalendarAccount(new SimpleAccount(this.accountId,
  //     this.calendarDisplayName, this.calendarColor), new ExportVcsCallBack(sharableTarget));
  // }

  // private immersiveListening() {
  //   harmonyShare.on('knockShare', this.immersiveCallback.bind(this));
  // }

  // private immersiveDisablingListening() {
  //   harmonyShare.off('knockShare', this.immersiveCallback.bind(this));
  // }
  // ShareKit 注释 - end
}