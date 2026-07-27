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

import emitter from '@ohos.events.emitter';
import { Callback } from '@ohos.base';
import { ALL_LUNAR_TERM, ALL_LUNAR_TERM_RES } from './LunarTermConsts';
import { Log } from '../default/common/Log';
import { CommonInnerEvent } from '../event/CommonInnerEvent';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';
import { DayData, MonthInfo, YearData } from './Date';
import { allLunarFestivalData, FestivalDay, FestivalType, setYearFestivalData } from './FestivalData';
import { allYearLunarStaticData } from './LunarStaicData';
import { AccessCountMap } from '../templates/AccessCountMap';
import { CalendarDate } from './CalendarDate';
import { DateUtil } from '../util/DateUtil';
import { EmitterCollector } from '../util/EmitterCollector';
import { GlobalDataKeys } from '../data/GlobalDataKeys';

const TAG: string = `DateManager`;

export interface DateManagerConfig {
  loadFestVialData : boolean,
  loadLunarData : boolean,
}

export class DateManager {
  public today: DayData;
  private allYearData: AccessCountMap<number, YearData> = new AccessCountMap<number, YearData>(50);
  private allYearLunarData: AccessCountMap<number, YearLunarData> = new AccessCountMap<number, YearLunarData>(50);
  // 设置选中天信息, 某天某月某日,全局唯一
  private _selectDay: DayData | null | undefined = null;
  private hasInited: boolean = false;
  // 用于热起更新日期的当前日期
  private currentDay: CalendarDate | null = null;
  private emitterController: EmitterCollector = new EmitterCollector();

  private _config : DateManagerConfig = {
    loadFestVialData: true,
    loadLunarData: true
  }
  constructor() {
    // 触发初始化
    this.today = DayData.buildByDate(new CalendarDate());
  }

  public get selectedDay(): DayData {
    if (!this._selectDay) {
      this._selectDay = DayData.buildByDate(new CalendarDate());
    }
    return this._selectDay;
  }

  public set selectedDay(day: DayData) {
    if (!this._selectDay) {
      this._selectDay = day;
      return;
    }
    if (this._selectDay.solarYear === day.solarYear &&
      this._selectDay.solarMonth === day.solarMonth &&
      this._selectDay.solarDay === day.solarDay) {
      return;
    }
    day.isSelected = true;
    if (this.selectedDay) {
      this.selectedDay.isSelected = false;
    }
    Log.info(TAG, `set selectedDay: ${this._selectDay} to ${day}`);
    this._selectDay.solarYear = day.solarYear;
    this._selectDay.solarMonth = day.solarMonth;
    this._selectDay.solarDay = day.solarDay;
  }

  static getInstance(): DateManager {
    return SingleInstanceHelper.createOrGet(DateManager, 'DateManager');
  }

  init(config? : DateManagerConfig) {
    Log.info(TAG, `init start`);
    if (config) {
      this._config = config;
    }
    const newToday = new CalendarDate();
    this.currentDay = newToday;
    let newDayData = this.getDayData(newToday.getFullYear(), newToday.getMonth() + 1, newToday.getDate());
    if (newDayData) {
      this.today.isToday = false;
      newDayData.isToday = true;
      this.today = newDayData;
    }
    if (this.hasInited) {
      Log.warn(TAG, `hasInited`);
      return;
    }
    this.systemDateChangeHandler = () => this.onSystemDateChange();
    // 系统时间的实时时间戳, 后台通过系统定时器每分钟触发一次刷新
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.systemDateChangeHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.systemDateChangeHandler);
    this.hasInited = true;
    Log.info(TAG, `init end`);
  }

  unInit() {
    Log.info(TAG, `unInit start`);
    if (!this.hasInited) {
      Log.warn(TAG, `already no Inited`);
      return;
    }
    this.emitterController.off();
    this.hasInited = false;
    Log.info(TAG, `unInit end`);
  }

  public onSystemDateChange(): void {
    // 触发初始化
    Log.info(TAG, `onSystemDateChange`);
    this.today.isToday = false;
    const newToday = new CalendarDate();
    const nowYear = newToday.getFullYear();
    const nowMonth = newToday.getMonth() + 1;
    const nowDay = newToday.getDate();
    let newDayData = this.getDayData(nowYear, nowMonth, nowDay);
    if (newDayData) {
      this.today = newDayData;
      this.today.isToday = true;
    }
    // 建立事件层次关系,避免时序问题
    emitter.emit({ eventId: CommonInnerEvent.INNER_DATE_CHANGED });
  }

  public getDayData(solarYear: number, solarMonth: number, solarDay: number): DayData | undefined {
    return this.getYearData(solarYear)?.getMonthInfo(solarMonth)?.getDayData(solarDay);
  }

  public getYearData(solarYear: number): YearData | undefined {
    // get from memory cache
    if (solarYear <= 0) {
      return undefined;
    }

    if (!this.allYearData.has(solarYear)) {
      let yearData = new YearData(solarYear);
      this.allYearData.set(solarYear, yearData);

      if (this._config.loadLunarData) {
        // get lunar data from memory
        let lunarData = this.getYearLunarData(solarYear);

        if (lunarData) {
          this.buildYearDataByYearLunarData(yearData, lunarData);
        }
      }

      if (this._config.loadFestVialData) {
        // build YearData by lunar data
        setYearFestivalData(yearData);
      }
      // 对于前后10年的年份，多触发几次get，增加count
      const nearByYear = 10;
      if (solarYear <= this.today.solarYear + nearByYear && solarYear >= this.today.solarYear - nearByYear) {
        this.allYearData.get(solarYear);
      }
    }
    return this.allYearData.get(solarYear);
  }

  /*
   get year lunar info
   * */
  public getYearLunarData(solarYear: number): YearLunarData | undefined {
    // query by year
    if (!this.allYearLunarData.has(solarYear)) {
      //  if query failed calculate now, start an async work to insert db
      let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) => data.year === solarYear);
      if (!staticYearData || staticYearData.length === 0) {
        Log.warn(TAG, `getYearLunarData staticYearData empty solarYear:${solarYear}`);
        return undefined;
      }
      let yearLunarData = YearLunarData.ConvertFromStaticData(staticYearData[0])
      this.allYearLunarData.set(solarYear, yearLunarData)
    }
    return this.allYearLunarData?.get(solarYear);
  }

  buildYearDataByYearLunarData(yearData: YearData, lunarData: YearLunarData): void {
    let allMonthInfo = yearData.getAllMonthInfo();
    for (let index = 0; index < allMonthInfo.length; index++) {
      let monthLunarInfo = lunarData.getMonthLunarInfo(allMonthInfo[index].getMonth())
      if (index === 1) {
        // 通过春节初一计算除夕，所以需要把上一个月的数据传入，初一只会出现在公历一月、二月，且除夕不会出现在12月，22085年才会出现春节初一与元旦同一天
        this.buildMonthLunarData(allMonthInfo[index], monthLunarInfo, allMonthInfo[index - 1]);
      } else {
        this.buildMonthLunarData(allMonthInfo[index], monthLunarInfo);
      }
    }

    // 节气赋值
    lunarData.lunarTermInfos.forEach((info => {
      const solarMonth = info.solarMonth;
      const solarDay = info.solarDay;
      let dayData = yearData.getMonthInfo(solarMonth)?.getDayData(solarDay);
      let termFestival: FestivalDay = {
        name: ALL_LUNAR_TERM[info.termIndex],
        type: FestivalType.SOLAR_TERM,
        resource: ALL_LUNAR_TERM_RES[info.termIndex]
      }
      if (termFestival.name === '清明节') {
        termFestival.type = FestivalType.LUNAR_CHINA;
      }
      dayData?.festivals.push(termFestival);
      if (termFestival.name === '冬至') {
        dayData?.festivals.push({ name: '入九', type: FestivalType.SOLAR_TERM, resource: $r('app.string.first_nine_days') });
      }
    }))
  }

  // 生成每月的农历信息
  buildMonthLunarData(monthInfo: MonthInfo, solarLunarDays: SolarLunarInfo[], lastMonthInfo?: MonthInfo): void {
    let daysInfo = monthInfo.getDaysInfo();
    let index = 0;
    for (let i = 0; i < solarLunarDays.length; ++i) {
      let startLunarDay = solarLunarDays[i].lunarDay;
      let startLunarMonth = solarLunarDays[i].lunarMonth;

      let endSolarDay = daysInfo.length; // default
      if (i + 1 !== solarLunarDays.length) {
        endSolarDay = solarLunarDays[i + 1].solarDay - 1;
      }

      for (; index < endSolarDay; ++index) {
        daysInfo[index].lunaMonth = startLunarMonth;
        daysInfo[index].lunarDay = startLunarDay;
        // 加入农历节日信息
        allLunarFestivalData.forEach(data => {
          if (data.rule.lunarMonth == startLunarMonth && data.rule.lunarDay == startLunarDay) {
            daysInfo[index].festivals.push(data.info);
            if (data.rule.lunarDay === 1 && data.rule.lunarMonth === 1) {
              // 春节的前一天的除夕设置
              this.pushChuXiFestival(daysInfo, index, lastMonthInfo);
            }
          }
        })
        startLunarDay += 1;
      }
    }
  }

  private systemDateChangeHandler: Callback<emitter.EventData> = () => {
  };

  /**
   * 将index所在的前一天设置为除夕
   * @param daysInfo
   * @param index
   * @param lastMonthInfo 上一个月的数据
   */
  private pushChuXiFestival(daysInfo: DayData[], index: number, lastMonthInfo?: MonthInfo): void {
    if (index === 0) {
      // 需要跨月设置前一个月的最后一天为除夕
      if (lastMonthInfo === undefined) {
        Log.error(TAG, 'No Valid Last MonthInfo!');
        return;
      }
      let lastMonthDaysInfo: DayData[] = lastMonthInfo.getDaysInfo();
      lastMonthDaysInfo[lastMonthDaysInfo.length - 1].festivals.push(this.getChuXiFestival());
      return;
    }
    daysInfo[index - 1]?.festivals.push(this.getChuXiFestival());
    return;
  }

  private getChuXiFestival(): FestivalDay {
    for (let lunarData of allLunarFestivalData) {
      if (lunarData.info.name === '除夕') {
        return lunarData.info;
      }
    }
    return allLunarFestivalData[0].info;
  }

  public updateCurrentDate(date: CalendarDate): void {
    this.currentDay = date;
  }

  // 判断当前存储的日期是否与系统日期不一致需要更新
  public isCurDateNeedRefresh(): boolean {
    if (this.currentDay === null) {
      return false;
    }
    return !DateUtil.isSameDay(this.currentDay, new CalendarDate());
  }
}

export interface YearLunarStaticData {
  year: number;
  solarLunars: number[]
  lunarTerms: number[]
}

export class YearLunarData {
  public year: number;
  public _solarLunarDays: SolarLunarInfo[] = [];

  constructor(year: number) {
    this.year = year;
  }

  private _lunarTermInfos: LunarTermInfo[] = [];

  public get lunarTermInfos(): LunarTermInfo[] {
    return this._lunarTermInfos;
  }

  static ConvertFromStaticData(data: YearLunarStaticData): YearLunarData {
    let yearData = new YearLunarData(data.year)
    data.solarLunars.forEach((item: number) => {
      yearData._solarLunarDays.push(SolarLunarInfo.fromHexData(item));
    })
    data.lunarTerms.forEach((item: number) => {
      yearData._lunarTermInfos.push(LunarTermInfo.fromHexData(item));
    })
    return yearData;
  }

  getMonthLunarInfo(month: number): SolarLunarInfo[] {
    return this._solarLunarDays.filter((info: SolarLunarInfo) => info.solarMonth === month);
  }
}

export class SolarLunarInfo {
  private static readonly solarMonthOffset: number = 24;
  private static readonly solarDayOffset: number = 16;
  private static readonly lunarMonthOffset: number = 8;
  public solarMonth: number;
  public solarDay: number;
  public lunarMonth: number;
  public lunarDay: number;

  constructor(solarMonth: number, solarDay: number, lunarMonth: number, lunarDay: number) {
    this.solarMonth = solarMonth;
    this.solarDay = solarDay;
    this.lunarMonth = lunarMonth;
    this.lunarDay = lunarDay;
  }

  static fromHexData(hex: number) {
    const solarMonth = (hex & 0xf000000) >> SolarLunarInfo.solarMonthOffset;
    const solarDay = (hex & 0xff0000) >> SolarLunarInfo.solarDayOffset;
    const lunarMonth = (hex & 0xff00) >> SolarLunarInfo.lunarMonthOffset;
    const lunarDay = (hex & 0xff);
    return new SolarLunarInfo(solarMonth, solarDay, lunarMonth, lunarDay)
  }

  isEqual(other: SolarLunarInfo): boolean {
    return this.solarMonth === other.solarMonth &&
      this.solarDay === other.solarDay &&
      this.lunarMonth === other.lunarMonth &&
      this.lunarDay === other.lunarDay;
  }

  /*
   0xABBCCDD
  A：solarMonth
  BB：solarDay
  CC：lunarMonth
  DD：lunarDay
  */
  toHexData(): number {
    return (this.solarMonth << SolarLunarInfo.solarMonthOffset) | (this.solarDay << SolarLunarInfo.solarDayOffset) |
      (this.lunarMonth << SolarLunarInfo.lunarMonthOffset) | (this.lunarDay);
  }

  toHexStr(): string {
    return '0x' + this.toHexData().toString(16); // 16 is hex
  }
}

export class LunarTermInfo {
  private static readonly solarMonthOffset: number = 16;
  private static readonly solarDayOffset: number = 8;
  public solarDay: number;
  public solarMonth: number;
  public termIndex: number;

  constructor(solarMonth: number, solarDay: number, termIndex: number) {
    this.solarMonth = solarMonth
    this.solarDay = solarDay
    this.termIndex = termIndex
  }

  static fromHexData(hex: number) {
    let solarMonth = (hex & 0xf0000) >> LunarTermInfo.solarMonthOffset;
    let solarDay = (hex & 0xff00) >> LunarTermInfo.solarDayOffset;
    let termIndex = (hex & 0xff);
    return new LunarTermInfo(solarMonth, solarDay, termIndex)
  }

  isEqual(other: LunarTermInfo): boolean {
    return this.solarMonth === other.solarMonth &&
      this.solarDay === other.solarDay &&
      this.termIndex === other.termIndex
  }

  /*
  0xABBCC
  A：solarMonth
  BB：solarDay
  C：termIndex
  */
  toHexData(): number {
    return (this.solarMonth << LunarTermInfo.solarMonthOffset) |
      (this.solarDay << LunarTermInfo.solarDayOffset) | (this.termIndex)
  }

  toHexStr(): string {
    return '0x' + this.toHexData().toString(16); // 16 is hex
  }
}