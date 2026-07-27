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
 * 首选项文件名枚举
 */
export enum PreferencesFiles {
  DEFAULT = 'default',
  ACCOUNT = 'account',
  SETTINGS = 'settings',
  MONTH = 'month',
  // 历法
  CALENDARS = 'calendars',
  TAB_INDEX = 'tabIndex',
  RECESS = 'recess',
  MIGRATE = 'migrate',
  NOTIFICATION = 'notification',
  STATEMENT_STATE = 'StatementState',
  PRIVACY = 'Privacy',
  // 导入导出
  EXPORT_IMPORT = 'export_import',
  // 共享
  SHARE = 'share',
  // 数据库轻量级配置
  DB_STORE = 'db_store',
  HAG = 'HAG',
  HOLIDAY = 'holiday',
  IMPORTANT_DAY_FROM_CARD_INFO = 'importantDayFromCardInfo',
  // 订阅
  Subscription = 'subscription',
  // 重要日卡片配置
  IMPORTANT_CARD_CONFIG = 'important_card_config',
  // 卡片信息
  BASE_CARD_INFO = 'form_base_info',
  // 问题与建议账号侧
  WISE_SUPPORT = 'wise_support',
  // 剪贴板
  PASTE_BOARD = 'paste_board',
  // 课程表
  SCHEDULE_COURSE = 'schedule_course',
  // 迁移业务卡片信息
  MIGRATE_BASE_FORM = 'migrate_base_form',
  // 双框架授权状态
  DOUBLE_SP_STATE = 'double_sp_state',
  // 能效资源
  EFFICIENCY_RESOURCES = 'efficiency_resources',
  // 情感化卡片
  EMOTIONAL_CARD = 'emotional_card',
  // 上一次打点记录
  REPORT_AGENDA_LAST_TIME = 'report_agenda_last_time',
  // 全部日程是否展示节日
  AGENDA_LIST_IS_SHOW_HOLIDAY = 'agenda_list_is_show_holiday',
}