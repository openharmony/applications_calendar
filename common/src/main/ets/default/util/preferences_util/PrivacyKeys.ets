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

export enum PrivacyKeys {

  /**
   * 天气缓存的版本
   */
  PRIVACY_WEATHER_CACHED_VERSION = 'privacy_cached_weather_version',

  /**
   * 定位缓存的版本
   */
  PRIVACY_LOCATION_CACHED_VERSION = 'privacy_cached_location_version',

}

// 协议ID，需与agreement_config.json里匹配
export enum AgreementType {
  privacyStatement = 10625, // 隐私声明
  change = 30000112 // 变更通知
}