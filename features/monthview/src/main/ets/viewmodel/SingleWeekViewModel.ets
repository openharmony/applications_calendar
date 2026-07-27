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

import { AgendaEventInfo, DAY_PER_WEEK, DayData, Log, CommonInnerEvent,
  CHINESE_HOLIDAY_STATE_VALUE,
  DeviceConfig,
  ReportUtil,
  statisticEvents,
  ThrottleFunction,
  NavPathManager,
  NavPathName,
  RouterName,
  SafeUtil,
  AgendaAbilityManager,
  VibratorUtils,
  I18nUtil,
  GlobalData,
  GlobalDataKeys,
  VibrationType,
  AccountUtils,
  } from '@app/common';
import { SingleDayViewModel, SingleDayViewModelArray } from './SingleDayViewModel';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { AgendaBlockInfo, WeekAgendaBlockModel } from './WeekAgendaBlockModel';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { ColorType, PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import emitter from '@ohos.events.emitter';
import { WeekAgendaLayout } from '../layoutmodel/FrameLayoutRule';
import { MonthlyViewStateManager, MonthlyWeekState } from './MonthlyViewState';
import Stack from '@ohos.util.Stack';
import { systemDateTime } from '@kit.BasicServicesKit';
import { AgendaBlockStateManagement, WeekAgendaState } from './WeekAgendaState';
import { AgendaEditMenuOpt, AgendaOperateHelper, CreateAgendaPageSource } from '@app/feature.agenda';
import { DayViewState } from '../viewmodel/MonthlyViewState';

const TAG: string = '[MonthlyView][SigWeekVM]';

//日程块之间的距离 2vp;
const agendaBlockTopMargin = WeekAgendaLayout.agendaRowPaddingTop;

const blockHeight = DeviceConfig.instance().config.monthAgendaBlockHeight;

const agendaBlockArea: number = 0;

const blankArea: number = 1;

const blankAreaIndex = -1;

@Observed
export class SingleWeekViewModelArray extends Array<SingleWeekViewModel> {
}

@Observed
export class WeekTitlesArray extends Array<string> {
}

@Observed
export class SingleWeekViewModel {
  public weekState: MonthlyWeekState = MonthlyViewStateManager.getInstance().weekState;
  public weekAgendaState: WeekAgendaState = WeekAgendaState.getInstance();
  public agendaBlockState: AgendaBlockStateManagement = WeekAgendaState.getInstance().agendaBlockState;
  // 持有的日视图数据
  public dayViewModels: SingleDayViewModelArray = [];
  // 当前所在周的年、月、周数（以当年1月4日所在周为第一周）
  public dateInfo: DateInfo
  // 月视图存在5-6周的情况，对于不存在的第六周则置为false
  public isExist: boolean = false
  // 所在周的每一天是否存在
  public instancesFlags: boolean[] = [];
  public festivalsNameArrays: string[] = [];
  // 单周的日程数据模型
  public agendaBlockModel: WeekAgendaBlockModel;
  public weekNumInd: number = -1; // 索引值

  // 动效相关参数
  public isShow: boolean = true; // 是否显示,用于月视图上滑
  public isSelect: boolean = false; // 用于判断选中周的标识
  public showIndex: number = 0; // 动效覆盖用当前zIndex
  public smallFoldHeight: number = 0; // 用于SmallFold模式的高度
  public nowMonthMoveHeight: number = 0; // 当前月视图已移动的高度

  // 重要日开关
  public showImportantDay: boolean = false;

  public createPageData: emitter.EventData = {};

  public popupPos: Position = { x: 0, y: 0 };

  public isCreatePopupShow: boolean = false;

  public isQuickCreate: boolean = false;

  private dayState: DayViewState = MonthlyViewStateManager.getInstance().dayState;

  //存点击事件的时间戳
  private agendaClickEventStack: Stack<number> = new Stack();

  private blankClickEventStack: Stack<number> = new Stack();

  public clickTwice: boolean = false;

  //控制pop的弹出方向
  public popDirection: Placement = Placement.Bottom;

  // 判断是否弹popup
  public showPopup: boolean = false;

  // 新建日程弹窗是否跟手, phone不跟手，进入新建页面半模态，tablet跟手
  public isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;
  private TAG = 'SingleWeekViewModel';

  constructor(weekNumInd: number, dayDataArr?: DayData[], dateInfo?: DateInfo) {
    this.updateWeekNum(weekNumInd);
    if (!dateInfo || !dayDataArr) {
      Log.info(TAG, 'dateInfo or dayDataArr is undefined!');
      this.isExist = false;
      this.dateInfo = new DateInfo(0, 0, 0, 0);
      this.agendaBlockModel = new WeekAgendaBlockModel(this, this.weekNumInd);
      for (let index = 0; index < DAY_PER_WEEK; index++) {
        this.dayViewModels.push(new SingleDayViewModel(this.weekNumInd, undefined, undefined, index));
      }
      return;
    }
    this.isExist = true;
    this.dateInfo = new DateInfo(dateInfo.year, dateInfo.month, dateInfo.weekNum, dateInfo.day);
    this.dateInfo.day = dayDataArr[0].solarDay;
    dayDataArr.forEach((dayData: DayData, index: number) => {
      this.dayViewModels.push(new SingleDayViewModel(this.weekNumInd, dayData, this.dateInfo, index));
    })
    this.agendaBlockModel = new WeekAgendaBlockModel(this, this.weekNumInd);
    this.smallFoldHeight = MonthViewLayoutModel.getInstance().frameProp.value.weekRowHeight;
  }

  /**
   * 更新每周的VM
   *
   * @param dayDataArr
   * @param dateInfo
   */
  update(weekNumInd: number, dayDataArr?: DayData[], dateInfo?: DateInfo) {
    this.updateWeekNum(weekNumInd);
    if (!dateInfo || !dayDataArr) {
      Log.info(TAG, 'NO VALID DATE INFO TO BUILD WEEK! This Week Will Not Be Actually Built!');
      this.isExist = false;
      this.dateInfo = new DateInfo(0, 0, 0, 0);
      for (let index = 0; index < 7; index++) {
        this.dayViewModels[index].update();
      }
      return;
    }
    this.isExist = true;
    this.dateInfo = new DateInfo(dateInfo.year, dateInfo.month, dateInfo.weekNum, dateInfo.day);
    this.dateInfo.day = dayDataArr[0].solarDay;
    for (let index = 0; index < 7; index++) {
      this.dayViewModels[index].update(dayDataArr[index], this.dateInfo)
    }
    this.agendaBlockModel.update();
  }

  onSmallStatusChange() {
    const newDayViewModels: SingleDayViewModelArray = [];
    this.dayViewModels.forEach((dayModel, index) => {
      const newModel = new SingleDayViewModel(this.weekNumInd, dayModel.dayData, this.dateInfo, index);
      newModel.isExceptHolidaysInstancesFlags = dayModel.isExceptHolidaysInstancesFlags;
      newModel.isHasInstances = dayModel.isExceptHolidaysInstancesFlags;
      newDayViewModels.push(newModel);
    });
    this.dayViewModels = newDayViewModels;
  }

  onCurrentDateChange(currentDate: number) {
    this.dayViewModels.forEach((singleDayViewModel: SingleDayViewModel) => {
      singleDayViewModel.onCurrentDateChange(currentDate)
    })
  }

  onTimeZoneChange(currentDate: number) {
    this.dayViewModels.forEach((singleDayViewModel: SingleDayViewModel) => {
      singleDayViewModel.onCurrentDateChange(currentDate);
    })
  }

  onCurrentDateColor(onlyColor: boolean = false) {
    this.dayViewModels.forEach((singleDayViewModel: SingleDayViewModel) => {
      singleDayViewModel.onCurrentDateColorChange(onlyColor)
    })
  }

  /**
   * 历法变更
   */
  onSubscriptionCalendar(showCalendar: boolean) {
    this.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      dayVM.onSubscriptionCalendar(showCalendar);
    })
    this.agendaBlockModel.onSubscriptionCalendar();
  }

  onShowImportantDayChange(showImportantDay: boolean) {
    this.agendaBlockModel.onShowImportantDayChange();
  }

  /**
   * 深色模式变更
   */
  onDarkModeChange() {
    this.agendaBlockModel.onDarkModeChange();
    Log.info(TAG, `WEEKDAY = ${PaletteCache.instance().getColor(ColorType.PRIMARY).red},
    WEEKEND = ${PaletteCache.instance().getColor(ColorType.TERTIARY).red}`);
    this.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      dayVM.onDarkModeChange();
    })
  }

  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE) {
    this.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      dayVM.onChineseHolidayStateChange(chineseHolidayState);
    })
    this.agendaBlockModel.onChineseHolidayStateChange(chineseHolidayState);
  }

  /**
   * 处理布局变化
   */
  onLayoutChange() {
    this.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      dayVM.onLayoutChange();
    })
  }

  /**
   * 地区变更
   */
  onSystemRegionChange(systemRegion: string) {
    this.agendaBlockModel.onSystemRegionChange();
    this.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      dayVM.onSystemRegionChange(systemRegion);
    })
  }

  onSelectDateChange(selectDate: DateInfo, isSelect: boolean = false): boolean {
    Log.debug(TAG, `onSelectDateChange weekNum ${selectDate.weekNum} ${this.dateInfo.weekNum} ${isSelect}`);
    if (this.dateInfo.weekNum !== selectDate.weekNum) {
      return false;
    }
    this.dayViewModels.forEach((dayVM: SingleDayViewModel, index: number) => {
      dayVM.onSelectDateChange(selectDate, isSelect);
    })
    return true;
  }

  onInstancesFlagsChange(instancesFlags: boolean[], exceptHolidaysInstancesFlags: boolean[]) {
    this.instancesFlags = instancesFlags;
    this.dayViewModels.forEach((dayVM: SingleDayViewModel, index: number) => {
      if (index < this.instancesFlags.length && index < exceptHolidaysInstancesFlags.length) {
        dayVM.onInstancesFlagsChange(this.instancesFlags[index], exceptHolidaysInstancesFlags[index]);
      }
    })
  }

  onFestivalsChange(festivalsNameArrays: string[]) {
    this.festivalsNameArrays = festivalsNameArrays;
    this.dayViewModels.forEach((dayVM: SingleDayViewModel, index: number) => {
      dayVM.onFestivalsChange(this.festivalsNameArrays[index]);
    })
  }

  onSigWeekAgendaChange(sigWeekAgendas: AgendaEventInfo[]) {
    this.agendaBlockModel.onSigWeekAgendaChange(sigWeekAgendas);
    this.dayViewModels.forEach((dayVM: SingleDayViewModel, index: number) => {
      // 需要变么？ dayVM.r(this.instancesFlags[index]);
    })
  }

  // 动画相关
  beforeAnimationStart(monthWeekHeight: number) {
    this.showIndex = 9 - this.weekNumInd;
    this.updateSmallFoldHeight(monthWeekHeight);
    this.isShow = true;
  }

  // 用于更新月视图上滑当前周位移距离的参数
  updateSmallFoldHeight(monthWeekHeight: number) {
    this.smallFoldHeight = monthWeekHeight;
  }

  afterAnimationEnd() {
  }

  // 更新当前周的标识以及对应的z序
  updateWeekNum(weekNumInd: number) {
    this.weekNumInd = weekNumInd;
    this.showIndex = 9 - this.weekNumInd;
  }

  onVisibilityChange(isShow: boolean) {
    this.isShow = isShow;
  }

  // 双击触发新建
  clickTwiceEvent(event: GestureEvent) {
    const offsetX = event.fingerList[0]?.localX || 0;
    const clickDateTime = this.getClickDateTime(offsetX);

    const eventData: emitter.EventData = {
      data: {
        agendaDateParam: clickDateTime,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
  }

  // 根据点击X坐标获取选中时间
  getClickDateTime(offsetX: number) {
    // 月视图单周宽度 = 月视图日期区域宽度减去左右边距
    const width = MonthViewLayoutModel.getInstance().frameProp.value.monthDateWidth - 48;
    const count = Math.floor(offsetX * 7 / width);
    const index = Math.max(Math.min(count, 6), 0);
    return this.dayViewModels[index].dayData.getTimeStamp();
  }

  updateWeekAgendaRow(nowWeekAgendaRow: number, needRefreshDay: boolean) {
    this.agendaBlockModel.onWeekAgendaRowsChange(nowWeekAgendaRow);
    if (needRefreshDay) {
      const showCalendar = MonthlyViewStateManager.getInstance().dayState.showCalendar;
      this.updateTagShowCalendar(showCalendar);
    }
  }

  updateTagShowCalendar(showCalendar: boolean) {
    this.dayViewModels.forEach((item) => {
      item.updateAgendaMini(showCalendar);
    })
  }

  // 更新语言
  onLanguageChange(language: string): void {
    this.agendaBlockModel.onLanguageChange(language);
    this.dayViewModels.forEach((item) => {
      item.onLanguageChange(language);
    })
  }

  // 更新主题
  onThemeChange(): void {
    this.dayViewModels.forEach((item) => {
      item.onThemeChange();
    })
  }

  clickEvent(event?: GestureEvent): ClickData {
    const curClickTimeStamp: number = systemDateTime.getTime(false)
    if (!event || !event.fingerList || !event.fingerList[0]) {
      Log.error(TAG, 'OnClickBlockAreaFocus Click Event Is Undefined');
      return new ClickData();
    }

    const width = px2vp(this.agendaBlockModel.cellWidth); // 单个日期的宽
    const relativeX = event.fingerList[0].localX; //相对父组件x坐标
    const relativeY = event.fingerList[0].localY; //相对父组件y坐标
    const xIndex = this.computeXIndex(relativeX, width); //第xIndex个日程块
    if (xIndex < 0 || xIndex > DAY_PER_WEEK - 1) {
      Log.error(TAG, 'OnClickBlockAreaFocus Index Out Of Range [0,6]')
      return new ClickData();
    }

    const yIndex = this.computeYIndex(relativeY);
    Log.info(TAG, `clickEvent xIndex:${xIndex}  yIndex:${yIndex}`)
    //遍历当周所有的日程块，判断是否点到日程块区域
    const agendaBlocks = this.agendaBlockModel.blocks;
    let clickOnAgendaArea: boolean = false;
    for (let i = 0; i < agendaBlocks.length; i++) {
      const agendaBlock = agendaBlocks[i];
      //点击到日程块区域
      if (agendaBlock.rowStart == yIndex && agendaBlock.columnStart <= xIndex && agendaBlock.columnEnd >= xIndex) {
        clickOnAgendaArea = true;
        const type: ClickPositionType = this.judgeClickType(this.agendaClickEventStack,
          curClickTimeStamp, agendaBlockArea);
        return new ClickData(xIndex, yIndex, agendaBlock, type);
      }
    }
    //点击到空白区域
    if (!clickOnAgendaArea) {
      const type: ClickPositionType = this.judgeClickType(this.blankClickEventStack, curClickTimeStamp, blankArea);
      return new ClickData(xIndex, yIndex, undefined, type);
    }

    return new ClickData();
  }

  /**
   * 点击事件坐标(x,y)的横坐标x有偏差，额外-1
   * @param x 点击事件x坐标
   * @param width  单个日期的宽
   * @returns xIndex 点击事件点在一周的第xIndex天
   */
  public computeXIndex(x: number, width: number): number {
    if (width > 1) {
      return Math.floor(x / (width - 1));
    } else if (width === 0) {
      return Math.floor(x);
    } else {
      return Math.floor(x / width);
    }
  }

  /**
   * @param y 点击事件y坐标
   * blockHeight  日程块的高
   * @returns yIndex 点击事件点在第xIndex天的第yIndex日程块
   */
  public computeYIndex(y: number): number {
    return Math.floor(y / (blockHeight + agendaBlockTopMargin));
  }

  judgeClickType(stack: Stack<number>, curClickTimeStamp: number, areaType: number): ClickPositionType {
    if (stack.isEmpty()) {
      //单击
      this.clickTwice = false;
      stack.push(curClickTimeStamp);
      return this.judgeClickPositionType(areaType, 1);
    } else {
      //判断是否双击
      const preClickTimeStamp = stack.pop();
      //300ms以内判断是双击,否则单击
      if (curClickTimeStamp - preClickTimeStamp < 300) {
        this.clickTwice = true;
        return this.judgeClickPositionType(areaType, 2);
      } else {
        this.clickTwice = false;
        stack.push(curClickTimeStamp);
        return this.judgeClickPositionType(areaType, 1);
      }
    }
  }

  judgeClickPositionType(areaType: number, clickTimes: number): ClickPositionType {
    if (clickTimes == 1) {
      if (areaType == 0) {
        return ClickPositionType.CLICK_AGENDA_BLOCK_ONCE;
      } else {
        return ClickPositionType.CLICK_BLANK_AREA_ONCE;
      }
    } else if (clickTimes == 2) {
      if (areaType == 0) {
        return ClickPositionType.CLICK_AGENDA_BLOCK_TWICE;
      } else {
        return ClickPositionType.CLICK_BLANK_AREA_TWICE;
      }
    }
    return ClickPositionType.NONE;
  }

  /**
   *
   * @param index 触控点所在周的index
   * @param agendaBlock 触控到的日程块对象
   * @param height 一周（包括日期区域和日程块区域）的高
   * @param width  一周中单个日期的宽
   * 折叠日程块：处于后Math.ceil(weekNumber/2)周的，弹出气泡朝上，否则朝下;
   * 最后一周的非折叠日程块朝上展开，其余朝下展开
   */
  public computePopDirection(index: number, agendaBlock: AgendaBlockInfo, width: number, totalWeekNum: number) {
    //pop在日程块中间弹出
    this.popupPos.x = width * (agendaBlock.columnStart + agendaBlock.columnEnd + 1) / 2;
    //height * index=相对屏幕左上角触控点所在周的高度
    this.popupPos.y = agendaBlock.rowStart * (blockHeight + agendaBlockTopMargin) + blockHeight;
    if (agendaBlock.isUnfold()) {
      if (totalWeekNum - 1 === index) {
        this.popDirection = Placement.Top;
        this.popupPos.y = agendaBlock.rowStart * (blockHeight + agendaBlockTopMargin) + 2;
      } else {
        this.popDirection = Placement.Bottom;
      }
    } else {
      if (totalWeekNum - index <= Math.ceil(totalWeekNum / 2)) {
        this.popDirection = Placement.Top;
        this.popupPos.y = agendaBlock.rowStart * (blockHeight + agendaBlockTopMargin) + 2;
      } else {
        this.popDirection = Placement.Bottom;
      }
    }
  }

  /**
   * 设置快速新建pop窗的x，y坐标，以及标志位为true
   * @param posX 快速新建pop窗的x坐标
   * @param posY 快速新建pop窗的y坐标
   */
  public setPopParameter(posX: number, posY: number) {
    this.popupPos.x = posX;
    this.popupPos.y = posY;
    this.isCreatePopupShow = true;
  }

  /**
   * 点击空白区域，重新设置焦点
   * @param index
   * @param focusedAgendaX
   * @param focusedAgendaY
   */
  public clickBlankFocusSetting() {
    this.agendaBlockState.preFocusWeekIndex = this.agendaBlockState.curFocusWeekIndex;
    this.agendaBlockState.curFocusWeekIndex = blankAreaIndex;
    this.agendaBlockState.focusedAgendaX = -1;
    this.agendaBlockState.focusedAgendaY = -1;
    this.freshSingleWeekAgendaBlockArea();
  }

  /**
   * 点击日程块，重新设置焦点
   * @param focusedAgendaX 焦点日程的x坐标
   * @param focusedAgendaY 焦点日程的y坐标
   * @param weekIndex 第几周
   */
  public clickAgendaFocusSetting(focusedAgendaX: number, focusedAgendaY: number, weekIndex: number) {
    this.setWeekFocus(weekIndex);
    //焦点信息设置
    this.agendaBlockState.focusedAgendaX = focusedAgendaX;
    this.agendaBlockState.focusedAgendaY = focusedAgendaY;

    //刷新当前preFocusWeekIndex的周日程区域
    this.freshSingleWeekAgendaBlockArea();
    //刷新preFocusWeekIndex的周日程区域
    emitter.emit({ eventId: CommonInnerEvent.FRESH_MONTH_AGENDA_BLOCK_AREA }, {
      data: {
        weekIndex: this.agendaBlockState.preFocusWeekIndex,
      }
    })
  }

  /**
   * 刷新单周的日程块区域
   */
  public freshSingleWeekAgendaBlockArea(): void {
    this.agendaBlockModel.freshAgendaArea();
  }

  /**
   * 设置焦点周参数
   * @param curFocusWeekIndex
   */
  public setWeekFocus(curFocusWeekIndex: number) {
    this.agendaBlockState.preFocusWeekIndex = this.agendaBlockState.curFocusWeekIndex;
    this.agendaBlockState.curFocusWeekIndex = curFocusWeekIndex;
  }

  public handleRightClick(x: number, y: number, weekIndex: number): AgendaBlockInfo | undefined {
    //判断是否点到日程块
    const width = px2vp(this.agendaBlockModel.cellWidth); // 单个日期的宽
    const yIndex = this.computeYIndex(y);
    const xIndex = this.computeXIndex(x, width); //第xIndex个日程块
    const agendaBlocks = this.agendaBlockModel.blocks;
    for (let i = 0; i < agendaBlocks.length; i++) {
      const agendaBlock = agendaBlocks[i];
      if (agendaBlock) {
        //点击到日程块区域
        if (agendaBlock.rowStart == yIndex && agendaBlock.columnStart <= xIndex && agendaBlock.columnEnd >= xIndex) {
          this.clickAgendaFocusSetting(xIndex, yIndex, weekIndex);
          return agendaBlock;
        }
      }
    }
    return undefined;
  }

  /**
   * 根据x y 坐标计算当前位置是哪个日程块
   * @param x
   * @param y
   * @returns
   */
  public getAgendaBlockByPos(x: number, y: number): AgendaBlockInfo | undefined {
    //判断是否点到日程块
    const width = px2vp(this.agendaBlockModel.cellWidth); // 单个日期的宽
    const yIndex = this.computeYIndex(y);
    const xIndex = this.computeXIndex(x, width); //第xIndex个日程块
    const agendaBlocks = this.agendaBlockModel.blocks;
    for (let i = 0; i < agendaBlocks.length; i++) {
      const agendaBlock = agendaBlocks[i];
      //点击到日程块区域
      if (agendaBlock.rowStart == yIndex && agendaBlock.columnStart <= xIndex && agendaBlock.columnEnd >= xIndex) {
        return agendaBlock;
      }
    }
    return undefined;
  }

  /**
   * 处理月视图日程块区域hover逻辑
   * @param x
   * @param y
   * @param weekIndex
   * @param totalWeekNum
   */
  private preTimeHoverOnBlankArea: number = 0; //上一次鼠标移动到空白区域的时间戳
  private preTimeHoverOnAgendaBlock: number = 0; //上一次鼠标移动到日程块的时间戳

  public handleHover(x: number, y: number, weekIndex: number, totalWeekNum: number) {
    if (this.weekState.openOtherPage) {
      this.weekState.openOtherPage = false;
      return;
    }
    clearTimeout(this.agendaBlockState.closeHoverPopTimer);
    clearTimeout(this.agendaBlockState.openNewHoverPopTimer);
    clearTimeout(this.agendaBlockState.closePopOnPopHoverTimer);
    const width = px2vp(this.agendaBlockModel.cellWidth); // 单个日期的宽
    const curHoverBlock = this.getAgendaBlockByPos(x, y);
    this.agendaBlockState.hoverWeekIndex = weekIndex;
    if (this.agendaBlockState.clickAgendaShow || this.agendaBlockState.duringSwiperAnimation) { //处于单击日程块状态，直接返回
      this.agendaBlockState.resetAgendaHoverFlag();
      this.preTimeHoverOnBlankArea = 0;
      this.preTimeHoverOnAgendaBlock = 0
      return;
    }
    if (curHoverBlock) { // 当前鼠标悬停在日程块上
      this.preTimeHoverOnBlankArea = 0; // 初始化鼠标落在空白区域的时间
      if (this.agendaBlockState.hoverBlock != curHoverBlock) { // 与上次悬停的日程块不相同， 相同则do nothing
        this.closeHoverPopTimerStart(); //鼠标静止经过80ms关闭气泡（只有鼠标移动才会触发onMouse方法，触发handleHover方法）
        this.agendaBlockState.openNewHoverPopTimer = setTimeout(() => { //静止经过300ms弹出新气泡(curHoverBlock)
          this.openNewHoverPop(curHoverBlock);
          this.computePopDirection(weekIndex, curHoverBlock, width, totalWeekNum);
          clearTimeout(this.agendaBlockState.openNewHoverPopTimer);
        }, 300);
        if (this.preTimeHoverOnAgendaBlock === 0) {
          this.preTimeHoverOnAgendaBlock = Date.now(); // 记录当前时间
        } else {
          if (Date.now() - this.preTimeHoverOnAgendaBlock > 180) { // 在时间超过指定值后触发hover逻辑
            this.weekAgendaState.showPopup = false;
            this.agendaBlockState.resetAgendaHoverFlag();
            this.agendaBlockState.timer = setTimeout(() => {
              this.openNewHoverPop(curHoverBlock);
              this.computePopDirection(weekIndex, curHoverBlock, width, totalWeekNum);
              clearTimeout(this.agendaBlockState.timer);
            }, 200);
          }
        }
      }
    } else {
      this.preTimeHoverOnAgendaBlock = 0; // 初始化鼠标落在日程区域的时间
      this.closeHoverPopTimerStart();
      if (this.preTimeHoverOnBlankArea === 0) {
        this.preTimeHoverOnBlankArea = Date.now(); // 记录当前时间
      } else {
        if (Date.now() - this.preTimeHoverOnBlankArea > 180) { // 在时间超过指定值后触发hover逻辑
          this.weekAgendaState.showPopup = false;
          this.agendaBlockState.resetAgendaHoverFlag();
        }
      }
    }
  }

  /**
   * 用于鼠标hover至pop弹窗清除日程区域hover打开关闭pop弹窗计时器的逻辑
   */
  agendaPopHoverClearTimer() {
    clearTimeout(this.agendaBlockState.closeHoverPopTimer);
    clearTimeout(this.agendaBlockState.openNewHoverPopTimer);
    clearTimeout(this.agendaBlockState.timer);
    clearTimeout(this.agendaBlockState.closePopOnPopHoverTimer);
    this.preTimeHoverOnBlankArea = 0;
    this.preTimeHoverOnAgendaBlock = 0
  }

  /**
   * 用于鼠标hover离开pop弹窗时关闭日程气泡的逻辑
   */
  agendaPopHoverClose() {
    clearTimeout(this.agendaBlockState.closePopOnPopHoverTimer);
    this.agendaBlockState.closePopOnPopHoverTimer = setTimeout(() => {
      this.weekAgendaState.showPopup = false;
      this.agendaBlockState.resetAgendaHoverFlag();
      clearTimeout(this.agendaBlockState.closePopOnPopHoverTimer);
    }, 200);
  }

  closeHoverPopTimerStart() {
    clearTimeout(this.agendaBlockState.closeHoverPopTimer);
    this.agendaBlockState.closeHoverPopTimer = setTimeout(() => {
      this.weekAgendaState.showPopup = false;
      this.agendaBlockState.resetAgendaHoverFlag();
      clearTimeout(this.agendaBlockState.closeHoverPopTimer);
    }, 80);
  }

  openNewHoverPop(curHoverBlock: AgendaBlockInfo | undefined) {
    if (!this.agendaBlockState.duringSwiperAnimation) { //在月视图滑动过程中不弹出pop
      this.preTimeHoverOnBlankArea = 0;
      this.preTimeHoverOnAgendaBlock = 0;
      this.weekAgendaState.showPopup = true;
      this.agendaBlockState.hoverBlock = curHoverBlock;
      this.agendaBlockState.hoverFlag = true;
    }
  }

  /**
   * 处理点击事件
   * @param index
   * @param event
   */
  onClickAgendaArea(index: number, totalWeekNum: number, event?: GestureEvent): ClickEventResultData {
    if (!event || !event.fingerList || !event.fingerList[0]) {
      Log.error(TAG, 'OnClickBlockAreaFocus Click Event Is Undefined');
      return new ClickEventResultData(ClickPositionType.NONE, undefined);
    }

    const width = px2vp(this.agendaBlockModel.cellWidth); // 单个日期的宽
    const clickData: ClickData = this.clickEvent(event);
    const eventType = clickData.getType();
    const isFold =
      clickData.getAgendaInfo() !== undefined && (clickData.getAgendaInfo() as AgendaBlockInfo).blockAgendas.length > 1;
    // 折叠日程块，PC ，单击打开气泡
    if (eventType === ClickPositionType.CLICK_AGENDA_BLOCK_ONCE && (this.needCommerce || isFold)) {
      Log.info(TAG, 'click agenda block once');
      //设置无响应悬停
      if (event.source === SourceType.TouchScreen) {
        this.setNoResponseHover();
      }

      return new ClickEventResultData(ClickPositionType.CLICK_AGENDA_BLOCK_ONCE,
        this.clickAgendaBlockOnce(clickData, index, width, totalWeekNum, event));
    }
    // 月视图非折叠日程块并且不是PC的情况下，单击，双击都跳转详情
    if (eventType === ClickPositionType.CLICK_AGENDA_BLOCK_ONCE ||
      eventType === ClickPositionType.CLICK_AGENDA_BLOCK_TWICE) {
      Log.info(TAG, 'click agenda block twice');
      const timer = setTimeout(() => {
        this.agendaBlockState.clickAgendaShow = false;
        this.agendaBlockState.hoverFlag = false;
        clearTimeout(this.agendaBlockState.timer);
        clearTimeout(timer);
      }, 300); // 添加时延设置点击状态，避免错误显示hover弹窗

      if (clickData.getAgendaInfo() === undefined) {
        Log.error(TAG, 'click agenda block twice, clickData.getAgendaInfo Is Undefined');
        return new ClickEventResultData(ClickPositionType.CLICK_AGENDA_BLOCK_TWICE, undefined);
      }
      const agendaBlock = clickData.getAgendaInfo() as AgendaBlockInfo;
      //折叠日程块不响应双击事件
      if (agendaBlock.blockAgendas.length > 1) {
        Log.info(TAG, 'click agenda block twice, collapse agendaBlock is not respond ');
        return new ClickEventResultData(ClickPositionType.CLICK_AGENDA_BLOCK_TWICE, undefined);
      }
      this.agendaBlockState.clickAgendaShow = true;

      if (AccountUtils.isBirthDayAccountById(agendaBlock.getInfo()?.mCalendarId)) {
        Log.info(TAG, 'click to contact detail');
      } else {
        // 跳转到日程详情
        this.toEventDetail(agendaBlock);
      }
      this.weekState.isWeekShow = false;
      ReportUtil.reportStatisticEvent(statisticEvents.monthCardViewAgendaDetail);
      return new ClickEventResultData(ClickPositionType.CLICK_AGENDA_BLOCK_TWICE, agendaBlock);
    } else if (eventType === ClickPositionType.CLICK_BLANK_AREA_ONCE) {
      Log.info(TAG, 'click blank area once');
      this.weekAgendaState.showPopup = false;
      return new ClickEventResultData(ClickPositionType.CLICK_BLANK_AREA_ONCE, undefined, clickData.getXIndex());
    } else if (eventType === ClickPositionType.CLICK_BLANK_AREA_TWICE) {
      Log.info(TAG, 'click blank area twice');
      //event.fingerList[0].localX：点击事件相对父组件的偏移度
      this.clickBlankAreaTwice(this.dayViewModels[clickData.getXIndex()],
        event.fingerList[0].localX, event.fingerList[0].localY);
      return new ClickEventResultData(ClickPositionType.CLICK_BLANK_AREA_TWICE, undefined);
    }
    return new ClickEventResultData(ClickPositionType.NONE, undefined);
  }

  /**
   * 处理长按事件,当前长按空白区域需要快速新建弹窗
   * @param index
   * @param event
   */
  onLongPressAgendaArea(index: number, event?: GestureEvent): ClickEventResultData {
    if (!event || !event.fingerList || !event.fingerList[0]) {
      Log.error(TAG, 'OnClickBlockAreaFocus Click Event Is Undefined');
      return new ClickEventResultData(ClickPositionType.NONE, undefined);
    }

    const clickData: ClickData = this.clickEvent(event);
    const eventType = clickData.getType();
    if (eventType === ClickPositionType.CLICK_BLANK_AREA_ONCE ||
      eventType === ClickPositionType.CLICK_BLANK_AREA_TWICE) {
      VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
      this.clickBlankAreaTwice(this.dayViewModels[clickData.getXIndex()],
        event.fingerList[0].localX, event.fingerList[0].localY);
      return new ClickEventResultData(ClickPositionType.CLICK_BLANK_AREA_TWICE, undefined);
    }

    return new ClickEventResultData(ClickPositionType.NONE, undefined);
  }

  /**
   * 日程详情跳转
   * @param eventId
   */
  toEventDetail(info: AgendaBlockInfo) {
    try {
      if (!info || !info.blockAgendas[0]) {
        Log.error(TAG, `info block error undefined`);
        return;
      }
      if (this.needCommerce) {
        this.weekState.openOtherPage = true;
        const agendaInfo = info.blockAgendas[0];
        AgendaAbilityManager.getInstance()
          .startAbilityByEventId(agendaInfo.mId, agendaInfo.mBegin, agendaInfo.mEnd, agendaInfo.mIsHoliday,
            agendaInfo.mTitle);
      } else {
        try {
          ThrottleFunction.instance().throttle(TAG, (): void => {
            const agendaInfo = info.blockAgendas[0];
            const param: Record<string, number | AgendaEventInfo> = {};
            param.id = agendaInfo.mId;
            param.holidayInfo = agendaInfo;
            param.instanceStartMills = agendaInfo.mBegin;
            param.instanceEndMills = agendaInfo.mEnd;
            NavPathManager.getInstance().pushPath({
              builderName: NavPathName.AGENDA_DETAIL,
              routerName: RouterName.ENTRY_HAP,
              param: param
            });
          }, 200)
        } catch (err) {
          Log.error(TAG, `toEventDetail error ${err?.message}`);
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'toEventDetail', err);
    }
  }

  /**
   * 单击（左键右键）月视图日程块之后，设置不响应hover效果
   */
  public setNoResponseHover(): void {
    this.agendaBlockState.clickAgendaShow = true;
    this.agendaBlockState.hoverFlag = false;
    clearTimeout(this.agendaBlockState.timer);
  }

  /**
   * 恢复月视图日程块响应hover效果
   */
  public recoverResponseHover(): void {
    this.agendaBlockState.clickAgendaShow = false;
  }

  /**
   * 点击空白处两次触发的事件
   * @param dayViewModel 双击位置对应的dayViewModel
   * @param posX 快速弹窗的x坐标
   * @param posY 快速弹窗的y坐标
   */
  private clickBlankAreaTwice(dayViewModel: SingleDayViewModel, posX: number, posY: number) {
    this.weekAgendaState.showPopup = false;
    if (dayViewModel) {
      const clickDateTime = dayViewModel.dayData.getTimeStamp();
      if (this.isCreateAgendaPopup) {
        this.createPageData = {
          data: {
            agendaDateParam: clickDateTime,
          }
        };
        // tablet设置快速新建pop窗的位置参数
        this.setPopParameter(posX, posY);
      } else {
        // phone跳转到新建日程
        const eventData: emitter.EventData = {
          data: {
            agendaDateParam: clickDateTime,
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
      }
    }
  }

  private clickAgendaBlockOnce(clickData: ClickData, index: number,
                               width: number, totalWeekNum: number, event: GestureEvent): AgendaBlockInfo | undefined {
    this.weekAgendaState.showPopup = false;
    this.isCreatePopupShow = false;
    if (!clickData.getAgendaInfo()) {
      return undefined;
    }
    //弹popup,折叠日程块：处于后Math.ceil(weekNumber/2)周的，弹出气泡朝上，否则朝下;
    //最后一周的非折叠日程块朝上展开，其余朝下展开
    const selectBlock = clickData.getAgendaInfo() as AgendaBlockInfo;
    this.computePopDirection(index, selectBlock, width, totalWeekNum);
    SafeUtil.setTimeout(() => {
      //如果是双击事件则不响应单击事件
      if (this.clickTwice) {
        return;
      }
      if (event.source == SourceType.TouchScreen) {
        this.weekAgendaState.showPopup = true;
      }
    }, 300)
    //焦点信息设置
    this.clickAgendaFocusSetting(selectBlock.columnStart, selectBlock.rowStart, index);
    return selectBlock;
  }

  public jumpCreateAgendaPop(clickDateTime: number) {
    this.createPageData = {
      data: {
        agendaDateParam: clickDateTime,
      }
    };
    this.openCreateAgendaPop();
  }

  public async jumpEditAgendaPop(selectBlock: AgendaBlockInfo | undefined, editType: number) {
    if (!selectBlock) {
      Log.error(TAG, `click to editAgendaPage err selectBlock undefined`);
      return;
    }
    let intent = CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE;
    if (editType === AgendaEditMenuOpt.ONLY_THIS_AGENDA) {
      intent = CreateAgendaPageSource.EDIT_THIS_AGENDA;
    } else if (editType === AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA) {
      intent = CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND;
    }
    const eventInfo = selectBlock.getInfo();
    if (!eventInfo) {
      Log.error(TAG, `click to editAgendaPage err eventInfo undefined`);
      return;
    }
    await AgendaOperateHelper.getCheckValueForEdit(eventInfo);
    this.createPageData = {
      data: {
        instanceStartMills: eventInfo.mBegin,
        instanceEndMills: eventInfo.mEnd,
        eventInfo: JSON.stringify(eventInfo),
        intent: intent,
      }
    };
    this.openCreateAgendaPop();
  }

  public openCreateAgendaPop() {
    this.isQuickCreate = false;
    this.isCreatePopupShow = true;
    //关闭气泡弹窗
    this.weekAgendaState.showPopup = false;
  }

  // 点到宫格的空白区域，当前日期格子获焦，右边列表展示选中日期
  public clickBlankArea(xIndex: number | undefined): boolean {
    if (xIndex === undefined) {
      Log.error(TAG, `clickBlankArea error index equals undefined`);
      return false;
    }
    if (xIndex < 0 || xIndex >= DAY_PER_WEEK) {
      Log.error(TAG, `clickBlankArea error index ${xIndex}`);
      return false;
    }
    if (!this.dayViewModels[xIndex]) {
      Log.error(TAG, `clickBlankArea or dayViewModels is null,  index ${xIndex}`);
      return false;
    }

    const isUgLanguage = I18nUtil.isUyghurLanguage(GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string);
    if (isUgLanguage) {
      // 维语 镜像
      this.dayViewModels[DAY_PER_WEEK - 1 - xIndex]
        .onClickChangeDisplayDate(this.dayState.isBackToToday, undefined);
    } else {
      this.dayViewModels[xIndex].onClickChangeDisplayDate(this.dayState.isBackToToday, undefined);
    }
    return true;
  }
}

export enum ClickPositionType {
  NONE, // 非法点击或无点击
  CLICK_AGENDA_BLOCK_ONCE, // 单击日程块
  CLICK_AGENDA_BLOCK_TWICE, // 双击日程块
  CLICK_BLANK_AREA_ONCE, // 单击空白区域
  CLICK_BLANK_AREA_TWICE // 双击空白区域
}

export class ClickData {
  constructor(xIndex: number = -1, yIndex: number = -1, agendaInfo: AgendaBlockInfo | undefined = undefined,
              type: ClickPositionType = ClickPositionType.NONE) {
    this.xIndex = xIndex;
    this.yIndex = yIndex;
    this.agendaInfo = agendaInfo;
    this.type = type;
  }

  private xIndex: number = 0;
  private yIndex: number = 0;
  private agendaInfo: AgendaBlockInfo | undefined = undefined;
  private type: number = -1;

  public getXIndex(): number {
    return this.xIndex;
  }

  public getYIndex(): number {
    return this.yIndex;
  }

  public getAgendaInfo(): AgendaBlockInfo | undefined {
    return this.agendaInfo;
  }

  public getType(): number {
    return this.type;
  }
}

export class ClickEventResultData {
  constructor(clickPositionType: ClickPositionType = ClickPositionType.NONE,
              selectBlock: AgendaBlockInfo | undefined = undefined, xIndex: number | undefined = undefined) {
    this.clickPositionType = clickPositionType;
    this.selectBlock = selectBlock;
    this.xIndex = xIndex;
  }

  private clickPositionType: ClickPositionType = ClickPositionType.NONE;
  private selectBlock: AgendaBlockInfo | undefined = undefined;
  private xIndex: number | undefined = undefined;

  public getClickPositionType(): ClickPositionType {
    return this.clickPositionType;
  }

  public getSelectBlock(): AgendaBlockInfo | undefined {
    return this.selectBlock;
  }

  public getXIndex(): number | undefined {
    return this.xIndex;
  }
}
