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
import { Log, ModuleName, ServiceEnum } from '@app/common';


export { GlobalNetService } from './src/main/ets/interface/GlobalNetService';

export { NetWorkManger } from './src/main/ets/impl/NetWorkManger';

export { NetConnectionUtil } from './src/main/ets/impl/NetConnectionUtil';

export { NetState } from './src/main/ets/impl/NetConnectionUtil';

// 网络api start
export { RequestHeaders,
  ResponseHeaders,
  HttpMethod,
  DavMethod,
  ContentType,
  ContentCoding } from './src/main/ets/net/HttpConfig';

export { RequestHelper } from './src/main/ets/net/RequestHelper';

export { RequestEngineBuilder } from './src/main/ets/net/RequestEngine';

export { PermissionInterceptor, PermissionChecker } from './src/main/ets/net/interceptor/PermissionInterceptor';

// 网络相关api end

// Har包初始化函数
export function serviceInit(service: string): void {
  Log.info(ModuleName.SERVICE_NETWORK, `serviceInit ${service}`);
  switch (service) {
    case ServiceEnum.GLOBAL_NET_SERVICE:
      import('./src/main/ets/impl/GlobalNetServiceImpl');
      break;
    default:
      break;
  }
}