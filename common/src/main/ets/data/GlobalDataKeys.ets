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



export enum GlobalDataKeys {

  TAB_INDEX = 'tabIndex', //tab页签的索引值

  DISPLAY_DATE = 'displayDate', //当前展示的视图的日期信息

  CURRENT_DATE = 'currentDate', //当前当天的视图的日期信息

  IS_RECESS_TOGGLE_ON = 'isRecessToggleOn', //设置项班休展示开关是否打开

  IS_RECESS_DATA_LOADED = 'isRecessDataLoaded', //班休数据是否加载

  START_OF_WEEK = 'startOfWeek', //一周开始日

  WEEKENDS = 'weekends', //周末

  DEFAULT_REMIND_TIME = 'defaultRemindTime', //默认提醒时间

  ALL_DAY_EVENTS_DEFAULT_REMIND_TIME = 'allDayEventsDefaultRemindTime', //全天事件默认提醒时间

  SETTINGS_HIDDEN_ITEMS = 'settingsHiddenItems', //设置界面隐藏的设置项

  SUBSCRIPTION_CALENDAR = 'subscriptionCalendar', //其它历法

  SHOW_MULTI_DELETE = 'showMultiDelete', //显示多选日程按钮

  SYSTEM_REGION = 'systemRegion', //系统设置地区

  IS_SHOW_WEEK_NUM_TOGGLE_ON = 'showWeekNumber', //显示周数

  IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW = 'showImportantDay', //月视图中显示重要日

  IS_SHOW_RECOMMENDED_SUBSCRIPTION = 'showRecommendedSubscription', //是否显示推荐订阅轮播图 true: 展示

  CHECK_EVENT_ID = 'checkEventId', //选中日程id值

  IS_CHOOSE_SUBSCRIPTION_CALENDAR = 'isChooseSubscriptionCalendar', //是否选中其他历法

  IS_24_HOUR_CLOCK = 'is24HourClock', //是否是24小时制

  LANGUAGE = 'language', //语言

  FONT_SIZE_SCALE = 'fontSizeScale', // 大字体档位参数

  THEME_COLOR = 'themeColor', //主题色

  LIGHT_THEME_COLOR = 'lightThemeColor', //重要日浅主题色

  Dark_THEME_COLOR = 'darkThemeColor', //重要日深主题色

  BESIDE_THEME_COLOR = 'besideThemeColor', //重要日灰色主题色

  BG_THEME_COLOR = 'bgThemeColor', // 0.1透明度主題色

  BG_COLOR = 'bgColor', //背景色

  IS_DARKMODE = 'isDarkMode',

  SHARE_SCHEDULE_POPUPS = 'shareSchedulePopups', //新建日历-添加共享成员tips

  ACCOUNT_SHARE_POPUPS = 'accountSharePopups', //新建日历账户-添加共享成员tips

  SHARE_SWITCH = 'share_switch', // 共享开关

  IS_ACCOUNT_LOGIN = 'isAccountLogin', //是否登录华为账户

  CURRENT_LANGUAGE = 'language', //当前系统的语言

  ENABLE_RECEIVE_SHARE_DATA = 'ENABLE_RECEIVE_SHARE_DATA', //是否接收共享数据开关

  WINDOW_TOP_AVOID_HEIGHT_IN_PX = 'windowTopAvoidHeightInPx', //顶部规避高度,px

  WINDOW_WIDTH_IN_PX = 'windowWidthInPx', // 窗口宽度px

  WINDOW_HEIGHT_IN_PX = 'windowHeightInPx', // 窗口高度px

  BIRTHDAY_ACCOUNT_ID = 'birthDayAccountId', // 生日账户id

  UNUSUAL_MODE = 'unusualMode', // 特殊模式（hicar、上下小折叠...)

  FOLD_SCREEN_TYPE = 'foldScreenType', // 折叠屏类型（0,0,0,0）

  IS_SUB_WINDOW_DETAIL = 'isSubWindowDetail', //是否打开详情子窗

  IS_OPEN_ACCESSIBILITY_SCREEN_READER = 'isOpenAccessibilityScreenReader', // 无障碍屏幕朗读能力

  IS_NOTIFICATION_GRANTED = 'isNotificationGranted', // 通知权限授权

  CHINESE_HOLIDAY_STATE = 'CHINESE_HOLIDAY_STATE',

  LAST_OPEN_SIDEBAR = 'isFirstOpenSidebar', //最后操作侧边栏是否打开,此时需要保持默认三分栏

  IS_NETWORK_AVAILABLE = 'isNetWorkAvailable', //网络是否可用

  IS_SLIDE_SLIP_BACK = 'isSlideSlipBack', //侧滑返回桌面

  IS_FIRST_LOAD_REGIONHOLIDAY = 'isFirstLoadRegionHoliday', // 是否第一次加载节假日

  IS_WALLPAPER_MODE = 'isWallpaperMode', // 是否台历模式

  SIDEBAR_WIDTH = 'sideBarWidth', // 侧边栏宽度

  IS_FORM_BASE_INFO_CLEANED = 'isFormBaseInfoCleaned', // 是否已经清理form_base_info中的脏数据

  AGENDA_LIST_WIDTH = 'agendaListWidth', // 右侧日程列表宽度
}
