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

import { PermissionChecker, PermissionInterceptor } from '../net/interceptor/PermissionInterceptor';
import { RequestEngineBuilder } from '../net/RequestEngine';
import lazy { GlobalNetService } from '../interface/GlobalNetService';
import { HttpRequestContext } from '../net/HttpClient';
import { RequestHelper } from '../net/RequestHelper';
import { factory } from '@app/common/src/main/ets/service/framework/Service';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesFiles';
import { SettingPreferencesKeys } from '@app/common/src/main/ets/default/util/preferences_util/SettingPreferencesKeys';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG = 'GlobalNetServiceImpl';
/**
 * GlobalNetServiceImpl
 */
@factory(ServiceEnum.GLOBAL_NET_SERVICE)
export class GlobalNetServiceImpl extends GlobalNetService {
  private requestHelper!:RequestHelper;

  constructor() {
    super(ServiceEnum.GLOBAL_NET_SERVICE);

  }

  private initRequestHelper(): void {
    Log.info(TAG, 'initRequestHelper');
    const permissionChecker: PermissionChecker = {
      isEnableExecuteRequest(context: HttpRequestContext): boolean {
        return PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS,
          SettingPreferencesKeys.IS_ALLOW_NETWORK, 0) === 1;
      }
    };
    const prefix = 'global';
    const permissionInterceptor: PermissionInterceptor = new PermissionInterceptor(prefix, permissionChecker);
    const builder = new RequestEngineBuilder().appendInterceptor(permissionInterceptor).setPrefixTag(prefix);
    const httpClient = builder.build();
    this.requestHelper = new RequestHelper(httpClient, builder);
  }

  getRequestHelper(): RequestHelper {
    return this.requestHelper;
  }

  protected doStart(): Promise<void> {
    this.initRequestHelper();
    return;
  }
}