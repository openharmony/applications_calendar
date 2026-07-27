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
 * 应用内部事件编号
 *
 * @since 2022-09-20
 */

export enum CommonInnerEvent {
  // 日历应用domain ID
  CALENDAR_DOMAIN_BASE_ID = 0xD00B700,

  // 创建日程视图事件
  EVENT_CREATE_AGENDA,

  // 点击新建日程页面的左上角叉号关闭
  EVENT_DISMISS_CREATE_AGENDA,

  // 冷启动月视图日程数据查询完成事件
  EVENT_MONTH_VIEW_AGENDA_DATA_QUERY_COMPLETED,

  // 日程详情更新事件
  EVENT_UPDATE_AGENDA_DETAIL,
  EVENT_DELETE_AGENDA_DETAIL,
  EVENT_UPDATE_AGENDA_LIST,
  EVENT_CLOSE_AGENDA_DETAIL_COVER,
  // 全量刷新全部日程列表页
  EVENT_FULL_UPDATE_AGENDA_LIST_PAGE,
  // 重置日程块焦点参数
  RESET_MONTH_AGENDA_BLOCK_FOCUS_PARAM,

  // 卡片相关事件
  EVENT_FORM,

  // 卡片日程详情相关事件
  EVENT_FORM_DETAIL,

  // 卡片点击进入月视图
  EVENT_FROM_CARD_TO_MONTH,

  // 通用各页面、弹窗退出
  EVENT_COMMON_CLOSE_PAGE_DIALOG,

  // 新建日程后将eventId传给重要日卡片
  EVENT_FORM_GET_AGENDA_ID,

  // 账号相关事件
  EVENT_ACCOUNT_CHANGE,
  EVENT_ACCOUNT_DETAIL_PAGE_OPEN,
  EVENT_ACCOUNT_DEFAULT_PAGE_OPEN,
  EVENT_ADD_SCHEDULE_PAGE_OPEN,

  // 周视图相关事件
  WEEK_VIEW,
  WEEK_SCALE_CHANGE, // 甘特图缩放

  // 用户授权相关事件
  PERMISSION,

  PERMISSION_DATA,

  PERMISSION_NOTIFICATION,

  PERMISSION_NETWORK,

  VIEW_PERMISSION_DESC_BACK,

  // 切换主界面TAB
  SWITCH_MAIN_PAGE_TAB,
  MONTH_VIEW_SELECT_DAY,
  BACK_TO_TODAY,
  CLICK_SETTING_PAGE,

  // 拉起新建日程页面
  CLICK_MAIN_PAGE_CREATE_AGENDA,
  CLICK_AGENDA_LIST_CREATE_AGENDA,
  CLICK_GANTT_BLOCK_CREATE_AGENDA,
  CLICK_AGENDA_DETAIL_CREATE_AGENDA,

  // 滑动事件
  SWIPE_MAIN_PAGE, // { 0 previous, 1 next}

  // 系统事件
  SYSTEM_EVENTS,
  SYSTEM_TIME_TICK, // 整分钟触发一次
  SYSTEM_DATE_CHANGED, // 日期
  SYSTEM_TIME_CHANGED, // 时间变化
  SYSTEM_HOUR_CYCLE_CHANGED, // 小时进制变化
  SYSTEM_TIMEZONE_CHANGED, // 时区变更
  SYSTEM_LOCALE_CHANGED, // 系统locale变更
  SYSTEM_LANGUAGE_CHANGED, // 语言变更
  SYSTEM_DATA_CHANGED, // 数据改变
  SYSTEM_HWID_LOGIN, // 账号登录
  SYSTEM_HWID_LOGOUT, //账号退出

  // 数据事件
  DATA_EVENTS,
  INNER_DATE_CHANGED, // 从DateManager发出的日期变更事件\
  DISPLAY_DATE_CHANGE, // 统一displayDate数据刷新事件
  JUMP_TO_SOMEDAY,
  DELETE_AGENDA, // 删除日程事件
  COPY_AGENDA, // 复制日程事件
  RECURRENCE_SET, // 自定义重复设置
  EVENT_MAIN_PAGE_UPDATE_DATA, // 更新主界面数据

  // 月视图相关事件
  MONTH_VIEW,
  MONTH_VIEW_LAYOUT_CHANGE, // 月视图的布局发生变化
  SINGLE_MONTH_VIEW_LAYOUT_CHANGE, // 单月视图的布局发生变化
  MONTH_VIEW_DELETE_REPEATED,
  FRESH_MONTH_AGENDA_BLOCK_AREA,

  // SVC格式日程分享
  VCS_EVENTS,
  VCS_ACCOUNT_CHANGE, // VCS帐户改变
  VCS_SHOW_PAGE, // 显示半模态主页
  VCS_SAVE_DATA, // 保存数据
  VCS_EXPORT_SHOW_PROGRESS_DIALOG,
  VCS_EXPORT_CLOSE_PROGRESS_DIALOG,
  VCS_EXPORT_CANCEL_TASK,
  VCS_EXPORT_UPDATE_PROGRESS,
  EVENT_IMPORT_AGENDA_PAGE_OPEN,

  VCS_SHARE_ACCOUNT, // vcs分享导出账户

  // 按键事件
  BUTTON_KEY_ENTER, // 回车键
  BUTTON_KEY_DEL, // 删除键
  BUTTON_KEY_COPY, // 复制键
  BUTTON_KEY_PASTE, // 粘贴键
  BUTTON_KEY_UP_OR_LEFT, // 方向键 上或左
  BUTTON_KEY_DOWN_OR_RIGHT, // 方向键 下或右
  BUTTON_KEY_SWIPER_UP, // swiper上翻页
  BUTTON_KEY_SWIPER_DOWN, // swiper下翻页

  // 共享相关事件
  EVENT_SHARE_ACCEPT,
  EVENT_SHARE_REJECT,
  EVENT_SHARE_DELETE,
  EVENT_SHARE_MEMBER_LIST_UPDATE, // 共享联系人刷新
  EVENT_DELETE_SHARE_MEMBER,
  EVENT_ON_CONTRACT_SELECTED, // 共享联系人被选择
  EVENT_ON_UNREAD_MESSAGE_CHANGE,
  PUSH_MESSAGE_CHANGE,

  EVENT_ON_ACCOUNT_CONTRACT_COUNT_CHANGED, // 账户的共享联系人数量变化
  EVENT_ON_ACCOUNT_EXIT,
  // 导航中转事件id
  NAV_PATH_STACK_JUMP,

  // 设置相关
  SETTINGS_START_OF_WEEK, // 一周开始日
  SETTINGS_WEEKENDS, // 周末
  SETTINGS_IS_RECESS_DATA_LOADED, // 班休数据是否下载完成
  SETTINGS_IS_RECESS_TOGGLE_ON, // 是否展示班休
  SETTINGS_OTHER_CALENDAR, // 其它历法
  SETTINGS_SHOW_WEEK_NUMBER, // 显示周数
  SETTINGS_ABOUT, // 设置-关于
  SETTINGS_NATIONAL_HOLIDAY, //节假日变更
  SETTINGS_HOLIDAY_COUNTRY_LIST, //节假日国家列表变更

  // PC更多场景下弹出PopUp页面
  MORE_PAGE_TO_POPUP, // 点击更多菜单按钮跳转到 全部日程页面、搜索、设置，具体页面在EventData中
  MORE_PAGE_POPUP_CLOSE, // 关闭当前子窗页面的气泡弹窗
  DETAIL_PAGE_POPUP_CLOSE, // 关闭当前日程详情子窗页面的气泡弹窗

  // 同意授权
  AGREE_AUTHORIZED,

  // 窗口最大化恢复
  EVENT_MAXIMIZE_RECOVERY,

  // 多选
  EVENT_UPDATE_MULTI_SELECTED,

  // 数据库事件
  EVENT_DB_EXCEPTION,

  SHARE_AGENDA,

  // 订阅相关
  SUBSCRIPTION_DISPLAY_CHANGED, // 订阅显示变更
  SUBSCRIPTION_STATE_CHANGED, // 订阅状态变更
  SUBSCRIBE_FROM_SUBSCRIPTION_RECOMMEND, // 从推荐订阅swiper点击订阅
  // 单向通知订阅元服务更新
  NOTICE_SUBSCRIPTION_UPDATE,

  // 接续
  APP_CONTINUE,

  // 日程时区
  AGENDA_TIME_ZONE_CHANGED, // 日程时区变化了

  // 锁定时区
  LOCKED_TIME_ZONE_CHANGED, // 锁定时区变化了
  LOCK_TIME_ZONE_SWITCH_CHANGED, // 锁定时区开关变化了

  // 课程表
  SCHEDULE_CHANGED, // 课程表更新
  EVENT_CLOSE_BIND_SHEET_PAGE, // 下滑关闭半模态

  // 周视图点击日期获取日程数据
  WEEK_SELECTED_DATE_GET_AGENDA_LIST,

  //一句话创建触发刷新
  INTELLIGENT_REFRESH,

  //更新班休
  UPDATE_RECESS,

  //更新主题
  THEME_FONT_CHANGE,

  // 下一月
  NEXT_MONTH,

  // 上一月
  PRE_MONTH,

  CLICK_STATUSBAR,

  // 删除日程弹窗删除成功
  DELETE_DIALOG_DELETE_AGENDA_SUCCESS,

  // 月视图常用节假日tip消失
  OPEN_CN_HOLIDAY_TIP_DISAPPEAR,

  // 深色模式变更刷新（绕过 @Watch 不触发问题）
  DARK_MODE_REFRESH,
}


// 用于eventHub广播监听注册的string类型Enum
export enum CommonEventHubCode {
  EVENT_UPDATE_AGENDA_NEW_PAGE = 'eventUpdateAgendaNewPage', // newWant更新日程详情
}