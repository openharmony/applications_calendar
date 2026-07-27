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

import { CalendarContract, CalendarDate, DateUtil, Log, LunarDateUtil } from '@app/common';
import { AgendaEventInfo } from '@app/common/src/main/ets/agenda/AgendaEventInfo';
import { ShareType } from './BusinessConstant';

const TAG = 'ShareEventVcsBean';
/**
 * 分享日程bean
 */
export class ShareEventVcsBean {
  public readonly text: string | undefined;
  public readonly fileUri: string | undefined;
  public readonly icsPath: string | undefined;
  public readonly event: AgendaEventInfo | undefined;
  public readonly shareType: ShareType;
  public readonly shareTitle?: string;
  public readonly description? : string;

  constructor(shareType: ShareType, text?: string, fileUri?: string,
              icsPath?: string, event?: AgendaEventInfo, shareTitle?: string) {
    this.shareType = shareType;
    this.text = text;
    this.fileUri = fileUri;
    this.icsPath = icsPath;
    this.event = event;
    this.shareTitle = shareTitle;
    this.description = this.getTimeStr();
  }

  /**
   * 获取日程时间的文字显示内容
   *
   * @param time 日程时间
   */
  getTimeStr(): string {
    if (!this.event) {
      Log.info(TAG, 'info is null');
      return '';
    }
    const dateOfTime = new CalendarDate(this.event.mBegin);
    const yearOfTime = dateOfTime.getFullYear();
    const yearOfNow = new CalendarDate().getFullYear();
    // 是否重要日

    let isImportantDay = (): boolean  => {
      return this.event?.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
        this.event?.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
    }
    let mIsAllDay: boolean = this.event?.mIsAllDay;
    let options: Record<string, string | Boolean> = {
      'month': 'long',
      'day': 'numeric',
    };
    if (!isImportantDay()) {
      options['weekday'] = 'long';
    }

    if (yearOfTime !== yearOfNow) {
      // 非本年时增加年份字段
      options['year'] = 'numeric';
    }
    if (this.event?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      if (isImportantDay()) {
        return LunarDateUtil.getLunarDate(dateOfTime)
      } else {
        return DateUtil.lunarDateString(dateOfTime);
      }
    }
    return DateUtil.intlDateFormatChineseStyle(dateOfTime, options);
  }

}