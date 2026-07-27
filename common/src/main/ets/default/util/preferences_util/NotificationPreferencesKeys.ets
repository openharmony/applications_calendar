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

export enum NotificationPreferencesKeys {

  // 是否已经申请过通知权限
  REQUEST_NOTIFICATION_PERMISSION_STATE = 'request_notification_permission_state',
  // 是否允许通知
  IS_FOLLOW_NOTIFICATION = 'is_follow_notification',

  // 弹窗请求通知权限的次数
  REQUEST_TIMES_IN_APP_KEY = 'request_times_in_app',

  // 上次弹窗通知授权时间戳
  LAST_REQUEST_TIME_IN_APP_KEY = 'last_request_in_app',

  // 是否首次进入应用
  IS_FIRST_IN_APP = 'is_first_in_app',
}