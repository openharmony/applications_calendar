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

import emitter from '@ohos.events.emitter';
import { Geometry } from '@app/common/src/main/ets/geometry/Geometry';
import { TabType } from '@app/common/src/main/ets/default/common/declare';
import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { DateViewModel } from './DateViewModel';
import { GanttViewModel } from './GanttViewModel';
import { AgendaModel } from '../model/AgendaModel';
import { DateRange } from '@app/common/src/main/ets/date/DateRange';
import { DayModel } from '../model/DayModel';
import {
  AgendaEventInfo,
  ARABIC_LANGUAGE,
  CalendarDate,
  CalendarUtils,
  CHINESE_HOLIDAY_STATE_VALUE,
  DateUtil,
  DAY_PER_WEEK,
  DeviceConfig,
  GlobalDataKeys,
  HOURS_PER_DAY,
  I18nUtil,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_WEEK,
  NumberFormatManager,
  PreferencesFiles,
  PreferencesUtil,
  ReportUtil,
  ServiceEnum,
  ServiceManager,
  statisticEvents,
  SubscriptionCalendar,
  traceEvents
} from '@app/common';
import { CommonInnerEvent } from '@app/common/src/main/ets/event/CommonInnerEvent';
import { GlobalData } from '@app/common/src/main/ets/data/GlobalData';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import componentUtils from '@ohos.arkui.componentUtils';
import { RootModel } from '../model/RootModel';
import { DateViewLayoutManager } from './DateViewLayout';
import { NewWeekTitleViewModel } from './NewWeekTitleViewModel';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { i18n } from '@kit.LocalizationKit';

const TAG = 'RootViewModel';

@Observed
export class StaticWeekDayInfo {
  public dayOfWeek: number = 0; // Date对象中getDay
  public isWeekend: boolean = false;
  public title: string = '一';
  public compId: string = '';

  constructor(dayOfWeek: number) {
    this.dayOfWeek = dayOfWeek;
  }
}

interface BreakPoint {
  value: number,
  name: string,
}

// 索引转换矩阵 0 标识当前页 -1 标识前一周/天 1标识后一周/天
const OFFSET_MATRIX: Array<number[]> = [
  [0, 1, -1],
  [-1, 0, 1],
  [1, -1, 0]
];

@Observed
export class RootViewModel {
  public readonly MIN_GANTT_VIEW_HEIGHT = 235; // 最小甘特图高度
  public readonly GOLD_DIVIDE = 1 + DeviceConfig.instance().config.detailRatio; // 分割比例
  public readonly dateSwiperController: SwiperController = new SwiperController();
  public readonly ganttSwiperController: SwiperController = new SwiperController();
  public tabType: TabType = TabType.DAY;
  // 公用状态变量
  public ganttSwiperIndex: number = 0;
  public dateSwiperIndex: number = 0;
  public gridColCount: number = 1;
  public selectDateIndex: number = 0;
  public hoursString: ObservedArray<string> = new ObservedArray<string>();
  public dateVMs: ObservedArray<DateViewModel> = new ObservedArray<DateViewModel>();
  public ganttVMs: ObservedArray<GanttViewModel> = new ObservedArray<GanttViewModel>();
  public staticWeekDayInfoList: ObservedArray<StaticWeekDayInfo> = new ObservedArray<StaticWeekDayInfo>();
  public selectAgendaInfo: AgendaEventInfo | undefined = undefined;
  public isDivide: boolean = false;
  public isShowWeekNumber: boolean = false; //是否显示周数
  public inDivideWindow: boolean = false; // 是否是分栏场景
  public swiperIndex: number = 0; //用于月视图切换到周视图swiper的初始化（月切换到周的分帧送显方案控制swiper下树，每次切换回周日视图，swiper会初始化，导致与月视图日期对不上）
  public gantIndex: number = 0; //用于月视图切换到周视图的分帧送显（分帧送显下掉，该变量可以删除）

  // 公用布局参数
  public rootHeight: number = 0;
  public middleWidth: number = 0;
  public ganttWidth: number = 0;
  public ganttGridWidth: number = 0;
  public ganttCellWidth: number = 0;
  public detailWidth: number = 0;
  public dateHeight: number = 44;
  public bottomHeight: number = 600;
  public ganttMargin: number = 16;
  // 字体
  public weekTitleFontSize: number = 12;
  public weekIndexFontSize: number = 10;
  public weekTextFontSize: number = 8;
  public solarDateFontSize: number = 18;
  public extraInfoFontSize: number = 10;
  public allDayTitleFontSize: number = 10;
  public agendaFontSize: number = 10;
  public timeFontSize: number = 0;
  public currentTimeFontSize: number = 0;
  public timeTextHeight: number = 14;
  public dividerHeight: number = 0;
  // 日期单元布局信息
  public extraInfoWidth: number = 36;
  public extraInfoCharCodeWidth: number = 11;
  public extraInfoAlign: TextAlign = TextAlign.Center;
  public extraInfoRight: boolean = false; // 判断是否在右侧显示,存在底部和右侧两种布局
  // 其他布局信息
  public selectCirclePos: Position = { x: 0, y: 0 };
  public selectCircleAnchor: Position = { x: 0, y: 0 };
  public selectCircleRadius: number = 24;
  public agendaDotRadius: number = 1.5;
  public dateMargin: number = 4;
  public dayGanttViewMargin: number = 0;
  private readonly DIVIDE_WIDTH: number = 600;
  private readonly HOUR_COUNT: number = HOURS_PER_DAY - 1;
  private readonly LEFT_WIDTH_PHONE: number = 25;
  private readonly LEFT_WIDTH_ADAPT: number = 56;
  private readonly SOLAR_HEIGHT_PHONE: number = 22;
  public solarDateHeight: number = this.SOLAR_HEIGHT_PHONE;
  private readonly SOLAR_HEIGHT_ADAPT: number = 22;
  private readonly EXTRA_HEIGHT_PHONE: number = 11;
  public extraInfoHeight: number = this.EXTRA_HEIGHT_PHONE;
  private readonly TAG_WEEK: string = 'WeekRootViewModel';
  private readonly TAG_DAY: string = 'DayRootViewModel';
  private readonly DELAY: number = 300;
  private readonly SWIPER_ITEM_COUNT: number = 3;
  private readonly MAX_DATE_HEIGHT: number = 75;
  private readonly VIEW_PADDING_TOP: number = 12; //tab组件中周日视图的上边距
  private readonly EXTRA_INFO_CHECK_WIDTH = 840; // 用于判断日期布局是左右还是上下的分界点
  private readonly EXTRA_INFO_BOTTOM_WIDTH = 36; // 节气节日底部显示时的宽度
  private readonly LEFT_CLICK_DELAY: number = 300; // 双击判断的延迟
  // 内部处理数据
  private dayModelMatrix: Array<DayModel[]> = [];
  private ganttNeedAdapt: boolean = DeviceConfig.instance().config.ganttNeedAdapt;
  private dateRange: DateRange.Range = { start: Date.now(), end: Date.now() };
  private systemRegion: string = 'CN';
  private subscriptionCalendar: number = 0; // 目前只有农历日程,需要摘到公用定义去，目前枚举在feature/setting
  private language: string = ''; //系统语言
  public  isRTL: boolean = false; // 是否是语言为ar的右向
  private isAR: boolean = false; // 是否为阿拉伯语
  private tag: string = this.TAG_WEEK;
  private breakPoints: BreakPoint[] = new Array();
  //布局参数
  private dateViewLayout = new DateViewLayoutManager();
  // 日期切换flag用于防止触发翻页更新方法
  private _dateSwipeFlag: boolean = false;
  // 周日视图切换动效用参数
  private needAnimate: boolean = true;
  // 是否显隐日程详情
  private _hideAgendaWindow: boolean = false;
  // 周/日视图 周题VM
  public weekTitleVM: NewWeekTitleViewModel = new NewWeekTitleViewModel();
  public chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE =
    AppStorage.get('CHINESE_HOLIDAY_STATE') ?? CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;
  // 用于判断双击操作的计数器
  private leftClickCount: number = 0;

  constructor(tabType: TabType) {
    this.tabType = tabType;
    this.tag = this.isWeekView() ? this.TAG_WEEK : this.TAG_DAY;
    this.breakPoints.push({ value: 0, name: 'xs' });
    this.breakPoints.push({ value: 740, name: 'sm' });
    this.breakPoints.push({ value: 99999, name: 'max' });
    this.weekTitleVM = new NewWeekTitleViewModel();
  }

  init(windowWidth: number = 360): void {
    Log.log(this.tag, `enter root view model, begin to init`);
    this.initParams();
    this.subscribeEvents();
    this.initVMs();
    this.initLayout();
    this.initDayModelMatrix();
    this.weekTitleVM.resetWeekTitles(this.tabType);
    this.weekTitleVM.resetWeekends(this.dateVMs);
    this.resetHours();
    this.resetDayModelMatrix();
    RootModel.instance().scale = PreferencesUtil.getNumberValueSync(PreferencesFiles.DEFAULT,
      RootModel.instance().GANTT_VIEW_SCALE_KEY, RootModel.instance().scale);
    this.initGanttScale(RootModel.instance().scale);
    this.updateAgenda();
    this.setGanttScrollOffset();
    Log.log(this.tag, `enter root view model, init done`);

    const width: number = windowWidth;
    let tempBp: string = '';
    for (let i = 0; i < this.breakPoints.length - 1; ++i) {
      if (width >= this.breakPoints[i].value && width < this.breakPoints[i+1].value) {
        tempBp = this.breakPoints[i].name;
        break;
      }
    }
    this.onBreakpointChange(tempBp);
  }

  subscribeEvents(): void {
    this.timeChangeHandler = () => this.onTimeChange();
    this.dateChangeHandler = () => this.onDateChange();
    this.dataChangeHandler = (data: emitter.EventData) => this.onDataChange(data);
    this.timeTickHandler = () => this.onTimeTick();
    this.timezoneChangeHandler = () => this.onTimezoneChange();
    this.hourCycleChangeHandler = () => this.onHourCycleChange();
    this.backToTodayHandler = () => this.onBackToToday();
    this.displayDateChangeHandler = () => this.onDisplayDateChange();
    this.jumpToSomedayHandler = (data: emitter.EventData): void => {
      if (data && data.data) {
        GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, data.data['dateTime'] ?? Date.now());
      }
      this.onDisplayDateChange();
    }
    this.swipeMainPageHandler = (data: emitter.EventData) => this.onSwipeMainPage(data);
    this.scaleChangeHandler = (data: emitter.EventData) => this.ganttScaleChange(data);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.timeChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.dateChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.timezoneChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_TIME_TICK }, this.timeTickHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_HOUR_CYCLE_CHANGED }, this.hourCycleChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, this.backToTodayHandler);
    emitter.on({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, this.jumpToSomedayHandler);
    emitter.on({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE }, this.displayDateChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SWIPE_MAIN_PAGE }, this.swipeMainPageHandler);
    emitter.on({ eventId: CommonInnerEvent.WEEK_SCALE_CHANGE }, this.scaleChangeHandler);
  }

  dateSwipe(direction: number): void {
    if (direction === 1) {
      this.dateSwiperController.showNext();
    } else {
      this.dateSwiperController.showPrevious();
    }
  }

  ganttSwipe(direction: number): void {
    if (direction === 1) {
      this.ganttSwiperController.showNext();
    } else {
      this.ganttSwiperController.showPrevious();
    }
  }

  onSwipeMainPage(data: emitter.EventData): boolean {
    if (!this.isCurrentView()) {
      return false;
    }
    if (!data.data) {
      return false;
    }
    const direction: number = data.data['direction'];
    Log.log(TAG, 'onSwipe: ' + direction);
    if (this.isWeekView()) {
      this.dateSwipe(direction);
    } else {
      this.ganttSwipe(direction);
    }
    return true;
  }

  setGanttScrollOffset(): void {
    const timeoutId = setTimeout(() => {
      this.ganttVMs.forEach(vm => vm.scrollToCurrentTime());
      clearTimeout(timeoutId);
    }, 0);
  }

  // 根据当前选展示的甘特图index同步其他甘特图的时间线显示
  updateScrollOffsetByIndex(updateIndex: number): void {
    if (!this.ganttVMs || !this.ganttVMs[updateIndex]) {
      return;
    }
    const nowOffset = this.ganttVMs[updateIndex].scroller.currentOffset();
    if (!nowOffset) {
      return;
    }
    Log.info(TAG, `scroll update index ${updateIndex} ${nowOffset.yOffset}`);

    this.ganttVMs.forEach((vm, index) => {
      vm.scrollOffsetY = nowOffset.yOffset;
      if (updateIndex !== index) {
        vm.scroller.scrollTo({ xOffset: 0, yOffset: vm.scrollOffsetY });
        vm.updateMorningAndAfternoon();
      }
    })
  }

  destroy(): void {
    this.unSubscribeEvents();
    this.ganttVMs.forEach(vm => vm.destroy());
  }

  unSubscribeEvents(): void {
    emitter.off(CommonInnerEvent.SYSTEM_TIME_CHANGED, this.timeChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_DATE_CHANGED, this.dateChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.dataChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_TIME_TICK, this.timeTickHandler);
    emitter.off(CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED, this.timezoneChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_HOUR_CYCLE_CHANGED, this.hourCycleChangeHandler);
    emitter.off(CommonInnerEvent.BACK_TO_TODAY, this.backToTodayHandler);
    emitter.off(CommonInnerEvent.DISPLAY_DATE_CHANGE, this.displayDateChangeHandler);
    emitter.off(CommonInnerEvent.SWIPE_MAIN_PAGE, this.swipeMainPageHandler);
    emitter.off(CommonInnerEvent.WEEK_SCALE_CHANGE, this.scaleChangeHandler);
    emitter.off(CommonInnerEvent.JUMP_TO_SOMEDAY, this.jumpToSomedayHandler);
  }

  onTimeChange(): void {
    if (!this.isCurrentView()) {
      return;
    }

    this.ganttVMs.forEach(vm => vm.updateTimeLine());
  }

  onDataChange(data: emitter.EventData): void {
    if (data?.data?.table !== 'Events' && data?.data?.table !== 'Calendars' && data?.data?.table !== 'Instances') {
      return;
    }

    if (!this.isCurrentView()) {
      return;
    }

    this.updateAgenda();
    this.clearAddAgendaBlock();
  }

  onDateChange(): void {
    if (!this.isCurrentView()) {
      return;
    }
    // 刷新当前时间线
    this.ganttVMs.forEach(vm => vm.updateTimeLine());
    this.resetDayModelMatrix();
    this.updateAgenda();
    this.clearAddAgendaBlock();
  }

  onTimeTick(): void {
    if (!this.isCurrentView()) {
      return;
    }

    this.ganttVMs.forEach(vm => vm.updateTimeLine());
  }

  onTimezoneChange(): void {
    this.onDateChange();
    this.onDisplayDateChange();
  }

  onHourCycleChange(): void {
    RootModel.instance().is24HourClock = GlobalData.instance().get(GlobalDataKeys.IS_24_HOUR_CLOCK) as boolean;
    if (!this.isCurrentView()) {
      return;
    }

    this.resetHours();
    this.ganttVMs.forEach((vm) => vm.setCurHour());
  }

  onBackToToday(): void {
    RootModel.instance().displayDate = new CalendarDate().setHours(0, 0, 0, 0);
    this.swiperIndex = this.dateSwiperIndex;
    this.gantIndex = this.ganttSwiperIndex;
    Log.log(this.tag, `onBackToToday`);
    if (!this.isCurrentView()) {
      return;
    }
    this.clearAddAgendaBlock();

    if (this.dateVMs[this.dateSwiperIndex].isNowInRange()) {
      this.backToTodayFromSameWeek();
    } else {
      this.backToTodayFromOtherWeek();
    }
  }

  backToTodayFromSameWeek(): void {
    Log.log(this.tag, `backToTodayFromSameWeek`);
    const dStamp: number = new CalendarDate(RootModel.instance().displayDate).setHours(0, 0, 0, 0);
    const weekStartStamp: number = this.getWeekStartStamp(dStamp);
    const targetIndex = Math.floor((dStamp - weekStartStamp) / MILLS_PER_DAY);
    const oldIndex = this.selectDateIndex;
    const diff = targetIndex - oldIndex;
    if (diff === 0) { // 屏蔽多次点击
      return;
    }

    const isPast = diff < 0;
    const isNeighbour = Math.abs(diff) === 1;
    const ganttDiff = Math.floor(diff / Math.abs(diff));
    const newGanttIndex = (this.ganttSwiperIndex + ganttDiff + this.SWIPER_ITEM_COUNT) % this.SWIPER_ITEM_COUNT;
    this.selectDateIndex = targetIndex;

    // 选中框位移
    animateTo({
      duration: 400,
      curve: Curve.Friction,
      onFinish: () => this.backToTodaySameWeekUpdateCacheGanttViews(newGanttIndex, dStamp)
    }, () => {
      this.selectCirclePos = {
        x: this.isRTL ? this.weekTitleVM.rootWidth -
          ((this.weekTitleVM.dateCellWidth - (this.weekTitleVM.weekTitlePos.x as number)) +
          this.weekTitleVM.leftWidth + this.weekTitleVM.dateCellWidth * targetIndex) -
          // 分栏场景下应考虑分栏边距
          (this.inDivideWindow ? this.ganttMargin : 0) :
          ((this.weekTitleVM.weekTitlePos.x as number) +
          this.weekTitleVM.leftWidth + this.weekTitleVM.dateCellWidth * targetIndex) +
            (this.inDivideWindow ? this.ganttMargin : 0),
        y: this.dateHeight / 2
      };
      this.selectCircleAnchor = this.weekTitleVM.weekTitleAnchor;
    });

    // 今天变色
    animateTo({ duration: 100, curve: Curve.Friction, delay: 200 }, () => {
      this.dateVMs[this.dateSwiperIndex].setSelect(targetIndex);
    });


    if (this.isWeekView()) {
      return;
    }

    this.backToTodaySameWeekInDayGanttView(dStamp, newGanttIndex, isNeighbour, isPast);
  }

  // 日甘特图变化
  backToTodaySameWeekInDayGanttView(dStamp: number, newGanttIndex: number, isNeighbour: boolean, isPast: boolean): void {
    this.ganttSwiperIndex = newGanttIndex;

    if (isPast) {
      this.ganttSwiperController.showPrevious();
    } else {
      this.ganttSwiperController.showNext();
    }

    // 相邻视图不需要刷新，走普通的swiper逻辑即可
    if (isNeighbour) {
      return;
    }

    const dayModel = this.getDayModelByStamp(dStamp);
    // 日视图需要刷新甘特图数据
    this.updateGanttVM(newGanttIndex);
    this.clearAddAgendaBlock();
    this.ganttVMs[newGanttIndex].updateBlocks();
    this.ganttVMs[newGanttIndex].updateDayModels([dayModel]);
    this.selectAgendaInfo = this.ganttVMs[newGanttIndex].getDefaultChosenInfo();
  }

  // 日视图非相邻的情况下，动效结束后更新缓存的甘特视图
  backToTodaySameWeekUpdateCacheGanttViews(newGanttIndex: number, dStamp: number): void {
    if (this.isWeekView()) {
      return;
    }

    const offsetList = OFFSET_MATRIX[newGanttIndex];
    offsetList.forEach((offset: number, index: number) => {
      if (index === newGanttIndex) {
        return;
      }

      const startStamp = dStamp + offset * MILLS_PER_DAY;
      const dayModel = this.getDayModelByStamp(startStamp);
      this.ganttVMs[index].updateDayModels([dayModel]);
      this.ganttVMs[index].updateBlocks();
    });
    this.selectAgendaInfo = this.ganttVMs[newGanttIndex].getDefaultChosenInfo();
  }

  // 非当前周，需要刷新数据
  async backToTodayFromOtherWeek(): Promise<void> {
    Log.log(this.tag, `backToTodayFromOtherWeek`);
    this.resetDayModelMatrix();
    this.initGanttBlock();
    await this.updateAgenda();

    // 今天日期变色
  }

  // 获取指定时间戳所在周的一周开始时间戳
  getWeekStartStamp(stamp: number): number {
    const date: CalendarDate = new CalendarDate(stamp);
    const dayOffset: number = date.getDay() - this.weekTitleVM.startOfWeek;
    const dayToStart: number = dayOffset >= 0 ? dayOffset : (DAY_PER_WEEK + dayOffset);
    let tempStamp = stamp - dayToStart * MILLS_PER_DAY;
    // 夏令时导致的特定日期一天只有23小时，偏移固定的N天毫秒数后，时间戳可能会由当天0点变为前一天的23点或者当天一点
    if (new CalendarDate(tempStamp).getHours() === 23) {
      tempStamp += MILLS_PER_HOUR;
    } else if (new CalendarDate(tempStamp).getHours() === 1) {
      tempStamp -= MILLS_PER_HOUR;
    }
    return tempStamp;
  }

  onDateSwiperAnimationEnd(index: number): void {
    Log.log(this.tag, `date swiper animation end index ${index} logic index ${this.dateSwiperIndex}`);
  }

  onGanttSwiperAnimationEnd(index: number): void {
    Log.log(this.tag, `gantt swiper animation end index ${index} logic index ${this.ganttSwiperIndex}`);
  }

  isWeekView(): boolean {
    return this.tabType === TabType.WEEK;
  }

  isNeedAdapt(): boolean {
    return this.ganttNeedAdapt;
  }

  isCurrentView(): boolean {
    return this.tabType === RootModel.instance().curTab;
  }

  isWeekDayView(): boolean {
    return this.tabType === TabType.DAY || this.tabType === TabType.WEEK;
  }

  public get dateSwipeFlag() {
    return this._dateSwipeFlag
  }

  public set dateSwipeFlag(dateSwipeFlag: boolean) {
    this._dateSwipeFlag = dateSwipeFlag
  }

  initVMs(): void {
    for (let i = 0; i < this.SWIPER_ITEM_COUNT; i++) {
      this.dateVMs.push(new DateViewModel(i, this));
      this.ganttVMs.push(new GanttViewModel(this));
    }

    for (let i = 0; i < DAY_PER_WEEK; i++) {
      this.weekTitleVM.staticWeekDayInfoList.push(new StaticWeekDayInfo(i));
    }

    for (let i = 0; i < this.HOUR_COUNT; i++) {
      this.hoursString.push('');
    }
  }

  initDayModelMatrix(): void {
    const date: CalendarDate = new CalendarDate();
    for (let i = 0; i < this.SWIPER_ITEM_COUNT; i++) {
      const list: DayModel[] = [];
      for (let j = 0; j < DAY_PER_WEEK; j++) {
        list.push(new DayModel(date));
      }
      this.dayModelMatrix.push(list);
    }
  }

  initParams(): void {
    const language = I18nUtil.getSystemLanguage();
    this.isRTL = i18n.isRTL(language);
    this.isAR = language.includes(ARABIC_LANGUAGE);
    this.weekTitleVM.onLanguageChange(language);
    this.weekTitleVM.weekends = GlobalData.instance().get(GlobalDataKeys.WEEKENDS) as number[];
    this.weekTitleVM.startOfWeek = GlobalData.instance().get(GlobalDataKeys.START_OF_WEEK) as number;
    this.weekTitleVM.startOfWeek =
      this.weekTitleVM.startOfWeek !== -1 ? this.weekTitleVM.startOfWeek : DateUtil.getDefaultStartOfWeek();
    RootModel.instance().displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    RootModel.instance().is24HourClock = GlobalData.instance().get(GlobalDataKeys.IS_24_HOUR_CLOCK) as boolean;
    this.language = GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string;
    this.weekTitleVM.weekTitle = DateUtil.getWeekTitle(false, this.language);
    this.subscriptionCalendar = GlobalData.instance().get(GlobalDataKeys.SUBSCRIPTION_CALENDAR) as number;
    this.systemRegion = GlobalData.instance().get(GlobalDataKeys.SYSTEM_REGION) as string;
    this.isShowWeekNumber = GlobalData.instance().get(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON) as boolean;
    RootModel.instance().curTab = GlobalData.instance().get(GlobalDataKeys.TAB_INDEX) as TabType;
    this.gridColCount = this.isWeekView() ? DAY_PER_WEEK : 1;
    this.hideAgendaWindow =
      PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT, TabType.DAY + GlobalDataKeys.TAB_INDEX, false);

    this.dividerHeight = this.isNeedAdapt() ? 16 : 32

    if (this.isNeedAdapt()) {
      this.weekTitleVM.leftWidth = this.LEFT_WIDTH_ADAPT;
      this.solarDateHeight = this.SOLAR_HEIGHT_ADAPT;
    } else {
      this.weekTitleVM.leftWidth = this.LEFT_WIDTH_PHONE;
      this.solarDateHeight = this.SOLAR_HEIGHT_PHONE;
      this.extraInfoHeight = this.EXTRA_HEIGHT_PHONE;
    }
  }

  // 全量更新每日数据
  resetDayModelMatrix(): void {
    const dStamp: number = RootModel.instance().displayDate;
    const weekStartStamp: number = this.getWeekStartStamp(dStamp);
    const offsetList: number[] = OFFSET_MATRIX[this.dateSwiperIndex];
    const selectDateIndex = Math.floor((dStamp - weekStartStamp) / MILLS_PER_DAY);
    this.setSelectCircleState(selectDateIndex);

    Log.log(this.tag, `date swiper index ${this.dateSwiperIndex} offset list ${offsetList}`);

    for (let i = 0; i < this.SWIPER_ITEM_COUNT; i++) {
      const offset: number = offsetList[i];
      const startStamp: number = weekStartStamp + offset * MILLS_PER_WEEK;
      this.updateDayModelList(startStamp, i);
    }

    for (let i = 0; i < this.SWIPER_ITEM_COUNT; i++) {
      this.updateDateVM(i);
      this.updateGanttVM(i);
    }

    this.updateDateRange();
  }

  initGanttBlock(): void {
    // 初始化时，先更新当前页面的基本信息
    this.ganttVMs[this.ganttSwiperIndex].updateBlocks();
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
  }

  // 更新单周的日期数据
  updateDayModelList(startStamp: number, weekIndex: number): void {
    const list: DayModel[] = this.dayModelMatrix[weekIndex];
    const date = new CalendarDate();
    const isShowCalendar = this.isShowCalendar();
    const isChineseRegion = this.isChineseRegion();
    for (let i = 0; i < DAY_PER_WEEK; i++) {
      const startOfDay = startStamp + i * MILLS_PER_DAY;
      date.setTime(startStamp + i * MILLS_PER_DAY);
      list[i].range = { start: startOfDay, end: startOfDay + MILLS_PER_DAY };
      list[i].resetDate(date);
      list[i].updateShowFestivals(isShowCalendar, isChineseRegion, this.chineseHolidayState);
    }
  }

  /**
   * 更新周日视图日期
   *
   * @param index 当前展示周
   */
  updateDateVM(index: number): void {
    const lastDate = this.dayModelMatrix[index][DAY_PER_WEEK - 1].getDate();
    this.dateVMs[index].weekIndexOfYear =
      CalendarUtils.getWeekNumber(lastDate, this.weekTitleVM.startOfWeek).toString();
    this.dateVMs[index].updateDayModels(this.dayModelMatrix[index]);
    this.dateVMs[index].setSelect(this.selectDateIndex);
  }

  updateGanttVM(index?: number): void {
    if (this.isWeekView() && index !== undefined) {
      // 计算当前日甘特图和周甘特图的偏移,用于更新甘特图日程区域
      const ganttIndex = (index - this.dateSwiperIndex + this.ganttSwiperIndex + this.SWIPER_ITEM_COUNT) %
      this.SWIPER_ITEM_COUNT;
      this.ganttVMs[ganttIndex].updateDayModels(this.dayModelMatrix[index]);
      return;
    }

    const dStamp = new CalendarDate(RootModel.instance().displayDate).setHours(0, 0, 0, 0);
    const offsetList = OFFSET_MATRIX[this.ganttSwiperIndex];
    offsetList.forEach((offset: number, index: number) => {
      const startStamp = dStamp + offset * MILLS_PER_DAY;
      const dayModel = this.getDayModelByStamp(startStamp);
      this.ganttVMs[index].updateDayModels([dayModel]);
    });
  }

  getDayModelByStamp(stamp: number): DayModel {
    let res = new DayModel(new CalendarDate(stamp));
    for (const dayModelList of this.dayModelMatrix) {
      const range: DateRange.Range = {
        start: dayModelList[0].range.start,
        end: dayModelList[dayModelList.length - 1].range.end
      };

      if (!DateRange.isDateInRange(stamp, range)) {
        continue;
      }

      for (const dayModel of dayModelList) {
        if (dayModel.range.start === stamp) {
          res = dayModel;
          break;
        }
      }
    }

    return res;
  }

  updateDateRange(): void {
    let start = Number.MAX_VALUE;
    let end = Number.MIN_VALUE;

    this.dayModelMatrix.forEach((dayModel: DayModel[]) => {
      start = Math.min(start, dayModel[0].range.start);
      end = Math.max(end, dayModel[dayModel.length - 1].range.end);
    });
    this.dateRange = { start, end };
  }

  async updateAgenda(): Promise<void> {
    await AgendaModel.instance().query(this.dateRange);

    Log.info(TAG, `update agenda success ${this.dateRange.start} ${this.dateRange.end}`);

    // 更新日期区域日程点
    this.dateVMs.forEach((dateVM: DateViewModel, index: number) => {
      this.dayModelMatrix[index].forEach((dayData: DayModel) => {
        dayData.agendaCount = AgendaModel.instance().getAgendaCountByRange(dayData.range, true, -1);
        dayData.festivalName = AgendaModel.instance().getFestivalNameByRange(dayData.range, -1);
      });
      dateVM.updateAgendaDot();
      dateVM.updateExtraInfo();
    });

    // 更新甘特图日程块
    hiTraceMeter.startTrace(traceEvents.updateBlocks, 0);
    this.ganttVMs.forEach((ganttVM: GanttViewModel) => ganttVM.updateBlocks());
    hiTraceMeter.finishTrace(traceEvents.updateBlocks, 0);
    if (this.selectAgendaInfo && AgendaModel.instance().findAgendaFromCache(this.selectAgendaInfo.mId)) {
      if (this.isDivide) { // 分栏模式因block重置需要通过选择日程刷新日程块选中态
        this.selectAgendaInfo =
          this.ganttVMs[this.ganttSwiperIndex].divideRefreshBlocksFocus(this.selectAgendaInfo?.mId,
            this.selectAgendaInfo?.mTitle);
      }
      return;
    }
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
    this.updateScrollOffsetByIndex(this.ganttSwiperIndex);
  }

  getMainTabComponentSize(): Geometry.GSize {
    const selfInfo = componentUtils.getRectangleById(`MainTabComponent`);
    const tabWidth = px2vp(selfInfo.size.width);
    const tabHeight = px2vp(selfInfo.size.height) - this.VIEW_PADDING_TOP;
    return { width: tabWidth, height: tabHeight }
  }

  initLayout(): void {
    const size: Geometry.GSize = this.getMainTabComponentSize()
    this.resetLayout(size);
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.calcScrollOffsetY()); // 初始化时间线展示
  }

  resetLayout(size: Geometry.GSize): void {
    this.weekTitleVM.rootWidth = size.width;
    this.rootHeight = size.height;
    this.extraInfoRight = this.weekTitleVM.rootWidth >= this.EXTRA_INFO_CHECK_WIDTH;
    this.inDivideWindow = size.width > this.DIVIDE_WIDTH;
    const isDayDivide = !this.isWeekView() && this.inDivideWindow;
    this.isDivide = isDayDivide && !this.hideAgendaWindow;
    this.dayGanttViewMargin = isDayDivide ? 16 : 0;
    if (this.extraInfoRight && !this.isWeekView()) {
      this.ganttWidth =
        this.isDivide ? Math.round(size.width / this.GOLD_DIVIDE) - this.ganttMargin * 2 :
          size.width - this.ganttMargin * 2;
    } else if (this.extraInfoRight && this.isWeekView()) {
      this.ganttWidth = size.width - this.ganttMargin * 2;
    } else if (!this.extraInfoRight && !this.isWeekView()) {
      this.ganttWidth = this.isDivide ? Math.round(size.width / this.GOLD_DIVIDE) - this.ganttMargin * 2 :
        (isDayDivide ? size.width - this.ganttMargin * 2 : size.width);
    } else {
      this.ganttWidth = size.width > this.DIVIDE_WIDTH ? size.width - this.ganttMargin * 2 : size.width;
    }
    this.detailWidth = this.isWeekView() ? 0 : size.width - this.ganttWidth - this.ganttMargin * 2;

    this.resetLayoutAdapt();

    this.dateHeight = this.isNeedAdapt() && this.inDivideWindow ?
    this.MAX_DATE_HEIGHT : (this.selectCircleRadius + 1) * 2 + 1;
    this.bottomHeight = size.height - this.weekTitleVM.weekTitleHeight - this.dateHeight -
    RootModel.instance().DATE_MARGIN_TOP - RootModel.instance().DATE_MARGIN_BOTTOM;

    this.setWeekTitlePosition();
    this.setSelectCircleState(this.selectDateIndex);
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.resetLayout(this.bottomHeight));
    this.dateVMs.forEach((vm: DateViewModel) => vm.resetLayout());
  }

  setWeekTitlePosition(): void {
    this.weekTitleVM.weekTitleAnchor = { x: '50%', y: '50%' };
    if (this.extraInfoRight) {
      const posX = this.dateMargin * 2 + this.agendaDotRadius * 2 + this.selectCircleRadius;
      this.weekTitleVM.weekTitlePos = { x: posX, y: this.weekTitleVM.weekTitleHeight / 2 };
    } else {
      this.weekTitleVM.weekTitlePos =
        { x: this.weekTitleVM.dateCellWidth / 2, y: this.weekTitleVM.weekTitleHeight / 2 };
    }
  }

  resetLayoutAdapt(): void {
    let targetIndex: number | undefined = this.dateViewLayout.getDateCellBreakPoint(this.weekTitleVM.rootWidth);
    if (targetIndex === undefined) {
      Log.debug(TAG, `targetIndex can not get ${targetIndex}`);
      return;
    }
    const dateLayout = this.dateViewLayout.dateCellBreakPoint[targetIndex].layout;

    this.weekTitleVM.weekTitleFontSize = dateLayout.weekTitleFontSize;
    this.solarDateFontSize = dateLayout.solarDateFontSize;
    this.agendaDotRadius = dateLayout.agendaDotRadius;
    this.extraInfoFontSize = dateLayout.extraInfoFontSize;
    this.selectCircleRadius = dateLayout.selectMaxCircleRadius;
    this.extraInfoCharCodeWidth = dateLayout.extraInfoCharCodeWidth;
    this.extraInfoHeight = dateLayout.extraInfoHeight;
    this.extraInfoAlign = this.extraInfoRight ? TextAlign.Start : TextAlign.Center;
    this.weekTitleVM.leftWidth = this.extraInfoRight ? this.LEFT_WIDTH_ADAPT : this.LEFT_WIDTH_PHONE;

    // 分栏场景下需要额外减去两边边距
    this.middleWidth = this.weekTitleVM.rootWidth - this.weekTitleVM.leftWidth - this.weekTitleVM.rightWidth;

    if (this.inDivideWindow) {
      this.middleWidth -= this.ganttMargin * 2;
    }
    this.weekTitleVM.dateCellWidth = this.middleWidth / DAY_PER_WEEK;
    this.ganttGridWidth = this.ganttWidth - this.weekTitleVM.leftWidth - this.weekTitleVM.rightWidth;
    this.ganttCellWidth = this.ganttGridWidth / this.gridColCount;

    this.weekTitleVM.solarDateWidth = this.solarDateFontSize * 2;
    this.solarDateHeight = this.solarDateFontSize + 2;
    this.extraInfoWidth = this.extraInfoRight ?
      this.weekTitleVM.dateCellWidth - this.agendaDotRadius * 2 - this.dateMargin * 4 - this.selectCircleRadius * 2 :
    this.EXTRA_INFO_BOTTOM_WIDTH;
  }

  calValueByRange(range: number[], ratio: number): number {
    return range[0] + (range[1] - range[0]) * ratio;
  }

  onSizeChange(size: Geometry.GSize): void {
    //再加一层判断,在转vp后判断高宽是否需要刷新
    if (this.weekTitleVM.rootWidth === size.width && this.rootHeight === size.height) {
      return;
    }

    this.resetLayout(size);
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.updateBlocks());
    //折叠屏展开后需要重置默认选中日程
    if (this.isDivide) {
      this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].divideRefreshBlocksFocus(this.selectAgendaInfo?.mId, this.selectAgendaInfo?.mTitle);
    } else {
      this.ganttVMs[this.ganttSwiperIndex].divideRefreshBlocksFocus(this.selectAgendaInfo?.mId, this.selectAgendaInfo?.mTitle);
    }
  }

  resetHours(): void {
    this.hoursString.forEach((_: string, index: number) => {
      const hour24: number = index + 1;
      const hour: number = hour24;
      this.hoursString[index] = `${NumberFormatManager.instance().numberFormat(hour).toString()}`;
    });
  }

  // 当前显示页更改
  onTabChange(curTab: TabType): void {
    RootModel.instance().curTab = curTab;
    this.clearGanttSelect(); // 切换显示页需要清除一下选中日程弹窗
    if (curTab !== TabType.WEEK && curTab !== TabType.DAY) {
      this.needAnimate = false; // 其他视图切换到周日视图不需要周日切换动效
      return;
    }

    if (curTab !== this.tabType) { // 切换视图且当前视图和原视图不一致则需要切换甘特图
      // 非分栏场景不需要执行动效
      this.inDivideWindow ? this.animateWeekDayChange(curTab) : this.weekDayChange(curTab);
    }

    Log.log(this.tag, `tab change to this view`);
    RootModel.instance().displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    this.clearAddAgendaBlock();
    this.weekTitleVM.resetWeekTitles(this.tabType);
    this.weekTitleVM.resetWeekends(this.dateVMs);
    this.resetHours();
    this.resetDayModelMatrix();
    this.initGanttBlock();
    this.updateAgenda();
    this.setGanttScrollOffset();
    Log.log(this.tag, `tab change to this view update done`);
  }

  // 非动效切换周日视图
  weekDayChange(curTab: TabType) {
    this.tabType = curTab;
    this.tag = this.isWeekView() ? this.TAG_WEEK : this.TAG_DAY;
    this.gridColCount = this.isWeekView() ? DAY_PER_WEEK : 1;
    this.resetLayout({ width: this.weekTitleVM.rootWidth, height: this.rootHeight });

    // 再次切换需要动效标识用于折叠屏切换
    this.needAnimate = true;
  }

  // 动效切换周日视图
  animateWeekDayChange(curTab: TabType) {
    // 先在分栏状态下把日程详情放出来用于动效
    this.isDivide = this.inDivideWindow && !this.hideAgendaWindow;
    animateTo({
      duration: this.needAnimate ? 300 : 0,
    }, () => {
      this.weekDayChange(curTab);
    });
  }

  // 用于DT测试的取消动效方法
  animateFlagChange(needAnimate: boolean) {
    this.needAnimate = needAnimate;
  }

  // 一周开始日更改
  onStartOfWeekChange(startOfWeek: number): void {
    Log.info(TAG, 'onStartOfWeekChange:' + startOfWeek);
    this.weekTitleVM.startOfWeek = startOfWeek;
    this.weekTitleVM.startOfWeek =
      this.weekTitleVM.startOfWeek !== -1 ? this.weekTitleVM.startOfWeek : DateUtil.getDefaultStartOfWeek();
    this.weekTitleVM.resetWeekTitles(this.tabType);
    this.weekTitleVM.resetWeekends(this.dateVMs);
    this.resetDayModelMatrix();
    this.updateAgenda();
  }

  // 中国节假日开关
  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE): void {
    this.chineseHolidayState = chineseHolidayState;
    this.dateVMs.forEach((vm: DateViewModel) => vm.onChineseHolidayStateChange());
  }

  //周数开关
  onShowWeekNumberChange(showWeekNumber: boolean): void {
    this.isShowWeekNumber = showWeekNumber;
  }

  onLanguageChange(language: string): void {
    this.isRTL = i18n.isRTL(language);
    this.isAR = language.includes(ARABIC_LANGUAGE);
    this.weekTitleVM.isAR = this.isAR;
    this.weekTitleVM.isRTL = this.isRTL;
    // 语言切换强制刷新dataFormat
    NumberFormatManager.instance().onLanguageChange(language);
    this.weekTitleVM.weekTitle = DateUtil.getWeekTitle(false, language);
    Log.info(this.tag, `rootView Update Language ${this.language} ${this.weekTitleVM.weekTitle}`);
    this.weekTitleVM.resetWeekTitles(this.tabType);
    this.dateVMs.forEach((vm: DateViewModel) => vm.updateLanguage(language));
    this.setSelectCircleState(this.selectDateIndex); // 变更圆圈位置
    this.resetHours(); // 重置小时数
    this.ganttVMs.forEach((vm: GanttViewModel) => {
      vm.onLanguageChange(language);
    });
  }

  set hideAgendaWindow(hideAgendaWindow: boolean) {
    this._hideAgendaWindow = hideAgendaWindow;
  }

  get hideAgendaWindow() {
    return this._hideAgendaWindow;
  }

  // 显示隐藏日程详情
  onAgendaListStateChange(hideAgendaWindow: boolean, animationTime: number = 300): void {
    if (this.hideAgendaWindow === hideAgendaWindow) {
      return;
    }

    this.hideAgendaWindow = hideAgendaWindow;
    // 先在分栏状态下把日程详情放出来用于动效
    this.isDivide = this.inDivideWindow;
    animateTo({
      duration: animationTime,
      curve: Curve.Friction,
    }, () => {
      this.resetLayout({ width: this.weekTitleVM.rootWidth, height: this.rootHeight });
    });
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.updateBlocks());
    // 分栏状态变化需要重新选中日程
    if (this.isDivide) {
      this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].divideRefreshBlocksFocus(this.selectAgendaInfo?.mId,
        this.selectAgendaInfo?.mTitle);
    } else {
      this.ganttVMs[this.ganttSwiperIndex].divideRefreshBlocksFocus(this.selectAgendaInfo?.mId,
        this.selectAgendaInfo?.mTitle);
    }
  }

  // 周末更改
  onWeekendsChange(weekends: number[]): void {
    this.weekTitleVM.weekends = weekends;
    this.weekTitleVM.resetWeekends(this.dateVMs);
  }

  // 历法信息更改
  onSubscriptionCalendarChange(subscriptionCalendar: number): void {
    this.subscriptionCalendar = subscriptionCalendar;
    if (!this.isCurrentView()) {
      return;
    }
    this.dateVMs.forEach((vm: DateViewModel) => vm.updateCalendar());
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.updateBlocks());
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
  }

  // 系统区域更改
  onSystemRegionChange(systemRegion: string): void {
    this.systemRegion = systemRegion;
    this.dateVMs.forEach((vm: DateViewModel) => vm.updateCalendar());
    this.ganttVMs.forEach((vm: GanttViewModel) => vm.updateBlocks());
  }

  // 是否显示农历
  isShowCalendar(): boolean {
    return this.subscriptionCalendar === SubscriptionCalendar.CHINESE_CALENDAR;
  }

  // 是否显示农历
  getChineseHolidayState(): CHINESE_HOLIDAY_STATE_VALUE {
    return this.chineseHolidayState;
  }

  // 不显示历法
  isNoCalendar(): boolean {
    return this.subscriptionCalendar === SubscriptionCalendar.NO_CALENDAR;
  }

  getSubscriptionCalendar(): number {
    return this.subscriptionCalendar;
  }

  // 是否是中国区域
  isChineseRegion(): boolean {
    return this.systemRegion === 'CN' || this.systemRegion === 'MO' || this.systemRegion === 'HK' || this.systemRegion === 'TW';
  }

  getSystemRegion(): string {
    return this.systemRegion;
  }

  // 显示日期更改
  onDisplayDateChange(): void {
    Log.log(this.tag, `on display date change`);
    const date = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    if (RootModel.instance().displayDate === date || !this.isWeekDayView()) {
      RootModel.instance().displayDate = date;
      return;
    }

    if (!this.isCurrentView()) {
      return;
    }

    Log.log(this.tag, `on display date Change ${RootModel.instance()
      .displayDate} -> ${date}  timeZone: ${CalendarDate.timeZone}}`);
    RootModel.instance().displayDate = date;
    this.resetDayModelMatrix();
    this.initGanttBlock();
    this.updateAgenda();
    this.gantIndex = this.ganttSwiperIndex;
    this.swiperIndex = this.dateSwiperIndex;
  }

  // 通过swiper更改当前选中天
  async changeDayBySwiper(index: number, targetIndex: number): Promise<void> {
    // swiper动画被打断时，当前index等于目标index，视图无需切换更新
    Log.log(this.tag, `change index from ${index} to ${targetIndex} gantt swiper index ${this.ganttSwiperIndex}`);
    if (index === targetIndex || this.ganttSwiperIndex === targetIndex) {
      return;
    }

    ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchView, { SOURCE_PAGE: this.tabType, TYPE: 0 });

    const offset = this.getChangeOffset(targetIndex, index);
    const offsetStamp = offset * (this.isWeekView() ? MILLS_PER_WEEK : MILLS_PER_DAY);
    const newGanttIndex = (index + offset + this.SWIPER_ITEM_COUNT) % this.SWIPER_ITEM_COUNT;
    const newCellIndex = this.selectDateIndex + offset;
    this.ganttSwiperIndex = newGanttIndex;

    this.clearAddAgendaBlock();
    this.clearGanttSelect();

    // 未切换周，需要动画
    if (!this.isWeekView() && newCellIndex >= 0 && newCellIndex < DAY_PER_WEEK) {
      Log.log(this.tag, `change day by gantt swiper ${index} -> ${targetIndex}`);
      this.setSelectCircleState(newCellIndex);
      this.setDisplayDate(RootModel.instance().displayDate + offsetStamp);
      this.updateGanttVM();
      this.ganttVMs.forEach((vm: GanttViewModel) => vm.updateBlocks());
      this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
      return;
    }

    // 切换周
    const selectDateIndex = this.isWeekView() ? this.selectDateIndex : (newCellIndex + DAY_PER_WEEK) % DAY_PER_WEEK;
    const newWeekIndex = (this.dateSwiperIndex + offset + this.SWIPER_ITEM_COUNT) % this.SWIPER_ITEM_COUNT;
    const weekChangeIndex = this.getChangeIndex(newWeekIndex, this.dateSwiperIndex);
    const weekOffset = this.getChangeOffset(newWeekIndex, this.dateSwiperIndex);
    const startStamp = this.getDayStamp(newWeekIndex, 0) + weekOffset * MILLS_PER_WEEK;
    this.dateSwiperIndex = newWeekIndex;

    Log.log(this.tag, `change week by gantt swiper ${index} -> ${targetIndex} ${this.dateSwiperIndex} -> ${newWeekIndex}`);
    this.setDisplayDate(RootModel.instance().displayDate + offsetStamp);
    await this.updateCacheChangedWeek(startStamp, weekChangeIndex);
    this.updateGanttVM(weekChangeIndex);

    this.setSelectCircleState(selectDateIndex);
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();

    if (this.isWeekView()) { // 周视图不需要翻页动画而是直接刷新日期
      this.dateSwiperController.changeIndex(this.dateSwiperIndex, false);
      const changeIndex = this.getChangeIndex(targetIndex, index);
      this.ganttVMs[changeIndex].updateBlocks();
      return;
    }

    if (newCellIndex < 0) {
      this.dateSwiperController.showPrevious();
    } else {
      this.dateSwiperController.showNext();
    }
  }

  // 通过swiper更改周
  async changeWeekBySwiper(index: number, targetIndex: number): Promise<void> {
    // swiper切换动画被打断时当前索引和目标索引一致
    if (index === targetIndex || this.dateSwiperIndex === targetIndex) {
      Log.warn(this.tag, `no change index:${index} targetIndex:${targetIndex} dateSwiperIndex:${this.dateSwiperIndex}`);
      return;
    }

    Log.log(this.tag, `change week by dateswiper ${index} ${targetIndex}`);
    ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchView, { SOURCE_PAGE: TabType.WEEK, TYPE: 0 });

    const changeIndex = this.getChangeIndex(targetIndex, index);
    const offset = this.getChangeOffset(targetIndex, index);
    const offsetStamp = offset * MILLS_PER_WEEK;
    const startStamp = this.getDayStamp(targetIndex, 0) + offsetStamp;
    this.dateSwiperIndex = targetIndex;
    this.clearAddAgendaBlock();
    this.clearGanttSelect();

    await this.updateCacheChangedWeek(startStamp, changeIndex);
    //更新选中日期
    this.setDisplayDate(RootModel.instance().displayDate + offsetStamp);

    if (this.isWeekView()) { // 周视图需要刷新缓存,并翻页移动到对应甘特图
      const newGanttSwiperIndex = (this.ganttSwiperIndex + offset + this.SWIPER_ITEM_COUNT) % this.SWIPER_ITEM_COUNT;
      const ganttChangeIndex = this.getChangeIndex(newGanttSwiperIndex, this.ganttSwiperIndex);
      this.ganttVMs[ganttChangeIndex].updateDayModels(this.dayModelMatrix[changeIndex]);
      this.ganttVMs[ganttChangeIndex].updateBlocks();
      this.dateSwipeFlag = true; // 标记用来防止触发翻页更新方法
      this.ganttSwiperIndex = newGanttSwiperIndex;
      this.ganttSwiperController.changeIndex(this.ganttSwiperIndex, false);
    } else { // 日视图需要全量刷新甘特图数据
      this.updateGanttVM();
      this.ganttVMs.forEach(vm => vm.updateBlocks());
    }
    //更新时间线、日视图默认选中日程
    this.updateScrollOffsetByIndex(this.ganttSwiperIndex);
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
  }

  // 更新缓存改变的周
  async updateCacheChangedWeek(startStamp: number, changeIndex: number): Promise<void> {
    // 更新日期、日期区间信息
    this.updateDayModelList(startStamp, changeIndex);
    this.updateDateRange();
    this.updateDateVM(changeIndex);

    // 刷新日程
    await AgendaModel.instance().query(this.dateRange);
    this.dayModelMatrix[changeIndex].forEach((dayData: DayModel) => {
      dayData.agendaCount = AgendaModel.instance().getAgendaCountByRange(dayData.range, true, -1);
      dayData.festivalName = AgendaModel.instance().getFestivalNameByRange(dayData.range, -1);
    });
    this.dateVMs[changeIndex].updateAgendaDot();
    this.dateVMs[changeIndex].updateExtraInfo();
  }

  // 获取日期单元格时间戳
  getDayStamp(swiperIndex: number, cellIndex: number): number {
    return this.dayModelMatrix[swiperIndex][cellIndex].getTimeStamp();
  }

  // 设置显示日期时间戳
  setDisplayDate(stamp: number): void {
    // 夏令时导致的特定日期一天只有23小时，偏移固定的N天毫秒数后，时间戳可能会由当天0点变为前一天的23点或者当天一点
    if (new CalendarDate(stamp).getHours() === 23) {
      stamp += MILLS_PER_HOUR;
    } else if (new CalendarDate(stamp).getHours() === 1) {
      stamp -= MILLS_PER_HOUR;
    }
    RootModel.instance().displayDate = stamp;
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, stamp);
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
  }

  // 设置选中圈的位置
  setSelectCircleState(cellIndex: number): void {
    this.selectDateIndex = cellIndex;
    this.dateVMs.forEach((vm: DateViewModel) => vm.setSelect(cellIndex));


    const cellOffset = this.weekTitleVM.dateCellWidth * cellIndex;
    // 基础偏移量
    const baseX = (this.weekTitleVM.weekTitlePos.x as number) + this.weekTitleVM.leftWidth + cellOffset;
    const rtlX = this.weekTitleVM.dateCellWidth - (this.weekTitleVM.weekTitlePos.x as number) +
      this.weekTitleVM.leftWidth + cellOffset;
    // 分栏场景下加上侧边距偏移量
    const marginOffset = this.inDivideWindow ? this.ganttMargin : 0;
    const x = this.isRTL ?
      // 镜像语言下，用全部宽度减去偏移量
      this.weekTitleVM.rootWidth - rtlX - marginOffset : baseX + marginOffset;
    this.selectCirclePos = {
      x: x,
      y: this.dateHeight / 2
    };

    this.selectCircleAnchor = this.weekTitleVM.weekTitleAnchor;
  }

  // 点击显示日期
  changeDayByClickDateCell(swiperIndex: number, cellIndex: number): void {
    if (this.isWeekView()) {
      ReportUtil.reportStatisticEvent(statisticEvents.weekClickDate);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.dayClickDate);
    }
    if (this.selectDateIndex === cellIndex) {
      if (this.isWeekView()) {
        this.jumpToOtherTab(TabType.DAY);
      } else {
        // 单击跳转回月视图
        this.jumpToOtherTab(TabType.MONTH);
      }
      return;
    }

    this.setDisplayDate(this.dayModelMatrix[swiperIndex][cellIndex].getTimeStamp());
    this.setSelectCircleState(cellIndex);

    if (this.isWeekView()) {
      return;
    }

    this.updateGanttVM();
    this.ganttVMs.forEach((vm: GanttViewModel) => {
      vm.updateBlocks();
      vm.hideAddAgendaBlock();
    });
    this.selectAgendaInfo = this.ganttVMs[this.ganttSwiperIndex].getDefaultChosenInfo();
  }

  // 跳转至其他tab
  jumpToOtherTab(tabType: TabType) {
    GlobalData.instance().set(GlobalDataKeys.TAB_INDEX, tabType);
    let eventData: emitter.EventData = {
      data: {
        'tabIndex': tabType,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData)
  }

  // 获取需要更新的swiperItem的索引
  getChangeIndex(newIndex: number, oldIndex: number): number {
    return this.SWIPER_ITEM_COUNT - newIndex - oldIndex;
  }

  // 获取当前显示的swiperItem相对旧item的索引差
  getChangeOffset(newIndex: number, oldIndex: number): number {
    const diff = newIndex - oldIndex;
    return diff === -1 || diff === 2 ? -1 : 1;
  }

  onBreakpointChange(bp: string) {
    if (bp === 'xs') {
      this.timeFontSize = 10;
      this.currentTimeFontSize = 10;
      this.allDayTitleFontSize = 10;
    } else {
      this.timeFontSize = 14;
      this.currentTimeFontSize = 12;
      this.allDayTitleFontSize = 14;
    }
  }

  // 隐藏添加日程块
  clearAddAgendaBlock() {
    this.ganttVMs.forEach((ganttVM) => {
      ganttVM.hideAddAgendaBlock();
    })
  }

  // 初始化甘特图的缩放,因周日视图甘特图缩放需要同步
  initGanttScale(scale: number) {
    // 缩放倍率为1无需处理
    if (scale === 1) {
      return;
    }

    this.ganttVMs.forEach((ganttVMS, index) => {
      ganttVMS.initOriginalGanttViewScale();
      ganttVMS.updateGanttViewScale(scale, true);
      ganttVMS.initOriginalGanttViewScale(false);
    })
  }

  // 同步缩放倍率
  ganttScaleChange(data: emitter.EventData): void {
    if (!data?.data) {
      return;
    }
    const scale: number = data.data['scale'];
    const pinchY: number = data.data['pinchY'];
    const tabType: number = data.data['tabType'];

    this.ganttVMs.forEach((ganttVMS, index) => {
      // 当前页面已缩放,无需再进行缩放操作
      if (this.ganttSwiperIndex !== index || this.tabType !== tabType) {
        ganttVMS.initOriginalGanttViewScale(true, pinchY);
        ganttVMS.updateGanttViewScale(scale, true);
      }
      // 缩放结束后的参数赋值
      ganttVMS.initOriginalGanttViewScale(false);
    })
  }

  // 清除甘特图选中日程
  clearGanttSelect() {
    this.ganttVMs.forEach((ganttVMS, index) => {
      ganttVMS.clearPop();
      ganttVMS.resetFocus();
    });
  }

  private timeChangeHandler: () => void = (): void => {
  };
  private dateChangeHandler: () => void = (): void => {
  };
  private timeTickHandler: () => void = (): void => {
  };
  private timezoneChangeHandler: () => void = (): void => {
  };
  private dataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  private hourCycleChangeHandler: () => void = (): void => {
  };
  private systemRegionChangeHandler: () => void = (): void => {
  };
  private backToTodayHandler: () => void = (): void => {
  };
  private displayDateChangeHandler: () => void = (): void => {
  };
  private jumpToSomedayHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  private swipeMainPageHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  private scaleChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
}