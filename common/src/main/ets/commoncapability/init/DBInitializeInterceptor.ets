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

import { InitializeInterceptor } from './InitializeInterceptor';
import { PreferencesUtil } from '../../default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '../../default/util/preferences_util/PreferencesFiles';
import { StatementStateKeys } from '../../default/util/preferences_util/StatementStateKeys';
import { ModeUtil } from '../../util/ModeUtil';

/**
 * 数据库初始化拦截器
 */
export class DBInitializeInterceptor implements InitializeInterceptor {
  constructor() {
  }

  async isCanInit(): Promise<boolean> {
    //开源版本日历没有隐私声明，这里直接返回true
     return PreferencesUtil.getBooleanValueSync(
     PreferencesFiles.STATEMENT_STATE, StatementStateKeys.KEY_IS_AGREE_STATEMENT, true);
  }

  providerInitParas(): null {
    return null;
  }
}
