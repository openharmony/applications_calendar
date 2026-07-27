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
  AccountUtils,
  AgendaEventInfo,
  DateUtil,
  Log,
  MILLS_PER_DAY,
  TabType,
  CompId,
  DeviceConfig,
  HOURS_PER_DAY,
  AccountColor,
  I18nUtil,
  GlobalThis,
  EmitterCollector,
  CalendarDate,
  NumberFormatManager,
} from '@app/common';
import measure from '@ohos.measure';
import { util } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';
import { RootModel } from '../model/RootModel';
import i18n from '@ohos.i18n';

const TAG: string = 'GanttBlockViewModel';

const MAX_FOLD_BLOCK_MAX_LINES: number = 3;

export enum GanttBlockType {
  UNUSED, // 未定义
  AGENDA, // 日程
  SPECIAL, // 节假日/节气等
  FOLD, // 折叠
}

@Observed
export class GanttBlockViewModel {
  public static readonly DARK_BLOCK_TEXT_COLOR: string = '#AAffffff'; // 高亮背景透明度(选中)
  public readonly BLOCK_SPACE_AND_LINE_WIDTH: number = 1.75; // 当前日程块间距
  public width: number = 0;
  public height: number = 0;
  public x: number = 0;
  public y: number = 0;
  public fontSize: number = DeviceConfig.instance().config.agendaBlockFontSize; //日程块的字体大小
  public lineHeight: number = 0; //日程块的字体行高
  public type: GanttBlockType = GanttBlockType.AGENDA;
  public mainText: ResourceStr = ''; // 日程标题 折叠日程数量 特殊日信息
  public subText: string = ''; // 地点
  public endDate: number = 0; //结束时间
  public infoList: AgendaEventInfo[] = [];
  public key: string = '';
  public mainTextMaxLines: number = 1;
  public subTextMaxLines: number = 1;
  public isAgendaExpired: boolean = false; //日程过期标志
  public isAllDayAgenda: boolean = false; //全天日程标志
  public DIVIDER_WIDTH: number = 1.5;
  public leftBorderRadius: number = 4;
  public rightBorderRadius: number = 4;
  public blockMarginLeft: number = 2;
  public blockMargin: number = 4;
  public isFocus: boolean = false;
  public tabType: TabType = TabType.DAY;
  private readonly DEFAULT_COLOR: string = AccountUtils.HexColor(AccountColor.RED); // 默认颜色
  private readonly TIME_WIDTH: number = 30; // 能放下时间的宽度
  private readonly BLOCK_SPACE: number = RootModel.instance().BLOCK_SPACE;
  public backgroundColor: ResourceColor = this.DEFAULT_COLOR;
  public backgroundFocusColor: ResourceColor = this.DEFAULT_COLOR;
  public backgroundDarkColor: ResourceColor = this.DEFAULT_COLOR;
  public backgroundDarkFocusColor: ResourceColor = this.DEFAULT_COLOR;
  public defaultBackgroundColor: ResourceColor = this.DEFAULT_COLOR;
  public textColor: ResourceColor = this.DEFAULT_COLOR;
  public compId: string = '';
  private readonly BLOCK_BG_OPACITY_DARK: string = '26'; // 默认深色背景透明度15%
  private readonly HIGHLIGHT_BG_OPACITY_DARK: string = '73'; // 高亮深色背景透明度(选中)45%
  private readonly BLOCK_BG_OPACITY: string = '0F'; // 默认背景透明度
  private readonly HIGHLIGHT_BG_OPACITY: string = '33'; // 高亮背景透明度(选中)
  private originalY: number = 0;
  private originalHeight: number = 0;
  private mainTextHeight: number = 0;
  private subTextHeight: number = 0;
  public showTimeText: boolean = true; // 是否显示开始时间
  public isCreatePopupShow: boolean = false; // 是否显示新建跟手弹窗
  public blockStartTime: number = 0;
  public blockEndTime: number = 0;
  public eventInfo: AgendaEventInfo = new AgendaEventInfo();
  // 广播携带的日程信息
  public createPageData: emitter.EventData = {};
  public emitterCollector : EmitterCollector = new EmitterCollector();
  public isQuickCreate: boolean = false;
  private isRTL: boolean = false; // 是否是语言为ar的右向

  constructor() {
    const language = I18nUtil.getSystemLanguage();
    this.isRTL = i18n.isRTL(language);
  }


  onLanguageChange(language: string): void {
    this.isRTL = i18n.isRTL(language);
    if (this.type === GanttBlockType.FOLD) {
      this.processMainText();
    }
  }

  private processMainText(){
    const num = NumberFormatManager.instance().numberFormat(this.infoList.length);
    this.mainText = this.isAllDayAgenda ? (this.isRTL ? `${num}+` : `+\u00A0${num}`) :
      (this.isRTL ? `${num}+` : `\u00A0+\u00A0\n${num}`); // 拼接空格处理一行显示省略号极端情况
  }

  setRect(x: number, y: number, width: number, height: number): void {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  containPoint(x: number, y: number): boolean {
    if (x === undefined || y === undefined) {
      return false;
    }
    return x >= this.x && x <= (this.x + this.width) && y >= this.y && y <= (this.y + this.height);
  }

  intersect(other: GanttBlockViewModel): boolean {
    const cx1 = this.x + this.width / 2;
    const cy1 = this.y + this.height / 2;
    const cx2 = other.x + other.width / 2;
    const cy2 = other.y + other.height / 2;

    // 因为精度原因，这里通过放大数值来比较，arkTS不让用toFixed等方法。8位是看数据取的。
    // return Math.abs(cx1 - cx2) < (this.width + other.width) / 2 && Math.abs(cy1 - cy2) < (this.height + other.height) / 2;
    return this.smallerThan(Math.abs(cx1 - cx2), (this.width + other.width) / 2) &&
    this.smallerThan(Math.abs(cy1 - cy2), (this.height + other.height) / 2);
  }

  smallerThan(a: number, b: number): boolean {
    const FIXED_DIGIT: number = 8;
    const FIXED_NUMBER: number = Math.pow(10, FIXED_DIGIT);
    return Math.floor(a * FIXED_NUMBER) < Math.floor(b * FIXED_NUMBER);
  }

  setInfo(info: AgendaEventInfo, lineHeight: number, allDayBlock: boolean = false): void {
    this.lineHeight = lineHeight;
    if (!info.isHoliday()) {
      this.setNormalAgenda(info, allDayBlock);
      return;
    }

    this.setSpecialItem(info);
  }

  getInfo(): AgendaEventInfo {
    return this.infoList[0];
  }

  getInfoList(): AgendaEventInfo[] {
    return this.infoList;
  }

  isFold(): boolean {
    return this.type === GanttBlockType.FOLD;
  }

  getEarliestDate(): number {
    return this.infoList[0].mBegin;
  }

  setNormalAgenda(info: AgendaEventInfo, allDayBlock: boolean = false): void {
    this.type = GanttBlockType.AGENDA;
    this.mainText = info.mTitle.length > 0 ? info.mTitle : $r('app.string.no_title_label');
    this.subText = info.mLocation.length > 0 ? info.mLocation : '';
    this.infoList = [info];
    const bgOpacity = this.BLOCK_BG_OPACITY;
    const bgFocusOpacity = this.HIGHLIGHT_BG_OPACITY;
    const bgDarkOpacity = this.BLOCK_BG_OPACITY_DARK;
    const bgDarkFocusOpacity = this.HIGHLIGHT_BG_OPACITY_DARK;
    const color = AccountUtils.HexColor(info.mDisplayColor);
    this.backgroundColor = `#${bgOpacity}${color}`;
    this.backgroundFocusColor = `#${bgFocusOpacity}${color}`;
    this.backgroundDarkColor = `#${bgDarkOpacity}${color}`;
    this.backgroundDarkFocusColor = `#${bgDarkFocusOpacity}${color}`;
    this.textColor = `#${color}`;
    this.endDate = info.mEnd;
    let nowDate: number = new Date().getTime();
    this.isAgendaExpired = this.endDate > nowDate ? false : true;
    this.key = '' + this.tabType + this.type + 'type' + info.mId;
    let allDayList: AgendaEventInfo[] = this.infoList.filter(
      (item: AgendaEventInfo) => (item.mEnd - item.mBegin) >= MILLS_PER_DAY);
    this.isAllDayAgenda = allDayBlock || allDayList.length > 0 || info.mIsAllDay ? true : false;
    this.compId = this.isAllDayAgenda ?
      CompId.ALL_DAY_AGENDA_BLOCK + util.generateRandomUUID() :
      CompId.NORMAL_AGENDA_BLOCK + util.generateRandomUUID();
    this.calculateMaxLines();
  }

  getStartTime(dateTime: number, is24Hour: boolean): string {
    const startDate = new CalendarDate(dateTime)
    let hour = startDate.getHours();
    const HOURS_HALF_DAY = HOURS_PER_DAY / 2;
    hour = (!is24Hour && hour > HOURS_HALF_DAY) ? hour % HOURS_HALF_DAY : hour;
    const hourStr = is24Hour ? hour.toString().padStart(2, '0') : hour;
    const minuteStr = startDate.getMinutes().toString().padStart(2, '0');
    return `${hourStr}:${minuteStr}`;
  }

  setSpecialItem(info: AgendaEventInfo): void {
    this.isAllDayAgenda = true;
    this.type = GanttBlockType.SPECIAL;
    this.mainText = info.mTitle;
    this.textColor = $r('app.color.holiday_block_title_color');
    this.backgroundColor = $r('app.color.holiday_block_bg_color');
    this.backgroundFocusColor = $r('app.color.holiday_block_bg_focus_color');
    this.backgroundDarkColor = $r('app.color.holiday_block_bg_color');
    this.backgroundDarkFocusColor = $r('app.color.holiday_block_bg_focus_color');
    this.infoList = [info];
    this.key = '' + this.tabType + this.type + 'type' + info.mTitle;
    this.compId = info.mTitle;
  }

  setFoldInfo(infoList: AgendaEventInfo[], lineHeight: number): void {
    this.lineHeight = lineHeight;
    this.type = GanttBlockType.FOLD;
    this.infoList = infoList;
    this.processMainText();
    this.textColor = `#${this.DEFAULT_COLOR}`;
    this.backgroundColor = `#${this.BLOCK_BG_OPACITY}${this.DEFAULT_COLOR}`;
    this.backgroundFocusColor = `#${this.HIGHLIGHT_BG_OPACITY}${this.DEFAULT_COLOR}`;
    this.backgroundDarkColor = `#${this.BLOCK_BG_OPACITY_DARK}${this.DEFAULT_COLOR}`;
    this.backgroundDarkFocusColor = `#${this.HIGHLIGHT_BG_OPACITY_DARK}${this.DEFAULT_COLOR}`;
    let nowDate: number = new Date().getTime();
    let agendaExpiredList: AgendaEventInfo[] = this.infoList.filter((item: AgendaEventInfo) => item.mEnd > nowDate);
    this.isAgendaExpired = agendaExpiredList.length > 0 ? false : true;
    try {
      this.key = '' + this.tabType + this.type + 'type' + nowDate + '+' + infoList.length;
    } catch (err) {
      Log.logErrorMsg(TAG, 'set block key error', err);
      this.key = `errorKey ${infoList.length}`;
    }
    this.calculateMaxLines();
  }

  // 跨天的单天日程块需要复制基础内容不包含布局信息和key
  clone(): GanttBlockViewModel {
    const ret = new GanttBlockViewModel();
    ret.type = this.type;
    ret.mainText = this.mainText;
    ret.subText = this.subText;
    ret.infoList = this.infoList;
    ret.backgroundColor = this.backgroundColor;
    ret.backgroundFocusColor = this.backgroundFocusColor;
    ret.backgroundDarkColor = this.backgroundDarkColor;
    ret.backgroundDarkFocusColor = this.backgroundDarkFocusColor;
    ret.textColor = this.textColor;
    ret.tabType = this.tabType;
    ret.key = this.key;
    ret.fontSize = this.fontSize;
    ret.lineHeight = this.lineHeight;
    return ret;
  }

  //临时方案 目前没有组件能自适应 计算标题和地点最大行高
  calculateMaxLines(): void {
    if (this.isAllDayAgenda) { //全天日程不需要计算高度
      this.showTimeText = false;
      return;
    }

    const width: number = this.width - this.DIVIDER_WIDTH - 2; //去除边距后的日程块宽度
    let blockLine: number = Math.max(Math.floor((this.height - this.BLOCK_SPACE * 2) / (this.lineHeight || 1)),
      this.height >= this.fontSize ? 1 : 0); //当前高度可以显示行数

    if (this.isFold()) {
      // 处理折叠日程块
      this.mainTextMaxLines = blockLine > 1 ? MAX_FOLD_BLOCK_MAX_LINES : blockLine;
      this.showTimeText = false;
      return;
    }

    // 如果当前能放下两行文字且宽度足够显示开始时间则显示开始时间
    if (blockLine >= 2 && this.width > this.TIME_WIDTH) {
      this.showTimeText = true;
      blockLine = blockLine - 1;
    } else {
      this.showTimeText = false;
    }

    //计算标题高度
    const mainTextSize = measure.measureTextSize({
      textContent: this.mainText,
      fontSize: this.fontSize,
      fontWeight: FontWeight.Regular,
      constraintWidth: width,
      lineHeight: this.lineHeight
    });
    if (!mainTextSize?.height) { //空值判断,为空时默认只显示标题
      this.mainTextMaxLines = Math.max(0, blockLine);
      this.subTextMaxLines = 0;
      return;
    }
    this.mainTextHeight = px2vp(Number(mainTextSize.height)); //标题文字高度
    const mainTextLine = Math.ceil(this.mainTextHeight / this.lineHeight); //标题文字需占行数

    //计算地点高度
    let subTextLine: number = 0; //地点文字需占行数
    if (this.subText.length !== 0) { //地点不为空才需要计算
      const subTextSize = measure.measureTextSize({
        textContent: this.subText,
        fontSize: this.fontSize,
        fontWeight: FontWeight.Regular,
        constraintWidth: width,
        lineHeight: this.lineHeight
      });
      if (subTextSize?.height) { //空值判断
        this.subTextHeight = px2vp(Number(subTextSize.height)); //地点文字高度
        subTextLine = Math.ceil(this.subTextHeight / this.lineHeight); //地点文字需占行数
      }
    }

    this.calculateLines(blockLine, mainTextLine, subTextLine);
  }

  // 用于甘特图缩放时需要重新计算显示行数的情况
  reCalculateMaxLines(): void {
    if (this.isAllDayAgenda) { //全天日程不需要重新计算高度
      this.showTimeText = false;
      return;
    }

    const width: number = this.width - this.DIVIDER_WIDTH - 2; //去除边距后的日程块宽度
    let blockLine: number = Math.max(Math.floor((this.height - this.BLOCK_SPACE * 2) / (this.lineHeight || 1)),
      this.height >= this.fontSize ? 1 : 0); //当前高度可以显示行数

    if (this.isFold()) {
      // 处理折叠日程块
      this.mainTextMaxLines = blockLine > 1 ? MAX_FOLD_BLOCK_MAX_LINES : blockLine;
      this.showTimeText = false;
      return;
    }

    // 如果当前能放下两行文字且宽度足够显示开始时间则显示开始时间
    if (blockLine >= 2 && width > this.TIME_WIDTH) {
      this.showTimeText = true;
      blockLine = blockLine - 1;
    } else {
      this.showTimeText = false;
    }

    //计算标题高度
    if (this.mainTextHeight === 0) { //空值判断,为空时默认只显示标题
      this.mainTextMaxLines = Math.max(0, blockLine);
      this.subTextMaxLines = 0;
      return;
    }

    //计算地点高度
    let subTextLine: number = 0; //地点文字需占行数
    if (this.subTextHeight === 0) { //空值判断
      subTextLine = Math.ceil(this.subTextHeight / this.lineHeight); //地点文字需占行数
    }

    const mainTextLine = Math.ceil(this.mainTextHeight / this.lineHeight); //标题文字需占行数

    this.calculateLines(blockLine, mainTextLine, subTextLine);
  }

  calculateLines(blockLine: number, mainTextLine: number, subTextLine: number) {
    if (blockLine <= 0) { //高度无法显示文本
      this.mainTextMaxLines = 0;
      this.subTextMaxLines = 0;
    } else if (mainTextLine >= blockLine) { //可以显示部分或全部标题文本
      this.mainTextMaxLines = blockLine;
      this.subTextMaxLines = 0;
    } else if (mainTextLine < blockLine && (mainTextLine + subTextLine) >= blockLine) { //可以显示完整标题和部分地点
      this.mainTextMaxLines = mainTextLine;
      this.subTextMaxLines = blockLine - mainTextLine;
    } else if ((mainTextLine + subTextLine) < blockLine) { //可以显示完整标题和地点
      this.mainTextMaxLines = blockLine;
      this.subTextMaxLines = blockLine - mainTextLine;
    }
  }

  /**
   * 清除获焦态
   */
  clearFocus() {
    this.isFocus = false;
  }

  /**
   * 获取获焦态
   */
  checkFocus() {
    this.isFocus = true;
  }

  // 更新日程的过期状态
  updateBlockExpired() {
    let nowDate: number = Date.now();
    if (this.isFold()) {
      let agendaExpiredList: AgendaEventInfo[] = this.infoList.filter((item: AgendaEventInfo) => item.mEnd > nowDate);
      this.isAgendaExpired = agendaExpiredList.length > 0 ? false : true;
    } else {
      this.isAgendaExpired = this.endDate > nowDate ? false : true;
    }
  }

  /**
   * 根据缩放值获取缩放后的坐标
   * @param scale
   */
  updateGanttViewScale(scale: number) {
    this.y = this.originalY * scale + this.BLOCK_SPACE_AND_LINE_WIDTH;
    this.height = this.originalHeight * scale;
  }

  /**
   * 设置当前缩放开始或结束的值
   */
  setOriginalGanttViewScale() {
    this.originalY = this.y - this.BLOCK_SPACE_AND_LINE_WIDTH;
    this.originalHeight = this.height;
  }

  getAccessibilityText(): string {
    if (this.infoList.length == 0) {
      return '';
    }
    let block = this.infoList[0];
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
    };

    let timeOption: DateTimeOptions = {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !I18nUtil.is24HourClock()
    };
    let beginDate: CalendarDate = new CalendarDate(block.mBegin);
    let endDate: CalendarDate = new CalendarDate(block.mEnd);
    let yearMonth = DateUtil.intlDateFormat(beginDate, dateOption);

    let top = '';
    let bottom = '';
    let sep = '';
    if (block.isHoliday() || block.mIsAllDay || (block.mIsMultiDayEvent && block.mFlag === AgendaEventInfo.FLAG_MID)) {
      top = GlobalThis.getResourceStr($r('app.string.all_day'));
    } else if (block.mIsMultiDayEvent && block.mFlag === AgendaEventInfo.FLAG_START) {
      top = DateUtil.intlDateFormatChineseStyle(beginDate, timeOption);
      bottom = GlobalThis.getResourceStr($r('app.string.start_date'))
    } else if (block.mIsMultiDayEvent && block.mFlag === AgendaEventInfo.FLAG_END) {
      top = DateUtil.intlDateFormatChineseStyle(endDate, timeOption);
      bottom = GlobalThis.getResourceStr($r('app.string.end_date'));
    } else {
      top = DateUtil.intlDateFormatChineseStyle(beginDate, timeOption);
      bottom = DateUtil.intlDateFormatChineseStyle(endDate, timeOption);
      sep = '至';
    }
    // todo 待翻译回稿
    if (this.isFold()) {
      return `${yearMonth}${top},有${this.infoList.length}条临近日程`;
    }
    let title = block.mTitle ? block.mTitle : GlobalThis.getResourceStr($r('app.string.no_title_label'));
    return yearMonth + ',' + top + sep + bottom + ',' + title + ',' + block.mLocation;
  }
}