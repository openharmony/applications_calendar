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
  AGENDA_SUB_DETAIL_WIDTH,
  behaviorEvents,
  BigFontSize,
  ButtonLayoutParam,
  CalendarContract,
  CalendarLayoutManager,
  CompId,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MIN_WINDOW_WIDTH_VP,
  ModeUtil,
  NavPageBuilderFactory,
  NavPathManager,
  NotificationTriggerHelper,
  ReportUtil,
  RouterName,
  TriggerSource,
  UnusualMode,
  ViewProxy
} from '@app/common';

import { AgendaDetail } from './AgendaDetail';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ImageButton } from '@app/common.components';
import { EditAgendaMenu } from '../../components/EditAgendaMenu';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { LengthMetrics } from '@kit.ArkUI';
import { AgendaDetailSource } from '../../common/AgendaEnum';

@Builder
function harBuilder(navParams: object) {
  AgendaDetailRoot({
    navParams: navParams
  });
}

const builderName = NavPathName.AGENDA_DETAIL;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

const TAG: string = 'AgendaDetailRoot';

@Component
export struct AgendaDetailRoot {
  @Consume navPathStack: NavPathStack;

  @State eventId: number = -1;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  // 右上角分享按钮被点击
  @State shareFlagChanged: boolean = false;

  // 右上角编辑按钮被点击
  @State editFlagChanged: boolean = false;

  // 顶部导航标题
  @State navTitle: Resource = $r('app.string.event_detail');

  // 右上角删除按钮被点击
  @State deleteFlagChanged: boolean = false;

  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  // 日程是否可编辑
  @State canEdit: boolean = true;

  // 日程可分享
  @State canShare: boolean = true;

  // 是否是特殊模式
  @StorageProp('unusualMode') @Watch('unusualModeChange') unusualMode: UnusualMode | undefined =
    AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  // 来源入口
  @State fromType: number = FromType.UNKNOWN;

  @State isEditMenuShow: boolean = false;

  @State mEventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State buttonLayout: ButtonLayoutParam = CalendarLayoutManager.getInstance().buttonLayout;

  @State detailPadding: number = 16;

  @Consume hideNavBarFlag: boolean;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //button背景色
  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private action: string = '';

  // 该值用于记录是否显示底部按钮,因当前底部按钮在折叠机大屏时需要移至右上角
  private showBottom: boolean = DeviceConfig.instance().config.isShowBottom;

  @State isShowBottom: boolean = this.showBottom;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private getUpdatedInfo: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.mEventInfo = info;
    this.navTitle = info.isImportantEvent() ? $r('app.string.important_day') : $r('app.string.event_detail');
    this.rightButtonShow = this.shouldShowOperateButtons();
  };

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  private navParams: object = JSON.parse('{}');

  private scroller: Scroller = new Scroller();

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  @State private buttonTopHeight: number = this.inSmallWindow ? 0 : 8;

  @State rightButtonShow: boolean = false;

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
    this.buttonTopHeight = this.inSmallWindow ? 0 : 8;
    this.checkButtonShowBottom();
  }

  checkButtonShowBottom() {
    const isBigScreen = this.windowWidth > AGENDA_SUB_DETAIL_WIDTH;
    this.isShowBottom = !isBigScreen && this.showBottom;
    this.rightButtonShow = this.shouldShowOperateButtons();
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
      this.mAgendaOperateHelper.editAgenda(this.mEventInfo);
    }
  }

  /**
   * 日程详情右上角按钮菜单
   */
  @Builder
  NavigationMenus() {
    Row() {
      ImageButton({
        image: $r('sys.symbol.share'),
        flagChanged: this.shareFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_share'),
        compId: CompId.ID_BT_AGENDA_DETAIL_SHARE
      })
        .margin({ right: 8 })
        .visibility(this.canShare ? Visibility.Visible : Visibility.None)
      if (!ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
        ImageButton({
          image: $r('sys.symbol.square_and_pencil'),
          flagChanged: this.editFlagChanged,
          buttonBackgroundColor: this.buttonBackgroundColor,
          promptText: $r('app.string.agenda_menu_item_edit'),
          onButtonClick: () => {
            this.goToEditEvent();
          },
          compId: CompId.AGENDA_DETAIL_EDIT
        })
          .margin({ end: LengthMetrics.vp(8) })
          .bindContextMenu(this.isEditMenuShow, this.buildEditMenu(), {
            placement: Placement.BottomRight,
            onDisappear: () => {
              this.isEditMenuShow = false;
            },
          })
          .visibility(this.canEdit ? Visibility.Visible : Visibility.None)
      }
      ImageButton({
        image: $r('sys.symbol.trash'),
        flagChanged: this.deleteFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_delete'),
        compId: CompId.AGENDA_DETAIL_DELETE
      })
    }
    .height(this.buttonLayout.menuHeight)
  }

  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    EditAgendaMenu({
      isFirstRepeatAgenda: this.isFirstRepeatAgenda(),
      editThisAgenda: () => {
        this.mAgendaOperateHelper.editThisAgenda(this.mEventInfo, this.instanceStartMills, this.instanceEndMills);
      },
      editThisAgendaAndBeyond: () => {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(
          this.mEventInfo, this.instanceStartMills, this.instanceEndMills);
      },
      onClickEdit: () => {
        this.mAgendaOperateHelper.editAgenda(this.mEventInfo);
      }
    })
  }

  @Builder
  buildBackButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .focusable(true)
        .fontSize(this.buttonLayout.symbolSize)
        .fontWeight(this.buttonLayout.symbolWeight)
        .fontColor([$r('sys.color.icon_primary')])
    }
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
    .width(this.buttonLayout.buttonHeight)
    .height(this.buttonLayout.buttonHeight)
    .id(CompId.AGENDA_DETAIL_BACK)
    .margin({ start: LengthMetrics.vp(16) })
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor(this.buttonBackgroundColor)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.pageRouterBack()
    })
  }

  @Builder
  MainContentBuilder() {
    GridRow({
      // 手机边距16,大屏边距24,宽度大于840则需要以10/12的栅格比例留白
      columns: { xs: 10, sm: 10, md: 12 },
      breakpoints: {
        value: ['600vp', '840vp'],
        reference: BreakpointsReference.ComponentSize
      },
      direction: GridRowDirection.Row
    }) {
      GridCol({ span: 10, offset: { xs: 0, sm: 0, md: 1 } }) {
        AgendaDetail({
          canEdit: $canEdit,
          canShare: $canShare,
          shareFlagChanged: this.shareFlagChanged,
          deleteFlagChanged: this.deleteFlagChanged,
          isShowBottom: this.isShowBottom,
          eventId: $eventId,
          sourceType: AgendaDetailSource.AGENDA_ROUTER,
          isDivide: false,
          isInPop: this.isInPop,
          needLeftPadding: true,
          needRightPadding: true,
          scroller: this.scroller,
          holidayInfo: this.holidayInfo,
          displayStartMills: this.instanceStartMills,
          displayEndMills: this.instanceEndMills,
          titleHeight: this.inSmallWindow ? this.getTitleHeight(this.buttonLayout.menuHeight, this.unusualMode,
            this.windowAvoidAreaTopRectHeight) : 16,
          onDeleteSuccess: () => {
            GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
            this.pageBackAfterDelete();
          },
          onAgendaNotFound: () => {
            GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
            this.pageBackAfterDelete();
          },
          fromType: this.fromType,
          getUpdatedInfo: this.getUpdatedInfo,
          paddingLeft: this.detailPadding,
          paddingRight: this.detailPadding,
        }).id(CompId.AGENDA_DETAIL_ROOT_AGENDA_DETAIL)
      }
    }
    .onAppear(() => {
      Log.info(TAG, `agenda gridRow appear`);
    })
    .onBreakpointChange((bp) => {
      // 小屏需要边距,到直接通过栅格来留白
      if (bp === 'xs') {
        this.detailPadding = 16;
      } else if (bp === 'sm') {
        this.detailPadding = 24;
      } else if (bp === 'md') {
        this.detailPadding = 0;
      }
    })
    .layoutWeight(1)
  }

  @Builder
  GridColContent() {
    Row() {
      if (this.hideNavBar(this.hideNavBarFlag, this.unusualMode)) {
        this.buildBackButton()
      }
      Text(this.navTitle)
        .fontSize(20)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
        .margin({ start: LengthMetrics.vp(8) })
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      if (this.rightButtonShow) {
        this.NavigationMenus()
      }
    }
    .padding({
      start: this.hideNavBar(this.hideNavBarFlag, this.unusualMode) ? LengthMetrics.vp(0) : LengthMetrics.vp(56),
      // titleButtonWidth为PC窗口三键规避,但在pop弹窗中无需此规避参数
      end: LengthMetrics.vp(16 + (this.isInPop ? 0 : this.titleButtonWidth))
    })
    .height(this.buttonLayout.menuHeight)
  }

  build() {
    NavDestination() {
      if (this.hideNavBar(this.hideNavBarFlag, this.unusualMode)) {
        this.GridColContent()
      }
      this.MainContentBuilder();
    }
    .onBackPressed(() => {
      return this.onBackPress()
    })
    .padding({
      top: this.isInPop
        ? this.buttonTopHeight : (ModeUtil.isSmallUpDownFoldMode(this.unusualMode) ?
        Math.max(this.windowAvoidAreaTopRectHeight - 8, 8) :
          (this.windowAvoidAreaTopRectHeight + this.buttonTopHeight)),
      bottom: this.isInPop ? 16 : 0,
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown(() => this.onPageShow())
    .onHidden(() => this.onPageHide())
    .hideTitleBar(this.hideNavBar(this.hideNavBarFlag, this.unusualMode))
    .title(this.GridColContent(), { paddingStart: LengthMetrics.vp(16) })
  }

  onPageShow() {
    if (this.isRootLauncherByFaCard()) {
      // 从卡片进入隐藏路由
      this.hideNavBarFlag = true;
    }
    this.viewProxy.onShown();
  }

  onPageHide() {
    // 兜底行为，防止编辑页面侧滑或者上滑关闭后，应用热启动进入首页，未恢复应用路由导致画面空白
    this.hideNavBarFlag = false;
    this.viewProxy.onHidden();
  }

  onBackPress(): boolean {
    this.viewProxy.onBackPressed();
    return this.terminateSelfIfMatch();
  }

  pageBackAfterDelete() {
    if (this.isInPop) {
      NavPathManager.getInstance().popRouter(RouterName.SEARCH_AGENDA_MAIN);
      return;
    }
    GlobalThis.getInstance().beforeAgendaAction = undefined;
    // 必须先开启路由否则会导致动画消失
    this.hideNavBarFlag = false;
    this.navPathStack.pop();
  }

  pageRouterBack() {
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaFaGoToMonth);
    if (this.isInPop) {
      NavPathManager.getInstance().popRouter(RouterName.SEARCH_AGENDA_MAIN);
      return;
    }

    GlobalThis.getInstance().beforeAgendaAction = undefined;
    // 卡片进入需要清除action防止再次进入日程详情无动效
    if (this.isRootLauncherByFaCard()) {
      (GlobalThis.getInstance().abilityWant!.parameters)!.action = '';
    }
    // 必须先开启路由否则会导致动画消失
    this.hideNavBarFlag = false;
    this.navPathStack.pop();
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS);

    const paramInter: RouterParam = this.navParams as RouterParam;
    if (!paramInter) {
      return;
    }
    try {
      this.eventId = paramInter.id;
      this.holidayInfo = paramInter.holidayInfo;
      this.isInPop = paramInter.isInPop;
      this.action = paramInter?.action;
      this.instanceStartMills = Number(paramInter?.instanceStartMills);
      this.instanceEndMills = Number(paramInter?.instanceEndMills);
      if (paramInter?.fromType) {
        this.fromType = paramInter.fromType;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'parse param failed', err);
    }
    this.checkButtonShowBottom();
    Log.info(TAG, `params.id = ${paramInter.id}, params.action = ${paramInter.action}`);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
  }

  private getTitleHeight(titleHeight: number, unusualMode: UnusualMode | undefined, avoidTopHeight: number): number {
    // 初始规避高度为标题高度+8
    const defaultHeight = titleHeight + 8;
    if (this.isInPop) { // 子窗模式,不需要考虑规避
      return defaultHeight + this.buttonTopHeight;
    }
    if (ModeUtil.isSmallUpDownFoldMode(unusualMode)) { // 小屏
      return defaultHeight + Math.max(avoidTopHeight - 8, 8);
    }
    return defaultHeight + avoidTopHeight + this.buttonTopHeight;
  }

  // 判断是否需要隐藏NavBar
  private hideNavBar(hideNavBarFlag: boolean, unusualMode: UnusualMode | undefined): boolean {
    return hideNavBarFlag || this.isInPop || ModeUtil.isHiCarOrSmallUpDownFoldMode(unusualMode);
  }

  /**
   * pc端是否展示编辑、分享、删除操作按钮
   */
  private shouldShowOperateButtons(): boolean {
    if (this.isShowBottom && !ModeUtil.isSmallUpDownFoldMode(this.unusualMode)) {
      return false;
    }

    if (this.holidayInfo?.mId === 0) {
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

  private terminateSelfIfMatch(): boolean {
    if (this.isRootLauncherByFaCard()) {
      (GlobalThis.getInstance().abilityWant!.parameters)!.action = '';
      return false;
    } else {
      GlobalThis.getInstance().beforeAgendaAction = undefined
      return false;
    }
  }

  /**
   * 判断是否卡片上的点击日程事件“CLICK_AGENDA_DETAIL“
   * @returns 是卡片上的点击日程事件
   */
  private isRootLauncherByFaCard(): boolean {
    const parameters = GlobalThis.getInstance().abilityWant?.parameters;
    if (!parameters || parameters.params === '') {
      Log.info(TAG, 'Not Root Launcher By FaCard!');
      return false;
    }
    const isCard = parameters.action === 'CLICK_AGENDA_DETAIL';
    return isCard;
  }

  unusualModeChange() {
    this.rightButtonShow = this.shouldShowOperateButtons();
  }
}

interface RouterParam {
  action: string;
  id: number;
  holidayInfo: AgendaEventInfo;
  instanceStartMills: number;
  instanceEndMills: number;
  fromType: number;
  isInPop: boolean;
}