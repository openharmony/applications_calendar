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
 * 上报统计事件打点
 * remind 打点事件名长度不能超过32
 */
export const statisticEvents = {
  openClickDeskIcon: 'OPEN_CLICK_DESK_ICON', // 打开日历-点击桌面图标
  mainPageSwitchTab: 'MAIN_PAGE_SWITCH_TAB', // 进入日历首页-切换TAB
  yearClickDate: 'YEAR_CLICK_DATE', // 进入日历-年视图点击日期
  monthClickDate: 'MONTH_CLICK_DATE', // 进入日历-月视图点击日期
  weekClickDate: 'WEEK_CLICK_DATE', // 进入日历-周视图点击日期
  dayClickDate: 'DAY_CLICK_DATE', // 进入日历-日视图点击日期
  backToToday: 'BACK_TO_TODAY', // 点击回到今天
  yearGoToCreateAgenda: 'YEAR_GO_TO_CREATE_AGENDA', // 年视图跳转到创建日程
  monthGoToCreateAgenda: 'MONTH_GO_TO_CREATE_AGENDA', // 月视图跳转到创建日程
  dayGoToCreateAgenda: 'DAY_GO_TO_CREATE_AGENDA', // 日视图跳转到创建日程
  weekGoToCreateAgenda: 'WEEK_GO_TO_CREATE_AGENDA', // 周视图跳转到创建日程
  agendaFaGoToCreateAgenda: 'AGENDA_FA_GO_TO_CREATE_AGENDA', // 日程卡片跳转到创建日程
  importantFaGoToCreateAgenda: 'IMPORTANT_FA_GO_TO_CREATE_AGENDA', // 重要日卡片跳转到创建日程
  monthCardViewAgendaDetail: 'MONTH_CARD_VIEW_AGENDA_DETAIL', // 月视图卡片查看日程详情
  weekClickAgenda: 'WEEK_CLICK_AGENDA', // 周视图-点击日程
  weekClickPopupNone: 'WEEK_CLICK_POPUP_NONE', // 周视图-点击查看日程-点击空白气泡消失POPUP_DISAPPEAR
  weekPopupViewAgendaDetail: 'WEEK_POPUP_VIEW_AGENDA_DETAIL', // 周视图点击日程泡泡弹窗查看日程详情
  dayViewAgendaDetail: 'DAY_VIEW_AGENDA_DETAIL', // 日视图点击日程查看日程详情
  agendaClickAgenda: 'AGENDA_CLICK_AGENDA', // 日程视图-点击某条日程查看详情
  agendaClickAgendaShare: 'AGENDA_CLICK_AGENDA_SHARE', // 日程视图-点击某条日程查看详情-分享
  agendaPressGoToMulti: 'AGENDA_PRESS_GO_TO_MULTI', // 日程视图-长按日程进入多选界面
  agendaPressSelectAll: 'AGENDA_PRESS_SELECT_ALL', // 长按日程进入删除或者选择状态-全选/取消全选
  agendaPressClickItem: 'AGENDA_PRESS_CLICK_ITEM', // 长按日程进入删除或者选择状态-点选
  agendaPressClickDelete: 'AGENDA_PRESS_CLICK_DELETE', // 长按日程进入删除或者选择状态-点击删除
  agendaFaViewAgendaDetail: 'AGENDA_FA_VIEW_AGENDA_DETAIL', // 点击日程卡片查看日程详情
  importantFaViewAgendaDetail: 'IMPORTANT_FA_VIEW_AGENDA_DETAIL', // 点击重要日卡片查看日程详情
  searchPressGoToMulti: 'SEARCH_PRESS_GO_TO_MULTI', // 搜索页长按跳转到多选界面
  agendaDetailGoToEditAgenda: 'AGENDA_DETAIL_GO_TO_EDIT_AGENDA', // 日程详情跳转到编辑日程
  createAgenda: 'CREATE_AGENDA', // 新建日程
  editAgenda: 'EDIT_AGENDA', // 编辑日程
  createAgendaSavePopup: 'CREATE_AGENDA_SAVE_POPUP', // 日程管理-新建日程-退出新建-弹窗-保存/取消
  editAgendaSavePopup: 'EDIT_AGENDA_SAVE_POPUP', // 日程管理-编辑日程-退出编辑-弹窗-保存/取消
  deleteAgendaSavePopup: 'DELETE_AGENDA_SAVE_POPUP', // 日程管理-删除日程-弹窗-保存/取消
  createAgendaModifyRemind: 'CREATE_AGENDA_MODIFY_REMIND', // 新建日程里操作提醒
  editAgendaModifyRemind: 'EDIT_AGENDA_MODIFY_REMIND', // 编辑日程里操作提醒
  viewAgendaModifyRemind: 'VIEW_AGENDA_MODIFY_REMIND', // 查看日程里操作提醒
  search: 'SEARCH', // 点击搜索图标
  searchClickAgenda: 'SEARCH_CLICK_AGENDA', // 输入搜索-点击搜索出的日程
  searchPressPopupDeleteAgenda: 'SEARCH_PRESS_POPUP_DELETE_AGENDA', // 搜索长按日程删除日程
  clickMore: 'CLICK_MORE', // 点击右上角更多图标
  createAccountClickColor: 'CREATE_ACCOUNT_CLICK_COLOR', // 日历账户管理-新建日历账户-点击选择颜色
  editAccountClickColor: 'EDIT_ACCOUNT_CLICK_COLOR', // 日历账户管理-编辑日历账户-点击选择颜色
  createAccount: 'CREATE_ACCOUNT', // 日历账户管理-新建账户
  editAccount: 'EDIT_ACCOUNT', // 日历账户管理-编辑账户
  createAccountSavePopup: 'CREATE_ACCOUNT_SAVE_POPUP', // 日历账户管理-新建日历账户-退出新建-弹窗-保存/取消
  editAccountSavePopup: 'EDIT_ACCOUNT_SAVE_POPUP', // 日历账户管理-编辑日历账户-退出编辑-弹窗-保存/取消
  deleteAccountSavePopup: 'DELETE_ACCOUNT_SAVE_POPUP', // 日历账户管理-删除日历账户-弹窗-保存/取消
  goToSettings: 'GO_TO_SETTINGS', // 设置-进入设置
  goToFeedBack: 'GO_TO_FEEDBACK', // 帮助与客服
  networkingPopup: 'NETWORKING_POPUP', // 日历联网更新弹框
  mainPageReportRecessState: 'MAIN_PAGE_REPORT_RECESS_STATE', // 进入主界面时上报班休显示状态
  mainPageSwitchView: 'MAIN_PAGE_SWITCH_VIEW', // 进入日历-左右滑动切换视图
  agendaSwitchTab: 'AGENDA_SWITCH_TAB', // 新建日程界面-切换TAB
  messageCenterSwitchTab: 'AGENDA_SWITCH_TAB', // 消息中心-切换TAB
  createDayFormDescriptionFa: 'CREATE_DAY_FORM_DESCRIPTION_FA', // 新建日程卡片
  createImportantFa: 'CREATE_IMPORTANT_FA', // 新建重要日卡片
  deleteDayFormDescriptionFa: 'DELETE_DAY_FORM_DESCRIPTION_FA', // 删除日程卡片
  deleteImportantFa: 'DELETE_IMPORTANT_FA', // 删除重要日卡片
  editImportantFa: 'EDIT_IMPORTANT_FA', // 编辑重要日卡片
  exitCalendar: 'EXIT_CALENDAR', // 退出日历
  agendaListServiceMeeting: 'AGENDA_LIST_SERVICE_MEETING', // 在日程列表点击一键入会按钮
  agendaDetailServiceMeeting: 'AGENDA_DETAIL_SERVICE_MEETING', // 在日程详情点击一键入会按钮
  subscriptionCardExposure: 'SUBSCRIPTION_CARD_EXPOSURE', //月视图-订阅服务曝光
  periodicReportAgenda: 'PERIODIC_REPORT_AGENDA', //周期上报日程数量
  createScheduleCard: 'CREATE_SCHEDULE_CARD', //新增课程表卡片
  deleteScheduleCard: 'DELETE_SCHEDULE_CARD', //删除课程表卡片
  parseScheduleCostTime: 'PARSE_SCHEDULE_COST_TIME', //日历-课表导入-开始相册导入-解析耗时
  allScheduleCount: 'ALL_SCHEDULE_COUNT', //课表总数
  attachmentInfo: 'ATTACHMENT_INFO', // 日历-附件-添加的附件数量和单个附件大小
  importAgendaSuccess: 'IMPORT_AGENDA_SUCCESS', //导入日程成功
  importAgendaFail: 'IMPORT_AGENDA_FAIL', //导入日程失败
};

/**
 * 上报行为事件打点
 */
export const behaviorEvents = {
  accountClickGoToCreate: 'ACCOUNT_CLICK_GO_TO_CREATE', // 日历账户管理-点击添加账户
  clickLeftDrawer: 'CLICK_LEFT_DRAWER', // 点击左侧抽屉菜单
  settingsSelectCalendar: 'SETTINGS_SELECT_CALENDAR', // 设置-其他历法-选择某一历法
  settingsHolidaySwitch: 'SETTINGS_HOLIDAY_SWITCH', // 设置-显示节假班休信息-开-关
  settingsWeekSwitch: 'SETTINGS_WEEK_SWITCH', // 设置-显示周数-开-关
  settingsWeekSelectStartTime: 'SETTINGS_WEEK_SELECT_START_TIME', // 设置-一周开始日-选择星期
  settingsWeekSelectWeekend: 'SETTINGS_WEEK_SELECT_WEEKEND', // 设置-周末-选择星期
  settingsRemindSelect: 'SETTINGS_REMIND_SELECT', // 设置-默认提醒时间
  oneclickServiceGoAppAgenda: 'ONECLICK_SERVICE_GO_APP_AGENDA', // 日历-用户点击一键服务按钮成功跳转到对应外部应用_日程时间前/中/后
  triggerShareAgendaOrAccount: 'TRIGGER_SHARE_AGENDA_OR_ACCOUNT', // 日历-用户触发分享日程时是账户分析/不是账户分析
  receiveShareAgendaOrAccount: 'RECEIVE_SHARE_AGENDA_OR_ACCOUNT', // 日历-用户接收分享日程时是账户分析/不是账户分析
  importantFaClickSelectDate: 'IMPORTANT_FA_CLICK_SELECT_DATE', // 日历-点击桌面重要日服务卡片-编辑-点选择日期
  monthClickImportantCard: 'MONTH_CLICK_IMPORTANT_CARD', // 日历-月视图-点击重要日卡片
  agendaClickAgendaDetail: 'AGENDA_CLICK_AGENDA_DETAIL', // 日程视图-点击某条日程查看详情
  agendaViewCheckAfterAgent: 'AGENDA_VIEW_CHECK_AFTER_AGENT', // 日历-日程视图-查看之后的日程
  agendaViewCheckBeforeAgent: 'AGENDA_VIEW_CHECK_BEFORE_AGENT', // 日历-日程视图-查看之前的日程
  clickCalendarCloudSync: 'CLICK_CALENDAR_CLOUD_SYNC', // 日历-云空间-日历云同步暂不开启/立即开启
  landscapeScreenClickDeskIcon: 'LANDSCAPE_SCREEN_CLICK_DESK_ICON', // 日历-横屏-点击桌面日历图标
  calendarReminderPopup: 'CALENDAR_REMINDER_POPUP', // 日历-日历提醒弹窗
  selectedDayAgendaCounts: 'SELECTED_DAY_AGENDA_COUNTS', // 日历-统计用户所选天的日程数
  agendaFaGoToMonth: 'AGENDA_FA_GO_TO_MONTH', // 日历-日程卡片点击跳转月视图
  notificationGoToAgendaDetail: 'NOTIFICATION_GO_TO_AGENDA_DETAIL', // 通知栏进入日历日程详情
  createAgendaSelectAccount: 'CREATE_AGENDA_SELECT_ACCOUNT', // 新建日程-选择账户
  createAccountClickNotice: 'CREATE_ACCOUNT_CLICK_NOTICE', // 新建日历账户-通知
  accountGoToMyCalendar: 'ACCOUNT_GO_TO_MY_CALENDAR', // 日历账户管理-我的日历
  settingSecurityPrivacy: 'SETTING_SECURITY_PRIVACY', // 设置-安全与隐私
  settingFeedBack: 'SETTING_FEED_BACK', // 日历设置-问题与建议
  agendaDetailShare: 'AGENDA_DETAIL_SHARE', // 重要日服务卡片-分享
  editAccountSwitch: 'EDIT_ACCOUNT_SWITCH', // 账户开关状态变更
  createAgendaCancelRemind: 'CREATE_AGENDA_CANCEL_REMIND', // 日历-新建日程-添加提醒-取消
  accountGetCounts: 'ACCOUNT_GET_COUNTS', // 日历-点击左侧侧边栏-日历账户管理-日历账户个数
  clickAllAgenda: 'CLICK_ALL_AGENDA', // 日历-日历基础操作-点击主界面右上角按钮-点击查看全部日程
  agendaDeleteType: 'AGENDA_DELETE_TYPE', // 删除日程（0：仅限次日程，1：此日程和将来的日程，2：所有日程）
  agendaSelectLunarDate: 'AGENDA_SELECT_LUNAR_DATE', // 点击日程开始/结束时间-显示农历，
  receiveShareAgenda: 'RECEIVE_SHARE_AGENDA', // 消息中心-接收共享日程
  createAgendaShare: 'CREATE_AGENDA_SHARE', // 新建日程-添加共享成员
  agendaImportantAlert: 'AGENDA_IMPORTANT_ALERT', // 日程的重要提醒开关
  helpAndSupport: 'HELP_AND_SUPPORT', // 日历设置-帮助与客服
  filingInformation: 'FILING_INFORMATION', // 日历设置-备案号
  keyboardEvents: 'KEYBOARD_EVENTS', // PC键盘操作
  darkMode: 'DARK_MODE', // 深色模式,
  cardRefresh: 'CARD_REFRESH', // 卡片刷新
  clickCardGoToMonth: 'CLICK_CARD_GO_TO_MONTH', // 点击卡片进入月视图
  monthCardSwitchMonths: 'MONTH_CARD_SWITCH_MONTHS', // 点击月视图卡片切换月份
  changeMonthMode: 'CHANGE_MONTH_MODE', // 切换月视图状态
  changeGanttScale: 'CHANGE_GANTT_SCALE', // 改变甘特图视图比例
  ganttCreateAgenda: 'GANTT_CREATE_AGENDA', // 甘特图新建日程
  moveGanttBlock: 'MOVE_GANTT_BLOCK', // 拖动甘特图日程块
  changeWindowMode: 'CHANGE_WINDOW_MODE', // 切换窗口状态
  longPressToPreview: 'LONG_PRESS_TO_PREVIEW', // 长按预览日程
  previewMenuType: 'PREVIEW_MENU_TYPE', // 长按预览点击菜单选项
  agendaDragOut: 'AGENDA_DRAG_OUT', // 日程拖出
  agendaDatePicker: 'AGENDA_DATE_PICKER', //新建/编辑日程-开始/结束/当个时间弹框-确定/取消
  editRepeatedAgenda: 'EDIT_REPEATED_AGENDA',
  editAgenda: 'EDIT_AGENDA',
  importAgenda: 'IMPORT_AGENDA', // 日历-侧边栏-导入日程
  checkAccountAgendas: 'CHECK_ACCOUNT_AGENDAS', // 日历-账户-点击左上角侧边栏按钮-日历账户-查看账户内所有日程
  refuseShareAgendaOrAccount: 'REFUSE_SHARE_AGENDA_OR_ACCOUNT', // 日历-用户拒绝分享日程时是账户分析/不是账户分析
  deleteAgendaShare: 'DELETE_AGENDA_SHARE', // 新建日程-删除共享成员
  messageCenterKnown: 'MESSAGE_CENTER_KNOWN', // 消息中心-点击
  jumpToSomeday: 'JUMP_TO_SOMEDAY', // 跳转到指定日期
  agendaDetailAttendees: 'AGENDA_DETAIL_ATTENDEES', // 日程详情-查看参与人
  agendaMultiShare: 'AGENDA_MULTI_SHARE', // 日历-日程-多选-分享
  agendaMultiDelete: 'AGENDA_MULTI_DELETE', // 日历-日程-多选-删除,
  agendaDrop: 'AGENDA_DROP', // 日历-日程-统一拖拽-拖入
  SettingStatus: 'SETTING_STATUS', // 统计各个设置项的状态点位,
  subscriptionToDetail: 'SUBSCRIPTION_TO_DETAIL', //侧边栏-点击具体的订阅服务-对应的服务详情
  subscriptionDisplay: 'SUBSCRIPTION_DISPLAY', //侧边栏-点击具体的订阅服务的选择框
  subscriptionManage: 'SUBSCRIPTION_MANAGE', //侧边栏-订阅服务-管理
  unSubscribeAction: 'UNSUBSCRIBE_ACTION', //月视图-长按订阅服务卡片-取消订阅-确认/取消
  agendaImportantAlertButton: 'AGENDA_IMPORTANT_ALERT_BUTTON', // 新建日程-重要提醒-开关
  importAgendaFromFile: 'IMPORT_AGENDA_FROM_FILE', //日历-侧边栏-导入日程-从文件中导入

  // 附件点位
  attachmentAdd: 'ATTACHMENT_ADD', // 日历-附件-添加
  attachmentDelete: 'ATTACHMENT_DELETE', // 日历-附件-删除,

  // 同步待办点位
  taskTodoCompleteState: 'TASK_TODO_COMPLETE_STATE', // 日历-待办-完成状态
  taskTodoJumpToNotepadDetail: 'TASK_TODO_JUMP_TO_NOTEPAD_DETAIL', // 日历-待办-跳转至备忘录详情,

  // 课程表点位
  sidebarAddSchedule: 'SIDEBAR_ADD_SCHEDULE', //日历-侧边栏-添加课程表
  scheduleSettingAddSchedule: 'SCHEDULE_SETTING_ADD_SCHEDULE', //日历-课表视图-更多选项-课表设置-新建课表
  deleteSchedule: 'DELETE_SCHEDULE', //日历-课表视图-更多选项-课表设置-左滑删除课表
  sidebarJumpSchedule: 'SIDEBAR_JUMP_SCHEDULE', //日历-侧边栏-点击课表名称-跳转到课表页面
  lunarViewCardToSchedule: 'LUNAR_VIEW_CARD_TO_SCHEDULE', //日历-月视图-点击课表卡片-跳转到课表页面
  selectScheduleAndWeek: 'SELECT_SCHEDULE_AND_WEEK', //日历-课表视图-点击课表和周数选择-课表周数选择弹窗
  scheduleSettingToEdit: 'SCHEDULE_SETTING_TO_EDIT', //日历-课表视图-更多选项-课表设置-点击对应课表课表进入设置详情
  timelineToScheduleEdit: 'TIMELINE_TO_SCHEDULE_EDIT', //日历-课表视图-点击左侧时间轴-课表设置
  plusSignAddCourse: 'PLUS_SIGN_ADD_COURSE', //日历-课表视图-右上角加号-添加课程
  deleteCourseConfirm: 'DELETE_COURSE_CONFIRM', //日历-课表视图-点击课程-课程预览弹窗-删除-确认/取消
  coursePreviewClose: 'COURSE_PREVIEW_CLOSE', //日历-课表视图-点击课程-课程预览弹窗-关闭按钮
  coursePreviewToEdit: 'COURSE_PREVIEW_TO_EDIT', //日历-课表视图-点击课程-课程预览弹窗-编辑按钮进入详情
  conflictCourseDisplay: 'CONFLICT_COURSE_DISPLAY', //日历-课表视图-点击课程-课程预览弹窗-冲突课程切换
  courseRemindingOpen: 'COURSE_REMINDING_OPEN', //日历-课程视图-更多选项-课程提醒-课前提醒-开启/关闭
  courseRemindingMode: 'COURSE_REMINDING_MODE', //日历-课程视图-更多选项-课程提醒-提醒方式-每节课提醒/近第一节课提醒
  courseRemindingTime: 'COURSE_REMINDING_TIME', //日历-课程视图-更多选项-课程提醒-提醒时间-5/10/15/20/25/30/35/40/45/50/55/60
  nextDayCourseRemindingOpen: 'NEXT_DAY_COURSE_REMINDING_OPEN', //日历-课程视图-更多选项-课程提醒-次日提醒-开启/关闭
  nextDayCourseRemindingMode: 'NEXT_DAY_COURSE_REMINDING_MODE', //日历-课程视图-更多选项-课程提醒-次日提醒事件-前一天/当天
  courseAddOtherTime: 'COURSE_ADD_OTHER_TIME', //日历-课程视图-新建/编辑课程-点击添加上课时间
  scheduleWeekendDisplay: 'SCHEDULE_WEEKEND_DISPLAY', //日历-课表视图-新建/编辑课表-周末显示-开启/关闭
  tokenizationAgendaPreview: 'TOKENIZATION_AGENDA_PREVIEW', // 长按分词预览行为打点
  clickPreviewJumpToCalendar: 'CLICK_PREVIEW_JUMP_TO_CALENDAR', // 日历预览，点击预览窗格跳转到日历

  /** 穿戴设备点位 开始标志位 **/
  //  一期点位
  backToTodayMonth: 'BACK_TO_TODAY_MONTH', //日历-月视图-双击顶部回到当月
  monthClickToWeek: 'MONTH_CLICK_TO_WEEK', //日历-月视图-点击周进入周视图
  swipeMonth: 'SWIPE_MONTH', //日历-月视图-左右滑动切换月份
  changeSelectedDay: 'CHANGE_SELECTED_DAY', //日历-周视图-点击切换选中天
  swipeWeek: 'SWIPE_WEEK', //日历-周视图-左右滑动切换周
  clickCardToAgendaList: 'CLICK_CARD_TO_AGENDALIST', //日历-日历基础操作-点击日历卡片顶部跳转日程列表
  clickCardToAgendaDetail: 'CLICK_CARD_TO_AGENDADETAIL', //日历-日历基础操作-点击日历卡片下部跳转日程详情

//  二期点位
  backToTodayWeek: 'BACK_TO_TODAY_WEEK', // 日历-周视图-双击顶部回到当周
  backToTodayWear: 'BACK_TO_TODAY_WEAR', // 日历-列表-双击顶部回到当天
  clickListItemToAgendaDetail: 'CLICK_LIST_ITEM_TO_AGENDADETAIL', // 日历-日程列表-点击列表元素跳转日程详情
  clickWeekListItemToAgendaDetail: 'CLICK_WEEK_LIST_ITEM_TO_AGENDADETAIL', // 日历-周视图-点击下发列表元素跳转日程详情
  tabToWeek:'TAB_TO_WEEK', // 日历-切换视图-点击周视图跳转周视图
  tabToMonth:'TAB_TO_MONTH', // 日历-切换视图-点击月视图跳转月视图
  tabToList:'TAB_TO_LIST', // 日历-切换视图-点击日程列表跳转日程列表
  onBackFromMonth:'ON_BACK_FROM_MONTH', //日历-月视图-侧滑退出应用
  onBackFromListToMonth:'ON_BACK_FROM_LIST_TO_MONTH', // 日历-列表-侧滑返回月视图
  onBackFromWeekToMonth:'ON_BACK_FROM_WEEK_TO_MONTH', // 日历-周视图-侧滑返回月视图
  clickCrownExit:'CLICK_CROWN_EXIT', // 日历-单击表冠退出应用

  cardRetryAddTemplate:'CARD_RETRY_ADD_TEMPLATE', // 日历-负一屏卡片-重新挂载数据代理
  /** 穿戴设备点位 结束标志位 **/
};

/**
 * 上报故障事件打点
 */
export const faultEvents = {
  holidayDownload: 'HOLIDAY_DOWNLOAD', // 下载节假日结果上报
  holidayParseFail: 'HOLIDAY_PARSE_FAIL', // 解析节假日异常上报
  holidaySaveFail: 'HOLIDAY_SAVE_FAIL', // 读取解析后节假日到内存失败上报
  sqlInitFail: 'SQL_INIT_FAIL', // 初始化数据库失败
  sqlQueryFail: 'SQL_QUERY_FAIL', // 查询数据库记录失败
  sqlInsertFail: 'SQL_INSERT_FAIL', // 插入数据库记录失败
  sqlUpdateFail: 'SQL_UPDATE_FAIL', // 修改数据库记录失败
  sqlDeleteFail: 'SQL_DELETE_FAIL', // 删除数据库记录失败
  cardAddTemplateFail: 'CARD_ADD_TEMPLATE_FAIL', // 卡片addTemplate记录失败
  emptyCardAddForm: 'EMPTY_CARD_ADD_FORM', // 异常分支之加卡片
  emptyCardUpdateForm: 'EMPTY_CARD_UPDATE_FORM', // 异常分支之刷新卡片
  emptyCardFormEvent: 'EMPTY_CARD_FORM_EVENT', // 异常分支之处理事件
  setCardInfoToSpFail: 'SET_CARD_INFO_TO_SP', // 向sp文件中保存卡片信息失败
  parseScheduleFailMessage: 'PARSE_SCHEDULE_FAIL_MESSAGE', //解析课表失败错误信息
  insertCourseToDBFail: 'INSERT_COURSE_DB_FAIL', //课表插入数据库失败
  accountStatusAcquisitionFail: 'ACCOUNT_STATUS_ACQUISITION_FAIL', //获取华为账号信息异常
  removeDirtyCardInfo: 'REMOVE_DIRTY_CARD_INFO' //清除卡片脏数据
};



