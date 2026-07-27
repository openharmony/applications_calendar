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

import { DayModel } from '../model/DayModel';
import { RootViewModel } from './RootViewModel';
import {
  DateUtil,
  DayMark,
  SubscriptionCalendar,
  CompId,
  LunarDateUtil,
  GlobalThis,
  CHINESE_HOLIDAY_STATE_VALUE,
  CalendarDate,
  TabType,
  NumberFormatManager,
  Log
} from '@app/common';
import { i18n } from '@kit.LocalizationKit';
import { RootModel } from '../model/RootModel';
import { addOnlySelectStatusText, addTodayText } from '@app/common/src/main/ets/util/AccessibilityUtil';

const SOLAR_DATE_NORMAL_COLOR: Resource = $r('sys.color.font_primary'); // 公历日期普通颜色
const SOLAR_DATE_TODAY_COLOR: Resource = $r('app.color.red_common'); // 公历日期当天颜色
const SOLAR_DATE_WEEKEND_COLOR: Resource = $r('sys.color.font_tertiary'); //
const SELECT_TODAY_COLOR_IN_CIRCLE: Resource = $r('sys.color.ohos_id_color_background'); // 选中当天圈类文字颜色
const CALENDAR_NORMAL_COLOR: Resource = $r('sys.color.font_tertiary'); // 历法
const CALENDAR_TODAY_COLOR: Resource = $r('app.color.red_common'); // 历法当天颜色
const FESTIVAL_NORMAL_COLOR: Resource = $r('app.color.red_common'); // 节假日颜色
const AGENDA_DOT_NORMAL_COLOR: Resource = $r('app.color.red_common'); // 未过期日程颜色

@Observed
export class DateCellViewModel {
  public isSelect: boolean = false;
  public index: number = 0;
  public solarDateStr: string = '20'; // 公历
  public extraInfoStr: string = '初一'; // 历法/节假日
  public solarOpacity: number = 1;
  public extraInfoOpacity: number = 1;
  public hasAgenda: boolean = false; // 日程
  public showLunarMonthUnderline: boolean = false;
  public solarDateMarkAnchor: Position = {};
  public solarDatePosition: Position = {};
  public extraInfoMarkAnchor: Position = {};
  public extraInfoPosition: Position = {};
  public lunarUnderlineMarkAnchor: Position = {};
  public lunarUnderlinePosition: Position = {};
  public lunarUnderlineWidth: number = 13;
  public agendaDotMarkAnchor: Position = {};
  public agendaDotPosition: Position = {};
  public solarDateColor: Resource = SOLAR_DATE_NORMAL_COLOR;
  public extraInfoColor: Resource = CALENDAR_NORMAL_COLOR;
  public agendaDotColor: Resource = AGENDA_DOT_NORMAL_COLOR;
  public compId: string = '';
  private dayModel: DayModel = new DayModel(new CalendarDate());
  private rootVM: RootViewModel = new RootViewModel(0);
  private isWeekend: boolean = false;
  public accessibilityTextStr: string = '';

  constructor(index: number, rootVM: RootViewModel) {
    this.index = index;
    this.rootVM = rootVM;
  }

  updateDayModel(dayModel: DayModel): void {
    this.dayModel = dayModel;
    this.solarDateStr = NumberFormatManager.instance().numberFormat(dayModel.solarDay);
    this.updateExtraInfo();
    this.updateColor();
    this.resetLayout();
    this.updateCompId();
    this.getAccessibilityTextStr();
  }

  getDayModel(): DayModel {
    return this.dayModel;
  }

  isExtraInfoOnRight() {
    return this.rootVM.extraInfoRight;
  }

  resetLayout(): void {
    if (this.rootVM.extraInfoRight) {
      this.resetLayoutAdapt();
    } else {
      this.resetLayoutPhone();
    }
  }

  getAccessibilityTextStr() {
    this.accessibilityTextStr = this.getAccessibilityText();
    const isDayView = this.rootVM.tabType === TabType.DAY;
    const doubleClickAgendaStr = GlobalThis.getResourceStr($r('app.string.broadcast_double_tap_view_agenda'));
    const swipeDayStr = GlobalThis.getResourceStr($r('app.string.broadcast_swipe_day'));
    const swipeWeekStr = GlobalThis.getResourceStr($r('app.string.broadcast_swipe_week'));
    const doubleClickStr = GlobalThis.getResourceStr($r('app.string.double_click_finger_execute'));
    if (this.isToday() && this.isSelect) {
      this.accessibilityTextStr += isDayView ?
        `, ${doubleClickAgendaStr}, ${swipeDayStr}` :
        `, ${doubleClickAgendaStr}, ${swipeWeekStr}`;
    } else if (this.index === 0) {
      this.accessibilityTextStr += isDayView ?
        `, ${doubleClickStr}, ${swipeDayStr}` :
        `, ${doubleClickStr}, ${swipeWeekStr}`;
    } else {
      this.accessibilityTextStr += `, ${doubleClickStr}`;
    }
  }

  resetLayoutAdapt(): void {
    this.agendaDotMarkAnchor = { x: 0, y: '50%' };
    this.solarDateMarkAnchor = { x: '50%', y: '50%' };
    const solarX = this.rootVM.dateMargin * 2 + this.rootVM.agendaDotRadius * 2 + this.rootVM.selectCircleRadius;
    const agendaDotX: number = this.rootVM.dateMargin * 2 + this.rootVM.agendaDotRadius + this.rootVM.selectCircleRadius;
    const agendaDotY: number = this.rootVM.selectCircleRadius * 2 - this.rootVM.agendaDotRadius * 2;
    this.solarDatePosition = { x: solarX, y: this.rootVM.dateHeight / 2 };
    this.agendaDotPosition = { x: agendaDotX, y: agendaDotY };
    this.lunarUnderlineWidth = this.rootVM.extraInfoCharCodeWidth * this.extraInfoStr.length;
    this.extraInfoMarkAnchor = { x: 0, y: this.rootVM.extraInfoHeight / 2 };
    const extraX: number = solarX + this.rootVM.selectCircleRadius + this.rootVM.dateMargin;
    const extraY: number = this.rootVM.dateHeight / 2 + this.rootVM.extraInfoHeight -
      (this.rootVM.solarDateFontSize - this.rootVM.extraInfoFontSize) / 4
    if (this.dayModel.dayMark === DayMark.NORMAL) {
      this.extraInfoPosition = { x: extraX, y: this.rootVM.dateHeight / 2 + 1 };
    } else {
      this.extraInfoPosition = { x: extraX, y: extraY };
    }

    this.lunarUnderlineMarkAnchor = { x: 0, y: 0 };
    if (this.dayModel.dayMark === DayMark.NORMAL) {
      this.lunarUnderlinePosition = { x: extraX, y: this.rootVM.dateHeight / 2 + 6 };
    } else {
      this.lunarUnderlinePosition = { x: extraX, y: extraY + this.rootVM.extraInfoFontSize / 2 };
    }
  }

  resetLayoutPhone(): void {
    const centerX = this.rootVM.weekTitleVM.dateCellWidth / 2;
    const centerY = this.rootVM.dateHeight / 2;
    const startY = centerY -
      (this.rootVM.solarDateHeight + this.rootVM.extraInfoHeight + this.rootVM.agendaDotRadius) / 2 - 2;
    this.agendaDotMarkAnchor = { x: this.rootVM.agendaDotRadius, y: this.rootVM.agendaDotRadius * 2 };
    this.agendaDotPosition = {
      x: centerX,
      y: centerY + this.rootVM.selectCircleRadius - this.rootVM.agendaDotRadius * 2 - 2
    };
    this.solarDateMarkAnchor = { x: '50%', y: '0%' };
    this.solarDatePosition = { x: centerX, y: startY };

    if (this.rootVM.isNoCalendar() && this.rootVM.chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CLOSE) {
      this.solarDateMarkAnchor = { x: '50%', y: '50%' };
      this.solarDatePosition = { x: centerX, y: centerY };
      return;
    }

    this.extraInfoMarkAnchor = { x: '50%', y: '0%' };
    const extraY = startY + this.rootVM.solarDateHeight / 2 + this.rootVM.extraInfoHeight - this.rootVM.agendaDotRadius;
    this.extraInfoPosition = { x: centerX, y: extraY };
    this.lunarUnderlineWidth = this.rootVM.extraInfoCharCodeWidth * 2;
    this.lunarUnderlineMarkAnchor = { x: '50%', y: '0%' };
    this.lunarUnderlinePosition = { x: centerX, y: extraY + this.rootVM.extraInfoHeight };
  }

  updateExtraInfo(language?: string): void {
    this.showLunarMonthUnderline = false;
    const showCalendar = this.rootVM.isShowCalendar() && DateUtil.isNeedDisplayLunaMonth(this.dayModel.solarYear);
    if (showCalendar) {
      this.showLunarMonthUnderline = this.dayModel.isFirstDayOfMonth();
    }
    //添加更新额外信息时判断是否为中国区域
    const isChineseRegion = this.rootVM.isChineseRegion();
    const chineseHolidayState = this.rootVM.getChineseHolidayState();
    this.dayModel.updateShowFestivals(this.rootVM.isShowCalendar(),
      isChineseRegion, chineseHolidayState);
    if (!language) {
      language = RootModel.instance().language;
    }
    if (this.dayModel.festivalName && this.dayModel.festivalName !== '') {
      this.extraInfoStr = this.dayModel.festivalName;
      if (this.extraInfoStr !== '') {
        return;
      }
    }
    if (this.dayModel.hasShowFestival()) {
      this.extraInfoStr = this.dayModel.getShowFestival(language);
      if (this.extraInfoStr !== '') {
        return;
      }
    }
    if (this.isIslamicCalendar()) {
      let calendar: i18n.Calendar = i18n.getCalendar(this.rootVM.getSystemRegion(), 'islamic_civil');
      const date: Date = new Date(this.dayModel.getTimeStamp());
      calendar.setTime(date);
      this.extraInfoStr = calendar.get('date').toString();
      return;
    }
    if (!showCalendar) {
      this.extraInfoStr = '';
      return;
    }

    if (this.dayModel.isFirstDayOfMonth()) {
      this.extraInfoStr = LunarDateUtil.parseLeapLunaMonth(this.dayModel, language);
      return;
    }
    this.extraInfoStr = LunarDateUtil.getChineseDay(this.dayModel.lunarDay, language);
  }

  isIslamicCalendar(): boolean {
    return this.rootVM.getSubscriptionCalendar() ===
    SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR;
  }

  updateColor(): void {
    if (this.isToday()) {
      this.solarDateColor = this.isSelect ? SELECT_TODAY_COLOR_IN_CIRCLE : SOLAR_DATE_TODAY_COLOR;
    } else {
      this.solarDateColor = this.isWeekend ? SOLAR_DATE_WEEKEND_COLOR : SOLAR_DATE_NORMAL_COLOR;
    }

    // 圈中当天文本的颜色
    if (this.isSelect && this.isToday() && !this.rootVM.extraInfoRight) {
      this.extraInfoColor = SELECT_TODAY_COLOR_IN_CIRCLE;
      this.agendaDotColor = SELECT_TODAY_COLOR_IN_CIRCLE;
      return;
    }

    this.agendaDotColor = AGENDA_DOT_NORMAL_COLOR;
    if (this.isSelect && this.isToday() && this.rootVM.extraInfoRight) {
      this.agendaDotColor = SELECT_TODAY_COLOR_IN_CIRCLE;
    }

    this.extraInfoColor = ((this.rootVM.isShowCalendar() && !this.isIslamicCalendar()) ||
      this.rootVM.getChineseHolidayState() !== CHINESE_HOLIDAY_STATE_VALUE.CLOSE) &&
      (this.dayModel.hasShowFestival() || (this.dayModel.festivalName && this.dayModel.festivalName !== ''))
      ? FESTIVAL_NORMAL_COLOR :
      (this.isToday() ? CALENDAR_TODAY_COLOR : CALENDAR_NORMAL_COLOR);
  }

  updateCompId(): void {
    const viewType: string = this.rootVM.isWeekView() ? CompId.WEEK_VIEW_ROOT : CompId.DAY_VIEW_ROOT;
    // 视图-日期-农历/节假日-是否今天
    this.compId = `${viewType}_${this.solarDateStr}_${this.extraInfoStr}_${this.isSelect}`;
  }

  updateWeekend(isWeekend: boolean): void {
    this.isWeekend = isWeekend;
    this.updateColor();
  }

  updateAgendaDot(): void {
    this.hasAgenda = this.dayModel.hasAgenda();
    this.resetLayout();
    this.updateColor();
  }

  setSelect(isSelect: boolean): void {
    if (this.isSelect === isSelect) {
      return;
    }

    this.isSelect = isSelect;
    this.updateCompId();
    this.resetLayout();
    this.updateColor();
  }

  isToday(): boolean {
    return new CalendarDate().setHours(0, 0, 0, 0) ===
    new CalendarDate(this.dayModel.getTimeStamp()).setHours(0, 0, 0, 0);
  }

  updateExtra(): void {
    this.updateExtraInfo();
    this.updateColor();

    this.resetLayout();
  }

  updateLanguage(language: string): void {
    this.updateExtraInfo(language);
    // 更新到阿拉伯语言后，需要日期数字部分
    this.solarDateStr = NumberFormatManager.instance().numberFormat(this.dayModel.solarDay);
  }

  onChineseHolidayStateChange(): void {
    this.updateExtraInfo();
    this.updateColor();
    this.resetLayout();
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
    if (currentYear !== this.dayModel.solarYear) {
      option.year = 'numeric';
    }
    const date = this.dayModel.getDate();
    let dateStr = DateUtil.intlDateFormat(date, option);
    let lunarDateStr = LunarDateUtil.toFullLunarDateString(date);
    let holiday = '';
    if (this.dayModel.hasShowFestival()) {
      holiday = this.dayModel.getShowFestival();
    }
    let dateDetailInfo = dateStr + lunarDateStr + holiday;
    if (this.dayModel.hasAgenda()) {
      dateDetailInfo += GlobalThis.getResourceStr($r('app.string.have_a_agenda'));
    }
    return addTodayText(dateDetailInfo, this.isToday());
  }
}