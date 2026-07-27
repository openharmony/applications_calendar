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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { SubscriptionCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';
import { LunarDateUtil } from '@app/common/src/main/ets/date/LunarDateUtil';
import { HolidayUtil, CHINESE_HOLIDAY_STATE_VALUE } from '@app/common/src/main/ets/date/HolidayUtil';
import { DayData } from '@app/common/src/main/ets/date/Date';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { DayMark } from '@app/common/src/main/ets/constants/Constants';
import { FestivalDay, FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { CardSingleDayViewModel } from '../viewModel/components/CardSingleDayViewModel';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { SettingsDataModel } from './SettingsDataModel';
import { i18n } from '@kit.LocalizationKit';
import { FestivalAbbreviationMap } from '@app/common/src/main/ets/date/FestivalAbbreviationMap';
import { HashMap } from '@kit.ArkTS';

const TAG: string = 'MonthCard_SigDayVM';

/**
 * 月视图卡片单日数据模型
 */
@Observed
export class SingleDayViewModel {
  // dayData 对象 用于记录历法、日期以及其他内容 优先使用该对象
  public dayData: DayData = new DayData(0, 0, 0);
  // 公历日期 当前所在周的年、月、周数（以当年1月4日所在周为第一周） 当前不支持 @Observed 嵌套 此变量用于唯一标识VM
  public dateInfo: DateInfo = new DateInfo(0, 0);
  // 公历日期
  public day: number = -1;
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
  // 是否农历月份的第一天
  public isFirstLunarDay: boolean = false;
  // 是否农历初一
  public isFirstLunarMonth: boolean = false;
  // 是否属于当前展示的月份
  public isCurrentMonth: boolean = false;
  // 是否是周末
  public isWeekends: boolean = false;
  // 是否显示TAG
  public showTagText: boolean = false;
  // 节假日、节气、农历 归一化TAG
  public tagText: string = '';
  // 是否显示班休
  public showRecessData: boolean = false;
  // 界面是否显示农历下划线
  public showLunarLine: boolean = false;
  // 当天的节假日
  public festivals: FestivalDay[] = [];
  //当天是否有节假日
  public hasFestivals: boolean = false;
  // 当天的标签是否显示节气
  public festivalTerm: boolean = true;
  // 系统设置数据
  public setting: SettingsDataModel = new SettingsDataModel();
  // 业务所需数据
  public cardData: CardSingleDayViewModel = new CardSingleDayViewModel();
  // 历法
  public subscriptionCalendar: number = -1;
  // 是否显示中国节假日
  public showChineseFestival: boolean = true;

  constructor(setting: SettingsDataModel, dayData?: DayData, dateInfo?: DateInfo) {
    this.setting = setting;
    if (!dateInfo || !dayData) {
      Log.error(TAG, `NO VALID DATE INFO TO BUILD DAY!`);
      return;
    }
    this.parseBaseState(dayData, dateInfo);
    this.parseHolidayAndTerm(dayData);
    this.parseShowRecessDataChange();
    this.updateDayCell();
    this.parseFormData();
  }

  /**
   * 将本类封装为特定对象给卡片视图使用
   */
  parseFormData() {
    this.cardData.year = this.dayData.solarYear; // 当天宫格的真实时间
    this.cardData.month = this.dayData.solarMonth;
    this.cardData.day = this.day;
    this.cardData.isToday = this.isToday;
    this.cardData.mark = this.mark;
    this.cardData.isCurrentMonth = this.isCurrentMonth;
    this.cardData.isWeekends = this.isWeekends;
    this.cardData.showTagText = this.showTagText;
    this.cardData.tagText = this.tagText;
    this.cardData.showRecessData = this.showRecessData;
    this.cardData.showLunarLine = this.showLunarLine;
    this.cardData.hasFestivals = this.hasFestivals;
    this.cardData.subscriptionCalendar = this.subscriptionCalendar;
    this.cardData.showChineseFestival = this.showChineseFestival;
    this.cardData.showChineseHolidayState = this.setting.showChineseHolidayState;
  }

  /**
   * 初始化班休后更新数据
   * @param dayData
   * @param dateInfo
   */
  update(dayData?: DayData, dateInfo?: DateInfo) {
    if (!dateInfo || !dayData) {
      Log.error(TAG, `update: NO VALID DATE INFO TO BUILD DAY!`);
      return;
    }
    this.parseBaseState(dayData, dateInfo);
    this.parseHolidayAndTerm(dayData);
    this.parseShowRecessDataChange();
    this.updateDayCell();
    this.parseFormData();
  }

  /**
   * 更新单日宫格样式
   */
  updateDayCell() {
    this.onSubscriptionCalendar(this.setting.subscriptionCalendar, this.setting.showChineseHolidayState);
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
    this.isWeekends = this.setting.weekends.includes(this.dayData.getWeekDay());
    this.isToday = DateUtil.isSameDay(this.dayData.getDate(), new CalendarDate());

    this.mark = dayData.dayMark;
    this.parseCalendar();
    this.showChineseFestival = this.setting.showChineseHolidayState !==
      CHINESE_HOLIDAY_STATE_VALUE.CLOSE;
    this.festivals = dayData.festivals.filter((festival: FestivalDay) =>
      this.showChineseFestival || this.checkIsChineseFestival(festival)
    );
    return;
  }

  // 校验是否为中国节假日
  checkIsChineseFestival(day: FestivalDay) {
    return day.type !== FestivalType.OFFICIAL_CHINA && day.type !== FestivalType.OFFICIAL_TAIWAN &&
      day.type !== FestivalType.OFFICIAL_HONGKONG && day.type !== FestivalType.LUNAR_CHINA &&
      day.type !== FestivalType.INTER;
  }

  // 校验是否为节气
  checkIsTerm(day: FestivalDay) {
    return day.type === FestivalType.SOLAR_TERM;
  }

  /**
   * 处理历法变更
   */
  parseCalendar() {
    if (this.isIslamicCalendar()) {
      let calendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemRegion(), 'islamic_civil');
      const date: Date = new Date(this.dayData.getTimeStamp());
      calendar.setTime(date);
      this.calendar = calendar.get('date').toString();
    } else {
      if (DateUtil.isNeedDisplayLunaMonth(this.dayData.solarYear)) {
        this.calendar = LunarDateUtil.parseLeapLunaMonth(this.dayData);
      } else {
        this.calendar = '';
      }
    }
  }

  isIslamicCalendar(): boolean {
    return this.subscriptionCalendar == SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR;
  }

  isNoCalendar(): boolean {
    return this.subscriptionCalendar == SubscriptionCalendar.NO_CALENDAR;
  }

  /**
   * 处理节假日和节气
   */
  parseHolidayAndTerm(dayData: DayData): void {
    let tempTerm: string = '';
    let tempHoliday: string = '';

    const festivals = this.festivals.filter(item => {
      return item !== null && item !== undefined;
    })
    for (let i = 0; i < festivals.length; i++) {
      if (tempTerm === '' && this.checkIsTerm(festivals[i])) {
        tempTerm = festivals[i].name;
      }

      if (tempHoliday === '' && !this.checkIsTerm(festivals[i])) {
        if (this.setting.showChineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN) {
          tempHoliday = festivals[i].name
        } else {
          tempHoliday = HolidayUtil.needRemoveHoliday(festivals[i].name);
        }
      }
    }
    // 非中国农历则关闭节气和农历节日的显示
    if (this.isNoCalendar() ||
      !DateUtil.isNeedDisplayLunaMonth(this.dayData.solarYear)) {
      tempTerm = '';
    }
    if (this.isIslamicCalendar() ) { // 伊斯兰历不取节气节日
     tempTerm = '';
    }
    this.term = tempTerm;
    this.holiday = tempHoliday;
    this.hasFestivals = this.term.length !== 0 || this.holiday.length !== 0;
  }

  /**
   * 历法变更
   *
   * @param showCalendar 是否显示历法
   */
  onSubscriptionCalendar(subscriptionCalendar: number, showChineseHolidayState: string) {
    const showCalendar: boolean = !(subscriptionCalendar === SubscriptionCalendar.NO_CALENDAR);
    this.subscriptionCalendar = subscriptionCalendar;
    this.showChineseFestival = showChineseHolidayState !== CHINESE_HOLIDAY_STATE_VALUE.CLOSE;
    this.festivals = this.dayData.festivals.filter((festival: FestivalDay) =>
      this.showChineseFestival || this.checkIsChineseFestival(festival));
    this.parseCalendar();
    this.parseHolidayAndTerm(this.dayData);
    this.updateTagTextProp(showCalendar);
    this.updateLunarLineProp(showCalendar);
  }

  /**
   * 是否显示标签文本，显示规则：若历法开则显示，若历法关且手机
   */
  updateShowTagText(showCalendar: boolean) {
    if (showCalendar) {
      this.showTagText = true;
    }
    if (this.hasFestivals) {
      this.showTagText = true;
    }
  }

  /**
   * 更新历法、节假日文本
   * @param showCalendar
   */
  updateTagTextContent(showCalendar: boolean): void {
    if (this.holiday.length !== 0) {
      const festivalAbbreviationMap: HashMap<string, string> = FestivalAbbreviationMap.getInstance();
      if (festivalAbbreviationMap.hasKey(this.holiday)) {
        this.tagText = festivalAbbreviationMap.get(this.holiday);
      } else {
        this.tagText = this.holiday;
      }
      this.festivalTerm = false;
    } else if (showCalendar && this.term.length !== 0) {
      this.tagText = this.term;
      this.festivalTerm = true;
    } else if (showCalendar) {
      this.tagText = this.calendar;
    } else {
      this.tagText = '';
    }

    // 控制历法、节假日的最大长度为4，如果为当天最大长度为3
    const maxStrLength: number = this.isToday ? 3 : 4;
    if (this.tagText.length > maxStrLength) {
      this.tagText = this.tagText.slice(0, maxStrLength - 1) + '...'
    }
  }

  updateTagTextProp(showCalendar: boolean): void {
    this.updateTagTextContent(showCalendar);
    this.updateShowTagText(showCalendar);
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
    if (this.isIslamicCalendar()) {
      this.showLunarLine = false;
      return;
    }
    if (this.isToday) {
      this.showLunarLine = false;
      return;
    }
    this.showLunarLine = this.isFirstLunarDay;
  }

  /**
   * 根据班休数据处理是否显示班休 班休数据为 0、undefined、null 表示当天不需要显示班休
   */
  private parseShowRecessDataChange(): void {
    // 初始化时，如果班休没有数据则不显示班休
    if (this.mark === undefined || this.mark === null) {
      this.showRecessData = false;
    }
    this.showRecessData = this.mark === 0 ? false : this.setting.isRecessToggleOn;
  }
}