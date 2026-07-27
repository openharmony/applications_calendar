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

import { ValueType } from '@ohos.data.ValuesBucket';

export interface InitializeInterceptor {

  /**
   * 拦截器定义是否需要初始化
   *
   * @return boolean 拦截器定义是否需要初始化
   */
  isCanInit(): Promise<boolean>;

  /**
   * 初始化需要的参数,动态初始化时需要
   *
   * @return Map<String, Object> Map<String, Object>
   */
  providerInitParas(): Map<string, ValueType> | null;
}
