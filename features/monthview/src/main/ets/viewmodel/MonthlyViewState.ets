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
  CHINESE_HOLIDAY_STATE_VALUE,
  DateUtil,
  FoldScreenType,
  GlobalDataKeys,
  I18nUtil,
  isChineseCalendar,
  Log,
  ModeUtil,
  MonthPreferencesKeys,
  PreferencesFiles,
  PreferencesUtil,
  SingleInstanceHelper,
  SubscriptionCalendar,
  TabType
} from '@app/common';
import { isIslamicCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';

const TAG: string = '[MonthlyView][State]';

// 月视图周显示状态下更新日期方向
export enum MonthlyWeekArrow {
  LAST = -1, // 上一周
  CURRENT, // 当周
  NEXT, // 下一周
}

// 月视图当前滑动的状态
export enum MonthAniType {
  NONE, // 处于月状态,暂未决定是上滑还是下滑
  MONTH_WEEK, // 处于月到周的中间态
  MONTH_FULL // 处于月到全屏的中间态
}

@Observed
export class MonthlyModeState {
  public isSmallFoldDevice: boolean = false; // 是否为上下折叠

  public isInSmallFold: boolean = false; // 是否处于小折叠外屏模式

  public isForceSmall: boolean = false; // 是否需要强制转小屏

  isInSmallFoldChange(isInSmallFold: boolean): boolean {
    this.isInSmallFold = isInSmallFold;
    return this.isInSmallFold;
  }

  isForceSmallChange(isForceSmall: boolean): boolean {
    this.isForceSmall = isForceSmall;
    return this.isForceSmall;
  }
}

@Observed
export class MonthlyViewState {
  public displayDate: number = 0; // 当前展示时间

  public startOfWeek: number = 0; // 一周开始日

  public currentDate: number = 0; // 当前天

  public showWeekNumber: boolean = false; // 是否展示周数

  public showImportantDay: boolean = false; // 是否展示重要日

  public subscriptionCalendar: number = 0; // 其它历法

  public weekends: number[] = []; // 周末

  public systemRegion: string = ''; // 系统地区

  public language: string = ''; // 系统语言

  public isAgendaRowMini: boolean = false; // 是否日程区域过小  PC/PAD/PHONE初始窗口可以显示, 避免冷启动场景从true->false发生变化导致刷新帧

  public isSmall: boolean = false;

  public hideAgendaWindow: boolean = false;

  public chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE = CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;

  /**
   * 根据一周开始日判断给定的索引是否是周末
   * @param index 需要判断的索引
   * @return 如果给定的索引是周末，返回true，否则返回false
   */
  isWeekendByStartOfWeek(index: number): boolean {
    return this.weekends.includes((index + this.startOfWeek) % 7)
  }

  /**
   * 返回伊斯兰历
   */
  isIslamicCalendar(): boolean {
    return this.subscriptionCalendar ==
    SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR;
  }

  /**
   * 当前不显示历法
   */
  isNoCalendar(): boolean {
    return this.subscriptionCalendar == SubscriptionCalendar.NO_CALENDAR;
  }
}


@Observed
export class DayViewState {
  public showCalendar: boolean = false; // 显示历法
  public showChineseHoliday: boolean = false; //
  public isBackToToday: boolean = false; //用来限制回到今天动画中选中圈的变更
  public isEditPan: boolean = false; // 跟手滑动以及上滑动画中不要去更新选中日
}

@Observed
export class MonthlyWeekState {
  public isWeekShow: boolean = false;

  public isFullShow: boolean = false;

  // 视图滑动范围，目前主要影响 中间视图控制柄的弯曲角度 取值范围 [0-100] 50:则处于中间月视图状态 0:箭头向上弯折 100：箭头向下弯折
  public currentVolume:number = 50;

  private _singleWeekBackgroundColorOpen: boolean = false;

  private _openOtherPage: boolean = false; //打开了其他页面（月视图不在顶层）

  changeIsWeekShow(isWeekShow: boolean, isSmallMode: boolean = false) {
    if (this.isWeekShow !== isWeekShow) {
      PreferencesUtil.putBooleanValue(PreferencesFiles.MONTH,
        isSmallMode ? MonthPreferencesKeys.MONTH_WEEK_SHOW_SMALL : MonthPreferencesKeys.MONTH_WEEK_SHOW, isWeekShow);
    }
    this.isWeekShow = isWeekShow;
  }

  changeIsFullShow(isFullShow: boolean, isSmallMode: boolean = false) {
    if (!isSmallMode && this.isFullShow !== isFullShow) {
      PreferencesUtil.putBooleanValue(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_FULL_SHOW, isFullShow);
    }
    this.isFullShow = isFullShow;
  }

  get singleWeekBackgroundColorOpen(): boolean {
    return this._singleWeekBackgroundColorOpen;
  }

  set singleWeekBackgroundColorOpen(singleWeekBackgroundColorOpen: boolean) {
    this._singleWeekBackgroundColorOpen = singleWeekBackgroundColorOpen;
  }

  get openOtherPage(): boolean {
    return this._openOtherPage;
  }

  set openOtherPage(openOtherPage: boolean) {
    this._openOtherPage = openOtherPage;
  }

}

// 状态管理器
export class MonthlyViewStateManager {
  public state: MonthlyViewState = new MonthlyViewState();
  public dayState: DayViewState = new DayViewState();
  public weekState: MonthlyWeekState = new MonthlyWeekState();
  public modeState: MonthlyModeState = new MonthlyModeState();

  constructor() {
  }

  static getInstance(): MonthlyViewStateManager {
    return SingleInstanceHelper.createOrGet(MonthlyViewStateManager, 'MonthlyViewStateManager');
  }

  init(displayDate: number,
       startOfWeek: number,
       currentDate: number,
       showWeekNumber: boolean,
       showImportantDay: boolean,
       subscriptionCalendar: number,
       weekends: number[],
       systemRegion: string,
       language: string,
       chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE,
       windowWidth: number): void {
    startOfWeek = DateUtil.getStartOfWeek(startOfWeek);
    weekends = this.parseWeekends(weekends);
    this.state.displayDate = displayDate;
    this.state.startOfWeek = startOfWeek;
    this.state.currentDate = currentDate;
    this.state.showWeekNumber = showWeekNumber;
    this.state.showImportantDay = showImportantDay;
    this.state.weekends = weekends;
    this.state.systemRegion = systemRegion;
    this.state.language = language;
    this.state.chineseHolidayState = chineseHolidayState;
    this.state.hideAgendaWindow = PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT,
      TabType.MONTH + GlobalDataKeys.TAB_INDEX, false);
    this.modeState.isSmallFoldDevice =
      AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE) === FoldScreenType.SMALL_UP_DOWN_FOLD;
    this.modeState.isInSmallFoldChange(ModeUtil.isSmallUpDownFoldMode(AppStorage.get(GlobalDataKeys.UNUSUAL_MODE)));
    this.onSubscriptionCalendar(subscriptionCalendar)
    this.onSystemRegionChange(systemRegion);
    this.initWeekShowState();
    this.state.isAgendaRowMini = windowWidth < 600 && !this.weekState.isFullShow;
    Log.info(TAG, `MonthlyView State init, state = ${this.state.displayDate} ${this.state.currentDate}` +
      ` ${this.state.startOfWeek} ${this.state.systemRegion} ${this.state.language} ` +
      `${chineseHolidayState} ${this.state.hideAgendaWindow}`);
  }

  initWeekShowState() {
    if (this.modeState.isInSmallFold) {
      let monthWeekShow: boolean =
        PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_WEEK_SHOW_SMALL, true);
      this.weekState.isWeekShow = monthWeekShow;
      this.weekState.isFullShow = false;
      return;
    }
    let monthWeekShow: boolean =
      PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_WEEK_SHOW, false);
    this.weekState.isWeekShow = monthWeekShow;
    let monthFullShow: boolean =
      PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_FULL_SHOW, false);
    this.weekState.isFullShow = monthFullShow;
    Log.info(TAG, `MonthlyView weekShow init, state = ${monthWeekShow} ${monthFullShow}`);
  }

  onDisplayDateChange(displayDate: number): void {
    // 展示日期变更
    this.state.displayDate = displayDate;
  }

  onShowWeekNumberChange(showWeekNumber: boolean): void {
    // 周数开关变更
    this.state.showWeekNumber = showWeekNumber;
    Log.info(TAG, `onShowWeekNumberChange showWeekNumber = ${this.state?.showWeekNumber}`);
  }

  onShowImportantDayChange(showImportantDay: boolean): void {
    // 重要日开关变更
    this.state.showImportantDay = showImportantDay;
    Log.info(TAG, `onShowImportantDayChange showImportantDay = ${this.state?.showImportantDay}`);
  }

  onTabsIndexChange(): void {
    // Tabs 索引变更
  }

  onStartOfWeekChange(startOfWeek: number): void {
    // 一周开始日 数据变更
    this.state.startOfWeek = DateUtil.getStartOfWeek(startOfWeek);
    Log.info(TAG, `onStartOfWeekChange startOfWeek = ${this.state?.startOfWeek}`);
  }

  onWeekendsChange(weekends: number[]): void {
    // 周末 数据变更
    this.state.weekends = this.parseWeekends(weekends);
    Log.info(TAG, `onWeekendsChange weekends = ${this.state?.weekends}`);
  }

  /**
   * 讲周末数字进行转化，去除数组内的-1（默认区域），若数组有-1值则返回默认[0,6](周日、周六)
   *
   * @param weekends
   * @returns
   */
  parseWeekends(weekends: number[]): number[] {
    return weekends.includes(-1) ? [0, 6] : weekends;
  }

  onCurrentDateChange(currentDate: number): void {
    // 当天时间变更。跨天场景
    this.state.currentDate = currentDate;
  }

  onSubscriptionCalendar(subCalendar: number): void {
    // 历法状态变更
    this.state.subscriptionCalendar = subCalendar;
    this.dayState.showCalendar = isChineseCalendar(subCalendar) || isIslamicCalendar(subCalendar);
  }

  onLanguageChange(language: string) {
    this.state.language = language;
  }

  /**
   * 处理系统地区变化
   */
  onSystemRegionChange(systemRegion: string) {
    this.state.systemRegion = systemRegion;
    this.dayState.showChineseHoliday = I18nUtil.isChineseRegion();
  }

  /**
   * 是否隐藏月视图日程列表
   * @param hideAgendaWindow
   */
  onAgendaListStateChange(hideAgendaWindow: boolean): void {
    this.state.hideAgendaWindow = hideAgendaWindow;
  }

  /**
   * 限制动画过程中圆圈的点击
   * @param isBackToToday
   */
  onIsBackingToTodayChange(isBackToToday: boolean) {
    this.dayState.isBackToToday = isBackToToday;
  }

  /**
   * 限制动画过程中圆圈的点击
   * @param isBackToToday
   */
  onIsEditPanChange(isEditPan: boolean) {
    this.dayState.isEditPan = isEditPan;
  }
}

