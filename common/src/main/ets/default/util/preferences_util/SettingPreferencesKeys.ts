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

export enum SettingPreferencesKeys {

  SHOW_WEATHER_FORECAST = 'SHOW_WEATHER_FORECAST', // 在日程中显示天气预报
  SHOW_IMPORTANT_DAY = 'SHOW_IMPORTANT_DAY', // 月视图中同时显示重要日
  SUBSCRIBE_SERVICE = 'SUBSCRIBE_SERVICE', // 订阅服务
  IS_RECESS_TOGGLE_ON = 'IS_RECESS_TOGGLE_ON', // 显示节假班休信息设置开关的状态
  SHOW_WEEK_NUMBER = 'SHOW_WEEK_NUMBER', // 显示周数
  START_OF_WEEK = 'START_OF_WEEK', // 一周开始日
  WEEKENDS = 'WEEKENDS', // 周末
  IS_TIME_ZONE_LOCKED = 'IS_TIME_ZONE_LOCKED', // 锁定时区
  LOCKED_TIME_ZONE = 'LOCKED_TIME_ZONE', // 选择的锁定时区值
  DEFAULT_REMIND_TIME = 'DEFAULT_REMIND_TIME', // 默认提醒时间
  ALL_DAY_EVENTS_DEFAULT_REMIND_TIME = 'ALL_DAY_EVENTS_DEFAULT_REMIND_TIME', // 全天事件默认提醒时间
  SUBSCRIPTION_CALENDAR = 'SUBSCRIPTION_CALENDAR', // 其它历法
  IS_CHOOSE_SUBSCRIPTION_CALENDAR = 'IS_CHOOSE_SUBSCRIPTION_CALENDAR', // 是否选择过历法
  IS_ALLOW_NETWORK = 'IS_ALLOW_NETWORK', // 是否允许访问网络
  HAS_ALLOW_LOCATION_AND_NETWORK_SERVICE = 'HAS_ALLOW_LOCATION_AND_NETWORK_SERVICE', // 用户同意定位网络
  SHARE_SCHEDULE_POPUPS = 'SHARE_SCHEDULE_POPUPS', // 新建日历-添加共享成员tips
  ACCOUNT_SHARE_POPUPS = 'ACCOUNT_SHARE_POPUPS', // 新建日历账户-添加共享成员tips
  LATEST_SHARE_ACCOUNT_ID = 'LATEST_SHARE_ACCOUNT_ID', // 侧边栏显示共享账户
  SHARE_SWITCH = 'SHARE_SWITCH', // 分享开关
  ENABLE_RECEIVE_SHARE_DATA_SWITCH = 'ENABLE_RECEIVE_SHARE_DATA_SWITCH', //是否接收共享数据开关
  BACK_GROUND_CHECKED_INTERVAL = 'BACK_GROUND_CHECKED_INTERVAL', // 后台选中的轮训间隔
  IS_SHOW_RECOMMENDED_SUBSCRIPTION = 'IS_SHOW_RECOMMENDED_SUBSCRIPTION', // 是否开推荐订阅启轮播图
  SHOULD_MIGRATE_CUSTOM_RING_TONE = 'SHOULD_MIGRATE_CUSTOM_RING_TONE', // 是否需要进行铃声迁移
}