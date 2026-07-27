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
  AgendaEventInfo,
  CalendarContract,
  CalendarDate,
  CalendarUtils,
  DateUtil,
  EventService,
  GlobalData,
  GlobalDataKeys,
  I18nUtil,
  Log,
  MILLS_PER_DAY,
  PasteHelper,
  ReminderService
} from '@app/common';
import lazy { parseEventInfo2String } from '@app/common/src/main/ets/default/util/ShareUtils';
import lazy { promptAction } from '@kit.ArkUI';


const TAG: string = 'CopyManager';


export class CopyHelper {
  private static _instance: CopyHelper = new CopyHelper();

  static instance(): CopyHelper {
    return CopyHelper._instance;
  }

  private tempEventInfo: AgendaEventInfo | undefined = undefined;

  stashEventInfo(eventInfo: AgendaEventInfo) {
    this.tempEventInfo = eventInfo;
  }

  clear() {
    this.tempEventInfo = undefined;
  }

  getStashEventInfo(): AgendaEventInfo | undefined {
    return this.tempEventInfo;
  }

  // 复制日程信息：暂存日程对象，并复制到剪切板
  async copyEventInfo(eventId: number) {
    if (!eventId || eventId < 0) {
      Log.info(TAG, 'nothing to copy');
      this.clear();
      return false;
    }
    const event = await EventService.INSTANCE.queryEventById(eventId);
    if (this.checkEventCannotCopy(event)) {
      this.clear();
      return false;
    }
    // 重复日程不支持应用内粘贴
    if (!event.isImportantEvent() && event.isRepeatEvent()) {
      this.clear()
    } else {
      // 暂存
      this.stashEventInfo(event);
    }
    // 复制到剪切板
    const contents: string = parseEventInfo2String(event);
    PasteHelper.getInstance().clearSystemBoard();
    PasteHelper.getInstance().setSystemBoard(contents);

    // 复制成功弹窗
    promptAction.showToast({
      message: $r('app.string.share_dialog_success_toast')
    })
    return true;
  }

  private checkEventCannotCopy(event: AgendaEventInfo): boolean {
    if (!event) { // 未查询到日程
      return true;
    }
    if (event.isHoliday()) { // 节假日不复制
      return true;
    }
    return false;
  }

  // 粘贴到当前高亮日
  async pasteEventInfoHighLight() {
    // 获取当前显示日
    const pasteDay = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    Log.info(TAG, 'pasteEventInfoDefault:' + pasteDay);
    return await this.pasteEventInfo(pasteDay);
  }

  // 粘贴到原位置,即粘贴相同日程
  async pasteEventInfoSelf() {
    if (!this.tempEventInfo) {
      return false;
    }
    Log.info(TAG, 'pasteEventInfoSelf:' + this.tempEventInfo.mBegin);
    return await this.pasteEventInfo(this.tempEventInfo.mBegin);
  }

  // 粘贴到指定起始时间，间隔不变
  async pasteEventInfoWithStartTime(pasteTime: number) {
    Log.info(TAG, 'pasteEventInfoWithStartTime:' + pasteTime);
    return await this.pasteEventInfo(pasteTime, pasteTime);
  }

  /**
   * 指定起始日及起始时间，粘贴日程
   * @param pasteDay 指定粘贴日
   * @param pasteTime 指定粘贴时间
   * @returns
   */
  async pasteEventInfo(pasteDay: number, pasteTime?: number) {
    // 待粘贴的日程或目标日期不存在，不执行粘贴
    if (!this.tempEventInfo || !pasteDay) {
      Log.info(TAG, 'nothing to paste');
      return false;
    }
    Log.info(TAG, `pasteDay is ${pasteDay}, pasteTime is ${pasteTime}`);
    // 拷贝待粘贴日程，避免重复粘贴时时间改变
    const pasteEvent = new AgendaEventInfo(this.tempEventInfo);
    // 1.获得原始起止时间及间隔
    const pasteEventBegin = pasteEvent.mBegin;
    const pasteEventEnd = pasteEvent.mEnd;
    const duration = pasteEventEnd - pasteEventBegin;
    Log.info(TAG, `copy event begin ${pasteEventBegin}`);

    // 2.计算目标起止时间
    // 目标日
    const dayDate = new CalendarDate(pasteDay);
    // 目标时，未指定时使用待粘贴日的起始时间，否则使用指定时间
    const timeDate = pasteTime ? new CalendarDate(pasteTime) : new CalendarDate(pasteEventBegin);
    // 目标起止时间
    const pasteBegin = new CalendarDate(dayDate.getFullYear(), dayDate.getMonth(), dayDate.getDate(),
      timeDate.getHours(), timeDate.getMinutes()).getTime();
    const pasteEnd = pasteBegin + duration;
    Log.info(TAG, `pasteBegin is ${pasteBegin}, pasteEnd is ${pasteEnd}`);

    // 3.赋予时间，处理数据并插入日程
    pasteEvent.mBegin = pasteBegin;
    pasteEvent.mEnd = pasteEnd;
    const value = this.getPostValue(pasteEvent);
    let eventId = await EventService.INSTANCE.insertEvent(value);
    // 插入提醒
    let isSucceed = !!eventId;
    if (isSucceed) {
      let checkValuesArrays =
        await ReminderService.INSTANCE.queryReminderInfo(pasteEvent.mId) as Array<CalendarContract.Reminders>;
      if (checkValuesArrays.length > 0) {
        isSucceed = isSucceed && await EventService.INSTANCE.insertReminder(eventId, checkValuesArrays) as boolean;
      }
    }
    return isSucceed;
  }

  getPostValue(eventInfo: AgendaEventInfo) {
    // 重要日/普通日程时间处理
    let dtStart: number = 0;
    let dtEnd: number = 0;
    let startTime: number = new CalendarDate(0, 0, 0).getTime();
    let endTime: number = new CalendarDate(0, 0, 0).getTime();
    if (eventInfo.mIsAllDay) {
      // 全天日程开始日期是当天UTC 0点 结束日期获取结束日期当天UTC24:00
      let current = new CalendarDate(eventInfo.mBegin);
      current.setHours(0, 0, 0);
      startTime = current.getTime() + current.getTimezoneOffset(current.getTime());
      Log.info(TAG, `getPostValue allDay current timeMillIs ${current.getTime()}, startTime ${startTime}`);
      dtStart = startTime;
      let endCurrent = new CalendarDate(eventInfo.mEnd);
      endCurrent.setHours(0, 0, 0);
      endTime = endCurrent.getTime() + endCurrent.getTimezoneOffset(endCurrent.getTime());
      dtEnd = eventInfo.mEnd === 0 ? (startTime + MILLS_PER_DAY) : endTime;
      const isSameDay = CalendarUtils.isSameDay(dtStart, dtEnd - MILLS_PER_DAY);
      if (!isSameDay && eventInfo.isLunarEvent()) {
        dtEnd = dtEnd - MILLS_PER_DAY;
      }
    } else {
      dtStart = eventInfo.mBegin === 0 ? startTime : eventInfo.mBegin;
      dtEnd = eventInfo.mEnd === 0 ? endTime : eventInfo.mEnd;
    }

    const value: Record<string, string | Number> = {
      'title': eventInfo.mTitle,
      'dtstart': DateUtil.changeToUTCTime(dtStart),
      'dtend': DateUtil.changeToUTCTime(dtEnd),
      'calendar_id': eventInfo.mCalendarId,
      // 存储系统当前时区, 默认上海'Asia/Shanghai'
      'eventTimezone': eventInfo.mIsAllDay ? 'UTC' : I18nUtil.getSystemTimeZone(),
      'description': eventInfo.mDescription.length === 0 ? '' : eventInfo.mDescription,
      'allDay': eventInfo.mIsAllDay ? 1 : 0,
      'eventLocation': eventInfo.mLocation.length === 0 ? '' : eventInfo.mLocation,
      'important_event_type': eventInfo.mImportantEventType,
      'event_time_stamp': Date.now(),
      'rrule': eventInfo.mRepeatRule,
      'event_calendar_type': eventInfo.mEventCalendar,
      'hwext_alert_type': eventInfo.alertType
    };

    return value;
  }
}