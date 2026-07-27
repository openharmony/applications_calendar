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

import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';

export class AgendaEventInfo {
  public static FLAG_START: number = 0;
  public static FLAG_MID: number = 1;
  public static FLAG_END: number = 2;
  public mId: number = 0;
  public mCalendarId: number = 0;
  public mTitle: Resource | string = '';
  public mLocation: string = '';
  public mDescription: string = '';
  public mStartDay: number = 0;
  public mEndDay: number = 0;
  public mFlag: number = 0;
  public mDisplayColor: number = 0;
  public mDay: number = 0;
  public mEventType: number = 0;
  public mBegin: number = 0;
  public mEnd: number = 0;
  public mIsAllDay: boolean = false;
  public mIsMultiDayEvent: boolean = false;
  public mIsSetDayHead: boolean = false;
  public mEventCalendar: number = 0;
  public mEventImageType: string = '';
  public mIsCanceled: boolean = false;
  public mSelfAttendeeStatus: boolean = false;
  public mIsMeetingEvent: boolean = false;
  public mPosition: number = 0;
  public mRepeatRule: string = '';
  public mEventTimeStamp: number = 0;
  public mImportantEventType: number = 0;
  public mHwextServiceType: string = '';
  public mHwextServiceVerified: boolean = false;
  public mHwextServiceUri: string = '';
  public mHwextServicePkgName: string = '';
  public mHwextServiceMinVersion: string = '';
  public mHwextServiceDescription: string = '';
  public mCornerType: number = 0;
  public checkValuesArray: CalendarContract.Reminders[] = [];
  public mAttendeeList: Array<CalendarContract.Attendees> = [];
  public mIsHoliday?: boolean;
}

 