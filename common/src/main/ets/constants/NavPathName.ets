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

export enum NavPathName {
  // AGENDA BEGIN
  AGENDA_DETAIL = 'agenda_detail',
  ATTENDEE_LIST = 'attendee_list',
  AGENDA_LIST = 'agenda_list',
  MONTH_VIEW = 'month_view',
  WEEK_VIEW = 'week_view',
  ACCOUNT_AGENDA_LIST = 'account_agenda_list',
  CREATE_AGENDA_POP = 'create_agenda_pop',
  MULTI_DELETE = 'multi_delete',
  FLEX_SEARCH_AGENDA = 'flex_search_agenda',
  CREATE_AGENDA_SUB = 'create_agenda_sub',
  // AGENDA END
  IMPORTANT_CARD_SELECT = 'important_card_select',
  IMPORTANT_CARD_EDIT = 'important_card_edit',
  // SUB FEATURE BEGIN
  PAF_PRIVACY_PAGE = 'paf_privacy_page',
  // SUB FEATURE END
  MAIN_PAGE = 'main_page',
  CONTACT_PICKER = 'contact_picker',
  // SHARE BEGIN
  MESSAGE_CENTER_MAIN = 'message_center_main',
  SHARE_AGENDA = 'share_agenda',
  SHARE_ACCOUNT = 'share_account',
  // SHARE END

  // REPEAT_RULE BEGIN
  CUSTOM_REPEAT = 'custom_repeat_page',
  // REPEAT_RULE END

  // IMPORT_EXPORT BEGIN
  IMPORT_ACCOUNT = 'import_account_root',
  IMPORT_SHOW_AGENDA = 'import_show_agenda_root',
  // IMPORT_EXPORT END
  SETTING_MAIN = 'setting_main',
  SETTING_ABOUT = 'setting_about',
  SETTINGS_TIME_ZONE = 'setting_time_zone',
  APP_DISPLAY_RECORD_DETAIL = 'app_display_record_detail',
  SETTINGS_NATIONAL_REGION_HOLIDAY = 'settings_national_region_holiday',
  PRIVACY_DECLARE = 'privacy_declare',

  IMPORT_AGENDA = 'import_agenda'
}