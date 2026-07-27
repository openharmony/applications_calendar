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


/**
 * the const of table CalendarAccessLevel
 */
export const enum CalendarAccessLevel {
  CAL_ACCESS_NONE = 0,
  CAL_ACCESS_FREEBUSY = 100,
  CAL_ACCESS_READ = 200,
  CAL_ACCESS_RESPOND = 300,
  CAL_ACCESS_OVERRIDE = 400,
  CAL_ACCESS_CONTRIBUTOR = 500,
  CAL_ACCESS_EDITOR = 600,
  CAL_ACCESS_OWNER = 700,
  CAL_ACCESS_ROOT = 800
}


/**
 * the const of table CalendarAccountName
 */
export const enum CalendarAccountName {
  // 默认帐户
  CUSTOM_ACCOUNT_NAME_PRE = 'com.openharmony.calendar_'
}


/**
 * the const of table CalendarAccountType
 */
export const enum CalendarAccountType {
  // 全部帐户
  ALL_ACCOUNT_TYPE = 'all',

  // 默认帐户
  LOCAL_ACCOUNT_TYPE = 'local',

  // 生日帐户
  BIRTHDAY_ACCOUNT_TYPE = 'com.openharmony.birthday',

  // 生日帐户类型
  BIRTHDAY_ACCOUNT_CORE_TYPE = 'birthday',

  // 生日账户id
  BIRTHDAY_ACCOUNT_ID = 'birthDayAccountId',

  // 独立个人帐户
  CUSTOM_ACCOUNT_TYPE = 'com.openharmony.custom',

  // 邮箱类型
  EMAIL_ACCOUNT_TYPE = 'email',

  // OpenHarmony exchange
  OpenHarmony_EXCHANGE_ACCOUNT_TYPE = 'com.OpenHarmony.email.exchange',

  // 订阅类型
  HOLIDAY_ACCOUNT_TYPE = 'holiday',

  // 双框架生日账户的accountType
  DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE = 'com.OpenHarmony.openharmony.birthday'
}
