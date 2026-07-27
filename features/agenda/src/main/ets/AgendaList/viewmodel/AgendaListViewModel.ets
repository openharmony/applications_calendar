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
  CommonInnerEvent,
  DateRange,
  DateUtil,
  Log,
  MILLS_PER_DAY,
  ReportUtil,
  MILLS_THIRTY_DAYS,
  ThrottleFunction,
  EventService,
  AgendaListDataSource,
  GlobalData,
  GlobalDataKeys,
  CalendarDate,
  GlobalThis,
  maskString
} from '@app/common';
import { AgendaListDataModel, cloneRange, ILLEGAL_CALENDAR_ID } from '../model/AgendaListDataModel';
import { emitter } from '@kit.BasicServicesKit';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { AgendaListItemViewModel } from '@app/common/src/main/ets/agenda/AgendaListDataSource';
import { KeyCode } from '@kit.InputKit';
import { FocusPage } from '../../components/FlexAgendaList';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { AgendaDetailSource } from '../../common/AgendaEnum';
import { common } from '@kit.AbilityKit';
import { reInitGlobalContextInTaskPool, runTaskAsync } from '@app/common/src/main/ets/util/TaskPool';
import { AgendaListBaseModel } from './AgendaListBaseModel';

// 点击文字按钮扩展查询年数
const EXTEND_YEAR: number = 3;

const TAG = 'AgendaListViewModel';
const dummyAgenda: AgendaEventInfo = new AgendaEventInfo();

@Observed
export class AgendaListViewModel extends AgendaListBaseModel {
  // 日历账户uuid
  private calendarUuid: string = '';
  // 全局统一展示时间戳
  private displayMills: number = -1;
  // 全局语言
  private language: string = '';
  // 日程时间范围
  private range: DateRange.Range = { start: Date.now(), end: Date.now() };
  // 滑动分页查询最大时间范围
  private maxRange: DateRange.Range = { start: Date.now(), end: Date.now() };
  // 日程数据模型
  private dataModel: AgendaListDataModel = new AgendaListDataModel(this.range, this.maxRange, this.calendarUuid);
  // 距离displayDate最近的日程索引列表
  private displayEventsIndexArr: number[] = [];
  // 距离今天最近的日程索引列表
  private todayEventsIndexArr: number[] = [];
  // 是否是删除操作，如果是，则执行列表软删除而不执行全量刷新
  private isDeleteOperate: boolean = false;
  // 是否在列表页新建了日程
  private isInsertAgenda: boolean = false;
  // 当前视图中的所有日程，存在节假日
  @Track public agendaResult: AgendaListItemViewModel[] = [];
  // 已经删除的日程
  @Track public deletedAgendaIds: Set<number> = new Set();
  // 系统时间当天的儒略日
  @Track public currentJulianDay: number = DateUtil.getJulianDay();
  // 列表初始索引
  @Track scrollIndex: number = -1;
  // 选中日程
  @Track selectedAgenda: AgendaEventInfo | undefined = undefined;
  // 顶部文字按钮显示文字
  @Track public headViewText: ResourceStr = '';
  // 底部文字按钮显示文字
  @Track public tailViewText: ResourceStr = '';
  // 是否显示回到今天按钮
  @Track isShowBackToday: boolean = false;
  // 顶部按钮loading
  @Track headLoading: boolean = false;
  // 底部按钮loading
  @Track tailLoading: boolean = false;
  // 页面展示元素是否准备完全
  @Track isDataReady: boolean = false;
  // 首尾字体大小
  @Track public viewTextSize: number = 16;
  // 右键删除选中的日程id
  @Track rightClickId: number = 0;
  // 右键删除的日程开始时间
  @Track rightClickStartMills: number = 0;
  // 正在上滑加载更多
  @Track isUpSlideQuerying: boolean = false;
  // 多选场景
  @Track public supportMultiSelect: boolean = false;
  @Track public shareableEventIds: number[] = []; // 可以分享的 event
  @Track public allAgendaCount: number = 0;
  @Track public selectAllButtonAvailable: boolean = false; // 全选按钮是否置灰
  private allEventsIds: number[] = []; // 查询的全部日程,不包含节假日
  private paramsEventId: number = 0;
  private paramsDisplaysMills: number = 0;
  private selectAll: boolean = false;
  private allEventLoaded: boolean = false; // 是否已经加载过所有 event 了

  constructor(
    displayMills: number,
    calendarUuid: string,
    language: string,
    mScroller: Scroller,
    paramsEventId: number,
    paramsDisplaysMills: number,
    vmShowDataChange: (showEventId: number, currentDisplayStartMills: number,
                       currentDisplayEndMills: number, selectedAgendaCount: number,
                       shareableEventCount: number,
                       event: AgendaEventInfo | undefined) => void
  ) {
    super();
    this.displayMills = displayMills;
    this.calendarUuid = calendarUuid;
    this.language = language;
    this.mScroller = mScroller;
    this.paramsEventId = paramsEventId;
    this.paramsDisplaysMills = paramsDisplaysMills;
    this.vmShowDataChange = vmShowDataChange;
  }

  /**
   * 初始化
   */
  public init() {
    this.parseRange(this.displayMills);
    this.dataModel = new AgendaListDataModel(this.range, this.maxRange, this.calendarUuid);
    this.initAgenda();
  }

  /**
   * 下拉加载更多日程
   */
  public async handlePullDown(): Promise<boolean> {
    if (this.range.start === this.maxRange.start) {
      return false;
    }
    const queryRange =
      { start: this.range.start - MILLS_THIRTY_DAYS, end: this.range.start } as DateRange.Range;
    queryRange.start = Math.max(this.maxRange.start, queryRange.start);
    const queryResult = await this.dataModel.queryPastAgenda(queryRange, this.supportMultiSelect);
    this.agendaResult = this.dataModel.getAgendaResult();
    if (this.selectAll) { // 触发全选后，新刷新的数据要被选中
      this.agendaResult.forEach(e => e.isSelected = true);
    }
    this.notifyDataReload(this.agendaResult);
    this.updateIndexArr();
    this.range.start = this.dataModel.getRange().start;
    this.range.end = this.dataModel.getRange().end;

    // 处理列表索引
    this.scrollIndex = queryResult.agendaList.length + 1;
    this.mScroller.scrollToIndex(this.scrollIndex);

    this.updateViewText();
    return true;
  }

  /**
   * 上滑加载更多日程
   */
  public async handleUpSlide(): Promise<boolean> {
    if (this.range.end === this.maxRange.end) {
      return false;
    }
    this.isUpSlideQuerying = true;
    const queryRange =
      { start: this.range.end + MILLS_PER_DAY, end: this.range.end + MILLS_THIRTY_DAYS } as DateRange.Range;
    queryRange.end = Math.min(this.maxRange.end, queryRange.end);
    return this.dataModel.queryFutureAgenda(queryRange, this.supportMultiSelect).then(() => {
      this.agendaResult = this.dataModel.getAgendaResult();
      if (this.selectAll) { // 触发全选后，新刷新的数据要被选中
        Log.info(TAG, `handleUpSlide selectAll`);
        this.agendaResult.forEach(e => e.isSelected = true);
      }
      this.notifyDataReload(this.agendaResult);
      this.range.start = this.dataModel.getRange().start;
      this.range.end = this.dataModel.getRange().end;
      this.updateViewText();
      this.isUpSlideQuerying = false;
      return true;
    })
  }

  /**
   * 判断是否显示"回到今天"按钮
   * @param startIndex：容器顶部的ListItem索引值
   * @param endIndex：容器底部的ListItem索引值
   */
  public changeBackTodayStatus(startIndex: number, endIndex: number) {
    if (this.agendaResult.length === 0) {
      this.isShowBackToday = false;
      return;
    } else {
      const indexArr: number[] = this.todayEventsIndexArr;
      const first: number = indexArr[0] + 1;
      const last: number = indexArr[indexArr.length - 1] + 1;
      if (!this.isTodayInRange()) {
        this.isShowBackToday = true;
      } else {
        this.isShowBackToday = (first > endIndex) || (last < startIndex); // 数值区间不相交，显示回到今天按钮
      }
    }
  }

  /**
   * 改变全局选择日期
   * @param startIndex：容器顶部的ListItem索引值
   */
  public changeDisplayDate(startIndex: number) {
    const topAgendaIndex = startIndex - 1;
    // 数组元素索引下标越界直接返回
    if (this.agendaResult.length === 0 || topAgendaIndex < 0 || topAgendaIndex >= this.agendaResult.length) {
      return;
    }
    Log.info(TAG, `changeDisplayDate topAgenda's titleHead = ${this.agendaResult[topAgendaIndex].mTitle[0]}`);
    const newDisplayDate = this.agendaResult[topAgendaIndex].mBegin;
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDisplayDate);
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
  }

  /**
   * 点击日程卡改变选中态
   * @param item
   */
  public onItemClick(item: AgendaEventInfo | undefined): boolean {
    if (!item) {
      return false;
    }
    this.selectedAgenda = item;
    this.vmShowDataChange(this.selectedAgenda.mId, this.selectedAgenda.mBegin, this.selectedAgenda.mEnd,
      this.shareableEventIds.length, 0,
      this.selectedAgenda);
    this.onActionFocusChange(FocusPage.AGENDA_DETAIL);
    return true;
  }

  /**
   * 顶部文字按钮点击事件
   */
  public onHeadTextClick() {
    if (!this.headLoading) {
      this.headLoading = true;
      const maxRangeStartDate = new CalendarDate(this.maxRange.start);
      maxRangeStartDate.setFullYear(maxRangeStartDate.getFullYear() - EXTEND_YEAR);
      this.maxRange.start = maxRangeStartDate.getTime();
      this.dataModel.setMaxRange(this.maxRange);
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaViewCheckBeforeAgent);
      this.handlePullDown();
      setTimeout(() => {
        this.headLoading = false;
      }, 1000);
    }
  }

  /**
   * 底部文字按钮点击事件
   */
  public onTailTextClick() {
    if (!this.tailLoading) {
      this.tailLoading = true;
      const maxRangeEndDate = new CalendarDate(this.maxRange.end);
      maxRangeEndDate.setFullYear(maxRangeEndDate.getFullYear() + EXTEND_YEAR);
      this.maxRange.end = maxRangeEndDate.getTime();
      this.dataModel.setMaxRange(this.maxRange);
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaViewCheckAfterAgent);
      this.handleUpSlide();
      setTimeout(() => {
        this.tailLoading = false;
      }, 1000);
    }
  }

  /**
   * "回到今天"按钮点击事件
   */
  public async onBackTodayClick() {
    if (!this.isTodayInRange()) {
      // 清除选中
      this.selectedAgenda = undefined;
      // 根据当前时间重新计算查询范围
      this.parseRange(Date.now());
      this.dataModel = new AgendaListDataModel(this.range, this.maxRange, this.calendarUuid);
      // 重查数据
      await this.dataModel.init();
      cloneRange(this.range, this.dataModel.getRange());
      this.initDataSource();
      // 更新距离今天和距离选中日期最近的日程索引
      this.updateIndexArr();
      // 更新上下按钮显示文字
      this.updateViewText();
    }
    if (this.todayEventsIndexArr.length === 0) {
      Log.warn(TAG, 'todayEventsIndexArr is empty');
      return;
    }
    if (this.agendaResult.length - 1 < this.todayEventsIndexArr[0]) {
      Log.warn(TAG, 'agendaResult length is short');
      return;
    }
    // 改变索引
    Log.info(TAG, `todayEventsIndexArr[0]'s titleHead = ${this.agendaResult[this.todayEventsIndexArr[0]].mTitle[0]}`);
    this.scrollIndex = this.todayEventsIndexArr[0] + 1;
    this.mScroller.scrollToIndex(this.scrollIndex);
    // 改变选中日程
    this.selectedAgenda = this.agendaResult[this.todayEventsIndexArr[0]];
    this.vmShowDataChange(this.selectedAgenda?.mId, this.selectedAgenda?.mBegin, this.selectedAgenda?.mEnd, 0, 0,
      this.selectedAgenda);
    this.isShowBackToday = false;
  }

  /**
   * 取消事件监听
   */
  public unsubscribeEvents(): void {
    emitter.off(CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL, this.eventDeleteChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_TIME_CHANGED, this.timeChangeHandler);
    emitter.off(CommonInnerEvent.EVENT_UPDATE_AGENDA_LIST, this.eventInfoChangeHandler);
    emitter.off(CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER, this.closeCoverHandler);
    emitter.off(CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE, this.fullUpdateViewHandler);
    emitter.off(CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED, this.selectedChangedHandler);
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.dataChangeHandler);
  }

  /**
   * 当前时间改变
   */
  public onCurrentDateChange(currentDate: number) {
    this.currentJulianDay = DateUtil.getJulianDay(currentDate);
  }

  /**
   * 语言改变
   */
  public onLanguageChange(language: string) {
    this.language = language;
    this.updateViewText();
  }

  /**
   * PC支持右键删除
   */
  public rightClickToDeleteConfirm(): boolean {
    try {
      this.handleSoftDelete(this.rightClickId, this.rightClickStartMills);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'handleSoftDelete in rightClickToDeleteConfirm', err);
      return false;
    }
  }

  /**
   * 多选删除
   */
  public async deleteMultiEventsConfirm(): Promise<void> {
    let toRemove: Set<number> = new Set();
    if (this.selectAll) {
      // 除了当前页面没选中的日程之外，数据库中的event都要删除
      toRemove = new Set(this.allEventsIds);
      this.agendaResult.filter(e => !e.isSelected).forEach(e => {
        toRemove.delete(e.mId);
      })
    } else {
      // 只删除当前选中的
      toRemove = new Set(this.agendaResult.filter(e => e.isSelected).map(e => e.mId));
    }
    if (toRemove.size < 0) {
      return;
    }
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `deleteMultiEventsConfirm get invalid context`);
      return;
    }
    await runTaskAsync(deleteEvents, context, toRemove);
    toRemove.forEach(event => this.deletedAgendaIds.add(event));
    this.agendaResult = this.agendaResult.filter(agenda => !this.deletedAgendaIds.has(agenda.mId));
  }

  /**
   * 初始化日程列表：数据源、顶/底部文字按钮、最近日程索引列表、选中态
   */
  private async initAgenda() {
    await this.dataModel.init();
    cloneRange(this.range, this.dataModel.getRange());
    this.initDataSource();
    this.updateViewText();
    this.updateIndexArr();
    this.initSelectedAgenda();
    this.isDataReady = true;
  }

  /**
   * 重新加载日程列表，用于显示和隐藏节假日
   */
  public async reInitAgenda(isShowHoliday: boolean) {
    this.dataModel.setIsShowHoliday(isShowHoliday);
    await this.dataModel.init();
    cloneRange(this.range, this.dataModel.getRange());
    this.initDataSource();
    this.updateViewText();
    this.updateIndexArr();
    this.isDataReady = true;
  }

  /**
   * 全量更新日程列表：数据源、顶/底部文字按钮、最近日程索引列表、滚动列表到指定索引
   */
  private async updateAgenda() {
    await this.dataModel.init(false, this.range);
    cloneRange(this.range, this.dataModel.getRange());
    this.initDataSource();
    this.updateIndexArr();
    this.updateScrollIndex();
    this.mScroller.scrollToIndex(this.scrollIndex);
    if (this.scrollIndex <= 0) {
      this.selectedAgenda = undefined;
      this.initSelectedAgenda();
    }
  }

  /**
   * 全量重载数据源
   */
  private initDataSource() {
    this.agendaResult = this.dataModel.getAgendaResult();
    this.notifyDataReload(this.agendaResult);
  }

  /**
   * 监听系统时间改变
   */
  private onTimeChange(): void {
    Log.info(TAG, 'On Time change');
    this.init();
    this.getTodayDateAgenda(this.agendaResult);
  }

  /**
   * 根据传入时间戳解析range
   * @param displayMills
   */
  private parseRange(displayMills: number) {
    const todayOfDisplayMills: CalendarDate = new CalendarDate(displayMills);
    const maxRangeStart: CalendarDate = new CalendarDate(todayOfDisplayMills.getFullYear() - 1,
      todayOfDisplayMills.getMonth(), todayOfDisplayMills.getDate());
    const maxRangeEnd: CalendarDate = new CalendarDate(todayOfDisplayMills.getFullYear() + 2,
      todayOfDisplayMills.getMonth(), todayOfDisplayMills.getDate());
    this.maxRange = { start: maxRangeStart.getTime(), end: maxRangeEnd.getTime() };
    this.range = { start: displayMills - 15 * MILLS_PER_DAY, end: displayMills + 15 * MILLS_PER_DAY };
  }

  // 通知懒加载重新加载所有数据
  public notifyDataReload(agendaList: AgendaListItemViewModel[]) {
    this.dataSources.setData(agendaList.filter(e =>!this.deletedAgendaIds.has(e.mId))); // 过滤已经删除的
    this.dataSources.notifyDataReload();

    this.selectAllButtonAvailable = this.agendaResult.filter(e => e.isHoliday()).length !== this.agendaResult.length
  }

  /**
   * 更新列表滚动索引
   */
  private updateScrollIndex() {
    if (this.agendaResult.length === 0) {
      return;
    }
    this.scrollIndex = this.getSelectedIndex() + 1;
  }

  /**
   * 更新最近日程索引列表
   */
  private updateIndexArr() {
    this.getDisplayDateAgenda(this.agendaResult);
    this.getTodayDateAgenda(this.agendaResult);
  }

  /**
   * 今日是否在日程扩展范围内
   */
  private isTodayInRange(): boolean {
    let rangeBeginJulianDay: number = DateUtil.getJulianDay(this.range.start);
    let rangeEndJulianDay: number = DateUtil.getJulianDay(this.range.end);
    return (this.currentJulianDay >= rangeBeginJulianDay) && (this.currentJulianDay <= rangeEndJulianDay);
  }

  /**
   * 处理默认选中日程
   */
  private initSelectedAgenda() {
    if ((this.displayEventsIndexArr.length > 0 && !this.selectedAgenda) || this.isInsertAgenda) {
      if (this.paramsEventId > 0 && this.paramsDisplaysMills > 0) {
        this.selectedAgenda = this.agendaResult.find(
          item => item.mId === this.paramsEventId && item.mBegin === this.paramsDisplaysMills);
      } else if (this.paramsEventId > 0) {
        // 兼容全搜跳转进来want只携带了日程id的场景
        this.selectedAgenda = this.agendaResult.find(item => item.mId === this.paramsEventId);
      } else {
        this.selectedAgenda = this.agendaResult[this.displayEventsIndexArr[0]];
      }
      this.isInsertAgenda = false;
    }
    if (this.selectedAgenda) {
      this.vmShowDataChange(this.selectedAgenda?.mId || -1, this.selectedAgenda.mBegin, this.selectedAgenda.mEnd, 0, 0,
        this.selectedAgenda);
    } else {
      let nextIdx = this.getNearAgendaOfArray(this.agendaResult, this.currentJulianDay)[0];
      if (nextIdx >= 0) {
        this.selectedAgenda = this.agendaResult[nextIdx];
      }
      this.vmShowDataChange(this.selectedAgenda?.mId || -1, 0, 0, 0, 0, this.selectedAgenda);
    }
    this.updateScrollIndex();
    this.mScroller.scrollToIndex(this.scrollIndex);
  }

  /**
   * 获取默认选中日程在当前列表中的索引
   */
  private getSelectedIndex(): number {
    if (this.selectedAgenda) {
      return this.dataModel.findIndexFromCache(this.selectedAgenda);
    } else {
      return -1;
    }
  }

  /**
   * 获取时间戳对应的日期展示文本
   * @param date
   * @returns
   */
  private getRangeText(mills: number): string {
    const date = new CalendarDate(mills);
    return DateUtil.intlDateFormatChineseStyle(date, { year: 'numeric', month: 'long', day: 'numeric' })
  }

  /**
   * 获取顶部按钮显示文字
   * @param mills
   * @returns
   */
  private getHeadViewText(mills: number): ResourceStr {
    return $r('app.string.load_previous_more_event', this.getRangeText(mills));
  }

  /**
   * 获取底部按钮显示文字
   * @param mills
   * @returns
   */
  private getTailViewText(mills: number): ResourceStr {
    return $r('app.string.load_next_more_event', this.getRangeText(mills));
  }

  /**
   * 获取距离 julianDay 最近的日程数组
   *
   * @param agendaList 日程数组
   * @param julianDay 儒略日
   */
  private getNearAgendaOfArray(agendaList: AgendaEventInfo[], julianDay: number): number[] {
    if (agendaList.length === 0) {
      return [];
    }
    let hasAgenda: boolean = false;
    let targetIndex: number = agendaList.length - 1;
    const indexArr: number[] = []; // julianDay 日程的索引值列表
    for (let i = 0; i < agendaList.length; i++) {
      if (agendaList[i]?.mDay === julianDay) {
        hasAgenda = true;
        indexArr.push(i);
      } else if (agendaList[i]?.mDay > julianDay) {
        if (!hasAgenda) {
          targetIndex = i;
        }
        break;
      }
    }
    if (hasAgenda) {
      return indexArr;
    } else {
      return [targetIndex];
    }
  }

  /**
   * 获取距离 displayDate 最近的日程
   *
   * @param agendaList 日程数组
   */
  private getDisplayDateAgenda(agendaList: AgendaEventInfo[]) {
    const displayJulianDay = DateUtil.getJulianDay(this.displayMills);
    this.displayEventsIndexArr = this.getNearAgendaOfArray(agendaList, displayJulianDay);
    Log.info(TAG, `getDisplayDateAgenda displayEventsIndexArr = ${this.displayEventsIndexArr}`);
  }

  /**
   * 获取距离今天最近的日程
   *
   * @param agendaList 日程数组
   */
  private getTodayDateAgenda(agendaList: AgendaEventInfo[]) {
    this.todayEventsIndexArr = this.getNearAgendaOfArray(agendaList, this.currentJulianDay);
    Log.info(TAG, `getTodayDateAgenda todayEventsIndexArr = ${this.todayEventsIndexArr}`);
  }

  /**
   * 更新按钮显示文本
   */
  private updateViewText() {
    if (this.range.start === this.maxRange.start) {
      this.headViewText = this.getHeadViewText(this.maxRange.start)
    } else {
      this.headViewText = '';
    }

    if (this.range.end === this.maxRange.end) {
      this.tailViewText = this.getTailViewText(this.maxRange.end);
    } else {
      this.tailViewText = '';
    }
  }

  /**
   * 事件监听
   */
  public subscribeEvents(): void {
    emitter.on({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_LIST }, this.eventInfoChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL }, this.eventDeleteChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.timeChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, this.selectedChangedHandler);
    emitter.on({
      eventId: CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER
    }, this.closeCoverHandler);
    // 全量刷新日程列表视图
    emitter.on({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE }, this.fullUpdateViewHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
  }

  private fullUpdateView(data: emitter.EventData, isDeleted: boolean): void {
    try {
      // 单量刷新
      if (data?.data?.eventId) {
        const eventId = Number(data?.data?.eventId);
        const instanceStartMills = Number(data?.data?.instanceStartMills);
        this.paramsEventId = eventId;
        this.paramsDisplaysMills = instanceStartMills;
        this.displayMills = instanceStartMills;
        this.isInsertAgenda = true;
        this.init();
      } else {
        // 清空当前选中的日程和目标日程的时间，在initAgenda里重置距离当前时间最近的时间
        if (isDeleted) {
          this.selectedAgenda = undefined;
          this.paramsDisplaysMills = new Date().getTime();
        }
        // 没有 eventId 时，只刷新日程
        this.initAgenda();
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'fullUpdateView', error);
    }
  }

  private onSelectedInfoChange(data: emitter.EventData): void {
    if (this.isInsertAgenda) {
      return;
    }
    ThrottleFunction.instance().debounceInstant(TAG + `onSelectedInfoChange`, (): void => {
      const newEventInfo = JSON.parse(data?.data?.newEventInfo) as AgendaEventInfo;
      const forceUpdate = data?.data?.forceUpdate as boolean;
      const shouldUpdateListFlag = this.shouldUpdateList(this.selectedAgenda, newEventInfo);
      if (this.isDeleteOperate) {
        this.isDeleteOperate = false;
        return;
      }
      this.selectedAgenda = new AgendaEventInfo(newEventInfo);
      if (!shouldUpdateListFlag && !forceUpdate) {
        return;
      }
      if (this.selectedAgenda) {
        this.parseRange(this.selectedAgenda.mBegin)
        this.dataModel.setMaxRange(this.maxRange);
        this.updateAgenda().then(() => {
          let eventData: emitter.EventData = {
            data: {
              'eventId': this.selectedAgenda?.mId,
              'displayStartMills': this.selectedAgenda?.mBegin,
              'displayEndMills': this.selectedAgenda?.mEnd,
              'sourceType': AgendaDetailSource.AGENDA_LIST,
            }
          };
          emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
        })
      }
    }, 200)
  }

  private shouldUpdateList(oldSelectedInfo: AgendaEventInfo | undefined, newInfo: AgendaEventInfo): boolean {
    if (!oldSelectedInfo) {
      return true;
    }
    if (oldSelectedInfo.mTitle !== newInfo.mTitle) {
      return true;
    }
    if (oldSelectedInfo.mLocation !== newInfo.mLocation) {
      return true;
    }
    if (oldSelectedInfo.mBegin !== newInfo.mBegin) {
      return true;
    }
    if (oldSelectedInfo.mEnd !== newInfo.mEnd) {
      return true;
    }
    if (oldSelectedInfo.mRepeatRule !== newInfo.mRepeatRule) {
      return true;
    }
    return false
  }

  private handleSoftDelete(eventId: number, displayStartMills: number): boolean {
    const mockInfo = new AgendaEventInfo();
    mockInfo.mId = eventId;
    mockInfo.mBegin = displayStartMills;
    const deletedAgendaIndex = this.dataModel.findIndexFromCache(mockInfo);
    if (deletedAgendaIndex < 0) {
      Log.error(TAG, 'wrong soft delete event id')
      return false;
    }
    this.agendaResult = this.dataModel.getAgendaResult();
    if (this.agendaResult[deletedAgendaIndex].mIsSetDayHead &&
      this.agendaResult.length > deletedAgendaIndex + 1) {
      this.agendaResult[deletedAgendaIndex + 1].mIsSetDayHead = true;
    }
    this.agendaResult.splice(deletedAgendaIndex, 1);
    this.notifyDataReload(this.agendaResult);
    if (this.agendaResult.length === 0) {
      this.vmShowDataChange(-1, 0, 0, 0, 0, this.selectedAgenda);
      return true;
    }
    // 处理选中
    if (this.agendaResult[deletedAgendaIndex]) {
      this.selectedAgenda = this.agendaResult[deletedAgendaIndex];
      this.scrollIndex = deletedAgendaIndex + 1;
    } else if (deletedAgendaIndex > 0) {
      this.selectedAgenda = this.agendaResult[deletedAgendaIndex - 1];
      this.scrollIndex = deletedAgendaIndex - 1;
    } else {
      this.selectedAgenda = this.agendaResult[this.displayEventsIndexArr[0]];
      this.scrollIndex = this.displayEventsIndexArr[0] + 1;
    }
    let eventData: emitter.EventData = {
      data: {
        'eventId': this.selectedAgenda.mId,
        'displayStartMills': this.selectedAgenda.mBegin,
        'displayEndMills': this.selectedAgenda.mEnd,
        'sourceType': AgendaDetailSource.AGENDA_LIST,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
    this.mScroller.scrollToIndex(this.scrollIndex);
    return true;
  }

  private onDeleteEventByID(data: emitter.EventData): boolean {
    this.isDeleteOperate = true;
    const eventId: number | undefined = data?.data?.eventId;
    const displayStartMills: number = data?.data?.displayStartMills;
    if (eventId === null || eventId === undefined) {
      Log.error(TAG, 'onDeleteEventByID no event id')
      return false;
    }
    try {
      this.handleSoftDelete(eventId, displayStartMills);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'handleSoftDelete in onDeleteEventByID', err);
      return false;
    }
  }

  getShareableEvents(events: AgendaEventInfo[]) {
    Log.info(TAG, `getShareableEvents start`);
    let start = new Date().getTime();
    this.shareableEventIds = AgendaOperateHelper.getShareableEvents(events);
    Log.info(TAG, `getShareableEvents cost ${new Date().getTime() - start} ms, count:${this.shareableEventIds.length}`);
  }

  // 查询所有的 event
  async queryAllAgendas() {
    Log.info(TAG, `showSelectAllNum`);
    let start = new Date().getTime();
    if (this.allEventLoaded) {
      // 为了查询全部日程的数量，如果已经获取过了，就不再重复查询了
      return;
    }
    let eventsIds = await EventService.INSTANCE.queryNormalEvents(this.calendarUuid);
    this.allEventsIds = eventsIds;
    this.allAgendaCount = eventsIds.length;
    this.allEventLoaded = true;
    Log.info(TAG, `queried all events: ${eventsIds.length} cost ${new Date().getTime() - start} ms`);
  }

  // 多选时，选中的日程变化
  private onSelectedItemsChanged(data: emitter.EventData): void {
    ThrottleFunction.instance().debounce('onSelectedItemsChanged', async () => {
      let selectAll: boolean = data.data?.selectAll;
      if (selectAll != undefined) { // selectAll 有值的时候 true 是全选， false 是反选
        Log.info(TAG, `selectAll:${selectAll}`);
        this.selectAll = selectAll;
        if (selectAll) {
          this.agendaResult.forEach((agenda) => {
            if (agenda.isHoliday() || agenda.isContactBirthday()) {
              agenda.isSelected = false;
              return;
            }
            agenda.isSelected = true;
          });
          let selected = this.agendaResult.filter((agenda) => agenda.isSelected);
          this.getShareableEvents(selected); // 等待获取可分享的日程数量
          await this.queryAllAgendas(); // 显示全部日程的个数，并通知数据修改到view
          this.vmShowDataChange(this.selectedAgenda?.mId || 0, 0, 0, this.shareableEventIds.length,
            this.allEventsIds.length, this.selectedAgenda);
        } else {
          this.agendaResult.forEach((agenda) => agenda.isSelected = false);
          this.shareableEventIds = [];
          this.vmShowDataChange(this.selectedAgenda?.mId || 0, 0, 0, 0, 0, this.selectedAgenda);
        }
      } else {
        let selected = this.agendaResult.filter((agenda) => agenda.isSelected);
        this.getShareableEvents(selected);
        let unselected = this.agendaResult.filter((agenda) => !agenda.isHoliday() && !agenda.isSelected);
        const selectedAgendaCount = this.selectAll ? this.allEventsIds.length - unselected.length : selected.length;
        this.vmShowDataChange(this.selectedAgenda?.mId || 0, 0, 0,
          this.shareableEventIds.length, selectedAgendaCount, this.selectedAgenda);
      }
      this.notifyDataReload(this.agendaResult);
    }, 1)
  }

  /**
   * 启用多选功能
   * @param selectedInfo - 选中的日程信息（可选）
   * @returns Promise<void>
   */
  public async enableMultiSelect(selectedInfo?: AgendaEventInfo) {
    Log.info(TAG, `enableMultiSelect, selectedInfo is ${maskString(selectedInfo?.mTitle)}`);
    // 初始化多选状态
    this.allEventLoaded = false;
    this.supportMultiSelect = true;
    this.selectAll = false;
    // 获取之前选中的日程（如果存在）
    const previouslySelectedEvent = this.agendaResult.find(event => event.isSelected);
    // 初始化数据模型并获取最新的日程结果
    await this.dataModel.init(false, this.range, true);
    this.agendaResult = this.dataModel.getAgendaResult();
    // 查找需要保持选中的日程索引
    const targetMId = selectedInfo?.mId ?? previouslySelectedEvent?.mId;
    const selectedIndex = targetMId !== null && targetMId !== undefined
      ? this.agendaResult.findIndex(event => event.mId === targetMId)
      : -1;
    // 如果找到匹配的日程，设置其为选中状态
    if (selectedIndex >= 0) {
      this.agendaResult[selectedIndex].isSelected = true;
      this.onSelectedItemsChanged({});
    }
    // 通知数据已重新加载
    this.notifyDataReload(this.agendaResult);
    // 如果没有提供selectedInfo参数，则重置选中的日程
    if (!selectedInfo) {
      this.selectedAgenda = undefined;
      this.initSelectedAgenda();
    }
  }

  public async disableMultiSelect() {
    this.supportMultiSelect = false;
    this.shareableEventIds = [];
    this.scrollIndex = -1; // 重新设置选中项
    await this.updateAgenda(); // 恢复正常显示
    this.notifyDataReload(this.agendaResult);
    this.vmShowDataChange(this.selectedAgenda?.mId || -1, 0, 0, 0, 0, this.selectedAgenda);
  }

  // vm改变状态变量需要同步回view
  private vmShowDataChange:
    (showEventId: number, currentDisplayStartMills: number,
     currentDisplayEndMills: number, shareableEventCount: number, selectedAgendaCount: number,
     event: AgendaEventInfo | undefined) => void = (showEventId: number, currentDisplayStartMills:
    number, currentDisplayEndMills: number, shareableEventCount: number, selectedAgendaCount: number,
                                                    event: AgendaEventInfo | undefined): void => {
  };
  private timeChangeHandler: () => void = (): void => {
    this.onTimeChange();
  };
  private eventDeleteChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.onDeleteEventByID(data);
  };
  private eventInfoChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.onSelectedInfoChange(data);
  };
  private selectedChangedHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.onSelectedItemsChanged(data);
  };
  // 日程详情全模态关闭
  private closeCoverHandler: () => void = (): void => {
    this.onActionFocusChange(FocusPage.AGENDA_LIST_VIEW);
  };
  // 手动处理用户点击动作对折叠屏的开合做适配，弱化变量传递，使用方式实现视图值传递，保证该视图的相对独立性
  // 此处非必选参数，不用放到构造函数里赋值
  public onActionFocusChange: (actionFocus: string) => void = (): void => {
  };
  private fullUpdateViewHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.fullUpdateView(data, true);
  };
  private dataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    if (data?.data?.isEmitFromEntryPage) {
      Log.warn(TAG, 'This Call is From Entry Page, No Need To Respond');
      return;
    }
    if (this.supportMultiSelect) {
      Log.warn(TAG, 'The current page is in multi-selection mode, No Need To Respond');
      return;
    }
    ThrottleFunction.instance().debounceInstant(TAG + `dataChangeHandler`, (data: emitter.EventData): void => {
      this.fullUpdateView(data, false)
    }, 2000)
  };

  /**
   * 键盘上下键改变选中态
   * @param keyCode
   */
  public onKeyPress(keyCode: number): boolean {
    let index = 0;
    if (this.selectedAgenda !== null && this.selectedAgenda !== undefined) {
      index = this.agendaResult.findIndex((item) => item.mId === this.selectedAgenda?.mId &&
        item.mDay === this.selectedAgenda?.mDay);
    }
    if (index === -1) {
      return false;
    }

    if (keyCode === KeyCode.KEYCODE_DPAD_UP && index > 0) { //上键
      this.mScroller.scrollToIndex(index, true, ScrollAlign.CENTER);
      let checkedItem = this.dataSources.getData(index - 1) ?? undefined;
      if (checkedItem !== null && checkedItem !== undefined) {
        this.onItemClick(checkedItem);
      }
    } else if (keyCode === KeyCode.KEYCODE_DPAD_DOWN && index < this.dataSources.totalCount() - 1) { //下键
      this.mScroller.scrollToIndex(index, true, ScrollAlign.START);
      let checkedItem = this.dataSources.getData(index + 1) ?? undefined;
      if (checkedItem !== null && checkedItem !== undefined) {
        this.onItemClick(checkedItem);
      }
    }
    return true;
  }
}

@Concurrent
async function deleteEvents(context: common.UIAbilityContext, toRemove: Set<number>): Promise<void> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const TAG = 'deleteEvents';
  let start = new Date().getTime();
  await EventService.INSTANCE.deleteEvents(toRemove).then((rowsDeleted) => {
    Log.info(TAG, `deleteMultiEvents ${rowsDeleted} deleted cost ${new Date().getTime() - start} ms`);
  })
}
