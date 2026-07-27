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
  behaviorEvents,
  CalendarDate,
  CalendarUtils,
  CHINESE_HOLIDAY_STATE_VALUE,
  DateUtil,
  DayData,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_WEEK,
  MonthPreferencesKeys,
  PreferencesFiles,
  PreferencesUtil,
  ReportHiEventParams,
  ReportUtil,
  SafeUtil,
  ServiceEnum,
  ServiceManager,
} from '@app/common';
import { SingleWeekViewModel, SingleWeekViewModelArray } from './SingleWeekViewModel';
import { MonthlyInfo, DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { WeekNumViewModel } from './WeekNumViewModel';
import { MonthAniType, MonthlyViewState, MonthlyViewStateManager, MonthlyWeekArrow } from './MonthlyViewState';
import { SingleMonthAgendaManager } from './SingleMonthAgendaManager';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { MonthStaticLayout, WeekAgendaLayout } from '../layoutmodel/FrameLayoutRule';
import { ReadOnlyDayCellProp } from '../layoutmodel/DayCellLayoutRule';
import componentUtils from '@ohos.arkui.componentUtils';
import {
  broadcastFullScreenStatus,
  broadcastSingleWeekStatus
} from '@app/common/src/main/ets/util/AccessibilityUtil';
import { util } from '@kit.ArkTS';
import { WeekTitleLayout } from '../layoutmodel/WeekTitleLayoutRule';
import { MonthAgendaListViewModel } from './MonthAgendaListViewModel';
import { DateBannerViewModel } from './DateBannerViewModel';

const TAG: string = '[MonthlyView][SigMonthVM]';

const MAX_WEEK_ACCOUNT: number = 6;

@Observed
export class SingleMonthlyViewModelArray extends Array<SingleMonthlyViewModel> {
}

@Observed
export class WeekTitlesArray extends Array<string> {
}

@Observed
export class SingleMonthlyViewModel {
  // 当月的上一个月份的VM，如果自身已在最左则存放最右边的月份
  public lastMonthVM: SingleMonthlyViewModel | undefined;
  // 当月的下一个月份的VM，如果自身已在最右则存放最左边的月份
  public nextMonthVM: SingleMonthlyViewModel | undefined;
  // 当月的年月信息
  public curMonthlyInfo: MonthlyInfo;
  // 周视图的数据模型
  public weekViewModels: SingleWeekViewModelArray = new SingleWeekViewModelArray();
  //dateBanner数据模型
  public dateBannerVM: DateBannerViewModel = new DateBannerViewModel();
  // 周数的数据模型
  public weekNumViewModel: WeekNumViewModel;
  // 当月周数
  public weekAccount: number = 5;
  // 布局用参数
  public weekTemplate: string = '1fr 1fr 1fr 1fr 1fr';
  // 当前此视图绑定的 VM 在数组内的索引
  public arrayIndex: number | undefined = 0;
  // 一周开始日
  public startOfWeek: number = 0;
  // 月视图绑定的布局参数
  public state: MonthlyViewState = MonthlyViewStateManager.getInstance().state;
  // 单月视图绑定的日程管理员
  public sigAgendaManager: SingleMonthAgendaManager;
  // 单月视图绑定的日程列表视图ViewModel
  public agendaListModel: MonthAgendaListViewModel;
  // 当月视图的选中时间（由于规格问题，存在系统选中时间和视图选中时间不一致的情况（当前需要在其他月份有默认选中态（当月一号）））
  public selectDate: DateInfo = new DateInfo();
  // 重要日开关
  public showImportantDay: boolean = false;
  // 动画的选中圈的X坐标
  public circleX: number = 0;
  // 动画的选中圈的Y坐标
  public circleY: number = 0;
  // 动画的过程中需要显示，动画结束后消失
  public isCircleVisible: boolean = false;
  // 动画的过程中需要显示，动画结束后消失
  public isCircleVisible2: boolean = false;
  // 动画的过程中需要显示，动画结束后为非实心
  public isCircleSolid: number = 0;
  // 动画的选中圈的缩放大小
  public circleScale: number = 1;
  // 动画实心圈显隐的控制
  public fillCircleOpacity: number = 0;
  // 动画的选中圈的大小
  public circleRadius: number = 0;
  // 背景板的高宽
  public bgWidth: number = 0;
  public bgHeight: number = 0;
  public dayLayoutWidth: number = 0;
  public bgDayHeight: number = 0;
  public isVerticalCell: boolean = false;
  // 视图滑动范围，目前主要影响 中间视图控制柄的弯曲角度 取值范围 [0-100] 50:则处于中间月视图状态 0:箭头向上弯折 100：箭头向下弯折
  public currentVolume: number = 50;
  public readonly MAX_AGENDA_WIDTH = 420; // 最大日程列表宽度
  public readonly MIN_AGENDA_HEIGHT = 200; // 最小日程列表高度
  public readonly MIN_AGENDA_HEIGHT_CHECK = 150; // 最小日程列表高度,用于判断是否能够下滑
  public isWeekShow: boolean = false; // 是否处于周视图状态
  public isFullShow: boolean = false; // 是否处于全屏月视图状态
  private aniState: number = MonthAniType.NONE; // 当前所处于的状态,为月状态-月到周状态和月到全屏状态
  private maxHeight: number = 0; // 用于存储当前月视图最大扩展高度
  private canFullShow: boolean = true; // 用于判断当前是否能够扩展全屏的参数
  private weekAniHeight: number = 0; // 存储记录动效执行时周当前高度的参数
  public showWeekNum: number = -1; // 当前选中的周标识
  public editHeight: number = 0; // 动效过程中月视图高度
  public isPanEdit: boolean = false; // 是否处于跟手更新月视图状态中
  public hideAgendaWindow: boolean = false; // 是否处于月视图日程列表隐藏态
  public showDivider: boolean = true; // 用于分割线动效的显示用参数
  // 月视图上滑状态
  private readonly ANIMATION_TIME = 300;
  private readonly CHANGE_MIN_MOVE = 50; // 移动多少距离触发月视图下滑
  private initHeight: number = 0; // 动效开始时月视图初始高度
  private nowMonthHeight: number = 0;
  private nowWeekHeight: number = 0;
  // 用于存储计算周日程高度的参数
  private normalMonthHeight: number = 0;
  private normalDayHeight: number = 0;
  private nowWeekAgendaRow: number = 0;
  public agendaListViewMinHeight: number = 0; // 直板机月视图日程区域最小高度，用于周视图下滑动效约束
  public agendaListViewHeight: number = 0; // 直板机月视图日程区域高度
  private timeOutId: number = -1;
  private _aniUUID: string = ''; // 用于判断是否需要打断动效的随机数
  private oldWeekShow: boolean = false; // 用于打断动效的旧记录参数
  private oldIsMini: boolean = MonthlyViewStateManager.getInstance().state.isAgendaRowMini;

  constructor(dateInfo: DateInfo, arrayIndex?: number) {
    this.startOfWeek = this.state.startOfWeek;
    this.showImportantDay = this.state.showImportantDay;
    this.curMonthlyInfo = new MonthlyInfo(dateInfo.year, dateInfo.month, this.startOfWeek);
    this.arrayIndex = arrayIndex;
    this.sigAgendaManager = new SingleMonthAgendaManager(this);
    this.agendaListModel = new MonthAgendaListViewModel(this.sigAgendaManager, arrayIndex);
    this.updateWeekShow(MonthlyViewStateManager.getInstance().weekState.isWeekShow);
    this.isFullShow = MonthlyViewStateManager.getInstance().weekState.isFullShow;
    if (this.isWeekShow) {
      this.updateSelectDate(dateInfo);
    }
    this.sigAgendaManager.getCurrentMonthAgenda();
    this.weekNumViewModel = new WeekNumViewModel(this.startOfWeek, this.curMonthlyInfo);
    this.buildSingleWeekViewModels();
    this.initDateBannerViewModel();
  }
  // 改变天宫格的选中状态
  public onSelectChange: () => void = () => {
  };

  get aniUUID() {
    return this._aniUUID;
  }

  set aniUUID(aniUUID: string) {
    this._aniUUID = aniUUID;
  }

  /**
   * 初始化DateBanner中的参数
   */
  initDateBannerViewModel() {
    this.dateBannerVM.subscriptionCalendar = this.state.subscriptionCalendar;
    this.dateBannerVM.systemRegion = this.state.systemRegion;
    this.dateBannerVM.currentDate = this.state.currentDate;
  }

  /**
   * 初始化 SingleWeekViewModels
   */
  buildSingleWeekViewModels(): void {
    const displayDays = this.curMonthlyInfo.getDisplayDays();
    const weekNumbers = this.weekNumViewModel.weekNumbers;
    this.weekViewModels = new Array(MAX_WEEK_ACCOUNT);
    for (let weekNumInd = 0; weekNumInd < MAX_WEEK_ACCOUNT; ++weekNumInd) {
      // 对于当月不存在的周赋予空值
      if (weekNumbers.length <= weekNumInd) {
        this.weekViewModels[weekNumInd] = new SingleWeekViewModel(-1);
        continue;
      }

      let dayDataArr: DayData[] = [];
      for (let index = 0; index < 7; ++index) {
        dayDataArr.push(displayDays[index + 7 * weekNumInd]);
      }
      this.weekViewModels[weekNumInd] = new SingleWeekViewModel(weekNumInd,
        dayDataArr, new DateInfo(this.curMonthlyInfo.solarYear, this.curMonthlyInfo.solarMonth,
          weekNumbers[weekNumInd]));
    }
    this.weekAccount = weekNumbers.length;
    this.weekTemplate = this.updateWeekTemplate(this.weekAccount);

    this.initSelectDay(true);
    if (this.isWeekShow) {
      this.weekViewModels.forEach((viewModel, index) => {
        const needShow = index === this.showWeekNum;
        viewModel.onVisibilityChange(needShow);
        viewModel.isSelect = needShow;
      })
    }
  }

  // 更新月视图背板的周显示状态
  updateWeekTemplate(weekAccount: number) {
    let string = '';
    if (MonthlyViewStateManager.getInstance().weekState.isWeekShow) {
      return '1fr';
    }

    for (let i = 0; i < weekAccount; i++) {
      string = string + ' 1fr';
    }
    return string.length === 0 ? '1fr 1fr 1fr 1fr 1fr' : string.slice(1);
  }

  /**
   * 根据当前的 curMonthlyInfo 更新 SingleWeekViewModels
   */
  updateSingleWeekViewModels() {
    const displayDays = this.curMonthlyInfo.getDisplayDays();
    const weekNumbers = this.weekNumViewModel.weekNumbers;
    this.weekAccount = weekNumbers.length;
    const isSmall = MonthViewLayoutModel.getInstance().frameProp.value.isSmall;
    this.updateWeekAgendaRow(this.isFullShow || !isSmall ? this.normalMonthHeight : 0, this.normalDayHeight);
    this.updateNowWeekAgendaHeight(this.normalMonthHeight);
    const isWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    for (let weekNumInd = 0; weekNumInd < MAX_WEEK_ACCOUNT; ++weekNumInd) {
      // 对于当月不存在的周赋予空值
      if (weekNumbers.length <= weekNumInd) {
        this.weekViewModels[weekNumInd]?.update(-1);
        continue;
      }
      let dayDataArr: DayData[] = [];
      for (let index = 0; index < 7; ++index) {
        const tempDayData = displayDays[index + 7 * weekNumInd];
        dayDataArr.push(tempDayData);
        // 根据当前选中日期更新周视图的选中状态
        if (this.selectDate.year !== undefined &&
          this.selectDate.day === tempDayData.solarDay &&
          this.selectDate.month === tempDayData.solarMonth) {
          this.updateShowLine(weekNumInd);
        }
      }
      this.weekViewModels[weekNumInd]?.update(weekNumInd, dayDataArr,
        new DateInfo(this.curMonthlyInfo.solarYear, this.curMonthlyInfo.solarMonth, weekNumbers[weekNumInd]));
    }
    this.weekTemplate = this.updateWeekTemplate(this.weekAccount);
    this.updateWeekVisibility(!isWeekShow);
  }

  /**
   * 更新当月视图的视图日程列表管理员
   */
  updateSingleMonthAgendaManager(): void {
    Log.info(TAG, 'updateSingleMonthAgendaManager curMonthlyInfo = ' + this.curMonthlyInfo)
    this.sigAgendaManager.getCurrentMonthAgenda();
  }

  /**
   * 全量刷新当月视图
   */
  updateWeekNum(): void {
    this.weekNumViewModel = new WeekNumViewModel(this.startOfWeek, this.curMonthlyInfo);
  }

  async updateSelectDate(selectDate: DateInfo) {
    this.selectDate = selectDate;
    this.agendaListModel.selectDate = selectDate;
    this.dateBannerVM.selectDate = selectDate;
  }

  /**
   * 更新单月的模型
   */
  updateSingleMonth(monthlyInfo: MonthlyInfo, arrowState: number, arrowCount: number = 1, weekUpdate: boolean = false) {
    const newMonthlyInfo = this.getMonthlyInfoByArrowCount(monthlyInfo, arrowState, arrowCount);

    Log.info(TAG, `updateSingleMonth newMonth = ${newMonthlyInfo.solarYear} ${newMonthlyInfo.solarMonth}`);
    const weekShowUpdateFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    if (!weekUpdate && !weekShowUpdateFlag && this.curMonthlyInfo.toString() === newMonthlyInfo.toString()) {
      Log.debug(TAG, 'No Need To Refresh Month View In updateSingleMonth, monthlyInfo=' + newMonthlyInfo.toString());
      return;
    }
    this.curMonthlyInfo = newMonthlyInfo;
    this.updateWeekNum();
    this.updateSingleWeekViewModels();
    this.updateSingleMonthAgendaManager();
  }

  // 根据跳转方向和当前月份显示日期获取待更新的视图,同时初始化选择日期
  getMonthlyInfoByArrowCount(monthlyInfo: MonthlyInfo, arrowState: number, arrowCount: number): MonthlyInfo {
    let newMonthlyInfo = monthlyInfo;
    if (MonthlyViewStateManager.getInstance().weekState.isWeekShow) {
      let displayDate = this.state.displayDate || this.state.currentDate;
      for (let i = 0; i <= arrowCount; i++) {
        displayDate = displayDate + (arrowState * MILLS_PER_WEEK);
      }
      const displayDateInfo = new CalendarDate(displayDate);
      this.updateSelectDate(new DateInfo(displayDateInfo.getFullYear(), displayDateInfo.getMonth() + 1,
        CalendarUtils.getWeekNumberByDate(displayDateInfo, this.state.startOfWeek),
        displayDateInfo.getDate()));
      newMonthlyInfo = new MonthlyInfo(displayDateInfo.getFullYear(),
        displayDateInfo.getMonth() + 1, this.startOfWeek);
    } else {
      if (arrowState === MonthlyWeekArrow.CURRENT) {
        return monthlyInfo;
      }
      for (let i = 0; i < arrowCount; i++) {
        newMonthlyInfo = arrowState === MonthlyWeekArrow.LAST ? newMonthlyInfo.getLast() : newMonthlyInfo.getNext();
      }
    }
    return newMonthlyInfo;
  }

  /**
   * 将当月1号 或 实时时间当天 置为选中态 如果月视图是初始化状态，则按照当前展示时间进行初始化
   * @param isInit 是否是月视图初始化状态
   * @param isDefaultSelect 是否是月视图的日期默认处于选中状态
   */
  initSelectDay(isInit: boolean = false, isDefaultSelect: boolean = true): void {
    // 周视图状态更新选择日期是在视图初始化时更新
    if (!this.isWeekShow && isDefaultSelect) {
      const defaultSelectDate: DateInfo = this.getDefaultSelectDate(isInit);
      this.updateSelectDate(defaultSelectDate);
    }
    Log.info(TAG, `initSelectDay ${this.selectDate.month} ${this.selectDate.weekNum} ${this.selectDate.day}`);
    this.onDisplayDateChange(this.selectDate, isDefaultSelect);
    return;
  }

  /**
   * 更新视图的日期，去除当月的选中态 并设置新选中态
   */
  updateSelectDay(selectDate?: DateInfo): void {
    Log.info(TAG, `updateSelectDay ${selectDate?.month} ${selectDate?.weekNum} ${selectDate?.day}`);
    if (selectDate === null || selectDate === undefined) {
      // 选中时间未赋值，则赋予默认值
      this.clearSelectDay();
      this.initSelectDay();
      this.sigAgendaManager.analyzeAgendaInDate(selectDate);
      return;
    }
    if (this.selectDate?.year === selectDate.year &&
      this.selectDate?.month === selectDate.month &&
      this.selectDate?.day === selectDate.day) {
      Log.info(TAG, 'select Today No Need To update');
      return;
    }
    if (this.isWeekShow && this.selectDate.weekNum !== selectDate.weekNum) {
      // 周视图状态下选中时间不在当周则赋予默认值
      this.clearSelectDay();
      this.initSelectDay();
      this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
      return;
    }
    if (this.curMonthlyInfo.solarYear !== selectDate.year || this.curMonthlyInfo.solarMonth !== selectDate.month) {
      // 选中时间不在当月则赋予默认值
      this.clearSelectDay();
      this.initSelectDay();
      this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
      return;
    }
    this.clearSelectDay();
    this.updateSelectDate(selectDate);
    this.onDisplayDateChange(selectDate, true);
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
    return;
  }

  /**
   * 清除当月视图的选中态
   */
  clearSelectDay(): void {
    if (this.selectDate === null || this.selectDate === undefined) {
      return;
    }
    this.onDisplayDateChange(this.selectDate, false);
    return;
  }

  /**
   * 若视图月份 == 实时月份 则选中实时时间；非实时月份，则默认选中一号
   *
   * @param isInit 是否是月视图初始化状态
   * @returns Default Select Date
   */
  getDefaultSelectDate(isInit: boolean = false): DateInfo {
    if (MonthlyViewStateManager.getInstance().weekState.isWeekShow) {
      return this.getDefaultSelectDateOnWeekShow();
    }
    const curDate = isInit ? new CalendarDate(this.state.displayDate) : new CalendarDate(this.state.currentDate);
    const curDateInfo: DateInfo = new DateInfo(curDate.getFullYear(), curDate.getMonth() + 1, 0, curDate.getDate());
    const year: number = this.curMonthlyInfo.solarYear as number;
    const month: number = this.curMonthlyInfo.solarMonth as number;
    const day: number = (year === curDateInfo.year && month === curDateInfo.month) ? curDateInfo.day : 1;
    const defaultSelectDate: DateInfo = new DateInfo(year, month,
      CalendarUtils.getWeekNumberByDate(new CalendarDate(year, month - 1, day), this.state.startOfWeek), day);
    Log.info(TAG, 'defaultSelectDate = ' + defaultSelectDate + ', this.state.startOfWeek = ' + this.state.startOfWeek);
    return defaultSelectDate;
  }

  //周视图状态下获取选择日期
  getDefaultSelectDateOnWeekShow(): DateInfo {
    let year: number = this.curMonthlyInfo.solarYear as number;
    let month: number = this.curMonthlyInfo.solarMonth as number;
    let day: number = 1;
    for (let i = 0; i < this.weekAccount; i++) {
      if (i === this.showWeekNum) {
        const selectDayData = this.weekViewModels[i].dayViewModels[0].dayData
        year = selectDayData.solarYear;
        month = selectDayData.solarMonth;
        day = selectDayData.solarDay;
        break;
      }
    }

    const defaultSelectDate: DateInfo = new DateInfo(year, month,
      CalendarUtils.getWeekNumberByDate(new CalendarDate(year, month - 1, day), this.state.startOfWeek), day);
    return defaultSelectDate;
  }

  /**
   * 更新当前两天的数据
   *
   * @param curSelectDate
   * @param preSelectDate
   */
  onDisplayDateChange(selectDate: DateInfo, isSelect: boolean): void {
    const curYear = this.curMonthlyInfo.solarYear;
    const curMonth = this.curMonthlyInfo.solarMonth;
    Log.info(TAG, `onDisplayDateChange ${selectDate.month}, isSelect=${isSelect},year ${curYear}, month ${curMonth}`);
    if (selectDate.year === curYear && selectDate.month === curMonth) {
      this.weekViewModels.forEach((sigWeekVm: SingleWeekViewModel, index: number) => {
        const isSelectWeek = sigWeekVm.onSelectDateChange(selectDate, isSelect);
        this.updateShowLine(isSelectWeek ? index : this.showWeekNum);
      })
    }
  }

  onStartOfWeekChange(startOfWeek: number): void {
    Log.info(TAG, `onStartOfWeekChange: ${startOfWeek}`);
    this.startOfWeek = startOfWeek;
    const newMonthInfo = new MonthlyInfo(this.curMonthlyInfo.solarYear,
      this.curMonthlyInfo.solarMonth, startOfWeek);
    this.updateSingleMonth(newMonthInfo, MonthlyWeekArrow.CURRENT);
    const weekNum = CalendarUtils.getWeekNumberByDate(this.selectDate.getDate(), this.state.startOfWeek);
    this.selectDate.weekNum = weekNum;
    this.dateBannerVM.selectDate.weekNum = weekNum;
    this.onDisplayDateChange(this.selectDate, true);
  }

  onWeekendsChange(weekends: number[]) {
    this.updateSingleWeekViewModels(); // 通知各个VM变更样式
    this.onDisplayDateChange(this.selectDate, true);
  }

  onCurrentDateChange(currentDate: number): void {
    this.dateBannerVM.onCurrentDateChange(currentDate);
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel?.onCurrentDateChange(currentDate)
    })
  }

  onTimeZoneChange(currentDate: number): void {
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel?.onTimeZoneChange(currentDate)
    })
  }

  /**
   * 历法变更
   */
  onSubscriptionCalendar(subscription: number) {
    this.dateBannerVM.onSubscriptionCalendar(subscription);
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onSubscriptionCalendar(MonthlyViewStateManager.getInstance().dayState.showCalendar)
    })
  }

  onShowImportantDayChange(showImportantDay: boolean) {
    this.showImportantDay = showImportantDay;
    this.sigAgendaManager.onFestivalsChange(this.sigAgendaManager.agendaResult);
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onShowImportantDayChange(showImportantDay)
    })
  }

  /**
   * 深色模式变更
   */
  onDarkModeChange() {
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onDarkModeChange()
    })
  }

  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE) {
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onChineseHolidayStateChange(chineseHolidayState);
    })
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
  }

  /**
   * 处理布局变化
   */
  onLayoutChange() {
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onLayoutChange()
    })
  }


  /**
   * 地区变更
   */
  onSystemRegionChange(systemRegion: string) {
    this.dateBannerVM.onSystemRegionChange(systemRegion);
    //重新加载日程块信息
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onSystemRegionChange(systemRegion)
    })

    //重新加载当月信息
    const displayDays = this.curMonthlyInfo.getDisplayDays();
    const weekNumbers = this.weekNumViewModel.weekNumbers;
    for (let weekNumInd = 0; weekNumInd < weekNumbers.length; ++weekNumInd) {
      let dayDataArr: DayData[] = [];
      for (let index = 0; index < 7; ++index) {
        dayDataArr.push(displayDays[index + 7 * weekNumInd]);
      }
      this.weekViewModels[weekNumInd]?.update(weekNumInd, dayDataArr,
        new DateInfo(this.curMonthlyInfo.solarYear, this.curMonthlyInfo.solarMonth, weekNumbers[weekNumInd]));
    }
    //初始化选中日期
    this.initSelectDay();
  }

  /**
   * 处理数据变化广播
   */
  async onDataChange() {
    await this.sigAgendaManager.onDataChange();
  }

  //由小屏转为宽屏时如未初始化日程块则需要重新刷新日程块
  refreshAgendaBlock() {
    this.sigAgendaManager.onSigWeekAgendaChange(this.sigAgendaManager.agendaResult);
  }

  /**
   * 通知 VM 状态变更，触发视图刷新
   *
   * @param isTodayAgendaExist 日程列表是否存在日程
   */
  onIsTodayAgendaExistChange(isTodayAgendaExist: boolean = true, isTodayAgendaReady: boolean = true) {
    this.agendaListModel.isTodayAgendaExist = isTodayAgendaExist;
    this.agendaListModel.isTodayAgendaReady = true;
    this.agendaListModel.onIsTodayAgendasChange(isTodayAgendaExist, isTodayAgendaReady); // 触发视图刷新
  }

  onBackToTodayX() {
    this.parseCirclePositionX(new CalendarDate());
    Log.info(TAG, 'onBackToToday this.circleX = ' + this.circleX + ', this.circleY = ' + this.circleY)
  }

  onBackToTodayY() {
    this.parseCirclePositionY(new CalendarDate());
    Log.info(TAG, 'onBackToToday this.circleX = ' + this.circleX + ', this.circleY = ' + this.circleY)
  }

  onBackToTodayShow() {
    this.fillCircleOpacity = 1;
  }

  onBackToTodayColorChange(onlyColor: boolean = false) {
    this.weekViewModels.forEach((singleWeekViewModel: SingleWeekViewModel) => {
      singleWeekViewModel.onCurrentDateColor(onlyColor)
    })
  }

  onBackToTodayAppear() {
    // 初始化动画选中圈的状态
    this.isCircleVisible = true;
    this.fillCircleOpacity = 0;
    this.isCircleVisible2 = true;
    // 根据当前的选中时间 初始化选中圈位置
    this.initCircleSize();
    let nowDate = new CalendarDate(this.state.displayDate);
    this.parseCirclePositionX(nowDate);
    this.parseCirclePositionY(nowDate);
    Log.info(TAG, 'onBackToTodayAppear this.circleX = ' + this.circleX + ', this.circleY = ' + this.circleY)

  }

  // 非当月回到今天，初始化选中圈
  onInitSelectCircleFromOtherMonth() {
    // 初始化动画选中圈的状态
    this.isCircleVisible = false;
    this.fillCircleOpacity = 0;
    this.isCircleVisible2 = true;
    // 初始化选中圈的缩放比例
    this.circleScale = 0.5;
    // 根据当前的选中时间 初始化选中圈位置
    this.initCircleSize();
    let nowDate = new CalendarDate(this.state.currentDate);
    this.parseCirclePositionX(nowDate);
    this.parseCirclePositionY(nowDate);
    Log.info(TAG,
      'onInitSelectCircleFromOtherMonth this.circleX = ' + this.circleX + ', this.circleY = ' + this.circleY)
    this.agendaListModel.updateScrollToTop();
  }

  // 非当月回到今天，选中圈入场
  onAppearSelectCircleFromOtherMonth() {
    // 初始化选中圈的缩放比例
    this.isCircleVisible2 = true;
    this.fillCircleOpacity = 1;
    this.circleScale = 1;
  }

  // 非当月回到今天，选中圈出场，动画结束，由日程图层绘制选中圈
  onDisappearSelectCircleFromOtherMonth() {
    // 初始化选中圈的缩放比例
    this.isCircleVisible2 = false;
  }

  onBackToTodayDisappear() {
    this.isCircleVisible = false;
    this.isCircleSolid = 0;
    this.isCircleVisible2 = false;
  }

  initCircleSize() {
    const monthSize = componentUtils.getRectangleById(`sigMonth_${this.arrayIndex}`);
    const isSmall = MonthViewLayoutModel.getInstance().frameProp.value.isSmall;
    const paddingHeight = isSmall ? ReadOnlyDayCellProp.circleLine * 2 + WeekTitleLayout.marginDownGap : 0;
    const isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
    this.bgWidth = px2vp(monthSize.size.width) - (isGrid ? 0 : 16);
    this.bgHeight = px2vp(monthSize.size.height) - paddingHeight;
    const maxWidth = this.bgWidth * 0.142857;
    const circleSize = MonthViewLayoutModel.getInstance().dayLayout.value.circleSize;
    this.dayLayoutWidth = Math.min(circleSize, maxWidth);
    this.bgDayHeight = circleSize;
    this.isVerticalCell = MonthViewLayoutModel.getInstance().frameProp.value.isVerticalCell;
    if (isGrid) {
      this.circleRadius = this.bgDayHeight - 5;
    } else {
      this.circleRadius = this.dayLayoutWidth - ReadOnlyDayCellProp.circleLine;
    }
  }

  parseCirclePositionX(circleDate: CalendarDate) {
    const displayDays: DayData[] = this.curMonthlyInfo.getDisplayDays();
    const subDate = new CalendarDate(
      circleDate.getFullYear(), circleDate.getMonth(), circleDate.getDate());
    const days: number = Math.ceil((subDate.getTime() - displayDays[0].getTimeStamp() - 1) / MILLS_PER_DAY);
    const isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
    const xOffset = Math.floor(days % 7) * this.bgWidth / 7;
    if (isGrid) {
      this.circleX = xOffset + this.circleRadius / 2 + 2 + ReadOnlyDayCellProp.circleLine / 2 + 2 - 0.6;
    } else {
      this.circleX = xOffset + (this.isVerticalCell ? (this.bgWidth / 14) : (this.dayLayoutWidth / 2)) + 16;
    }
    Log.info(TAG, 'parseCirclePosition this.day = ' + days + ' this.circleX = ' +
    this.circleX + ', this.circleY = ' + this.circleY + ', bgHeight = ' + this.bgHeight)
  }

  parseCirclePositionY(circleDate: CalendarDate) {
    const displayDays: DayData[] = this.curMonthlyInfo.getDisplayDays();
    const subDate = new CalendarDate(circleDate.getFullYear(), circleDate.getMonth(), circleDate.getDate());
    const days: number = Math.ceil((subDate.getTime() - displayDays[0].getTimeStamp() - 1) / MILLS_PER_DAY);
    const weekAccount = this.weekNumViewModel.weekNumbers.length;
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const dayHeight = weekFlag ? 0 : Math.floor(days / 7) * this.bgHeight / weekAccount;
    const isSmall = MonthViewLayoutModel.getInstance().frameProp.value.isSmall;
    const isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
    this.circleY = (dayHeight * 10 + this.bgDayHeight * 5) / 10 +
      (isGrid ? ReadOnlyDayCellProp.circleLine / 2 : 0);
    Log.info(TAG, 'parseCirclePosition this.day = ' + days + ' this.circleX = ' + this.circleX +
      ', this.circleY = ' + this.circleY + ', weekAccount = ' + weekAccount + ', bgHeight = ' + this.bgHeight +
      ', bgWidth = ' + this.bgWidth)
  }

  // 更新当前月视图内周视图的显隐
  updateWeekVisibility(isShow: boolean) {
    this.updateWeekShow(!isShow);
    this.weekTemplate = this.updateWeekTemplate(this.weekAccount);
    this.weekViewModels.forEach((viewModel, index) => {
      viewModel.isSelect = index === this.showWeekNum;
      const needShow = viewModel.isSelect || isShow;
      viewModel.onVisibilityChange(needShow);
    })
  }

  // 更新左右视图的周显示状态
  updateNearlyMonthlyInfoForWeekShow(isShow: boolean, weekNum: number) {
    if (!this.nextMonthVM || !this.lastMonthVM) {
      return;
    }
    const arrowCount = isShow ? 1 : 0;
    const nowMonthHeight = this.normalMonthHeight
    this.nextMonthVM.updateWeekShow(!isShow);
    this.nextMonthVM.updateSingleMonth(this.curMonthlyInfo, MonthlyWeekArrow.NEXT, arrowCount, true);
    this.nextMonthVM.initSelectDay();
    this.nextMonthVM.updateViewCanScroll();
    this.nextMonthVM.updateNowWeekAgendaHeight(nowMonthHeight);
    this.lastMonthVM.updateWeekShow(!isShow);
    this.lastMonthVM.updateSingleMonth(this.curMonthlyInfo, MonthlyWeekArrow.LAST, arrowCount, true);
    this.lastMonthVM.initSelectDay();
    this.lastMonthVM.updateViewCanScroll();
    this.lastMonthVM.updateNowWeekAgendaHeight(nowMonthHeight);
  }

  // 更新视图状态
  updateWeekShow(isWeekShow: boolean) {
    this.isWeekShow = isWeekShow;
    this.agendaListModel.isWeekShow = isWeekShow;
  }

  // 更新当前显示行
  updateShowLine(showLine: number) {
    this.weekNumViewModel.showNumber = showLine;
    this.showWeekNum = showLine;
    this.weekViewModels.forEach((viewModel, index) => {
      viewModel.isSelect = index === this.showWeekNum;
    })
  }

  // 更新当前选中日期
  updateWeekShowSelectDate(weekArrow: number) {
    let displayDate = this.state.displayDate;
    if (weekArrow !== MonthlyWeekArrow.CURRENT) {
      displayDate = displayDate + (weekArrow * MILLS_PER_WEEK);
    } else {
      this.nextMonthVM?.updateWeekShowSelectDate(MonthlyWeekArrow.NEXT);
      this.lastMonthVM?.updateWeekShowSelectDate(MonthlyWeekArrow.LAST);
    }
    const displayDateInfo = new CalendarDate(displayDate);
    this.clearSelectDay();
    this.updateSelectDate(new DateInfo(displayDateInfo.getFullYear(), displayDateInfo.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(displayDateInfo, this.state.startOfWeek),
      displayDateInfo.getDate()));
    this.initSelectDay();
    this.updateWeekVisibility(!this.isWeekShow);
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate);
  }

  // 周视图状态下更新左右视图选中日期,与当前日期保持一周差距
  updateNearlyMonthly() {
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow; // 是否处于周视图下
    if (!weekFlag) {
      return;
    }
    this.nextMonthVM?.updateDisplayDateInWeekShow(MonthlyWeekArrow.NEXT);
    this.lastMonthVM?.updateDisplayDateInWeekShow(MonthlyWeekArrow.LAST);
    this.nextMonthVM?.updateWeekShowSelectDate(MonthlyWeekArrow.NEXT);
    this.lastMonthVM?.updateWeekShowSelectDate(MonthlyWeekArrow.LAST);
  }

  // 当前显示日期一周前后如跨月则需要更新月视图状态
  updateDisplayDateInWeekShow(weekArrow: number) {
    let displayDate = this.state.displayDate;
    displayDate = displayDate + (weekArrow * MILLS_PER_WEEK);
    const displayDateInfo = new CalendarDate(displayDate);
    //处于当前年月,无需刷新视图
    if (this.curMonthlyInfo.solarYear === displayDateInfo.getFullYear() &&
      this.curMonthlyInfo.solarMonth - 1 === displayDateInfo.getMonth()) {
      return;
    }
    this.updateSingleMonth(this.curMonthlyInfo, weekArrow, 0);
  }

  // 根据当前内外屏的本地值变化当前内外屏的月周状态
  changeMonthShow(isInSmallFold: boolean) {
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow; // 是否处于周视图下
    if (isInSmallFold) {
      if (this.isFullShow) { // 全屏还原至左右分屏
        this.isFullShow = false;
        MonthlyViewStateManager.getInstance().weekState.changeIsFullShow(false, true);
        this.updateWeekAgendaRow(0, 0);
        this.updateNearlyMonthlyInfoForFullShow(false);
      }
      let monthWeekShow: boolean =
        PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_WEEK_SHOW_SMALL, true);
      if (weekFlag !== monthWeekShow) { // 切换当前月周状态
        this.finishWeekUpdateByButton(true, 0);
      }
    } else {
      let monthWeekShow: boolean =
        PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_WEEK_SHOW, false);
      let monthFullShow: boolean =
        PreferencesUtil.getBooleanValueSync(PreferencesFiles.MONTH, MonthPreferencesKeys.MONTH_FULL_SHOW, false);
      if (weekFlag !== monthWeekShow) { // 切换当前月周状态
        this.finishWeekUpdateByButton(true, 0);
      }
      if (this.isFullShow !== monthFullShow) {
        this.changeToFullUpdate();
      }
    }
    if (this.isPanEdit) { // 动效中打断动效并还原状态
      this.cutAnimationUpdate();
    }
  }

  // 还原当前周视图状态并刷新左右视图
  restoreMonthShow() {
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow; // 是否处于周视图下
    if (weekFlag) { //非小屏还原周视图至月视图
      MonthlyViewStateManager.getInstance().weekState.changeIsWeekShow(false);
      this.updateNearlyMonthlyInfoForWeekShow(true, this.showWeekNum);
      this.updateWeekVisibility(true);
    }
    if (this.isFullShow) { // 全屏还原至左右分屏
      this.isFullShow = false;
      MonthlyViewStateManager.getInstance().weekState.changeIsFullShow(false);
      this.updateWeekAgendaRow(0, 0);
      this.updateNearlyMonthlyInfoForFullShow(false);
    }
    if (this.isPanEdit) { // 动效中打断动效并还原状态
      this.cutAnimationUpdate();
    }
  }

  updateCanFullShow(canFullShow: boolean) {
    this.canFullShow = canFullShow;
  }

  /**
   *  跟手移动初始化动效参数
   * @param forceUpdate 是否忽略条件进行强制更新,一般用于无法月视图下滑场景的还原
   * @param fromByButton 是否来自月视图按钮点击切换状态，按钮点击的没有手势结束调用，需要主动调用重置默认值
   */
  initMonthHeight(forceUpdate: boolean = false, fromByButton: boolean = false) {
    if (MonthlyViewStateManager.getInstance().dayState.isBackToToday) { // 回到今天不要响应月视图上滑
      return;
    }
    this.cutAnimationUpdate(); // 把之前操作的动效强制结束并更新参数

    this.aniState = // 判断当前需要执行的动效类型
      this.isWeekShow ? MonthAniType.MONTH_WEEK : (this.isFullShow ? MonthAniType.MONTH_FULL : MonthAniType.NONE);
    Log.info(TAG, `initMonthHeight aniState : ${this.aniState}`);
    this.initViewEditHeight();
    this.isPanEdit = true; // 判断当前是否处于跟手滑动的参数
    MonthlyViewStateManager.getInstance().onIsEditPanChange(this.isPanEdit);
    // 初始化动效参数
    if (this.aniState === MonthAniType.MONTH_FULL) {
      this.initFullMonthAni(forceUpdate);
    } else if (this.aniState === MonthAniType.MONTH_WEEK) {
      this.updateAgendaAreaMinHeight(fromByButton);
      this.initWeekMonthAni();
    }
  }

  /**
   *  变更日程区域高度，避免日程块突然消失
   * @param fromByButton 是否从月视图日期区域下方按钮触发
   */
  public updateAgendaAreaMinHeight(fromByButton: boolean = false) {
    this.agendaListViewMinHeight = this.agendaListViewHeight;
    if (fromByButton && this.agendaListViewMinHeight !== 0) {
      this.agendaListViewMinHeight = 0;
    }
  }

  /**
   * 初始化视图高度参数
   */
  initViewEditHeight() {
    const minAniHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    // 小折叠适配,因小折叠需要高度固定100%故需要额外对每周高度进行计算
    this.weekAniHeight = MonthlyViewStateManager.getInstance().modeState.isInSmallFold ?
      this.normalMonthHeight / this.weekAccount : MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const isWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const isFullShow = MonthlyViewStateManager.getInstance().weekState.isFullShow;
    const normalHeight = this.weekAccount * this.weekAniHeight;
    this.maxHeight = this.normalMonthHeight; // 月视图下滑能够到达的最大高度
    Log.info(TAG, `Start Month View State Change ${this.weekAniHeight} ${isWeekShow} ${isFullShow} ${normalHeight}`);

    const monthSize = componentUtils.getRectangleById(`sigMonth_${this.arrayIndex}`);
    this.editHeight = // 初始化当前月视图的高度,该参数用于实时更新月视图跟手滑动的高度
      isWeekShow ? minAniHeight : (isFullShow ? this.maxHeight : normalHeight);
    this.updateCurrentVolume(this.editHeight);
    this.initHeight = this.editHeight; // 记录用,在开始滑动时的月视图初始高度
  }

  // 初始化月视图上滑动效参数
  initWeekMonthAni() {
    this.weekViewModels.forEach((weekModel, index) => {
      weekModel.isSelect = index === this.showWeekNum;
      weekModel.nowMonthMoveHeight = this.isWeekShow ? (this.weekAniHeight * (this.weekAccount - 1)) : 0;
      weekModel.beforeAnimationStart(this.weekAniHeight);
    })
  }

  // 初始化月视图下滑动效参数
  initFullMonthAni(forceUpdate: boolean = false) {
    // 强制小屏或折叠外屏时不允许上滑
    const modeState = MonthlyViewStateManager.getInstance().modeState;
    if (modeState.isInSmallFold || modeState.isForceSmall) {
      this.isPanEdit = false;
      return;
    }

    // 非强制更新情况,
    if (!forceUpdate && !this.canFullShow && this.aniState === MonthAniType.MONTH_FULL) { // 小屏状态不能下滑
      this.isPanEdit = false;
      return;
    }
    this.updateWeekShow(false);
    MonthlyViewStateManager.getInstance().weekState.changeIsFullShow(true);
    if (!this.isFullShow) {
      MonthlyViewStateManager.getInstance().state.isAgendaRowMini = true;
      this.oldIsMini = true;
      this.weekViewModels.forEach((item) => {
        this.nowWeekAgendaRow = 0;
        item.updateWeekAgendaRow(0, false);
      })
    }
  }

  // 通过跟手移动距离更新视图高度
  updateWeekHeightByOffsetY(offsetY: number) {
    if (!this.isPanEdit) {
      return;
    }
    // 判断当前是下滑还是上滑操作,从而确定需要执行的操作类型
    if (this.aniState === MonthAniType.NONE) {
      this.aniState = offsetY > 0 ? MonthAniType.MONTH_FULL : MonthAniType.MONTH_WEEK;
      if (this.aniState === MonthAniType.MONTH_FULL) {
        this.initFullMonthAni();
      } else if (this.aniState === MonthAniType.MONTH_WEEK) {
        this.initWeekMonthAni();
      }
    }
    if (this.aniState === MonthAniType.MONTH_WEEK) {
      this.updateWeekMonthHeight(offsetY)
    } else if (this.aniState === MonthAniType.MONTH_FULL) {
      this.updateMonthFullHeight(offsetY);
    }
  }

  updateWeekMonthHeight(offsetY: number) {
    const minAniHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const monthWeekHeight = this.weekAniHeight;
    const updateHeight = this.isWeekShow ? Math.min(-offsetY, 0) : Math.max(-offsetY, 0);
    const editHeight = Math.min(Math.max(this.initHeight - updateHeight, monthWeekHeight),
      (this.weekAccount - 1) * monthWeekHeight + minAniHeight);
    this.updateWeekHeight(Math.abs(updateHeight), monthWeekHeight, editHeight);
  }

  /**
   * 跟手更新动效参数
   * @param weekHeight 需要更新的高度,即跟手移动距离
   * @param monthWeekHeight 当前月视图周的高度
   * @param editHeight 当前月视图的总高度
   */
  updateWeekHeight(weekHeight: number, monthWeekHeight: number, editHeight: number) {
    if (this.editHeight === editHeight || this.isFullShow) {
      return;
    }

    // 当前月视图的上滑动效是通过改变月视图日期区域高度以及每周的offset来实现的,上滑减少月视图高度并通过offset让周整体上移
    const minAniHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const nowHeight = weekHeight;
    this.editHeight = Math.max(editHeight, minAniHeight); // 更新当前视图总体高度, 不能超过一周最小高度
    this.updateCurrentVolume(this.editHeight);
    const weekLength = this.weekAccount; // 获取需要循环判断的周数
    // 循环周并更新当前周的移动高度以跟手实时更新
    for (let i = 0; i < weekLength; i++) {
      const nowIndex = this.isWeekShow ? weekLength - 1 - i : i;
      this.weekViewModels[nowIndex].nowMonthMoveHeight =
        Math.max(this.isWeekShow ? this.weekAniHeight * (this.weekAccount - 1) - nowHeight : nowHeight, 0);
    }
  }

  /**
   * 更新视图完成进度, **注意：本函数高度关联视图高度 editHeight**
   * @param editHeight 当前月视图的总高度
   */
  updateCurrentVolume(editHeight: number): number {
    const minViewHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const midViewHeight = this.weekAccount * minViewHeight;
    const maxViewHeight = this.maxHeight;
    let currentVolume = 50;
    if (editHeight === 0) {
      // 初始化未完成，属于容错分支，规避VDE外屏场景下，因WMS底座导致编辑高度为0的场景
      Log.error(TAG, 'No Valid Edit Height!');
    } else if (editHeight < minViewHeight) {
      currentVolume = 0;
    } else if (editHeight < midViewHeight) {
      currentVolume = (editHeight - minViewHeight) / (midViewHeight - minViewHeight) * 50;
    } else if (editHeight < maxViewHeight) {
      currentVolume = 50 + (editHeight - midViewHeight) / (maxViewHeight - midViewHeight) * 50;
    } else if (editHeight >= maxViewHeight) {
      currentVolume = 100;
    }
    Log.info(TAG, `editHeight = ${editHeight} , currentVolume=${currentVolume}, minViewHeight=${minViewHeight},` +
      ` midViewHeight=${midViewHeight}, maxViewHeight=${maxViewHeight}`);
    this.currentVolume = currentVolume;
    // 在单例模式中存储，避免滑动页面时，单月vm参数失效
    MonthlyViewStateManager.getInstance().weekState.currentVolume = currentVolume;
    return currentVolume; // 返回当前类值 用于DT
  }

  // 全屏态跟手更新高度
  updateMonthFullHeight(offsetY: number) {
    const monthWeekHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const updateHeight = this.isFullShow ? Math.max(-offsetY, 0) : Math.min(-offsetY, 0);
    const minHeight = this.weekAccount * monthWeekHeight;
    const nowHeight = this.initHeight - updateHeight;
    const editHeight = Math.min(Math.max(nowHeight, minHeight),
      this.maxHeight);
    this.updateMonthHeight(editHeight, monthWeekHeight);
  }

  updateMonthHeight(editHeight: number, monthWeekHeight: number) {
    this.editHeight = editHeight;
    this.updateCurrentVolume(this.editHeight);
    this.updateWeekAgendaRow(editHeight, monthWeekHeight, true);
  }

  // 按键直接触发周月视图切换
  finishWeekUpdateByButton(forceUpdate: boolean = false, animateTime: number = 80) {
    Log.info(TAG, `click weekButton update weekShow ${this.isWeekShow} ${this.isFullShow}`);
    // 处于中间态时按钮不会触发,新增小折叠状态点击上滑可以直接上滑到
    if (!this.isWeekShow && !this.isFullShow && !MonthlyViewStateManager.getInstance().modeState.isInSmallFold) {
      return;
    }
    this.initMonthHeight(forceUpdate, true);
    this.finishWeekHeightUpdate(0, true, animateTime);
  }

  // 直接触发月全屏视图切换
  changeToFullUpdate() {
    Log.info(TAG, `change to FullShow ${this.isWeekShow} ${this.isFullShow}`);
    // 周状态下不触发防止出现显示bug
    if (this.isWeekShow) {
      return;
    }
    this.initMonthHeight(true);
    this.aniState = MonthAniType.MONTH_FULL;
    this.finishWeekHeightUpdate(0, true, 0);
  }

  // 根据当前已移动的距离对剩下的距离执行动效并变更周状态
  finishWeekHeightUpdate(offsetY: number, needUpdate: boolean = false, animationTime: number = 80) {
    if (!this.isPanEdit) {
      return;
    }
    // 如果是全屏态则直接执行全屏态动效退出逻辑
    if (this.aniState === MonthAniType.MONTH_FULL) {
      this.finishMonthFullAni(offsetY, needUpdate);
      return;
    }

    Log.info(TAG, `finish weekShow animation start, weekShow ${this.isWeekShow} offset: ${offsetY}`);
    const isSmallMode = MonthlyViewStateManager.getInstance().modeState.isInSmallFold;
    const monthWeekHeight = this.weekAniHeight;

    const updateHeight = this.isWeekShow ? Math.min(-offsetY, 0) : Math.max(-offsetY, 0);
    // 移动距离超过当前周高度的一半,或为直接点击按钮才需要切换周月状态
    const updateWeekShow = Math.abs(updateHeight) > (monthWeekHeight / 2);
    if (needUpdate || updateWeekShow) {
      MonthlyViewStateManager.getInstance().weekState.changeIsWeekShow(!this.isWeekShow, isSmallMode);
      const nowWeekShow = this.isWeekShow;
      // 在动画触发前就更新左右视图状态
      SafeUtil.setTimeout(() => {
        this.updateNearlyMonthlyInfoForWeekShow(nowWeekShow, this.showWeekNum);
        broadcastSingleWeekStatus(nowWeekShow);
      }, 0);
    }

    const nowWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;

    // 触发动效
    this.animationWeekHeight(nowWeekShow, animationTime, monthWeekHeight);

    Log.info(TAG, `finishWeekHeightUpdate aniState : ${this.aniState}`);
    // 月视图状态变更打点
    let params: ReportHiEventParams = {
      TYPE: nowWeekShow ? 1 : 0
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.changeMonthMode, params);
  }

  // 通过计算自动播放上滑下滑动效
  animationWeekHeight(weekShow: boolean, animationTime: number, monthWeekHeight: number) {
    const totalTime = animationTime * (this.weekAccount - 1); // 总执行时间,用于分段执行延迟
    let delayTime = 0;
    const uuid = util.generateRandomUUID();
    this.aniUUID = uuid;
    this.oldWeekShow = weekShow;

    // 分段执行用的高度
    const divideHeight = this.weekViewModels[0].smallFoldHeight * this.showWeekNum;
    // 当前已移动的高度
    const nowHeight = this.weekViewModels[0].nowMonthMoveHeight;

    const monthHeight = this.weekAccount * this.weekAniHeight;
    const minAniHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    // 需要移动的总高度
    const nowMonthHeight = monthHeight - minAniHeight;
    // 最终需要的高度
    const finalHeight = weekShow ? nowMonthHeight : 0;

    // 当前是否已经达到最终高度,此时不需要执行动效
    const finishFlag = weekShow ? nowHeight >= nowMonthHeight : nowHeight <= 0;

    if (finishFlag) {
      this.allFinishAnimationUpdate(weekShow, monthWeekHeight);
      return;
    }

    let nowAniTime = Math.abs((finalHeight - nowHeight) / nowMonthHeight * totalTime);
    // 是否需要执行第一段动效,为位移开始到当前选中周处于第一行
    const needFirst = weekShow ? nowHeight < divideHeight : nowHeight > divideHeight;
    // 是否需要执行第二段动效,为当前选中周到第一行后选中周不移动其他周位移
    const needLast = !weekShow || this.showWeekNum !== this.weekAccount - 1;

    if (needFirst) {
      delayTime = Math.abs((divideHeight - nowHeight) / nowMonthHeight * totalTime);
      nowAniTime = Math.max(nowAniTime - delayTime, 0);
      animateToImmediately({
        duration: delayTime,
        curve: Curve.Linear,
        iterations: 1, // 设置-1表示动画无限循环
        playMode: PlayMode.Normal,
        onFinish: () => {
          if (!needLast) {
            if (!this.isPanEdit || this.aniUUID !== uuid) { // 动效是否已打断标识
              return;
            }
            this.allFinishAnimationUpdate(weekShow, monthWeekHeight);
          }
        }
      }, () => {
        this.editHeight = monthHeight - divideHeight;
        this.updateCurrentVolume(this.editHeight);
        // 当前动效高度为0时会直接从组件树卸载子节点导致动效过程中子节点瞬间消失,故终点设为1
        this.weekViewModels.forEach((item) => {
          item.nowMonthMoveHeight = divideHeight;
        });
        this.updateAgendaAreaMinHeight();
      })
    }
    Log.info(TAG, `weekChange start ani ${weekShow} ${nowAniTime} ${delayTime} ${this.editHeight} ${divideHeight}`)
    if (needLast) {
      animateToImmediately({
        duration: nowAniTime,
        delay: delayTime,
        curve: Curve.Linear,
        iterations: 1, // 设置-1表示动画无限循环
        playMode: PlayMode.Normal,
        onFinish: () => {
          if (!this.isPanEdit || this.aniUUID !== uuid) { // 动效是否已打断标识
            return;
          }
          this.allFinishAnimationUpdate(weekShow, monthWeekHeight);
        }
      }, () => {
        this.editHeight = weekShow ? minAniHeight : this.weekAccount * this.weekAniHeight;
        this.updateCurrentVolume(this.editHeight);
        this.weekViewModels.forEach((item) => {
          item.nowMonthMoveHeight = finalHeight;
        });
        this.updateAgendaAreaMinHeight();
      })
    }
  }

  // 中间态到全屏态动效结束时播放动画
  finishMonthFullAni(offsetY: number, needUpdate: boolean = false, aniTime: number = 40) {
    const monthWeekHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    const updateHeight = this.isFullShow ? Math.max(-offsetY, 0) : Math.max(offsetY, 0);
    const isSmallMode = MonthlyViewStateManager.getInstance().modeState.isInSmallFold;
    const changeState = needUpdate || updateHeight >= this.CHANGE_MIN_MOVE;
    const finalFullShow = changeState ? !this.isFullShow : this.isFullShow;
    animateToImmediately({
      duration: changeState ? aniTime * this.weekAccount : aniTime,
      curve: Curve.Friction,
      onFinish: () => {
        Log.info(TAG, `finish Month View State Change ${finalFullShow} ${this.isFullShow} ${this.isPanEdit}`);
        broadcastFullScreenStatus(finalFullShow);
        this.updateNearlyMonthlyInfoForFullShow(finalFullShow);
      }
    }, () => {
      this.editHeight = finalFullShow ? this.maxHeight : this.weekAccount * monthWeekHeight;
      this.updateCurrentVolume(this.editHeight);
      this.isFullShow = finalFullShow;
      MonthlyViewStateManager.getInstance().weekState.changeIsFullShow(finalFullShow, isSmallMode);
      if (finalFullShow) {
        this.updateWeekAgendaRow(this.maxHeight, this.normalDayHeight, true);
      } else {
        this.updateWeekAgendaRow(0, 0);
      }
      this.isPanEdit = false;
      this.updateAgendaAreaMinHeight();
    });
  }

  // 更新左右视图的全屏显示状态
  updateNearlyMonthlyInfoForFullShow(isFullShow: boolean) {
    if (!this.nextMonthVM || !this.lastMonthVM) {
      return;
    }
    this.nextMonthVM.isFullShow = isFullShow;
    this.lastMonthVM.isFullShow = isFullShow;
    if (isFullShow) {
      this.nextMonthVM.updateWeekAgendaRow(this.maxHeight, this.normalDayHeight);
      this.lastMonthVM.updateWeekAgendaRow(this.maxHeight, this.normalDayHeight);
    } else {
      this.nextMonthVM.updateWeekAgendaRow(0, 0);
      this.lastMonthVM.updateWeekAgendaRow(0, 0);
    }
  }

  // 动效全部执行完毕后执行的参数变化
  allFinishAnimationUpdate(weekShow: boolean, monthWeekHeight: number) {
    this.aniUUID = '';
    this.weekTemplate = this.updateWeekTemplate(this.weekAccount);
    // 还原动效参数
    this.isPanEdit = false;
    MonthlyViewStateManager.getInstance().onIsEditPanChange(this.isPanEdit);
    const minAniHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
    this.initHeight = weekShow ? minAniHeight : monthWeekHeight * this.weekAccount;
    this.updateWeekVisibility(!weekShow);
    this.updateViewCanScroll();
    // 动效参数终结
    this.weekViewModels.forEach((viewModel, index) => {
      viewModel.nowMonthMoveHeight = 0; //
      viewModel.afterAnimationEnd();
    })
  }

  // 打断动效后执行的结束函数
  cutAnimationUpdate() {
    if (this.aniUUID === '') { // aniUUID为空则表示当前无动效执行
      return;
    }
    this.aniUUID = '';
    const monthWeekHeight = this.weekAniHeight;
    this.allFinishAnimationUpdate(this.oldWeekShow, monthWeekHeight);
  }

  updateNowMonthHeight(nowMonthHeight: number, nowWeekHeight: number) {
    this.nowMonthHeight = nowMonthHeight - MonthStaticLayout.monthPaddingTop;
    this.nowWeekHeight = nowWeekHeight;
    this.updateViewCanScroll();
  }

  // 更新用于计算周日程块高度的月和日期高度
  updateWeekAgendaHeight(normalMonthHeight: number, normalDayHeight: number, isSmall: boolean) {
    this.normalMonthHeight = normalMonthHeight;
    this.canFullShow = true;
    let agendaMonthHeight = this.normalMonthHeight;
    if (isSmall) {
      const navigationHeight = AppStorage.get<number>('windowAvoidAreaNavigationRectHeight') ?? 0;
      const isSmallFold = MonthlyViewStateManager.getInstance().modeState.isInSmallFold;
      const smallPadding = 24 + WeekTitleLayout.marginDownGap + (isSmallFold ? 0 : navigationHeight);
      Log.info(TAG, `update now canFullShow ${normalMonthHeight} ${normalDayHeight} ${navigationHeight}`);
      // 按照最大周数判断是否可以下拉，避免下拉后滑动到六周场景下的显示异常
      const minHeight = MAX_WEEK_ACCOUNT * normalDayHeight + this.MIN_AGENDA_HEIGHT_CHECK;
      this.canFullShow = normalMonthHeight - smallPadding >= minHeight;
      this.normalMonthHeight = normalMonthHeight - smallPadding;
      agendaMonthHeight = this.isFullShow || isSmallFold ? this.normalMonthHeight : this.weekAccount * normalDayHeight;
      if (this.isFullShow && !this.canFullShow) {
        this.finishWeekUpdateByButton(true, 0);
      }
    }
    this.normalDayHeight = normalDayHeight;
    // 刷新每周日程行数
    this.updateWeekAgendaRow(agendaMonthHeight, this.normalDayHeight);
  }

  // 通过月视图可用高度以及当前日期高度更新每周日程行数
  updateWeekAgendaRow(normalMonthHeight: number, normalDayHeight: number, needDaily: boolean = false) {
    let newWeekAgendaRow = 0;
    if (normalMonthHeight !== 0) {
      const weekAgendaHeight = WeekAgendaLayout.agendaRowHeight; // 周日程块的高度
      const agendaMaxRow = WeekAgendaLayout.agendaMaxRow; // 周日程块的最大数量
      const agendaPaddingTop = WeekAgendaLayout.agendaRowPaddingTop; // 日程区域上边距
      const oneWeekHeight = Math.floor(normalMonthHeight / this.weekAccount);
      const isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
      const nowWeekAgendaHeight =
        oneWeekHeight - normalDayHeight - (isGrid ? 0 : agendaPaddingTop) + ReadOnlyDayCellProp.circleLine;
      newWeekAgendaRow = Math.max(Math.min(Math.floor(nowWeekAgendaHeight / weekAgendaHeight), agendaMaxRow), 0);
      this.updateNowWeekAgendaHeight(normalMonthHeight);
    }
    Log.info(TAG, `'onWeekAgendaRowsChange: weekAgendaRows = ${this.nowWeekAgendaRow} ${newWeekAgendaRow}`);
    const nowIsMini = newWeekAgendaRow === 0;
    const needRefreshDay = this.oldIsMini !== nowIsMini;
    MonthlyViewStateManager.getInstance().state.isAgendaRowMini = nowIsMini;
    this.oldIsMini = nowIsMini;
    if (this.nowWeekAgendaRow !== newWeekAgendaRow) {
      this.nowWeekAgendaRow = newWeekAgendaRow;
      if (needDaily) {
        SafeUtil.setTimeout(() => {
          this.updateNowWeekAgendaRow(newWeekAgendaRow, true);
        }, 17)
      } else {
        this.updateNowWeekAgendaRow(newWeekAgendaRow, true);
      }
    } else if (needRefreshDay) {
      const showCalendar = MonthlyViewStateManager.getInstance().dayState.showCalendar;
      this.updateTagShowCalendar(showCalendar);
    }
  }

  // 用于小折叠的高度更新,小折叠因需要保持100%高度故需要额外计算每周的高度
  updateNowWeekAgendaHeight(newMonthHeight: number) {
    const isSmallUpMode = MonthlyViewStateManager.getInstance().modeState.isInSmallFold;

    if (isSmallUpMode) {
      const nowWeekHeight = newMonthHeight / this.weekAccount;
      this.weekViewModels.forEach((item) => {
        item.updateSmallFoldHeight(nowWeekHeight);
      })
    }
  }

  updateNowWeekAgendaRow(newWeekAgendaRow: number, needRefreshDay: boolean) {
    this.weekViewModels.forEach((item) => {
      item.updateWeekAgendaRow(newWeekAgendaRow, needRefreshDay);
    })
  }

  updateTagShowCalendar(showCalendar: boolean) {
    this.weekViewModels.forEach((item) => {
      item.updateTagShowCalendar(showCalendar);
    })
  }

  // 获取当前能够展现的日程块行数
  getNowMonthAgendaRow() {
    return this.nowWeekAgendaRow;
  }

  updateViewCanScroll() {
    this.agendaListModel.canScroll = this.isWeekShow ?
      this.nowMonthHeight < (this.nowWeekHeight + this.MIN_AGENDA_HEIGHT) :
      this.nowMonthHeight < (this.nowWeekHeight * this.weekAccount + this.MIN_AGENDA_HEIGHT);
  }

  /**
   * 是否隐藏月视图日程列表
   * @param hideAgendaWindow
   */
  onAgendaListStateChange(hideAgendaWindow: boolean, needAni: boolean = true, dividerMove: boolean = true) {
    this.showDivider = dividerMove;
    animateTo({
      duration: needAni ? this.ANIMATION_TIME : 0,
      curve: Curve.Friction,
    }, () => {
      this.hideAgendaWindow = hideAgendaWindow;
    });
    if (!dividerMove) { // 用于取消宫格线移动的参数
      animateTo({
        duration: 0,
        curve: Curve.Friction,
      }, () => {
        this.showDivider = true;
      });
    }
  }

  // 更新对应的日程管理器的重要日列表
  updateImportantAgenda(importantAgendas: AgendaEventInfo[]) {
    this.sigAgendaManager.allImportantResult = importantAgendas;
    this.sigAgendaManager.analyzeAgendaInDate(this.selectDate, true);
  }

  // 更新语言
  onLanguageChange(language: string): void {
    this.sigAgendaManager.getCurrentMonthAgenda();
    this.weekViewModels.forEach((item) => {
      item.onLanguageChange(language);
    })
  }

  // 更新主题
  onThemeChange(): void {
    this.weekViewModels.forEach((item) => {
      item.onThemeChange();
    })
  }

  onSmallStatusChange() {
    const weekNumbers = this.weekNumViewModel.weekNumbers;
    for (let weekNumInd = 0; weekNumInd < weekNumbers.length; ++weekNumInd) {
      this.weekViewModels[weekNumInd]?.onSmallStatusChange()
    }
    this.onDisplayDateChange(this.selectDate, true);
  }
}
