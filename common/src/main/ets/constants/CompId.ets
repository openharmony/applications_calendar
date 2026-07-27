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
 * 界面元素id，便于自动化用例设计的时候捕捉操作控件属性
 * 确保元素id唯一
 *
 * @since 2022-02-01
 */
export enum CompId {
  ENTRY_PAGE_NAVIGATION = 'entry_page_navigation',
  MAIN_PAGE_NAV_DESTINATION = 'main_page_nav_destination',
  CALENDAR_SIDEBAR_CONTAINER = 'calendar_sidebar_container',
  MAIN_PAGE_BUILD_MENU = 'main_page_build_menu', //主页面菜单栏（年月周日那一栏）
  BUTTON_IN_MAIN_PAGE = 'button_in_main_page',

  /* 主界面 */
  MAIN_PAGE_DATE_INFO = 'main_page_date_info', // 主界面左上角年月信息
  SLIDE_TAB_BAR = 'SlideTabBar', //主界面tab
  MAIN_TAB_COMPONENT = 'MainTabComponent', //主界面tab页内容
  TABS_YEAR = 'tabs_year', // 年视图tab页签
  TABS_MONTH = 'tabs_month', // 月视图tab页签
  TABS_WEEK = 'tabs_week', // 周视图tab页签
  TABS_DAY = 'tabs_day', // 日视图tab页签
  DATE_SWITCH_LEFT_ARROW = 'date_switch_left_arrow', // 日期切换器左箭头
  BUTTON_BACK_TO_TODAY = 'button_back_to_today', // “回到今天”按钮
  DATE_SWITCH_RIGHT_ARROW = 'date_switch_right_arrow', // 日期切换器右箭头
  ADD_AGENDA = 'phone_add_agenda', // 新增日程按钮
  HIDE_AGENDA = 'phone_hide_agenda', // 隐藏日程按钮

  /* 年视图 */
  CHINESE_ZODIAC_LEGEND = 'chinese_zodiac_legend', // 年视图左上角生肖年信息
  LUNAR_LEGEND = 'lunar_legend', // 年视图左上角农历初一标识
  RECESS_LEGEND = 'recess_legend', // 年视图左上角班休标识
  YEAR_VIEW = 'year_view', // 年视图
  YEAR_LEGEND = 'year_legend', // 年视图左上角生肖年和农历信息
  YEAR_SWIPER = 'year_swiper', //年视图swiper
  ONE_YEAR_VIEW = 'one_year_view', //年视图swiper的内容

  /* 月视图 */
  MONTH_VIEW = 'month_view',
  WEARABLE_MONTH_VIEW = 'wearable_month_view', // 穿戴设备上的月视图
  SINGLE_MONTH_VIEW = 'single_month_view', // 单个月视图
  WEARABLE_SINGLE_MONTH_VIEW = 'wearable_single_month_view', // 穿戴设备上的单个月视图
  MONTH_VIEW_DATE = 'month_view_date', // 月视图中的日期
  OPEN_CN_HOLIDAY_TIP = 'open_cn_holiday_tip', //月视图打开常用节假日显示tip
  BACK_TO_TODAY = 'back_to_today', // 回到今天
  NO_AGENDA = 'no_agenda', //日程列表无日程
  MONTH_VIEW_SLIDE_UP = 'month_view_slide_up', //月视图上滑
  MONTH_VIEW_SWIPER = 'month_view_swiper', //月视图swiper
  LARGE_SINGLE_MONTHLY_VIEW = 'large_single_monthly_view', //大屏月视图
  SMALL_SINGLE_MONTHLY_VIEW = 'small_single_monthly_view', //小屏月视图
  BUILD_LARGE_DATE_AREA = 'build_large_date_area', //月视图日期区域
  SMALL_SINGLE_MONTHLY_VIEW_AGENDA_AREA = 'small_single_monthly_view_agenda_area', //小屏月视图日程区域
  MONTH_VIEW_DATE_BANNER = 'month_view_date_banner', //月视图日程区域左上方显示选中日期农历信息的banner
  AGENDA_LIST = 'agenda_list', //小屏月视图日程列表
  NORMAL_AGENDA_LIST_ITEM = 'normal_agenda_list_item', //普通日程ListItem
  SYNC_TODO_LIST_ITEM = 'sync_todo_list_item', //同步待办ListItem
  SYNC_TODO_CHECKBOX = 'sync_todo_checkbox', //同步待办选择圈
  SYNC_TODO_CONTENT = 'sync_todo_content', //同步待办信息（标题，时间）
  AGENDA_TIME_LINE = 'agenda_time_line', //日程时间轴
  AGENDA_CONTEND = 'agenda_contend', //日程信息（标题，地点）
  SINGLE_WEEK_AGENDA_AREA = 'single_week_agenda_area',
  SUBSCRIPTION_GROUP = 'subscription_group', // 月视图列表内的订阅卡片组
  SCHEDULE_GROUP = 'schedule_group', // 月视图列表内的课程表卡片组

  /* 日程视图 */
  LOAD_PRE_AGENDA_TEXT = 'load_pre_agenda_text', // 查看x年x月x日之前的日程-文字内容
  LOAD_AFTER_AGENDA_TEXT = 'load_after_agenda_text', // 查看x年x月x日之后的日程-文字内容
  ALL_AGENDA = 'all_agenda', //全部日程
  AGENDA_INFO = 'agenda_info', //日视图右侧的日程信息(标题，时间，地点)
  AGENDA_MAP = 'agenda_map', //日程详情静态缩略图
  AGENDA_REMINDER_INFO = 'agenda_reminder_info', //提醒，重要提醒块
  EVENT_OTHER_INFO = 'event_other_info', //日程其他信息块（日程所属账户，日程说明信息）
  AGENDA_HIDE_LIST = 'agenda_hide_list', // 隐藏日程列表

  /* 新建日程 */
  TABS_SCHEDULE = 'tabs_schedule', //日程tab页签
  TABS_IMPORTANT_EVENT = 'tabs_important_event', //重要日tab页签
  ADD_AGENDA_TITLE = 'add_agenda_title', // 新建日程 - 标题
  ADD_AGENDA_LOCATION = 'add_agenda_location', // 新建日程 - 地点
  ADD_AGENDA_START_TIME = 'add_agenda_start_time', // 新建日程 - 开始时间
  ADD_AGENDA_END_TIME = 'add_agenda_end_time', // 新建日程 - 结束时间
  ADD_AGENDA_IMPORTANT_TIME = 'add_agenda_important_time', // 新建日程 - 重要日时间
  ADD_AGENDA_ADD_REMIND = 'add_agenda_add_remind', // 新建日程 - 添加提醒（按钮）
  ADD_AGENDA_REMARK = 'add_agenda_remark', // 新建日程 - 说明
  ADD_AGENDA_COMFRIM = 'add_agenda_comfrim', // 新建日程 - 确认
  ADD_AGENDA_CANCEL = 'add_agenda_cancel', // 新建日程 - 取消
  ADD_AGENDA_SHARE_PERSON = 'add_agenda_share_person', // 新建日程 - 添加共享成员
  CANCEL_SINGLE_REMIND = 'add_agenda_cancel_single_remind', // 新建日程 - 取消单个提醒git
  ADD_AGENDA_START_TIME_TEXT = 'add_agenda_start_time_text', // 新建日程 - 开始时间文本
  ADD_AGENDA_END_TIME_TEXT = 'add_agenda_end_time_text', // 新建日程 - 结束时间文本
  ADD_AGENDA_SELECT_ACCOUNT = 'add_agenda_select_account', // 新建日程 - 选择账户（按钮）
  ADD_AGENDA_SELECTED_ACCOUNT_TEXT = 'add_agenda_selected_account_text', // 新建日程 - 被选账户文本
  ADD_AGENDA_SELECTED_ACCOUNT_CIRCLE = 'add_agenda_selected_account_circle', // 新建日程 - 被选账户圆点
  ADD_AGENDA_IMP_DATE_TEXT = 'add_agenda_imp_date_text', // 新建日程 - 重要日日期文本
  NEW_IMPORTANT_EVENT = 'new_important_event', //新建重要日
  EDIT_IMPORTANT_EVENT = 'edit_important_event', //编辑重要日
  EDIT_EVENT = 'edit_event', //编辑日程
  NEW_EVENT = 'new_event', //新建日程
  AGENDA_DATE_AND_TIME_PICKER = 'agenda_date_and_time_picker', // 时间选择弹窗
  AGENDA_DATE_TITLE = 'agenda_date_title', //开始|结束 - 时间选择弹窗
  SHOW_LUNAR_CALENDAR = 'show_lunar_calendar', //开始|结束 - 显示农历
  REPEAT = 'repeat', //新建日程 重复TEXT
  AGENDA_ABBREVIATION = 'agenda_abbreviation', //一句话创建
  PASTE_BUTTON = 'paste_button', //粘贴按键
  ADD_AGENDA_SELECTED_TIMEZONE = 'add_agenda_selected_timezone', // 新建日程-选择时区
  AGENDA_DETAIL_PAGE_BOX = 'agenda_detail_page_box', // 日程详情容器

  /* 日历设置 */
  SEARCH_AGENDA = 'search_agenda', // 搜索日程

  MORE_MENU = 'more_menu', // 更多设置
  MENU_JUMP_SPECIFIED_DATE = 'menu_jump_specified_date', // 更多--> 跳转到指定日期
  MENU_SHOW_ALL_AGENDA = 'menu_show_all_agenda', // 更多-->查看全部日程
  MENU_PREFERENCES = 'menu_preferences', // 更多-->设置
  MENU_FEEDBACK = 'menu_feedback', // 帮助与客服

  SETTINGS_SCROLL = 'settings_scroll', //设置--整体滚动页面
  SETTINGS_CALENDAR = 'settings_calendar', // 其他历法
  SETTINGS_IS_CHOOSE_CALENDAR = 'is_choose_calendar', // 是否选择过历法
  SETTINGS_NATIONAL_REGION_HOLIDAY = 'settings_national_region_hiliday', // 国家（地区）节日
  SETTINGS_WEATHER_FORECASTS = 'settings_weather_forecasts', // 天气预报
  SETTINGS_IMPORTANT_DAYS = 'settings_important_days', // 重要日
  SETTINGS_ADD_ONS = 'settings_add_ons', // 订阅服务
  SETTINGS_SHOW_RECESS = 'settings_show_recess', // 显示节假班休信息
  SETTINGS_SHOW_WEEK_NUMBER = 'settings_show_week_number', // 显示周数
  SETTINGS_START_OF_WEEK = 'settings_start_of_week', // 一周开始日
  SETTINGS_WEEKENDS = 'settings_weekends', // 周末
  SETTINGS_LOCK_TIME_ZONE = 'settings_lock_time_zone', // 锁定时区
  SETTINGS_TIME_ZONE = 'settings_time_zone', // 时区
  SETTINGS_NOTIFICATION = 'settings_notification', // 通知
  SETTINGS_NOTIFICATION_RING = 'settings_notification_ring', // 普通通知铃声
  SETTINGS_IMPORTANT_NOTIFICATION_RING = 'settings_important_notification_ring', // 重要通知铃声
  SETTINGS_DEFAULT_REMINDER_TIME = 'settings_default_reminder_time', // 默认提醒时间
  SETTINGS_REMINDER_TIME_FOR_ALLDAY_EVENT = 'settings_reminder_time_for_allday_event', // 全天事件默认提醒时间
  SETTINGS_THIRD_PARTY_SDK_LIST = 'settings_third_party_sdk_list', // 第三方SDK
  SETTINGS_PERSONAL_INFORMATION_COLLECTED = 'settings_personal_information_collected', // 个人信息收集清单
  SETTINGS_APPLICATION_DISPLAY_RECORD_NUMBER = 'settings_application_display_record_number', // 应用展示备案号
  SETTINGS_CUSTOMER_SERVICE_HOTLINE = 'settings_customer_service_hotline', // 客服电话
  SETTINGS_NETWORK = 'settings_network', // 网络请求
  SETTINGS_RECOMMENDED_SUBSCRIPTION = 'settings_recommended_subscription', // 推荐订阅
  SHARE_SWITCH = 'share_switch', // 共享开关
  CALENDAR_VIEW_SETTINGS = 'calendar_view_settings', //日历视图
  HELP = 'help', //帮助与客服
  SHARING = 'sharing', //共享
  REMINDER_SETTINGS = 'reminder_settings', // 提醒
  ALTERNATE_CALENDARS = 'alternate_calendars', //设置-->其他历法
  WEEK_STARTS_ON = 'week_starts_on', //设置-->一周开始日
  DEFAULT_REMINDER_TIME = 'default_reminder_time', //设置-->默认提醒时间
  ALL_DAY_EVENTS_DEFAULT_REMIND_TIME = 'all_day_events_default_remind_time', //设置-->全天事件默认提醒时间
  WEEKENDS = 'weekends', //设置-->周末
  SETTINGS_STATEMENT_AND_PRIVACY = 'settings_statement_and_privacy', // 设置--关于日历的隐私与声明
  SETTINGS_About = 'settings_about', //设置--关于
  SETTINGS_FeedBack = 'settings_feedBack', //设置--问题与建议
  SETTING_FIRST_GROUP = 'setting_first_group', // 设置项- 第一组
  SETTING_TIMEZONE = 'setting_timezone', // 设置项-时区
  SETTING_SECURITY = 'setting_security', // 设置项-安全与隐私
  SETTING_NETWORK = 'setting_network', // 设置项-联网操作
  SETTING_LEARN_USER_DATA = 'setting_learnuserdata', // 设置 - 了解我们如何使用您的数据

  // 周视图
  WEEK_VIEW_ROOT = 'week_view_root', // 周视图根组件
  WEEK_VIEW_TITLE = 'week_view_title', //周视图标题
  DATE_VIEW = 'date_view', //日期视图
  WEEK_VIEW_SWIPER = 'week_view_swiper',
  GANTT_VIEW_SWIPER = 'gantt_view_swiper',
  WEARABLE_WEEK_LIST_VIEW = 'wearable_week_list_view', // 穿戴设备上的单个周视图列表
  WEEK_ALLDAY_AREA = 'week_allday_area', // 周视图展示全天日程区域

  // 日视图
  DAY_VIEW_ROOT = 'day_view_root', // 日视图根组件

  //甘特图
  GANTT_VIEW = 'gantt_view', //甘特图
  GANTT_VIEW_ROOT = 'gantt_view_root', //甘特图根组件
  GRID_GANTT = 'grid_gantt', //甘特图网格区域
  GANTT_VIEW_AGENDA_POP = 'gantt_view_agenda_pop', //甘特图弹窗

  ALL_DAY = 'all_day', // 全天
  MORNING = 'morning', // 上午
  AFTERNOON = 'afternoon', // 下午
  EXPAND_AND_COLLAPSE_ALL_DAY_AGENDA = 'expand_and_Collapse_all_day_agenda', //展开和收起全天日程
  ALL_DAY_AGENDA_BLOCK = 'all_day_agenda_block', //全天日程块
  NORMAL_AGENDA_BLOCK = 'normal_agenda_block', //普通日程块

  /* 侧边栏 */
  SIDEBAR = 'sidebar', //侧边栏
  EXPAND_AND_COLLECTION_SIDEBAR_BUTTON = 'expand_and_collapse_sidebar_button', //展开和收起侧边栏
  SIDEBAR_ACCOUNT_CALENDAR = 'sidebar_account_calendar', //日历账户
  LOCAL_CALENDAR = 'local_calendar', //本地日历
  SIDEBAR_ACCOUNT_CALENDAR_LOGIN = 'sidebar_account_calendar_login', //华为账号
  EXPAND_AND_COLLECTION_ACCOUNTS = 'expand_and_collapse_account', //展开和收起帐户
  ADD_ACCOUNT = 'add_account', //添加账户
  ADD_CALENDAR = 'add_calendar', // 添加日历
  ADD_SCHEDULE = 'add_schedule', // 添加课表
  IMPORT_AGENDA = 'import_agenda', // 导入日程
  SELECT_ACCOUNT = 'select_account', //选择帐户
  CLICK_ON_ACCOUNTS = 'click_on_accounts', //点击帐户
  SIDEBAR_MESSAGE_CENTER = 'sidebar_message_center', //消息中心
  SIDEBAR_DATE_SWITCH_LEFT_ARROW = 'sidebar_date_switch_left_arrow', //侧边栏日期切换左箭头
  SIDEBAR_DATE_SWITCH_RIGHT_ARROW = 'sidebar_date_switch_right_arrow', //侧边栏日期切换右箭头
  SIDEBAR_DATE_INFO = 'sidebar_date_info', //侧边栏年月信息
  UN_READ = 'un_read', //消息中心 - 未读
  READ = 'read', //消息中心 - 已读
  SUBSCRIBE_MANAGE = 'subscribe_Manage', //订阅管理
  SUBSCRIPTION_LIST = 'subscription_list', //订阅列表

  // 日程详情
  AGENDA_DETAIL_SHARE = 'agenda_detail_share', // 日程详情页分享按钮
  AGENDA_DETAIL_EDIT = 'agenda_detail_edit', // 日程详情页编辑按钮
  AGENDA_DETAIL_DELETE = 'agenda_detail_delete', // 日程详情页删除按钮
  AGENDA_DETAIL_BACK = 'agenda_detail_back', // 日程详情返回按钮
  AGENDA_DETAIL_MULTI_DELETE = 'agenda_detail_multi_delete', // 日程详情页批量删除按钮
  AGENDA_DETAIL_MULTI_SHARE = 'agenda_detail_multi_share', // 日程详情页批量分享按钮
  WEARABLE_AGENDA_DETAIL_PAGE = 'wearable_agenda_detail_page', // 穿戴的日程详情页
  AGENDA_LIST_KEY = 'agendaListKey', //日程列表页面日程List
  CUSTOM_TITLE = 'custom_title', //全部日程页面顶部的title
  CUSTOM_TITLE_TEXT = 'CUSTOM_TITLE_TEXT', //全部日程页面顶部的title文本
  FLEX_AGENDA_LIST = 'flex_agenda_list', // 全部日程页面
  AGENDA_LIST_VIEW = 'agenda_list_view', //全部日程页面左半边
  WEARABLE_AGENDA_LIST_VIEW = 'agenda_list_view', // 穿戴的日程列表视图
  OPEN_CLOUD_SYNC_TIP = 'open_cloud_sync_tip', //全部日程页面左半边的上方 云同步tip
  AGENDA_LIST_STACK = 'agenda_list_stack', //全部日程页面左半边的下方 日程list
  AGENDA_DETAIL = 'agenda_detail', //全部日程页面右边，日程详情
  AGENDA_JOIN_MEETING_BTN = 'agenda_join_meeting_btn', // 加入会议按钮
  ID_BT_AGENDA_DETAIL_SHARE = 'id_bt_agenda_detail_share', // 日程分享按钮
  ID_BT_AGENDA_DETAIL_POP_SHARE = 'id_bt_agenda_detail_pop_share', // 日程pop分享按钮
  ID_BT_AGENDA_DETAIL_SHARE_BOTTOM_BTN = 'id_bt_agenda_detail_share_bottom_btn', // 日程分享按钮-底部tab
  BOX_BOTTOM_TAB = 'box_bottom_tab', // 分享编辑删除按钮容
  SELECTED_AGENDA_VIEW_AGENDA_DETAIL = 'selected_agenda_view_agenda_detail', // 日视图页面日程详情
  AGENDA_DETAIL_ROOT_AGENDA_DETAIL = 'agenda_detail_root_agenda_detail', // 日程详情页面日程详情
  FLEX_AGENDA_LIST_AGENDA_DETAIL = 'flex_agenda_list_agenda_detail', // 全部日程页面日程详情
  FLEX_SEARCH_AGENDA_AGENDA_DETAIL = 'flex_search_agenda_agenda_detail', // 搜索日程页面日程详情
  AGENDA_LIST_MORE = 'agenda_list_more', // 全部日程更多按钮(目前包括：日程多选，节日节气显示)

  // 搜索日程
  FLEX_SEARCH_AGENDA_SEARCH_INPUT = 'flex_search_agenda_search_input', // 搜索日程搜索组件

  // 重复日程
  EVENT_ADD_REPEAT = 'event_add_repeat', //重复
  NO_REPEAT = 'no_repeat', // 不重复
  EVERY_DAY_REPEAT = 'every_day_repeat', //每天
  EVERY_WEEK_REPEAT = 'every_week_repeat', //每周
  EVERY_MONTH_REPEAT = 'every_month_repeat', //每月
  EVERY_YEAR_REPEAT = 'every_year_repeat', //每年
  EVERY_LUNAR_YEAR_REPEAT = 'every_lunar_year_repeat', //农历每年
  CUSTOM_REPEAT = 'custom_repeat', //自定义
  REPEATING_SCHEDULE_EXPAND_COLLAPSE = 'repeating_schedule_expand_collapse', //重复日程展开收起
  EFFECTIVE_DATE = 'effective_date', //有效日期
  SAME_DAY_OF_EVERY_MONTH = 'same_day_of_every_month', //在每个月的同一天
  SPECIFIC_DATES = 'specific_dates', //特定日期
  ALL_THE_TIME = 'all_the_time', //一直
  UP_TO_LABEL = 'up_to_label', //截止到
  LIMITED_TIMES = 'limited_times', //限定次数

  // 账户详情
  ACCOUNT_NAME = 'account_name', // 新建账户 - 账户名称
  CREATE_AN_ACCOUNT = 'create_an_account', //新建日历帐户
  EDIT_ACCOUNT = 'edit_account', //编辑日历帐户
  ACCOUNT_DETAIL_SHARE_TOP = 'account_detail_share_top', //账户右上角PC分享
  ACCOUNT_DETAIL_SHARE_BUTTON = 'account_detail_share_button', //账户下发分享phone
  EXPAND_AND_COLLAPSE_COLOR = 'expand_and_collapse_color', //展开和收起颜色
  SELECT_COLOR = 'select_color', //选择颜色
  SHARE_MEMBER = 'share_member', //共享成员
  ADD_SHARE_MEMBER = 'add_share_member', //添加共享成员

  // 日程搜索
  AGENDA_SEARCH_INPUT = '__SearchField__flex_search_agenda_search_input', // 系统搜索组件输入框固定ID
  AGENDA_SEARCH_BACK = 'agenda_search_back', // 日程搜索框左边退出按钮
  AGENDA_SEARCH_DELETE = 'agenda_search_delete', // 日程搜索框右边清空搜索内容按钮
  SEARCH_AGENDA_LIST = 'search_agenda_list', // 日程搜索列表
  TIME_ZONE_SEARCH_INPUT = 'time_zone_search_input', // 时区列表搜索框

  /* 公用 */
  NONE = 'none', //无
  CANCEL = 'cancel', //取消
  CONFIRMS = 'confirms', //确认
  SHARES = 'shares', //分享
  DELETE = 'delete', //删除
  NAME = 'name', //名称
  COLOR = 'color', //颜色
  BACK_MAIN = 'backMain', //返回
  AGENDA_TITLE = 'agenda_title', //标题
  AGENDA_LOCATION = 'agenda_location', //地点
  AGENDA_REMARK = 'agenda_remark', //说明
  MULTI_SELECT = 'multi_select', //多选
  NAV_BACK_BUTTON = '__NavdestinationField__BackButton__Back__', //导航栏返回

  /* 月份 */
  JANUARY = 'January', //1月
  FEBRUARY = 'February', //2月
  MARCH = 'March', //3月
  APRIL = 'April', //4月
  MAY = 'May', //5月
  JUNE = 'June', //6月
  JULY = 'July', //7月
  AUGUST = 'August', //8月
  SEPTEMBER = 'September', //9月
  OCTOBER = 'October', //10月
  NOVEMBER = 'November', //11月
  DECEMBER = 'December', //12月

  /* 星期 */
  LOCAL_DEFAULT = 'local_default', //默认星期
  SUNDAY = 'Sunday', //星期日
  MONDAY = 'Monday', //星期一
  TUESDAY = 'Tuesday', //星期二
  WEDNESDAY = 'Wednesday', //星期三
  THURSDAY = 'Thursday', //星期四
  FRIDAY = 'Friday', //星期五
  SATURDAY = 'Saturday', //星期六

  /* 历法 */
  CHINESE_CALENDAR = 'chinese_calendar', //中国农历
  JAPANESE_CALENDAR = 'japanese_calendar', //和历
  PERSIAN_CALENDAR = 'persian_calendar', //波斯历
  HEBREW_CALENDAR = 'hebrew_calendar', //希伯来历
  ISLAMIC_CALENDAR = 'islamic_calendar', //伊斯兰希吉来日历
  BUDDHIST_CALENDAR = 'buddhist_calendar', //佛历
  INDIAN_NATIONAL_CALENDAR = 'indian_national_calendar', //印度国定历

  /* 提醒时间 */
  NO_REMINDER = 'no_reminder', //无提醒
  AT_TIME_OF_EVENT = 'at_time_of_event', //准时
  FIVE_MINUTES_BEFORE = 'five_minutes_before', //5分钟前
  TEN_MINUTES_BEFORE = 'ten_minutes_before', //10分钟前
  FIFTEEN_MINUTES_BEFORE = 'fifteen_minutes_before', //15分钟前
  THIRTY_MINUTES_BEFORE = 'thirty_minutes_before', //30分钟前
  AN_HOUR_BEFORE = 'an_hour_before', //1小时前
  TWO_HOURS_BEFORE = 'two_hours_before', //2小时前
  ONE_DAY_BEFORE = 'one_day_before', //1天前
  TWO_DAYS_BEFORE = 'two_days_before', //2天前
  ONE_WEEK_BEFORE = 'one_week_before', //1周前

  /* 新建日程 */
  CREATE_AGENDA = 'create_agenda', //新建日程框
  DEFAULT_AGENDA_LIST = 'default_agenda_list', //默认日程填写信息的list
  ANNIVERSARY_AGENDA = 'anniversary_agenda', //纪念日填写信息的list

  AGENDA_BASIC_INFO = 'agenda_basic_info', // 新建日程/纪念日/倒数日下 的日程基本信息栏
  TAB_CONTROLLER = 'tab_controller', //新建日程/倒数日 下的日程提醒信息栏
  ACCOUNT_INFO = 'account_info', //新建日程/倒数日 下的日程账户栏
  SHARE_LIST = 'share_list', //新建日程下 的分享栏
  AGENDA_OTHER_INFO = 'agenda_other_info', //新建日程/纪念日/倒数日 下的说明栏

  AGENDA_MUTI_SELECT_BTN = 'agenda_muti_select_btn',
  RADIO_LIST_PRIVATE = 'RadioList_Private',

  EMPTY_CONTAINER = 'empty_container', // 空内容

  ADD_AGENDA_ATTACHMENT = 'add_agenda_attachment', // 新建日程-添加附件
  ADD_AGENDA_ATTACHMENT_ITEM = 'add_agenda_attachment_item', // 新建日程-添加附件-附件item
  ATTACHMENT_MEMBER = 'attachment_member', //附件
  ATTACHMENT_LIST = 'attachment_list', //新建日程下的附件栏

  IMPORT_PAGE_CONTAINER = 'import_page_container', // 分享导入页
}
