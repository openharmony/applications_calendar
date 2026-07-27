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
  AgendaListDataSource,
  AgendaListItemViewModel,
  CalendarDate,
  CommonInnerEvent,
  DateUtil,
  DeviceConfig,
  EventService,
  Log,
  ReportUtil,
  statisticEvents,
  QueryInfo,
  InstanceService,
  MILLS_THIRTY_DAYS,
  MILLS_PER_DAY,
  DateRange,
  SafeUtil,
  MILLS_ONE_YEAR,
  EmitterCollector,
  EmptyUtils
} from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { AGENDA_SEARCH_DATE_BEGIN, AGENDA_SEARCH_DATE_END } from '@app/common/src/main/ets/agenda/Constants';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { FocusPage } from '../../components/FlexAgendaList';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { KeyCode } from '@kit.InputKit';
import { AgendaListBaseModel } from '../../AgendaList/viewmodel/AgendaListBaseModel';

const TAG: string = 'SearchAgendaViewModel';

// 自动扩展查询时间边界获取到的最大数据
const MAX_AUTO_QUERY_LENGTH = 30;
// 自动扩展查询边界最大次数，用于规避日程稀疏而多次查询的场景
const MAX_AUTO_QUERY_TIMES = 3;
// 点击文字按钮扩展查询年数
const EXTEND_YEAR: number = 3;

const QUERY_PAGE_SIZE: number = 100;

@Observed
export default class SearchAgendaViewModel extends AgendaListBaseModel {
  // 选中日程id
  @Track public clickId: number = 0;
  // 全搜接口返回结果集
  @Track public datas: AgendaListItemViewModel[] = [];
  // 系统时间当天的儒略日
  @Track public currentJulianDay: number = DateUtil.getJulianDay();
  // 下拉loading
  @Track public headLoading: boolean = false;
  // 顶部文字按钮显示文字
  @Track public headViewText: ResourceStr = '';
  // 上拉loading
  @Track public tailLoading: boolean = false;
  // 底部文字按钮显示文字
  @Track public tailViewText: ResourceStr = '';
  // 首尾字体大小
  @Track public viewTextSize: number = 16;
  @Track public isDataReady: boolean = false;
  @Track public checkEventId: number = -1;
  @Track public currentDate: number = DateUtil.getStartOfDayTimeStamp();
  @Track public showResult: boolean = false;
  @Track public antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;
  //svg模糊度
  @Track public displayEventsIndexArr: number[] = [];
  // 选中日程唯一标识
  @Track public checkedIdentity: string = '';
  // 分栏场景右侧日程详情id
  @Track public showEventId: number = -1;
  @Track public currentDisplayStartMills: number = 0;
  @Track public currentDisplayEndMills: number = 0;
  // 是否显示回到今天按钮
  @Track public isShowBackToday: boolean = false;
  // 删除日程数量
  @Track public selectedAgendaCount: number = 0;
  // 全选按钮是否置灰
  @Track public selectAllButtonAvailable: boolean = false;
  // 默认搜索日程开始范围：1900-1-1
  private readonly defaultRangeBegin: CalendarDate = new CalendarDate(AGENDA_SEARCH_DATE_BEGIN);
  // 默认搜索日程结束范围：2100-12-31
  private readonly defaultRangeEnd: CalendarDate = new CalendarDate(AGENDA_SEARCH_DATE_END);
  // 全局统一的展示日期时间戳
  private displayDate: number = -1;
  // 下拉加载更多当前页数
  private pastCurrentPage: number = 1;
  // 上拉加载更多当前页数
  private futureCurrentPage: number = 1;
  // 查询用账户uuid
  private calendarUuid: string = '';
  // 最近一次返回的过去日程数量
  private pastAgendaNum: number = 0;
  // 最近一次返回的未来日程数量
  private futureAgendaNum: number = 0;
  private changeValue: string = '';
  // 是否存在于弹窗中
  private isInPop: boolean = false;
  // 是否支持多选
  private supportMultiSelect: boolean = false;
  public shareableEventIds: number[] = [];
  // 距离今天最近的日程索引列表
  private todayEventsIndexArr: number[] = [];
  private allEvents: AgendaEventInfo[] = []; // 搜索匹配的全部日程
  private selectAll: boolean = false;
  private allEventLoaded: boolean = false; // 是否已经加载过所有 event 了
  private range: DateRange.Range = { start: Date.now(), end: Date.now() };
  private emitterCollector : EmitterCollector = new EmitterCollector();

  public constructor(
    displayDate: number,
    checkEventId: number,
    currentDate: number,
    changeValue: string,
    showResult: boolean,
    calendarUuid: string,
    onFirstIdChange: (firstEventId: number, isContainCheckId: boolean) => void,
    onDeleteSuccess: () => void,
    showEventId: number,
    currentDisplayStartMills: number,
    currentDisplayEndMills: number,
    vmShowDataChange: (data: showDataParams) => void,
    isInPop: boolean,
    mScroller: Scroller
  ) {
    super();
    this.displayDate = displayDate;
    this.checkEventId = checkEventId;
    this.currentDate = currentDate;
    this.changeValue = changeValue;
    this.showResult = showResult;
    this.calendarUuid = calendarUuid;
    this.onFirstIdChange = onFirstIdChange;
    this.onDeleteSuccess = onDeleteSuccess;
    this.showEventId = showEventId;
    this.currentDisplayStartMills = currentDisplayStartMills;
    this.currentDisplayEndMills = currentDisplayEndMills;
    this.vmShowDataChange = vmShowDataChange;
    this.isInPop = isInPop;
    this.mScroller = mScroller;
  }

  // 列表第一条日程id改变回调
  public onFirstIdChange: (firstEventId: number, isContainCheckId: boolean) => void =
    (firstEventId: number, isContainCheckId: boolean): void => {
    };
  // 删除日程回调函数
  public onDeleteSuccess: () => void = (): void => {
  };
  // 日程详情全模态关闭
  private closeCoverHandler: () => void = (): void => {
  };

  /**
   * 监听系统事件
   * @returns
   */
  subscribeEvents(): boolean {
    this.eventDeleteChangeHandler = (data: emitter.EventData) => this.onDeleteEventByID(data);
    this.selectedChangedHandler = (data: emitter.EventData) => this.onSelectedItemsChanged(data);
    this.timeChangeHandler = () => this.onTimeChange();
    this.closeCoverHandler = () => {
      Log.info(TAG, 'closeCoverHandler In Search Page');
      this.onActionFocusChange(FocusPage.FLEX_SEARCH_AGENDA);
    }
    this.searchListChangeHandler = () => {
      Log.info(TAG, 'the search schedule has been edited');
      this.onFirstSearch();
    };
    try {
      this.emitterCollector.on({
        eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED
      }, this.searchListChangeHandler);
      this.emitterCollector.on({
        eventId: CommonInnerEvent.EVENT_DELETE_AGENDA_DETAIL
      }, this.eventDeleteChangeHandler);
      this.emitterCollector.on({
        eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED
      }, this.timeChangeHandler);
      this.emitterCollector.on({
        eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED
      }, this.selectedChangedHandler);
      this.emitterCollector.on({
        eventId: CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER
      }, this.closeCoverHandler);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'subscribeEvents failed', err);
      return false;
    }
  }

  /**
   * 取消监听系统事件
   * @returns
   */
  unsubscribeEvents(): boolean {
    try {
      this.emitterCollector.off();
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'subscribeEvents failed', err);
      return false;
    }
  }

  async onTimeChange(): Promise<boolean> {
    Log.debug(TAG, 'On Time change');
    return this.onFirstSearch();
  }

  async onDataChange(data: emitter.EventData): Promise<boolean> {
    if (data?.data?.table !== 'Events' && data?.data?.table !== 'Calendars') {
      return false;
    }

    Log.debug(TAG, `On Data change, table = ${data?.data?.table}`);
    return this.onFirstSearch();
  }

  async onChangeValueChange(changeValue: string): Promise<boolean> {
    Log.hilogInfo(TAG, 'On changeValue change = %{private}s', changeValue);
    this.changeValue = changeValue;
    return this.onFirstSearch();
  }

  async onCurrentDateChange(currentDate: number) {
    Log.debug(TAG, `onCurrentDateChange change = ${currentDate}`);
    this.currentJulianDay = DateUtil.getJulianDay(currentDate);
    return this.onFirstSearch();
  }

  private getShareableEvents(events: AgendaEventInfo[]) {
    this.shareableEventIds = AgendaOperateHelper.getShareableEvents(events);
  }

  // 查询所有的匹配到的 event
  async showSelectAllNum() {
    if (this.allEventLoaded) {
      // 为了查询全部日程的数量，如果已经获取过了，就不再重复查询了，直接通知
      return;
    }
    const temp: QueryInfo = {} as QueryInfo;
    temp.startTime = this.defaultRangeBegin.getTime();
    temp.endTime = this.defaultRangeEnd.getTime();
    temp.searchText = this.changeValue;
    temp.filterRepeat = true;
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      temp.calendarUuid = this.calendarUuid;
    }
    const allEvents = await InstanceService.INSTANCE.queryInstanceGrouped(temp) as AgendaEventInfo[];
    this.allEvents = allEvents;
    this.allEventLoaded = true;
    Log.info(TAG, `queried all events: ${allEvents.length}`);
  }

  enableMultiSelect() {
    this.onSelectedItemsChanged({});
  }

  // 多选时，选中的日程变化
  private onSelectedItemsChanged(data: emitter.EventData): void {
    let selectAll: boolean = data.data?.selectAll;
    let filtered = AgendaUtil.filterDupByEventId(this.datas);
    if (selectAll != undefined) { // selectAll 有值的时候 true 是全选， false 是反选
      Log.info(TAG, `selectAll:${selectAll}}`);
      this.selectAll = selectAll;
      if (selectAll == true) {
        this.showSelectAllNum(); // 显示全部日程的个数
        filtered.forEach((e) => e.isSelected = true);
        this.getShareableEvents(filtered);
        this.selectedAgendaCount = filtered.length;
      } else {
        filtered.forEach((e) => e.isSelected = false);
        this.shareableEventIds = [];
        this.selectedAgendaCount = 0;
      }
      this.vmShowDataChange({
        showEventId: this.showEventId,
        currentDisplayStartMills: this.currentDisplayStartMills,
        currentDisplayEndMills: this.currentDisplayEndMills,
        shareableEventCount: this.shareableEventIds.length,
        selectedEventCount: this.selectedAgendaCount
      });
      return;
    } else {
      let selected = this.datas.filter((e) => e.isSelected);
      let unselectedCount = this.datas.length - selected.length;
      this.getShareableEvents(selected);
      this.selectedAgendaCount = selected.length;
      this.vmShowDataChange({
        showEventId: this.showEventId,
        currentDisplayStartMills: this.currentDisplayStartMills,
        currentDisplayEndMills: this.currentDisplayEndMills,
        shareableEventCount: this.shareableEventIds.length,
        selectedEventCount: this.selectedAgendaCount
      });
    }
  }

  /**
   * 改变状态，引起视图刷新
   */
  setStatusAndRefreshView() {
    Log.info(TAG, `Delete list data length = ${this.datas?.length}`);
    this.getDisplayDateAgenda(this.datas);
    this.getTodayDateAgenda(this.datas);
    if (this.supportMultiSelect) {
      let filtered = AgendaUtil.filterDupByEventId(this.datas);
      this.dataSources.setData(filtered);
    } else {
      this.dataSources.setData(this.datas);
    }
    this.dataSources.notifyDataReload();
    this.isDataReady = true;
  }

  /**
   * 根据当前的选中id 删除对应的日程
   * @returns
   */
  async deleteEventById(): Promise<boolean> {
    try {
      const rowsDeleted: number = await EventService.INSTANCE.deleteEventById(this.clickId) as number;
      if (rowsDeleted === undefined || rowsDeleted <= 0) {
        Log.warn(TAG, 'delete by id fail');
        return false;
      }
      this.datas = this.datas.filter(e => e.mId != this.clickId);
      this.dataSources.setData(this.datas);
      this.dataSources.notifyDataReload();
      this.onDeleteSuccess();
      ReportUtil.reportStatisticEvent(statisticEvents.searchPressPopupDeleteAgenda);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'subscribeEvents failed', err);
      return false;
    }
  }

  /**
   * 多选删除
   */
  public async deleteMultiEventsConfirm() {
    const start = new Date().getTime();
    let toRemove: Set<number> = new Set();
    if (this.selectAll) {
      // 除了当前页面没选中的日程之外，数据库中的event都要删除
      toRemove = new Set(this.allEvents.map(e => e.mId));
      this.datas.filter(e =>!e.isSelected).forEach(e => {
        toRemove.delete(e.mId);
      })
    } else {
      // 只删除当前选中的
      toRemove = new Set(this.datas.filter(e => e.isSelected).map(e => e.mId));
    }
    if (toRemove.size < 0) {
      Log.warn(TAG, `toRemove size ${toRemove.size}`);
      return;
    }
    EventService.INSTANCE.deleteEvents(toRemove).then((rowsDeleted) => {
      Log.info(TAG, `deleteMultiEvents ${rowsDeleted} deleted cost ${new Date().getTime() - start} ms`);
    })
    this.datas = this.datas.filter((e) =>!e.isSelected);
    emitter.emit({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE });
    this.setStatusAndRefreshView();
  }

  /**
   * 判断数组中是否存在该 id
   *
   * @param checkEventId 需要判断的日程 id 值
   * @param datas 日程数据数组
   */
  isContainCheckId(checkEventId: number, datas: AgendaEventInfo[]): boolean {
    Log.info(TAG, `checkEventId: ${this.checkEventId}`);
    const length = datas.length;
    for (let i = 0; i < length; i++) {
      if (checkEventId === datas[i].mId) {
        Log.info(TAG, `item.mId: ${datas[i].mId}`);
        return true;
      }
    }
    return false;
  }

  /**
   * 按照日程开始时间倒叙查询当前时间到1900-1-1的日程
   * @returns
   */
  async searchPastAgenda(): Promise<AgendaEventInfo[]> {
    const temp: QueryInfo = {} as QueryInfo;
    temp.startTime = this.defaultRangeBegin.getTime();
    temp.endTime = this.displayDate;
    temp.searchText = this.changeValue?.trim() ?? '';
    temp.currentPage = this.pastCurrentPage;
    temp.filterRepeat = true;
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      temp.calendarUuid = this.calendarUuid;
    }
    const groupResult = await InstanceService.INSTANCE.queryInstanceGrouped(temp) as AgendaEventInfo[];
    if (groupResult === undefined) {
      Log.error(TAG, `queryEventsInFusionSearchGrouped Return Nothing When searchFutureAgenda`);
      return [];
    }
    Log.info(TAG, `past CurrentPage: ${this.pastCurrentPage}, groupResult: ${groupResult.length}`);
    this.pastAgendaNum = groupResult.length;
    // return groupResult.reverse(); 待全搜排序能力支持后适配
    return groupResult;
  }

  /**
   * 按照日程开始时间正序查询当前时间到2100-12-31的日程
   * @returns
   */
  async searchFutureAgenda(): Promise<AgendaEventInfo[]> {
    const temp: QueryInfo = {} as QueryInfo;
    temp.startTime = this.displayDate;
    temp.endTime = this.defaultRangeEnd.getTime();
    temp.searchText = this.changeValue?.trim() ?? '';
    temp.currentPage = this.futureCurrentPage;
    temp.filterRepeat = true;
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      temp.calendarUuid = this.calendarUuid;
    }
    const groupResult = await InstanceService.INSTANCE.queryInstanceGrouped(temp) as AgendaEventInfo[];
    if (groupResult === undefined) {
      Log.error(TAG, `queryEventsInFusionSearchGrouped Return Nothing When searchFutureAgenda`);
      return [];
    }
    Log.info(TAG, `future CurrentPage: ${this.futureCurrentPage}, groupResult: ${groupResult.length}`);
    this.futureAgendaNum = groupResult.length;
    return groupResult;
  }

  /**
   * 第一次查询日程
   * @returns 是否查询成功返回
   */
  async onFirstSearch(): Promise<boolean> {
    Log.info(TAG, 'this.onSearch');
    if (this.changeValue === null || this.changeValue === undefined || this.changeValue.length == 0) {
      this.showResult = false;
      return false;
    }
    let queryInfo: QueryInfo = {
      startTime: this.displayDate - MILLS_ONE_YEAR,
      endTime: this.displayDate + MILLS_ONE_YEAR,
      searchText: this.changeValue.trim()
    }
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      queryInfo.calendarUuid = this.calendarUuid;
    }
    const result: AgendaEventInfo[] = await this.query(queryInfo);
    this.selectAllButtonAvailable = result.filter(e => e.isHoliday()).length !== result.length;
    this.changeDefaultStatusByResult(result);
    this.setStatusAndRefreshView();
    return true;
  }

  async query(queryInfo: QueryInfo): Promise<AgendaEventInfo[]> {
    try {
      this.range.start = Math.min(queryInfo.startTime, this.range.start);
      this.range.end = Math.max(queryInfo.endTime, this.range.end);
      let result: AgendaEventInfo[] = await InstanceService.INSTANCE.queryInstanceGrouped(queryInfo);
      this.updateViewText();
      return result;
    } catch (err) {
      Log.logErrorMsg(TAG, 'query failed', err);
      return [];
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
   * 更新按钮显示文本
   */
  private updateViewText() {
    this.headViewText = this.getHeadViewText(this.range.start);
    this.tailViewText = this.getTailViewText(this.range.end);
  }

  /**
   * 顶部文字按钮点击事件
   */
  public async onHeadTextClick() {
    if (this.headLoading) {
      return;
    }
    this.headLoading = true;
    const startTime = new CalendarDate(this.range.start)
      .setFullYear(new CalendarDate(this.range.start).getFullYear() - EXTEND_YEAR);
    let queryInfo: QueryInfo = {
      startTime: startTime,
      endTime: this.range.start,
      searchText: this.changeValue.trim()
    }
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      queryInfo.calendarUuid = this.calendarUuid;
    }
    const result: AgendaEventInfo[] = await this.query(queryInfo);
    const tempDatas: AgendaEventInfo[] = [...result, ...this.datas];
    this.changeDefaultStatusByResult(tempDatas);
    this.setStatusAndRefreshView();
    SafeUtil.setTimeout(() => {
      this.headLoading = false;
    }, 1000);
  }

  /**
   * 底部文字按钮点击事件
   */
  public async onTailTextClick() {
    if (this.tailLoading) {
      return;
    }
    this.tailLoading = true;
    const endTime = new CalendarDate(this.range.end)
      .setFullYear(new CalendarDate(this.range.end).getFullYear() + EXTEND_YEAR);
    let queryInfo: QueryInfo = {
      startTime: this.range.end + MILLS_PER_DAY,
      endTime: endTime,
      searchText: this.changeValue.trim()
    }
    if (!EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      queryInfo.calendarUuid = this.calendarUuid;
    }
    const result: AgendaEventInfo[] = await this.query(queryInfo);
    const tempDatas: AgendaEventInfo[] = [...this.datas, ...result];
    this.changeDefaultStatusByResult(tempDatas);
    this.setStatusAndRefreshView();
    SafeUtil.setTimeout(() => {
      this.tailLoading = false;
    }, 1000);
  }

  // 下拉加载下一页
  async handlePullDown() {
    if (this.pastAgendaNum < QUERY_PAGE_SIZE) {
      return;
    }
    Log.info(TAG, 'this.handlePullDown');
    if (this.changeValue === null || this.changeValue === undefined || this.changeValue.length == 0) {
      this.showResult = false;
      return;
    }
    if (!this.headLoading) {
      this.pastCurrentPage++;
      this.headLoading = true;
      const pastAgendaResult = await this.searchPastAgenda();
      const tempDatas: AgendaEventInfo[] = [...pastAgendaResult, ...this.datas];
      this.changeDefaultStatusByResult(tempDatas);
      this.setStatusAndRefreshView();
      const timer = setTimeout(() => {
        this.headLoading = false;
        clearTimeout(timer);
      }, 2000);
    }
  }

  // 上拉加载下一页
  async handlePullUp() {
    if (this.futureAgendaNum < QUERY_PAGE_SIZE) {
      return;
    }
    Log.info(TAG, 'this.handlePullUp');
    if (this.changeValue === null || this.changeValue === undefined || this.changeValue.length == 0) {
      this.showResult = false;
      return;
    }
    if (!this.tailLoading) {
      this.futureCurrentPage++;
      this.tailLoading = true;
      const futureAgendaResult = await this.searchFutureAgenda();
      const tempDatas: AgendaEventInfo[] = [...this.datas, ...futureAgendaResult];
      this.changeDefaultStatusByResult(tempDatas);
      this.setStatusAndRefreshView();
      const timer = setTimeout(() => {
        this.tailLoading = false;
        clearTimeout(timer);
      }, 2000);
    }
  }

  /**
   * 根据查询结果，获取日程结果集，改变页面状态参数
   *
   * @param result 日程列表
   */
  changeDefaultStatusByResult(result: Array<AgendaEventInfo>) {
    if (result.length === 0) {
      this.onFirstIdChange(-1, false);
      this.showResult = true;
      this.datas = [];
    } else {
      this.datas = result.slice().map((e) => new AgendaListItemViewModel(e));
      this.showResult = true;
      this.onFirstIdChange(this.datas[0].mId, this.isContainCheckId(this.checkEventId, this.datas));
    }
  }

  /**
   * 触发删除事件
   *
   * @param data
   */
  onDeleteEventByID(data: emitter.EventData): boolean {
    if (data?.data?.eventId === null || data?.data?.eventId === undefined) {
      return false;
    }
    // 将页面的日程数组进行软删除
    const eventId = data?.data?.eventId as number;
    this.datas = this.datas.filter((event: AgendaEventInfo) => {
      return event.mId !== eventId;
    })
    this.setStatusAndRefreshView();
    this.onDeleteSuccess();
    return true
  }

  /**
   * 获取距离 julianDay 最近的日程数组
   *
   * @param datas 插入今日空白日程的日程数组，传入数组需要按 mDay 进行升序排序
   * @param julianDay 儒略日
   */
  getNearAgendaOfArray(datas: AgendaEventInfo[], julianDay: number): number[] {
    // todo 传入数组需要按 mDay 进行升序排序
    if (datas.length === 0) {
      return [];
    }
    let hasAgenda: boolean = false;
    let targetIndex: number = datas.length - 1;
    const indexArr: number[] = []; // julianDay日程的索引值列表
    for (let i = 0; i < datas.length; i++) {
      if (datas[i]?.mDay === julianDay) {
        hasAgenda = true;
        indexArr.push(i);
      } else if (datas[i]?.mDay > julianDay) {
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
   * 获取距离 diplayDate 最近的日程
   *
   * @param datas 日程数组
   */
  getDisplayDateAgenda(datas: AgendaEventInfo[]) {
    if (this.datas.length === 0) {
      this.showEventId = -1;
      this.vmShowDataChange({
        showEventId: this.showEventId,
        currentDisplayStartMills: this.currentDisplayStartMills,
        currentDisplayEndMills: this.currentDisplayEndMills,
        shareableEventCount: this.shareableEventIds.length,
        selectedEventCount: this.selectedAgendaCount,
        selectable: false // 搜索前已经开启多选，搜索后结果为空时需退出多选
      });
      this.mScroller.scrollToIndex(0);
      return;
    }
    const displayJulianDay = DateUtil.getJulianDay(this.displayDate);
    this.displayEventsIndexArr = this.getNearAgendaOfArray(datas, displayJulianDay);
    this.checkedIdentity = this.getCheckedIdentity(this.datas[this.displayEventsIndexArr[0]]);
    this.showEventId = this.datas[this.displayEventsIndexArr[0]].mId;
    this.currentDisplayStartMills = this.datas[this.displayEventsIndexArr[0]].mBegin;
    this.currentDisplayEndMills = this.datas[this.displayEventsIndexArr[0]].mEnd;
    this.vmShowDataChange({
      showEventId: this.showEventId,
      currentDisplayStartMills: this.currentDisplayStartMills,
      currentDisplayEndMills: this.currentDisplayEndMills,
      shareableEventCount: this.shareableEventIds.length,
      selectedEventCount: this.selectedAgendaCount
    });
  }

  /**
   * 判断是否显示"回到今天"按钮
   * @param startIndex：容器顶部的ListItem索引值
   * @param endIndex：容器底部的ListItem索引值
   */
  public changeBackTodayStatus(startIndex: number, endIndex: number) {
    if (this.datas.length === 0) {
      this.isShowBackToday = false;
      return;
    } else {
      const indexArr: number[] = this.todayEventsIndexArr;
      const first: number = indexArr[0] + 1;
      const last: number = indexArr[indexArr.length - 1] + 1;
      if (!this.isTodayInRange()) {
        this.isShowBackToday = false;
      } else {
        this.isShowBackToday = (first > endIndex) || (last < startIndex); // 数值区间不相交，显示回到今天按钮
      }
    }
  }

  /**
   * 今日是否在日程扩展范围内
   */
  private isTodayInRange(): boolean {
    if (this.datas.length === 0) {
      return false;
    }
    let rangeBeginJulianDay: number = DateUtil.getJulianDay(this.datas[0].mBegin);
    let rangeEndJulianDay: number = DateUtil.getJulianDay(this.datas[this.datas.length - 1].mBegin);
    return (this.currentJulianDay >= rangeBeginJulianDay) && (this.currentJulianDay <= rangeEndJulianDay);
  }

  /**
   * "回到今天"按钮点击事件
   */
  public onBackTodayClick() {
    // 改变索引
    this.mScroller.scrollToIndex(this.todayEventsIndexArr[0] + 1);
    this.isShowBackToday = false;
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

  getCheckedIdentity(item: AgendaEventInfo) {
    return `${item.mId}_${item.mBegin}_${item.mDay}`;
  }

  onItemClick(item: AgendaEventInfo) {
    const identityStr = this.getCheckedIdentity(item);
    this.checkedIdentity = identityStr;
    // 更新本模块状态量
    this.vmShowDataChange({
      showEventId: this.showEventId,
      currentDisplayStartMills: this.currentDisplayStartMills,
      currentDisplayEndMills: this.currentDisplayEndMills,
      shareableEventCount: this.shareableEventIds.length,
      selectedEventCount: this.selectedAgendaCount
    });
    this.onActionFocusChange(FocusPage.AGENDA_DETAIL);
    Log.info(TAG, `onItemClick this.checkedIdentity = ${identityStr}`);
  }

  /**
   * 处理日程搜索页面键盘上下按键事件（被选中日程切换）
   *
   * @param keyCode
   */
  public onKeyPress(keyCode: number): boolean {
    const checkedIdentityStrings: string [] = this.checkedIdentity.split('_');
    const checkedId: number = Number(checkedIdentityStrings[0]);
    const checkedMDay: number = Number(checkedIdentityStrings[2]);
    let index = -1;

    for (let i = 0; i < this.dataSources.totalCount(); i++) {
      const agendaListItemViewModel: AgendaListItemViewModel | null = this.dataSources.getData(i);
      if (agendaListItemViewModel === null) {
        continue;
      }
      if (agendaListItemViewModel.mId === checkedId && agendaListItemViewModel.mDay === checkedMDay) {
        index = i;
        break;
      }
    }

    Log.info(TAG, `Current checked agenda index: ${index}`);
    if (index === -1) {
      Log.error(TAG, 'Current checked agenda index not found');
      return false;
    }

    let checkedItem: AgendaListItemViewModel | null = null;
    switch (keyCode) {
      case KeyCode.KEYCODE_DPAD_UP:
        if (index > 0) {
          checkedItem = this.dataSources.getData(index - 1);
          this.mScroller.scrollToIndex(index, true, ScrollAlign.CENTER);
        }
        break;
      case KeyCode.KEYCODE_DPAD_DOWN:
        if (index < this.dataSources.totalCount() - 1) {
          checkedItem = this.dataSources.getData(index + 1);
          this.mScroller.scrollToIndex(index, true, ScrollAlign.START);
        }
        break;
      default:
    }
    if (checkedItem != null) {
      this.onItemClick(checkedItem);
    }
    return true;
  }

  // 时间改变回调
  private timeChangeHandler: () => void = (): void => {
  };
  // 日程被删除的回调
  private eventDeleteChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  // 日程改变的回调
  private searchListChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  private selectedChangedHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
  // vm改变状态变量需要同步回view
  private vmShowDataChange:
    (data: showDataParams) => void = (data: showDataParams): void => {
    };
  // 手动处理用户点击动作对折叠屏的开合做适配，弱化变量传递，使用方式实现视图值传递，保证该视图的相对独立性
  // 此处非必选参数，不用放到构造函数里赋值
  public onActionFocusChange: (actionFocus: string) => void = (): void => {
  };
}

//vm改变状态变量参数
export interface showDataParams {
  showEventId: number;
  currentDisplayStartMills: number;
  currentDisplayEndMills: number;
  shareableEventCount: number;
  selectedEventCount: number;
  selectable?: boolean
}
