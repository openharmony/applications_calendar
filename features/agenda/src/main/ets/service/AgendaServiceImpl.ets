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
  AgendaService,
  AgendaEventInfo,
  factory,
  LunarDateUtil,
  ServiceEnum,
  CalendarContract,
  GlobalData,
  GlobalDataKeys,
  DateUtil,
  GlobalThis,
  CalendarDate,
  I18nUtil,
  MILLS_PER_DAY,
  Log,
} from '@app/common';
import { LunarDate } from '@app/common/src/main/ets/date/LunarDate';
import { Recurrence, Frequency } from '@app/feature.repeatrule';
import bundleManager from '@ohos.bundle.bundleManager';

// 仅标题以中文生日结尾时需要显示周岁，生日两个字不需要翻译
const BIRTHDAY_STR: string = '生日';

// 仅中文下显示周岁，周岁两个字不需要翻译（同双框架）
const CHINESE_ANNIVERSARY: string = '周岁';

export interface AgendaOffsetTitle {
  title : string,
  isFullYear : boolean
};

const TAG = '[AgendaService]';

@factory(ServiceEnum.AGENDA_SERVICE)
export class AgendaServiceImpl extends AgendaService {
  /**
   * 重复倒数日标题后加上 · n周年
   *
   * @param agendaInfo: 日程
   * @param instanceTime: 日程实例时间戳
   *
   * @returns titleStr: 标题 · n周年
   */
  public updateRepeatAgendaTitle(agendaInfo: AgendaEventInfo, instanceTime: number): string {
    if (Recurrence.parse(agendaInfo.mRepeatRule).freq !== Frequency.YEARLY) {
      return agendaInfo.mTitle;
    }
    const originalDate = new CalendarDate(agendaInfo.mOriginalBegin);
    const instanceDate = new CalendarDate(instanceTime);
    const titleStr: string = agendaInfo.mTitle.split('·')[0].trim();
    const language: string = GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string;
    // 如果当前日期小于开始日期，直接返回标题
    if (instanceDate <= originalDate) {
      return titleStr;
    }

    // 计算实例年份与起始年份的差异
    let yearDifference = agendaInfo.isLunarEvent()
      ? LunarDateUtil.getLunarYear(instanceDate) - LunarDateUtil.getLunarYear(originalDate)
      : instanceDate.getFullYear() - originalDate.getFullYear();

    if (yearDifference === 0) {
      return agendaInfo.mTitle;
    }
    // 注：参考双框架，日程标题以生日结尾时，且当前语言是中文，显示成周岁。
    if (titleStr && titleStr.endsWith(BIRTHDAY_STR) && I18nUtil.isSystemChineseLanguage()) {
      return `${titleStr} · ${yearDifference} ${CHINESE_ANNIVERSARY}`;
    } else {
      const titleTail: string = GlobalThis.getPluralStr($r('app.plural.in_anniversarys'), yearDifference, language);
      return `${titleStr} · ${titleTail}`;
    }
  }


  public updateNormalAgendaTitle(agendaInfo: AgendaEventInfo, startMills: number): AgendaOffsetTitle {
    const titleStr: string = agendaInfo.mTitle.split('·')[0].trim();

    // 如果当前日期小于开始日期，直接返回标题
    if (startMills <= agendaInfo.mOriginalBegin) {
      return { title: titleStr, isFullYear: false };
    }
    // 计算实例年份与起始年份的差异
    let yearDifference = 0;
    let remainingDays = 0;
    if (agendaInfo.isLunarEvent()) {
      const startDate = new LunarDate();
      startDate.setTime(agendaInfo.mOriginalBegin);
      const endDate = new LunarDate();
      endDate.setTime(startMills);
      if (startDate.getMonth() < endDate.getMonth() ||
        (startDate.getMonth() === endDate.getMonth() && startDate.getDate() <= endDate.getDate())) {
        yearDifference = endDate.getFullYear() - startDate.getFullYear();
      } else {
        yearDifference = endDate.getFullYear() - startDate.getFullYear() - 1;
      }
      startDate.addYear(yearDifference);
      remainingDays = Math.ceil((endDate.getTimeInMills() - startDate.getTimeInMills()) / MILLS_PER_DAY);
    } else {
      const originalDate = new Date(agendaInfo.mOriginalBegin);
      const instanceDate = new Date(startMills);
      const originalYear = originalDate.getFullYear();
      yearDifference = instanceDate.getFullYear() - originalYear;
      originalDate.setFullYear(originalYear + yearDifference);
      remainingDays = Math.ceil((instanceDate.getTime() - originalDate.getTime()) / MILLS_PER_DAY);
    }

    if (yearDifference <= 0 || remainingDays !== 0) {
      return { title: agendaInfo.mTitle, isFullYear: false };
    }

    // 注：参考双框架，日程标题以生日结尾时，且当前语言是中文，显示成周岁。
    if (titleStr && titleStr.endsWith(BIRTHDAY_STR) && I18nUtil.isSystemChineseLanguage()) {
      return { title: `${titleStr} · ${yearDifference} ${CHINESE_ANNIVERSARY}`, isFullYear: true };
    } else {
      const titleTail: string = GlobalThis.getPluralStr($r('app.plural.in_anniversarys'), yearDifference);
      return { title: `${titleStr} · ${titleTail}`, isFullYear: true };
    }
  }

  /**
   * 重要日标题联想距离参考日期（当天或选中）还剩多少天
   *
   * @param agendaInfo: 日程
   * @param instancesTime: 日程实例的开始时间
   * @param referenceDate: 参考日期
   *
   * @returns titleStr: 标题 · n天
   */
  public agendaTitleDayOffset(agendaInfo: AgendaEventInfo, instancesTime: number, referenceDate: number): string {
    if ((agendaInfo.mImportantEventType !== CalendarContract.EventImportantType.ANNIVERSARIES &&
      agendaInfo.mImportantEventType !== CalendarContract.EventImportantType.COUNTDOWN) ||
      agendaInfo.mTitle === '') {
      return agendaInfo.mTitle;
    }

    // 如果是非重复的倒数日，且日程开始时间小于参考时间，就不计算时间差值
    if (agendaInfo.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN &&
    !agendaInfo.isRepeatEvent() &&
      instancesTime <= referenceDate) {
      return agendaInfo.mTitle;
    }

    const language: string = GlobalData.instance().get(GlobalDataKeys.LANGUAGE) as string;
    const dayOffsetObj = DateUtil.getDayOffset(instancesTime, agendaInfo.mImportantEventType, referenceDate, language);
    const titleStr = this.updateRepeatAgendaTitle(agendaInfo, instancesTime);

    if (dayOffsetObj.dayOffset === 0) {
      return titleStr;
    }
    let titleTail: string = dayOffsetObj.content;
    if (titleTail && titleTail.length > 0) {
      return GlobalThis.getResourceStrParms($r('app.string.agenda_title_separate'), titleStr, titleTail);
    } else {
      return titleStr;
    }
  }

  protected async doStart(): Promise<void> {
    Log.info(TAG, `doStart`);
  }
}
