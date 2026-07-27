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

export enum StatementStateKeys {

  /**
   * 是否已同意日历隐私声明
   */
  KEY_IS_AGREE_STATEMENT = 'is_agree_calendar_statement',

  /**
   * 启屏页同意与否状态的细节
   */
  KEY_STATEMENT_RECORD = 'statement_record',

  /**
   * 是否日历隐私声明变更通知
   */
  KEY_IS_PERMISSION_CHANGE_STATEMENT = 'is_permission_change_calendar_statement',

  APP_VERSION = 'app_version',

  AGREE_TIMESTAMP = 'agree_timestamp',

  AGREE_FORMAT_TIME = 'agree_format_time',

  PRIVACY_VERSION = 'privacy_version',

  ACCOUNT_ID = 'account_id',

  AGREE_RESULT = 'agree_result',

  SETTING_CACHE = 'setting_cache',
}