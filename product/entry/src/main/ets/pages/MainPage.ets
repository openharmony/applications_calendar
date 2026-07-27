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

import data_preferences from '@ohos.data.preferences';
import emitter from '@ohos.events.emitter';
import {
  AgendaEventInfo,
  AgendaTransitionUtil,
  BackPressInterceptor,
  behaviorEvents,
  BigFontSize,
  CalendarContract,
  CalendarService,
  checkReadContactPermission,
  CommonInnerEvent,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  EmptyUtils,
  EventService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  HiEventParamsConfirm,
  Log,
  MILLS_PER_MINUTE,
  NavPathManager,
  NavPathName,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceManager,
  ShareRole,
  ShareTypeEnum,
  SourceTypeEnum,
  statisticEvents,
  TabType,
  ThrottleFunction,
  ViewCallInterceptorHolder,
  ViewProxy,
  MIN_WINDOW_WIDTH_VP,
  ServiceEnum,
  CommonService,
  AgendaDeleteService,
  CompId,
  AppContinueManager,
  EmitterCollector,
  UnusualMode,
  ModeUtil,
  ClickSource,
  CalendarDate,
  SafeUtil,
  AgendaAbilityManager,
  ContinueType,
  DateInfo,
  MonthlyInfo,
  PreferencesUtil,
  PreferencesFiles,
  MILLS_PER_WEEK,
  MIN_WINDOW_HEIGHT_VP,
  DateTitleUtil,
  CalendarCacheService
} from '@app/common';
import {
  CommonTextDialog,
  DateSwitch,
  SlideTabBar,
  SingleButtonDialog,
  JumpToSomedayPicker,
  TimePoint
} from '@app/common.components';
import { AgendaDetailCover, CopyHelper, DeleteAgendaRadio, DeleteMode, FlexSearchAgenda } from '@app/feature.agenda';
import { CalendarSideBarContainer, SIDEBAR_VISIBLE_TAG, SIDE_BAR_SHOW_USER } from './SideBarContainer';
import lazy { ButtonInMainPage } from '../common/comp/ButtonInMainPage';
import Want from '@ohos.app.ability.Want';
import { MainPageLayout, MainPageLayoutManager, MainPageVirtualGrid, SidebarLayout } from './MainViewModel';
// 裁剪日程共享功能 - 移除 MessageExternalController, ShareRelationInfo, ShareRelationService
// import { MessageExternalController, ShareRelationInfo, ShareRelationService } from '@app/feature.share';
import { MainTabComponent } from './MainTabComponent';
import uri from '@ohos.uri';
import { CardType, FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { CACHE_SYNC_SWITCH_STATUS, CloudUtils, isSyncAbleAccount } from '@app/common/src/main/ets/dao/CloudUtils';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { CARD_IMPORTANT } from '@app/feature.card/src/main/ets/utils/CardJumpUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { DateTitle } from '../common/comp/DateTitle';
import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
// import { MonthViewAgendaBlockShareParam } from '@app/common/src/main/ets/default/util/ShareUtils'; // ShareKit 注释
import { ExportVcsCallBack, ImportExportService, ImportVcsCallBack } from '@app/feature.importexport';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';
import { AGENDA_SEARCH_DATE_BEGIN, AGENDA_SEARCH_DATE_END } from '@app/common/src/main/ets/agenda/Constants';
import {
  MonthlyViewTemporaryAgendaData
} from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewTemporaryAgendaData';
import { SingleMonthAgendaManager } from '@app/feature.monthview/src/main/ets/viewmodel/SingleMonthAgendaManager';
import { barText, focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { JumpExtActionType } from '@app/common/src/main/ets/card/CardConstants';

const DETAIL_WANT_PARAM_ID: string = 'event_id';

const DETAIL_WANT_PARAM_START_TIME: string = 'start';

const DETAIL_WANT_PARAM_END_TIME: string = 'end';

const SWITCH_ON: number = 1;

const TAG: string = 'MainPage';

/**
 * MainPage for current ability
 *
 * @since 2022-03-01
 */

export type ActionType = 'CLICK_MONTH_FORM_HEADER' | 'CLICK_AGENDA_DETAIL' | 'CLICK_CREATE_EVENT' | 'SHARE_PUSH'
  | 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW';

@Component
export struct MainPage {
  static readonly MAX_FRAME_STAGE = 3;

  @Consume navPathStack: NavPathStack;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Provide isOnDropAllowed: boolean = true;

  @Provide keyCtrlState: boolean = false; // Ctrl 键的状态

  @Provide needShowHideButton: boolean = true; // 是否需要显示详情开合按钮

  @StorageProp('themeColor') themeColor: string = '';

  // 显示/隐藏班休信息
  @StorageProp('isRecessToggleOn') isRecessToggleOn: boolean = false;

  @StorageLink('language') language: string = '';

  // tab页签索引，无缓存情况下首次进入日历应用显示月视图
  @StorageLink('tabIndex') tabsIndex: number = TabType.MONTH;

  // tabIndex的本地缓存
  @StorageLink('tabIndexPreferences') tabIndexPreferences: data_preferences.Preferences | null = null;

  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  //显示搜索日程页面
  @State showSearch: boolean = false;

  // PC右上角回到今天的标记位，改变该值用于触发回到今天操作
  @State backToTodayFlag: boolean = false;

  // 窗口宽度
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 窗口高度
  @LocalStorageLink('windowHeight') @Watch('onWindowHeightChange') windowHeight: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  // 是否需要隐藏菜单栏
  @State hideMenu: boolean = this.windowHeight < MIN_WINDOW_HEIGHT_VP;

  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

  @StorageLink(CACHE_SYNC_SWITCH_STATUS) syncSwitchStatus: number = 0;

  private deleteAgenda: AgendaEventInfo | undefined = undefined; // 要删除的agenda

  private deleteTimestamp: number = -1; // 涉及删除的时间

  private deleteAccountType: string = '';

  private agendaDeleteService: AgendaDeleteService | undefined = undefined;

  private initCreateAgenda: boolean = false;

  private viewId: number = 0;

  private isClickConfirm: boolean = false;

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

  // 删除重复日程弹框
  deleteRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DeleteAgendaRadio({
      confirm: (checkValue) => {
        this.isClickConfirm = true;
        if (!this.deleteAgenda) {
          return;
        }
        if (!this.showSearch && this.tabsIndex === TabType.MONTH) {
          focusComponentById(CompId.MONTH_VIEW_DATE_BANNER, 0);
        }
        if (checkValue === DeleteMode.ONLY_THIS_AGENDA) {
          this.agendaDeleteService?.addExclusiveToRepeatRule(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else if (checkValue === DeleteMode.THIS_AND_FUTURE_AGENDA) {
          this.agendaDeleteService?.updateEndTime(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else {
          this.agendaDeleteService?.deleteEvent(this.deleteAgenda.mId);
        }
      },
      showCloudSyncTip: isSyncAbleAccount('', this.deleteAccountType) &&
        CloudUtils.isSupportCloudSync() && CloudUtils.isCloudSyncOpened(),
      title: this.agendaDeleteService?.getDeleteAgendaDialogTitle(this.deleteAgenda?.mTitle || ''),
      isFirstRepeatAgenda: this.deleteAgenda?.mBegin === this.deleteTimestamp,
    }),
    alignment: DialogAlignment.Center,
    onDidDisappear: () => {
      if (this.isClickConfirm) {
        emitter.emit({ eventId: CommonInnerEvent.DELETE_DIALOG_DELETE_AGENDA_SUCCESS });
      }
      this.isClickConfirm = false;
    }
  });

  // 删除非重复日程弹框
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: this.agendaDeleteService?.getDeleteMessage(this.deleteAgenda, this.deleteAccountType),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        this.isClickConfirm = true;
        if (!this.deleteAgenda) {
          return;
        }
        if (!this.showSearch && this.tabsIndex === TabType.MONTH) {
          focusComponentById(CompId.MONTH_VIEW_DATE_BANNER, 0);
        }
        this.agendaDeleteService?.deleteEvent(this.deleteAgenda?.mId);
      },
      onCancelClick: () => {
        Log.info(TAG, 'click cancel');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle,
    onDidDisappear: () => {
      Log.info(TAG, `onDidDisappear isClickConfirm: ${this.isClickConfirm}`);
      if (this.isClickConfirm) {
        emitter.emit({ eventId: CommonInnerEvent.DELETE_DIALOG_DELETE_AGENDA_SUCCESS });
      }
      this.isClickConfirm = false;
    }
  });

  @State layout: MainPageLayout = MainPageLayoutManager.getInstance().layout;

  //侧边栏相关配置
  @State @Watch('onSidebarStateChange') sidebarLayout: SidebarLayout = MainPageLayoutManager.getInstance().sidebarLayout;

  // 是否是HiCar模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined =
    AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  @Provide sideBarOverlay: boolean = MainPageLayoutManager.getInstance().sidebarLayout.sideBarOverlay; // 侧边栏样式控制

  @Provide isShowLeftBar: boolean = !this.sideBarOverlay; // 按钮控制

  @Provide sidebarVisible: boolean = this.isShowLeftBar;

  @Provide isAnimation: boolean = false;

  @Provide maskPosX: number = 0;

  @Provide isMaximizeRecovery: boolean = false; // 窗口是否最大化恢复

  @Provide hideAgendaWindowMonth: boolean = false; // 月视图是否隐藏日程列表

  @Provide hideAgendaWindowDay: boolean = false; // 日视图是否隐藏日程详情

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  viewProxy: ViewProxy = new ViewProxy(TAG);

  private showFloatButton: boolean = DeviceConfig.instance().config.showFloatButton; // 显示日期选择器

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  @StorageProp(GlobalDataKeys.SIDEBAR_WIDTH) sidebarWidth: number = DeviceConfig.instance().config.deviceLayout.sidebarWidth;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private keyboardSwitchingDate: boolean = DeviceConfig.instance().config.keyboardSwitchingDate;

  private eventFormHandler: () => void = (): void => {
  };

  private showJumpToSomedayHandler: () => void = () => {
    this.jumpToSomedayDialogController?.open();
  }

  private emitterCollector: EmitterCollector = new EmitterCollector();

  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 100;

  // 开始时间
  startDate: Date = new Date(
    Math.trunc(new Date().getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE
  );

  jumpToSomedayDialogController: CustomDialogController | null = new CustomDialogController({
    builder: JumpToSomedayPicker({
      confirm: (date) => {
        const nowDate = new CalendarDate(date.getFullYear(), date.getMonth(), date.getDate());
        emitter.emit({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, { data: { 'dateTime': nowDate.getTime() } });
      },
      selectedDateTime: this.startDate,
      timePoint: TimePoint.START,
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel
  });

  onWindowWidthChange() {
    Log.info(TAG, `${this.viewId} onWindowWidthChange, windowWidth is ${this.windowWidth}`);
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  onWindowHeightChange() {
    Log.info(TAG, `${this.viewId} onWindowHeightChange, windowHeight is ${this.windowHeight}`);
    this.hideMenu = this.windowHeight < MIN_WINDOW_HEIGHT_VP;
  }

  onSidebarStateChange() {
    this.sideBarOverlay = this.sidebarLayout.sideBarOverlay;
  }

  @Builder
  buildDateSwitchComponent() {
    DateSwitch({
      buttonText: $r('app.string.today'),
      onClickButton: () => {
        GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, new Date().getTime());
        //额外进行广播通知回到今天事件
        emitter.emit({ eventId: CommonInnerEvent.BACK_TO_TODAY });
        if (this.tabsIndex === TabType.AGENDA) {
          // PC日程列表界面右上角点击今天，改变标记位
          this.backToTodayFlag = !this.backToTodayFlag;
        }
        let params: ReportHiEventParams = {
          SOURCE_PAGE: this.tabsIndex
        }
        ReportUtil.reportStatisticEvent(statisticEvents.backToToday, params);
      },
      onClickLeftArrow: () => {
        emitter.emit({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, { data: { 'direction': 0 } });
      },
      onClickRightArrow: () => {
        emitter.emit({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, { data: { 'direction': 1 } });
      }
    })
  }

  /**
   * 每秒收到广播-回调函数
   */
  subscribeCallBack() {
    GlobalData.instance().set(GlobalDataKeys.CURRENT_DATE, new Date().getTime());
  }

  getDateTitleText(): ResourceStr {
    return DateTitleUtil.formatTitle(this.displayDate, this.tabsIndex, this.language);
  }

  @Builder
  buildSearch() {
    if (this.showSearch) {
      Column() {
        FlexSearchAgenda({
          themeColor: this.themeColor,
          onDismiss: () => {
            this.showSearch = false;
          },
          showSearch: this.showSearch
        })
      }
      .zIndex(4)
      .position({ x: 0, y: this.windowAvoidAreaTopRectHeight })
      .margin({
        left: (this.sideBarOverlay || !this.isShowLeftBar) ? 0 : this.sidebarWidth
      })
      .padding({ bottom: this.windowAvoidAreaTopRectHeight })
      .height('100%')
    }
  }

  @Builder
  buildMenu() {
    // 菜单区域  侧边栏按钮; 日期标题栏; 设置按钮
    /* 设置 */
    Row() {
      if (!this.showFloatButton) { // 不显示悬浮窗按钮时,就需要显示日期选择
        this.buildDateSwitchComponent();
      }
      ButtonInMainPage({
        themeColor: this.themeColor,
        showSearch: this.showSearch,
        needHideAgendaFolding: this.layout.needHideAgendaFolding,
        initCreateAgenda: this.initCreateAgenda,
        onChanged: (showSearch: boolean): void => {
          this.showSearch = showSearch;
        },
        showJumpToSomedayDialog: this.showJumpToSomedayHandler,
      })
    }
    .id(CompId.MAIN_PAGE_BUILD_MENU)
    .hitTestBehavior(HitTestMode.None) // 防止tabBar无法响应点击事件
    .justifyContent(FlexAlign.End)
    .width('100%')
    .padding({
      start: LengthMetrics.vp(16),
      end: LengthMetrics.vp(16 + this.titleButtonWidth)
    })
    .height(this.layout.menuBarHeight)
    .margin({ top: this.buttonTopHeight })
    .zIndex(2)
    .visibility(this.hideMenu ? Visibility.None : Visibility.Visible)
    .position({
      start: LengthMetrics.vp(0),
      top: LengthMetrics.vp(this.windowAvoidAreaTopRectHeight)
    })
  }

  @Builder
  buildMask() {
    //侧边栏遮盖层
    Column()
      .width('100%')
      .height('200%')
      .position({
        start: LengthMetrics.vp(this.maskPosX),
        top: LengthMetrics.vp(-this.windowAvoidAreaTopRectHeight)
      })
      .visibility(this.isShowLeftBar && this.sideBarOverlay ? Visibility.Visible : Visibility.Hidden)
      .hitTestBehavior(HitTestMode.Block)
      .backgroundColor($r('sys.color.mask_fourth'))
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.accessibility_close_sidebar')))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .zIndex(101)
      .onClick(() => {
        this.closeSideBarAnimate()
      })
  }

  @Builder
  buildAgendaDetail() {
    Column() {
      AgendaDetailCover({
        eventId: this.agendaTransitionUtil.param.id as number,
        instanceStartMills: Number(this.agendaTransitionUtil.param?.instanceStartMills),
        instanceEndMills: Number(this.agendaTransitionUtil.param?.instanceEndMills),
        fromType: this.agendaTransitionUtil.param.fromType as number,
        isHoliday: this.agendaTransitionUtil.param.isHoliday as boolean,
        holidayTitle: this.agendaTransitionUtil.param.holidayTitle as string,
        canSubWindow: this.agendaTransitionUtil.param.canSubWindow as boolean,
        isPop: (this.agendaTransitionUtil.param.isPop ?? false) as boolean
      })
    }
    .geometryTransition(this.agendaTransitionUtil.geometryId)
    // 添加编辑页出现和消失的透明度动画
    .transition(this.agendaTransitionUtil.needAnimation ? TransitionEffect.asymmetric(
      TransitionEffect.opacity(0.99),
      TransitionEffect.opacity(0.8).animation({ duration: 275 }).combine(
        TransitionEffect.opacity(0).animation({ duration: 75, delay: 275 })).combine(
        TransitionEffect.opacity(0).animation({ duration: 325, delay: 350 }))
    ) : TransitionEffect.OPACITY.animation({ duration: 0 }))
    // 要实现圆角的一镜到底，需要对编辑页加clip
    .clip(true)
    .justifyContent(FlexAlign.Center)
    .borderRadius(this.agendaTransitionUtil.editPageBorderRadius)
  }

  build() {
      NavDestination() {
        CalendarSideBarContainer({
          showSearch: this.showSearch,
          displayDate: this.displayDate,
          hideMenu: this.hideMenu,
          statusBarHeight: this.windowAvoidAreaTopRectHeight + (this.layout.menuBarHeight - 40) / 2, // 40为button大小
        }) {
          Column() {
            // 断点虚拟节点
            MainPageVirtualGrid()
            // 系统状态栏占位
            Row()
              .size({
                width: '100%',
                height: this.windowAvoidAreaTopRectHeight + (this.hideMenu ? 0 : this.layout.tabViewOffsetY)
              })
            Column() {
              DateTitle({
                dateTitleText: this.getDateTitleText(),
                tabsIndex: this.tabsIndex,
                textHeight: this.layout.menuBarHeight,
                needPadding: this.layout.stack,
                marginTop: this.buttonTopHeight,
                hideMenu: this.hideMenu,
                marginBottom: 4,
              })
            }
            .position({
              start: LengthMetrics.vp((this.isShowLeftBar && !this.sideBarOverlay) ? 0 : this.layout.dateTitleOffsetX),
              top: LengthMetrics.vp(this.windowAvoidAreaTopRectHeight + this.layout.dateTitleOffsetY)
            })
            .zIndex(3) // 保持在按钮z序之上用于触发点击事件
            .onClick(() => {
              if (this.tabsIndex === TabType.MONTH) {
                this.showJumpToSomedayHandler();
              }
            })
            .accessibilityDescription(this.getDateTitleAccessibilityDescription())
            .accessibilityText(this.getDateTitleAccessibilityText());
            this.buildMenu();
            SlideTabBar({
              tabBarHeight: this.layout.menuBarHeight,
              widthLimitType: this.layout.widthLimitType,
              innerWidth: this.windowWidth,
              stack: this.layout.stack
            })
            MainTabComponent()
        }
        .accessibilityLevel((this.isShowLeftBar && this.sideBarOverlay) || this.showSearch ? 'no-hide-descendants' : 'no')
        .size({ width: '100%', height: '100%' })
      }

        this.buildMask()
        this.buildSearch()
      }
      .id(CompId.MAIN_PAGE_NAV_DESTINATION)
      .keyboardShortcut('n', [ModifierKey.CTRL], () => {
        Log.info(TAG, 'Press Ctrl + n, Create Agenda');
        let eventData: emitter.EventData = {
          data: {
            'tabIndex': this.tabsIndex,
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
        switch (this.tabsIndex) {
          case TabType.YEAR: {
            ReportUtil.reportStatisticEvent(statisticEvents.yearGoToCreateAgenda);
            break;
          }
          case TabType.MONTH: {
            ReportUtil.reportStatisticEvent(statisticEvents.monthGoToCreateAgenda);
            break;
          }
          case TabType.WEEK: {
            ReportUtil.reportStatisticEvent(statisticEvents.weekGoToCreateAgenda);
            break;
          }
          case TabType.DAY: {
            ReportUtil.reportStatisticEvent(statisticEvents.dayGoToCreateAgenda);
            break;
          }
          default:
            break;
        }
      })
      .onShown(() => this.viewProxy.onShown())
      .onHidden(() => this.viewProxy.onHidden())
      .onBackPressed(() => this.onBackPress())
      .backgroundColor($r('sys.color.background_secondary'))
      .hideTitleBar(true)
      .bindContentCover(this.agendaTransitionUtil.isEditPageShow, this.buildAgendaDetail(), {
        modalTransition: ModalTransition.NONE,
        // 添加onDisappear以实现侧滑退出的逻辑，否则侧滑后会有问题
        onDisappear: () => {
          // 判断此次退出是否为切换小屏退出
          const isModeChange = ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode);
          const isPop = this.agendaTransitionUtil.param.isPop ?? false;
          this.agendaTransitionUtil.onBackClicked(!isPop, isModeChange, !isPop);
          // renderGroup会导致一镜到底退出时的抖动动效存在问题,需要暂时关闭renderGroup
          this.isMaximizeRecovery = true;
          ThrottleFunction.instance().debounce(TAG, () => {
            this.isMaximizeRecovery = false;
          }, AgendaTransitionUtil.ANIMATE_TOTAL_TIME);
        },
        onWillDismiss: (dismiss) => {
          Log.info(TAG, 'Agenda Detail Cover Page Is About To Dismiss.');
          if (AppStorage.get('isInCopy')) {
            // 模态转场阻止侧滑关闭
            AppStorage.setOrCreate('isInCopy', false);
          } else {
            emitter.emit({ eventId: CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER }); // 通知全部日程、搜索日程页面重新获焦
            dismiss.dismiss();
          }
        }
      })
  }

  reportRecessStatistic() {
    let params: ReportHiEventParams = {
      IS_ON: this.isRecessToggleOn ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE
    }
    ReportUtil.reportStatisticEvent(statisticEvents.mainPageReportRecessState, params)
  }

  // 尝试接续

  tryAppContinue(data: emitter.EventData): void {
    Log.info(TAG, `tryAppContinue`);
    let continuePage = AppContinueManager.getInstance().getContinuePage(ContinueType.RECEIVE);
    if (continuePage == undefined) {
      Log.info(TAG, `tryAppContinue continuePage undefined`);
      return;
    }
    if (continuePage.pageName === NavPathName.AGENDA_DETAIL ||
      continuePage.pageName === NavPathName.AGENDA_LIST) {
      Log.info(TAG, `tryAppContinue on target`);
      if (continuePage.event == undefined) {
        return;
      }
      const param: Record<string, number | string | undefined | AgendaEventInfo> = {};
      param.id = continuePage.event.mId;
      param.holidayInfo = continuePage.event;
      param.instanceStartMills = continuePage.event.mBegin;
      param.instanceEndMills = continuePage.event.mEnd;
      AppContinueManager.getInstance().removeContinuePage(continuePage.pageName, ContinueType.RECEIVE);
      this.navPathStack.clear(false);
      // PC接续打开详情子窗
      if (this.needCommerce && continuePage.pageName === NavPathName.AGENDA_DETAIL) {
        AgendaAbilityManager.getInstance().startAbilityByEventId(continuePage.event.mId,
          continuePage.event.mBegin, continuePage.event.mEnd);
        return;
      }
      NavPathManager.getInstance().pushPath({
        builderName: continuePage.pageName,
        routerName: RouterName.ENTRY_HAP,
        param: param,
        animated: false
      });
    }
  }

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.mainPageAppear, 0);
    GlobalData.instance().initLanguageAndDate();
    // 查询月视图swiper三个月的日程数据
    this.getMonthlyAgenda();
    this.initParam();
    this.registerListener();
    this.viewProxy.aboutToAppear();
    // 维测用,用于判断是否创建了两个不同的页面
   // this.viewId = this.getUniqueId();
    Log.info(TAG, `aboutToAppear check ${this.viewId}`);
    let tempParameters = this.getParameters();
    this.parseWantParams(tempParameters ? tempParameters.action as ActionType : undefined, tempParameters);
    this.subscribeEvents();
    this.emitterForm();
    this.reportRecessStatistic();
    let bp = MainPageLayoutManager.getInstance().bp;
    const reg: RegExp = new RegExp('lg|xl', 'g');
    if (reg.test(bp)) {
      ReportUtil.reportBehaviorEvent(behaviorEvents.landscapeScreenClickDeskIcon);
    }
    setTimeout(() => {
      this.periodicReportAgenda();  // 延时1s统计点位，不影响冷启动
    }, 1000)
    this.syncBirthDayData();
    this.initDeleteService();
    CalendarCacheService.getInstance().tryInitDbRepairSwitch();
    hiTraceMeter.finishTrace(traceEvents.mainPageAppear, 0);
  }

  private getParameters(): ParametersInter | undefined {
    try {
      let temp: Object | undefined = GlobalThis.getInstance().abilityWant?.parameters;
      return temp ? temp as ParametersInter : undefined;
    } catch (e) {
      Log.logErrorMsg(TAG, `get parameters error `, e);
      return undefined;
    }
  }

  private getDateTitleAccessibilityDescription(): string {
    return this.tabsIndex === TabType.MONTH ? barText($r('app.string.double_click_finger_execute')) : ' ';
  }

  private getDateTitleAccessibilityText(): string {
    if (this.tabsIndex === TabType.MONTH) {
      return GlobalThis.getResourceStr($r('app.string.click_date_hit_text'))
        .replace('%s', this.getDateTitleText().toString());
    }
    return barText(this.getDateTitleText());
  }

  /**
   * 事件监听
   */
  private subscribeEvents(): void {
    this.timeChangeHandler = (): void => {
      this.subscribeCallBack();
    };
    this.windowStatusChangeHandler = (data: emitter.EventData) => this.onWindowStatusChange(data);
    this.deleteAgendaHandler = (data: emitter.EventData) => this.deleteEvent(data);
    this.copyAgendaHandler = (data: emitter.EventData) => this.copyEvent(data);
    this.appContinueHandler = (data: emitter.EventData) => this.tryAppContinue(data);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.timeChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_TICK }, this.timeChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_MAXIMIZE_RECOVERY }, this.windowStatusChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_DB_EXCEPTION }, this.dbExceptionHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.DELETE_AGENDA }, this.deleteAgendaHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.COPY_AGENDA }, this.copyAgendaHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SHARE_AGENDA }, this.shareAgendaHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.APP_CONTINUE }, this.appContinueHandler);
    if (this.keyboardSwitchingDate) {
      this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_UP_OR_LEFT }, this.pressLeftOrUp);
      this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_DOWN_OR_RIGHT }, this.pressRightOrDown);
    }
  }

  /**
   * 取消事件监听
   */
  private unsubscribeEvents(): void {
    try {
      this.emitterCollector.off();
    } catch (err) {
      Log.logErrorMsg(TAG, `unsubscribeEvents`, err);
    }
  }

  private async periodicReportAgenda() {
    const now = Date.now();
    const lastTime: number = await PreferencesUtil.getNumberValue(PreferencesFiles.REPORT_AGENDA_LAST_TIME, 'Report_Agenda_Last_Time');
    if((now - lastTime) > MILLS_PER_WEEK) { // 距离上次打点超过一周则需要重新打点
      const eventIds = await EventService.INSTANCE.queryAllEvents();
      let params: ReportHiEventParams = {
        TOTAL_AGENDA_NUMBER: eventIds.length
      }
      ReportUtil.reportStatisticEvent(statisticEvents.periodicReportAgenda, params);
      PreferencesUtil.putNumberValue(PreferencesFiles.REPORT_AGENDA_LAST_TIME, 'Report_Agenda_Last_Time', now);
    }
  }

  getMonthlyAgenda() {
    // 查询日程数据
    const displayDate: CalendarDate = new CalendarDate(new Date().getTime());
    const dateInfo = new DateInfo(displayDate.getFullYear(), displayDate.getMonth() + 1);
    const curMonthlyInfo = new MonthlyInfo(dateInfo.year, dateInfo.month,
      MonthlyViewStateManager.getInstance().state.startOfWeek);

    this.getCurrentMonthAgenda(curMonthlyInfo.getLast(), 0);
    this.getCurrentMonthAgenda(curMonthlyInfo, 1);
    this.getCurrentMonthAgenda(curMonthlyInfo.getNext(), 2);
  }

  async getCurrentMonthAgenda(curMonthlyInfo: MonthlyInfo, index: number) {
    const tmpAgendaData = MonthlyViewTemporaryAgendaData.getInstance();
    tmpAgendaData.agendaList[index] = await SingleMonthAgendaManager.queryAndProcessAgendaData(curMonthlyInfo);
    tmpAgendaData.flagList[index] = true;
  }

  private async initDeleteService() {
    this.agendaDeleteService = await ServiceManager.getInstance().
    getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.unsubscribeEvents();
    ViewCallInterceptorHolder.getInstance().removeBackPressInterceptor(this.backPressInterceptor);
    this.jumpToSomedayDialogController = null;
  }

  // harden热起用,重置参数
  initParam() {
    // 初始化加载mainPageLayout的高宽
    MainPageLayoutManager.getInstance().init(this.windowWidth, this.windowHeight);
    this.sideBarOverlay = MainPageLayoutManager.getInstance().sidebarLayout.sideBarOverlay; // 侧边栏样式控制
    // 仅嵌入式侧边栏需要恢复记忆上一次操作
    this.isShowLeftBar = this.sideBarOverlay ? !this.sideBarOverlay :
      PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT, SIDE_BAR_SHOW_USER, !this.sideBarOverlay);
    this.sidebarVisible = this.isShowLeftBar;
    this.maskPosX = 0;
    this.hideAgendaWindowMonth = PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT,
      TabType.MONTH + GlobalDataKeys.TAB_INDEX, false); // 月视图是否隐藏日程列表
    this.hideAgendaWindowDay = PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT,
      TabType.DAY + GlobalDataKeys.TAB_INDEX, false); // 日视图是否隐藏日程详情
  }

  /**
   * 从缓存中获取tab页签索引值
   */
  getTabIndexFromStorage(): number {
    let tabIndex: number = TabType.MONTH;
    if (this.tabIndexPreferences) {
      tabIndex = Number(this.tabIndexPreferences.getSync("tabIndex", TabType.MONTH));
    }
    return tabIndex; // 缓存中取出来的是字符串
  }

  /**
   * 获取tab页签值
   */
  async getTableIndex(): Promise<number> {
    let tabIndex: Object | undefined = this.tabsIndex.toString() ? this.tabsIndex :
      GlobalThis.getInstance().abilityWant?.parameters?.tabIndex;
    if (!this.tabIndexPreferences) {
      const context = GlobalThis.getInstance().context;
      if (context) {
        try {
          this.tabIndexPreferences = await data_preferences.getPreferences(context, 'tabIndex');
        } catch (err) {
          Log.logErrorMsg(TAG, `getTableIndex: data_preferences get failed, error message: ${err.message}}`);
        }
      }
    }
    if (tabIndex === undefined) {
      tabIndex = this.getTabIndexFromStorage();
    }
    Log.info(TAG, 'getTableIndex tabIndex: ' + tabIndex);
    return Number(tabIndex);
  }

  async getTableIndexFromCard(): Promise<number> {
    let tabIndex: Object | undefined = GlobalThis.getInstance().abilityWant?.parameters?.tabIndex;
    if (!this.tabIndexPreferences) {
      try {
        this.tabIndexPreferences = await data_preferences.getPreferences(GlobalThis.getInstance()
          .context as Context, 'tabIndex');
      } catch (err) {
        Log.logErrorMsg(TAG, `getTableIndex: data_preferences get failed, error message: ${err.message}}`);
      }
    }
    if (tabIndex === undefined) {
      tabIndex = this.getTabIndexFromStorage();
    }
    Log.info(TAG, 'getTableIndexFromCard tabIndex: ' + tabIndex);
    return Number(tabIndex);
  }

  /**
   * 监听事件
   */
  emitterForm() {
    const innerEvent: emitter.InnerEvent = {
      eventId: CommonInnerEvent.EVENT_FORM
    };
    this.eventFormHandler = () => {
      Log.log(TAG, 'emitterForm success');
      const temp: Want | null = GlobalThis.getInstance().abilityWant;
      if (temp && temp.parameters) {
        this.parseWantParams(temp.parameters.action as ActionType, temp.parameters as Object as ParametersInter);
      }
    };
    this.emitterCollector.on(innerEvent, this.eventFormHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.calendarChangeHandler);
  }

  changeShowLeftButtonByAnimate(isShow: boolean): void {
    this.sidebarVisible = isShow;
    animateToImmediately({
      duration: 300,
      curve: Curve.Smooth,
      onFinish: () => {
        this.sidebarVisible = isShow;
      }
    }, () => {
      this.isShowLeftBar = isShow;
      this.maskPosX = isShow ? this.sidebarWidth : 0;
      Log.info(TAG, `isShowLeftBar button click ${this.isShowLeftBar}`);
    });
  }

  /**
   * 跳转到月视图
   *
   * @param parameters want参数
   */
  private async jumpToMonth(parameters: ParametersInter | undefined): Promise<boolean> {
    if (!parameters) {
      return false;
    }

    this.navPathStack.clear(false);
    this.reportFaGoToMonthView(parameters.faType);
    const currentDate = new CalendarDate();
    const year = parameters.year !== undefined ? parameters.year : currentDate.getFullYear();
    const month = parameters.month !== undefined ? parameters.month : currentDate.getMonth();
    const day = parameters.day !== undefined ? parameters.day : currentDate.getDate();
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, DateUtil.dateToStamp(year, month, day));

    const jumpExtAction = parameters?.jumpExtAction;
    Log.info(TAG, `jumpToMonth, jumpExtAction ${jumpExtAction}`);
    if (jumpExtAction === JumpExtActionType.OPEN_CREATE_SCHEDULE_SHEET) {
      // 打开课表创建弹窗
      Log.info(TAG, `jumpToMonth, jumpExtAction > action ${jumpExtAction}`);
      SafeUtil.setTimeout(() => {
        this.changeShowLeftButtonByAnimate(true);
        emitter.emit({ eventId: CommonInnerEvent.EVENT_ADD_SCHEDULE_PAGE_OPEN });
      }, 500);
    }
    // 额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    const tableIndex = await this.getTableIndexFromCard();
    const eventData: emitter.EventData = { data: { "tabIndex": tableIndex, } };
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData)
    return true;
  }

  /**
   * 解析want携带的数据
   *
   * @param action 自定义action
   * @param parameters want参数
   */
  async parseWantParams(action: ActionType | undefined, parameters: ParametersInter | undefined): Promise<void> {
    Log.info(TAG, `form event action: ${action}`);
    if (this.tryHandleShare(GlobalThis.getInstance().abilityWant)) {
      return;
    }
    // ShareKit 注释 - start
    // if (this.tryHandleFileShare()) {
    //   return;
    // }
    // ShareKit 注释 - end
    if (await this.jumpToAgendaDetail(GlobalThis.getInstance().abilityWant)) {
      return;
    }
    switch (action) {
      case 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW': {
        if (!parameters || !parameters.startTimestamp) {
          Log.error(TAG, 'parameters is Illegal! Pay Attention To Source Date In Agenda Preview!');
          break;
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.clickPreviewJumpToCalendar);
        let timeStamp = Number.parseInt(parameters.startTimestamp);
        if (new CalendarDate(AGENDA_SEARCH_DATE_BEGIN).getTime() > timeStamp ||
          new CalendarDate(AGENDA_SEARCH_DATE_END).getTime() < timeStamp) {
          Log.info(TAG, 'jump by preview timeStamp exceeding the time limit ')
          timeStamp = Date.now();
        }
        const desDate = new CalendarDate(timeStamp);
        parameters.year = desDate.getFullYear();
        parameters.month = desDate.getMonth();
        parameters.day = desDate.getDate();
        if (await this.jumpToMonth(parameters)) {
          Log.warn(TAG, 'parameters! Pay Attention To Source Date In Agenda Preview!');
          return;
        }
        break;
      }
      case 'CLICK_MONTH_FORM_HEADER': {
        if (!parameters) {
          Log.error(TAG, 'parameters is Illegal! Pay Attention To Source Date!');
          break;
        }
        if (await this.jumpToMonth(parameters)) {
          Log.warn(TAG, 'parameters! Pay Attention To Source Date!');
          return;
        }
        break;
      }
      case 'CLICK_AGENDA_DETAIL': {
        Log.info(TAG, 'CLICK_AGENDA_DETAIL');
        const action: string | undefined = parameters?.action;
        const id: number | undefined = parameters?.id;
        const instanceStartMills: number | undefined = parameters?.instanceStartMills;
        const calendarType: string | undefined = parameters?.calendarType;
        if (id === undefined || id <= 0) {
          // eventId 为默认值 或 无法识别 则不带数据跳转到默认的日程列表
          Log.error(TAG, 'eventId is undefined or eventId <= 0!');
          this.jumpAgendaList();
          return;
        }
        if (calendarType === CalendarContract.CalendarType.BIRTHDAY) { // 卡片跳转联系人生日
          break;
        }
        const dimension: string | undefined = parameters?.dimension;
        const faType: string | undefined = parameters?.faType;
        Log.info(TAG, 'const { action, id } = parameters ' + action + id);
        const param: Record<string, number | string | AgendaEventInfo | undefined> = {};
        param.action = action;
        param.id = id;
        param.instanceStartMills = instanceStartMills;
        if (faType === CARD_IMPORTANT) {
          param.fromType = FromType.IMPORTANT_FA;
        }
        if (parameters?.holidayInfo) {
          param.holidayInfo = JSON.parse(parameters.holidayInfo)
        }
        param.instanceEndMills = parameters?.instanceEndMills;
        this.reportFaGoToAgendaDetail(dimension, faType)
        // 检查 path 堆栈中栈顶是不是 AGENDA_DETAIL
        let pathNames = this.navPathStack.getAllPathName();
        if (pathNames.length > 0) {
          let topPathName = pathNames[pathNames.length - 1]
          // 如果是栈顶是AGENDA_DETAIL，不再PUSH
          if (topPathName === NavPathName.AGENDA_DETAIL) {
            emitter.emit({ eventId: CommonInnerEvent.EVENT_FORM_DETAIL }, param)
            break;
          }
        }
        this.navPathStack.clear(false);
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_DETAIL,
          routerName: RouterName.ENTRY_HAP,
          param: param,
          animated: false
        });
        break;
      }
      case 'CLICK_CREATE_EVENT': {
        Log.info(TAG, 'CLICK_CREATE_EVENT');
        ReportUtil.reportStatisticEvent(statisticEvents.agendaFaGoToCreateAgenda)
        let eventData: emitter.EventData = {
          data: {
            'action': action,
            'oneSentenceCreate': true
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
        this.initCreateAgenda = true;
        break;
      }
      case 'SHARE_PUSH': {
        Log.info(TAG, 'SHARE_PUSH');
        const permission = await checkReadContactPermission();
        if (parameters && permission) {
          this.onReceivePush();
        }
        break;
      }
      default:
        break;
    }
    const tabIndex: number = await this.getTableIndex();
    const eventData: emitter.EventData = { data: { "tabIndex": tabIndex, } };
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData);
  }

  // todo Delete
  reportFaGoToAgendaDetail(dimension: string | undefined, faType: string | undefined) {
    let fa_dimension = FormDimension.Dimension_2_2
    if (dimension === '2x4') {
      fa_dimension = FormDimension.Dimension_2_4
    } else if (dimension === '4x4') {
      fa_dimension = FormDimension.Dimension_4_4
    } else if (dimension === '6x4') {
      fa_dimension = FormDimension.DIMENSION_6_4
    }
    let params: ReportHiEventParams = {
      FA_DIMENSION: fa_dimension
    }
    if (faType === 'agenda_fa') {
      ReportUtil.reportStatisticEvent(statisticEvents.agendaFaViewAgendaDetail, params)
    } else if (faType === CARD_IMPORTANT) {
      ReportUtil.reportStatisticEvent(statisticEvents.importantFaViewAgendaDetail, params)
    }
  }

  async onReceivePush() {
    Log.info(TAG, 'on receive push notification');
    let userMessage: UserMessageSdsBean = {} as UserMessageSdsBean;
    let messageWant = GlobalThis.getInstance().abilityWant;
    if (!messageWant?.parameters) {
      return;
    }
    if (this.syncSwitchStatus != SWITCH_ON) {
      this.shareSwitchDialogController?.open();
      return;
    }
    userMessage.messageId = messageWant?.parameters.messageId as string;
    userMessage.resourceId = messageWant?.parameters.resourceId as string;
    userMessage.status = messageWant?.parameters.status as number;
    userMessage.messageTemplateKey = messageWant?.parameters.messageTemplateKey as string;
    userMessage.messageParam = messageWant?.parameters.messageParam as object;
    userMessage.messageType = messageWant?.parameters.messageType as string;
    userMessage.recordTime = messageWant?.parameters.recordTime as number;
    userMessage.ttl = messageWant?.parameters.ttl as number;
    // 裁剪日程共享功能 - 注释掉消息处理逻辑
    // const param: Record<string, string> = {};
    // const messageStruct = await MessageExternalController.getInstance().coverUserMessageToMessageStruct(userMessage);
    // param.message = JSON.stringify(messageStruct);
    // param.source = ClickSource.MAIN_PAGE;
    // if (messageStruct?.shareType === ShareTypeEnum.AGENDA) {
    //   NavPathManager.getInstance().pushPath({
    //     builderName: NavPathName.SHARE_AGENDA,
    //     routerName: RouterName.ENTRY_HAP,
    //     param: param
    //   }
    //   );
    // } else if (messageStruct?.shareType === ShareTypeEnum.ACCOUNT) {
    //   NavPathManager.getInstance().pushPath({
    //     builderName: NavPathName.SHARE_ACCOUNT,
    //     routerName: RouterName.ENTRY_HAP,
    //     param: param
    //   }
    //   );
    // }
  }

  onPageHide() {
    this.viewProxy.onPageHide()
  }

  onBackPress(): boolean {
    Log.info(TAG, "onBackPress");
    if (this.showSearch) {
      this.showSearch = false;
      return true;
    }
    if (this.isShowLeftBar && this.sideBarOverlay) {
      this.closeSideBarAnimate()
      return true;
    }

    GlobalData.instance().set(GlobalDataKeys.IS_SLIDE_SLIP_BACK, true);

    return false;
  }

  closeSideBarAnimate() {
    animateTo({
      duration: 300,
      curve: Curve.Smooth,
      onFinish: () => {
        ThrottleFunction.instance().debounce(SIDEBAR_VISIBLE_TAG, () => {
          this.sidebarVisible = false;
        }, 400);
      }
    }, () => {
      this.isShowLeftBar = false;
      this.maskPosX = 0;
      PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT, SIDE_BAR_SHOW_USER, false);
    });
  }

  //时间变化响应事件
  private timeChangeHandler: () => void = (): void => {
  };

  // 处理窗口最大化恢复
  private windowStatusChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private dbExceptionHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private copyAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private deleteAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private appContinueHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private calendarChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.onCalendarChange(data);
  };

  async onCalendarChange(data: emitter.EventData) {
    if (data?.data?.table !== 'Calendars') {
      return;
    }
    let accounts = await CalendarService.INSTANCE.queryCalendarList();
    await GlobalData.instance().setBirthDayAccountId(accounts);
  }

  private readonly backPressInterceptor: BackPressInterceptor = (): boolean => {
    return this.onBackPress();
  }

  private async syncBirthDayData() {
    const accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    GlobalData.instance().setBirthDayAccountId(accounts);
  }

  private registerListener() {
    ViewCallInterceptorHolder.getInstance().addBackPressInterceptor(this.backPressInterceptor);
  }

  private reportFaGoToMonthView(faType: string) {
    let params: ReportHiEventParams = {};
    switch (faType) {
      case 'AgendaCard2x2':
        params.TYPE = CardType.AGENDA_CARD_2X2;
        break;
      case 'AgendaCard2x4':
        params.TYPE = CardType.AGENDA_CARD_2X4;
        break;
      case 'AgendaCard4x4':
        params.TYPE = CardType.AGENDA_CARD_4X4;
        break;
      case 'AgendaCard4x6':
        params.TYPE = CardType.AGENDA_CARD_4X6;
        break;
      case 'MonthCard2x2':
        params.TYPE = CardType.MONTH_CARD_2X2;
        break;
      case 'MonthCard4x4':
        params.TYPE = CardType.MONTH_CARD_4X4;
        break;
      default:
        break;
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.clickCardGoToMonth, params);
  }

  private tryHandleShare(abilityWant: Want | null): boolean {
    if (!abilityWant) {
      Log.warn(TAG, `tryHandleShare abilityWant is null`);
      return false;
    }
    if (!abilityWant.uri) {
      Log.warn(TAG, `tryHandleShare abilityWant uri null`);
      return false;
    }
    if (!abilityWant.uri.endsWith('.ics') && !abilityWant.uri.endsWith('.vcs')) {
      Log.warn(TAG, `tryHandleShare uri is neither ics nor vcs`);
      return false;
    }
    Log.info(TAG, `tryHandleShare: uri is ics or vcs, handling required`);
    this.doImport(abilityWant.uri);
    return true;
  }

  // ShareKit 注释 - start
  // private tryHandleFileShare(): boolean {
  //   const abilityWant = GlobalThis.getInstance().shareData;
  //   if (!abilityWant) {
  //     Log.warn(TAG, `tryHandleFileShare abilityWant is null`);
  //     return false;
  //   }
  //   GlobalThis.getInstance().shareData = null;
  //   const records = abilityWant.getRecords();
  //   if (!records || records.length === 0) {
  //     Log.warn(TAG, `tryHandleFileShare abilityWant records are null or empty`);
  //     return false;
  //   }
  //   const uris = records.map(record => record.uri);
  //   if (!uris[0]) {
  //     Log.warn(TAG, `tryHandleFileShare abilityWant uri null`);
  //     return false;
  //   }
  //   if (!uris[0].endsWith('.ics') && !uris[0].endsWith('.vcs')) {
  //     Log.warn(TAG, `tryHandleFileShare uri is neither ics nor vcs`);
  //     return false;
  //   }
  //   Log.info(TAG, `tryHandleFileShare: uri is ics or vcs, handling required`);
  //   this.doImport(uris[0]);
  //   return true;
  // }
  // ShareKit 注释 - end

  private async doImport(uri: string) {
    let service = await ServiceManager.getInstance()
      .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
    service?.import(uri, ImportVcsCallBack.getInstance())
  }

  /**
   * 尝试解析通知里的Uri 跳转到日程详情,目前不支持循环日程,需要通知代理处理
   * calendar://com.openharmony.calendar?event_id=${notificationInfo.eventId}
   * @param abilityWant
   * @return 是否处理 abilityWant
   */
  private async jumpToAgendaDetail(abilityWant: Want | null): Promise<boolean> {
    if (!abilityWant?.uri || EmptyUtils.isEmptyString(abilityWant?.uri, true)) {
      return false;
    }
    try {
      const agendaUri: uri.URI = new uri.URI(abilityWant?.uri);
      // calendarDate 通知里的uri 的协议格式
      if ('calendar' != agendaUri.scheme || 'com.openharmony.calendar' != agendaUri.host) {
        return false;
      }
      const urlParams: string[] = agendaUri.query.split('&');
      const jumpParam: Record<string, number | string> = {};
      this.parseParams(urlParams, jumpParam);

      return await this.jumpAgendaDetail(jumpParam);
    } catch (err) {
      Log.logErrorMsg(TAG, `JumpToAgendaDetail uri is ${abilityWant?.uri} illeagl`, err);
      return false;
    }
  }

  private parseParams(urlParams: string[], jumpParam: Record<string, number | string>): void {
    if (EmptyUtils.isEmptyArray(urlParams)) {
      return;
    }
    for (let element of urlParams) {
      const keyValue: string[] = element.split('=');
      if (EmptyUtils.isEmptyArray(keyValue) || keyValue.length <= 1) {
        continue;
      }
      const key = keyValue[0];
      const value = keyValue[1];
      switch (key) {
        case DETAIL_WANT_PARAM_ID:
          Log.info(TAG, `parseParams eventId is ${keyValue[1]}`);
          jumpParam.id = Number.parseInt(value);
          break;
        case DETAIL_WANT_PARAM_START_TIME:
          jumpParam.instanceStartMills = Number.parseInt(value);
          break;
        case DETAIL_WANT_PARAM_END_TIME:
          jumpParam.instanceEndMills = Number.parseInt(value);
          break;
        case 'scheduleUuid':
          jumpParam.scheduleUuid = value;
          break;
        case 'targetTime':
          jumpParam.targetTime = Number.parseInt(value);
          break;
        case 'courseInstanceUuid':
          jumpParam.courseInstanceUuid = value;
          break;
        default:
          Log.info(TAG, `parseParams get unknown key ${key}`);
          break;
      }
    }
  }

  private async jumpAgendaDetail(jumpParam: Record<string, number | string>): Promise<boolean> {
    if (!jumpParam.id) {
      return false;
    }
    // 裁剪日程共享功能 - 直接跳转到普通日程详情
    return this.jumpCustomAgenda(jumpParam);
  }

  private jumpCustomAgenda(jumpParam: Record<string, string | number>): boolean {
    let page = AppContinueManager.getInstance().getContinuePage();
    if (page?.pageName === NavPathName.AGENDA_DETAIL && page.event?.mId === jumpParam.id) {
      Log.info(TAG, `same event id`);
      return true;
    }
    emitter.emit({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG });
    NavPathManager.getInstance().replacePathByName({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: jumpParam
    }, false);
    ReportUtil.reportBehaviorEvent(behaviorEvents.notificationGoToAgendaDetail);
    Log.info(TAG, 'send to agenda detail');
    return true;
  }

  /**
   * 跳转到日程列表
   * @returns 是否流程执行完毕
   */
  private jumpAgendaList(): boolean {
    const param: Record<string, number | string | AgendaEventInfo | undefined> = {};
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.AGENDA_LIST,
      routerName: RouterName.ENTRY_HAP,
      param: param,
      animated: false
    });
    Log.info(TAG, 'send to Default agenda detail');
    return true;
  }

  private onWindowStatusChange(data: emitter.EventData): void {
    if (data.data?.isMaximizeRecovery) {
      const isMaximizeRecovery: boolean = data.data.isMaximizeRecovery;
      ThrottleFunction.instance().debounce(TAG, () => {
        this.isMaximizeRecovery = isMaximizeRecovery;
      }, 0)
    }
  }

  private deleteEvent(data: emitter.EventData): void {
    let eventId: number | undefined = data.data?.eventId;
    let deleteTimestamp: number | undefined = data.data?.timestamp;
    let isMainAbility: boolean | undefined = data.data?.isMainAbility ?? true;
    // deleteTimestamp 用于删除重复日程的重复规则,isMainAbility判断是否在mainAbility发起
    if (eventId == undefined || deleteTimestamp == undefined || !isMainAbility) {
      return;
    }
    EventService.INSTANCE.queryEventById(eventId).then(async (event) => {
      if (event) {
        let accounts = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
        let accountMap = CommonService.INSTANCE.getAccountMap(accounts);
        this.deleteAccountType = accountMap.get(event.mCalendarId).accountType;
        this.deleteAgenda = event;
        this.deleteTimestamp = deleteTimestamp||0;
        Log.info(TAG, `delete agenda ${this.deleteAgenda.mId}-${this.deleteTimestamp}-${this.deleteAccountType}`);
        if (event.isRepeatEvent() && !event.isImportantEvent()) {
          this.deleteRepeatAgendaDialogController?.open();
        } else {
          this.deleteDialogController?.open();
        }
      }
    })
  }
  private copyEvent(data: emitter.EventData): void {
    let eventId: number | undefined = data.data?.eventId;
    if (!eventId) {
      return;
    }
    CopyHelper.instance().copyEventInfo(eventId);
  }

  // 分享日程监听逻辑
  private shareAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const compId: string = data?.data?.compId;
    const eventIds: number[] = data?.data?.eventIds;
    if (compId && eventIds && eventIds.length > 0) {
      GlobalThis.getInstance().shareAnchorViewId = compId;
      // ShareKit 注释 - start
      // if (data?.data?.comeFormAgendaBlock) {
      //   const agendaBlockShareParam = MonthViewAgendaBlockShareParam.getInstance();
      //   agendaBlockShareParam.shareAnchorX = data?.data?.popPos.windowOffset.x;
      //   agendaBlockShareParam.shareAnchorY = data?.data?.popPos.windowOffset.y;
      //   agendaBlockShareParam.comeFormAgendaBlock = true;
      //   agendaBlockShareParam.agendaBlockWidth = data?.data?.agendaBlockWidth;
      // }
      // ShareKit 注释 - end
      ServiceManager.getInstance().getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE)
        .then(service => {
          const isBatch = eventIds.length > 1;
          service?.exportVcsByEvents(eventIds, new ExportVcsCallBack(), isBatch);
        });
    } else {
      Log.error(TAG, 'shareAgendaHandler compId or eventId is null');
    }
  };

  // 键盘事件 方向键 右或下
  private pressRightOrDown: () => void = (): void => {
    ThrottleFunction.instance().throttle(TAG + 'pressRightOrDown', (): void => {
      emitter.emit({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, { data: { 'direction': 1 } });
    }, this.DELAY);
  };

  // 键盘事件 方向键 左或上
  private pressLeftOrUp: () => void = (): void => {
    ThrottleFunction.instance().throttle(TAG + 'pressLeftOrUp', (): void => {
      emitter.emit({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, { data: { 'direction': 0 } });
    }, this.DELAY);
  };
}

export interface ParametersInter {
  year: number;
  month: number;
  day: number;
  action: string | ActionType;
  id: number;
  faType: string;
  dimension: string;
  holidayInfo: string;
  instanceStartMills: number;
  instanceEndMills: number;
  calendarType: string | undefined;
  formId: string;
  uuid: string;
  jumpExtAction: JumpExtActionType | undefined;
  startTimestamp: string | undefined;
  targetTime: string | undefined;
}

interface UserMessageSdsBean {
  messageId: string;
  resourceId: string;
  status: number;
  messageTemplateKey: string;
  messageParam: object;
  messageType: string;
  recordTime: number;
  ttl: number;
  notifyId: number;
}