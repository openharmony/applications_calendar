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

import { GlobalThis } from '../data/GlobalThis';
import { I18nUtil } from '../util/I18nUtil';
import { i18n } from '@kit.LocalizationKit';
import { AgendaEventInfo } from '../agenda/AgendaEventInfo';
import { EventService } from '../dao/service/EventService';
import { Log } from '../default/common/Log';
import { MILLS_PER_DAY } from '../util/DateUtil';

export const SUBSCRIPTION_HOLIDAY_DISPLAY_COUNTRY = 'SUBSCRIPTION_HOLIDAY_DISPLAY_COUNTRY';

export const CUSTOM_CHINA_COUNTRY_CODE = 'CN_CUSTOM';

export const CHINA_COUNTRY_CODE = 'CN';

export const USER_CHINA_COUNTRY_DEFAULT = 'USER_CHINA_COUNTRY_DEFAULT';

export const CHINESE_HOLIDAY_STATE = 'CHINESE_HOLIDAY_STATE';

export enum CHINESE_HOLIDAY_STATE_VALUE {
  CLOSE = 'CLOSE',
  CN_OPEN = 'CN',
  CN_CUSTOM_OPEN = 'CN_CUSTOM',
}

const NEED_REMOVE_HOLIDAY: string[] =
  ['情人节', '愚人节', '母亲节', '父亲节', '万圣夜', '感恩节', '平安夜', '圣诞节'];

// 支持显示和设置的中国节假日，固定七个法定节日+常用的七夕重阳
export const SUPPORT_CHINESE_HOLIDAYS: string[] = ['元旦', '春节', '清明节', '劳动节', '端午节', '中秋节', '国庆节', '七夕节', '重阳节'];

const TAG: string = 'HolidayUtil';

export class HolidayUtil {
  static needRemoveHoliday(tempHoliday: string): string {
    for (let holidayName of NEED_REMOVE_HOLIDAY) {
      if (holidayName === tempHoliday) {
        return '';
      }
    }
    return tempHoliday;
  }

  static getDisplayCountry(code: string): string {
    if (code === CHINESE_HOLIDAY_STATE_VALUE.CN_CUSTOM_OPEN) {
      return I18nUtil.getDisplayCountry(CHINA_COUNTRY_CODE);
    }
    if (code === CHINA_COUNTRY_CODE) {
      return GlobalThis.getResourceStr($r('app.string.commonly_used_holidays'), i18n.System.getSystemLanguage());
    }
    return I18nUtil.getDisplayCountry(code);
  }

  static async isRecentChineseHoliday(eventId: number): Promise<boolean> {
    if (eventId <= 0) {
      return false;
    }
    const holidays: AgendaEventInfo[] = await EventService.INSTANCE.queryHolidaysByTitles(SUPPORT_CHINESE_HOLIDAYS);
    if (!holidays || holidays.length === 0) {
      Log.warn(TAG, 'isRecentChineseHoliday no recent holiday');
      return false;
    }
    const agendaList: AgendaEventInfo[] = holidays.filter((item: AgendaEventInfo): boolean => {
      if (!item || !item.isHoliday()) {
        return false;
      }
      // 按照与${#getRecentHolidayProxy}相同的过滤规则，过滤查询到的节日
      const now: number = Date.now();
      const oneYearTwoMonthDays: number = 366 + 60;
      const lastDayTime: number = now + oneYearTwoMonthDays * MILLS_PER_DAY;
      return item.mEnd > now && item.mBegin < lastDayTime;
    });
    agendaList.sort((holidayA, holidayB) => holidayA.mBegin - holidayB.mBegin);
    if (agendaList && agendaList.length > 0) {
      return eventId === agendaList[0].mId;
    }
    return false;
  }
}

