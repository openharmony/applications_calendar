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
  AgendaEventInfo,
  CalendarDate,
  CHINESE_HOLIDAY_STATE_VALUE,
  CompId,
  DateUtil,
  DeviceConfig,
  FestivalDay,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  HolidayUtil,
  I18nUtil,
  isChineseCalendar,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_WEEK,
  SafeUtil,
  traceEvents
} from '@app/common';
import { SingleWeekViewModel } from './SingleWeekViewModel';
import { ObservedArray } from '@app/common/src/main/ets/templates/ObservedArray';
import { MonthlyViewState, MonthlyViewStateManager } from './MonthlyViewState';
import { SingleDayViewModel } from './SingleDayViewModel';
import { FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { FrameLayout, WeekAgendaLayout } from '../layoutmodel/FrameLayoutRule';
import util from '@ohos.util';
import { PaintCache } from '@app/common/src/main/ets/graphic/PaintCache';
import { common2D, drawing, text } from '@kit.ArkGraphics2D';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
// import { systemShare } from '@kit.ShareKit'; // ShareKit 注释
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { AgendaBlockStateManagement, WeekAgendaState } from './WeekAgendaState';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import i18n from '@ohos.i18n';
import { fontName, MonthPaintCache } from '../utils/MonthPaintCache';

const TAG: string = '[MonthlyView][WeekAgendaBlockModel]';

//竖线的宽度 2vp
const barWidth = 2;
//日程块与下一个日程块的间隔
const agendaBlockMargin = 2;
//圆角半径 4vp
const blockMarginRadii = 4;
//竖线和日程块标题文字之间的距离 2vp
const barTextMargin = 2;
//标题文字离右边边距 1vp
const textMargin = 1;

@Observed
export class WeekAgendaBlockModel extends DrawModifier {
  // 持有的日视图数据
  private weekVM: SingleWeekViewModel;
  // 当月最后一天的时间戳
  private lastDayInCurMonth: number = 0;
  // 当月第一天的时间戳
  private firstDayInCurMonth: number = 0;
  // 单周的日程
  private sigWeekAgendas: AgendaEventInfo[] = [];
  // 单周的节假日程
  private sigWeekHoliday: string[] = [];
  // 日程块的装填状态
  private blockState: number[][] = [];
  // 月视图的布局单例
  private lastRow: number = 0;

  public blocks: ObservedArray<AgendaBlockInfo> = new ObservedArray<AgendaBlockInfo>();

  // 存储当前锁定时区偏移量
  private nowTimeZoneOffset: number = 0;

  private chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE | undefined =
    AppStorage.get('CHINESE_HOLIDAY_STATE') ?? CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;
  private agendaBlockState: AgendaBlockStateManagement = WeekAgendaState.getInstance().agendaBlockState;
  public cellWidth: number = 0;
  //周的高度（日期+日程块区域的高度）
  public weekHeight: number = 0;
  public readonly blockHeight = DeviceConfig.instance().config.monthAgendaBlockHeight;
  private readonly agendaBlockTopMargin = 2; //日程块之间的间距
  private readonly firstAgendaBlockTopMargin = 1.5; //第一个日程块与日期区域的间距
  private readonly agendaBlockLeftMargin = 2; //日程块距离左边的间距
  private agendaBlockSize = DeviceConfig.instance().config.agendaBlockFontSize;
  private layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  private weekNumInd: number = -1;
  public isFocused: boolean = false;
  private language: string | undefined = AppStorage.get(GlobalDataKeys.LANGUAGE);
  private isRTL: boolean = i18n.isRTL(this.language); // 是否是镜像语言

  constructor(weekVM: SingleWeekViewModel, weekNumInd: number) {
    super();
    this.weekVM = weekVM;
    this.initBlockState();
    this.weekNumInd = weekNumInd;
  }

  // 通知视图层，日程块内容变更
  onBlocksChange(blocks: ObservedArray<AgendaBlockInfo>) {
    let newBlocks: AgendaBlockInfo[] = [];
    blocks.forEach((block: AgendaBlockInfo) => {
      if (block.isVisible) {
        newBlocks.push(block);
      }
    })
    this.blocks = newBlocks;
  }

  update() {
    this.initBlockState();
  }

  /**
   * 初始化日程块状态矩阵
   */
  initBlockState() {
    this.blockState = [];
    for (let i = 0; i < this.lastRow; i++) {
      let blocks: number[] = [];
      for (let j = 0; j < 7; j++) {
        blocks.push(-1);
      }
      this.blockState.push(blocks);
    }

    // 记录当月的第一天和最后一天的最后一刻
    this.lastDayInCurMonth = DateUtil.dateToStamp(this.weekVM.dateInfo.year,
      this.weekVM.dateInfo.month, 0) + MILLS_PER_DAY - 1;
    this.firstDayInCurMonth = DateUtil.dateToStamp(this.weekVM.dateInfo.year,
      this.weekVM.dateInfo.month - 1, 1);
    Log.debug(TAG, 'this.firstDayInCurMonth = ' + this.firstDayInCurMonth + ', this.lastDayInCurMonth = ' +
      this.lastDayInCurMonth);
  }

  /**
   * 处理每周的日程列表变化
   *
   * @param sigWeekAgendas
   */
  onSigWeekAgendaChange(sigWeekAgendas: AgendaEventInfo[]): void {
    this.sigWeekAgendas = this.processDuplicateAgenda(sigWeekAgendas);
    this.buildBlocks();
  }

  /**
   * 历法变更
   */
  onSubscriptionCalendar() {
    this.buildBlocks();
  }

  onShowImportantDayChange() {
    this.buildBlocks();
  }

  /**
   * 地区变更
   */
  onSystemRegionChange() {
    this.buildBlocks();
  }

  /**
   * 深色模式变更
   */
  onDarkModeChange() {
    this.buildBlocks();
  }

  /**
   * 语言变更
   * @param language 变更的语言
   */
  onLanguageChange(language: string): void {
    this.language = language;
    this.isRTL = i18n.isRTL(language);
    this.buildBlocks();
  }

  /**
   * 处理每周的日程列表内的重复日程
   *
   * @param sigWeekAgendas
   */
  processDuplicateAgenda(sigWeekAgendas: AgendaEventInfo[]): AgendaEventInfo[] {
    let res: AgendaEventInfo[] = [];
    this.sigWeekHoliday = [];
    sigWeekAgendas.forEach((agenda: AgendaEventInfo) => {
      if (res.length === 0 ||
        (agenda.mId !== res[res.length - 1].mId) ||
        (agenda.mId === res[res.length - 1].mId && agenda.mRepeatRule !== '')) {
        res.push(agenda);
      }
      if (agenda.isHoliday()) {
        this.sigWeekHoliday.push(agenda.mTitle.trim());
      }
    })
    return res;
  }


  /**
   * 基于当前的日程数据信息，构造日程块
   */
  buildBlocks(): void {
    // 重置日程状态矩阵
    this.initBlockState();

    // 新的日程块矩阵
    let newBlocks: AgendaBlockInfo[] = [];

    //如果日程块无法显示日程则将日程块清空
    if (this.lastRow === 0) {
      this.onBlocksChange(newBlocks);
      return;
    }

    // 记录当前日期偏移,用于全天日程的偏移
    this.nowTimeZoneOffset = new CalendarDate().getTimeOffset();

    this.buildFestivalAgendaBlocks(newBlocks);
    this.buildImportAgendaBlocks(newBlocks);
    if (this.isRTL) {
      this.processRTL(newBlocks);
    }
    this.onBlocksChange(newBlocks);
  }

  /**
   * 定制化处理镜像语言
   * @param newBlocks 原来的日程块
   */
  processRTL(newBlocks: AgendaBlockInfo[]) {
    newBlocks.forEach((block: AgendaBlockInfo) => {
      block.columnStart = 6 - block.columnStart;
      block.columnEnd = 6 - block.columnEnd;
    })
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

  /**
   * 构造单个日程块
   *
   * @param newBlocks 当前正在构造的日程块队列
   * @param agenda
   * @param index
   * @returns 是否构造了新的日程块
   */
  buildSingleBlock(newBlocks: ObservedArray<AgendaBlockInfo>, agenda: AgendaEventInfo): boolean {
    if (this.lastRow < 1) {
      return false;
    }
    // 取日程与当前周的交集
    const agendaRange: number[] = this.getInnerUnionBetweenWeekAndAgenda(agenda);

    // 遍历每一行 判断日程是否放得下
    const agendaRow: number = this.getValidRow(agendaRange);

    // 构造每一个日程块
    this.buildRowBlock(newBlocks, agenda, agendaRange, agendaRow);
    return false;
  }

  /**
   * 获取日程与当周时间的交集
   *
   * @param agenda
   * @returns
   */
  getInnerUnionBetweenWeekAndAgenda(agenda: AgendaEventInfo): number[] {
    const fistDay: number = this.weekVM.dayViewModels[0].dayData.getTimeStamp();
    let zoneOffset: number = 0;
    if (agenda.mIsAllDay && agenda.eventTimeZone) {
      //全天日程采用UTC时区存储,需要计算偏移量 --welink会插入非UTC时区的全天日程,故需要获取时区计算偏移量
      zoneOffset = I18nUtil.getTimeZoneOffsetById(agenda.eventTimeZone) - this.nowTimeZoneOffset;
    }
    const startGap: number = agenda.mBegin - zoneOffset - fistDay;
    const columnStart: number = startGap > 0 ? Math.floor((startGap) / MILLS_PER_DAY) : 0;
    const endGap: number = agenda.mEnd - zoneOffset - fistDay - 1;
    const isSameAllDay = agenda.mIsAllDay && agenda.mStartDay == agenda.mEndDay;
    const columnEnd: number =
      isSameAllDay ? columnStart : (endGap >= MILLS_PER_WEEK ? 6 : Math.floor((endGap) / MILLS_PER_DAY));
    return [columnStart, columnEnd];
  }

  /**
   * 输入的日程时间范围日程 是否存在对应的空间放置 若存在则返回对应的行数，若不存在则返回-1
   *
   * @param agendaRange 日程的时间范围
   * @returns
   */
  getValidRow(agendaRange: number[]): number {
    for (let row = 0; row < this.lastRow; row++) {
      let colFlag: boolean = true;
      for (let col = agendaRange[0]; col < agendaRange[1] + 1; col++) {
        if (this.blockState[row][col] !== -1) {
          colFlag = false;
          break;
        }
      }
      if (colFlag === true) {
        return row;
      }
    }
    return -1;
  }

  /**
   * 绘制日程块，并加入到 newBlocks 中去
   *
   * @param newBlocks 存放当周所有日程块
   * @param agenda 日程内容
   * @param agendaRange 范围
   * @param agendaRow 应放置日程的行数
   * @returns
   */
  buildRowBlock(newBlocks: ObservedArray<AgendaBlockInfo>, agenda: AgendaEventInfo,
                agendaRange: number[], agendaRow: number): boolean {
    if (agendaRow !== -1) {
      this.constructBlock(newBlocks, agenda, agendaRange, agendaRow);
    } else {
      this.processAbbreviation(newBlocks, agenda, agendaRange);
    }
    return false;
  }

  /**
   * 创建新的日程块
   *
   * @param newBlocks 存放当周所有日程块
   * @param agenda 日程内容
   * @param agendaRange 范围
   * @param agendaRow 应放置日程的行数
   */
  constructBlock(newBlocks: ObservedArray<AgendaBlockInfo>, agenda: AgendaEventInfo, agendaRange: number[],
                 agendaRow: number, isAbbreviation: boolean = false): void {
    const position: BlockPosition = new BlockPosition(agendaRow, agendaRow, agendaRange[0], agendaRange[1]);
    const outOfDateFlag: boolean = agenda.mEnd < new Date().getTime() ? true : false;
    const isCurMonth: boolean = (agenda.mBegin >= this.firstDayInCurMonth && agenda.mBegin < this.lastDayInCurMonth) ||
      (agenda.mEnd >= this.firstDayInCurMonth && agenda.mEnd < this.lastDayInCurMonth);
    const weekFirstDate = this.weekVM.dayViewModels[0].dayData.getTimeStamp();
    const nBlock: AgendaBlockInfo = new AgendaBlockInfo(agenda, newBlocks.length,
      position, outOfDateFlag, isCurMonth, isAbbreviation, weekFirstDate, this.layout.isSmall);
    this.recordBlocks(nBlock);
    newBlocks.push(nBlock);
    return;
  }

  /**
   * 处理缩略的日程，
   *
   * @param newBlocks 存放当周所有日程块
   * @param agenda 日程内容
   * @param agendaRange 范围
   */
  processAbbreviation(newBlocks: ObservedArray<AgendaBlockInfo>, agenda: AgendaEventInfo, agendaRange: number[]): void {
    // 将新的日程插入到缩略块中
    if (!this.blockState[this.lastRow - 1]) {
      Log.warn(TAG, 'this.blockState is null');
      return;
    }
    for (let col = agendaRange[0]; col < agendaRange[1] + 1; col++) {
      const blockIndex: number = this.blockState[this.lastRow - 1][col];
      if (blockIndex !== -1) {
        if (newBlocks[blockIndex] === undefined) {
          continue;
        }
        if (!newBlocks[blockIndex]?.isAbbreviation) {
          // 拆分当前的长条块->缩略块
          this.divideAbbrBlock(newBlocks, this.lastRow - 1, col);
        }
        // 在新生成的缩略块中 加入新日程 '+1'->'+2'
        newBlocks[this.blockState[this.lastRow - 1][col]]?.addAgenda(agenda);
      } else {
        // 创建新的 '+1' 缩略日程块'
        const newAgendaRange = [col, col];
        this.constructBlock(newBlocks, agenda, newAgendaRange, this.lastRow - 1, true);
      }
    }
    return;
  }

  /**
   * 将长日程块划分为缩略日程块
   */
  divideAbbrBlock(newBlocks: ObservedArray<AgendaBlockInfo>, row: number, col: number) {
    const blockIndex: number = this.blockState[row][col];
    newBlocks[blockIndex].isVisible = false;
    this.constructBlock(newBlocks, newBlocks[this.blockState[row][col]].blockAgendas[0], [col, col], row, true);
    let left: number = col - 1;
    let right: number = col + 1;
    while (left >= 0 && this.blockState[row][left] === blockIndex) {
      this.constructBlock(newBlocks, newBlocks[this.blockState[row][left]].blockAgendas[0], [left, left], row, true);
      left--;
    }
    while (right <= 6 && this.blockState[row][right] === blockIndex) {
      this.constructBlock(newBlocks, newBlocks[this.blockState[row][right]].blockAgendas[0], [right, right], row, true);
      right++;
    }
  }

  /**
   * 记录日程块状态
   *
   * @param block
   */
  recordBlocks(block: AgendaBlockInfo): void {
    for (let i = block.columnStart; i < block.columnEnd + 1; i++) {
      this.blockState[block.rowStart][i] = block.index;
    }
    return;
  }

  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE) {
    this.chineseHolidayState = chineseHolidayState;
    this.buildBlocks();
  }

  /**
   * 处理日程块最大行数变化
   *
   * @param weekAgendaRows
   */
  onWeekAgendaRowsChange(weekAgendaRows: number): void {
    const weekAgendaRowChange = Math.max(weekAgendaRows, 0)
    if (weekAgendaRowChange !== this.lastRow) {
      Log.info(TAG, 'onWeekAgendaRowsChange: weekAgendaRows = ' + weekAgendaRows)
      this.lastRow = weekAgendaRowChange;
      this.buildBlocks();
    }
  }

  private buildImportAgendaBlocks(newBlocks: AgendaBlockInfo[]) {
    const showImportant: boolean = MonthlyViewStateManager.getInstance().state.showImportantDay;
    for (let i = 0; i < this.sigWeekAgendas.length; i++) {
      const sigWeekAgenda: AgendaEventInfo = this.sigWeekAgendas[i];
      if (!showImportant && sigWeekAgenda.isImportantEvent()) {
        continue;
      }
      this.buildSingleBlock(newBlocks, sigWeekAgenda);
    }
  }

  private buildFestivalAgendaBlocks(newBlocks: AgendaBlockInfo[]) {
    // 月视图的状态机
    const state: MonthlyViewState = MonthlyViewStateManager.getInstance().state;
    // 新的重要节日日程块
    this.weekVM.dayViewModels.forEach((dayVM: SingleDayViewModel) => {
      let tagFlag = true; //标签显示节假日则日程块无需重复显示,添加标志用于跳过
      dayVM.dayData.festivals.forEach((festivalDay: FestivalDay) => {
        if (this.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CLOSE &&
          festivalDay.type !== FestivalType.SOLAR_TERM) {
          return;
        }
        if (this.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN &&
          HolidayUtil.needRemoveHoliday(festivalDay.name) === '') {
          return;
        }
        if (!this.needShowFestivalAgenda(state, festivalDay)) {
          return;
        }
        //跳过tag显示的节假日
        if (this.sigWeekHoliday.includes(festivalDay.name)) {
          return;
        }
        let festivalAgenda: AgendaEventInfo = new AgendaEventInfo();
        const selectDate = dayVM.dayData.getDate();
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
        this.buildSingleBlock(newBlocks, festivalAgenda);
      });
    });
  }

  /**
   * 重置日程块焦点参数
   */
  public resetMonthAgendaBlockFocusParam(): void {
    const weekAgendaState: WeekAgendaState = WeekAgendaState.getInstance();
    const agendaBlockState: AgendaBlockStateManagement = WeekAgendaState.getInstance().agendaBlockState;
    weekAgendaState.showPopup = false;
    agendaBlockState.clickAgendaShow = false;
    agendaBlockState.focusedAgendaX = -1;
    agendaBlockState.focusedAgendaY = -1;
  }

  /**
   * 判断是否能显示 点击 日程块的pop
   * @returns
   */
  public showAgendaPop(): boolean {
    return (this.checkWeekAndMonth(this.agendaBlockState.curFocusWeekIndex) && this.agendaBlockState.clickAgendaShow);
  }

  /**
   * 判断是否能显示 hover 日程块的pop
   * @returns
   */
  public showHoverPop(): boolean {
    //当前显示月===日程块所属月，且鼠标所在周===日程块所属周, 且点击日程pop不存在
    return (this.checkWeekAndMonth(this.agendaBlockState.hoverWeekIndex) && !this.agendaBlockState.clickAgendaShow);
  }

  /**
   * 判断当前显示月===日程块所属月，且鼠标所在周===日程块所属周
   * @returns
   */
  public checkWeekAndMonth(weekIndex: number): boolean {
    const date = new Date(GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number);
    const month = date.getMonth() + 1;
    if (month === this.weekVM.dateInfo.month && this.weekNumInd === weekIndex) {
      return true;
    } else {
      return false;
    }
  }

  public getCompId() {
    return 'week_agenda_' + this.weekNumInd + '_' + this.weekVM.dateInfo.month;
  }

  /**
   * 计算被分享日程的位置
   * @param selectBlock
   * @returns
   */
  // ShareKit 注释 - start
  // public getSharePopPos(selectBlock: AgendaBlockInfo): systemShare.ShareControllerAnchor {
  //   let xStart: number = 0;
  //   xStart = this.cellWidth * selectBlock.columnStart;
  //   const yStart = selectBlock.rowStart * vp2px(this.blockHeight + this.agendaBlockTopMargin) +
  //     vp2px(this.firstAgendaBlockTopMargin);
  //   return {
  //     windowOffset: {
  //       x: xStart,
  //       y: yStart
  //     }
  //   };
  // }
  // ShareKit 注释 - end

  /**
   * 计算被分享日程的宽度
   * @param selectBlock
   * @returns
   */
  public getShareAgendaBlockWidth(selectBlock: AgendaBlockInfo): number {
    return this.cellWidth * (selectBlock.columnEnd - selectBlock.columnStart + 1);
  }

  drawContent(context: DrawContext): void {
    try {
      const canvas = context.canvas;
      const size = context.size;
      this.weekHeight = size.height;
      this.cellWidth = vp2px(size.width) / 7;
      //showBlockNum：能展示日程块的数量
      const showBlockNum = Math.floor(this.weekHeight / (this.blockHeight + this.agendaBlockTopMargin));
      hiTraceMeter.startTrace(traceEvents.drawContent, 0);
      if (showBlockNum > 0 && this.blocks) {
        this.blocks.forEach(agendaBlock => {
          if (!agendaBlock) {
            Log.error(TAG, 'agendaBlock is null!');
            return;
          }
          //rowStart=0，表示第一个展示，showBlockNum=1表示可以显示一个日程块
          if (agendaBlock.rowStart < showBlockNum) {
            const yStart = agendaBlock.rowStart *
            vp2px(this.blockHeight + this.agendaBlockTopMargin) + vp2px(this.firstAgendaBlockTopMargin);
            const xStart = this.cellWidth * agendaBlock.columnStart + vp2px(this.agendaBlockLeftMargin);
            const xEnd = this.cellWidth * (agendaBlock.columnEnd + 1);

            const date = new Date(GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number);
            const month = date.getMonth() + 1;

            if ((this.weekNumInd === this.weekVM.agendaBlockState.curFocusWeekIndex) &&
              this.weekVM.agendaBlockState.focusedAgendaX === agendaBlock.columnStart &&
              agendaBlock.rowStart === this.weekVM.agendaBlockState.focusedAgendaY) {

              if (month === this.weekVM.dateInfo.month) {
                this.drawAgendaBlock(canvas, agendaBlock, xStart, yStart, xEnd, true);
              } else { //当前显示的月与该WeekViewModel所属的月不一致，选中态取消
                this.drawAgendaBlock(canvas, agendaBlock, xStart, yStart, xEnd, false);
              }
            } else {
              this.drawAgendaBlock(canvas, agendaBlock, xStart, yStart, xEnd, false);
            }
          }
        });
      }
      hiTraceMeter.finishTrace(traceEvents.drawContent, 0);
    } catch (error) {
      Log.logErrorMsg(TAG, 'drawContent error:', error);
    }
  }

  //绘制日程块
  drawAgendaBlock(canvas: drawing.Canvas, agendaBlockInfo: AgendaBlockInfo,
                  xStart: number, yStart: number, xEnd: number, focused: boolean): void {
    const brush = PaintCache.instance().getBrush();

    //绘制日程标题左边的竖线
    let rect: common2D.Rect = this.isRTL ? {
      left: xEnd,
      top: yStart,
      right: xEnd - vp2px(barWidth),
      bottom: vp2px(this.blockHeight) + yStart
    } : {
      left: xStart,
      top: yStart,
      right: xStart + vp2px(barWidth),
      bottom: vp2px(this.blockHeight) + yStart
    }
    let roundRect: drawing.RoundRect = new drawing.RoundRect(rect, vp2px(3), vp2px(3));

    brush.setColor(PaletteCache.instance().getHexColor(agendaBlockInfo.blockLineColor));
    canvas.attachBrush(brush);
    canvas.drawRoundRect(roundRect);

    //判断日程块是否获焦
    let blockColor = agendaBlockInfo.blockColor;
    if (focused) {
      blockColor = agendaBlockInfo.blockFocusColor;
    }

    const blockRightMargin = this.layout.isGrid ? agendaBlockMargin : 0;

    //绘制背景矩形
    let backRect: common2D.Rect = {
      left: xStart,
      top: yStart,
      right: xEnd - vp2px(blockRightMargin),
      bottom: vp2px(this.blockHeight) + yStart
    }

    let backRoundRect: drawing.RoundRect = new drawing.RoundRect(backRect,
      vp2px(blockMarginRadii), vp2px(blockMarginRadii));

    brush.setColor(PaletteCache.instance().getHexColor(blockColor));
    canvas.attachBrush(brush);
    canvas.drawRoundRect(backRoundRect);

    hiTraceMeter.startTrace(traceEvents.buildBlock, 0);
    let paragraph = this.buildParagraphGraph(agendaBlockInfo);
    hiTraceMeter.finishTrace(traceEvents.buildBlock, 0);
    // 布局,绘制text的宽度
    paragraph.layoutSync(xEnd - xStart - vp2px(textMargin + blockRightMargin + barWidth));

    //绘制文本
    paragraph.paint(canvas, xStart + vp2px(barTextMargin + (this.isRTL ? 0 : barWidth)), yStart +
      vp2px(this.blockHeight - this.agendaBlockSize) / 2 - 2); // 镜像语言需要取消空出的日程条位置

    canvas.detachBrush();
    canvas.getSaveCount();
  }

  buildParagraphGraph(agendaBlockInfo: AgendaBlockInfo): text.Paragraph {
    //字体颜色，字重，字体大小等属性由此设置
    let myTextStyle: text.TextStyle = {
      fontSize: vp2px(this.agendaBlockSize),
      color: PaletteCache.instance().getHexColor(agendaBlockInfo.titleColor),
      ellipsisMode: 2,
      ellipsis: '...',
      fontFeatures: [{ name: 'ss08', value: 1 }],
      fontFamilies: [fontName],
    };

    //断词类型，换行策略，文本方向以及对齐方式由此设置
    let myParagraphStyle: text.ParagraphStyle = {
      textStyle: myTextStyle,
      align: text.TextAlign.JUSTIFY,
      maxLines: 1,
      wordBreak: text.WordBreak.BREAK_ALL,
      breakStrategy: text.BreakStrategy.HIGH_QUALITY
    };

    let paragraphGraphBuilder = new text.ParagraphBuilder(myParagraphStyle,
      MonthPaintCache.instance().getAgendaBlockFontCollection());
    //更新文本样式
    paragraphGraphBuilder.pushStyle(myTextStyle);
    //添加文本
    let tagText: string | Resource = agendaBlockInfo.titleString !== '' ? agendaBlockInfo.titleString :
    GlobalThis.getResourceStr($r('app.string.no_title_label'));
    paragraphGraphBuilder.addText(tagText);

    return paragraphGraphBuilder.build();
  }

  public freshAgendaArea() {
    this.invalidate();
  }

}

@Observed
export class AgendaBlockInfo extends DrawModifier {
  // 是否是占位日程块
  public isPlaceholder = true;
  // 是否显示
  public isVisible = true;
  // 显示的标题
  public titleString: string = '';
  // 显示的标题
  public titleColor: string = '';
  // 日程块的颜色
  public titleFocusColor: string = '#006cde';
  // 日程块的颜色
  public blockColor: string = '#86006cde';
  // 日程块竖线的颜色
  public blockLineColor: string = '#B3006cde';
  //日程块焦点的颜色
  public blockFocusColor: string = '#80F76045';
  // 持有的日视图数据
  public rowStart: number = 0;
  public rowEnd: number = 0;
  public columnStart: number = 0;
  public columnEnd: number = 0;
  // 单个日程块包含的日程（缩略的日程块可以有多个日程）
  public blockAgendas: AgendaEventInfo[] = [];
  // 在本周日程列表中的索引值
  public index: number = 0;
  // 当前日程是否过期
  public isOutOfDate: boolean = false;
  // 判断是否在当月
  public isCurMonth: boolean = false;
  // 判断是否被缩略
  public isAbbreviation: boolean = false;
  //日程块的id
  public blockId: number = -1;
  public uuid: string = '';
  //日程块的类型
  public blockType: number = -1;
  //日程块弹窗
  public blockPop: boolean = false;
  //日程块hover弹窗
  public hoverPop: boolean = false;
  //日程块时间戳
  public blockTimeStamp: number = 0;
  //日程块时间戳
  private _blockStartStamp: number = 0;
  //是否为小屏日程块
  private isSmall: boolean = true;

  public readonly blockHeight = DeviceConfig.instance().config.monthAgendaBlockHeight;

  constructor(agenda: AgendaEventInfo, index: number, position: BlockPosition, isOutOfDate: boolean,
    isCurMonth: boolean, isAbbreviation: boolean = false, firstDayInCurWeek: number = 0,
    isSmall: boolean = true) {
    super();
    this.isPlaceholder = false;
    this.blockAgendas.push(agenda);
    this.blockId = agenda.mId;
    this.uuid = util.generateRandomUUID();
    this.blockType = agenda.mImportantEventType;

    this.isAbbreviation = isAbbreviation;
    this.isSmall = isSmall;

    this.columnStart = position.columnStart;
    this.columnEnd = position.columnEnd;
    this.rowStart = position.rowStart;
    this.rowEnd = position.rowEnd;

    this.index = index;
    if (this.isAbbreviation) {
      this.titleString = '+1';
    } else {
      this.titleString = agenda.mTitle;
    }

    this.isCurMonth = isCurMonth;
    this.isOutOfDate = isOutOfDate;
    this.parseBlockColor(agenda);
    this.blockTimeStamp = Date.now();
    this.blockStartStamp = firstDayInCurWeek + this.columnStart * MILLS_PER_DAY;
  }

  public get blockStartStamp() {
    return this._blockStartStamp;
  }

  public set blockStartStamp(blockStartStamp: number) {
    this._blockStartStamp = blockStartStamp;
  }

  addAgenda(agenda: AgendaEventInfo) {
    this.blockAgendas.push(agenda);
    this.titleString = '+' + String(this.blockAgendas.length);
    this.parseBlockColor(agenda);
  }

  popAgenda(): AgendaEventInfo | undefined {
    const agenda: AgendaEventInfo | undefined = this.blockAgendas.pop();
    if (agenda === undefined) {
      Log.error(TAG, 'NO VALID AGENDA EVENT INFO!');
      return undefined;
    }
    if (this.blockAgendas.length === 1) {
      this.titleString = this.blockAgendas[0].mTitle;
      this.parseBlockColor(this.blockAgendas[0]);
    } else {
      this.titleString = '+' + String(this.blockAgendas.length);
    }
    return agenda;
  }

  parseBlockColor(agenda: AgendaEventInfo): void {
    const isDarkMode: boolean = AppStorage.get<boolean>(GlobalDataKeys.IS_DARKMODE) ?? false;
    const maxDarkOpacity = WeekAgendaLayout.fontTextMaxDarkOpacity;
    const fontDesOpacity: string = this.getOpacityString(WeekAgendaLayout.fontOpacity, isDarkMode, maxDarkOpacity);
    const blockDesOpacity: string = isDarkMode ? this.getOpacityString(WeekAgendaLayout.rectDarkOpacity, isDarkMode) :
    this.getOpacityString(WeekAgendaLayout.rectOpacity, isDarkMode);
    const lineDesOpacity: string = this.getOpacityString(WeekAgendaLayout.agendaLineOpacity, isDarkMode);
    const blockFocusDesOpacity: string =
      isDarkMode ? this.getOpacityString(WeekAgendaLayout.rectDarkFocusOpacity, isDarkMode) :
      this.getOpacityString(WeekAgendaLayout.rectFocusOpacity, isDarkMode);
    if (this.isAbbreviation) {
      // 缩略日程 '+1'
      const textColor = isDarkMode ? WeekAgendaLayout.fixContentTextColorWhite : WeekAgendaLayout.abbreviationTextColor;
      this.titleColor = this.adjustOpacity(textColor, fontDesOpacity);
      this.titleFocusColor =
        this.adjustOpacity(textColor, this.getOpacityString(WeekAgendaLayout.fontOpacity, isDarkMode, maxDarkOpacity));
      this.blockColor = this.adjustOpacity(WeekAgendaLayout.abbreviationRectColor, blockDesOpacity);
      this.blockFocusColor = this.adjustOpacity(WeekAgendaLayout.abbreviationRectColor, blockFocusDesOpacity);
      this.blockLineColor = this.adjustOpacity(WeekAgendaLayout.abbreviationRectColor, lineDesOpacity);
      return;
    }
    if (agenda.isHoliday()) {
      // 节假日日程块
      const holidayColor = isDarkMode ? WeekAgendaLayout.holidayDarkColor : WeekAgendaLayout.holidayColor;
      const textOpacity = isDarkMode ? this.getOpacityString(WeekAgendaLayout.fontOpacity, isDarkMode, maxDarkOpacity) :
      this.getOpacityString(WeekAgendaLayout.holidayFontOpacity, isDarkMode);
      this.titleColor = this.adjustOpacity(holidayColor, textOpacity);
      this.titleFocusColor =
        this.adjustOpacity(holidayColor,
          this.getOpacityString(WeekAgendaLayout.fontOpacity, isDarkMode, maxDarkOpacity));
      this.blockColor = this.adjustOpacity(holidayColor, blockDesOpacity);
      this.blockFocusColor = this.adjustOpacity(holidayColor, blockFocusDesOpacity);
      this.blockLineColor =
        this.adjustOpacity(holidayColor, this.getOpacityString(WeekAgendaLayout.holidayLineOpacity, isDarkMode));
      return;
    }

    const textColor =
      isDarkMode ? WeekAgendaLayout.fixContentTextColorWhite : '#' + AccountUtils.HexColor(agenda.mDisplayColor);
    this.titleColor = this.adjustOpacity(textColor, fontDesOpacity);
    this.titleFocusColor =
      this.adjustOpacity(textColor, this.getOpacityString(WeekAgendaLayout.fontOpacity, isDarkMode, maxDarkOpacity));
    this.blockColor = this.adjustOpacity('#' + AccountUtils.HexColor(agenda.mDisplayColor), blockDesOpacity);
    this.blockFocusColor = this.adjustOpacity('#' + AccountUtils.HexColor(agenda.mDisplayColor), blockFocusDesOpacity);
    this.blockLineColor = this.adjustOpacity('#' + AccountUtils.HexColor(agenda.mDisplayColor), lineDesOpacity);
    return;
  }

  /**
   * 获取最终的透明度字符串,小屏深色模式
   * @param opacityNum 透明度数值,0-255对应0到100%透明度
   * @param isDarkMode 是否为深色模式
   * @param maxOpacity 深色模式最大透明度,默认90%
   * @returns
   */
  getOpacityString(opacityNum: number, isDarkMode: boolean, maxOpacity: number = 230) {
    const opaMulti = this.isCurMonth ? 1 : WeekAgendaLayout.notInCurMonthOpacity;
    if (isDarkMode) {
      opacityNum = this.isSmall ? opacityNum + WeekAgendaLayout.smallDarkOpacityAdd : opacityNum; // 添加20透明度
      opacityNum = Math.min(opacityNum, maxOpacity); // check最大透明度
    }
    const finalOpacity = Math.round(opacityNum * opaMulti);
    return '#' + (finalOpacity & 0xFFFFFF).toString(16).padStart(2, '0');
  }

  toString(): string {
    return 'titleString = ' + this.titleString + ', isUnfold = ' + this.isUnfold() + ', blockAgendas.length = ' + this.blockAgendas.length +
      ', position = [' + this.rowStart + ',' + this.rowEnd + ',' + this.columnStart + ',' + this.columnEnd + ']';
  }

  /**
   * 判断日程块是否被折叠
   *
   * @returns
   */
  isUnfold(): boolean {
    return !this.isAbbreviation;
  }

  /**
   * 非折叠状态获取第一个日程
   *
   * @returns 第一条日程
   */
  getInfo(): AgendaEventInfo {
    return this.blockAgendas[0];
  }

  /**
   * 折叠状态获取全部内容日程
   *
   * @returns 全部日程
   */
  getInfoList(): AgendaEventInfo[] {
    return this.blockAgendas;
  }

  /**
   * 获取最早日程的时间
   *
   * @returns 全部日程
   */
  getEarliestDate(): number {
    return this.blockAgendas[0].mBegin;
  }

  /**
   * 调整日程条目文字的透明度
   *
   * @param sourceColor 原来的不包含文字透明度的源颜色
   * @param desOpacity 目标透明度
   * @return 调整透明度之后的字体颜色
   */
  private adjustOpacity(sourceColor: string, desOpacity: string): string {
    return sourceColor.replace('#', desOpacity);
  }

  drawTagText(canvas: drawing.Canvas, size: Size): void {
    const brush = PaintCache.instance().getBrush();

    //绘制日程标题左边的竖线
    let rect: common2D.Rect = {
      left: 0,
      top: 0,
      right: vp2px(2),
      bottom: vp2px(this.blockHeight)
    }
    let roundRect: drawing.RoundRect = new drawing.RoundRect(rect, vp2px(2), vp2px(2));

    brush.setColor(PaletteCache.instance().getHexColor(this.blockLineColor));
    canvas.attachBrush(brush);
    canvas.drawRoundRect(roundRect);

    canvas.detachBrush();
    canvas.getSaveCount();
  }

  getTagColor() {
    throw new Error('Method not implemented.');
  }

  drawContent(context: DrawContext): void {
    try {
      const canvas = context.canvas;
      const size: Size = { width: vp2px(context.size.width), height: vp2px(context.size.height) };
      this.drawTagText(canvas, size);
    } catch (error) {
      Log.logErrorMsg(TAG, 'drawTagText error:', error);
    }
  }

  clearPreview() {
    if (this.blockPop || this.hoverPop) {
      this.blockPop = false;
      this.hoverPop = false;
      SafeUtil.setTimeout(() => {
        focusControl.requestFocus(CompId.SLIDE_TAB_BAR); // hover态取消后会丢失焦点,需要重新获焦防止方向键无法连续触发
      }, 300)
    }
  }
}

export class BlockPosition {
  public rowStart: number = 0;

  public rowEnd: number = 0;

  public columnStart: number = 0;

  public columnEnd: number = 0;

  constructor(rowStart: number, rowEnd: number, columnStart: number, columnEnd: number) {
    this.rowStart = rowStart;
    this.rowEnd = rowEnd;
    this.columnStart = columnStart;
    this.columnEnd = columnEnd;
  }
}
