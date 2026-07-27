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
  CommonInnerEvent,
  DateUtil,
  EventService,
  GlobalData,
  GlobalDataKeys,
  InstanceService,
  Log,
  MILLS_PER_WEEK,
  ModeUtil,
  ReportUtil,
  ServiceEnum,
  ServiceManager,
} from '@app/common';
import { SingleMonthlyViewModel, SingleMonthlyViewModelArray } from './SingleMonthlyViewModel';
import { MonthlyInfo, DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { WeekTitleViewModel } from './WeekTitleViewModel';
import { MonthlyViewState, MonthlyViewStateManager, MonthlyWeekArrow } from './MonthlyViewState';
import { ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import emitter from '@ohos.events.emitter';
import { AgendaBlockInfo } from './WeekAgendaBlockModel';
import { addExDateToDb, updateUntilToDb } from '@app/feature.repeatrule';
import { AgendaOperateHelper } from '@app/feature.agenda/src/main/ets/helpers/AgendaOperateHelper';
import componentUtils from '@ohos.arkui.componentUtils';
import { MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { WeekTitleLayout } from '../layoutmodel/WeekTitleLayoutRule';
import { ReadOnlyDayCellProp } from '../layoutmodel/DayCellLayoutRule';
import { SingleMonthAgendaManager } from './SingleMonthAgendaManager';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';

const TAG: string = `[MonthlyView][MonthlyVM]`;

/**
 * MonthlyViewModel
 *
 * ViewModel of MonthlyView
 * Process monthly view layout
 * @since 2023-07-28
 */
@Observed
export class MonthlyViewModel {
  public readonly MAX_YEAR: number = 5000;
  public readonly MIN_YEAR: number = 1;
  public readonly MAX_MONTH_COUNT: number = 3;
  public readonly SWIPER_ANIMATION_TIME: number = 300;
  // 当前展示的年、月信息
  public dateInfo: DateInfo = new DateInfo(0, 0, 0);
  // 选中时间
  public selectDate: DateInfo = new DateInfo(0, 0, 0);
  // 存储单月模型
  public singleMonthlyViewModels: SingleMonthlyViewModelArray = new SingleMonthlyViewModelArray();
  // 周题
  public weekTitlesVM: WeekTitleViewModel = new WeekTitleViewModel();
  // 月视图的状态机
  public state: MonthlyViewState = MonthlyViewStateManager.getInstance().state;
  // 当前页面的索引值
  public currentIndex: number = 1;
  // 重要日查询序号，防止开关关闭后较早发起的异步查询回写旧数据
  private importantAgendaQueryVersion: number = 0;
  // 月视图所在的 Swiper 控制器
  public swiperController: SwiperController = new SwiperController();
  // 判断是否正在执行回到今天动画
  public isBackingToToday: boolean = false;
  // 判断是否正在执行回到今天翻页动效
  public isBackingToTodaySwipe: boolean = false;
  // 判断是否正在执行跨天回到当月动效
  private _isBackingToTodayAni: boolean = false;
  // 判断是否正在执行当月回到当月动效
  private _isBackingToTodayInMonth: boolean = false;
  // 判断是否正在执行跳转到某日
  public isJumpToSomeday: boolean = false;
  // 回到今天动画执行中禁止翻页
  public disableSwiper: boolean = false;
  private backOldIndex: number = -1; // 回到今天跳转前页签
  private backTargetIndex: number = -1; // 回到今天跳转后页签

  private readonly SWIPER_ANIMATION_LONG_TIME: number = 300; // 执行翻页选中圈出现动效的等待翻页时间
  private readonly COLOR_CHANGE_TIME: number = 250; // 动效过程中日期颜色变化的时间点
  // 每帧时长，KLV目前是1s/帧率，去各种设备最大值，klv的16.7.
  private readonly MAX_IDEAL_FRAME_TIME: number = 17;
  public isFollowingAgendaDeleting: boolean = false;
  public isThisAgendaDeleting: boolean = false;
  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();
  public isFirstRepeated: boolean = false;

  public constructor() {
    this.buildWeekTitle();
  }

  public get isBackingToTodayAni() {
    return this._isBackingToTodayAni;
  }

  public get isBackingToTodayInMonth() {
    return this._isBackingToTodayInMonth;
  }

  public set isBackingToTodayAni(isBackingToTodayAni: boolean) {
    this._isBackingToTodayAni = isBackingToTodayAni;
  }

  public set isBackingToTodayInMonth(isBackingToTodayInMonth: boolean) {
    this._isBackingToTodayInMonth = isBackingToTodayInMonth;
  }

  /**
   * 构造周题
   */
  buildWeekTitle() {
    this.weekTitlesVM = new WeekTitleViewModel();
  }


  /**
   * 一周开始日触发周题中的内容更新
   *
   * @param startOfWeek 一周开始日（0->6）对应周日->周六
   */
  updateWeekTitleByStartOfWeek(startOfWeek: number = 0) {
    if (!this.weekTitlesVM) {
      Log.error(TAG, 'NO VALID WEEK TITLE');
    }
    this.weekTitlesVM.startOfWeek = startOfWeek;
    this.weekTitlesVM.updateWeekTitles();
  }

  /**
   * 根据当前显示年月信息，初始化数据，将数据序列化
   *
   * @param displayDate 当前展示日期
   * @param currentIndex 当前屏幕上显示索引
   */
  reInitByMonth(displayDate: CalendarDate, currentIndex: number) {
    if (currentIndex < 0 || currentIndex >= this.MAX_MONTH_COUNT) {
      Log.error(TAG, 'NO VALID SWIPER INDEX!');
      return;
    }
    this.dateInfo = new DateInfo(displayDate.getFullYear(), displayDate.getMonth() + 1);
    this.selectDate = new DateInfo(this.dateInfo.year, this.dateInfo.month,
      CalendarUtils.getWeekNumberByDate(displayDate, this.state.startOfWeek), displayDate.getDate());
    const weekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    Log.log(TAG, `reInitByMonthly dateInfo:${this.selectDate.month} ${this.selectDate.weekNum} ${this.selectDate.day}`);
    this.buildSingleMonthlyViewModels(this.selectDate, currentIndex, weekShow);
    this.updateWeekTitleByStartOfWeek(this.state.startOfWeek); // 根据 一周开始日 初始化周题
  }

  /**
   * 构造单月模型数组，构建双端的链表
   *
   * @param displayMonth
   * @param currentIndex
   */
  buildSingleMonthlyViewModels(dateInfo: DateInfo, currentIndex: number, weekShow: boolean) {
    const displayYear: number = dateInfo.year;
    const displayMonth: number = dateInfo.month;
    // 初始化 singleMonthlyViewModels 数组
    this.singleMonthlyViewModels = new Array(this.MAX_MONTH_COUNT);
    const newDateInfo = weekShow ? new DateInfo(dateInfo.year, dateInfo.month,
      dateInfo.weekNum, dateInfo.day) :
      new DateInfo(displayYear, displayMonth);
    this.singleMonthlyViewModels[currentIndex] = new SingleMonthlyViewModel(newDateInfo, currentIndex);
    // 分别向数组两端初始化
    if (weekShow) {
      this.initMonthArrayWeekShow(currentIndex);
    } else {
      this.initMonthArray(currentIndex);
    }
  }

  initMonthArrayWeekShow(currentIndex: number) {
    let tempNode: SingleMonthlyViewModel = this.singleMonthlyViewModels[currentIndex];
    for (let i = currentIndex + 1; i <= this.MAX_MONTH_COUNT - 1; i++) {
      const displayDate = tempNode.selectDate.getDate().getTime();
      const newDisplayDate = new CalendarDate(displayDate + MILLS_PER_WEEK);
      const newDateInfo = new DateInfo(newDisplayDate.getFullYear(), newDisplayDate.getMonth() + 1,
        CalendarUtils.getWeekNumberByDate(newDisplayDate, this.state.startOfWeek), newDisplayDate.getDate());
      this.singleMonthlyViewModels[i] = new SingleMonthlyViewModel(newDateInfo, i);
      tempNode = this.singleMonthlyViewModels[i];
    }
    tempNode = this.singleMonthlyViewModels[currentIndex];
    for (let i = currentIndex - 1; i >= 0; i--) {
      const displayDate = tempNode.selectDate.getDate().getTime();
      const newDisplayDate = new CalendarDate(displayDate - MILLS_PER_WEEK);
      const newDateInfo = new DateInfo(newDisplayDate.getFullYear(), newDisplayDate.getMonth() + 1,
        CalendarUtils.getWeekNumberByDate(newDisplayDate, this.state.startOfWeek), newDisplayDate.getDate());
      this.singleMonthlyViewModels[i] = new SingleMonthlyViewModel(newDateInfo, i);
      tempNode = this.singleMonthlyViewModels[i];
    }

    // 将 singleMonthlyViewModel 互相连接 构建双端链表
    for (let i = 0; i < this.MAX_MONTH_COUNT - 1; i++) {
      this.singleMonthlyViewModels[i].nextMonthVM = this.singleMonthlyViewModels[i + 1];
    }
    for (let i = this.MAX_MONTH_COUNT - 1; i > 0; i--) {
      this.singleMonthlyViewModels[i].lastMonthVM = this.singleMonthlyViewModels[i - 1];
    }
    this.singleMonthlyViewModels[0].lastMonthVM = this.singleMonthlyViewModels[this.MAX_MONTH_COUNT - 1];
    this.singleMonthlyViewModels[this.MAX_MONTH_COUNT - 1].nextMonthVM = this.singleMonthlyViewModels[0];
  }

  initMonthArray(currentIndex: number) {
    let tempNode: SingleMonthlyViewModel = this.singleMonthlyViewModels[currentIndex];
    for (let i = currentIndex + 1; i <= this.MAX_MONTH_COUNT - 1; i++) {
      const tempMonth = tempNode.curMonthlyInfo.getNext();
      const dateInfo: DateInfo = new DateInfo(tempMonth.solarYear, tempMonth.solarMonth);
      this.singleMonthlyViewModels[i] = new SingleMonthlyViewModel(dateInfo, i);
      tempNode = this.singleMonthlyViewModels[i];
    }
    tempNode = this.singleMonthlyViewModels[currentIndex];
    for (let i = currentIndex - 1; i >= 0; i--) {
      const tempMonth = tempNode.curMonthlyInfo.getLast();
      const dateInfo: DateInfo = new DateInfo(tempMonth.solarYear, tempMonth.solarMonth);
      this.singleMonthlyViewModels[i] = new SingleMonthlyViewModel(dateInfo, i);
      tempNode = this.singleMonthlyViewModels[i];
    }

    // 将 singleMonthlyViewModel 互相连接 构建双端链表
    for (let i = 0; i < this.MAX_MONTH_COUNT - 1; i++) {
      this.singleMonthlyViewModels[i].nextMonthVM = this.singleMonthlyViewModels[i + 1];
    }
    for (let i = this.MAX_MONTH_COUNT - 1; i > 0; i--) {
      this.singleMonthlyViewModels[i].lastMonthVM = this.singleMonthlyViewModels[i - 1];
    }
    this.singleMonthlyViewModels[0].lastMonthVM = this.singleMonthlyViewModels[this.MAX_MONTH_COUNT - 1];
    this.singleMonthlyViewModels[this.MAX_MONTH_COUNT - 1].nextMonthVM = this.singleMonthlyViewModels[0];
  }

  /**
   * 更新日期数组
   *
   * @param index 新的索引
   * @param lastIndex 久的索引
   */
  updateDataArray(index: number, lastIndex: number) {
    const curMonthlyInfo: MonthlyInfo | undefined = this.singleMonthlyViewModels[index]?.curMonthlyInfo;
    let lastNode: SingleMonthlyViewModel | undefined = this.singleMonthlyViewModels[index];
    if (!curMonthlyInfo) {
      Log.error(TAG, 'NO VALID CUR MONTHLY INFO!');
      return;
    }
    let lastMonthCount: number = 0;
    let nextNode: SingleMonthlyViewModel | undefined = this.singleMonthlyViewModels[index];
    let nextMonthCount: number = 0;

    Log.info(TAG, `index: ${index}, lastIndex: ${lastIndex}`);

    // 当前展示的年、月信息
    this.updateDateInfo(curMonthlyInfo, index);

    // 向链表两端寻找
    while ((lastNode != this.singleMonthlyViewModels[lastIndex] &&
      nextNode != this.singleMonthlyViewModels[lastIndex])) {
      nextNode = nextNode?.nextMonthVM;
      nextMonthCount++;

      lastNode = lastNode?.lastMonthVM;
      lastMonthCount++;

      // 若回到起点则退出
      if (
        lastNode == this.singleMonthlyViewModels[index] || nextNode == this.singleMonthlyViewModels[index]
      ) {
        break;
      }
    }
    if (lastNode == this.singleMonthlyViewModels[lastIndex]) {
      this.updateSingleViewModelByIndex(nextNode?.arrayIndex, curMonthlyInfo, MonthlyWeekArrow.NEXT, nextMonthCount);
    } else {
      this.updateSingleViewModelByIndex(lastNode?.arrayIndex, curMonthlyInfo, MonthlyWeekArrow.LAST, lastMonthCount);
    }
  }

  updateDateInfo(curMonthlyInfo: MonthlyInfo, index: number) {
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    if (weekFlag) {
      const nowDateInfo = this.singleMonthlyViewModels[index]?.selectDate;
      const year: number = nowDateInfo.year;
      const month: number = nowDateInfo.month;
      const day: number = nowDateInfo.day;
      const newDisplayDate = new CalendarDate(year, month - 1, day);
      this.dateInfo = new DateInfo(year, month);
      this.selectDate = new DateInfo(this.dateInfo.year, this.dateInfo.month,
        CalendarUtils.getWeekNumberByDate(newDisplayDate, this.state.startOfWeek), newDisplayDate.getDate());
    } else {
      const year: number = curMonthlyInfo.solarYear;
      const month: number = curMonthlyInfo.solarMonth;
      const curDate = new CalendarDate(this.state.currentDate);
      const curYear: number = curDate.getFullYear();
      const curMonth: number = curDate.getMonth() + 1;
      const day: number = (curYear === year && curMonth === month) ? curDate.getDate() : 1;
      const newDisplayDate: CalendarDate = new CalendarDate(year, month - 1, day);
      this.dateInfo = new DateInfo(year, month);
      this.selectDate = new DateInfo(this.dateInfo.year, this.dateInfo.month,
        CalendarUtils.getWeekNumberByDate(newDisplayDate, this.state.startOfWeek), newDisplayDate.getDate());
    }
  }

  /**
   * update SingleViewModel By Index
   *
   * @param index the index of DataArray
   * @param monthlyInfo the month Info of SingleViewModel which is need to update
   * @param arrowState 更新方向
   * @param monthlyInfo 更新次数
   */
  updateSingleViewModelByIndex(index: number | undefined, monthlyInfo: MonthlyInfo,
                               arrowState: number, arrowCount: number = 1) {
    if (index === undefined) {
      Log.error(TAG, 'NO VALID INDEX OF SingleViewModel!');
      return;
    }
    let singleMonthlyViewModel = this.singleMonthlyViewModels[index];
    if (!singleMonthlyViewModel) {
      Log.error(TAG, `'singleMonthlyViewModel is null`);
      return;
    }
    Log.debug(TAG, `updateSingleViewModelByIndex index = ${index}, newMonth = ${monthlyInfo.solarMonth}`);
    singleMonthlyViewModel.updateSingleMonth(monthlyInfo, arrowState, arrowCount);
  }

  /**
   * update SingleViewModel By Index
   *
   * @param index the index of DataArray
   * @param monthlyInfo the month Info of SingleViewModel which is need to update
   */
  updateAllVMByIndex(index: number | undefined, monthlyInfo: MonthlyInfo, arrowCount: number = 1) {
    if (index === undefined) {
      Log.error(TAG, 'NO VALID INDEX IN updateAllVM !');
      return;
    }
    Log.log(TAG, `updateAllVMByIndex index = ${index}, newMonth = ${monthlyInfo.solarMonth}`);
    this.updateSingleViewModelByIndex(index, monthlyInfo,
      MonthlyWeekArrow.CURRENT, arrowCount); // update center month view
    this.updateNeighborVMByCenterIndex(index, monthlyInfo, arrowCount); // update right and left month view
  }

  /**
   * update neighbor SingleViewModel By centerSigMonthVM's Index
   *
   * @param index the index of centerSigMonthVM
   * @param monthlyInfo the month Info of SingleViewModel which is need to update
   */
  updateNeighborVMByCenterIndex(centerIndex: number | undefined, monthlyInfo: MonthlyInfo, arrowCount: number = 1) {
    if (centerIndex === undefined) {
      Log.error(TAG, 'NO VALID INDEX IN updateNeighborVMByCenterIndex !');
      return;
    }
    const centerSigMonthVM: SingleMonthlyViewModel = this.singleMonthlyViewModels[centerIndex];
    if (!centerSigMonthVM) {
      Log.error(TAG, 'centerSigMonthVM is null');
      return;
    }
    if (!centerSigMonthVM.lastMonthVM) {
      Log.error(TAG, 'lastMonthVM is null');
      return;
    }
    if (!centerSigMonthVM.nextMonthVM) {
      Log.error(TAG, 'nextMonthVM is null');
      return;
    }
    const lastIndex = centerSigMonthVM.lastMonthVM.arrayIndex as number;
    const nextIndex = centerSigMonthVM.nextMonthVM.arrayIndex as number;
    this.updateSingleViewModelByIndex(lastIndex, monthlyInfo, MonthlyWeekArrow.LAST, arrowCount);
    this.updateSingleViewModelByIndex(nextIndex, monthlyInfo, MonthlyWeekArrow.NEXT, arrowCount);
  }

  onTabsIndexChange(): void {
    Log.info(TAG, `onTabsIndexChange displayDateNum timeStamp = ${this.state.displayDate}`);
    const newDate: CalendarDate = new CalendarDate(this.state.displayDate);
    const newDisplayDate: DateInfo = new DateInfo(newDate.getFullYear(), newDate.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(newDate, this.state.startOfWeek), newDate.getDate());
    this.selectDate = newDisplayDate; // 更新视图选中时间
    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const arrowCount = weekFlag ? 0 : 1;
    this.isJumpToSomeday = false; // 标识位归位
    this.updateAllVMByIndex(this.currentIndex,
      new MonthlyInfo(newDisplayDate.year, newDisplayDate.month, this.state.startOfWeek), arrowCount);
    // 初始化 newVM 左右两个月的选中日期
    let newVM: SingleMonthlyViewModel | undefined = this.singleMonthlyViewModels[this.currentIndex];
    if (!newVM) {
      Log.error(TAG, 'newVM is null');
      return;
    }
    if (weekFlag) {
      newVM.updateWeekShowSelectDate(MonthlyWeekArrow.CURRENT);
    } else {
      newVM.lastMonthVM?.initSelectDay();
      newVM.nextMonthVM?.initSelectDay();
      newVM.updateSelectDay(this.selectDate);
    }
    //视图切换后给monthlyViewModel绑定的dateInfo重新赋值当前选中日期
    this.dateInfo = new DateInfo(newVM.curMonthlyInfo?.solarYear, newVM.curMonthlyInfo?.solarMonth);
  }

  reportDisplayDateChange() {
    let newVM: SingleMonthlyViewModel | undefined = this.singleMonthlyViewModels[this.currentIndex];
    if (!newVM) {
      Log.error(TAG, 'newVM is null');
      return;
    }
    let normalLen: number = 0;
    let importantLen: number = 0;
    if (newVM.sigAgendaManager?.todayNormalAgendas) {
      normalLen = newVM.sigAgendaManager.todayNormalAgendas.length
    }
    if (newVM.sigAgendaManager?.todayImportantAgendas) {
      importantLen = newVM.sigAgendaManager.todayImportantAgendas.length
    }
    let params: ReportHiEventParams = {
      NORMAL_AGENDA_COUNTS: normalLen,
      IMPORTANT_AGENDA_COUNTS: importantLen,
      TIME_POINT: this.selectDate.getDate().getTime()
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.selectedDayAgendaCounts, params);
  }

  onDisplayDateChange() {
    const newDate: CalendarDate = new CalendarDate(this.state.displayDate);
    Log.info(TAG, 'onDisplayDateChange displayDateNum = ' + newDate.toDateString());
    const newDisplayDate: DateInfo = new DateInfo(newDate.getFullYear(), newDate.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(newDate, this.state.startOfWeek), newDate.getDate());

    // 找到新旧对应的DayVM，先删除旧的选中态，再更新新的选中态
    this.singleMonthlyViewModels.forEach((item) => {
      item.updateSelectDay(newDisplayDate);
      // 更新选中日期需要将日程列表移动至第一个未过期日程
      Log.info(TAG, 'updateScrollToTop by onDisplayDateChange');
      item.agendaListModel.updateScrollToTop();
    })

    const weekFlag = MonthlyViewStateManager.getInstance().weekState.isWeekShow; // 是否处于周视图下
    const isInMonth = newDisplayDate.year === this.dateInfo.year &&
      newDisplayDate.month === this.dateInfo.month; //是否处于同一月

    if (isInMonth && this.selectDate.day === newDisplayDate.day) {
      // 没有变动,无需更新
      Log.info(TAG, 'onDisplayDateChange There is no need to refresh');
      return;
    }

    const oldSelectDate = this.selectDate;
    this.selectDate = newDisplayDate;

    if ((!weekFlag || newDisplayDate.weekNum === oldSelectDate.weekNum) && isInMonth) {
      // 周视图当周或非周视图当月内变更，不需要改变swiperIndex
      let singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
      if (!singleMonthlyViewModel) {
        Log.error(TAG, 'singleMonthlyViewModel is null');
        return;
      }
      singleMonthlyViewModel.updateNearlyMonthly();
      this.reportDisplayDateChange();
      return;
    }

    // 其他月变更
    this.updateMonthInfoForDisplayDateChange(newDate, newDisplayDate, weekFlag);
  }

  updateMonthInfoForDisplayDateChange(newDate: CalendarDate, newDisplayDate: DateInfo, weekFlag: boolean) {
    let newVM: SingleMonthlyViewModel | undefined = this.singleMonthlyViewModels[this.currentIndex];
    if (newDate.getTime() <= new CalendarDate(this.dateInfo.year, this.dateInfo.month - 1, 1).getTime()) {
      // 向前滑动一个月
      newVM = newVM?.lastMonthVM;
    } else {
      // 向后滑动一个月
      newVM = newVM?.nextMonthVM;
    }
    if (!newVM) {
      Log.error(TAG, 'newVM is null');
      return;
    }
    const newMonthInfo = new MonthlyInfo(newDisplayDate.year, newDisplayDate.month, this.state.startOfWeek);
    const arrowCount = weekFlag ? 0 : 1;
    this.updateAllVMByIndex(newVM.arrayIndex, newMonthInfo, arrowCount);

    // 初始化 newVM 左右两个月的选中日期
    if (weekFlag) {
      newVM.updateWeekShowSelectDate(MonthlyWeekArrow.CURRENT);
    } else {
      newVM.lastMonthVM?.initSelectDay();
      newVM.nextMonthVM?.initSelectDay();
      newVM.updateSelectDay(this.selectDate);
    }

    this.currentIndex = newVM.arrayIndex as number;
    this.dateInfo = new DateInfo(newVM.curMonthlyInfo?.solarYear, newVM.curMonthlyInfo?.solarMonth);
  }

  onStartOfWeekChange(startOfWeek: number) {
    Log.info(TAG, 'onStartOfWeekChange: ' + startOfWeek);
    this.updateWeekTitleByStartOfWeek(startOfWeek);
    this.singleMonthlyViewModels.forEach((item) => {
      item.onStartOfWeekChange(startOfWeek);
    })
    this.selectDate.weekNum = CalendarUtils.getWeekNumberByDate(this.selectDate.getDate(), startOfWeek);
  }

  onWeekendsChange(weekends: number[]) {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onWeekendsChange(weekends);
    })
  }

  getDeleteAgendaDialogTitle(selectBlock: AgendaBlockInfo | undefined): ResourceStr {
    if (!selectBlock) {
      return '';
    }
    return $r('app.string.whether_to_delete', selectBlock?.getInfo().mTitle);
  }

  async getEventByInstance(instance: AgendaEventInfo) {
    return await EventService.INSTANCE.queryEventById(instance.mId);
  }

  // 删除当前单个日程
  async deleteThisAgenda(selectBlock: AgendaBlockInfo | undefined) {
    if (!selectBlock?.blockId) {
      return;
    }
    this.isThisAgendaDeleting = true;
    const instance = selectBlock.getInfo();
    const isDeleted = await addExDateToDb(selectBlock.blockId, instance.mBegin);
    if (isDeleted) {
      this.mAgendaOperateHelper.eventToSoftDelete(selectBlock.blockId, instance.mBegin);
    } else {
      this.isThisAgendaDeleting = false;
      Log.warn(TAG, 'deleteThisAgenda fail');
    }
  }

  // 删除此日程和将来的日程
  async deleteThisAgendaAndBeyond(selectBlock: AgendaBlockInfo | undefined) {
    if (!selectBlock?.blockId) {
      return;
    }
    this.isFollowingAgendaDeleting = true;
    const instance = selectBlock.getInfo();
    const isDeleted = await updateUntilToDb(selectBlock.blockId, instance.mBegin);
    if (isDeleted) {
      this.mAgendaOperateHelper.eventToSoftDelete(selectBlock.blockId, instance.mBegin);
    } else {
      this.isFollowingAgendaDeleting = false;
      Log.warn(TAG, 'deleteThisAgendaAndBeyond fail');
    }
  }

  // 是否重复日程第一条
  async setIsFirstRepeatAgenda(selectBlock: AgendaBlockInfo): Promise<boolean> {
    return new Promise<boolean>(async (resolve, reject) => {
      if (!selectBlock) {
        this.isFirstRepeated = false;
        resolve(false);
        return;
      }
      const instance = selectBlock.getInfo();
      const event = await this.getEventByInstance(instance);
      if (!event.isRepeatEvent()) {
        this.isFirstRepeated = false;
        resolve(false);
        return;
      }
      if (instance.mBegin === event.mBegin) {
        this.isFirstRepeated = true;
        resolve(true);
        return;
      }
      this.isFirstRepeated = false;
      resolve(false);
    })
  }

  /**
   * 历法变更
   */
  onSubscriptionCalendar(subscriptionCalendar: number) {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onSubscriptionCalendar(subscriptionCalendar);
    })
  }

  onShowImportantDayChange(showImportantDay: boolean): void {
    this.updateImportantAgenda(showImportantDay);
    this.singleMonthlyViewModels.forEach((item) => {
      item.onShowImportantDayChange(showImportantDay);
    })
  }

  /**
   * 深色模式变更
   */
  onDarkModeChange() {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onDarkModeChange();
    })
  }

  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE) {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onChineseHolidayStateChange(chineseHolidayState);
    })
  }

  /**
   * 语言变更  ----
   */
  onLanguageChange(language: string): void {
    this.weekTitlesVM.updateWeekLanguage(language);
    this.singleMonthlyViewModels.forEach((item) => {
      item.onLanguageChange(language);
    })
  }

  onThemeChange(): void {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onThemeChange();
    })
  }

  /**
   * 地区变更
   */
  onSystemRegionChange(systemRegion: string) {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onSystemRegionChange(systemRegion);
    })
  }

  onSwiperIndexChange(index: number): void {
    // Swiper 滑动
    Log.debug(TAG, 'from：' + this.currentIndex + ' to:' + index);
    if (this.currentIndex === index) {
      return;
    }

    // 翻页时执行结束动效函数
    this.clearAnimation()

    // 全量更新月份数据 VM
    this.updateDataArray(index, this.currentIndex);

    // 修改全局的选中时间
    if (MonthlyViewStateManager.getInstance().weekState.isWeekShow) {
      const selectDate = this.singleMonthlyViewModels[index]?.selectDate;
      const newDisplayDate = DateUtil.dateToStamp(selectDate.year, selectDate.month - 1, selectDate.day);
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDisplayDate);
    } else {
      const year = this.dateInfo.year;
      const month = this.dateInfo.month;
      const curDate: CalendarDate = new CalendarDate(this.state.currentDate);
      const curYear: number = curDate.getFullYear();
      const curMonth: number = curDate.getMonth() + 1;
      const day: number = (curYear === year && curMonth === month) ? curDate.getDate() : 1;
      const newDisplayDate = DateUtil.dateToStamp(year, month - 1, day);
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDisplayDate);
    }
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
  }

  onCurrentDateChange(currentDate: number): void {
    Log.info(TAG, 'onCurrentDateChange: currentDate = ' + currentDate);
    this.singleMonthlyViewModels.forEach((item: SingleMonthlyViewModel) => {
      item.onCurrentDateChange(currentDate);
    })
  }

  onTimeZoneChange(currentDate: number): void {
    Log.info(TAG, `onTimeZoneChange: currentDate = ${currentDate}, nowTimeZone: ${CalendarDate.timeZone}`);
    this.singleMonthlyViewModels.forEach((item: SingleMonthlyViewModel) => {
      item.onTimeZoneChange(currentDate);
    })
  }

  /**
   * 处理数据变化广播
   */
  async onDataChange(showImportantDay: boolean) {
    // 查询账户信息
    this.updateImportantAgenda(showImportantDay);
    await this.updateCalendarAccount();
    for (let i = 0; i < this.singleMonthlyViewModels.length; i++) {
      await this.singleMonthlyViewModels[i].onDataChange();
    }
  }

  /**
   * 从当前缓存的三个月视图中移除已删除的日程实例。
   */
  onAgendaSoftDelete(eventId: number, displayStartMills: number): void {
    this.singleMonthlyViewModels.forEach((item: SingleMonthlyViewModel): void => {
      item.sigAgendaManager.onAgendaSoftDelete(eventId, displayStartMills);
    });
  }

  // 查询账户
  async updateCalendarAccount() {
    SingleMonthAgendaManager.accountList = await InstanceService.INSTANCE.queryAccountListTask();
  }

  // 查询重要日日程
  async updateImportantAgenda(showImportantDay: boolean) {
    const queryVersion = ++this.importantAgendaQueryVersion;
    const allImportantResult = showImportantDay ? await InstanceService.INSTANCE.queryImportantEventsTask() : [];
    if (queryVersion !== this.importantAgendaQueryVersion || showImportantDay !== this.state.showImportantDay) {
      Log.info(TAG, `ignore expired important agenda result, showImportantDay = ${showImportantDay}`);
      return;
    }
    this.singleMonthlyViewModels.forEach((item: SingleMonthlyViewModel) => {
      item.updateImportantAgenda(AgendaEventInfo.batchDeepCloneAgenda(allImportantResult));
    })
  }


  /**
   * 是否隐藏月视图日程列表
   * @param hideAgendaWindow
   */
  onAgendaListStateChange(hideAgendaWindow: boolean, needAni: boolean = true, dividerMove: boolean = true) {
    this.singleMonthlyViewModels.forEach((item: SingleMonthlyViewModel) => {
      item.onAgendaListStateChange(hideAgendaWindow, needAni, dividerMove);
    })
  }

  /**
   * 处理跳转到某天的动作
   */
  onJumpToSomeDay(timeOfJumpDay: number) {
    const jumpDay: CalendarDate = new CalendarDate(timeOfJumpDay);
    const isInMonth = this.dateInfo.year === jumpDay.getFullYear() &&
      this.dateInfo.month === jumpDay.getMonth() + 1;
    const isWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const startOfWeek = this.singleMonthlyViewModels[this.currentIndex]?.startOfWeek;
    const jumpWeek = CalendarUtils.getWeekNumberByDate(jumpDay, startOfWeek);

    // 更新选中时间
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, timeOfJumpDay);
    if (isInMonth && (!isWeekShow || this.selectDate.weekNum === jumpWeek)) {
      this.displayDateChangeRefresh(timeOfJumpDay);
    } else {
      this.jumpToSomeDayInOtherMonth(timeOfJumpDay, jumpDay, isWeekShow);
    }
  }

  jumpToSomeDayInOtherMonth(timeOfJumpDay: number, jumpDay: CalendarDate, isWeekShow: boolean) {
    // 防止触发swiper动画事件
    this.isJumpToSomeday = true;

    this.state.displayDate = timeOfJumpDay;

    let oriStartOfWeek = AppStorage.get<number>(`startOfWeek`);
    if (!oriStartOfWeek) {
      oriStartOfWeek = -1;
    }
    const startOfWeek: number = DateUtil.getStartOfWeek(oriStartOfWeek);
    const jumpMonthInfo = new MonthlyInfo(jumpDay.getFullYear(), jumpDay.getMonth() + 1, startOfWeek);
    let targetVMIndex: number = 1;
    const oldVMIndex: number = this.currentIndex;

    // 优先开始swiper动画，找到目标单月视图的索引值
    if (timeOfJumpDay < this.selectDate.getDate().getTime()) {
      Log.debug(TAG, 'swiper To Last Month!');
      this.swiperController.showPrevious();
      targetVMIndex = this.singleMonthlyViewModels[this.currentIndex]?.lastMonthVM?.arrayIndex as number;
    } else {
      this.swiperController.showNext();
      Log.debug(TAG, 'swiper To Next Month!');
      targetVMIndex = this.singleMonthlyViewModels[this.currentIndex]?.nextMonthVM?.arrayIndex as number;
    }

    const targetVM = this.singleMonthlyViewModels[targetVMIndex];

    // 更新目标单月视图的视图数据
    this.updateSingleViewModelByIndex(targetVMIndex, jumpMonthInfo, MonthlyWeekArrow.CURRENT);

    // 找到目标单月视图中新旧对应的单日视图，先删除旧的选中态，再更新新的选中态
    targetVM.updateSelectDay(new DateInfo(
      jumpDay.getFullYear(),
      jumpDay.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(jumpDay, this.state.startOfWeek),
      jumpDay.getDate()))

    // 更新月视图的选中天
    this.selectDate = new DateInfo(
      jumpDay.getFullYear(),
      jumpDay.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(jumpDay, this.state.startOfWeek),
      jumpDay.getDate());

    //清除旧页面选中态
    this.singleMonthlyViewModels[oldVMIndex].updateSelectDay();

    // 刷新月视图目标月左右相邻单月视图
    const curMonthInfo = targetVM.curMonthlyInfo;
    if (isWeekShow) {
      targetVM.updateWeekShowSelectDate(MonthlyWeekArrow.CURRENT);
      targetVM.updateNearlyMonthly();
    } else {
      this.updateNeighborVMByCenterIndex(targetVMIndex, curMonthInfo);
      targetVM.lastMonthVM?.initSelectDay();
      targetVM.nextMonthVM?.initSelectDay();
    }

    this.dateInfo = new DateInfo(jumpDay.getFullYear(), jumpDay.getMonth() + 1);
  }

  /**
   * 处理回到今天动作
   */
  onBackToToday() {
    let singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
    if (!singleMonthlyViewModel) {
      Log.error(TAG, 'singleMonthlyViewModel is null');
      return;
    }
    // 添加回到今天清除选中特效
    this.clearAnimation();

    const currentTime: number = this.state.currentDate;
    const currentDate: CalendarDate = new CalendarDate(currentTime);
    const isInMonth = this.dateInfo.year === currentDate.getFullYear() &&
      this.dateInfo.month === currentDate.getMonth() + 1;
    const isWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const startOfWeek = singleMonthlyViewModel.startOfWeek;
    const currentWeek = CalendarUtils.getWeekNumberByDate(currentDate, startOfWeek);
    // 当月内回到今天
    if (isInMonth && (!isWeekShow || this.selectDate.weekNum === currentWeek)) {
      //当前已经是今天,无需响应触发
      const oldDate = singleMonthlyViewModel.selectDate?.getDate();
      if (oldDate?.getDate() === currentDate.getDate()) {
        Log.info(TAG, 'Now is Today, No need to Update!');
        return;
      }
      Log.info(TAG, `Today is In Current Month, No Need to swiper! Today is  + ${this.state.currentDate}`);
      //判断曲线
      const oldTime = oldDate?.getTime() || 0;
      const curveFlag = currentTime > oldTime;
      // 通知原先圆圈的透明度变化 1->0
      singleMonthlyViewModel.clearSelectDay();
      if (!(MonthlyViewStateManager.getInstance().modeState.isForceSmall)) {
        // 回到今天动画 初始化 选中圈的位置
        singleMonthlyViewModel.onBackToTodayAppear();
      }
      this.backToTodayAnimationForSameSwipe(curveFlag, currentTime);

      return;
    }
    singleMonthlyViewModel.agendaListModel.updateScrollToTop();
    this.onBackToTodayFromOtherMonth(currentTime, currentDate, isWeekShow);
  }

  backToTodayAnimationForSameSwipe(curveFlag: boolean, currentTime: number) {
    let singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
    if (!singleMonthlyViewModel) {
      Log.error(TAG, 'singleMonthlyViewModel is null');
      return;
    }
    this.isBackingToTodayInMonth = true;
    MonthlyViewStateManager.getInstance().onIsBackingToTodayChange(this.isBackingToTodayInMonth);
    //显隐变化
    animateTo({
      duration: 100,
      curve: Curve.Linear,
      delay: 200,
      iterations: 1, // 设置-1表示动画无限循环
      playMode: PlayMode.Normal,
    }, () => {
      singleMonthlyViewModel.onBackToTodayShow();
    })
    //颜色变化
    setTimeout(() => {
      singleMonthlyViewModel.onBackToTodayColorChange(true);
    }, this.COLOR_CHANGE_TIME);
    //Y坐标变化
    animateTo({
      duration: 400,
      curve: curveFlag ? Curve.Friction : Curve.Smooth,
      delay: 0,
      iterations: 1, // 设置-1表示动画无限循环
      playMode: PlayMode.Normal,
    }, () => {
      singleMonthlyViewModel.onBackToTodayY();
    })
    //X坐标变化
    animateTo({
      duration: 400,
      curve: curveFlag ? Curve.Smooth : Curve.Friction,
      delay: 0,
      iterations: 1, // 设置-1表示动画无限循环
      playMode: PlayMode.Normal,
      onFinish: () => { //动画结束后的后续处理
        Log.info(TAG, 'play end');
        Log.info(TAG,
          'end back to today circleX ' + singleMonthlyViewModel.circleX +
            ' , circleY = ' + singleMonthlyViewModel.circleY);
        this.finishBackToTodaySameMonthAni(singleMonthlyViewModel, currentTime);
      }
    }, () => {
      singleMonthlyViewModel.onBackToTodayX();
    })
  }

  // 当月回到今天结束执行方法
  finishBackToTodaySameMonthAni(singleMonthlyViewModel: SingleMonthlyViewModel, currentTime: number) {
    if (!this.isBackingToTodayInMonth) {
      return;
    }
    if (singleMonthlyViewModel) {
      singleMonthlyViewModel.onBackToTodayDisappear();
    }

    //刷新视图
    this.displayDateChangeRefresh(currentTime);
    this.isBackingToTodayInMonth = false;
    MonthlyViewStateManager.getInstance().onIsBackingToTodayChange(this.isBackingToTodayInMonth);
  }

  /**
   * 非当月回到今天
   *
   * @param currentTime
   * @param currentDate
   */
  onBackToTodayFromOtherMonth(currentTime: number, currentDate: CalendarDate, isWeekShow: boolean) {
    this.disableSwiper = true;
    this.isBackingToToday = true;
    this.isBackingToTodaySwipe = true;
    MonthlyViewStateManager.getInstance().onIsBackingToTodayChange(this.isBackingToToday);
    // 优先开始swiper动画
    if (currentTime < this.selectDate.getDate().getTime()) {
      this.swiperController.showPrevious();
    } else {
      this.swiperController.showNext();
    }

    setTimeout(() => {
      this.animateAfterSwipeAnimateBegin(currentTime, currentDate, isWeekShow);
    }, this.MAX_IDEAL_FRAME_TIME);
  }

  animateAfterSwipeAnimateBegin(currentTime: number, currentDate: CalendarDate, isWeekShow: boolean) {
    // 更新选中时间
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, currentTime);
    let oriStartOfWeek = AppStorage.get<number>(`startOfWeek`);
    if (!oriStartOfWeek) {
      oriStartOfWeek = -1;
    }
    const startOfWeek: number = DateUtil.getStartOfWeek(oriStartOfWeek);
    const monthDate: CalendarDate = this.selectDate.getDate();
    const currentMonthInfo = new MonthlyInfo(currentDate.getFullYear(), currentDate.getMonth() + 1, startOfWeek);
    let targetVMIndex: number = 1;
    const oldVMIndex: number = this.currentIndex;
    let arrowCount: number = 1;
    // 周视图回到今天需要优先设置displayDate
    if (isWeekShow) {
      this.state.displayDate = currentTime;
      arrowCount = 0; // 周视图特殊刷新逻辑
    }
    if (currentTime < monthDate.getTime()) {
      Log.debug(TAG, 'swiper To Last Month!')
      // 找到当前月份的索引值
      targetVMIndex = this.singleMonthlyViewModels[this.currentIndex]?.lastMonthVM?.arrayIndex as number;
    } else {
      Log.debug(TAG, 'swiper To Next Month!')
      // 找到当前月份的索引值
      targetVMIndex = this.singleMonthlyViewModels[this.currentIndex]?.nextMonthVM?.arrayIndex as number;
    }
    this.backOldIndex = oldVMIndex;
    this.backTargetIndex = targetVMIndex;

    // 通知原先圆圈的透明度变化 1->0, 修改目标VM的选中时间且默认不选中
    this.singleMonthlyViewModels[targetVMIndex].initSelectDay(false, false);

    // 更新目标月份的选中天
    this.singleMonthlyViewModels[targetVMIndex].selectDate = new DateInfo(
      currentDate.getFullYear(),
      currentDate.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(currentDate, this.state.startOfWeek),
      currentDate.getDate());

    // 更新目标月份的数据
    this.updateSingleViewModelByIndex(targetVMIndex, currentMonthInfo, MonthlyWeekArrow.CURRENT);

    // 更新当前选中圈和选中日期
    this.dateInfo = new DateInfo(currentDate.getFullYear(), currentDate.getMonth() + 1);
    this.selectDate = new DateInfo(
      currentDate.getFullYear(),
      currentDate.getMonth() + 1,
      CalendarUtils.getWeekNumberByDate(currentDate, this.state.startOfWeek),
      currentDate.getDate());
    this.singleMonthlyViewModels[targetVMIndex].initSelectDay();


    setTimeout(() => {
      this.animateAfterSwipeAnimateEnd(oldVMIndex, targetVMIndex, currentDate, arrowCount, isWeekShow);
    }, this.SWIPER_ANIMATION_LONG_TIME)
  }

  animateAfterSwipeAnimateEnd(oldVMIndex: number, targetVMIndex: number, currentDate: CalendarDate,
    arrowCount: number, isWeekShow: boolean): void {
    this.disableSwiper = false;
    if (!this.isBackingToToday) {
      return;
    }
    this.isBackingToTodayAni = true;

    //清除旧页面选中态
    this.singleMonthlyViewModels[oldVMIndex]?.updateSelectDay();
    let targetVM = this.singleMonthlyViewModels[targetVMIndex];
    if (!targetVM) {
      Log.error(TAG, 'targetVM is null')
      this.isBackingToTodayAni = false;
      return;
    }
    // 刷新目标页面左右相邻视图
    const curMonthInfo = targetVM.curMonthlyInfo;
    if (isWeekShow) {
      targetVM.updateNearlyMonthly();
    } else {
      this.updateNeighborVMByCenterIndex(targetVMIndex, curMonthInfo, arrowCount);
      targetVM.lastMonthVM?.initSelectDay();
      targetVM.nextMonthVM?.initSelectDay();
    }
    this.backingAnimateFinish(currentDate, targetVMIndex);
  }

  backingAnimateFinish(currentDate: CalendarDate, targetVMIndex: number) {
    this.isBackingToToday = false;
    this.isBackingToTodayAni = false;
    this.backOldIndex = -1;
    this.backTargetIndex = -1;

    this.currentIndex = targetVMIndex;
    MonthlyViewStateManager.getInstance().onIsBackingToTodayChange(this.isBackingToToday);
    // 选中时间 变更，状态机记录
    this.state.displayDate = currentDate.getTime();
  }

  // 结束回到今天翻页动画
  finishAfterSwipeAnimateEnd(currentDate: CalendarDate, isWeekShow: boolean) {
    if (this.backOldIndex === -1 || this.backTargetIndex === -1) {
      return;
    }
    const arrowCount = isWeekShow ? 0 : 1;
    this.animateAfterSwipeAnimateEnd(this.backOldIndex, this.backTargetIndex, currentDate, arrowCount, isWeekShow);
  }

  // 结束回到今天选中圈变化动效
  finishBackingAnimateFinish(currentDate: CalendarDate) {
    if (this.backTargetIndex === -1) {
      return;
    }
    this.backingAnimateFinish(currentDate, this.backTargetIndex);
  }

  /**
   * 刷新视图,设置displayDate用
   */
  displayDateChangeRefresh(displayDate: number) {

    // 选中时间 变更，状态机记录
    this.state.displayDate = displayDate;

    // 更新视图
    this.onDisplayDateChange();

  }

  //由小屏转为宽屏时如未初始化日程块则需要重新刷新日程块
  refreshAgendaBlock() {
    // 对每个缓存视图初始化日程块
    this.singleMonthlyViewModels.forEach((item) => {
      item.refreshAgendaBlock();
    })
  }

  //由小屏转为宽屏时如处于周视图状态则需还原为月视图状态
  restoreMonthShow() {
    let singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
    if (!singleMonthlyViewModel) {
      Log.error(TAG, `'singleMonthlyViewModel is null`);
      return;
    }
    singleMonthlyViewModel.restoreMonthShow();
  }

  //切换内外屏需要重新设置当前的月周全屏态
  changeMonthShow(isInSmallFold: boolean) {
    let singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
    if (!singleMonthlyViewModel) {
      Log.error(TAG, `'singleMonthlyViewModel is null`);
      return;
    }
    singleMonthlyViewModel.changeMonthShow(isInSmallFold);
  }

  // 更新当前视图的高度
  updateNowMonthHeight(nowMonthHeight: number, nowWeekHeight: number) {
    this.singleMonthlyViewModels.forEach((item) => {
      item.updateNowMonthHeight(nowMonthHeight, nowWeekHeight);
    })
  }

  updateMonthWeekAgendaHeight(nowMonthHeight: number, nowDayHeight: number, isSmall: boolean = false) {
    const circleLine = ReadOnlyDayCellProp.circleLine; // 每周的日期下边距
    // 计算可用的月视图高度
    const normalMonthHeight = nowMonthHeight - this.getMonthDatePadding(isSmall);
    // 计算当前每一周日期的高度
    const normalDayHeight = nowDayHeight + circleLine;

    this.singleMonthlyViewModels.forEach((item) => {
      item.updateWeekAgendaHeight(normalMonthHeight, normalDayHeight, isSmall);
    })
  }

  getMonthDatePadding(isSmall: boolean = false): number {
    //首先尝试获取当前周题高度
    const weekSize = componentUtils.getRectangleById(`monthWeekTitle_${this.currentIndex}`);
    let weekTitleHeight = weekSize && weekSize.size ?
    px2vp(weekSize.size.height) : MonthStaticLayout.weekTitleHeight;
    if (weekTitleHeight === 0) {
      weekTitleHeight = MonthStaticLayout.weekTitleHeight; // 当前周题高度
    }
    Log.info(TAG, `'updateWeekAgendaHeight: weekTitleHeight = ${weekTitleHeight}`);
    const weekTitlePadding = MonthStaticLayout.weekTitlePaddingBottom; // 周题的下边距
    const isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
    const monthPadding = MonthStaticLayout.singleMonthPadding; // 月视图的下内边距
    const monthTopPadding = isGrid ? 8 : MonthStaticLayout.singleMonthPadding; // 月视图的上内边距
    const monthGap = WeekTitleLayout.marginDownGap; // 月视图的上下外边距
    const weekTitleTop = MonthViewLayoutModel.getInstance().frameProp.value.monthPaddingTop;
    const largePadding = isSmall ? 0 : (monthPadding + monthTopPadding);

    return weekTitleHeight + weekTitlePadding + weekTitleTop + largePadding + monthGap * 2;
  }

  swiperFlitEvent(isNext: boolean) {
    if (isNext) {
      this.swiperController.showNext();
    } else {
      this.swiperController.showPrevious();
    }
  }

  // 清空当前执行的动效
  clearAnimation() {
    // 清空月视图上滑动效
    this.singleMonthlyViewModels.forEach((singleModels) => {
      singleModels.cutAnimationUpdate();
    })

    // 清空回到今天动效
    if (this.isBackingToTodayAni) {
      this.finishBackingToTodayAni();
    }

    // 清空回到今天翻页动效
    if (this.isBackingToToday) {
      this.finishBackingToTodaySwipe();
    }

    // 清空当月回到今天翻页动效
    if (this.isBackingToTodayInMonth) {
      this.finishBackingToTodayInMonth();
    }
  }

  private finishBackingToTodaySwipe() {
    const isWeekShow = MonthlyViewStateManager.getInstance().weekState.isWeekShow;
    const currentDate: CalendarDate = new CalendarDate(MonthlyViewStateManager.getInstance().state.currentDate);
    this.finishAfterSwipeAnimateEnd(currentDate, isWeekShow);
  }

  private finishBackingToTodayAni() {
    const currentDate: CalendarDate = new CalendarDate(MonthlyViewStateManager.getInstance().state.currentDate);
    this.finishBackingAnimateFinish(currentDate);
  }

  private finishBackingToTodayInMonth() {
    const singleMonthlyViewModel = this.singleMonthlyViewModels[this.currentIndex];
    const currentTime: number = this.state.currentDate;
    this.finishBackToTodaySameMonthAni(singleMonthlyViewModel, currentTime);
  }

  changeBackTargetIndex(index: number) {
    this.backTargetIndex = index;
  }

  changeBackOldIndex(index: number) {
    this.backOldIndex = index;
  }

  /**
   * 大小屏切换需要重新绑定drawModifier
   */
  onSmallStatusChange() {
    this.singleMonthlyViewModels.forEach((item) => {
      item.onSmallStatusChange();
    })
  }
}
