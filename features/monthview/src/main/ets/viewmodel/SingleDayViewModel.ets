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
  ARABIC_LANGUAGE,
  CalendarDate,
  CHINESE_HOLIDAY_STATE_VALUE,
  CommonInnerEvent,
  DateManager,
  DateUtil,
  DayData,
  DayMark,
  DeviceConfig,
  EmptyUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  HolidayUtil,
  I18nUtil,
  Log,
  LunarDateUtil,
  NavPathManager,
  NavPathName,
  NumberFormatManager,
  ReportUtil,
  RouterName,
  ServiceEnum,
  ServiceManager,
  statisticEvents,
  TabType,
  TextParagraphManager,
} from '@app/common';
import { DayViewState, MonthlyViewStateManager } from './MonthlyViewState';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { FestivalDay, FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import emitter from '@ohos.events.emitter';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { i18n } from '@kit.LocalizationKit';
import { ColorType, PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
import { PaintCache, TextArg } from '@app/common/src/main/ets/graphic/PaintCache';
import { drawing } from '@kit.ArkGraphics2D';
import { Size } from '@kit.ArkUI';
import { DayCellLayout, ReadOnlyDayCellProp } from '../layoutmodel/DayCellLayoutRule';
import { addOnlySelectStatusText, addTodayText,
  broadcastContent } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { HashMap } from '@kit.ArkTS';
import { FestivalAbbreviationMap } from '@app/common/src/main/ets/date/FestivalAbbreviationMap';

const TAG: string = `[MonthlyView][SigDayVM]`;

@Observed
export class SingleDayViewModelArray extends Array<SingleDayViewModel> {
}

const SELECT_TAG_LENGTH: number = 3;
const NO_SELECT_TAG_LENGTH: number = 4;
const RECESS_WIDTH_OR_HEIGHT: number = 10; // 班休字体宽高
const RECESS_CIRCLE_RADIUS: number = 7; // 班休选中圈半径

export class SingleDayViewModel extends DrawModifier {
  public layout: DayCellLayout = new DayCellLayout();
  public state: DayViewState = new DayViewState();
  // dayData 对象 用于记录历法、日期以及其他内容 优先使用该对象
  public dayData: DayData = new DayData(0, 0, 0);
  // 公历日期 当前所在周的年、月、周数（以当年1月4日所在周为第一周） 当前不支持 @Observed 嵌套 此变量用于唯一标识VM
  public dateInfo: DateInfo = new DateInfo(0, 0);
  // 公历日期
  public day: number = -1
  // 今天
  public isToday: boolean = false;
  // 班休 0、undefined、null:普通  1：休  2：班
  public mark: DayMark = DayMark.NORMAL;
  // 历法
  public calendar: string = '占位';
  // 节气
  public term: string = '';
  // 节日
  public holiday: string = '';
  // 选中
  public isSelect: boolean = false;
  // 是否农历月份的第一天
  public isFirstLunarDay: boolean = false;
  // 是否农历初一
  public isFirstLunarMonth: boolean = false;
  // 是否属于当前展示的月份
  public isCurrentMonth: boolean = false;
  // 是否是周末
  public isWeekends: boolean = false;
  public showTagText: boolean = false; // 是否显示TAG

  // 是否显示班休
  public showRecessData: boolean = false;
  public recessText: string = '';
  // 界面是否显示农历下划线
  public showLunarLine: boolean = false;
  // 当天的节假日
  public festivals: FestivalDay[] = [];
  //当天是否有节假日
  public hasFestivals: boolean = false;
  // 当天是否有日程
  public isHasInstances: boolean = false;
  // 当天是否有除节假日以外的日程
  public isExceptHolidaysInstancesFlags: boolean = false;
  // 当天的标签是否显示节气
  public festivalTerm: boolean = true;
  public weekNumIndex: number = -1;
  public dayIndex: number = -1; // vm在月视图vm的索引值
  // 当天是否有日程
  public isFirstDayOfMonth: boolean = false;
  // 节假节日
  public tagText: string = ''; // 节假日、节气、农历 归一化裁剪TAG
  private oriTagText: string = ''; // 原节假日字串,用于宫格化实时进行省略号拆分
  private finTagText: string = ''; // 宫格化下最终显示用的文字

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;
  // vm改变状态变量需要同步回view
  public vmSelectChange: () => void = (): void => {
  };
  private isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
  // 动效用颜色变化
  private dateColorChange: boolean = false;
  private chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE | undefined =
    AppStorage.get('CHINESE_HOLIDAY_STATE') ?? CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;

  private halfHeight = 0;
  private halfWidth = 0;

  private isAR: boolean = false; // 是否为阿拉伯语

  public set gridview(isGrid: boolean) {
    this.isGrid = isGrid;
  }

  constructor(weekNumInd: number, dayData?: DayData, dateInfo?: DateInfo, dayIndex?: number) {
    super();
    this.layout = MonthViewLayoutModel.getInstance().dayLayout.value;
    this.state = MonthlyViewStateManager.getInstance().dayState;
    this.weekNumIndex = weekNumInd;
    if (this.weekNumIndex === -1) {
      Log.error(TAG, `weekNumIndex is -1`);
      return;
    }
    if (dayIndex !== undefined) {
      this.dayIndex = dayIndex;
      if (this.dayIndex === 0 && this.weekNumIndex === 0) {
        this.isFirstDayOfMonth = true;
      }
    }
    if (!dateInfo || !dayData) {
      Log.error(TAG, `NO VALID DATE INFO TO BUILD DAY!dateInfo = ${dateInfo}, dayData = ${dayData})`);
      return;
    }
    this.parseBaseState(dayData, dateInfo);
    this.processLanguage(I18nUtil.getSystemLanguage());
    this.parseHolidayAndTerm(dayData);
    this.parseShowRecessDataChange();
    this.updateDayCell();


    this.invalidate();
  }

  update(dayData?: DayData, dateInfo?: DateInfo) {
    if (!dateInfo || !dayData) {
      Log.error(TAG, `update: NO VALID DATE INFO TO BUILD DAY!dateInfo = ${dateInfo}, dayData = ${dayData}`);
      return;
    }
    this.parseBaseState(dayData, dateInfo);
    this.processLanguage(I18nUtil.getSystemLanguage());
    this.parseHolidayAndTerm(dayData);
    this.parseShowRecessDataChange();
    this.onSelectChange(false); // 默认置为不选中，在外部通过VM来实现选中状态
    this.updateDayCell();
    this.invalidate();
  }

  /**
   * 更新单日宫格样式
   */
  updateDayCell() {
    this.updateRecessTextProp();
    const showCalendar = MonthlyViewStateManager.getInstance().dayState.showCalendar;
    this.onSubscriptionCalendar(showCalendar);
    this.invalidate();
  }

  // 更新AgendaMini变更
  updateAgendaMini(showCalendar: boolean) {
    this.updateTagTextProp(showCalendar);
    this.invalidate();
  }

  /**
   * 处理基础单天宫格的基础信息
   *
   * @param dayData 每天的日期数据
   * @param dateInfo 当天的视图信息
   */
  parseBaseState(dayData: DayData, dateInfo: DateInfo): void {
    // 处理数据信息
    this.dateInfo = new DateInfo(dateInfo.year, dateInfo.month, dateInfo.weekNum, dateInfo.day);
    this.dateInfo.day = dayData.solarDay;
    this.day = dayData.solarDay;
    this.dayData = dayData;

    // 处理状态信息
    this.isCurrentMonth = this.dateInfo.month === dayData.solarMonth;
    this.isFirstLunarDay = dayData.lunarDay === 1;
    this.isFirstLunarMonth = dayData.lunaMonth === 1;
    const state = MonthlyViewStateManager.getInstance().state;
    this.isWeekends = state.weekends.includes(this.dayData.getWeekDay(false));
    this.isToday = this.parseIsToday();

    this.mark = dayData.dayMark;
    this.updateRecessTextProp();
    this.parseCalendar();
    this.festivals = dayData.festivals;
    return;
  }

  /**
   * 处理历法变更
   */
  parseCalendar() {
    if (MonthlyViewStateManager.getInstance().state.isIslamicCalendar()) {
      let calendar: i18n.Calendar = i18n.getCalendar(MonthlyViewStateManager.getInstance()
        .state
        .systemRegion, 'islamic_civil');
      const date: Date = new Date(this.dayData.getTimeStamp());
      calendar.setTime(date);
      this.calendar = calendar.get('date').toString();
    } else {
      if (DateUtil.isNeedDisplayLunaMonth(this.dayData.solarYear)) {
        const language = MonthlyViewStateManager.getInstance().state.language;
        this.calendar = LunarDateUtil.parseLeapLunaMonth(this.dayData, language);
      } else {
        this.calendar = '';
      }
    }
  }

  /**
   * 处理节假日和节气
   */
  parseHolidayAndTerm(dayData: DayData): void {
    const language = MonthlyViewStateManager.getInstance().state.language;
    let tempTerm: string = '';
    let tempHoliday: string = '';
    for (let i = 0; i < dayData.festivals.length; i++) {
      if (tempTerm === '' && dayData.festivals[i].type === FestivalType.SOLAR_TERM) {
        tempTerm = GlobalThis.getResourceStr(dayData.festivals[i].resource, language);
      }
      if (tempHoliday === '' && dayData.festivals[i].type !== FestivalType.SOLAR_TERM &&
        (MonthlyViewStateManager.getInstance().dayState.showChineseHoliday ||
        this.checkIsChineseFestival(dayData.festivals[i]))
      ) {
        tempHoliday = GlobalThis.getResourceStr(dayData.festivals[i].resource, language);
        if (EmptyUtils.isEmptyString(tempHoliday)) {
          tempHoliday = dayData.festivals[i].name;
        }
      }
    }
    if (this.dayData.festivalName && this.dayData.festivalName !== '') {
      tempHoliday = this.dayData.festivalName;
    }
    this.term = tempTerm;

    if (MonthlyViewStateManager.getInstance().state.isIslamicCalendar() ||
    MonthlyViewStateManager.getInstance().state.isNoCalendar() ||
      !DateUtil.isNeedDisplayLunaMonth(this.dayData.solarYear)) {
      this.term = '';
    }

    if (this.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CLOSE) {
      this.holiday = '';
    } else {
      if (this.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN) {
        this.holiday = HolidayUtil.needRemoveHoliday(tempHoliday);
      } else {
        this.holiday = tempHoliday;
      }
    }
    this.hasFestivals = this.term.length !== 0 || this.holiday.length !== 0;
    return;
  }


  getCompId(): string {
    let compId: string = `${this.day}_${this.holiday}_${this.term}_${this.calendar}`;
    return compId;
  }

  checkIsChineseFestival(day: FestivalDay) {
    return day.type !== FestivalType.OFFICIAL_CHINA &&
      day.type !== FestivalType.OFFICIAL_TAIWAN &&
      day.type !== FestivalType.OFFICIAL_HONGKONG;
  }

  /**
   * 处理选中时间变化
   *
   * @param selectDate 选中时间
   * @param isSelect 是否选中
   */
  onSelectDateChange(selectDate: DateInfo, isSelect: boolean = false) {
    Log.debug(TAG, `onSelectDateChange:${selectDate.month}.${selectDate.day},isSelect:${isSelect},day:${this.day}`);
    if (selectDate.day !== this.dateInfo.day) {
      return;
    }
    this.onSelectChange(isSelect);
  }

  /**
   * 改变天宫格的选中状态
   *
   * @param isSelect 当天是否被选中
   */
  onSelectChange(isSelect: boolean) {
    this.isSelect = isSelect;
    this.dateColorChange = false;
    if (this.isSelect) {
      if (DateManager.getInstance().selectedDay.solarMonth === this.dateInfo.month) {
        Log.info(TAG, `onSelectChange isSelect = ${isSelect}, day = ${this.dateInfo.day}`);
        emitter.emit({ eventId: CommonInnerEvent.MONTH_VIEW_SELECT_DAY }, {
          data: {
            'DistanceY': this.weekNumIndex * MonthViewLayoutModel.getInstance().dayLayout.value.circleSize
          }
        })
      }
    }
    // TODO 这里选中视图变化，很多属性不用重新计算的
    this.updateDayCell();

    this.invalidate();

    this.vmSelectChange();
  }

  /**
   * 历法变更
   *
   * @param showCalendar 是否显示历法
   */
  onSubscriptionCalendar(showCalendar: boolean) {
    this.parseCalendar();
    this.parseHolidayAndTerm(this.dayData);
    this.updateTagTextProp(showCalendar);
    this.updateLunarLineProp(showCalendar);

    this.invalidate();
  }

  // 更新语言
  onLanguageChange(language: string): void {
    const showCalendar = MonthlyViewStateManager.getInstance().dayState.showCalendar;
    this.parseCalendar();
    this.parseHolidayAndTerm(this.dayData);
    this.updateTagTextProp(showCalendar);
    this.processLanguage(language);
    this.invalidate();
  }

  /**
   * 处理语言逻辑
   * @param language
   */
  processLanguage(language: string): void {
    this.isAR = language.includes(ARABIC_LANGUAGE);
    // 语言切换强制刷新dataFormat
    NumberFormatManager.instance().onLanguageChange(language);
    TextParagraphManager.instance().onLanguageChange(language);
  }

  // 更新主题字体
  onThemeChange(): void {
    this.invalidate();
  }

  /**
   * 当天是否有日程
   */
  onInstancesFlagsChange(isHasInstances: boolean, isExceptHolidaysInstancesFlags: boolean) {
    this.isHasInstances = isHasInstances;
    this.isExceptHolidaysInstancesFlags = isExceptHolidaysInstancesFlags;
    this.invalidate();
  }

  onFestivalsChange(festivalsName: string) {
    this.dayData.festivalName = festivalsName;
    this.parseHolidayAndTerm(this.dayData);
    const showCalendar = MonthlyViewStateManager.getInstance().dayState.showCalendar;
    this.updateTagTextProp(showCalendar);
    this.invalidate();
  }

  onCurrentDateChange(currentDate: number) {
    this.isToday = this.parseIsToday();
    this.dateColorChange = false;
    this.updateDayCell();

    this.invalidate();
  }

  onCurrentDateColorChange(onlyColor: boolean = false) {
    this.isToday = this.parseIsToday();
    this.dateColorChange = this.isToday && !this.isSelect && onlyColor;
    this.isSelect = this.isToday;

    this.invalidate();
  }

  /**
   * 页面变化导致的布局变化
   */
  onLayoutChange() {
    this.updateDayCell();

    this.invalidate();
  }

  onDarkModeChange() {
    this.invalidate();
  }

  onChineseHolidayStateChange(chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE) {
    this.chineseHolidayState = chineseHolidayState;
    this.parseHolidayAndTerm(this.dayData);
    this.updateDayCell();
    this.invalidate();
  }

  onSystemRegionChange(systemRegion: string) {
    this.invalidate();
  }

  /**
   * 是否显示标签文本，显示规则：若历法开则显示，若历法关且手机
   */
  updateShowTagText(showCalendar: boolean) {
    if (showCalendar || this.chineseHolidayState !== CHINESE_HOLIDAY_STATE_VALUE.CLOSE) {
      this.showTagText = true;
      return;
    }
    if (!MonthViewLayoutModel.getInstance().frameProp.value.isSmall) {
      this.showTagText = false;
      return;
    }
    if (this.isSelect) {
      this.showTagText = false;
      return;
    }
    if (this.hasFestivals) {
      this.showTagText = true;
      return;
    }
    this.showTagText = true;
  }

  // 标签文本
  updateTagTextContent(showCalendar: boolean): void {
    const isMini = MonthlyViewStateManager.getInstance().state.isAgendaRowMini;
    if (isMini && this.holiday.length !== 0) {
      const festivalAbbreviationMap: HashMap<string, string> = FestivalAbbreviationMap.getInstance();
      if (festivalAbbreviationMap.hasKey(this.holiday)) {
        this.tagText = festivalAbbreviationMap.get(this.holiday);
      } else {
        this.tagText = this.holiday;
      }
      this.festivalTerm = false;
    } else if (isMini && showCalendar && this.term.length !== 0) {
      this.tagText = this.term;
      this.festivalTerm = true;
    } else if (showCalendar) {
      this.tagText = this.calendar;
    } else {
      this.tagText = '';
    }
    this.oriTagText = this.tagText;
    const maxStrLength: number = this.isSelect ? SELECT_TAG_LENGTH : NO_SELECT_TAG_LENGTH;
    if (this.tagText.length > maxStrLength) {
      this.tagText = this.tagText.slice(0, maxStrLength - 1) + '...';
    }
  }

  updateTagTextProp(showCalendar: boolean): void {
    this.updateTagTextContent(showCalendar);
    this.updateShowTagText(showCalendar);
  }

  updateRecessTextProp(): void {
    this.recessText = this.mark === 0 ? '' : (this.mark === 1 ? '休' : '班');
    this.vmSelectChange();
  }

  // 初一下划线属性  下划线有可能在圈外
  updateLunarLineProp(showCalendar: boolean): void {
    if (!showCalendar) {
      this.showLunarLine = false;
      return;
    }
    if (!DateUtil.isNeedDisplayLunaMonth(this.dayData.solarYear)) {
      this.showLunarLine = false;
      return;
    }
    if (MonthlyViewStateManager.getInstance().state.isIslamicCalendar()) {
      this.showLunarLine = false;
      return;
    }
    if (!this.isFirstLunarDay) {
      this.showLunarLine = false;
      return;
    }
    this.showLunarLine = true;
  }

  getDateColor(): ColorType {
    if (!this.isCurrentMonth) {
      return ColorType.TERTIARY_OPACITY_40;
    }


    if (this.isToday && !this.isSelect && this.mark === DayMark.NORMAL) {
      return ColorType.THEME;
    }

    if (!this.isToday) {
      return this.isWeekends ? ColorType.TERTIARY : ColorType.PRIMARY;
    }

    return this.isSelect ? ColorType.PRIMARY_CONTRARY : ColorType.THEME;
  }

  getRecessColor(): ColorType {
    if (this.isToday && this.isSelect && this.mark === DayMark.OFF) {
      return ColorType.BLUE;
    }
    if (this.isToday && this.isSelect && this.mark === DayMark.WORK) {
      return ColorType.THEME
    }

    if (this.isCurrentMonth) {
      if (this.mark === DayMark.OFF) {
        return ColorType.BLUE;
      } else {
        return ColorType.THEME;
      }
    }

    if (this.mark === DayMark.OFF) {
      return ColorType.BLUE_OPACITY_40;
    }

    return ColorType.THEME_OPACITY_40;
  }

  getTagColor(): ColorType {
    const layout = MonthViewLayoutModel.getInstance().dayLayout.value;
    if (this.isToday && this.isSelect && layout.isVerticalCell) {
      return ColorType.PRIMARY_CONTRARY;
    }

    if (!this.hasFestivals) {
      if (!this.isToday) {
        return this.isCurrentMonth ? ColorType.TERTIARY : ColorType.TERTIARY_OPACITY_40;
      }

      return this.isCurrentMonth ? ColorType.THEME : ColorType.THEME_OPACITY_40;
    }

    return this.isCurrentMonth ? ColorType.THEME : ColorType.THEME_OPACITY_40;
  }

  drawCircle(canvas: drawing.Canvas, size: Size): void {
    if (!this.isSelect || this.dateColorChange) {
      return;
    }
    const color = PaletteCache.instance().getColor(ColorType.THEME);
    const needGrid = this.isGrid;
    const x = needGrid ? this.halfHeight + 2 : this.halfWidth;
    const y = this.halfHeight + 0.5;
    Log.info(TAG, `needGrid: ${needGrid}`);
    const radius = Math.min(this.halfWidth, this.halfHeight) -
      (needGrid ? (this.needCommerce ? 1 : 4) : (this.needCommerce ? 1 : 0.5));
    const paintCache = PaintCache.instance();
    if (this.isToday) {
      const brush = paintCache.getBrush();
      brush.setColor(color);
      brush.setAntiAlias(true);
      canvas.attachBrush(brush);
      canvas.drawCircle(x, y, radius);
      canvas.detachBrush();
    } else {
      const circleWidth = vp2px(this.needCommerce && !needGrid ? 2 : ReadOnlyDayCellProp.circleLine); // PC圆圈过细，有锯齿感
      const pen = paintCache.getPen();
      pen.setColor(color);
      pen.setStrokeWidth(circleWidth);
      pen.setAntiAlias(true);
      canvas.attachPen(pen);
      canvas.drawCircle(x, y, radius - circleWidth / 2);
      canvas.detachPen();
    }
  }

  drawDate(canvas: drawing.Canvas, size: Size): void {
    const layout = MonthViewLayoutModel.getInstance().dayLayout.value;
    const colorType = this.getDateColor();
    const color = PaletteCache.instance().getColor(colorType);
    const paintCache = PaintCache.instance();
    const brush = paintCache.getBrush();
    brush.setColor(color);
    canvas.attachBrush(brush);
    const fontSizeScale = AppStorage.get<number>('fontSizeScale') || 1;
    let fontSize = fontSizeScale > 1 ? layout.solarFontSize + 2 : layout.solarFontSize;
    if (this.needCommerce) {
      fontSize = fontSize + 2;
    }
    const arg: TextArg = {
      fontSize: vp2px(fontSize),
      text: NumberFormatManager.instance().numberFormat(this.day),
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info = paintCache.getText(arg);

    // 处理文本位置
    let x: number = 0;
    let y: number = 0;
    if (this.isGrid) {
      // 宫格,文字位于左侧
      x = this.halfHeight - info.width / 2 + 1.5;
      y = this.halfHeight + info.height / 2 - info.baseline + 1;
    } else if (layout.isVerticalCell) {
      // 竖屏，文字位于中位线以上，再加layout.verticalGap的偏移
      x = this.halfWidth - info.width / 2;
      y = this.halfHeight - info.baseline + vp2px(ReadOnlyDayCellProp.verticalGap);
    } else {
      // 横屏，直接居中展示
      x = this.halfWidth - info.width / 2;
      y = this.halfHeight + info.height / 2 - info.baseline;
    }

    if (this.isAR) {
      // 计算绘制起始点-相对中心偏移
      Log.debug(TAG, `x = ${x}, y = ${y}, info.width = ${info.width}, info.height = ${info.height}`);
      let offsetX = this.day > 9 ? 28 : 12;
      let offsetY = -info.height;
      const paragraph = TextParagraphManager.instance().getTextParagraph(arg.text, info.width, color, fontSize);
      paragraph.paint(canvas, x + offsetX, y + offsetY);
    } else {
      canvas.drawTextBlob(info.blob, x, y);
      canvas.detachBrush();
    }
  }

  drawRecessCircle(canvas: drawing.Canvas, size: Size): void {
    if (!this.showRecessData || (this.mark === DayMark.NORMAL)) {
      return;
    }
    const fontSizeScale = AppStorage.get<number>('fontSizeScale') || 1;
    const isSmall = MonthViewLayoutModel.getInstance().frameProp.value.isSmall;
    let radius = this.layout.circleSize / 2 - Number(fontSizeScale > 1 ? 2 : 0);

    let x = this.halfWidth + this.layout.circleSize + Number(fontSizeScale > 1 ? 8 : 6);
    let y = size.height / 4 - this.layout.circleSize / 3 - Number(fontSizeScale > 1 ? 3 : 0);
    const color = PaletteCache.instance().getColor(isSmall ? ColorType.RECESSCIRCLE : ColorType.RECESS_CIRCLE_BIG);
    if (!this.isGrid && !isSmall) {
      Log.info(TAG,
        `special Circle by isGird : ${this.isGrid} isSmall : ${isSmall} needCommerce :${this.needCommerce}`);
      if (this.needCommerce) {
        // 针对PC分屏场景左右布局月视图非宫格情况特殊处理
        x = this.halfWidth + this.layout.circleSize / 2 + Number(fontSizeScale > 1 ? 5 : 6);
        y = size.height / 4 - this.layout.circleSize / 6 - Number(fontSizeScale > 1) * 5;
        radius = this.layout.circleSize / 4 - Number(fontSizeScale > 1 ? 2 : 0);
      } else {
        // 针对pad自由多窗分屏场景和折叠屏手机左右布局月视图非宫格情况特殊处理
        x = size.width - vp2px(RECESS_CIRCLE_RADIUS);
        y = vp2px(RECESS_CIRCLE_RADIUS);
        radius = vp2px(RECESS_CIRCLE_RADIUS);
      }
    }
    if (this.layout.isVerticalCell || (!this.isGrid && !isSmall)) {
      if ((this.isToday && this.isSelect) || this.isSelect) {
        const brush = PaintCache.instance().getBrush();
        brush.setColor(color);
        brush.setAntiAlias(true);
        canvas.attachBrush(brush);
        canvas.drawCircle(x, y, radius);
      }
    }
    canvas.detachBrush();
  }

  drawRecess(canvas: drawing.Canvas, size: Size): void {
    if (!this.showRecessData || (this.mark === DayMark.NORMAL)) {
      return;
    }
    const recessText = this.mark === DayMark.OFF ? '休' : '班';
    const colorType = this.getRecessColor();
    const color = PaletteCache.instance().getColor(colorType);
    const paintCache = PaintCache.instance();
    const brush = paintCache.getBrush();
    brush.setColor(color);
    canvas.attachBrush(brush);
    const fontSizeScale = AppStorage.get<number>('fontSizeScale') || 1;

    const arg: TextArg = {
      fontSize: vp2px(this.layout.recessFontSize),
      text: recessText,
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info = paintCache.getText(arg);
    const arg1: TextArg = {
      fontSize: vp2px(this.layout.solarFontSize),
      text: this.day.toString(),
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info1 = paintCache.getText(arg1);
    const argTag: TextArg = {
      fontSize: vp2px(this.layout.calOrHolFontSize),
      text: this.finTagText,
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const infoTag = paintCache.getText(argTag);
    const layout = this.layout;
    const isSmall = MonthViewLayoutModel.getInstance().frameProp.value.isSmall;

    if (this.isGrid) {
      // 宫格,文字位于右侧
      const x = size.width - infoTag.width - info.width - vp2px(this.layout.circleSize / 2);
      const y = this.halfHeight + info.height / 2 - info1.baseline + 2;
      canvas.drawTextBlob(info.blob, x, y);
    } else if (!isSmall) {
      Log.info(TAG, `special handling by needCommerce:${this.needCommerce} `);
      if (this.needCommerce) {
        // 针对PC分屏场景左右布局月视图非宫格情况特殊处理
        const x = this.halfWidth + this.layout.circleSize / 4 + 4 + Number(fontSizeScale > 1 ? 5 : 6);
        const y = size.height / 4 - this.layout.circleSize / 12 + 2 - Number(fontSizeScale > 1) * 5;
        canvas.drawTextBlob(info.blob, x, y);
      } else {
        // 针对pad自由多窗分屏场景和折叠屏手机左右布局月视图非宫格情况特殊处理
        const x = size.width - vp2px(RECESS_WIDTH_OR_HEIGHT / 2 + RECESS_CIRCLE_RADIUS);
        const y = vp2px(RECESS_WIDTH_OR_HEIGHT / 2 + RECESS_CIRCLE_RADIUS - 1)
        canvas.drawTextBlob(info.blob, x, y);
      }
    } else if (layout.isVerticalCell) {
      const x = this.halfWidth + this.layout.circleSize / 2 + 8 + Number(fontSizeScale > 1 ? 5 : 6);
      const y = size.height / 4 - this.layout.circleSize / 6 + 4 - Number(fontSizeScale > 1) * 5;
      canvas.drawTextBlob(info.blob, x, y);
    } else {
      // 横屏时，班休x向，位于选中圈右侧，再加2vp间距
      const x = this.halfWidth + vp2px(layout.circleSize / 2 + 2);
      // 横屏时，班休y向，直接与日期顶部对齐
      const y = this.halfHeight - info1.height / 2 + info.height - info.baseline * 2;
      canvas.drawTextBlob(info.blob, x, y);
    }
    canvas.detachBrush();
  }

  drawLunarLine(canvas: drawing.Canvas, size: Size): void {
    if (!this.showLunarLine) {
      return;
    }
    const paintCache = PaintCache.instance();
    // 历法或节假日的下划线
    const calOrHolFontFirstLunarDayLineHeight: number = 1;
    const brush = paintCache.getBrush();
    brush.setColor(PaletteCache.instance().getColor(ColorType.THEME_OPACITY_60));
    canvas.attachBrush(brush);
    const layout = this.layout;
    const needGrid = this.isGrid;
    const arg: TextArg = {
      fontSize: vp2px(layout.calOrHolFontSize),
      text: this.finTagText,
      bold: false,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info = paintCache.getText(arg);
    const lunarLineWidth: number = info.width - vp2px(2);
    let x: number = 0;
    let y: number = 0;
    if (layout.isVerticalCell) {
      // 竖屏，农历横线左右居中，位于历法节气下方
      x = this.halfWidth - lunarLineWidth / 2;
      y = this.halfHeight + vp2px(ReadOnlyDayCellProp.verticalGap) + info.height;
      canvas.drawRect({
        left: x,
        top: y,
        right: x + lunarLineWidth,
        bottom: y + vp2px(calOrHolFontFirstLunarDayLineHeight)
      });
    } else {
      // 横屏，农历横线于右侧，位于历法节气下方
      x = needGrid ? size.width - info.width - vp2px(this.layout.circleSize / 2 - 6) :
        this.halfWidth + vp2px(layout.circleSize / 2 + 2);
      y = this.halfHeight + info.height / 2 - info.baseline / 2 + 3;
      canvas.drawRect({
        left: x,
        top: y,
        right: x + lunarLineWidth,
        bottom: y + vp2px(calOrHolFontFirstLunarDayLineHeight)
      });
    }
    canvas.detachBrush();
  }

  drawTagText(canvas: drawing.Canvas, size: Size): void {
    // 空串不需要绘制，会导致异常
    if ((this.tagText.length === 0) || !this.showTagText) {
      return;
    }

    const colorType = this.getTagColor();
    const color = PaletteCache.instance().getColor(colorType);
    const paintCache = PaintCache.instance();
    const brush = paintCache.getBrush();
    brush.setColor(color);
    canvas.attachBrush(brush);
    const arg1: TextArg = {
      fontSize: vp2px(this.layout.solarFontSize),
      text: this.day.toString(),
      bold: true,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info1 = paintCache.getText(arg1);

    this.finTagText = this.layout.isVerticalCell ? this.tagText : this.oriTagText;
    // 计算宫格的tag能够显示的字数
    if (this.isGrid || (!this.layout.isVerticalCell && this.oriTagText.length > SELECT_TAG_LENGTH)) {
      const recessLength = this.showRecessData ? this.layout.recessFontSize + 4 : 0;
      const gridLength =
        px2vp(size.width) - this.layout.circleSize - this.layout.circleSize / 2 + px2vp(info1.width / 2) - recessLength;
      const length = this.isGrid ? Math.floor((gridLength) / this.layout.calOrHolFontSize) :
      Math.floor((px2vp(size.width) / 2 - (this.layout.circleSize / 2) - 1.5) / this.layout.calOrHolFontSize);
      this.finTagText =
        this.oriTagText.length > length ? this.oriTagText.slice(0, length - 1) + '...' : this.oriTagText;
    }

    const arg: TextArg = {
      fontSize: vp2px(this.layout.calOrHolFontSize),
      text: this.finTagText,
      bold: false,
      fontFamily: paintCache.getFontFamilyPath()
    };
    const info = paintCache.getText(arg);
    let x: number = 0;
    let y: number = 0;
    if (this.isGrid) {
      // 宫格,文字位于右侧居中
      x = size.width - info.width - vp2px(this.layout.circleSize / 2 - 6);
      y = this.halfHeight + info.height / 2 - info1.baseline + 2;
      canvas.drawTextBlob(info.blob, x, y);
    } else if (this.layout.isVerticalCell) {
      // 竖屏时，左右居中，位于日期下方
      x = this.halfWidth - info.width / 2;
      y = this.halfHeight + info.height - info.baseline + vp2px(ReadOnlyDayCellProp.verticalGap);
    } else {
      // 横屏时，上下居中+layout.calOrHolFontMarginTop，位于日期右方+2vp，与班休、农历横线左对齐
      x = this.halfWidth + vp2px(this.layout.circleSize / 2 + 1.5);
      if (this.showRecessData) {
        // 有班休时，与日期底部对齐
        y = this.halfHeight + info1.height / 2 - info1.baseline + ReadOnlyDayCellProp.calOrHolFontMarginTop;
      } else {
        // 无班休时，垂直居中显示
        y = this.halfHeight + info.height / 2 - info.baseline + ReadOnlyDayCellProp.calOrHolFontMarginTop;
      }
    }

    canvas.drawTextBlob(info.blob, x, y);
    canvas.detachBrush();
  }

  drawAgendaDot(canvas: drawing.Canvas, size: Size): void {
    const layout = this.layout;
    const isAgendaRowMini = MonthlyViewStateManager.getInstance().state.isAgendaRowMini;
    if (!(isAgendaRowMini && this.isExceptHolidaysInstancesFlags)) {
      return;
    }
    const colorType = (this.isSelect && this.isToday) ?
    ColorType.PRIMARY_CONTRARY : ColorType.THEME_OPACITY_40;
    const color = PaletteCache.instance().getColor(colorType);
    const brush = PaintCache.instance().getBrush();
    brush.setColor(color);
    canvas.attachBrush(brush);
    const x: number = this.halfWidth;
    let y: number = this.halfHeight +
    vp2px(layout.calOrHolFontHeight + ReadOnlyDayCellProp.verticalGap + ReadOnlyDayCellProp.agendaMarginTop) - 1;
    const radius = vp2px(layout.agendaPointSize) / 2;
    // hiCar日程标点向上偏移3vp,小折叠外屏向上偏移2vp
    const modeState = MonthlyViewStateManager.getInstance().modeState;
    if (modeState.isForceSmall) {
      y -= 3;
    } else if (modeState.isInSmallFold) {
      y -= 2;
    }

    canvas.drawCircle(x, y, radius);
    canvas.detachBrush();
  }

  drawContent(context: DrawContext): void {
    const canvas = context.canvas;
    const size: Size = { width: vp2px(context.size.width),
      height: vp2px(MonthViewLayoutModel.getInstance().dayLayout.value.circleSize ) };
    this.isGrid = MonthViewLayoutModel.getInstance().frameProp.value.isGrid;
    this.halfHeight = size.height / 2;
    this.halfWidth = size.width / 2;
    this.drawCircle(canvas, size);
    this.drawDate(canvas, size);
    this.drawTagText(canvas, size);
    this.drawRecessCircle(canvas, size);
    this.drawRecess(canvas, size);
    this.drawLunarLine(canvas, size);
    this.drawAgendaDot(canvas, size);
  }

  /**
   * 根据班休数据处理是否显示班休 班休数据为 0、undefined、null 表示当天不需要显示班休
   */
  private parseShowRecessDataChange(): void {
    // 初始化时，如果班休没有数据则不显示班休
    if (this.mark === undefined || this.mark === null) {
      this.showRecessData = false;
    }
    if (this.mark === 0) {
      this.showRecessData = false;
    }
    return;
  }

  /**
   * 判断当前天数据是否与实时时间相同
   */
  private parseIsToday(): boolean {
    // 转换系统时区对比
    const curDate: Date = DateUtil.getLockTimeZoneDate(MonthlyViewStateManager.getInstance().state.currentDate);
    return DateUtil.isSameYearMonthDay(this.dayData.getOriDate(), curDate);
  }

  /**
   * 点击日期和空白区域触发逻辑
   * @param isBackToToday 是否处于回到今天状态
   * @param dayAccessibilityText 点击天的语言播报信息
   * @param isClickDateArea 是否为点击日期
   */
  onClickChangeDisplayDate(isBackToToday: boolean,
                           dayAccessibilityText: string | undefined, isClickDateArea: boolean = false) {
    const dayData = this.dayData;
    if (dayData === null || dayData === undefined) {
      Log.error(TAG, 'onClickSingleDay NO VALID DATE INFO TO BUILD DAY!');
      return;
    }

    Log.info(TAG, `onClick dayData =  + ${dayData.toString()}, isBackToToday ${isBackToToday}`);
    //正处于回到今天动画中,不触发点击事件
    if (isBackToToday) {
      return;
    }

    const newDisplayDate: number = DateUtil.dateToStamp(
      dayData.solarYear,
      dayData.solarMonth - 1,
      dayData.solarDay);
    Log.info(TAG,
      `onClickChangeDisplayDate newDisplayDate = ${newDisplayDate}, date: : ${dayData.solarYear}.${dayData.solarMonth}.${dayData.solarDay}`);
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDisplayDate);
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });

    this.jumpToOtherView(isClickDateArea);

    ReportUtil.reportStatisticEvent(statisticEvents.monthClickDate);
    if (dayAccessibilityText) {
      broadcastContent(addOnlySelectStatusText(dayAccessibilityText, true));
    }
  }

  /**
   * 跳转其他界面逻辑
   * @param isClickDateArea 是否点击日期区域
   */
  private jumpToOtherView(isClickDateArea: boolean) {
    // hicar点击日期需要跳转全部日程
    if (MonthlyViewStateManager.getInstance().modeState.isForceSmall) {
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.AGENDA_LIST,
        routerName: RouterName.ENTRY_HAP,
        param: {}
      });
      return;
    }

    // 接下来是月视图跳转日视图逻辑
    if (!this.isSelect) { // 只有选中日期后再次点击该日期才需要跳转
      return;
    }
    if (!isClickDateArea) { // 点击日期下方甘特区域不需要跳转,与产品对齐因当前甘特区域存在长按和双击新建日程逻辑故暂不做跳转
      return;
    }
    if (MonthlyViewStateManager.getInstance().modeState.isInSmallFold) { // 小折叠外屏不需要跳转日视图
      return;
    }
    if (!MonthlyViewStateManager.getInstance().weekState.isFullShow &&
      MonthViewLayoutModel.getInstance().frameProp.value?.isSmall) { // 小屏只有在全屏月视图状态才需要跳转,与双保持一致
      return;
    }

    // 已选中的日期再次点击需要跳转日视图
    GlobalData.instance().set(GlobalDataKeys.TAB_INDEX, TabType.DAY);
    let eventData: emitter.EventData = {
      data: {
        'tabIndex': TabType.DAY,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData);
  }

  getAccessibilityText(): string {
    // 月/日-星期-农历-节气/节日
    let option: Record<string, string> = {
      'month': 'long',
      'weekday': 'long',
      'day': 'numeric'
    }
    // 非本年加上年信息，否则不加
    const currentYear = new CalendarDate().getFullYear();
    if (currentYear !== this.dayData.solarYear) {
      option.year = 'numeric';
    }
    let dateStr = DateUtil.intlDateFormat(this.dayData.getDate(), option);
    const language = MonthlyViewStateManager.getInstance().state.language;
    let lunarDateStr = LunarDateUtil.toFullLunarDateString(this.dayData.getDate(), language);
    let dateDetailInfo = dateStr + lunarDateStr + this.term + this.holiday;
    if (this.isHasInstances) {
      dateDetailInfo += GlobalThis.getResourceStr($r('app.string.have_a_agenda'));
    }
    if (language === 'zh-Hans' || language === 'zh-Hant') {
      return this.recessText + addTodayText(dateDetailInfo, this.isToday);
    } else {
      return addTodayText(dateDetailInfo, this.isToday);
    }
  }
}
