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

import { OneYearView } from './OneYearView';
import {
  BigFontSize,
  CalendarDate,
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  DateManager,
  DateUtil,
  DayData,
  EmitterCollector,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  isChineseCalendar,
  Log,
  LunarDateUtil,
  ReportUtil,
  statisticEvents,
  SubscriptionCalendar,
  TabType,
  ThrottleFunction,
  YearAnimateParam
} from '@app/common';
import { YearViewModel } from '../viewmodel/YearViewModel';
import { YearLegend } from './YearLegend';
import { YearViewLayoutModel } from '../layoutmodel/YearViewLayoutModel';
import { ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import emitter from '@ohos.events.emitter';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import lazy { inspector } from '@kit.ArkUI';
import { CommonProp } from '../layoutmodel/YearViewLayoutProp';
import { broadcastContent, focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { SingleYearViewModel, YearInfo } from '../viewmodel/SingleYearViewModel';
import { LengthMetrics } from '@kit.ArkUI';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { intl } from '@kit.LocalizationKit';

const TAG: string = '[YearView][YearView]';

/**
 * Year View
 * The single year view is a super-large component. When slide the view, the entire page cannot be redrawn.
 * @since 2022-03-01
 */

@Component({ freezeWhenInactive: true })
export struct YearView {
  @StorageProp(GlobalDataKeys.DISPLAY_DATE) @Watch('onSelectedDayChange') displayDate: number = 0;

  @StorageProp('tabIndex') @Watch('onTabsIndexChanged') tabsIndex: number = TabType.YEAR;

  @Consume('yearViewAnimateParam') animateParam: CombineAnimateParam;

  @Consume('yearLegendAnimateParam') yearLegendAnimateParam: CombineAnimateParam;

  @Consume('yearAnimationParam') yearParam: YearAnimateParam;

  // 一周起始日
  @StorageProp('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = 0;

  // 历法
  @StorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = SubscriptionCalendar.CHINESE_CALENDAR;

  // 周末
  @StorageLink('weekends') @Watch('onWeekendsChange') weekends: number[] = [];

  // 主题色
  @StorageProp('themeColor') @Watch('onThemeColorChange') themeColor: string = '';

  //系统语言
  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  //字体大小
  @StorageLink('fontSizeScale') @Watch('onFontSizeChange') fontSizeScale: number = 1;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 显示/隐藏班休信息

  @State swipeCount: number = 3; // need move into view model in the future

  @State viewModel: YearViewModel = new YearViewModel(new CalendarDate(this.displayDate).getFullYear());

  @State rootLoaded: boolean = false;

  // 深色模式刷新标志位，变更时强制 Swiper 页重建以刷新 Canvas 颜色
  @State darkRefreshKey: number = 0;

  @Provide commonProp: CommonProp = new CommonProp();

  private swiperController: SwiperController = new SwiperController();

  private readonly yearArray: number[] = [];

  //刷新视图用标志位
  private swiperFlag: boolean = false;

  //是否更新过displayDate标志
  private isUpdateDisplayDate: boolean = false;

  private componentObserver: inspector.ComponentObserver = inspector.createComponentObserver(CompId.YEAR_VIEW);

  private emitterCollector : EmitterCollector = new EmitterCollector();

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.yearViewAppear, 0);
    this.commonProp.themeColor = GlobalData.instance().get(GlobalDataKeys.THEME_COLOR) as string;
    YearViewLayoutModel.instance().init();

    this.viewModel.init();
    for (let index = 0; index < this.swipeCount; ++index) {
      this.yearArray.push(index);
    }
    this.rootObserver = () => {
      this.rootLoaded = true
    };
    this.componentObserver.on('draw', this.rootObserver);
    if (this.yearParam.componentWidth !== 0) {
      YearViewLayoutModel.instance().onSizeChange(
        Math.round(this.yearParam.componentWidth), Math.round(this.yearParam.componentHeight));
      this.yearAnimationParamChange(true);
    }
    this.commonProp.hasRecess = this.viewModel.hasRecess();
    this.emitterCollector.on({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, this.onSwipe);
    this.emitterCollector.on({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, this.jumpToSomedayHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, () => {
      const date: CalendarDate = new CalendarDate(this.displayDate);
      let dateStr = DateUtil.intlDateFormat(date, { dateStyle: 'long' }, this.language);
      broadcastContent(`${GlobalThis.getResourceStr($r('app.string.back_to_today'))}, ${dateStr}`);
    });
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.onSystemDateChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_WEEKENDS }, this.weekendsChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_START_OF_WEEK }, this.startOfWeekChangeHandler);
    // 其它历法变更：通过 emitter 广播触发，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_OTHER_CALENDAR }, this.subscriptionCalendarChangeHandler);
    // 深色模式变更：通过 emitter 广播触发，绕过 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.DARK_MODE_REFRESH }, this.darkModeRefreshHandler);
    hiTraceMeter.finishTrace(traceEvents.yearViewAppear, 0);
  }

  private onSystemDateChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
    Log.info(TAG, `onSystemDateChangeHandler`);
    this.onSystemDateChange();
  };

  // 周末设置变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private weekendsChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const weekends = AppStorage.get<number[]>(GlobalDataKeys.WEEKENDS) ?? [-1];
    this.viewModel?.onWeekendsChange(weekends);
  };

  // 一周开始日变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private startOfWeekChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    let startOfWeek = AppStorage.get<number>(GlobalDataKeys.START_OF_WEEK) ?? 0;
    if (startOfWeek === -1) {
      startOfWeek = DateUtil.getDefaultStartOfWeek();
    }
    this.viewModel?.onStartOfWeekChange(startOfWeek);
  };

  // 其它历法变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private subscriptionCalendarChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const subscriptionCalendar = AppStorage.get<number>(GlobalDataKeys.SUBSCRIPTION_CALENDAR) ?? -1;
    this.viewModel?.onSubCalendarChange(isChineseCalendar(subscriptionCalendar));
  };

  // 深色模式变更事件处理，绕过 @StorageProp @Watch 不触发的问题
  private darkModeRefreshHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const isDarkMode = AppStorage.get<boolean>(GlobalDataKeys.IS_DARKMODE) ?? false;
    PaletteCache.instance().setDarkMode(isDarkMode);
    // 变更 key 强制 Swiper 页重建，OneYearView 组件重新创建并读取最新 AppStorage 值
    this.darkRefreshKey = this.darkRefreshKey + 1;
  };

  private onSystemDateChange() {
    const newDate = new CalendarDate();
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDate.getTime());
    Log.log(TAG, `onSystemDateChange ${newDate.toLocaleString()}, time: ${newDate.getTime()}`);
  }

  aboutToDisappear() {
    this.emitterCollector.off();
    this.componentObserver.off('draw', this.rootObserver);
    this.viewModel?.destroy();
  }

  onSubscriptionCalendarChange() {
    if (this.tabsIndex !== TabType.YEAR) {
      return;
    }
    Log.debug(TAG, 'onSubscriptionCalendarChange:' + this.subscriptionCalendar);
    this.viewModel?.onSubCalendarChange(isChineseCalendar(this.subscriptionCalendar));
  }

  onWeekendsChange() {
    Log.debug(TAG, 'onWeekendsChange:' + this.weekends);
    this.viewModel?.onWeekendsChange(this.weekends);
  }

  onLanguageChange(): void {
    this.viewModel?.onLanguageChange(this.language);
  }

  onThemeColorChange() {

  }

  onTabsIndexChanged() {
    Log.debug(TAG, `onTabsIndexChanged: tabsIndex:${this.tabsIndex}`);
    // only switch to YEAR start work
    if (this.tabsIndex !== TabType.YEAR) {
      return;
    }
    // 当切换到年视图之后,开始刷新数据
    this.onSelectedDayChange();
    // 增加历法切换刷新
    this.onSubscriptionCalendarChange();
    // 刷新周末设置, 修复freezeWhenInactive导致周末设置变更未及时生效的问题
    this.onWeekendsChange();
  }

  onStartOfWeekChange() {
    let startOfWeek = this.startOfWeek;
    if (startOfWeek === -1) { // switch default
      startOfWeek = DateUtil.getDefaultStartOfWeek();
    }
    this.viewModel?.onStartOfWeekChange(startOfWeek);
  }

  onFontSizeChange() {
    Log.info(TAG, 'onFontSizeChange:' + this.fontSizeScale);
    YearViewLayoutModel.instance().onFontSizeChange(this.fontSizeScale);
  }

  // 2. 从PC 主界面DateSwitch触发
  onSelectedDayChange() {
    const inYearView = this.tabsIndex === TabType.YEAR;
    const dayData = DayData.buildByDate(new CalendarDate(this.displayDate));
    Log.debug(TAG, `onSelectedDayChange: ${dayData.toString()} inYearView:${inYearView}`);
    this.viewModel?.onSelectedDayChange(dayData, inYearView);
    this.commonProp.hasRecess = this.viewModel.hasRecess();
    this.yearAnimationParamChange();
  }

  yearAnimationParamChange(scaleUpdate: boolean = false) {
    const colCount = YearViewLayoutModel.instance().gridProp.value.colCount;
    const minHeight = YearViewLayoutModel.instance().gridProp.value.minHeight;
    this.yearParam.changeYearAnimationParam(this.displayDate, colCount, minHeight, scaleUpdate);
  }

  // 1. 从其他视图触发，范围在单月中

  onSwipe = (eventData: emitter.EventData) => {
    if (this.tabsIndex !== TabType.YEAR) {
      return;
    }
    if (!eventData.data) {
      return;
    }
    const direction: number = eventData.data['direction'];
    Log.log(TAG, 'onSwipe: ' + direction);
    this.isUpdateDisplayDate = true;
    if (direction === 1) {
      this.swiperController.showNext();
    } else {
      this.swiperController.showPrevious();
    }
    this.setCurrentDisplayDay();
  };

  onChangeFontSize(num: number) {
    return FontSizeScaleUtils.getLimitHeightNum(
      GlobalThis.getInstance().fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_SIX,
      num);
  }

  build() {
    Column() {
      Row() {
        YearLegend({
          displayDate: this.displayDate,
          subscriptionCalendar: this.subscriptionCalendar
        })
      }
      .width('100%')
      .padding({ start: LengthMetrics.percent(0.04), bottom: LengthMetrics.vp(this.onChangeFontSize(4)) })
      .alignItems(VerticalAlign.Center)
      .focusable(false)
      .visibility(this.yearLegendAnimateParam.visibility ? Visibility.Visible : Visibility.Hidden)
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY
            .combine(TransitionEffect.opacity(this.yearLegendAnimateParam.opacity)
              .animation(this.yearLegendAnimateParam.opacityAnimateParam)),
          TransitionEffect.OPACITY
            .combine(TransitionEffect.opacity(this.yearLegendAnimateParam.opacity)
              .animation(this.yearLegendAnimateParam.opacityAnimateParam))
        )
      )

      if (this.rootLoaded) {
        this.buildSwiper()
      }
    }
    .padding({ bottom: this.windowAvoidAreaNavigationRectHeight > 0 ? 8 : 0 })
    .id(CompId.YEAR_VIEW)
    .size({ width: '100%', height: '100%' })
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildSwiper() {
    Swiper(this.swiperController) {
      ForEach(this.yearArray, (index: number) => {
        OneYearView({
          viewModel: this.viewModel.singleVMs[index] as SingleYearViewModel,
          swipeIndex: index
        })
      }, (index: number) => `${index}-${this.darkRefreshKey}`)
    }
    .cachedCount(0)
    .accessibilityLevel('no')
    .autoPlay(false)
    .indicator(false) // 默认开启指示点
    .loop(true) // 默认开启循环播放
    .duration(300)
    .vertical(false)
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      const width = newValue.width;
      const height = newValue.height;
      const oldWidth = oldValue.width;
      const oldHeight = oldValue.height;
      if (width === oldWidth && height === oldHeight) {
        return;
      }
      if (width || height) {
        YearViewLayoutModel.instance().onSizeChange(
          Math.round(width as number), Math.round(height as number));
        this.yearParam.componentWidth = width as number;
        this.yearParam.componentHeight = height as number - 30;
        ThrottleFunction.instance().debounce(TAG + 'Animation', () => {
          this.yearAnimationParamChange(true);
        })

      }
    })
    .id(CompId.YEAR_SWIPER)
    .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
      Log.log(TAG, `onAnimationStart startIndex ${index}, endIndex ${targetIndex}, swiperFlag ${this.swiperFlag}`);
      //添加标志位用于确定是否执行过AnimationStart
      if (this.swiperFlag) {
        return;
      }
      if (index === targetIndex) {
        return;
      }
      this.swiperFlag = !this.swiperFlag;
      hiTraceMeter.startTrace(traceEvents.yearViewSwipe, 0);
      this.onSwiperRefresh(index, targetIndex);
      let compId = `SingleMonthView_swipeItem_${targetIndex}_month_0`;
      focusComponentById(compId, 200)
    })
    .onAnimationEnd(()=>{
      hiTraceMeter.finishTrace(traceEvents.yearViewSwipe, 0);
    })
    .onChange((index: number) => {
      Log.log(TAG, `onChange Index ${index}, swiperFlag ${this.swiperFlag}`);
      //标志位判断是否执行过AnimationStart
      if (this.swiperFlag) {
        //执行过AnimationStart,无需再次刷新
        this.swiperFlag = !this.swiperFlag;
        return;
      }
      //未执行过则需要刷新,更改标志位标志正在刷新
      this.swiperFlag = true;
      this.onSwiperRefresh(this.viewModel.curIndex, index);
      this.swiperFlag = false;
    })
    .layoutWeight(1)
    .pageFlipMode(PageFlipMode.SINGLE)

    .visibility(this.animateParam.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.IDENTITY
          .combine(TransitionEffect.scale(this.animateParam.scaleOption)
            .animation(this.animateParam.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.animateParam.opacity)
            .animation(this.animateParam.opacityAnimateParam)),
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale(this.animateParam.scaleOption)
            .animation(this.animateParam.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.animateParam.opacity)
            .animation(this.animateParam.opacityAnimateParam))
      )
    )
  }

  onSwiperRefresh(index: number, targetIndex: number) {
    Log.debug(TAG, `onSwiperRefresh from: ${index} to: ${targetIndex}`);
    if (index === targetIndex) {
      return;
    }
    const direction = (index - targetIndex === 1 || index - targetIndex === -2) ? 0 : 1;
    if (direction) {
      this.viewModel.onShowNext();
    } else {
      this.viewModel.onShowPrevious();
    }
    this.isUpdateDisplayDate = false;
    this.setCurrentDisplayDay();
    this.commonProp.hasRecess = this.viewModel.hasRecess();
  }

  setCurrentDisplayDay() {
    // 获取滑动之后的目标年
    const curInfo = this.viewModel.curData?.info as YearInfo;
    if (!curInfo) {
      Log.error(TAG, `curInfo null`);
      return;
    }
    const curYear = curInfo.year;
    Log.debug(TAG, `year: ${curYear}`);
    // 获取当前选中的月日
    const selectDay = DateManager.getInstance().selectedDay;
    let curDate: number = DateUtil.dateToStamp(curYear, selectDay.solarMonth - 1, selectDay.solarDay);

    if (DateUtil.isSelectDayInit(curYear)) {
      curDate = DateUtil.dateToStamp(curYear, 0, 1);
    }
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, curDate); // 通知其它界面变化
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    let params: ReportHiEventParams = {
      SOURCE_PAGE: TabType.YEAR,
      TYPE: 0,
    }
    ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchView, params);
  }

  private rootObserver: () => void = (): void => {
  };

  // 处理跳转到某天
  private jumpToSomedayHandler: Callback<emitter.EventData> = (data : emitter.EventData): void => {
    if (data && data.data) {
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, data.data['dateTime'] ?? Date.now());
    }
  };
}
