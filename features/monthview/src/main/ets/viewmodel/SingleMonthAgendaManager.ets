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
  AccountColor,
  AccountUtils,
  AgendaDataSource,
  AgendaEventInfo,
  CalendarContract,
  CalendarDate,
  CHINESE_HOLIDAY_STATE_VALUE,
  CommonService,
  DateManager,
  DateUtil,
  DayData,
  FestivalDay,
  getAdaptImportantTime,
  HolidayUtil,
  I18nUtil,
  InstanceService,
  isChineseCalendar,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_WEEK,
  QueryInfo,
  SafeUtil,
  ServiceEnum,
  ServiceManager,
  SystemTimerUtil,
  traceEvents,
  MonthlyInfo,
  DataSourceTemplate,
  DAY_PER_WEEK,
  CommonInnerEvent,
  maskString,
} from '@app/common';
import { SingleMonthlyViewModel } from './SingleMonthlyViewModel';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { SingleWeekViewModel, SingleWeekViewModelArray } from './SingleWeekViewModel';
import HashMap from '@ohos.util.HashMap';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { HashSet } from '@kit.ArkTS';
import { i18n } from '@kit.LocalizationKit';
import { MonthlyViewState, MonthlyViewStateManager } from './MonthlyViewState';
import { FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { MonthlyViewTemporaryAgendaData } from './MonthlyViewTemporaryAgendaData';
import { emitter } from '@kit.BasicServicesKit';
import { Recurrence, Frequency } from '@app/feature.repeatrule';

const TAG: string = '[MonthlyView][SigMonthAgendaManager]';
const LIST_ANIMATION_DURING = 300; // 月视图日程列表刷新的动效完成时长；
const LIST_ANIMATION_MIN_GAP = 10; // 等待宫格绘制完成时延


/**
 * SingleMonthAgendaManager
 *
 * AgendaManager of Single Month
 * Process Agenda in the Single month view
 * @since 2023-09-05
 */
@Observed
export class SingleMonthAgendaManager {
  // 当月视图内的所有日程
  public agendaResult: AgendaEventInfo[] = [];
  // 当月视图未过期的所有重要日日程
  public allImportantResult: AgendaEventInfo[] = [];
  // 当日日程列表的普通日程
  public todayNormalAgendas: AgendaEventInfo[] = [];
  // 当日日程列表的重要日日程
  public todayImportantAgendas: AgendaEventInfo[] = [];
  // 当前数据管理者绑定的月视图
  public sigMonthVM: SingleMonthlyViewModel;
  // 日程列表懒加载的普通日程内容
  public normalAgendaDataSources: AgendaDataSource = new AgendaDataSource([]);
  // 日程列表懒加载的重要日日程内容
  public importantAgendaDataSources: AgendaDataSource = new AgendaDataSource([]);
  // 日程列表内是否有日程
  public isTodayAnyAgendaExist: boolean = false
  // 所在月份的每一天是否存在
  public instancesFlags: boolean[] = [];
  // 所在月份的每一天是否存在
  public festivalsNameArrays: string[] = [];
  // 所在月份的每一天是否存在除假节日以外的日程
  public exceptHolidaysInstancesFlags: boolean[] = [];
  // 日程最小结束时间
  public minEndTime: number = -1;
  // 定时器
  public timer: SystemTimerUtil = new SystemTimerUtil();
  // 账户列表
  public static accountList: CalendarContract.Accounts[] = [];
  // 是否首次加载日程列表
  public isFirstLoadAgendaList: boolean = false;

  private isLoadImportantAgenda: boolean = false;
  private isLoadNormalAgenda: boolean = false;
  // 删除后 Instances 可能短暂返回旧数据，记录软删除项用于过滤并发查询结果
  private softDeletedEventIds: number[] = [];
  private softDeletedInstanceKeys: string[] = [];


  public constructor(sigMonthVM: SingleMonthlyViewModel) {
    this.sigMonthVM = sigMonthVM;
  }

  /**
   * 删除成功后同步移除月视图中的本地实例，避免 Instances 表尚未刷新时宫格继续显示旧日程块。
   * displayStartMills 为 0 表示删除整条日程，否则只删除指定的重复日程实例。
   */
  public onAgendaSoftDelete(eventId: number, displayStartMills: number): void {
    if (displayStartMills === 0) {
      if (!this.softDeletedEventIds.includes(eventId)) {
        this.softDeletedEventIds.push(eventId);
      }
    } else {
      const instanceKey: string = `${eventId}-${displayStartMills}`;
      if (!this.softDeletedInstanceKeys.includes(instanceKey)) {
        this.softDeletedInstanceKeys.push(instanceKey);
      }
    }
    const oldLength: number = this.agendaResult.length;
    this.agendaResult = this.filterSoftDeletedAgendas(this.agendaResult);
    if (oldLength === this.agendaResult.length) {
      return;
    }
    Log.info(TAG, `soft delete agenda from month cache, eventId: ${eventId}, begin: ${displayStartMills}`);
    this.sigMonthVM.agendaListModel.onAgendaChange(this.agendaResult);
  }

  private filterSoftDeletedAgendas(result: AgendaEventInfo[]): AgendaEventInfo[] {
    return result.filter((agenda: AgendaEventInfo): boolean => {
      if (this.softDeletedEventIds.includes(agenda.mId)) {
        return false;
      }
      const instanceKey: string = `${agenda.mId}-${agenda.mBegin}`;
      return !this.softDeletedInstanceKeys.includes(instanceKey);
    });
  }

  /**
   * 获取当前月份的日程数据
   */
  async getCurrentMonthAgenda() {
    hiTraceMeter.startTrace('getCurrentMonthAgenda', 0);
    let groupResult: AgendaEventInfo[] = [];
    const tmpAgendaData=MonthlyViewTemporaryAgendaData.getInstance();
    if (tmpAgendaData.notUseCache) { // 非冷启查询数据
      groupResult = await SingleMonthAgendaManager.queryAndProcessAgendaData(this.sigMonthVM?.curMonthlyInfo);

      if (this.sigMonthVM.arrayIndex !== undefined) {
        tmpAgendaData.recycleData(this.sigMonthVM.arrayIndex);
      }
    } else {  // 冷启使用MainAbility查询出并放在缓存里的日程数据
      if (this.sigMonthVM.arrayIndex === undefined) {
        return;
      }
      const arrayIndex: number = this.sigMonthVM.arrayIndex;
      await tmpAgendaData.waitForReady(this.sigMonthVM.arrayIndex);
      groupResult = tmpAgendaData.agendaList[arrayIndex];
      Log.info(TAG, 'groupResult length : ${groupResult.length} date : ${this.sigMonthVM?.curMonthlyInfo.toString()}');
      tmpAgendaData.cntPlus();
    }

    // 删除通知和 Instances 查询可能并发，防止较晚返回的旧实例重新显示在宫格中
    groupResult = this.filterSoftDeletedAgendas(groupResult);

    // 没有日程，后续都不需要处理!
    if (groupResult.length === 0) {
      Log.warn(TAG, 'groupResult empty');
      this.agendaResult = groupResult;
      this.sigMonthVM.agendaListModel.onAgendaChange(this.agendaResult);
      return;
    };
    // 查询到的结果集存到页面中
    this.agendaResult = groupResult;

    // 当月存在日程，重新绘制每周的日程视图
    this.sigMonthVM.agendaListModel.onAgendaChange(this.agendaResult);

    if (!this.isFirstLoadAgendaList) {
      this.isFirstLoadAgendaList = true;
      // 初次加载数据,滑动到顶部，叠卡过期日程
      Log.info(TAG, 'getCurrentMonthAgenda: updateScrollToTop by isFirstLoadAgendaList');
      this.sigMonthVM.agendaListModel.updateScrollToTop();
    }
    hiTraceMeter.finishTrace('getCurrentMonthAgenda', 0);
    emitter.emit({ eventId: CommonInnerEvent.EVENT_MONTH_VIEW_AGENDA_DATA_QUERY_COMPLETED });
  }

  static async queryAndProcessAgendaData(curMonthlyInfo: MonthlyInfo): Promise<AgendaEventInfo[]> {
    Log.info(TAG, `getCurrentMonthAgenda start`);
    const beginAndEnd: CalendarDate[] = SingleMonthAgendaManager.getBeginAndEndFromMonthViewData(curMonthlyInfo);
    if (!curMonthlyInfo) {
      Log.error(TAG, 'sigMonthVM curMonthlyInfo is undefined!');
      return [];
    }
    const temp: QueryInfo = {
      startTime: beginAndEnd[0].getTime(),
      endTime: beginAndEnd[1].getTime(),
      skipQueryAccount: true
    };
    Log.info(TAG, `querInstancesAsync start`);
    // 需要对每天进行分组，考虑日程列表内容

    let instanceResultArray: AgendaEventInfo[] = [];
    let accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap();
    try {
      hiTraceMeter.startTrace(traceEvents.queryInstanceGroupedAndGetAccountMap, 0);
      const results = await Promise.all([
        InstanceService.INSTANCE.queryInstanceGrouped(temp),
        SingleMonthAgendaManager.getAccountMap()
      ]);
      instanceResultArray = results[0];
      accountMap = results[1];
    } catch (error) {
      // 任何一个操作失败，都会进入 catch 块
      Log.logErrorMsg(TAG, `One or both operations failed, accountMap.length: ${accountMap},
        instanceResultArray.lenth: ${instanceResultArray.length} `, error);
    }
    hiTraceMeter.finishTrace(traceEvents.queryInstanceGroupedAndGetAccountMap, 0);

    Log.info(TAG, `querInstancesAsync range=${temp.startTime}->${temp.endTime} length: ${instanceResultArray.length}`);
    let groupResult : AgendaEventInfo[] = [];
    for (let item of instanceResultArray) {
      // 根据账户显隐状态过滤
      if (accountMap.get(item.mCalendarId)?.visible) {
        item.mDisplayColor = accountMap.get(item.mCalendarId).calendarColor;
        groupResult.push(item);
      }
    }
    Log.info(TAG, `queryAndProcessAgendaData range=${temp.startTime}->${temp.endTime} length:${groupResult.length}`);

    return groupResult;
  }

  static async getAccountMap(): Promise<HashMap<number, CalendarContract.Accounts>> {
    hiTraceMeter.startTrace('getAccountMap', 0);
    if (SingleMonthAgendaManager.accountList.length === 0) {
      try {
        SingleMonthAgendaManager.accountList = await InstanceService.INSTANCE.queryAccountListTask();
        Log.info(TAG, `getAccountList length : ${SingleMonthAgendaManager.accountList.length}`);
      } catch (error) {
        Log.logErrorMsg(TAG, `getAccountList err:`, error);
      }
    }
    hiTraceMeter.finishTrace('getAccountMap', 0);
    return CommonService.INSTANCE.getAccountMap(SingleMonthAgendaManager.accountList);
  }


  /**
   * 获取日程结束时间
   */
  getNotificationEndTimes(): number[] {
    let notificationEndTimes: number[] = [];
    const currentTime = new Date().getTime();
    this.agendaResult.forEach((item) => {
      if (item.mEnd > currentTime) {
        notificationEndTimes.push(item.mEnd);
      }
    })
    return notificationEndTimes;
  }

  /**
   * 获取本视图使用的月度数据的头尾两个日期
   */
  static getBeginAndEndFromMonthViewData(curMonthlyInfo: MonthlyInfo): CalendarDate[] {
    const ONE_DAY_MILL: number = 86400000;
    if (!curMonthlyInfo) {
      Log.error(TAG, 'curMonthlyInfo is NULL!');
      return [new CalendarDate(), new CalendarDate()];
    }
    const curMonthDays: DayData[] = curMonthlyInfo.getDisplayDays();
    if (curMonthDays.length === 0) {
      Log.error(TAG, 'NO DAYS DATA IN monthViewData!');
      return [new CalendarDate(), new CalendarDate()];
    }
    const firstDay: DayData = curMonthDays[0];
    const lastDay: DayData = curMonthDays[curMonthDays.length - 1];
    const begin = new CalendarDate(firstDay.solarYear, firstDay.solarMonth - 1, firstDay.solarDay);
    const end = new CalendarDate(new CalendarDate(lastDay.solarYear, lastDay.solarMonth - 1, lastDay.solarDay)
      .getTime() + ONE_DAY_MILL - 1);
    return [begin, end];
  }

  /**
   * 解析展示日期当天的日程信息，触发日程列表绘制
   *
   * @param selectDate
   */
  analyzeAgendaInDate(selectDate?: DateInfo, isImportant: boolean = false): boolean {
    if (selectDate === undefined) {
      Log.error(TAG, 'NO VALID SELECT DATE!');
      return false;
    }
    Log.info(TAG, `analyzeAgendaInDate selectDate = ${selectDate.month} ${selectDate.weekNum} ${selectDate.day}`);
    this.analyzeNormalAgendaInDate(selectDate);
    this.analyzeImportantAgendaInDate(selectDate);

    // 触发月视图日程列表刷新
    this.notifyTodayAgendasChanged(isImportant);
    this.logTodayAgendas(selectDate);
    return true;
  }

  /**
   * 对月视图中的日程列表进行排序
   *
   * @param agendaList 日程列表
   * @param isAgendaList 是否对日程列表进行排序，
   * 若是日程列表，则按开始时间(时间小优先)>结束时间(时间小优先)>标题排序(字符序靠前优先)
   * 若不是，则先按跨天（跨天优先）>开始时间(时间小优先)>结束时间(时间大优先)>标题排序(字符序靠前优先)
   * @return 排序后的日程信息数组
   */
  sortAgendaList(agendaList: AgendaEventInfo[], isAgendaList: boolean = false): AgendaEventInfo[] {
    if (!agendaList || agendaList.length === 0) {
      return [];
    }
    // 避免在循环里调用获取时区偏移量操作，减少耗时
    const stamp = agendaList[0].mEnd;
    const timeZoneOffset = DateUtil.getTimeZoneOffset(CalendarDate.timeZone, stamp);
    const offset = DateUtil.getTimeZoneOffset(I18nUtil.getSystemTimeZone(), stamp);
    const isSameDayTimeStamp = (stamp1: number, stamp2: number): boolean => {
      const gmtDate1 = new Date(stamp1 - offset + timeZoneOffset);
      const gmtDate2 = new Date(stamp2 - offset + timeZoneOffset);
      return DateUtil.isSameYearMonthDay(gmtDate1, gmtDate2);
    };

    return agendaList.sort((agenda1: AgendaEventInfo, agenda2: AgendaEventInfo) => {
      if ((agenda1.mIsAllDay && agenda2.mIsAllDay) || (agenda1.isHoliday() && agenda2.isHoliday())) {
        // 标题排序
        if (agenda1.mTitle === agenda2.mTitle) {
          return 0;
        }
        if (agenda1.mTitle === '入九' && agenda2.mTitle === '冬至') {
          return 1;
        }
        return agenda1.mTitle < agenda2.mTitle ? -1 : 1;
      }
      if (agenda1.isHoliday()) {
        return -1;
      }
      if (agenda2.isHoliday()) {
        return 1;
      }
      if (isAgendaList) {
        const isCrossA: boolean = !agenda1.mIsAllDay && !isSameDayTimeStamp(agenda1.mBegin, agenda1.mEnd);
        const isCrossB: boolean = !agenda2.mIsAllDay && !isSameDayTimeStamp(agenda2.mBegin, agenda2.mEnd);
        if (isCrossA !== isCrossB) {
          return isCrossA ? -1 : 1;
        }
      }
      if (agenda1.mIsAllDay) {
        return -1;
      }
      if (agenda2.mIsAllDay) {
        return 1;
      }

      if (!isAgendaList) {
        const isCrossA: number = isSameDayTimeStamp(agenda1.mBegin, agenda1.mEnd) ? 1 : 0;
        const isCrossB: number = isSameDayTimeStamp(agenda2.mBegin, agenda2.mEnd) ? 1 : 0;
        // 若两者有一个不跨天
        if (isCrossA !== isCrossB) {
          return isCrossA - isCrossB;
        }
      }
      const startA: number = agenda1.mBegin;
      const startB: number = agenda2.mBegin;
      // 开始时间早的排序靠前
      if (startA !== startB) {
        return startA - startB;
      }
      const endA: number = agenda1.mEnd;
      const endB: number = agenda2.mEnd;
      // 结束时间前的排序靠前
      if (endA !== endB) {
        return isAgendaList ? (endA - endB) : (endB - endA);
      }

      // 标题排序
      if (agenda1.mTitle === agenda2.mTitle) {
        return 0;
      }

      return agenda1.mTitle < agenda2.mTitle ? -1 : 1;
    });
  }


  async onFestivalsChange(result: AgendaEventInfo[]) {
    const curMonthDays: DayData[] | undefined = this.sigMonthVM?.curMonthlyInfo?.getDisplayDays();
    if (curMonthDays === undefined) {
      Log.error(TAG, 'NO VALID CUR MONTH DAYS on Instances Flags Change');
      return;
    }
    this.agendaResult = result;
    Log.info(TAG,
      `onFestivalsChange agendaResult : ${result.length}, date: ${this.sigMonthVM?.curMonthlyInfo.toString()}`);
    const firstDay: DayData = curMonthDays[0] as DayData;
    const beginJulian = firstDay.getDate().getJulianDay();
    const daysAccount: number = curMonthDays.length;
    const showImportant: boolean = MonthlyViewStateManager.getInstance().state.showImportantDay;
    this.festivalsNameArrays  = new Array(daysAccount).fill('');
    const monthDateLength = daysAccount;
    try {
      for (const item of result) {
        // 仅处理节假日类型的日程，普通日程不应覆盖农历日期文本，应显示为圆点
        if (!item.isHoliday()) {
          continue;
        }
        if (!showImportant && item.isImportantEvent()) {
          continue;
        }
        // 解析查询到的结果集，按照实例的开始日期和结束日历对状态数组进行赋值
        let instanceStartDay: number = item.mStartDay;
        let instanceEndDay: number = item.mEndDay;
        //  实例开始标点
        let firstIndex: number = 0;
        if (instanceStartDay - beginJulian > 0) {
          firstIndex = instanceStartDay - beginJulian
        }
        // 实例结束标点
        let lastIndex: number = monthDateLength - 1;
        const endGap: number = instanceEndDay - beginJulian;
        if (endGap < (monthDateLength - 1)) {
          lastIndex = endGap
        }
        for (let i = firstIndex; i <= lastIndex; i++) {
          if (i < 0 || i > this.festivalsNameArrays.length) {
            continue;
          }
          if (this.festivalsNameArrays[i] === '' || item.mTitle === '冬至') {
            this.festivalsNameArrays[i] = item.mTitle;
          }
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `onFestivalsChange init error`, err);
    }
    for (let weekIndex = 0; weekIndex < Math.floor(daysAccount / DAY_PER_WEEK); weekIndex++) {
      if (this.sigMonthVM?.weekViewModels === undefined) {
        Log.error(TAG, 'NO VALID WEEK VM on holiday Change');
        return;
      }
      const sigWeekVM: SingleWeekViewModel = this.sigMonthVM?.weekViewModels[weekIndex] as SingleWeekViewModel;
      sigWeekVM?.onFestivalsChange(this.festivalsNameArrays.slice(DAY_PER_WEEK * weekIndex, DAY_PER_WEEK * weekIndex + DAY_PER_WEEK));
    }
  }

  /**
   * 监听 agendaResult 变化 改变本月日期对应的日程标志矩阵
   *
   * @param result 查询到的结果
   */
  async onInstancesFlagsChange(result: AgendaEventInfo[]) {
    const curMonthDays: DayData[] | undefined = this.sigMonthVM?.curMonthlyInfo?.getDisplayDays();
    if (curMonthDays === undefined) {
      Log.error(TAG, 'NO VALID CUR MONTH DAYS on Instances Flags Change');
      return;
    }
    this.agendaResult = result;
    Log.info(TAG,
      `onInstancesFlagsChange agendaResult : ${result.length}, date: ${this.sigMonthVM?.curMonthlyInfo.toString()}`);
    const showImportant: boolean = MonthlyViewStateManager.getInstance().state.showImportantDay;
    if (!showImportant) {
      result = result.filter((item: AgendaEventInfo): boolean => !item.isImportantEvent());
    }
    this.instancesFlags = this.getInstancesFlags(curMonthDays, result);
    //移除节假日日程对日程点的影响
    result = result.filter(item => {
      // 普通日程显示日程点
      if (item.mImportantEventType === CalendarContract.EventImportantType.NORMAL) {
        return true;
      }
      // 新规格，重要日也要展示日程点
      if (item.isImportantEvent()) {
        return true;
      }
      return false;
    });
    this.exceptHolidaysInstancesFlags = this.getInstancesFlags(curMonthDays, result);
    const daysAccount: number = curMonthDays.length;
    for (let weekIndex = 0; weekIndex < Math.floor(daysAccount / DAY_PER_WEEK); weekIndex++) {
      if (this.sigMonthVM?.weekViewModels === undefined) {
        Log.error(TAG, 'NO VALID WEEK VM on Instances Flags Change');
        return;
      }
      const sigWeekVM: SingleWeekViewModel = this.sigMonthVM?.weekViewModels[weekIndex] as SingleWeekViewModel;
      sigWeekVM?.onInstancesFlagsChange(this.instancesFlags.slice(DAY_PER_WEEK * weekIndex, DAY_PER_WEEK * weekIndex + DAY_PER_WEEK),
        this.exceptHolidaysInstancesFlags.slice(DAY_PER_WEEK * weekIndex, DAY_PER_WEEK * weekIndex + DAY_PER_WEEK));
    }
  }

  private getInstancesFlags(curMonthDays: DayData[], result: AgendaEventInfo[]): boolean[] {
    const firstDay: DayData = curMonthDays[0] as DayData;
    const beginJulian = firstDay.getDate().getJulianDay();
    const daysAccount: number = curMonthDays.length;
    let newInstancesFlags: boolean[] = new Array(daysAccount).fill(false);
    const monthDateLength = daysAccount;
    try {
      for (const item of result) {
        // 解析查询到的结果集，按照实例的开始日期和结束日历对状态数组进行赋值
        let instanceStartDay: number = item.mStartDay;
        let instanceEndDay: number = item.mEndDay;

        //  实例开始标点
        let firstIndex: number = 0;
        if (instanceStartDay - beginJulian > 0) {
          firstIndex = instanceStartDay - beginJulian
        }

        // 实例结束标点
        let lastIndex: number = monthDateLength - 1;
        const endGap: number = instanceEndDay - beginJulian;
        if (endGap < (monthDateLength - 1)) {
          lastIndex = endGap
        }
        for (let i = firstIndex; i <= lastIndex; i++) {
          newInstancesFlags[i] = true;
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'getEventListFromCursor', err);
    }
    return newInstancesFlags;
  }

  /**
   * 每一个单周的日程数据变更
   *
   * @param result
   */
  onSigWeekAgendaChange(result: AgendaEventInfo[]) {
    if (result === null || result === undefined) {
      // 小概率查询失败，不改变当前日程块内容
      Log.error(TAG, 'NO VALID RESULT IN SIG WEEK AGENDA CHANGE!');
      return;
    }
    Log.info(TAG, 'result.length = ' + result.length)
    const curMonthDays: DayData[] | undefined = this.sigMonthVM.curMonthlyInfo?.getDisplayDays();
    if (curMonthDays === undefined) {
      Log.error(TAG, 'NO VALID WEEK VM on Sig Week Agenda Change');
      return;
    }
    const daysAccount: number = curMonthDays.length as number;
    const weekAccount: number = Math.floor(daysAccount / 7);
    if (result.length === 0) {
      this.sigWeekNoAgendaChange(weekAccount);
      return;
    }

    if (daysAccount === 0) {
      return;
    }
    // 将每个日程划分到每周中去，每周取左闭右开区间[00:00:00 , 23:59:59)
    const startTimeOfCurMonth: number = curMonthDays[0].getTimeStamp();
    let weekAgendas: AgendaEventInfo[][] = [];
    for (let index = 0; index < weekAccount; index++) {
      weekAgendas.push([]);
    }
    const sortedList: AgendaEventInfo[] = this.sortAgendaList(result, false);

    // 用于重复跨天日程去重
    const checkSet: HashSet<string> = new HashSet();
    for (let agenda of sortedList) {
      const key = '' + agenda.mId + '-' + agenda.mStartDay + '-' + agenda.mEndDay;
      if (checkSet.has(key)) {
        continue;
      }
      checkSet.add(key);
      let startTimeOfCurMonthFinal: number = startTimeOfCurMonth;
      if (agenda.mIsAllDay) {
        //全天日程采用UTC时区存储,需要计算偏移量 --welink会插入非UTC时区的全天日程,故需要获取时区计算偏移量
        startTimeOfCurMonthFinal = startTimeOfCurMonthFinal + I18nUtil.getTimeZoneOffsetById(agenda.eventTimeZone);
      }
      // 向下取整周次，将日程向[0 , （weekAccount - 1）]区间散列
      const startTime: number = Math.floor((agenda.mBegin - startTimeOfCurMonthFinal) / (MILLS_PER_WEEK));
      const startIndex: number = startTime >= 0 ? startTime : 0;
      const endTime: number = Math.floor((agenda.mEnd - startTimeOfCurMonthFinal - 1) / (MILLS_PER_WEEK));
      const endIndex: number = endTime >= (weekAccount - 1) ? (weekAccount - 1) : endTime;
      for (let index = startIndex; index <= endIndex; index++) {
        weekAgendas[index].push(agenda);
      }
    }

    for (let weekIndex = 0; weekIndex < weekAccount; weekIndex++) {
      const sigWeekVMArr: SingleWeekViewModelArray = this.sigMonthVM?.weekViewModels as SingleWeekViewModelArray;
      sigWeekVMArr[weekIndex]?.onSigWeekAgendaChange(weekAgendas[weekIndex]);
    }
  }

  /**
   * 处理数据变化广播
   */
  async onDataChange() {
    Log.info(TAG, 'sigMonthAgendaManager onDataChange start!');
    await this.getCurrentMonthAgenda();
    return;
  }

  protected isImportantEventCanShow(event: AgendaEventInfo, selectDateBegin: number, selectedDateEnd: number): boolean {
    if (!event) {
      return false;
    }
    // 若是重复并且带有截止时间的重要日，需要算出截止重复的时间
    if (event.isRepeatEvent() && (event.mRepeatRule.includes('UNTIL=') || event.mRepeatRule.includes('COUNT='))) {
      const endRepetitionTime: number = this.getEndRepetitionTime(event);
      // 截止重复的时间小于选中时间，则不需要展示
      if (endRepetitionTime !== 0 && endRepetitionTime <= selectDateBegin) {
        Log.info(TAG, `repeat important title:${maskString(event.mTitle)},end repeatition time:${endRepetitionTime}`);
         return false;
      }
    }
    // 重要日是UTC时区的，转换为当前时区进行比较计算
    const beginTimeInCurrentTimezone: number = event.mBegin + i18n.getTimeZone().getRawOffset();
    // 从创建时间开始，即可展示倒数日
    const startShowTime: number = Math.min(beginTimeInCurrentTimezone, event.mEventTimeStamp);
    if (event.isImportantAnniversaries()) {
      // 对于纪念日，选中时间大于开始显示时间，即可展示（无截止时间）
      return selectedDateEnd >= startShowTime;
    } else if (event.isImportantCountDown()) {
      if (event.isRepeatEvent()) {
        // 对于重复倒数日，选中时间大于开始显示时间，即可展示（无截止时间）
        return selectedDateEnd >= startShowTime;
      } else {
        // 对于非重复倒数日，除了要大于可显示时间，还要小于截止日期
        const agendaDateTime = DateUtil.getStartMillsOfDate(new CalendarDate(event.mBegin));
        const selectedDateTime = DateUtil.getStartMillsOfDate(new CalendarDate(selectDateBegin));
        return selectedDateEnd >= startShowTime && selectedDateTime <= agendaDateTime;
      }
    }
    // 不是纪念日也不是倒数日，当前版本不支持，直接不显示
    return false;
  }

  public getEndRepetitionTime(event: AgendaEventInfo): number {
    const recurrence: Recurrence = new Recurrence();
    recurrence.parse(event.mRepeatRule);
    if (recurrence.hasUntil()) { // 结束重复的是具体日期，直接获取
      return recurrence.getUntilMills();
    } else if (recurrence.hasCount()) { //结束重复的是次数，需要通过次数和规则综合获取结束重复时间
      let date = new Date(event.mOriginalBegin);
      const count = recurrence.count;
      switch (recurrence.freq) {
        case Frequency.MONTHLY:
          return date.setUTCMonth(date.getMonth() + count - 1);
        case Frequency.YEARLY:
          return date.setUTCFullYear(date.getUTCFullYear() + count - 1);
        default:
          return 0;
      }
    } else { // 没有结束重复时间, 根据上层判断，应该走不到该处
      return 0;
    }
  }

  /**
   * 对月视图重要日列表进行排序,倒数日在纪念日前面。倒数日时间戳越小越靠前，纪念日时间戳越大越靠前。
   */
  protected groupImportantAgendas(importantAgendas: AgendaEventInfo[], selectDate: number) {
    if (!Array.isArray(importantAgendas)) {
      Log.error(TAG, 'NO importantAgendas!');
      return;
    }
    let offSetDayMap: Record<number, number> = {};
    importantAgendas.forEach((item) => {
      offSetDayMap[item.mId] = this.calculateDayOffset(item, selectDate);
    })
    // 0是日程 ，1是纪念日，2是倒数日
    importantAgendas.sort((a, b) => {
      let typeGap = b.mImportantEventType - a.mImportantEventType; // 倒数日在纪念日前面
      if (typeGap === 0) { // 表示类型相同
        if (a.mImportantEventType === 1) {
          return b.mBegin - a.mBegin; // 纪念日时间戳越大越靠前
        }
        return offSetDayMap[a.mId] - offSetDayMap[b.mId]; // 倒数日时间差越小越靠前
      }
      return typeGap;
    })
  }

  private calculateDayOffset(event: AgendaEventInfo, selectDate: number) {
    const toDate = new CalendarDate(selectDate);
    // 按rule规则，将重要日挪移到当月，便于计算倒数天数
    const showTime = getAdaptImportantTime(event.mEventCalendar, event.mBegin, event.mRepeatRule, toDate);
    const offsetContent = DateUtil.getDayOffset(showTime, event.mImportantEventType, selectDate);
    return offsetContent.dayOffset;
  }

  /**
   * 单周无日程处理逻辑
   */
  protected sigWeekNoAgendaChange(weekAccount: number) {
    for (let weekIndex = 0; weekIndex < weekAccount; weekIndex++) {
      if (this.sigMonthVM?.weekViewModels === undefined) {
        Log.error(TAG, 'NO VALID WEEK VM on Instances Flags Change');
        return;
      }
      const sigWeekVM: SingleWeekViewModel = this.sigMonthVM?.weekViewModels[weekIndex] as SingleWeekViewModel;
      sigWeekVM?.onSigWeekAgendaChange([]);
    }
  }

  private analyzeNormalAgendaInDate(selectDate: DateInfo) {
    const julianDay: number = selectDate.getDate().getJulianDay();
    let result: AgendaEventInfo[] = [];
    if (this.agendaResult) {
      result = this.agendaResult.filter((item: AgendaEventInfo) => item.mDay === julianDay &&
        (item.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
          item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY));
    }
    this.addFestivalAgenda(result, selectDate);
    this.todayNormalAgendas = [];
    Log.info(TAG, `form agendaResult to todayNomalAgendas length:${result.length},date:${selectDate.toString()}`);
    if (result.length !== 0) {
      this.todayNormalAgendas = this.sortAgendaList(result, true); // 对日程列表的顺序进行重排
      return;
    }
    Log.info(TAG, `agendaResult length :${this.agendaResult.length}, date:${selectDate.toString()}`);
  }

  addFestivalAgenda(result: AgendaEventInfo[], selectDate: DateInfo) {
    const festivalAgendas: string[] = result.filter((item: AgendaEventInfo) => item.mImportantEventType ===
    CalendarContract.EventImportantType.HOLIDAY).map(info => info.mTitle.trim());
    const selectDayData: DayData = DateManager.getInstance().getDayData(selectDate.year,
      selectDate.month, selectDate.day) as DayData;
    if (!selectDayData) {
      Log.error(TAG, 'selectDayData is null');
      return;
    }
    const monthState = MonthlyViewStateManager.getInstance().state;
    selectDayData.festivals.forEach((festivalDay: FestivalDay) => {
      if (monthState.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CLOSE &&
        festivalDay.type !== FestivalType.SOLAR_TERM) {
        Log.error(TAG, `festivalDay remove close holiday ${festivalDay.name}`);
        return;
      }
      if (monthState.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN &&
        HolidayUtil.needRemoveHoliday(festivalDay.name) === '') {
        Log.error(TAG, `festivalDay remove in same nature holiday ${festivalDay.name}`);
        return;
      }
      if (monthState.isIslamicCalendar()) {
        Log.error(TAG, `festivalDay remove in islamic ${festivalDay.name}`);
        return;
      }
      if (!this.needShowFestivalAgenda(monthState, festivalDay)) {
        Log.error(TAG, `festivalDay remove in other regin ${festivalDay.name}`);
        return;
      }
      if (festivalAgendas.includes(festivalDay.name)) {
        Log.error(TAG, `festivalDay remove in same agenda ${festivalDay.name}`);
        return;
      }
      let festivalAgenda: AgendaEventInfo = new AgendaEventInfo();
      const selectDate = selectDayData.getDate();
      // 适配时区将本地节假日设置为UTC时区的0点
      const stamp: number =
        new Date().setUTCFullYear(selectDate.getFullYear(), selectDate.getMonth(), selectDate.getDate());
      festivalAgenda.eventTimeZone = 'UTC';
      festivalAgenda.mTitle = festivalDay.name;
      festivalAgenda.mIsHoliday = true;
      festivalAgenda.mIsAllDay = true;
      festivalAgenda.mId = -1; // 用作标识，无实际含义
      festivalAgenda.mBegin = stamp;
      festivalAgenda.mImportantEventType = -1; // 用作标识，无实际含义
      festivalAgenda.mEnd = stamp + MILLS_PER_DAY - 1;
      festivalAgenda.mDisplayColor = AccountColor.RED;
      result.push(festivalAgenda);
    });

  }

  needShowFestivalAgenda(state: MonthlyViewState, festivalDay: FestivalDay) {
    return (isChineseCalendar(state.subscriptionCalendar) || (festivalDay.type !== FestivalType.SOLAR_TERM)) &&
      //非中国地区去除中国节假日
      (this.isChineseRegion(state.systemRegion) || this.isChineseFestival(festivalDay))
  }

  isChineseFestival(day: FestivalDay) {
    return day.type !== FestivalType.OFFICIAL_CHINA && day.type !== FestivalType.OFFICIAL_TAIWAN &&
      day.type !== FestivalType.OFFICIAL_HONGKONG;
  }

  //判断地区是否属于中国
  isChineseRegion(region: string): boolean {
    return region === 'CN' || region === 'MO' || region === 'HK' || region === 'TW';
  }

  private analyzeImportantAgendaInDate(selectDate: DateInfo) {
    if (!this.allImportantResult) {
      Log.info(TAG, `no important agenda in ${selectDate.year}-${selectDate.month}`);
      return;
    }
    const date: CalendarDate = new CalendarDate(selectDate.year, selectDate.month - 1, selectDate.day);
    const todayBegin: number = DateUtil.getStartMillsOfDate(date);
    const todayEnd: number = DateUtil.getEndMillsOfDate(date);
    this.moveRecurrenceImportantToSelectDate(date);
    let result: AgendaEventInfo[] = [];
    if (this.allImportantResult) {
      result = this.allImportantResult.filter((item: AgendaEventInfo) => {
        return this.isImportantEventCanShow(item, todayBegin, todayEnd);
      })
      this.groupImportantAgendas(result, date.getTime());
    }
    this.todayImportantAgendas = [];
    if (result && result.length !== 0) {
      this.todayImportantAgendas = result;
    }
  }

  /**
   * 针对循环重要日，将重要日日程的日期，调整为选中日期当年/当月/下一年/下一月对应的日期
   */
  protected moveRecurrenceImportantToSelectDate(selectDate: CalendarDate) {
    if (!this.allImportantResult) {
      return;
    }
    this.allImportantResult.forEach((important: AgendaEventInfo) => {
      if (!important) {
        // 非重要日，不需要处理 -- 非循环重要日仍然需要适配时区将时间调整为当前时间的0点
        return;
      }
      important.mBegin = getAdaptImportantTime(important.mEventCalendar, important.mOriginalBegin,
        important.mRepeatRule, selectDate) + 1; // +1用于与当前重要日逻辑保持一致
      important.mEnd = important.mBegin - important.mOriginalBegin + important.mOriginalEnd;
    });
  }

  /**
   * 监听 agendasList 变化，触发月视图的日程列表刷新 dataSources 改变，引起视图刷新
   */
  private notifyTodayAgendasChanged(isImportant: boolean = false) {
    Log.info(TAG, `Agenda list data length = ${this.todayNormalAgendas?.length}, ${this.todayImportantAgendas?.length}`);
    this.isTodayAnyAgendaExist = this.todayNormalAgendas?.length > 0 ||
      this.todayImportantAgendas?.length > 0;

    if (isImportant) {  //只有第一次启动会走该分支，为解决普通日程和重要日日程先后刷新问题
      this.isLoadImportantAgenda = true;
      this.sigMonthVM.onIsTodayAgendaExistChange(this.isTodayAnyAgendaExist,
        this.isLoadNormalAgenda && this.isLoadImportantAgenda);
      this.importantAgendaDataSources.setData(this.todayImportantAgendas);
      this.sigMonthVM.agendaListModel.refreshAgendaCounts('notifyTodayAgendasChanged');
      this.importantAgendaDataSources.notifyDataReload();
    } else {
      setTimeout(() => {
        /**
         * 延迟调用动效接口 需要等待日期宫格完成绘制再绘制下方列表动效，
         * 否则在月视图处于收齐状态，点击前后两个月的日期（例如6.30 切到 7.1）时会出现上方日期区域的闪动
         * 根因在于当前Canvas不支持动效，且 ArkUI 无法感知到日期是否完成绘制
         */
        animateTo({ duration: LIST_ANIMATION_DURING, curve: Curve.Friction }, () => {
          this.isLoadNormalAgenda = true;
          this.sigMonthVM.onIsTodayAgendaExistChange(this.isTodayAnyAgendaExist,
            this.isLoadNormalAgenda && this.isLoadImportantAgenda);
          Log.info(TAG, ' selectDate ：' + this.sigMonthVM.selectDate.toString() +
            'old normalAgendaDataSources length : ' + this.normalAgendaDataSources.totalCount() +
            'new normalAgendaDataSources length : ' + this.todayNormalAgendas.length);
          this.normalAgendaDataSources.setData(this.todayNormalAgendas);
          this.importantAgendaDataSources.setData(this.todayImportantAgendas);
          this.sigMonthVM.agendaListModel.refreshAgendaCounts('notifyTodayAgendasChanged');
          this.normalAgendaDataSources.notifyDataReload();
          this.importantAgendaDataSources.notifyDataReload();
        });
      }, LIST_ANIMATION_MIN_GAP);
    }
  }

  public logTodayAgendas(selectDate: DateInfo) {
    // 打印普通日程和重要日程前10个的ID，辅助外部定位问题
    if (selectDate.month === this.sigMonthVM.curMonthlyInfo.solarMonth) {
      Log.info(TAG, `todayNormalAgenda ids: ${this.todayNormalAgendas.slice(0, 10).map(event => event.mId).toString()}` +
        ` date: ${selectDate.month}-${selectDate.day}`);
      Log.info(TAG, `todayImportantAgenda ids: ${this.todayImportantAgendas.slice(0, 10).map(event => event.mId).toString()}` +
        ` date: ${selectDate.month}-${selectDate.day}`);
      return true;
    }
    return false;
  }
}
