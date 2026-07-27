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
 * 设置的持久化数据存放的key值
 *
 * @since 2022-07-27
 */
enum settingKeys {
  showWeatherForecast = 'SHOW_WEATHER_FORECAST', // 在日程中显示天气预报
  showImportantDay = 'SHOW_IMPORTANT_DAY', // 月视图中同时显示重要日
  subscribeService = 'SUBSCRIBE_SERVICE', // 订阅服务
  isRecessToggleOn = 'IS_RECESS_TOGGLE_ON', // 显示节假班休信息设置开关的状态
  showWeekNumber = 'SHOW_WEEK_NUMBER', // 显示周数
  startOfWeek = 'START_OF_WEEK', // 一周开始日
  weekends = 'WEEKENDS', // 周末
  lockTimeZone = 'LOCK_TIME_ZONE', // 锁定时区 dirty数据,废弃
  timeZone = 'TIME_ZONE', // dirty数据,废弃
  isTimeZoneLocked = 'IS_TIME_ZONE_LOCKED', // 锁定时区
  lockedTimeZone = 'LOCKED_TIME_ZONE', // 选择的锁定时区值
  defaultRemindTime = 'DEFAULT_REMIND_TIME', // 默认提醒时间
  allDayEventsDefaultRemindTime = 'ALL_DAY_EVENTS_DEFAULT_REMIND_TIME', // 全天事件默认提醒时间
  subscriptionCalendar = 'SUBSCRIPTION_CALENDAR', // 其它历法
  isChooseSubscriptionCalendar = 'IS_CHOOSE_SUBSCRIPTION_CALENDAR', // 是否选择过历法
  nationalRegionHoliday = 'NATIONAL_REGION_HOLIDAY', // 国家地区节假日
  isAllowNetwork = 'IS_ALLOW_NETWORK', // 是否允许访问网络
  // 已经脏数据,废弃
  isShareSwitch = 'SHARE_SWITCH', // 共享开关设置开关状态
  enableReceiveShareDataSwitch = 'ENABLE_RECEIVE_SHARE_DATA_SWITCH', //是否接收共享数据开关
};

export default settingKeys;