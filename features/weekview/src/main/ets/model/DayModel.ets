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

import { DayData } from '@app/common/src/main/ets/date/Date';
import { DateRange } from '@app/common/src/main/ets/date/DateRange';
import { DateManager } from '@app/common/src/main/ets/date/DateManager';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { FestivalDay, FestivalType } from '@app/common/src/main/ets/date/FestivalData';
import { CalendarDate, CHINESE_HOLIDAY_STATE_VALUE, EmptyUtils, GlobalThis, HolidayUtil } from '@app/common';

const TAG: string = 'DayModel';

export class DayModel extends DayData {
  public range: DateRange.Range = { start: Date.now(), end: Date.now() };
  public showFestivals: FestivalDay[] = [];
  public agendaCount: number = 0;
  constructor(date: CalendarDate) {
    super(date.getFullYear(), date.getMonth(), date.getDate());
  }

  resetDate(date: CalendarDate): void {
    const cacheData = DateManager.getInstance().getDayData(date.getFullYear(), date.getMonth() + 1, date.getDate());
    if (!cacheData) {
      Log.error(TAG, `get cacheData failed ${date.toLocaleString()}`);
      return;
    }
    this._dayMark = cacheData.dayMark;
    this.dayMarkValue = cacheData.dayMarkValue;
    this.solarYear = cacheData.solarYear;
    this.solarMonth = cacheData.solarMonth;
    this.solarDay = cacheData.solarDay;
    this.lunaMonth = cacheData.lunaMonth;
    this.lunarDay = cacheData.lunarDay;
    this.festivals = cacheData.festivals.sort((a: FestivalDay, b: FestivalDay) => {
      return b.type - a.type;
    });
  }

  updateShowFestivals(showCalendar: boolean, showChineseCalendar: boolean,
    chineseHolidayState: CHINESE_HOLIDAY_STATE_VALUE): void {
    const filterTypes: FestivalType[] = [];
    if (!showCalendar) { // 暂时只有农历节假日
      filterTypes.push(FestivalType.SOLAR_TERM);
    }

    if (chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CLOSE) {
      filterTypes.push(FestivalType.INTER);
      filterTypes.push(FestivalType.LUNAR_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_TAIWAN);
      filterTypes.push(FestivalType.OFFICIAL_HONGKONG);
    }

    if (!showChineseCalendar) { // 其他地区不显示中国节假日
      filterTypes.push(FestivalType.LUNAR_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_CHINA);
      filterTypes.push(FestivalType.OFFICIAL_TAIWAN);
      filterTypes.push(FestivalType.OFFICIAL_HONGKONG);
    }

    let festivalsTemp: FestivalDay[] = [];
    for (let item of this.festivals) {
      if (filterTypes.includes(item.type)) {
        continue;
      }
      if (chineseHolidayState === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN &&
        HolidayUtil.needRemoveHoliday(item.name) === '') {
        continue;
      }
      festivalsTemp.push(item);
    }

    this.showFestivals = festivalsTemp;
  }

  hasShowFestival(): boolean {
    return this.showFestivals.length > 0;
  }

  getShowFestival(language?: string): string {
    let holidayName: string = '';
    if (!this.hasShowFestival()) {
      return holidayName;
    }
    holidayName = GlobalThis.getResourceStr(this.showFestivals[0].resource, language);
    if (EmptyUtils.isEmptyString(holidayName)) {
      holidayName = this.showFestivals[0].name;
    }
    return holidayName;
  }

  isFirstDayOfMonth(): boolean {
    return this.lunarDay === 1;
  }

  isPastDay(): boolean {
    const date = new CalendarDate(this.solarYear, this.solarMonth - 1, this.solarDay) // 为了保证getDay正常
    return new CalendarDate().setHours(0, 0, 0, 0) > new CalendarDate(date.getTime()).setHours(0, 0, 0, 0);
  }

  hasAgenda(): boolean {
    return this.agendaCount > 0;
  }
}