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


export enum SubscriptionCalendar {
  NO_CALENDAR = -1,
  CHINESE_CALENDAR = 0,
  JAPANESE_CALENDAR = 2,
  PERSIAN_CALENDAR = 3,
  HEBREW_CALENDAR = 4,
  ISLAMIC_HIJILAI_calendar_CALENDAR = 5,
  BUDDHIST_CALENDAR = 6,
  INDIAN_NATIONAL_CALENDAR = 7,
}

export function isChineseCalendar(calendar: SubscriptionCalendar) {
  return calendar === SubscriptionCalendar.CHINESE_CALENDAR;
}

export function isIslamicCalendar(calendar: SubscriptionCalendar) {
  return calendar === SubscriptionCalendar.ISLAMIC_HIJILAI_calendar_CALENDAR;
}
