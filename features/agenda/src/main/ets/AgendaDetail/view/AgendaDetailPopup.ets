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
  AgendaEventInfo,
  CalendarContract,
  CompId,
  ClickSource,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NotificationTriggerHelper,
  TriggerSource,
  ViewProxy,
  CommonInnerEvent,
  BigFontSize,
  EmitterCollector,
  NavPageBuilderFactory,
  RouterName,
  NavPathManager,
  AgendaTransitionUtil,
  NavPathName,
  AGENDA_SUB_DETAIL_WIDTH,
  PreferencesFiles,
  PreferencesUtil,
  SafeUtil,
  AccountColor
} from '@app/common';

import { AgendaDetail } from './AgendaDetail';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { EditAgendaMenu } from '../../components/EditAgendaMenu';
import { emitter } from '@kit.BasicServicesKit';
import { ImageButton } from '@app/common.components';
import { CreateAgendaPageSource } from '../../CreateAgenda/Constants';
import { RouterParam } from '../../CreateAgenda/view/CreateAgendaRoot';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'AgendaDetailPopup';

@Component
export struct AgendaDetailPopup {
  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  private navPathStackInDetailPop: NavPathStack = new NavPathStack();

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @State eventId: number = -1;

  // 右上角缩放按钮被点击
  @State scaleFlagChanged: boolean = false;

  // 右上角分享按钮被点击
  @State shareFlagChanged: boolean = false;

  // 右上角编辑按钮被点击
  @State editFlagChanged: boolean = false;

  // 右上角删除按钮被点击
  @State deleteFlagChanged: boolean = false;

  // 顶部导航标题
  @State navTitle: Resource = $r('app.string.event_detail');

  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  // 日程是否可编辑
  @State canEdit: boolean = true;

  // 日程可分享
  @State canShare: boolean = true;

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  // 来源入口
  @State fromType: number = FromType.UNKNOWN;

  @State isEditMenuShow: boolean = false;

  @State mEventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State rightButtonShow: boolean = false;

  // hover态颜色
  @State hoverColor: Resource = $r('app.color.default_background');

@State isMessageResource: boolean = false;

//是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //button背景色
  private buttonBackgroundColor: ResourceColor =
    this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private isShowBottom: boolean = false;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private scroller: Scroller = new Scroller();

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private isPopShrink: boolean = false;

  private waitToClosePage: boolean = false; // 等待关闭界面标识

  private isSubDetailCheck: boolean = DeviceConfig.instance().config.isSubDetailCheck;

  private isHoliday: boolean = false;

  private holidayTitle: string = '';

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  //详情子窗打开状态存储
  @StorageLink(GlobalDataKeys.IS_SUB_WINDOW_DETAIL) isSubWindowDetail: boolean = false;

  private getUpdatedInfo: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.mEventInfo = info;
    this.navTitle = info.isImportantEvent() ? $r('app.string.important_day') : $r('app.string.event_detail');
    this.rightButtonShow = this.shouldShowOperateButtons();
  };

  private eventToClosePopup: () => void = () => {
  };

  private clickToClosePopup: () => void = () => {
    Log.info(TAG, `click close agenda popup ${this.navPathStackInDetailPop.size()}`);
    if (this.navPathStackInDetailPop.size() === 0) {
      emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
    } else {
      this.waitToClosePage = true;
    }
  };

  private updateBottomShow: (rightButtonShow: boolean) => void = () => {
    this.rightButtonShow = this.rightButtonShow;
  };

  private jumpToPopEditPage: (intent: CreateAgendaPageSource) => void = (intent: CreateAgendaPageSource) => {
    this.jumpToEditPage(intent);
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    NavPathManager.getInstance().createRouter(RouterName.AGENDA_DETAIL_HAP, this.navPathStackInDetailPop);
    this.rightButtonShow = this.shouldShowOperateButtons();
    if (this.isHoliday) { // 拼接节假日数据
      this.holidayInfo.mTitle = this.holidayTitle;
      this.holidayInfo.mIsHoliday = true;
      this.holidayInfo.mIsAllDay = true;
      this.holidayInfo.mId = -1; // 用作标识，无实际含义
      this.holidayInfo.mBegin = this.instanceStartMills;
      this.holidayInfo.mImportantEventType = -1; // 用作标识，无实际含义
      this.holidayInfo.mEnd = this.instanceEndMills;
      this.holidayInfo.mDisplayColor = AccountColor.RED;
    }
    NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS);
    this.eventToClosePopup = () => {
      Log.info(TAG, `emitter close agenda popup`);
      emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
    };
    // 卡片点击进入月视图，关闭全模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.eventToClosePopup);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.eventToClosePopup);
    this.emitterCollector.on({ eventId: CommonInnerEvent.DETAIL_PAGE_POPUP_CLOSE }, this.clickToClosePopup);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    NavPathManager.getInstance().discard(RouterName.AGENDA_DETAIL_HAP);
    this.emitterCollector.off();
  }

  onWindowWidthChange() {
    if (!this.isSubDetailCheck) {
      // 不需要感知窗口变化
      return;
    }
    if (this.windowWidth < AGENDA_SUB_DETAIL_WIDTH) {
      Log.info(TAG, `pop statu change ${this.windowWidth}`);
      // 小于子窗展示宽度则直接将其切换到全屏cover
      this.jumpToAgendaCover(false, true);
    }
  }

  // 是否重复日程第一条
  isFirstRepeatAgenda(): boolean {
    if (!this.mEventInfo.isRepeatEvent()) {
      return false;
    }
    if (this.mEventInfo.mBegin === this.instanceStartMills) {
      return true;
    }
    return false;
  }

  goToEditEvent() {
    if (this.mEventInfo.isRepeatEvent() && !this.mEventInfo.isImportantEvent()) {
      this.isEditMenuShow = true;
    } else {
      this.jumpToEditPage();
    }
  }

  jumpToEditPage(intent: CreateAgendaPageSource = CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE) {
    const params: RouterParam = {
      'intent': intent,
      'eventInfo': JSON.stringify(this.mEventInfo),
      page: 0,
      agendaDateParam: this.instanceStartMills,
      instanceStartMills: this.instanceStartMills,
      instanceEndMills: this.instanceEndMills
    };
    NavPathManager.getInstance().getRouter(RouterName.AGENDA_DETAIL_HAP)?.pushPath({
      name: NavPathName.CREATE_AGENDA_SUB,
      param: params,
      onPop: (popInfo: PopInfo) => {
        Log.info(TAG, 'navPath pop');
        if (this.waitToClosePage) {
          emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
          return;
        }
        this.onWindowWidthChange();
      }
    })
  }

  // 因menu关闭延时会导致弹窗异常,故添加延时跳转编辑界面
  menuJumpToEditPage(intent: CreateAgendaPageSource = CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE) {
    SafeUtil.setTimeout(() => {
      this.jumpToEditPage(intent);
    }, 200)
  }

  onBackPress(): boolean {
    this.viewProxy.onBackPressed();
    return false;
  }

  pageBackAfterDelete() {
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
  }

  pageRouterBack() {
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
  }

  getGeometryId(): string {
    return '' + this.eventId + '-Cover';
  }

  @State geometry: string = '';

  @State transitionOption: GeometryTransitionOptions = {};

  private onAniStart: () => void = () => {
    this.geometry = this.getGeometryId();
    this.pageRouterBack();
  }

  private onAniEnd: () => void = () => {
    this.geometry = '';
    this.transitionOption = {};
  }

  /**
   * pc端是否展示编辑、分享、删除操作按钮
   */
  private shouldShowOperateButtons(): boolean {
    if (this.isShowBottom) {
      return false;
    }

    if (this.holidayInfo?.mIsHoliday) {
      return false;
    }

    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return false;
    }
    return true;
  }

  /**
   * 跳转全屏详情
   * @param needAnimate 是否需要动画
   * @param isWindowChange 是否为窗口变化自动跳转
   */
  private jumpToAgendaCover(needAnimate: boolean = true, isWindowChange: boolean = false) {
    if (!isWindowChange) { // 窗口宽度不满足详情子窗的显示条件时需要跳转全屏详情,此时不应该记录最后打开的详情窗口状态
      this.isSubWindowDetail = false;
      PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT, GlobalDataKeys.IS_SUB_WINDOW_DETAIL, false);
    }
    this.agendaTransitionUtil.buildEventDetail(this.mEventInfo, FromType.MONTH_VIEW, true);
    this.agendaTransitionUtil.param.isPop = true;
    this.agendaTransitionUtil.param.instanceStartMills = this.instanceStartMills;
    this.agendaTransitionUtil.param.instanceEndMills = this.instanceEndMills;
    this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), needAnimate, this.onAniStart, this.onAniEnd, false);
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  /**
   * 日程详情右上角按钮菜单
   */
  @Builder
  NavigationMenus() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.share'),
        flagChanged: this.shareFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_share'),
        compId: CompId.ID_BT_AGENDA_DETAIL_POP_SHARE
      })
        .margin({ left: 8 })
        .visibility(this.canShare ? Visibility.Visible : Visibility.None)
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.square_and_pencil'),
        flagChanged: this.scaleFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_edit'),
        compId: CompId.AGENDA_DETAIL_EDIT,
        onButtonClick: () => {
          this.goToEditEvent();
        }
      })
        .bindMenu(this.isEditMenuShow, this.buildEditMenu(), {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.isEditMenuShow = false;
          }
        })
        .visibility(this.canEdit ? Visibility.Visible : Visibility.None)
        .margin({ left: 8 })
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.trash'),
        flagChanged: this.deleteFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_delete'),
        compId: CompId.AGENDA_DETAIL_DELETE,
      })
        .margin({ left: 8 })
      Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .focusable(true)
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
      }
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
      .width(40)
      .height(40)
      .id(CompId.AGENDA_DETAIL_BACK)
      .margin({ left: 8 })
      .borderRadius($r('sys.float.corner_radius_level4'))
      .backgroundColor(this.buttonBackgroundColor)
      .onHover((isHover: boolean | undefined) => {
        this.hoverColor = isHover ? $r('app.color.hover_background') : $r('app.color.default_background');
      })
      .onClick(() => {
        this.pageRouterBack()
      })
    }
    .height(48)
  }

  /**
   * 日程详情右上角缩放按钮
   */
  @Builder
  jumpToCoverMenus() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.arrow_up_left_and_arrow_down_right'),
        flagChanged: this.scaleFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: '扩展', // 待提翻
        onButtonClick: () => {
          this.jumpToAgendaCover();
        }
      })
        .margin({ left: 8 })
    }
    .height(48)
  }

  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    EditAgendaMenu({
      isFirstRepeatAgenda: this.isFirstRepeatAgenda(),
      editThisAgenda: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_THIS_AGENDA);
      },
      editThisAgendaAndBeyond: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND);
      },
      onClickEdit: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE);
      }
    })
  }

  @Builder
  MainContentBuilder() {
    Column() {
      AgendaDetail({
        canEdit: $canEdit,
        canShare: $canShare,
        shareFlagChanged: this.shareFlagChanged,
        deleteFlagChanged: this.deleteFlagChanged,
        isShowBottom: this.isShowBottom,
        shareAnchorViewId: CompId.ID_BT_AGENDA_DETAIL_POP_SHARE,
        eventId: this.eventId,
        isDivide: false,
        isCover: true,
        isDetailPop: true,
        holidayInfo: this.holidayInfo,
        displayStartMills: this.instanceStartMills,
        displayEndMills: this.instanceEndMills,
        paddingLeft: 16,
        paddingRight: 16,
        scroller: this.scroller,
        titleHeight: 72,
        jumpToPopEditPage: this.jumpToPopEditPage,
        isInDetailPop: true,
        onDeleteSuccess: () => {
          GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
          this.pageBackAfterDelete();
        },
        onAgendaNotFound: () => {
          GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
          this.pageBackAfterDelete();
        },
        fromType: this.fromType,
        getUpdatedInfo: this.getUpdatedInfo
      })
    }.layoutWeight(1)
  }

  @Builder
  GridColContent() {
    Row() {
      Text(this.navTitle)
        .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          20
        ))
        .minFontSize(4)
        .margin({ left: 16 })
        .maxLines(1)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      this.jumpToCoverMenus()
      if (this.rightButtonShow) {
        this.NavigationMenus()
      }
    }
    .padding({ right: 16 })
    .margin({ top: 8 })
    .height(56)
  }

  @Builder
  buildAgenda() {
    Navigation(this.navPathStackInDetailPop) {
      Column() {
        this.GridColContent()
        this.MainContentBuilder()
      }
    }
    .hideTitleBar(true)
    .id(TAG)
    .mode(NavigationMode.Stack)
    .geometryTransition(this.geometry, this.transitionOption)
    .navDestination(this.navRoute)
    .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') :
      $r('app.color.color_privacy_background'))
    .height('100%')
    .constraintSize({ maxHeight: 560 })
  }

  build() {
    this.buildAgenda()
  }
}