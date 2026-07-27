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

import { EmptyUtils } from '../../util/EmptyUtils';
import { ServiceErrCode } from './ServiceConsts';

export class ServiceApi {
  private static apiMap: Map<string, string[]> = new Map();

  public static clear() : void {
    ServiceApi.apiMap.clear();
  }

  public static getApiMap(): Map<string, string[]> {
    return ServiceApi.apiMap;
  }

  public static registerApi(serviceName: string, apiName: string): ServiceErrCode {
    if (EmptyUtils.isEmptyString(serviceName, true)) {
      return ServiceErrCode.SERVICE_NAME_INVALID;
    }
    if (EmptyUtils.isEmptyString(apiName, true)) {
      return ServiceErrCode.API_NAME_INVALID;
    }
    let apiList = ServiceApi.apiMap.get(serviceName);
    if (apiList) {
      if (apiList.indexOf(apiName) !== -1) {
        return ServiceErrCode.API_ALREADY_REGISTERED;
      }
    } else {
      apiList = [];
    }
    apiList.push(apiName);
    ServiceApi.apiMap.set(serviceName, apiList);
    return ServiceErrCode.SUCCESS;
  }

  public static isRegistered(serviceName: string, apiName: string): boolean {
    const apiList = ServiceApi.apiMap.get(serviceName);
    if (apiList === undefined) {
      return false;
    }
    return apiList.includes(apiName);
  }
}