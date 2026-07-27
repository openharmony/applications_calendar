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

import { SingleMonthlyView } from './SingleMonthlyView';
import {
  AgendaAbilityManager,
  AgendaDeleteService,
  AgendaEventInfo,
  behaviorEvents,
  CalendarDate,
  CHINESE_HOLIDAY_STATE_VALUE,
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  EmptyUtils,
  EventService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  I18nUtil,
  Log,
  ModeUtil,
  NavPathManager,
  ReportUtil,
  RouterName,
  SafeUtil,
  ServiceEnum,
  ServiceManager,
  statisticEvents,
  TabType,
  ThrottleFunction,
  UnusualMode
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { MonthlyViewModel } from '../viewmodel/MonthlyViewModel';
import { WeekTitle } from './WeekTitle';
import { MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import emitter from '@ohos.events.emitter';
import { HiEventParamsConfirm, ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import lazy { prompt } from '@kit.ArkUI';
import { AgendaBlockInfo } from '../viewmodel/WeekAgendaBlockModel';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { LengthMetrics } from '@kit.ArkUI';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { DayCellLayout } from '../layoutmodel/DayCellLayoutRule';
import { WeekTitleLayout } from '../layoutmodel/WeekTitleLayoutRule';
import { WeekNumLayout } from '../layoutmodel/WeekNumLayoutRule';
import { FrameLayout, MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { CopyHelper, DeleteAgendaRadio, DeleteMode } from '@app/feature.agenda';
import { focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { PaintCache } from '@app/common/src/main/ets/graphic/PaintCache';
import { AgendaBlockStateManagement, WeekAgendaState } from '../viewmodel/WeekAgendaState';

const TAG: string = '[MonthlyView][MonthlyView]';

// 月视图日程块初始化状态
export enum AgendaBlockState {
  NOT_INIT, // 未初始化
  NOT_LOAD, // 已初始化但未加载
  IS_LOAD, // 已加载
}


/**
 * Monthly View
 * The Monthly view is a super-large component. When slide the view, the entire page cannot be redrawn.
 * @since 2023-08-16
 */
@Preview
@Component({ freezeWhenInactive: true })
export struct MonthlyView {
  @Consume navPathStack: NavPathStack;

  @StorageProp(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  @StorageProp('tabIndex') @Watch('onTabsIndexChange') tabsIndex: number = TabType.YEAR;

  // 一周起始日
  @StorageProp('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = 0;

  // 系统地区
  @StorageProp('systemRegion') @Watch('onSystemRegionChange') systemRegion: string = 'CN';

  // 显示/隐藏周数信息
  @StorageProp('showWeekNumber') @Watch('onShowWeekNumberChange') showWeekNumber: boolean = false;

  @Provide innerShowWeekNumber: boolean = this.showWeekNumber;

  // 显示/隐藏重要日
  @StorageLink(GlobalDataKeys.IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW) @Watch('onShowImportantDayChange') showImportantDay: boolean = false;

  @Provide innerShowImportantDay: boolean = this.showImportantDay;

  // 系统时间当天的时间戳，处理实时时间的变化，应用在mainPage接到 Time_tick 广播后会修改 currentDate
  @StorageProp(GlobalDataKeys.CURRENT_DATE) @Watch('onCurrentDateChange') currentDate: number = 0;

  // 周末
  @StorageLink('weekends') @Watch('onWeekendsChange') weekends: number[] = [-1];

  // 其它历法
  @StorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendar') subscriptionCalendar: number = -1;

  // 深色模式
  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  //中国节假日开关状态
  @StorageProp('CHINESE_HOLIDAY_STATE') @Watch('onChineseHolidayStateChange') chineseHolidayState:
    CHINESE_HOLIDAY_STATE_VALUE = AppStorage.get('CHINESE_HOLIDAY_STATE') ?? CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;

  // 是否是HiCar模式
  @StorageProp('unusualMode') @Watch('unusualModeOnChange') unusualMode: UnusualMode | undefined =
    AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  @Consume needShowHideButton: boolean; // 是否需要显示详情开合按钮

  private unusualModeOnChange() {
    const modeState = MonthlyViewStateManager.getInstance().modeState;
    const isInSmallFold =
      modeState.isInSmallFoldChange(ModeUtil.isSmallUpDownFoldMode(AppStorage.get(GlobalDataKeys.UNUSUAL_MODE)));
    modeState.isForceSmallChange(ModeUtil.isHiCarMode(AppStorage.get(GlobalDataKeys.UNUSUAL_MODE)));
    this.layoutModel.onModeChange();
    if (modeState.isForceSmall) {
      this.viewModel.restoreMonthShow();
    } else {
      this.viewModel.changeMonthShow(isInSmallFold);
    }
    if (isInSmallFold || modeState.isForceSmall) {
      this.rootLoaded = true;
    }

    this.layout.monthPaddingTop = isInSmallFold ? 0 : MonthStaticLayout.monthPaddingTop;
  }

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 显示隐藏日程列表
  @Consume @Watch('onAgendaListStateChange') hideAgendaWindowMonth: boolean;

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  @Consume monthAgendaViewAnimate: CombineAnimateParam;

  // 月视图绑定的视图模型
  @State viewModel: MonthlyViewModel = new MonthlyViewModel();

  // 选中日程块
  @Provide selectBlock: AgendaBlockInfo | undefined = undefined;

  // hover日程块
  @Provide hoverBlock: AgendaBlockInfo | undefined = undefined;

  // 是否弹窗右键菜单
  @Provide rightPop: boolean = false;

  @State rootLoaded: boolean = false;

  @State private cashedCount: number = 0;

  swipeCount: number = 3; // need move into view model in the future

  private weekState = MonthlyViewStateManager.getInstance().weekState;

  private agendaBlockState: AgendaBlockStateManagement = WeekAgendaState.getInstance().agendaBlockState;

  private viewId: number = 0; // 用于维测的页面id

  //删除窗口
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.delete_this_event_title'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        this.deleteEventById();
        this.reportPopupStatistic(this.selectBlock?.getInfo().mImportantEventType || 0, HiEventParamsConfirm.TRUE)
      },
      onCancelClick: () => {
        this.reportPopupStatistic(this.selectBlock?.getInfo().mImportantEventType || 0, HiEventParamsConfirm.FALSE)
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  // 删除重复日程弹框
  deleteRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DeleteAgendaRadio({
      confirm: (checkValue) => {
        if (checkValue === DeleteMode.ONLY_THIS_AGENDA) {
          this.viewModel.deleteThisAgenda(this.selectBlock);
        } else if (checkValue === DeleteMode.THIS_AND_FUTURE_AGENDA) {
          this.viewModel.deleteThisAgendaAndBeyond(this.selectBlock);
        } else {
          this.deleteEventById();
        }

        const params: ReportHiEventParams = {
          TYPE: this.selectBlock?.getInfo().mImportantEventType,
          DELETE_TYPE: checkValue
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDeleteType, params);
      },
      title: this.viewModel.getDeleteAgendaDialogTitle(this.selectBlock),
      isFirstRepeatAgenda: this.viewModel.isFirstRepeated
    }),
    alignment: DialogAlignment.Center,
  });

  //刷新视图用标志位
  private swiperFlag: boolean = false;

  // 月视图绑定的布局参数
  private layoutModel: MonthViewLayoutModel = MonthViewLayoutModel.getInstance();

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @Provide layout: FrameLayout = this.layoutModel.frameProp.value;

  @Provide dayCellLayout: DayCellLayout = this.layoutModel.dayLayout.value;

  @Provide weekTitleLayout: WeekTitleLayout = this.layoutModel.weekTitleProp.value;

  @Provide weekNumLayout: WeekNumLayout = this.layoutModel.weekNumProp.value;

  @Provide inSmallWindow: boolean = this.layout.isSmall;

  private swiperController: SwiperController = new SwiperController();

  private emitterCollector : EmitterCollector = new EmitterCollector();

  subscribeEvents(): void {
    const viewId = this.viewId;
    this.timeChangeHandler = (): void => {
      ThrottleFunction.instance().throttle(TAG + 'time', (): void => {
        this.onTimeChange();
      }, 200)
    }
    this.timeZoneChangeHandler = (): void => {
      ThrottleFunction.instance().throttle(TAG + 'timeZone', (): void => {
        this.onTimeZoneChange();
      }, 200)
    }
    this.dataChangeHandler = (data: emitter.EventData): void => {
      this.throttleToDataChange(data);
    };
    this.backToTodayHandler = (data: emitter.EventData): void => {
      Log.info(TAG, `now start back to today ${viewId}`);
      Log.info(TAG,
        'start back to today circleX ' + this.viewModel.singleMonthlyViewModels[this.viewModel.currentIndex].circleX +
          ' , circleY = ' + this.viewModel.singleMonthlyViewModels[this.viewModel.currentIndex].circleY);
      ThrottleFunction.instance().throttle(TAG + 'backToToday', (): void => {
        this.onBackToToday(data);
      }, 200)
    }
    this.displayDateHandler = (): void => {
      this.onDisplayDateChange();
    }
    this.swipeMainPageHandler = (data: emitter.EventData): void => this.onSwipeMainPage(data);
    this.jumpToSomedayHandler = (data): void => {
      if (!data || !data.data) {
        return;
      }
      this.viewModel.onJumpToSomeDay(data.data['dateTime'] ?? Date.now())
    }
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.timeChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.timeChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.timeZoneChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, this.backToTodayHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE }, this.displayDateHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, this.swipeMainPageHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, this.jumpToSomedayHandler);


    //键鼠操作增强
    this.keyEnterEventHandler = (): void => this.onKeyEventEnter();
    this.keyDelEventHandler = (): Promise<void> => this.onKeyEventDel();
    this.keyCopyEventHandler = (data: emitter.EventData): Promise<void> => this.onKeyEventCopy(data);
    this.keyPasteEventHandler = (data: emitter.EventData): Promise<void> => this.onKeyEventPaste(data);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_ENTER }, this.keyEnterEventHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_DEL }, this.keyDelEventHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_COPY }, this.keyCopyEventHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_PASTE }, this.keyPasteEventHandler);

    this.swiperFlitUpEventHandler = (): void => this.viewModel.swiperFlitEvent(false);
    this.swiperFlitDownEventHandler = (): void => this.viewModel.swiperFlitEvent(true);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_SWIPER_UP }, this.swiperFlitUpEventHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BUTTON_KEY_SWIPER_DOWN }, this.swiperFlitDownEventHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.MONTH_VIEW_DELETE_REPEATED }, this.deleteRepeatedHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.THEME_FONT_CHANGE }, this.onThemeChange);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_MAIN_PAGE_UPDATE_DATA }, this.updateDataHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL }, this.agendaDeleteHandler);
    this.emitterCollector.on({
      eventId: CommonInnerEvent.EVENT_MONTH_VIEW_AGENDA_DATA_QUERY_COMPLETED
    }, this.agendaDataQueryCompletedHandle);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_WEEKENDS }, this.weekendsChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_START_OF_WEEK }, this.startOfWeekChangeHandler);
    // 其它历法变更：通过 emitter 广播触发，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_OTHER_CALENDAR }, this.subscriptionCalendarChangeHandler);
    // 显示周数变更：通过 emitter 广播触发，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_SHOW_WEEK_NUMBER }, this.showWeekNumberChangeHandler);
    // 深色模式变更：通过 emitter 广播触发，绕过 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.DARK_MODE_REFRESH }, this.darkModeRefreshHandler);
  }

  unsubscribeEvents(): void {
    try {
      this.emitterCollector.off();
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed to unsubscribe Events', err);
    }
  }

  onChineseHolidayStateChange() {
    MonthlyViewStateManager.getInstance().state.chineseHolidayState = this.chineseHolidayState;
    Log.info(TAG, `monthlyView onChineseHolidayStateChange ${this.chineseHolidayState}`);
    this.viewModel.onChineseHolidayStateChange(this.chineseHolidayState);
  }

  /**
   * 组件实例化
   * 加载顺序布局->状态机->VM
   */
  aboutToAppear() {
    // 维测用,用于判断是否创建了两个不同的页面
    //this.viewId = this.getUniqueId();
    Log.info(TAG, `monthlyView aboutToAppear ${this.viewId} ${this.currentDate} ${DateUtil.getStartOfDayTimeStamp()}`);
    hiTraceMeter.startTrace(traceEvents.monthViewAppear, 0);
    this.initParam();
    this.init();
    PaletteCache.instance().setDarkMode(this.isDarkMode as boolean);
    hiTraceMeter.finishTrace(traceEvents.monthViewAppear, 0);
    this.hideAgendaWindowMonth = MonthlyViewStateManager.getInstance().state.hideAgendaWindow;
  }

  /**
   * 实现视图的初始化
   * 加载顺序布局->状态机->VM
   */
  init() {
    // 当前展示的月份
    const displayDate: CalendarDate = new CalendarDate(this.displayDate);
    Log.debug(TAG, `aboutToAppear , displayMonth is ${displayDate.toDateString()}`);

    // 初始化月视图的状态机，每次进月视图会触发状态变更
    MonthlyViewStateManager.getInstance()
      .init(
        this.displayDate, // 当前展示时间
        this.startOfWeek, // 一周开始日
        this.currentDate, // 当前天
        this.showWeekNumber, // 是否展示周数
        this.showImportantDay, // 是否展示月视图
        this.subscriptionCalendar, // 其它历法
        this.weekends, // 周末
        this.systemRegion, // 系统地区
        this.language, // 系统语言
        this.chineseHolidayState, // 中国节假日开关
        this.windowWidth) // 窗口宽度

    // 初始化 viewModel
    this.viewModel.reInitByMonth(displayDate, this.viewModel.currentIndex);
    this.viewModel.updateImportantAgenda(this.showImportantDay);
    this.viewModel.updateCalendarAccount();
    this.viewModel.swiperController = this.swiperController;
    this.subscribeEvents();
    this.unusualModeOnChange();
    this.onAgendaListStateChange();
  }

  // harden热起用,重置参数
  initParam() {
    this.selectBlock = undefined;
  }

  /**
   * 资源清理
   */
  aboutToDisappear() {
    this.unsubscribeEvents();
    this.deleteDialogController = null;
    this.deleteRepeatAgendaDialogController = null;
  }

  onShowWeekNumberChange(): void {
    this.innerShowWeekNumber = this.showWeekNumber
    // 周数开关变更
    // 是否显示周末设置项 变更，状态机记录
    MonthlyViewStateManager.getInstance().onShowWeekNumberChange(this.showWeekNumber);
  }

  onShowImportantDayChange(): void {
    this.innerShowImportantDay = this.showImportantDay
    // 重要日开关变更
    // 是否显示重要日设置项 变更，状态机记录
    MonthlyViewStateManager.getInstance().onShowImportantDayChange(this.showImportantDay);
    // 重要日开关变更，VM状态变更
    this.viewModel.onShowImportantDayChange(this.showImportantDay);
  }

  onTabsIndexChange(): void {
    // Tabs 索引变更
    Log.log(TAG, 'onTabsIndexChange: ' + this.tabsIndex);

    if (this.tabsIndex !== TabType.MONTH) {
      Log.log(TAG, 'onTabsIndexChange, No Need To Refresh MonthView Cause cur tabsIndex = ' + this.tabsIndex);
      return;
    }

    // 刷新周末设置状态机, 修复freezeWhenInactive导致周末设置变更未及时生效的问题
    MonthlyViewStateManager.getInstance().onWeekendsChange(this.weekends);

    // tabIndex 页签变更，更新所有日期数据
    this.viewModel?.onTabsIndexChange();

    // 显式刷新周末设置, 因为 updateSingleMonth 在月份未变时会跳过重建, 导致日期宫格的 isWeekends 未更新
    this.viewModel.onWeekendsChange(this.weekends);

    this.needShowHideButton = !this.layout.isSmall;
    this.hideAgendaWindowMonth = MonthlyViewStateManager.getInstance().state.hideAgendaWindow;
  }

  onStartOfWeekChange(): void {
    Log.info(TAG, 'onStartOfWeekChange:' + this.startOfWeek);
    // 一周开始日 数据变更
    const startOfWeek: number = this.startOfWeek === -1 ? DateUtil.getDefaultStartOfWeek() : this.startOfWeek; // 处理默认值
    Log.info(TAG, 'onStartOfWeekChange,realStartOfWeek:' + startOfWeek);
    if (startOfWeek < 0 || startOfWeek > 7) {
      Log.error(TAG, 'onStartOfWeekChange invalid: ' + startOfWeek);
      return;
    }

    // 一周开始日 变更，状态机记录
    MonthlyViewStateManager.getInstance().onStartOfWeekChange(startOfWeek);

    // 周末 变更，状态机记录 // 当前无法顺利使用数组变更，所以需要通过VM方式通知
    this.viewModel.onStartOfWeekChange(startOfWeek);
  }

  onWeekendsChange(): void {
    // 周末设置项 变更，状态机记录
    MonthlyViewStateManager.getInstance().onWeekendsChange(this.weekends);

    // 周末 数据变更
    this.viewModel.onWeekendsChange(this.weekends);
  }

  /**
   * 处理实时时间变化，功能同监听 time_tick 广播，上层接到广播后会实时修改 CurrentDate
   */
  onCurrentDateChange(): void {
    // 实时时间 变更，状态机记录
    MonthlyViewStateManager.getInstance().onCurrentDateChange(this.currentDate);

    // 当天时间变更。跨天场景，分钟变更场景
    this.viewModel.onCurrentDateChange(this.currentDate);
  }

  onSubscriptionCalendar(): void {
    Log.info(TAG, `onSubscriptionCalendar subscriptionCalendar=${this.subscriptionCalendar}`);
    // 历法 变更，状态机记录
    MonthlyViewStateManager.getInstance().onSubscriptionCalendar(this.subscriptionCalendar);
    // 历法状态变更，VM状态变更
    this.viewModel.onSubscriptionCalendar(this.subscriptionCalendar);
  }

  onDarkModeChange(): void {
    PaletteCache.instance().setDarkMode(this.isDarkMode as boolean);
    this.viewModel.onDarkModeChange();
  }

  onLanguageChange(): void {
    MonthlyViewStateManager.getInstance().onLanguageChange(this.language);
    //语言变更
    this.viewModel.onLanguageChange(this.language);
  }

  // 主题变更
  private onThemeChange: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    PaintCache.instance().setFontFamilyPath('');
    this.viewModel.onThemeChange();
  };

  onAgendaListStateChange(): void {
    if (this.tabsIndex !== TabType.MONTH || ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
      return;
    }

    // 状态机记录
    MonthlyViewStateManager.getInstance().onAgendaListStateChange(this.hideAgendaWindowMonth);

    const isMirror = I18nUtil.isUyghurLanguage(this.language);
    this.monthAgendaViewAnimate.translateOptions = { x: isMirror ? -420 : 420 } // 日程列表跟随日期视图上移
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: 300, curve: Curve.Friction
    };
    const isGrid = this.layout.isGrid;
    this.layoutModel.onSizeRefresh();
    const needMove = this.layout.isGrid === isGrid;

    // 日程详情显隐
    this.viewModel.onAgendaListStateChange(this.hideAgendaWindowMonth, true, needMove);
    this.viewModel.updateMonthWeekAgendaHeight(Number(this.layoutModel.compSizeEnv.data.get('height')),
      this.dayCellLayout.circleSize, this.layout.isSmall);
  }

  onSystemRegionChange(): void {
    Log.info(TAG, 'onSystemRegionChange:' + this.systemRegion);
    //状态机记录
    MonthlyViewStateManager.getInstance().onSystemRegionChange(this.systemRegion);

    //地区变更 ，VM状态变更
    this.viewModel.onSystemRegionChange(this.systemRegion);

    // 地区变更，触发地区默认的一周开始日变更
    Log.info(TAG, 'onStartOfWeekChange by onSystemRegionChange');
    this.onStartOfWeekChange();
  }

  onDisplayDateChange(): void {
    // 展示日期变更
    Log.log(TAG, `${this.viewId} onDisplayDateChange timeStamp: ${this.displayDate}`);
    // 选中时间 变更，状态机记录
    MonthlyViewStateManager.getInstance().onDisplayDateChange(this.displayDate);

    if (this.tabsIndex !== TabType.MONTH) {
      Log.debug(TAG, 'onDisplayDateChange Not Happen In Month View, No Need To Refresh MonthView Cause cur tabsIndex = ' + this.tabsIndex);
      return;
    }

    if (this.viewModel.isBackingToToday) {
      Log.debug(TAG, 'onDisplayDateChange is Backing To Today, No Need To Refresh MonthView Cause cur tabsIndex = ' + this.tabsIndex);
      return;
    }

    // 选中时间 变更，VM处理状态变更
    this.viewModel.onDisplayDateChange();
  }

  onSwiperIndexChange(index: number): void {
    // Swiper 滑动
    if (this.viewModel.isBackingToTodaySwipe) {
      Log.debug(TAG, 'onSwiperIndexChange is Backing To Today, No Need To Refresh MonthView Cause cur tabsIndex = ' + this.tabsIndex);
      this.viewModel.isBackingToTodaySwipe = false;
      return;
    }

    // Swiper 滑动
    if (this.viewModel.isJumpToSomeday) {
      Log.debug(TAG, 'onSwiperIndexChange is Backing To Today, No Need To Refresh MonthView Cause cur tabsIndex = ' + this.tabsIndex);
      return;
    }

    this.clearPreview();

    this.viewModel.onSwiperIndexChange(index);

    this.selectBlock = undefined;

    //月视图滑动时，清除上个月的日程块选中态
    const focusWeekIndex = this.agendaBlockState.curFocusWeekIndex;
    const curMonthViewModel = this.viewModel.singleMonthlyViewModels[this.viewModel.currentIndex];
    if (focusWeekIndex >= 0) {
      curMonthViewModel.lastMonthVM?.weekViewModels[focusWeekIndex].freshSingleWeekAgendaBlockArea();
      curMonthViewModel.nextMonthVM?.weekViewModels[focusWeekIndex].freshSingleWeekAgendaBlockArea();
    }

    this.handleAccessibilityFocus(index);

    let params: ReportHiEventParams = {
      SOURCE_PAGE: TabType.MONTH,
      TYPE: this.weekState.isWeekShow ? 1 : 0,
    }
    ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchView, params);
  }

  private getAccessibilityText(index: number): string {
    let month = this.viewModel.singleMonthlyViewModels[index];
    let option: Record<string, string> = { 'year': 'numeric', 'month': 'long' }
    let date = new CalendarDate();
    date.setFullYear(month.curMonthlyInfo.solarYear);
    date.setMonth(month.curMonthlyInfo.solarMonth - 1);
    return DateUtil.intlDateFormat(date, option);
  }

  /**
   * 处理数据变化广播
   */
  async onDataChange() {
    await this.viewModel.onDataChange(this.showImportantDay);
    return;
  }

  /**
   * 处理实时时间变更
   */
  onTimeChange() {
    // @StorageProp 在 onForeground 场景下不同步更新，直接从 AppStorage 读取最新值
    const latestCurrentDate = AppStorage.get<number>(GlobalDataKeys.CURRENT_DATE) ?? this.currentDate;
    MonthlyViewStateManager.getInstance().onCurrentDateChange(latestCurrentDate);

    this.viewModel.onCurrentDateChange(latestCurrentDate);

    // 应用在前台跨天时，自动选中最新一天
    if (this.tabsIndex === TabType.MONTH && !this.viewModel.isBackingToToday) {
      const displayDateValue = AppStorage.get<number>(GlobalDataKeys.DISPLAY_DATE) ?? 0;
      const today = new Date(latestCurrentDate);
      const display = new Date(displayDateValue);
      const isCrossDay = today.getFullYear() !== display.getFullYear() ||
        today.getMonth() !== display.getMonth() ||
        today.getDate() !== display.getDate();
      if (isCrossDay) {
        GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, latestCurrentDate);
        emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
      }
    }
  }

  /**
   * 处理实时系统时区变更
   */
  onTimeZoneChange() {
    Log.info(TAG, 'System Time Zone Changed ! currentDate = ' + this.currentDate);

    // 选中时间 变更，状态机记录
    MonthlyViewStateManager.getInstance().onCurrentDateChange(this.currentDate);

    this.viewModel.onTimeZoneChange(this.currentDate);

    this.onDisplayDateChange();
  }

  /**
   * 处理回到今天的动作
   */
  onBackToToday(data: emitter.EventData) {
    //非当前视图无需触发
    if (this.tabsIndex !== TabType.MONTH) {
      // 选中时间 变更，状态机记录
      MonthlyViewStateManager.getInstance().onDisplayDateChange(this.displayDate);
      return;
    }
    //清除日程选中态
    this.selectBlock = undefined;

    this.viewModel.onBackToToday();
  }

  //回车键响应
  onKeyEventEnter() {
    if (this.tabsIndex === TabType.MONTH && this.selectBlock !== undefined) {
      if (this.selectBlock?.blockId !== undefined && this.selectBlock?.blockAgendas.length === 1) {
        this.toEventDetail();
        ReportUtil.reportStatisticEvent(statisticEvents.monthCardViewAgendaDetail);
      } else {
        this.selectBlock.blockPop = true;
      }
    }
  }

  //删除键响应
  async onKeyEventDel() {
    const selectBlock = this.selectBlock;
    if (this.tabsIndex === TabType.MONTH && selectBlock !== undefined) {
      const checkRes = this.isSelectBlockValid(selectBlock);
      if (checkRes) {
        let event = selectBlock.getInfo();
        let deleteService = ServiceManager.getInstance()
          .getService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE);
        if (!event.isImportantEvent() && !event.isHoliday()) {
          deleteService?.notifyDeleteEvent(event.mId, event.mBegin, true);
        }
      } else {
        prompt.showToast({
          message: GlobalThis.getResourceStr($r('app.string.agenda_can_not_delete'))
        })
      }
    }
  }

  // Ctrl+C复制响应
  async onKeyEventCopy(data: emitter.EventData) {
    if (this.tabsIndex !== TabType.MONTH) {
      return;
    }
    let eventId = data?.data?.eventId as number;
    if (!eventId) {
      const selectBlock = this.selectBlock;
      if (!selectBlock || !selectBlock.isUnfold()) {
        CopyHelper.instance().clear();
        return;
      }
      const checkRes = this.isSelectBlockValid(selectBlock);
      if (!checkRes) {
        return;
      }
      eventId = selectBlock.getInfo().mId;
    }
    CopyHelper.instance().copyEventInfo(eventId);
  }

  // 粘贴响应
  async onKeyEventPaste(data: emitter.EventData) {
    if (this.tabsIndex !== TabType.MONTH) {
      return;
    }
    Log.info(TAG, 'paste to hightlight in monthview');
    CopyHelper.instance().pasteEventInfoHighLight();
  }

  /**
   * 日程详情跳转
   * @param eventId
   */
  toEventDetail() {
    try {
      ThrottleFunction.instance().throttle(TAG + 'detail', (): void => {
        if (this.selectBlock) {
          if (this.needCommerce) {
            const info = this.selectBlock.getInfo();
            AgendaAbilityManager.getInstance()
              .startAbilityByEventId(info.mId, info.mBegin, info.mEnd, info.mIsHoliday,
                info.mTitle);
            return
          }
          const param: Record<string, number | AgendaEventInfo> = {};
          param.id = this.selectBlock.blockId;
          param.holidayInfo = this.selectBlock.getInfo();
          NavPathManager.getInstance().pushPath({
            builderName: NavPathName.AGENDA_DETAIL,
            routerName: RouterName.ENTRY_HAP,
            param: param
          });
        }
      }, 200)
    } catch (err) {
      Log.logErrorMsg(TAG, 'to event detail error', err);
    }
  }

  reportPopupStatistic(type: number, isSave: number) {
    let params: ReportHiEventParams = {
      TYPE: type,
      IS_SAVE: isSave
    }
    ReportUtil.reportStatisticEvent(statisticEvents.deleteAgendaSavePopup, params);
  }

  async deleteEventById() {
    if (this.selectBlock?.blockId) {
      const rowsDeleted = await EventService.INSTANCE.deleteEventById(this.selectBlock.blockId) as number;
      if (rowsDeleted > 0) {
        Log.info(TAG, `delete by id success ${this.selectBlock?.blockId}`);
      } else {
        Log.warn(TAG, 'delete by id fail');
      }
    }
  }

  onSwipeMainPage(data: emitter.EventData): void {
    if (this.tabsIndex !== TabType.MONTH) {
      return;
    }
    if (!data.data) {
      return;
    }
    const direction: number = data.data['direction'];
    Log.log(TAG, 'onSwipe: ' + direction);
    if (direction === 1) {
      this.swiperController.showNext();
    } else {
      this.swiperController.showPrevious();
    }
  }

  handleAnimationStart(index: number, targetIndex: number) {
    Log.log(TAG, `onAnimationStart startIndex ${index} , endIndex ${targetIndex}, swiperFlag ${this.swiperFlag}`);
    //添加标志位用于确定是否执行过AnimationStart
    if (this.swiperFlag) {
      return;
    }
    if (index === targetIndex && targetIndex === this.viewModel.currentIndex) {
      return;
    }
    this.swiperFlag = !this.swiperFlag;

    if (this.viewModel.isBackingToTodaySwipe) {
      Log.info(TAG, 'isBackingToToday No Need To Process Swiper Change');
      this.viewModel.isBackingToTodaySwipe = false;
      return;
    }

    if (this.viewModel.isJumpToSomeday) {
      this.viewModel.isJumpToSomeday = false;
      Log.info(TAG, 'jumpToSomeday No Need To Process Swiper Change');
      return;
    }

    hiTraceMeter.startTrace(traceEvents.monthViewSwipe, 0);
    this.onSwiperIndexChange(targetIndex);
  }

  handleSwiperChange(index: number) {
    Log.log(TAG, `onChange Index ${index} , swiperFlag ${this.swiperFlag}`);


    //标志位判断是否执行过AnimationStart
    if (this.swiperFlag) {
      //执行过AnimationStart,无需再次刷新
      this.swiperFlag = !this.swiperFlag;
      this.viewModel.currentIndex = index;
      return;
    }
    //未执行过则需要刷新,更改标志位标志正在刷新
    this.swiperFlag = !this.swiperFlag;

    this.onSwiperIndexChange(index);
    this.viewModel.currentIndex = index;
    this.swiperFlag = !this.swiperFlag;
  }

  handleSizeChange(oldValue: SizeOptions, newValue: SizeOptions) {
    Log.debug(TAG, `onSizeChange: ${oldValue.width} ${oldValue.height} ==> ${newValue.width} ${newValue.height}`);
    if (oldValue.width === newValue.width && oldValue.height === newValue.height) {
      return;
    }
    const width = Math.round(Number(newValue.width));
    const height = Math.round(Number(newValue.height));

    const oldSmallStatus = this.layout.isSmall;
    this.layoutModel.onSizeChange(width, height);
    this.inSmallWindow = this.layout.isSmall;
    this.needShowHideButton = !this.layout.isSmall;

    // 大小屏切换需要重新绑定drawModifier
    if (oldSmallStatus !== this.layout.isSmall) {
      Log.info(TAG, `onSmallStatusChange: ${oldSmallStatus} to ${this.layout.isSmall}`);
      this.viewModel.onSmallStatusChange();
    }

    // 由小屏转为宽屏需要还原周视图状态,宽屏需要更新周日程列表的高度
    if (!this.layout.isSmall) {
      this.viewModel.restoreMonthShow();
    }
    this.viewModel.updateMonthWeekAgendaHeight(height, this.dayCellLayout.circleSize, this.layout.isSmall);

    // 用于界面是否能够滚动的判断
    if (this.layout.isSmall) {
      const nowWeekHeight = this.layout.weekRowHeight;
      this.viewModel.updateNowMonthHeight(height, nowWeekHeight);
    }
  }

  // 清除弹出窗
  clearPreview() {
    this.hoverBlock?.clearPreview();
    this.selectBlock?.clearPreview();
    this.agendaBlockState.focusedAgendaX = -1;
    this.agendaBlockState.focusedAgendaY = -1;
    WeekAgendaState.getInstance().showPopup = false;
    this.agendaBlockState.resetAgendaHoverFlag();
  }

  private handleAccessibilityFocus(index: number) {
    const singleWeek = this.viewModel.singleMonthlyViewModels[index]?.weekViewModels[0];
    if (singleWeek && singleWeek.dayViewModels) {
      for (let i = 0; i < singleWeek.dayViewModels.length; i++) {
        const temp = singleWeek.dayViewModels[i];
        if (temp.isCurrentMonth) {
          // 跳转到当月1日
          focusComponentById(temp.getCompId(), 500);
          return;
        }
      }
    }
  }

  @Builder
  MonthViewSwiper() {
    Swiper(this.swiperController) {
      ForEach(new Array(this.swipeCount).fill(''), (item: string, index: number) => {
        SingleMonthlyView(
          {
            viewModel: this.viewModel.singleMonthlyViewModels[index],
            weekTitlesVM: this.viewModel.weekTitlesVM
          })
      }, (item: string, index: number) => index.toString())
    }
    .id(CompId.MONTH_VIEW_SWIPER)
    .accessibilityLevel('no')
    .cachedCount(this.cashedCount)
    .index(this.viewModel.currentIndex)
    .autoPlay(false)
    .indicator(false) // 默认开启指示点
    .loop(true) // 默认开启循环播放
    .duration(this.viewModel.SWIPER_ANIMATION_TIME)
    .vertical(false)
    .focusable(true)
    .disableSwipe(this.viewModel.disableSwiper)
    .onAnimationStart((index: number, targetIndex: number) => {
      //在月视图上下滑动的动效中不关闭SingleWeekView背景色
      if (index !== targetIndex) {
        this.weekState.singleWeekBackgroundColorOpen = false; //月视图左右滑动关闭SingleWeekView背景色
      }
      //滑动的过程中不弹出日程块hover pop
      this.agendaBlockState.duringSwiperAnimation = true;
      clearTimeout(this.agendaBlockState.timer);
      this.handleAnimationStart(index, targetIndex);
    })
    .onAnimationEnd(() => {
      hiTraceMeter.finishTrace(traceEvents.monthViewSwipe, 0);
      this.agendaBlockState.duringSwiperAnimation = false;
      this.agendaBlockState.clickAgendaShow = false;
    })
    .onChange((index: number) => {
      this.handleSwiperChange(index);
    })
    .layoutWeight(1)
    .margin({ top: this.unusualMode === UnusualMode.HICAR ? -20 : 0 })
    .pageFlipMode(PageFlipMode.SINGLE)
  }

  build() {
    Column() {
      // 非分栏场景, 周标题不跟随滑动, 放在最顶层
      if (this.layout.isSmall) {
        WeekTitle({ viewModel: this.viewModel.weekTitlesVM });
      }

      if (this.rootLoaded) {
        this.MonthViewSwiper();
      }
    }
    .id(CompId.MONTH_VIEW)
    .width('100%')
    .height('100%')
    .padding({
      top: LengthMetrics.vp(ModeUtil.isSmallUpDownFoldMode(this.unusualMode) ? 0 :
      MonthStaticLayout.monthPaddingTop),
      start: LengthMetrics.vp(this.layout.isSmall || this.layout.isGrid ? 0 : 16),
      bottom: LengthMetrics.vp(this.layout.isSmall ? 0 : 16)
    })
    .onSizeChange((oldValue, newValue) => {
      this.handleSizeChange(oldValue, newValue);
    })
    .onMouse(() => {
      //移动到日程块区域之外，将hover pop关掉
      this.agendaBlockState.resetAgendaHoverFlag();
    })
    .onAppear(() => {
      this.rootLoaded = true;
    })
  }

  private isSelectBlockValid(selectBlock: AgendaBlockInfo): boolean {
    return selectBlock.blockId !== undefined &&
      selectBlock.blockId !== -1 && selectBlock.blockAgendas.length === 1;
  }

  // 处理系统时间变化
  private timeChangeHandler: () => void = (): void => {
  };

  // 处理系统时区变化
  private timeZoneChangeHandler: () => void = (): void => {
  };

  // 处理日历日程数据变化
  private deleteRepeatedHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    // 事件从已点击的 singleAgenda 产生，此时 selectBlock 一定存在
    if (this.selectBlock?.getInfo().isImportantEvent()) {
      return;
    }
    this.viewModel.setIsFirstRepeatAgenda(this.selectBlock!).then(() => {
      this.deleteRepeatAgendaDialogController?.open();
    })
  };

  // 处理日历日程数据变化
  private dataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  // 删除成功后立即清理月视图日程块缓存
  private agendaDeleteHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    if (!data?.data) {
      return;
    }
    const eventId: number | undefined = data.data['eventId'] as number | undefined;
    const displayStartMillsValue: number | undefined = data.data['displayStartMills'] as number | undefined;
    if (eventId === undefined || eventId === null) {
      return;
    }
    const displayStartMills: number = displayStartMillsValue ?? 0;
    this.viewModel.onAgendaSoftDelete(eventId, displayStartMills);
  };

  // 处理回到今天变化
  private backToTodayHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  // 处理日期变化
  private displayDateHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private swipeMainPageHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private jumpToSomedayHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  //处理选中时按下回车键变化
  private keyEnterEventHandler: () => void = (): void => {
  };

  //处理选中时按下删除键变化
  private keyDelEventHandler: () => void = (): void => {
  };

  //处理选中时按下复制键变化
  private keyCopyEventHandler: (data: emitter.EventData) => void = (): void => {
  };

  // 周末设置变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private weekendsChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const weekends = AppStorage.get<number[]>(GlobalDataKeys.WEEKENDS) ?? [-1];
    MonthlyViewStateManager.getInstance().onWeekendsChange(weekends);
    this.viewModel.onWeekendsChange(weekends);
  };

  // 一周开始日变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private startOfWeekChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const rawStartOfWeek = AppStorage.get<number>(GlobalDataKeys.START_OF_WEEK) ?? 0;
    const startOfWeek = rawStartOfWeek === -1 ? DateUtil.getDefaultStartOfWeek() : rawStartOfWeek;
    if (startOfWeek < 0 || startOfWeek > 7) {
      return;
    }
    MonthlyViewStateManager.getInstance().onStartOfWeekChange(startOfWeek);
    this.viewModel.onStartOfWeekChange(startOfWeek);
  };

  // 其它历法变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private subscriptionCalendarChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const subscriptionCalendar = AppStorage.get<number>(GlobalDataKeys.SUBSCRIPTION_CALENDAR) ?? -1;
    MonthlyViewStateManager.getInstance().onSubscriptionCalendar(subscriptionCalendar);
    this.viewModel.onSubscriptionCalendar(subscriptionCalendar);
  };

  // 显示周数变更事件处理，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private showWeekNumberChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const showWeekNumber = AppStorage.get<boolean>(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON) ?? false;
    this.innerShowWeekNumber = showWeekNumber;
    MonthlyViewStateManager.getInstance().onShowWeekNumberChange(showWeekNumber);
  };

  // 深色模式变更事件处理，绕过 @StorageProp @Watch 不触发的问题
  private darkModeRefreshHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const isDarkMode = AppStorage.get<boolean>(GlobalDataKeys.IS_DARKMODE) ?? false;
    PaletteCache.instance().setDarkMode(isDarkMode);
    this.viewModel.onDarkModeChange();
    // 强制 Swiper 缓存页销毁并重建
    this.cashedCount = 0;
    SafeUtil.setTimeout(() => {
      this.cashedCount = 1;
    }, 50);
  };

  //处理按下粘贴键的变化
  private keyPasteEventHandler: (data: emitter.EventData) => void = (): void => {
  };

  //处理Swiper翻页事件
  private swiperFlitUpEventHandler: () => void = (): void => {
  };

  private swiperFlitDownEventHandler: () => void = (): void => {
  };

  // 广播限流，刷新视图
  private throttleToDataChange: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const currentNavPath: string[] = this.navPathStack.getAllPathName();
    // 在全部日程列表数据同步时，主界面不在栈顶时不触发月视图查询
    if (!EmptyUtils.isEmptyArray(currentNavPath) && currentNavPath[0] === NavPathName.AGENDA_LIST) {
      return;
    }
    // 添加逻辑防止多余触发
    if (data?.data?.table !== 'Events' && data?.data?.table !== 'Calendars' && data?.data?.table !== 'Instances' &&
      data?.data?.table !== 'event_attachments') {
      return;
    }
    Log.info(TAG, 'Data changed Week Agenda View is going to refresh now');
    ThrottleFunction.instance().throttleQuery(TAG + ':onDataChange', async () => {
      await this.onDataChange();
    });
  };

  // 刷新视图
  private updateDataHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    if (!data?.data?.updateData) {
      return;
    }
    const showImportantDay: boolean | undefined = data.data['showImportantDay'] as boolean | undefined;
    if (typeof showImportantDay === 'boolean') {
      Log.info(TAG, `update important day switch immediately: ${showImportantDay}`);
      this.innerShowImportantDay = showImportantDay;
      MonthlyViewStateManager.getInstance().onShowImportantDayChange(showImportantDay);
      this.viewModel.onShowImportantDayChange(showImportantDay);
      return;
    }
    Log.info(TAG, 'update data Week Agenda View is going to refresh now');
    ThrottleFunction.instance().throttleQuery(TAG + ':onDataChange', async () => {
      await this.onDataChange();
    });
  };

  // 月视图日程数据查询完成后，打开swiper预加载
  private agendaDataQueryCompletedHandle: () => void = (): void => {
    const delay: number = 300;
    // 添加延时等待月视图日程渲染完成
    SafeUtil.setTimeout(() => {
      this.cashedCount = 1;
    }, delay);
  };
}
