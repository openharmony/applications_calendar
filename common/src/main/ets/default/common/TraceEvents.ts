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
 * 上报trace事件打点
 */
export const traceEvents = {
  mainPageAppear: 'MAIN_PAGE_APPEAR', // 主界面创建
  yearViewAppear: 'YEAR_VIEW_APPEAR', // 年视图创建
  singleYearViewAppear: 'SINGLE_YEAR_VIEW_APPEAR', // 单年创建
  monthViewAppear: 'MONTH_VIEW_APPEAR', // 月视图创建
  monthAgendaListAppear: 'MONTH_AGENDA_LIST_APPEAR', // 月视图日程列表创建
  weekViewAppear: 'WEEK_VIEW_APPEAR', // 周视图创建
  ganttAppear: 'GANTT_APPEAR', // 周、日视图的甘特视图创建
  dayViewAppear: 'DAY_VIEW_APPEAR', // 日视图创建
  agendaListAppear: 'AGENDA_LIST_APPEAR', // 月视图日程列表创建
  mainAbilityCreate: 'MAIN_ABILITY_CREATE', // mainability在create出入口耗时
  mainAbilityWindowStage: 'MAIN_ABILITY_WINDOW_STAGE', // mainability在windowStage出入口耗时
  mainAbilityForeground: 'MAIN_ABILITY_FOREGROUND', // mainability在foreground出入口耗时
  mainAbilityDestroy: 'MAIN_ABILITY_DESTROY', // mainability在Destroy出入口耗时
  cardAbilityCreate: 'CARD_ABILITY_CREATE', // cardAbility在create出入口耗时
  cardAbilityWindowStage: 'CARD_ABILITY_WINDOW_STAGE', // cardAbility在windowStage出入口耗时
  cardAbilityDestroy: 'CARD_ABILITY_DESTROY', // cardAbility在Destroy出入口耗时
  importVcs: 'IMPORT_VCS', // 导入vcs解析
  exportVcs: 'EXPORT_VCS', // 导出组装vcs
  hagDownload: 'HAG_DOWNLOAD', // HAG一键入会下载数据
  cloudManageLogin: 'CLOUD_MANAGE_LOGIN', // 日历云登录耗时
  cloudManageGetAt: 'CLOUD_MANAGE_GET_AT', // 日历云获取办公云AT
  cloudManageBlockUsers: 'CLOUD_MANAGE_BLOCK_USERS', // 日历云屏蔽联系人
  cloudManageDeleteBlockUsers: 'CLOUD_MANAGE_DELETE_BLOCK_USERS', // 日历云删除屏蔽联系人
  cloudManageQueryBlockUsers: 'CLOUD_MANAGE_QUERY_BLOCK_USERS', // 日历云删除屏蔽联系人
  cloudManageModifyMessage: 'CLOUD_MANAGE_MODIFY_MESSAGE', // 日历云修改用户信息
  cloudManageDeleteMessage: 'CLOUD_MANAGE_DELETE_MESSAGE', // 日历云删除消息中心消息
  cloudManageQueryMessage: 'CLOUD_MANAGE_QUERY_MESSAGE', // 日历云查询消息中心消息
  cloudManageAddConfig: 'CLOUD_MANAGE_ADD_CONFIG', // 日历云新增用户配置
  cloudManageQueryConfig: 'CLOUD_MANAGE_QUERY_CONFIG', // 日历云查询用户配置
  cloudManageLogout: 'CLOUD_MANAGE_LOGOUT', // 日历云退出登录
  queryAttendee: 'QUERY_ATTENDEE', // 查询日程与会人
  queryCalendarList: 'QUERY_CALENDAR_LIST', // 查询所有calendar
  queryCalendarById: 'QUERY_CALENDAR_BY_ID', // 根据id查账户
  queryCalendarByCondition: 'QUERY_CALENDAR_BY_CONDITION', // 根据条件查询账户
  insertCalendar: 'INSERT_CALENDAR', // 新建账户
  deleteCalendarById: 'DELETE_CALENDAR_BY_ID', // 根据id删除账户
  updateCalendarById: 'UPDATE_CALENDAR_BY_ID', // 根据id更新账户
  queryInFusionSearch: 'QUERY_IN_FUSION_SEARCH', // 归一化查询
  updateByEventId: 'UPDATE_BY_EVENT_ID', // 根据id更新日程
  updateReminderByReplace: 'UPDATE_REMINDER_BY_REPLACE', // 更新提醒时间
  deleteEventById: 'DELETE_EVENT_BY_ID', // 根据日程id，删除日程
  deleteEvents: 'DELETE_EVENTS', // 批量删除日程
  insertEvent: 'INSERT_EVENT', // 插入日程
  queryEvents: 'QUERY_EVENTS', // 查询所有日程 Events 信息
  queryEventByEventId: 'QUERY_EVENT_BY_EVENT_ID', // 根据 event id查询日程
  queryEventsByAccountId: 'QUERY_EVENTS_BY_ACCOUNT_ID', // 根据 账户id查询日程
  queryEventsByIds: 'QUERY_EVENTS_BY_IDS', // 根据 日程ids查询日程
  queryInstanceGroupedAndGetAccountMap: 'QUERY_INSTANCE_GROUPED_AND_GET_ACCOUNT_MAP', // 查询实例分组且获取账户Map
  insertEvents: 'INSERT_EVENTS', // 批量插入日程
  deleteEventByEventIds: 'DELETE_EVENT_BY_EVENT_IDS', // 根据event id删除日程
  queryCondition: 'QUERY_CONDITION', // 构建查询条件
  insertMemberIdentity: 'INSERT_MEMBER_IDENTITY', // 插入联系人信息
  queryMemberIdentities: 'query_Member_Identities', // 查询联系人信息
  queryMemberIdentityList: 'query_Member_Identity_List', // 查询联系人信息
  queryMessageAgendaRemind: 'QUERY_MESSAGE_AGENDA_REMIND', // 根据消息中心日程id查询日程
  queryAgendaByCondition: 'QUERY_AGENDA_BY_CONDITION', // 查询消息中心日程附表
  queryMessageCalendar: 'QUERY_MESSAGE_CALENDAR', // 查询消息中心账户附表
  insertMessageCenter: 'INSERT_MESSAGE_CENTER', // 消息中心插入数据
  updateMessageCenter: 'UPDATE_MESSAGE_CENTER', // 消息中心更新数据
  deleteMessageCenter: 'DELETE_MESSAGE_CENTER', // 消息中心删除数据
  deleteMessageCenterList: 'DELETE_MESSAGE_CENTER_List', // 消息中心删除数据
  queryMessageCenterPagination: 'QUERY_MESSAGE_CENTER_PAGINATION', // 消息中心分页查询数据
  queryMessageCenter: 'QUERY_MESSAGE_CENTER', // 消息中心查询数据
  insertOneLink: 'INSERT_ONE_LINK', // 插入一键入会
  queryShareMemberRecord: 'QUERY_SHARE_MEMBER_RECORD', // 查询共享成员记录
  batchInsertShareMember: 'BATCH_INSERT_SHARE_MEMBER', // 批量插入共享成员
  deleteShareMember: 'DELETE_SHARE_MEMBER', // 删除共享成员
  queryShareMember: 'QUERY_SHARE_MEMBER', // 查询共享成员
  queryShareMemberList: 'QUERY_SHARE_MEMBER_List', // 查询共享成员
  insertShareMember: 'INSERT_SHARE_MEMBER', // 插入共享成员
  updateShareMemberState: 'UPDATE_SHARE_MEMBER_STATE', // 更新共享成员状态
  queryShareRelation: 'QUERY_SHARE_RELATION', // 查询共享关联表
  insertShareRelation: 'INSERT_SHARE_RELATION', // 插入共享关联信息
  queryRelationListByConditions: 'QUERY_RELATION_LIST_BY_CONDITIONS', // 查询共享关联表
  insertReminder: 'INSERT_REMINDER', // 插入提醒
  deleteReminderById: 'DELETE_REMINDER_BY_ID', // 根据id删除提醒
  deleteReminderByEventId: 'DELETE_REMINDER_BY_EVENT_ID', // 根据event id删除提醒
  updateReminderById: 'UPDATE_REMINDER_BY_ID', // 根据id更新提醒
  queryReminderByEventId: 'QUERY_REMINDER_BY_EVENT_ID', // 根据event id查询提醒
  searchAgenda: 'SEARCH_AGENDA', //搜索日程
  weekendsSettingsChange: 'WEEKENDS_SETTINGS_CHANGE', // 周末设置变更
  allMonthVM: 'ALL_MONTH_VM', // 查询月视图卡片业务
  queryCalendarMetaData: 'QUERY_CALENDAR_META',
  jumpToAgendaDetail: 'JUMP_TO_AGENDA_DETAIL', // 跳转日程详情
  yearViewSwipe: 'CUSTOM_ANIMATOR_YEAR_VIEW_SWIPE', // 年视图滑动
  monthViewSwipe: 'CUSTOM_ANIMATOR_MONTH_VIEW_SWIPE', // 月视图滑动
  weekViewSwipe: 'CUSTOM_ANIMATOR_WEEK_VIEW_SWIPE', // 周视图滑动
  dayViewSwipe: 'CUSTOM_ANIMATOR_DAY_VIEW_SWIPE', // 日视图滑动
  monthAgendaListSwipe: 'CUSTOM_ANIMATOR_MONTH_AGENDA_LIST_SWIPE', // 月视图日程列表滑动
  agendaListSwipe: 'CUSTOM_ANIMATOR_AGENDA_LIST_SWIPE', // 全部日程列表滑动
  ganttViewSwipe: 'CUSTOM_ANIMATOR_GANTT_VIEW_SWIPE', // 甘特图滑动
  accountListSwipe: 'CUSTOM_ANIMATOR_ACCOUNT_LIST_SWIPE', // 帐户列表滑动
  encryptLocation: 'IPC_ENCRYPT_LOCATION', // 跨进程经纬度加密
  decryptLocation: 'IPC_DECRYPT_LOCATION', // 跨进程经纬度解密
  batchInsertAttachment: 'BATCH_INSERT_ATTACHMENT', // 批量插入附件
  insertAttachment: 'INSERT_ATTACHMENT', // 插入附件
  deleteAttachment: 'DELETE_ATTACHMENT', // 删除附件
  queryAttachment: 'QUERY_ATTACHMENT', // 查询附件
  copyAttachment: 'IPC_COPY_ATTACHMENT', // 跨进程复制附件
  acquireAttachmentUri: 'IPC_ACQUIRE_ATTACHMENT_URI', // 跨进程获取转授权uri
  buildBlock: 'BUILD_BLOCK', // 单个日程块渲染
  drawContent: 'DRAW_CONTENT', // 所有日程块渲染
  drawMonthTitle: 'DRAW_MONTH_TITLE', // 绘制月视图标题
  drawWeekTitle: 'DRAW_WEEK_TITLE', // 绘制周视图标题
  drawDate: 'DRAW_DATE', // 绘制月视图日程
  updateBlocks: 'UPDATE_BLOCKS', // 更新甘特图日程块
};