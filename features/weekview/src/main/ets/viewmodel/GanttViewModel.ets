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

import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { DateRange } from '@app/common/src/main/ets/date/DateRange';
import { GanttBlockViewModel } from './GanttBlockViewModel';
import { DayModel } from '../model/DayModel';
import {
  AccountColor,
  AgendaEventInfo,
  CalendarContract,
  CalendarDate,
  CHINESE_HOLIDAY_STATE_VALUE,
  CommonInnerEvent,
  CompId,
  DateUtil,
  EventService,
  HolidayUtil,
  HOURS_PER_DAY,
  I18nUtil,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  PreferencesFiles,
  PreferencesUtil,
  ReminderService,
  SafeUtil
} from '@app/common';
import { AgendaModel } from '../model/AgendaModel';
import { RootViewModel } from './RootViewModel';
import { FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { RootModel } from '../model/RootModel';
import { NewGanttBlockViewModel } from './NewGanttBlockViewModel';
import emitter from '@ohos.events.emitter';
import { addExDateToDb, updateUntilToDb } from '@app/feature.repeatrule';
import { AgendaDetailSource, DeleteMode as ChangeMode } from '@app/feature.agenda';
import { AgendaOperateHelper } from '@app/feature.agenda/src/main/ets/helpers/AgendaOperateHelper';
import i18n from '@ohos.i18n';

const TAG: string = 'GanttViewModel';
const TEN_MINUTE_MILLS = 10 * MILLS_PER_MINUTE;

class GanttViewStateModel {
  selectBlock: GanttBlockViewModel | undefined = undefined;
}

interface ScrollOffset {
  xOffset: number,
  yOffset: number
};

@Observed
export class GanttLineViewModel {
  //上午和下午的时间
  public readonly MORNING_RATIO: number = 11.5;
  public readonly AFTERNOON_RATIO: number = 12.5;
  public morningLine: number = this.MORNING_RATIO;
  public afternoonLine: number = this.AFTERNOON_RATIO;
  public hiddenMorning: boolean = false;
  public hiddenAfternoon: boolean = false;
  public hiddenHourIndex: number = -1;
  public gridCellHeight: number = 60;
  public oldGridCellHeight: number = 60;

  public hideLineInOtherRange() {
    this.hiddenHourIndex = -1;
    this.hiddenMorning = false;
    this.hiddenAfternoon = false;
  }

  public updateLinePosition(nowY: number) {
    if (nowY < this.AFTERNOON_RATIO) {
      this.morningLine = nowY;
      this.afternoonLine = this.AFTERNOON_RATIO;
    } else {
      this.morningLine = this.AFTERNOON_RATIO - 1;
      this.afternoonLine = nowY;
    }
  }

  public updateLineHidden(stampFromStart: number, timeTextHeight: number, heightPerMs: number) {
    const nearestHour = Math.round(stampFromStart / MILLS_PER_HOUR);
    const gap = Math.abs(nearestHour * MILLS_PER_HOUR - stampFromStart) * heightPerMs;
    this.hiddenHourIndex = gap > timeTextHeight ? -1 : (nearestHour - 1); // 只显示1-23小时
    const gapMorning = Math.abs(this.morningLine * MILLS_PER_HOUR - stampFromStart) * heightPerMs;
    this.hiddenMorning = gapMorning < (timeTextHeight / 2); // 是否显示上午
    const gapAFTERNOON = Math.abs(this.afternoonLine * MILLS_PER_HOUR - stampFromStart) * heightPerMs;
    this.hiddenAfternoon = gapAFTERNOON < (timeTextHeight / 2); // 是否显示下午
  }

  public updateGanttLineScale(scale: number) {
    this.gridCellHeight = this.oldGridCellHeight * scale;
  }

  public setOriginalGanttLineScale() {
    this.oldGridCellHeight = this.gridCellHeight;
  }
}

@Observed
export class GanttViewModel {
  public readonly GRID_MARGIN_TOP: number = 6;
  public readonly DEFAULT_ALL_DAY_FONT_HEIGHT_CN: number = 12;
  public readonly DEFAULT_ALL_DAY_FONT_HEIGHT_EN: number = 9;
  public readonly BLOCK_POP_MARGIN: number = 8;
  public readonly LINE_WIDTH: number = 0.5;
  public scroller: Scroller = new Scroller();
  public height: number = 584;
  public imgWidth: number = 20;
  public imgHeight: number = 10;
  public buttonPosition: Position = { x: 0, y: 0 };
  public scrollHeight: number = 560;
  public gridCellHeight: number = 60
  public gridWrapperHeight: number = 1480;
  public gridHeight: number = 1440;
  public allDayBlocks: ObservedArray<GanttBlockViewModel> = [];
  public normalBlocks: ObservedArray<GanttBlockViewModel> = [];
  public needShowTimeLine: boolean = false;
  public timeLinePositionY: number = 0;
  public timeStr: string = '00:00';
  public state: GanttViewStateModel = new GanttViewStateModel();
  public isShowButton: boolean = false;
  public isArrowDown: boolean = true;
  public showPopup: boolean = false;
  public isHoverPop: boolean = false;
  public hoverWidth: number = 1;
  public hoverHeight: number = 1;
  public ganttLineVM: GanttLineViewModel = new GanttLineViewModel();
  public addBlockVM: NewGanttBlockViewModel = new NewGanttBlockViewModel();
  public scrollOffsetY: number = 0;
  private readonly ALL_DAY_ROW_COUNT_ARROW_DOWN: number = 3;
  public maxAllDayRowCount: number = this.ALL_DAY_ROW_COUNT_ARROW_DOWN;
  private readonly ALL_DAY_ROW_COUNT_ARROW_UP: number = 6;
  public blockSpace: number = RootModel.instance().BLOCK_SPACE;
  private readonly BLOCK_SPACE_TOP: number = 4;
  public allDayBlockSpace: number = this.BLOCK_SPACE_TOP;
  private readonly BLOCK_BORDER_RADIUS_ADAPT: number = 4;
  private readonly BLOCK_BORDER_RADIUS_PHONE: number = 4;
  public blockBorderRadius: number = this.BLOCK_BORDER_RADIUS_PHONE;
  private readonly BLOCK_FOLD_WIDTH_ADAPT: number = 24;
  private readonly BLOCK_FOLD_WIDTH_PHONE: number = 15;
  private readonly BLOCK_MIN_WIDTH: number = 32;
  private readonly BLOCK_MARGIN_VERTICAL: number = 8;
  private readonly BLOCK_ALL_DAY_HEIGHT_ADAPT: number = 24;
  private readonly BLOCK_ALL_DAY_HEIGHT_PHONE: number = 20;
  private readonly BLOCK_PADDING: number = 4;
  public blockPadding: number = this.BLOCK_PADDING;
  private readonly WEEK_BLOCK_MAX_UNFOLD_PHONE: number = 2;
  private readonly DAY_BLOCK_MAX_UNFOLD_PHONE: number = 5;
  private readonly LINE_HEIGHT_ADAPT: number = 14;
  private readonly LINE_HEIGHT_PHONE: number = 14;
  public lineHeight: number = this.LINE_HEIGHT_PHONE;
  private readonly DEFAULT_ALL_DAY_HEIGHT_PHONE: number = 26;
  public allDayHeight: number = this.DEFAULT_ALL_DAY_HEIGHT_PHONE;
  private readonly DEFAULT_ALL_DAY_HEIGHT_ADAPT: number = 26;
  private rootVM: RootViewModel = new RootViewModel(0); // 这里的初始化值没有实际意义。
  private dayModelList: DayModel[] = [];
  private range: DateRange.Range = { start: 0, end: 0 };
  private originAgendaList: AgendaEventInfo[] = []; // 原始的日程数据
  private allDayAgendaList: AgendaEventInfo[] = []; // 全天日程数据(包含节假日)
  private normalAgendaList: AgendaEventInfo[] = []; // 单天的普通日程数据
  private blockFoldWidth: number = this.BLOCK_FOLD_WIDTH_PHONE;
  private blockMinWidth: number = this.BLOCK_MIN_WIDTH;
  private blockMarginVertical: number = this.BLOCK_MARGIN_VERTICAL;
  private blockAllDayHeight: number = this.BLOCK_ALL_DAY_HEIGHT_PHONE;
  private maxUnfoldBlocks: number = 2;
  private heightPerMs: number = 0;
  //甘特图缩放相关参数
  private readonly MIN_CELL_HEIGHT: number = 40; // 最小时间线高度
  private readonly MAX_CELL_HEIGHT: number = 150; // 最大时间线高度
  private showRowCount: number = 12; // 当前总显示时间行数
  private pinchPositionY: number = -1; // 捏合的高度值
  private pinchPositionHeight: number = -1; // 捏合高度值距离当前甘特图显示坐标的高度
  private oldShowRowCount: number = 12;
  private oldTimeLinePositionY: number = 0;
  private oldGridCellHeight: number = 0;
  private oldGridWrapperHeight: number = 0;
  private oldGridHeight: number = 0;
  private oldHeightPerMs: number = 0;
  private minScale: number = 0; // 当前缩放最小比例
  private maxScale: number = 0; // 当前缩放最大比例
  private nowScale: number = 1; // 当前缩放比例
  private updateScale: number = 1; // 本次缩放更新的比例
  private isInScale: boolean = false; // 是否正在更新

  private refreshTimer: number = -1;
  // 甘特图拖拽参数
  public ganttViewDropState: GanttViewDropState = new GanttViewDropState();
  // 甘特图间续框选参数
  public deleteAgendaBlocks: GanttBlockViewModel[] = [];
  public selectedAgendaBlocks: Set<GanttBlockViewModel> = new Set();
  public nowDeleteIndex: number = 0;
  public allDeletedRepeatEvent: Set<number> = new Set();
  public deleteAccountType: string = '';
  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  // 需要rootVM里的布局参数,周、日视图有不一致的参数，不适合使用单例。
  constructor(rootVM: RootViewModel) {
    this.rootVM = rootVM;
    if (!this.rootVM.isNeedAdapt()) {
      return;
    }

    this.blockBorderRadius = this.BLOCK_BORDER_RADIUS_ADAPT;
    this.blockFoldWidth = this.BLOCK_FOLD_WIDTH_ADAPT;
    this.blockAllDayHeight = this.BLOCK_ALL_DAY_HEIGHT_ADAPT;
    this.lineHeight = this.LINE_HEIGHT_ADAPT;
    this.allDayHeight = this.DEFAULT_ALL_DAY_HEIGHT_ADAPT;
  }

  onLanguageChange(language: string): void {
    this.allDayBlocks.forEach(block=>{
      block.onLanguageChange(language)
    })
  }

  destroy(): void {
    if (this.refreshTimer !== -1) {
      clearTimeout(this.refreshTimer);
    }
    PreferencesUtil.putNumberValueSync(PreferencesFiles.DEFAULT,
      RootModel.instance().GANTT_VIEW_SCALE_KEY, RootModel.instance().scale);
  }

  resetLayout(height: number): void {
    this.height = height;
    this.scrollHeight = height - this.allDayHeight;
    this.gridCellHeight = Math.max(Math.min(this.scrollHeight / this.showRowCount, this.MAX_CELL_HEIGHT),
      this.MIN_CELL_HEIGHT);
    this.ganttLineVM.gridCellHeight = this.gridCellHeight;
    this.gridHeight = this.gridCellHeight * HOURS_PER_DAY;
    this.gridWrapperHeight = this.gridHeight + this.GRID_MARGIN_TOP;
    this.heightPerMs = this.gridHeight / MILLS_PER_DAY;

    // pc下需要根据最小宽度适配最多不折叠日程块数量
    if (this.rootVM.isNeedAdapt()) {
      const blockNums = (this.rootVM.ganttCellWidth - this.blockSpace) / (this.blockSpace + this.blockMinWidth);
      this.maxUnfoldBlocks = Math.max(Math.floor(blockNums), 2);
    } else {
      this.maxUnfoldBlocks = this.rootVM.isWeekView() ? this.WEEK_BLOCK_MAX_UNFOLD_PHONE : this.DAY_BLOCK_MAX_UNFOLD_PHONE;
    }

    this.updateTimeLine();
    this.updateMorningAndAfternoon();
    this.updateAddAgendaBlock();
  }

  updateDayModels(list: DayModel[]): void {
    this.dayModelList = list;
    this.range = { start: list[0].range.start, end: list[list.length - 1].range.end };
    this.updateTimeLine();
  }

  updateBlocks(): void {
    Log.log(TAG, 'updateBlocks start');
    this.allDayBlocks = [];
    this.normalBlocks = [];
    this.splitAgenda();
    Log.log(TAG, 'updateAllDay start');
    this.updateAllDay();
    Log.log(TAG, 'resetLayout start');
    this.resetLayout(this.height);
    Log.log(TAG, 'updateNormal start');
    this.updateNormal();
    Log.log(TAG, 'updateNormal end normalBlock size : ' + this.normalBlocks.length);
    Log.log(TAG, 'clearSelect start');
    this.clearSelect();
    Log.log(TAG, 'calcNextRefresh start');
    this.calcNextRefresh();
    if (this.isInScale) {
      this.emitterGanttScale();
    }
    Log.log(TAG, 'updateBlocks end');
  }

  // 更新存储的日程过期状态
  updateBlocksExpired(): void {
    this.allDayBlocks.forEach((block) => {
      block.updateBlockExpired();
    });
    this.normalBlocks.forEach((block) => {
      block.updateBlockExpired();
    });
  }

  // 根据日程时间计算更新周期
  calcNextRefresh(): void {
    if (!DateRange.isDateInRange(Date.now(), this.range)) {
      return;
    }

    let minNotExpireEnd: number = Date.now();
    for (const item of this.normalBlocks) {
      if (item.getInfo().isOutDate()) {
        continue;
      }

      minNotExpireEnd = item.getInfo().mEnd;
      break;
    }

    for (const item of this.allDayBlocks) {
      if (item.getInfo().isOutDate()) {
        continue;
      }

      minNotExpireEnd = Math.min(item.getInfo().mEnd, minNotExpireEnd);
      break;
    }

    if (minNotExpireEnd === Date.now()) {
      return;
    }

    if (this.refreshTimer !== -1) {
      clearTimeout(this.refreshTimer);
    }

    this.refreshTimer = setTimeout(() => {
      this.updateBlocksExpired();
    }, minNotExpireEnd - Date.now());
  }

  // 通知AgendaDetail刷新
  eventToRefreshDetail(info: AgendaEventInfo) {
    let eventData: emitter.EventData = {
      data: {
        'eventId': info.mId,
        'displayStartMills': info.mBegin,
        'displayEndMills': info.mEnd,
        'sourceType': AgendaDetailSource.DAY_VIEW,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
  }

  getDefaultChosenInfo(): AgendaEventInfo | undefined {
    const needFocus: boolean = !this.rootVM.isWeekView() && this.rootVM.isDivide;
    if (!needFocus) {
      return undefined;
    }

    if (this.allDayBlocks.length) {
      this.clearBlocksFocus(this.allDayBlocks);
      this.allDayBlocks[0].isFocus = true;
      this.state.selectBlock = this.allDayBlocks[0];
      // 日视图日程块选中时，通知AgendaDetail刷新
      if (!this.rootVM.isWeekView()) {
        this.eventToRefreshDetail(this.allDayBlocks[0].getInfo());
      }
      return this.allDayBlocks[0].getInfo();
    }

    if (this.normalBlocks.length) {
      this.clearBlocksFocus(this.normalBlocks);
      this.normalBlocks[0].isFocus = true;
      this.state.selectBlock = this.normalBlocks[0];
      // 日视图日程块选中时，通知AgendaDetail刷新
      if (!this.rootVM.isWeekView()) {
        this.eventToRefreshDetail(this.normalBlocks[0].getInfo());
      }
      return this.normalBlocks[0].getInfo();
    }

    return undefined;
  }

  divideRefreshBlocksFocus(agendaId?: number, agendaTitle?: string): AgendaEventInfo | undefined {
    if (!agendaId) {
      return this.getDefaultChosenInfo();
    }
    if (this.allDayBlocks) {
      for (let i = 0; i < this.allDayBlocks.length; i++) {
        if (this.allDayBlocks[i].getInfo()?.mId === agendaId && this.allDayBlocks[i].getInfo()?.mTitle === agendaTitle && !this.allDayBlocks[i].isFold()) {
          this.clearBlocksFocus(this.allDayBlocks);
          this.allDayBlocks[i].isFocus = true;
          this.state.selectBlock = this.allDayBlocks[i];
          return this.allDayBlocks[i].getInfo();
        }
      }
    }
    if (this.normalBlocks) {
      for (let i = 0; i < this.normalBlocks.length; i++) {
        if (this.normalBlocks[i].getInfo()?.mId === agendaId && this.normalBlocks[i].getInfo()?.mTitle === agendaTitle && !this.normalBlocks[i].isFold()) {
          this.clearBlocksFocus(this.normalBlocks);
          this.normalBlocks[i].isFocus = true;
          this.state.selectBlock = this.normalBlocks[i];
          return this.normalBlocks[i].getInfo();
        }
      }
    }
    return this.getDefaultChosenInfo();
  }

  // 处理节假日
  handleFestival(): void {
    const filterTypes: FestivalType[] = [];
    if (!this.rootVM.isShowCalendar()) { // 暂时只有农历节假日
      filterTypes.push(FestivalType.SOLAR_TERM);
    }

    if (this.rootVM.getChineseHolidayState() === CHINESE_HOLIDAY_STATE_VALUE.CLOSE) {
      filterTypes.push(FestivalType.INTER);
      filterTypes.push(FestivalType.LUNAR_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_TAIWAN);
      filterTypes.push(FestivalType.OFFICIAL_HONGKONG);
    }

    if (!this.rootVM.isChineseRegion()) { // 其他地区不显示中国节假日
      filterTypes.push(FestivalType.LUNAR_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_TAIWAN);
      filterTypes.push(FestivalType.OFFICIAL_HONGKONG);
    }

    for (const dayModel of this.dayModelList) {
      for (const item of dayModel.festivals) {
        if (filterTypes.includes(item.type)) {
          continue;
        }
        if (AgendaModel.instance().checkHasSameHoliday(item.name)) {
          continue;
        }

        if (this.rootVM.getChineseHolidayState() === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN &&
          HolidayUtil.needRemoveHoliday(item.name) === '') {
            continue;
        }

        const info = new AgendaEventInfo();
        const selectDate = new CalendarDate(dayModel.range.start);
        // 适配时区将本地节假日设置为UTC时区的0点
        const stamp: number =
          new Date().setUTCFullYear(selectDate.getFullYear(), selectDate.getMonth(), selectDate.getDate());
        info.eventTimeZone = 'UTC';
        info.mIsHoliday = true;
        info.mIsAllDay = true;
        info.mTitle = item.name;
        info.mId = -1;
        info.mBegin = stamp;
        info.mEnd = info.mBegin + MILLS_PER_DAY;
        info.mDisplayColor = AccountColor.RED;
        this.allDayAgendaList.push(info);
      }
    }
  }

  public transClickPosition(eventX: number, eventY: number, isAllDay: boolean): Position {
    if (isAllDay) {
      return { x: eventX + this.rootVM.weekTitleVM.leftWidth, y: eventY };
    }

    const offsetY: number = this.getScrollOffsetY();

    return { x: eventX + this.rootVM.weekTitleVM.leftWidth, y: eventY - offsetY + this.allDayHeight };
  }

  public transPositionToStamp(x: number, y: number, isAllDay: boolean): number {
    const day = Math.floor(x / this.rootVM.ganttCellWidth);
    if (isAllDay) {
      return this.range.start + day * MILLS_PER_DAY;
    }

    const offsetY: number = this.getScrollOffsetY();

    const timeFromZero = (y / this.gridHeight) * MILLS_PER_DAY;
    return this.range.start + day * MILLS_PER_DAY + timeFromZero;
  }

  public getScrollOffsetY(): number {
    const offset: OffsetResult = this.scroller.currentOffset();
    if (!offset) {
      return this.range.start;
    }
    return offset.yOffset;
  }

  // 日程相交合并
  pushFoldInfoList(block: GanttBlockViewModel, infoList: AgendaEventInfo[],
                   preDrawnBlocks: Array<GanttBlockViewModel[]>, curCol: number) {
    for (let col = curCol + 1; col < preDrawnBlocks.length; col++) {
      for (const other of preDrawnBlocks[col]) {
        other.x = 0;
        if (!block.intersect(other)) {
          continue;
        }

        this.buildBlockIntersect(block, other);
        infoList.push(other.getInfo());
      }
    }
  }

  // 相交日程高度进行合并
  buildBlockIntersect(block: GanttBlockViewModel, other: GanttBlockViewModel) {
    block.y = Math.min(block.y, other.y);
    const endY = Math.max(block.y + block.height, other.y + other.height);
    block.height = endY - block.y;
  }

  isNowInRange(): boolean {
    return DateRange.isDateInRange(Date.now(), this.range);
  }

  updateTimeLine(): void {
    if (!this.isNowInRange()) {
      this.needShowTimeLine = false;
      return;
    }

    this.needShowTimeLine = true;
    this.setHourPosition();
    this.setCurHour();
  }

  setHourPosition(): void {
    if (!this.isNowInRange()) {
      this.ganttLineVM.hideLineInOtherRange();
      return;
    }

    const startOfDay = new CalendarDate().setHours(0, 0, 0, 0);
    const stampFromStart = Date.now() - startOfDay;
    this.timeLinePositionY = stampFromStart * this.heightPerMs + this.GRID_MARGIN_TOP;
    this.ganttLineVM.updateLineHidden(stampFromStart, this.rootVM.timeTextHeight, this.heightPerMs);
  }

  setCurHour(): void {
    if (!this.isNowInRange()) {
      return;
    }

    const curDate = new CalendarDate();
    const HOURS_HALF_DAY = HOURS_PER_DAY / 2;
    let hour = curDate.getHours();
    hour = (!RootModel.instance().is24HourClock && hour > HOURS_HALF_DAY) ? hour % HOURS_HALF_DAY : hour;
    const hourStr = RootModel.instance().is24HourClock ? hour.toString().padStart(2, '0') : hour;
    const minuteStr = curDate.getMinutes().toString().padStart(2, '0');
    this.timeStr = `${hourStr}:${minuteStr}`;
  }

  calcScrollOffsetY(): void {
    const startOfDay = new CalendarDate().setHours(0, 0, 0, 0);
    const now = Date.now();
    const gap = now - startOfDay - MILLS_PER_HOUR * 2;
    this.scrollOffsetY = Math.min(gap * this.heightPerMs, this.gridWrapperHeight - this.scrollHeight);
  }

  scrollToCurrentTime(): void {
    this.calcScrollOffsetY();
    this.scroller.scrollTo({ xOffset: 0, yOffset: this.scrollOffsetY });
  }

  onFlagChange(): void {
    this.isArrowDown = !this.isArrowDown;
    if (this.isArrowDown) {
      this.maxAllDayRowCount = this.ALL_DAY_ROW_COUNT_ARROW_DOWN;
    } else {
      this.maxAllDayRowCount = this.ALL_DAY_ROW_COUNT_ARROW_UP;
    }
    this.allDayBlocks = [];
    this.updateAllDay();
  }

  updateMorningAndAfternoon() {
    // 计算纵向时间线偏移并改变上下午时间线位置
    const offset: OffsetResult = this.scroller.currentOffset();
    //未取到值则直接跳过
    if (!offset || offset.yOffset === 0) {
      Log.info(TAG, `not get the scroll index !`);
      return;
    }
    Log.debug(TAG, `now scroll index ${offset.yOffset}`);
    //计算当前页面的坐标
    const nowY = Math.ceil((offset.yOffset || 0) / this.gridCellHeight) + 0.5;
    this.ganttLineVM.updateLinePosition(nowY);
    //隐藏时间线
    const startOfDay = new CalendarDate().setHours(0, 0, 0, 0);
    const stampFromStart = Date.now() - startOfDay;
    this.ganttLineVM.updateLineHidden(stampFromStart, this.rootVM.timeTextHeight, this.heightPerMs);
  }

  // 添加按钮显示
  showAddAgendaBlock(positionX: number, positionY: number) {
    this.initAddAgendaBlock(); // 初始化添加日程

    // 根据点击位置更新添加日程的显示位置
    const heightCount = Math.floor(positionY / this.gridCellHeight);
    const widthCount = Math.floor(positionX / this.rootVM.ganttCellWidth);

    this.addBlockVM.widthCount = widthCount;
    this.addBlockVM.heightStart = heightCount;
    this.addBlockVM.positionX = widthCount * this.rootVM.ganttCellWidth;
    this.addBlockVM.positionY = heightCount * this.gridCellHeight;
    this.addBlockVM.tabType = this.rootVM.tabType;
    this.addBlockVM.ganttStartTime = this.range.start;
    this.addBlockVM.updatePosition();

    this.addBlockVM.isAddShow = true;
  }

  // 隐藏添加日程
  hideAddAgendaBlock() {
    this.addBlockVM.width = this.rootVM.ganttCellWidth;
    this.addBlockVM.heightCount = 1;
    this.addBlockVM.height = this.gridCellHeight;
    this.addBlockVM.originalHeight = this.addBlockVM.height;
    this.addBlockVM.isAddShow = false;
  }

  // 更新添加日程的坐标和当前高度
  updateAddAgendaBlock() {
    this.addBlockVM.positionX = this.addBlockVM.widthCount * this.rootVM.ganttCellWidth;
    this.addBlockVM.positionY = this.addBlockVM.heightStart * this.gridCellHeight;
    this.addBlockVM.width = this.rootVM.ganttCellWidth;
    this.addBlockVM.height = this.gridCellHeight * this.addBlockVM.heightCount;
    this.addBlockVM.originalHeight = this.addBlockVM.height;
    this.addBlockVM.gridCellHeight = this.gridCellHeight;
    this.addBlockVM.ganttCellWidth = this.rootVM.ganttCellWidth;
  }

  // 初始化
  initAddAgendaBlock() {
    this.addBlockVM.width = this.rootVM.ganttCellWidth;
    this.addBlockVM.heightCount = 1;
    this.addBlockVM.height = this.gridCellHeight * this.addBlockVM.heightCount;
    this.addBlockVM.originalHeight = this.addBlockVM.height;
    this.addBlockVM.gridCellHeight = this.gridCellHeight;
    this.addBlockVM.ganttCellWidth = this.rootVM.ganttCellWidth;
  }

  // 根据当前缩放值更新甘特图
  updateGanttViewScale(scale: number, needUpdate: boolean = false) {
    if (!this.isInScale && !needUpdate) {
      return;
    }
    const newScale = Math.min(Math.max(scale, this.minScale), this.maxScale);
    this.updateScale = newScale;
    if (this.updateScale === this.nowScale) {
      return;
    }
    this.timeLinePositionY = this.oldTimeLinePositionY * newScale;
    this.gridCellHeight = this.oldGridCellHeight * newScale;
    this.gridWrapperHeight = this.oldGridWrapperHeight * newScale;
    this.gridHeight = this.oldGridHeight * newScale;
    this.showRowCount = this.oldShowRowCount / newScale;
    this.heightPerMs = this.oldHeightPerMs * newScale;
    if (this.pinchPositionHeight !== -1) {
      const moveOffsetY = this.pinchPositionY * newScale - this.pinchPositionHeight;
      this.scroller.scrollTo({ xOffset: 0, yOffset: moveOffsetY });
    }

    this.ganttLineVM.updateGanttLineScale(newScale);
    this.addBlockVM.updateGanttViewScale(newScale);
    this.normalBlocks.forEach((block) => {
      block.updateGanttViewScale(newScale);
      block.reCalculateMaxLines();
    })
  }

  getCurrentTime(is24Hour: boolean): string {
    const curDate = new CalendarDate();
    let hour = curDate.getHours();
    const HOURS_HALF_DAY = HOURS_PER_DAY / 2;
    hour = (!is24Hour && hour > HOURS_HALF_DAY) ? hour % HOURS_HALF_DAY : hour;
    const hourStr = is24Hour ? hour.toString().padStart(2, '0') : hour;
    const minuteStr = curDate.getMinutes().toString().padStart(2, '0');
    return `${hourStr}:${minuteStr}`;
  }

  // 初始化以及在缩放结束时更新值以用于下次缩放
  initOriginalGanttViewScale(isInScale: boolean = true, positionY: number = -1) {
    this.isInScale = isInScale;
    this.nowScale = this.nowScale * this.updateScale;
    this.updateScale = 1;
    this.oldTimeLinePositionY = this.timeLinePositionY;
    this.oldGridCellHeight = this.gridCellHeight;
    this.oldGridWrapperHeight = this.gridWrapperHeight;
    this.oldGridHeight = this.gridHeight;
    this.oldShowRowCount = this.showRowCount;
    this.oldHeightPerMs = this.heightPerMs;
    this.minScale = this.MIN_CELL_HEIGHT / this.oldGridCellHeight;
    this.maxScale = this.MAX_CELL_HEIGHT / this.oldGridCellHeight;
    this.ganttLineVM.setOriginalGanttLineScale();
    this.addBlockVM.setOriginalGanttViewScale();
    this.normalBlocks.forEach((block) => {
      block.setOriginalGanttViewScale();
    })
    // 用来记录当前缩放的中心位置,用于固定缩放的位置
    if (positionY === -1) {
      this.pinchPositionY = -1;
      return;
    }
    this.pinchPositionY = positionY;
    const offset: OffsetResult = this.scroller.currentOffset();
    if (!offset) {
      this.pinchPositionHeight = -1;
      return;
    }
    this.pinchPositionHeight = this.pinchPositionY - offset.yOffset;
  }

  emitterGanttScale() {
    this.isInScale = false;
    RootModel.instance().scale = this.nowScale * this.updateScale;

    const eventData: emitter.EventData = {
      data: {
        'scale': this.updateScale,
        'pinchY': this.pinchPositionY,
        'tabType': this.rootVM.tabType,
      }
    };
    Log.info(TAG, `emiiter gantt scale ${this.updateScale} ${this.pinchPositionY}`);
    emitter.emit({ eventId: CommonInnerEvent.WEEK_SCALE_CHANGE }, eventData);
  }

  private clearSelect() {
    this.clearPop();
    //清除选中日程
    this.state.selectBlock = undefined;
  }

  public clearPop() {
    //清除弹窗
    this.showPopup = false;
    this.isHoverPop = false;
  }

  public resetFocus() {
    SafeUtil.setTimeout(() => {
      focusControl.requestFocus(CompId.SLIDE_TAB_BAR); // hover态取消后会丢失焦点,需要重新获焦防止方向键无法连续触发
    }, 300)
  }

  private clearBlocksFocus(blocks: ObservedArray<GanttBlockViewModel>) {
    blocks.forEach((block: GanttBlockViewModel) => {
      block.clearFocus();
    })
  }

  private splitAgenda(): void {
    this.originAgendaList = AgendaModel.instance().getAgendaByRange(this.range);
    Log.info(TAG, `start: ${this.range.start} end: ${this.range.end}, originAgendaList : ${this.originAgendaList.length}`);
    this.normalAgendaList = [];
    this.allDayAgendaList = [];
    // 分组
    for (const info of this.originAgendaList) {
      if (!info.mIsAllDay &&
        info.mImportantEventType === CalendarContract.EventImportantType.NORMAL &&
        (info.mEnd - info.mBegin) < MILLS_PER_DAY) {
        this.normalAgendaList.push(info);
      } else {
        this.allDayAgendaList.push(info);
      }
    }
    Log.info(TAG, `allDayAgendaList : ${this.allDayAgendaList.length}, normalAgendaList: ${this.normalAgendaList.length}`);
    this.handleFestival();

    this.allDayAgendaList = this.sortAgendaList(this.allDayAgendaList, true);
    this.normalAgendaList = this.sortAgendaList(this.normalAgendaList, false);
  }

  private sortAgendaList(list: AgendaEventInfo[], isAllDay: boolean = false): AgendaEventInfo[] {
    const getTitle = (item: AgendaEventInfo): string => {
      return item.mTitle ?? '';
    };

    return list.sort((a: AgendaEventInfo, b: AgendaEventInfo) => {
      if (a.isHoliday() && b.isHoliday()) {
        // 标题排序
        if (a.mTitle === b.mTitle) {
          return 0;
        }
        if (a.mTitle === '入九' && b.mTitle === '冬至') {
          return 1;
        }
        return a.mTitle < a.mTitle ? -1 : 1;
      }
      const getAgendaRank = (item: AgendaEventInfo): number => {
        if (!item.mIsAllDay && (item.mEnd - item.mBegin) >= MILLS_PER_DAY) {
          return 0;
        }
        if (item.isHoliday()) {
          return 1;
        }
        return 2;
      };
      const rankA: number = getAgendaRank(a);
      const rankB: number = getAgendaRank(b);
      if (rankA !== rankB) {
        return rankA - rankB;
      }
      // 真正全天日程按日期排序，跨天日程保留实际开始时间
      const startA: number = isAllDay && a.mIsAllDay ? DateUtil.getStartOfDayTimeStamp(a.mBegin) : a.mBegin;
      const startB: number = isAllDay && b.mIsAllDay ? DateUtil.getStartOfDayTimeStamp(b.mBegin) : b.mBegin;
      if (startA !== startB) {
        return startA - startB;
      }
      const endA: number = isAllDay && a.mIsAllDay ? DateUtil.getStartOfDayTimeStamp(a.mEnd) + MILLS_PER_DAY : a.mEnd;
      const endB: number = isAllDay && b.mIsAllDay ? DateUtil.getStartOfDayTimeStamp(b.mEnd) + MILLS_PER_DAY : b.mEnd;
      if (endA !== endB) {
        return endB - endA;
      }
      return getTitle(a).localeCompare(getTitle(b));
    });
  }

  private updateAllDay(): void {
    const drawnBlocks: Array<GanttBlockViewModel[]> = [];
    const foldInfoList: Array<AgendaEventInfo[]> = Array.from(
      new Array<AgendaEventInfo[]>(this.rootVM.gridColCount),
      () => new Array<AgendaEventInfo>()
    );
    let maxRow: number = 1;
    Log.info(TAG, 'updateAllDay start');
    const nowOffset = new CalendarDate().getTimeOffset();
    for (const info of this.allDayAgendaList) {
      const row = this.handleAllDayUnfoldBlock(info, foldInfoList, drawnBlocks, nowOffset);
      maxRow = Math.max(maxRow, row + 1);
    }
    Log.info(TAG, 'handleAllDayUnfoldBlocks end allDayBlock size : ' + this.allDayBlocks.length);

    this.isShowButton = this.allDayAgendaList.length > 3 && maxRow > 3 ? true : false;

    const rowCount = Math.min(maxRow, this.maxAllDayRowCount);
    this.allDayHeight = (this.blockAllDayHeight + this.allDayBlockSpace) * rowCount - this.allDayBlockSpace + this.blockMarginVertical * 2;

    this.buttonPosition = {
      x: this.rootVM.weekTitleVM.leftWidth / 2 - this.imgWidth / 2,
      y: this.allDayHeight - this.blockMarginVertical - this.blockAllDayHeight / 2 - this.rootVM.allDayTitleFontSize / 2,
    };

    // 如果最大行数小于预设的全天最大行数，则不需要处理折叠日程块
    if (maxRow <= this.maxAllDayRowCount) {
      Log.info(TAG, 'updateAllDay return');
      return;
    }
    Log.info(TAG, 'handleAllDayFoldBlocks start');
    this.handleAllDayFoldBlocks(foldInfoList, drawnBlocks[this.maxAllDayRowCount - 1]);
    Log.info(TAG, 'handleAllDayFoldBlocks end allDayBlock size : ' + this.allDayBlocks.length);
  }

  /**
   * 处理全天非折叠日程信息
   * @param info 当前日程信息
   * @param foldInfoList 已折叠的日程信息
   * @param drawnBlocks 需要绘制的日程列表
   * @param nowOffset 当前锁定时区的偏移
   * @returns
   */
  private handleAllDayUnfoldBlock(info: AgendaEventInfo, foldInfoList: Array<AgendaEventInfo[]>,
    drawnBlocks: Array<GanttBlockViewModel[]>, nowOffset: number): number {
    const block: GanttBlockViewModel = new GanttBlockViewModel();
    let begin = info.mBegin;
    let end = info.mEnd;
    if (info.mIsAllDay && info.eventTimeZone) {
      //全天日程采用UTC时区存储,需要计算偏移量 --welink会插入非UTC时区的全天日程,故需要获取时区计算偏移量,额外添加锁定时区的偏移量
      const zoneOffset = I18nUtil.getTimeZoneOffsetById(info.eventTimeZone);
      begin = begin - zoneOffset + nowOffset;
      // 全天日程end为UTC时间的24点，会被计算为下一天0点，故处理时减去1ms再进行计算
      end = end - zoneOffset - 1 + nowOffset;
    }
    const startStamp: number = Math.max(begin, this.range.start);
    const endStamp: number = Math.min(end, this.range.end);
    const startIndex: number = Math.floor((startStamp - this.range.start) / MILLS_PER_DAY);
    const isSameAllDay = info.mIsAllDay && info.mStartDay == info.mEndDay;
    const endIndex: number =
      isSameAllDay ? (startIndex + 1) : Math.ceil((endStamp - this.range.start) / MILLS_PER_DAY);
    const x: number = startIndex * this.rootVM.ganttCellWidth + this.blockSpace;
    const y: number = this.blockMarginVertical;
    const width: number = (endIndex - startIndex) * this.rootVM.ganttCellWidth;
    const height: number = this.blockAllDayHeight;
    block.setRect(x, y, width, height);
    block.tabType = this.rootVM.tabType;
    // 尝试放下当前日程块
    let row = 0;
    for (; row <= drawnBlocks.length; row++) {
      // 创建新的一行
      if (!drawnBlocks[row]) {
        drawnBlocks[row] = [block];
        break;
      }

      if (!this.isIntersect(block, drawnBlocks[row])) {
        drawnBlocks[row].push(block);
        break;
      }

      block.y += this.blockAllDayHeight + this.allDayBlockSpace;
    }

    // 如果当前行大于等于最大行数，将日程信息存入折叠块信息缓存
    if (row >= this.maxAllDayRowCount - 1) {
      for (let i = startIndex; i < endIndex; i++) {
        if (i < foldInfoList.length) {
          foldInfoList[i].push(info);
        }
      }
    }

    // 只需保存最大行数的block信息
    if (row <= this.maxAllDayRowCount - 1 && this.needShowEvent(info)) {
      block.setInfo(info, this.lineHeight, true);
      this.allDayBlocks.push(block);
    }

    return row;
  }

  //过滤需要显示在周视图界面的日程type
  private needShowEvent(info: AgendaEventInfo): boolean {
    return info.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
      info.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY ||
    info.isImportantEvent();
  }

  // 处理折叠日程块
  private handleAllDayFoldBlocks(foldInfoList: Array<AgendaEventInfo[]>, lastRow: GanttBlockViewModel[]): void {
    const y = this.blockMarginVertical + (this.blockAllDayHeight + this.allDayBlockSpace) * (this.maxAllDayRowCount - 1);
    for (let col = 0; col < foldInfoList.length; col++) {
      const foldInfo = foldInfoList[col];
      let infoList: AgendaEventInfo[] = []
      foldInfo.forEach(info => {
        if (this.needShowEvent(info)) {
          infoList.push(info)
        }
      })
      if (infoList.length === 0) {
        continue;
      }

      const block = new GanttBlockViewModel();
      const x: number = col * this.rootVM.ganttCellWidth + this.blockSpace;
      block.setRect(x, y, this.rootVM.ganttCellWidth, this.blockAllDayHeight);
      block.tabType = this.rootVM.tabType;
      block.isAllDayAgenda = true;
      block.setFoldInfo(infoList, this.lineHeight);
      this.allDayBlocks.push(block);
      this.clearIntersectBlocksWidthFoldBlock(block, lastRow);
    }
  }

  // 清理与折叠日程块冲突的非折叠日程块
  private clearIntersectBlocksWidthFoldBlock(foldBlock: GanttBlockViewModel, lastRow: GanttBlockViewModel[]): void {
    for (const block of lastRow) {
      if (!block.intersect(foldBlock) || block.isFold()) {
        continue;
      }

      this.allDayBlocks.splice(this.allDayBlocks.indexOf(block), 1);
      lastRow.splice(lastRow.indexOf(block), 1);
    }
  }

  // 是否可在当前行/列放下
  private isIntersect(block: GanttBlockViewModel, rowOrCol: GanttBlockViewModel[]): boolean {
    for (const drawnBlock of rowOrCol) {
      if (drawnBlock.intersect(block)) {
        return true;
      }
    }

    return false;
  }

  private updateNormal(): void {
    const groupList = this.groupAgendaList(this.normalAgendaList);
    const beginTime: number = Date.now();
    for (const group of groupList) {
      this.handleNormalGroup(group);
    }
    const costTime: number = Date.now() - beginTime;
    const logThresholdTime: number = 30;
    if (costTime > logThresholdTime) {
      Log.info(TAG, `updateNormal do group cost ${costTime}ms for ${groupList.length} groups`);
    }
  }

  // 按日程的时间区间是否相交进行分组
  private groupAgendaList(list: AgendaEventInfo[]): Array<AgendaEventInfo[]> {
    const groupList: Array<AgendaEventInfo[]> = [];

    let i = 0;
    while (i < list.length) {
      const group = [list[i]];
      let end: number = list[i].mEnd;
      let j = i + 1;

      while (j < list.length && list[j].mBegin < end) {
        group.push(list[j]);

        if (list[j].mEnd > end) {
          end = list[j].mEnd;
        }
        j++;
      }

      i = j;
      groupList.push(group);
    }

    return groupList;
  }

  private handleNormalGroup(group: AgendaEventInfo[]): void {
    const initBlocks = this.initNormalBlocks(group);
    const preDrawnBlocks = this.preDrawNormalBlocks(initBlocks);

    if (preDrawnBlocks.length <= this.maxUnfoldBlocks) {
      this.handleGroupNotFold(preDrawnBlocks);
    } else {
      this.handleGroupNeedFold(preDrawnBlocks);
    }
  }

  private initNormalBlocks(infoList: AgendaEventInfo[]): GanttBlockViewModel[] {
    const initBlocks: GanttBlockViewModel[] = [];

    for (const info of infoList) {
      const block: GanttBlockViewModel = new GanttBlockViewModel();
      const start: number = Math.max(info.mBegin, this.range.start) - this.range.start;
      const end: number = Math.min(info.mEnd, this.range.end) - this.range.start;
      block.x = 0;
      block.y = start * this.heightPerMs;
      block.width = this.blockMinWidth;
      // 最小时间跨度为十分钟，保证甘特图能显示
      const height = (end - start) > TEN_MINUTE_MILLS ? (end - start) : TEN_MINUTE_MILLS;
      block.height = height * this.heightPerMs;
      block.tabType = this.rootVM.tabType;
      block.setInfo(info, this.lineHeight);
      initBlocks.push(block);
    }

    return initBlocks;
  }

  private preDrawNormalBlocks(initBlocks: GanttBlockViewModel[]): Array<GanttBlockViewModel[]> {
    const drawnBlocks: Array<GanttBlockViewModel[]> = [];
    const maxColumns: number = this.maxUnfoldBlocks;
    for (const block of initBlocks) {
      for (let col = 0; col <= drawnBlocks.length; col++) {
        if (col >= maxColumns) {
          if (!drawnBlocks[col]) {
            drawnBlocks[col] = [block];
          } else {
            drawnBlocks[col].push(block);
          }
          break;
        }
        if (!drawnBlocks[col]) {
          drawnBlocks[col] = [block];
          break;
        }

        if (!this.isIntersect(block, drawnBlocks[col])) {
          drawnBlocks[col].push(block);
          break;
        }

        block.x += this.blockMinWidth;
      }
    }
    return drawnBlocks;
  }

  private handleGroupNeedFold(preDrawnBlocks: Array<GanttBlockViewModel[]>): void {
    const unfoldWidth = (this.rootVM.ganttCellWidth - this.blockSpace * 2 - this.blockFoldWidth) / (this.maxUnfoldBlocks - 1) - this.blockSpace;

    // 折叠块前maxUnfoldBlocks - 1列，同无需折叠的处理流程
    for (let col = 0; col < this.maxUnfoldBlocks - 1; col++) {
      for (const block of preDrawnBlocks[col]) {
        this.handleGroupBlockItem(block, col, unfoldWidth);
      }
    }

    // 处理折叠日程块,按可显示的最后一列来处理
    const curCol = this.maxUnfoldBlocks - 1;
    const foldCol = preDrawnBlocks[curCol];
    this.handleFoldBlockInfo(foldCol, preDrawnBlocks, curCol, unfoldWidth);
  }

  private handleFoldBlockInfo(foldBlocks: GanttBlockViewModel[], preDrawnBlocks: Array<GanttBlockViewModel[]>,
                              curCol: number, unfoldWidth: number) {
    const finishBlocks: GanttBlockViewModel[] = []; // 合并完成待绘制的block
    for (const curBlock of foldBlocks) {
      // 存在未相交的日程在折叠后相交,故需要重复已合并日程进行判断
      let flag = false;
      for (const foldBlock of finishBlocks) {
        curBlock.x = foldBlock.x;
        if (!curBlock.intersect(foldBlock)) {
          continue;
        }
        const foldList = foldBlock.getInfoList();

        this.buildBlockIntersect(foldBlock, curBlock);
        foldList.push(curBlock.getInfo());
        foldBlock.setFoldInfo(foldList, this.lineHeight);
        flag = true;
        break;
      }

      // arkTs不支持continue指定循环,故使用此标志位用于判断是否需要执行后续逻辑
      if (flag) {
        continue;
      }

      const infoList = [curBlock.getInfo()];
      const block = new GanttBlockViewModel();
      block.setRect(0, curBlock.y, curBlock.width, curBlock.height);

      this.pushFoldInfoList(block, infoList, preDrawnBlocks, curCol);

      block.tabType = this.rootVM.tabType;
      block.setFoldInfo(infoList, this.lineHeight);
      // 将已经合并的block放置于已合并完成的数组用于后续判断是否相交
      finishBlocks.push(block);
    }
    // 最后再对合并好的block进行初始化
    for (let foldBlock of finishBlocks) {
      this.handleGroupBlockItem(foldBlock, curCol, unfoldWidth, false);
    }
  }

  private handleGroupNotFold(preDrawnBlocks: Array<GanttBlockViewModel[]>): void {
    const unfoldWidth = (this.rootVM.ganttCellWidth - this.blockSpace) / preDrawnBlocks.length - this.blockSpace;
    for (let col = 0; col < preDrawnBlocks.length; col++) {
      for (const block of preDrawnBlocks[col]) {
        this.handleGroupBlockItem(block, col, unfoldWidth);
      }
    }
  }

  private handleGroupBlockItem(block: GanttBlockViewModel, col: number, blockWidth: number, isUnfoldBlock: boolean = true): void {
    const startDayCol: number = Math.floor(block.y / this.gridHeight);
    const endDayCol: number = Math.floor((block.y + block.height) / this.gridHeight);
    const isSameDay: boolean = startDayCol === endDayCol;
    const startX: number = startDayCol * this.rootVM.ganttCellWidth;
    const originHeight: number = block.height;

    block.x = startX + col * (blockWidth + this.blockSpace) + this.blockSpace;
    block.y = block.y % this.gridHeight + this.blockSpace + (this.LINE_WIDTH / 2);
    block.width = isUnfoldBlock ? blockWidth : this.blockFoldWidth;
    this.normalBlocks.push(block);

    // 跨天日程需要克隆一份到另一个网格列
    if (isSameDay || endDayCol >= this.rootVM.gridColCount) {
      block.calculateMaxLines(); //高宽变化需要重新触发文字显示计算
      return;
    }

    // 设置当前高度
    block.height = this.gridHeight - block.y;
    block.calculateMaxLines(); //高宽变化需要重新触发文字显示计算

    const expandBlock = block.clone();
    expandBlock.x = block.x + this.rootVM.ganttCellWidth;
    expandBlock.y = this.blockSpace;
    expandBlock.width = block.width;
    expandBlock.height = originHeight - block.height;
    expandBlock.calculateMaxLines(); //高宽变化需要重新触发文字显示计算
    this.normalBlocks.push(expandBlock);
  }

  public async onGanttBlockDrop(changeType: number = ChangeMode.ALL_AGENDAS) {
    Log.info(TAG, 'rowIndex ' + this.ganttViewDropState.dropRow)
    Log.info(TAG, 'colIndex ' + this.ganttViewDropState.dropCol)

    const eventInfo = this.ganttViewDropState.dropEventInfo;
    if (!eventInfo) {
      return;
    }
    const duration = eventInfo.mEnd - eventInfo.mBegin;
    // 获取拖拽放置后的时间戳
    const dayTimeStamp = this.range.start + MILLS_PER_DAY * this.ganttViewDropState.dropCol;
    const startTime = dayTimeStamp + this.ganttViewDropState.dropRow * MILLS_PER_HOUR

    Log.info(TAG, `before event beginTime  ${eventInfo.mBegin}`)
    eventInfo.mBegin = startTime;
    eventInfo.mEnd = startTime + duration;
    Log.info(TAG, `after drop event beginTime  ${eventInfo.mBegin}`)

    if (changeType == ChangeMode.ONLY_THIS_AGENDA) {
      this.dropThisAgenda(eventInfo, this.ganttViewDropState.dropEventInstanceStartMill)
    } else if (changeType == ChangeMode.THIS_AND_FUTURE_AGENDA) {
      this.dropThisAgendaAndBeyond(eventInfo, this.ganttViewDropState.dropEventInstanceStartMill)
    } else {
      this.dropNormalAgenda(eventInfo)
    }
  }

  /**
   *
   * @param eventInfo 需要更新的event
   * @returns 处理后适用于数据库操作的Record
   */
  getPostValue(eventInfo: AgendaEventInfo): Record<string, string | Number> {
    // 普通日程时间处理
    let dtStart: number = eventInfo.mBegin;
    let dtEnd: number = eventInfo.mEnd;
    const value: Record<string, string | Number> = {
      'title': eventInfo.mTitle,
      'dtstart': DateUtil.changeToUTCTime(dtStart),
      'dtend': DateUtil.changeToUTCTime(dtEnd),
      'calendar_id': eventInfo.mCalendarId,
      // 存储系统当前时区, 默认上海'Asia/Shanghai'
      'eventTimezone': eventInfo.mIsAllDay ? 'UTC' : I18nUtil.getSystemTimeZone(),
      'description': eventInfo.mDescription.length === 0 ? '' : eventInfo.mDescription,
      'allDay': eventInfo.mIsAllDay ? 1 : 0,
      'eventLocation': eventInfo.mLocation.length === 0 ? '' : eventInfo.mLocation,
      'important_event_type': eventInfo.mImportantEventType,
      'event_time_stamp': Date.now(),
      'rrule': eventInfo.mRepeatRule,
      'event_calendar_type': eventInfo.mEventCalendar,
      'hwext_alert_type': eventInfo.alertType
    };

    return value;
  }

  // drop重复日程仅此日程逻辑
  async dropThisAgenda(eventInfo: AgendaEventInfo, instanceStartMills: number) {
    const isDeleted = await addExDateToDb(eventInfo.mId, instanceStartMills);
    eventInfo.mRepeatRule = '';

    const value: Record<string, string | Number> = this.getPostValue(eventInfo);

    if (isDeleted) {
      const eventId = await EventService.INSTANCE.insertEvent(value)
      let isSucceed = !!eventId;
      let checkValuesArrays =
        await ReminderService.INSTANCE.queryReminderInfo(eventInfo.mId) as Array<CalendarContract.Reminders>;
      if (checkValuesArrays.length > 0) {
        isSucceed = isSucceed && await EventService.INSTANCE.insertReminder(eventId, checkValuesArrays) as boolean;
      }
      if (!isSucceed) {
        Log.warn(TAG, 'insertReminder failed');
      }
    } else {
      Log.warn(TAG, 'delete in editThisAgenda failed');
    }
  }

  // drop重复日程此日程和未来日程逻辑
  async dropThisAgendaAndBeyond(eventInfo: AgendaEventInfo, instanceStartMills: number) {
    const isDeleted = await updateUntilToDb(eventInfo.mId, instanceStartMills);
    const value: Record<string, string | Number> = this.getPostValue(eventInfo);
    if (isDeleted) {
      const eventId = await EventService.INSTANCE.insertEvent(value)
      let isSucceed = !!eventId;
      let checkValuesArrays =
        await ReminderService.INSTANCE.queryReminderInfo(eventInfo.mId) as Array<CalendarContract.Reminders>;
      if (checkValuesArrays.length > 0) {
        isSucceed = isSucceed && await EventService.INSTANCE.insertReminder(eventId, checkValuesArrays) as boolean;
      }
      if (!isSucceed) {
        Log.warn(TAG, 'insertReminder failed');
      }
    } else {
      Log.warn(TAG, 'delete in editThisAgendaAndBeyond failed');
    }
  }

  // drop常规日程
  async dropNormalAgenda(eventInfo: AgendaEventInfo) {
    const value: Record<string, string | Number> = this.getPostValue(eventInfo);

    const isSucceed: boolean = await EventService.INSTANCE.updateEventAndReminder(
      eventInfo.mId, [], false, value, 0) as boolean;
    if (!isSucceed) {
      Log.error(TAG, 'update event error');
      return false;
    }
    return true;
  }

  // 删除重复日程仅此日程逻辑
  async deleteThisAgenda() {
    const instance = this.deleteAgendaBlocks[this.nowDeleteIndex].getInfo();

    if (!instance) {
      return;
    }
    const isDeleted = await addExDateToDb(instance.mId, instance.mBegin);
    if (isDeleted) {
      this.mAgendaOperateHelper.eventToSoftDelete(instance.mId, instance.mBegin);
    }
  }

  // 删除重复日程此日程和未来日程逻辑
  async deleteThisAgendaAndBeyond() {
    const instance = this.deleteAgendaBlocks[this.nowDeleteIndex].getInfo();

    if (!instance) {
      return;
    }
    const isDeleted = await updateUntilToDb(instance.mId, instance.mBegin);
    if (isDeleted) {
      this.mAgendaOperateHelper.eventToSoftDelete(instance.mId, instance.mBegin);
    }
  }

  // 删除常规日程
  async deleteNormalAgenda() {
    const instance = this.deleteAgendaBlocks[this.nowDeleteIndex].getInfo();
    if (!instance) {
      return;
    }
    if (instance.mId) {
      const rowsDeleted = await EventService.INSTANCE.deleteEventById(instance.mId) as number;
      if (rowsDeleted <= 0) {
        Log.warn(TAG, 'delete by id fail');
      }
    }
  }
}

export class GanttViewDropState {
  public dropEventInfo: AgendaEventInfo = new AgendaEventInfo();
  public dropCol: number = 0;
  public dropRow: number = 0;
  public dropEventId: number = 0;
  public dropEventInstanceStartMill = 0;
  public ganttViewX = 0;
}
