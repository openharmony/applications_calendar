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
  CalendarDate,
  DateManager,
  DateUtil,
  DAY_PER_WEEK,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  Log,
  MonthInfo,
  ServiceEnum,
  ServiceManager
} from '@app/common';
import { SingleDayViewModel, SingleDayViewModelArray } from './SingleDayViewModel';
import { WeekTitlesArray, WeekTitleViewModel } from './WeekTitleViewModel';
import { SideBarMonthViewLayout } from './SideBarMonthViewLayout';

const TAG: string = "[SideBar][SigMonthVM]";

@Observed
export class SingleMonthViewModelArray extends Array<SingleMonthViewModel> {
}

@Observed
export class SingleMonthViewModel {
  static readonly dayItemCount: number = 6 * 7; // max number of day show items
  month: number;
  year: number;
  public dayViewModels: SingleDayViewModelArray = [];
  updateFlag: boolean = false; // for canvas
  showRecessData: boolean = false;
  showLunarInfo: boolean = true;
  monthInfo: MonthInfo | undefined = undefined;
  monthTitle: string = '';
  startOfWeek: number = 0;
  weekTitles: WeekTitlesArray;
  weekends: number[] = [];
  weekNum: number = 5;
  language: string = '';
  hasDisplayDay: boolean = false;

  constructor(year: number, month: number, showLunarInfo: boolean = true) {
    this.month = month;
    this.year = year;
    this.startOfWeek = WeekTitleViewModel.getInstance().startOfWeek;
    this.language = GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string;
    this.weekTitles = WeekTitleViewModel.getInstance().getWeekTitle(this.language);
    this.monthInfo = DateManager.getInstance().getYearData(this.year)?.getMonthInfo(this.month);
    if (!this.monthInfo) {
      Log.error(TAG, `getMonthInfo failed ${this.year}:${this.month}`);
      return;
    }
    this.dayViewModels = [];
    for (let index = 0; index < SingleMonthViewModel.dayItemCount; ++index) {
      this.dayViewModels.push(new SingleDayViewModel())
    }
    this.showLunarInfo = showLunarInfo;
    this.weekends = GlobalData.instance().get(GlobalDataKeys.WEEKENDS) as number[];
    this.updateShowDaysInfo();
    this.monthTitle = DateUtil.getMonthTitle(this.month - 1, this.language);
  }

  //系统时间变化更新今天标识
  public updateDate(oldDate: CalendarDate, newDate: CalendarDate) {
    let needRefresh = false; //判断是否需要刷新的标志位
    const selectDay = DateManager.getInstance().selectedDay; //需要重新选中
    //循环当月日持判断是否存在需要刷新今天标识的日期
    this.dayViewModels?.forEach((item: SingleDayViewModel) => {
      if (oldDate.getFullYear() === item.year
        && (oldDate.getMonth() + 1) === item.month
        && oldDate.getDate() === item.day) {
        item.updateToday(false);
        needRefresh = true;
      } else if (newDate.getFullYear() === item.year
        && (newDate.getMonth() + 1) === item.month
        && newDate.getDate() === item.day) {
        item.updateToday(true)
        needRefresh = true;
      }
      if (item.day === selectDay.solarDay && selectDay.solarMonth === this.month && item.isNowMonth) {
        item.isSelect = true;
      }
    })
    //循环完毕后再触发刷新操作
    if (needRefresh) {
      this.updateFlag = this.updateFlag ? false : true;
    }
  }

  // 响应选中日期变化
  public onSelectedDateChange() {
    const selectDay = DateManager.getInstance().selectedDay;
    // 月标题的颜色需要感知年份变化
    this.dayViewModels?.forEach((item) => {
      if (item.day === selectDay.solarDay && selectDay.solarMonth === this.month && item.isNowMonth) {
        Log.info(TAG, `enable select ${this.year}:${this.month}:${item.day}`);
        item.isSelect = true;
      } else {
        item.isSelect = false;
      }
    })
    this.hasDisplayDay = (selectDay.solarMonth === this.month && selectDay.solarYear === this.year);
    // 刷新标志位,在Canvas组件中触发刷新
    this.updateFlag = this.updateFlag ? false : true;
  }

  public onStartOfWeekChange(startOfWeek: number) {
    Log.debug(TAG, `${this.year}:${this.month} onStartOfWeekChange: ${this.startOfWeek} => ${startOfWeek}`);
    if (this.startOfWeek != startOfWeek) {
      this.startOfWeek = startOfWeek;
      this.updateShowDaysInfo();
      this.weekTitles = WeekTitleViewModel.getInstance().weekTitles;
    }
  }

  public updateByYearMonth(newYear: number, newMonth: number) {
    Log.debug(TAG, `month from ${this.month} to ${newMonth} update form ${this.year} to ${newYear}`);
    if (this.year != newYear || this.month != newMonth) {
      if (newMonth > 12) {
        newMonth = 1;
        newYear = newYear + 1;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear = newYear - 1;
      }
      this.year = newYear;
      this.month = newMonth;
      this.monthInfo = DateManager.getInstance().getYearData(this.year)?.getMonthInfo(newMonth);
      this.updateShowDaysInfo();
    }
  }

  onSubCalendarChange(showLunar: boolean) {
    Log.info(TAG, "onSubCalendarChange: " + showLunar);
    this.showLunarInfo = showLunar;
    this.updateShowDaysInfo();
  }

  onWeekendsChange(weekends: number[]) {
    this.weekends = weekends;
    this.updateShowDaysInfo();
  }

  onLanguageChange(language: string) {
    this.language = language;
    this.weekTitles = WeekTitleViewModel.getInstance().getWeekTitle(this.language);
    this.monthTitle = DateUtil.getMonthTitle(this.month - 1, this.language);
  }

  private updateShowDaysInfo() {
    if (this.startOfWeek < 0 || this.startOfWeek > 7) {
      Log.error(TAG, "startOfWeek invalid y:" + this.startOfWeek);
      return;
    }
    // check first day's week
    const days = this.monthInfo?.getDaysInfo();
    if (!days || days.length === 0) {
      Log.error(TAG, "updateShowDaysInfo failed y:" + this.year + 'm:' + this.month);
      return;
    }
    const firstDayWeek = days[0].getWeekDay();
    // case 1 : firstDayWeek is 0 and startOfWeek is 1; need 6 space
    // case 2 : firstDayWeek is 1 and startOfWeek is 0; need 1 space
    let space: number = 0;
    if (firstDayWeek >= this.startOfWeek) {
      space = firstDayWeek - this.startOfWeek;
    } else {
      space = 7 - this.startOfWeek + firstDayWeek;
    }
    const weekends: number[] = GlobalData.instance().get(GlobalDataKeys.WEEKENDS) as number[];
    Log.debug(TAG, `${this.year}：${this.month} - startOfWeek ${this.startOfWeek}, firstDayWeek ${firstDayWeek},space：${space}`);
    if (!this.dayViewModels) {
      return;
    }

    //填充上月数据
    let lastMonthInfo: MonthInfo | undefined = this.monthInfo?.getLast();
    if (lastMonthInfo) {
      let lastDays = lastMonthInfo.getDaysInfo();
      for (let index = 0; index < space; ++index) {
        this.dayViewModels[index].update(lastDays[lastDays.length - space + index], false, this.showLunarInfo, weekends, false);
      }
    } else {
      for (let index = 0; index < space; ++index) {
        this.dayViewModels[index].update();
      }
    }

    // insert cur month info
    days.forEach((element, index) => {
      this.dayViewModels[space + index].update(element, this.showRecessData, this.showLunarInfo, weekends);
    });
    for (let index = space + days.length; index < SingleMonthViewModel.dayItemCount; ++index) {
      this.dayViewModels[index].update();
    }

    //填充下月日期并计算当月显示行数
    let showDays = space + days.length;
    this.weekNum = showDays > 35 ? 6 : 5;
    let nextMonthInfo: MonthInfo | undefined = this.monthInfo?.getNext();
    if (nextMonthInfo) {
      let nextDays = nextMonthInfo.getDaysInfo();
      let nextSpace = this.weekNum * 7 - showDays;
      for (let index = 0; index < nextSpace; ++index) {
        this.dayViewModels[index + showDays].update(nextDays[index], false, this.showLunarInfo, weekends, false);
      }
    }

    // 刷新标志位,在Canvas组件中触发刷新
    this.updateFlag = this.updateFlag ? false : true;
    this.onSelectedDateChange();
  }

  getClickDisplayMills(clickX: number, clickY: number) {
    const layout = SideBarMonthViewLayout.getInstance();
    const sidebarWidth: number = AppStorage.get<number>(GlobalDataKeys.SIDEBAR_WIDTH) ?? DeviceConfig.instance()
      .config.deviceLayout.sidebarWidth;
    // 月份数据宽度为侧边栏宽度减去总月视图内边距*2加上swiper外边距*2
    const sidebarMonthWidth = sidebarWidth - layout.monthWidthMargin * 4;
    // 月份数据高度为总月视图高度减去总月视图上下边距再减去月视图年月切换组件的高度
    const sidebarMonthHeight =
      layout.sidebarMonthHeight - layout.monthTopMargin - layout.monthBottomMargin - layout.sidebarDateSwitchHeight;
    // 计算落在一行哪个天,限制范围0-6
    const widthIndex = Math.max(Math.min(Math.floor(clickX * DAY_PER_WEEK / sidebarMonthWidth), 6), 0);
    const weekNumber = this.weekNum + 1; // 计算当前行数,为当月周数 + 周题的额外一行
    // 计算落在哪一行,限制范围0-当月周数+1
    const heightIndex = Math.max(Math.min(Math.floor(clickY * weekNumber / sidebarMonthHeight), this.weekNum), 0);
    if (heightIndex === 0) { // 落在周题则直接进行月份跳转
      return -1;
    }
    const index = (heightIndex - 1) * DAY_PER_WEEK + widthIndex;
    if (this.dayViewModels.length < index) { // 当前存储数据异常,小于点击的index则不进行日期跳转
      return -1;
    }
    const clickDay = this.dayViewModels[index];

    // 返回选中天的0点
    return DateUtil.dateToStamp(clickDay.year, clickDay.month - 1, clickDay.day);
  }
}
