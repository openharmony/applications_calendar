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

import { AgendaEventInfo } from '../../../agenda/AgendaEventInfo';
import { CalendarContract } from '../../../default/calendar/CalendarContract';


/**
 * 导入日程数据的封装
 */
export class AgendaEventInfoWrap extends AgendaEventInfo {
  public reminders: CalendarContract.Reminders[] = [];

  public reset() {
    this.mDescription = '';
    this.mEnd = -1;
    this.mBegin = -1;
    this.duration = '';
    this.hasAlarm = '';
    this.lastDate = -1;
    this.mRepeatRule = '';
    this.status = '';
    this.mTitle = '';
    this.mLocation = '';
    this.eventTimeZone = '';
    this.accessLevel = -1;
    this.mIsAllDay = false;
    this.mEventImageType = '';
    this.mEventCalendar = 0;
    this.mImportantEventType = 0;
    this.alertType = 0;
    this.reminders = [];
    this.mLanguageResources = '';
    this.mLanguageRecord = {};
  }
}