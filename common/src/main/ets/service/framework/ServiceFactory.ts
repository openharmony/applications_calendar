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

import { Log } from '../../default/common/Log';
import { EmptyUtils } from '../../util/EmptyUtils';
import { TypeUtils } from '../../util/TypeUtils';
import { Constructor, Service } from './Service';
import { ServiceErrCode } from './ServiceConsts';
import { ServiceManager } from './ServiceManager';

const TAG = '[Service][Factory]';

class ServiceFactory {
  private constructorMap: Map<string, Constructor<Service>> = new Map<string, Constructor<Service>>();

  clear(): void {
    this.constructorMap.clear();
  }

  register(serviceName: string, constructor: Constructor<Service>): ServiceErrCode {
    if (EmptyUtils.isEmptyString(serviceName, true)) {
      Log.warn(TAG, 'serviceName empty');
      return ServiceErrCode.SERVICE_NAME_INVALID;
    }
    Log.info(TAG, `register ${serviceName}`);
    if (this.constructorMap.has(serviceName)) {
      Log.warn(TAG, `${serviceName} has already registered.`);
      return ServiceErrCode.SERVICE_ALREADY_REGISTERED;
    }
    this.constructorMap.set(serviceName, constructor);
    return ServiceErrCode.SUCCESS;
  }

  /**
   * 根据服务名称获取服务的构造函数
   * @param serviceName 服务名称
   * @return 返回服务的构造函数
   */
  getConstructor(serviceName: string): Constructor<Service> {
    if (!this.constructorMap.has(serviceName)) {
      Log.warn(TAG, `${serviceName} is not registered.`);
      return null;
    }
    return this.constructorMap.get(serviceName);
  }

  /**
   * 异步获取指定服务的构造函数
   * @param serviceName 服务名称
   * @return 返回一个Promise，其解析值是一个服务的构造函数
   * @throws 如果服务不存在，可能会抛出错误
   */
  async getConstructorAsync(serviceName: string): Promise<Constructor<Service>> {
    const tag = TAG + '-getConstructorAsync';
    const constructor = this.constructorMap.get(serviceName);
    if (constructor) {
      return constructor;
    }
    Log.info(tag, `${serviceName} not registered try dynamic import`);
    const moduleName = ServiceManager.getInstance().getServiceModule(serviceName);
    if (!moduleName) {
      Log.warn(tag, `${serviceName} module not exist`);
      return undefined;
    }

    try {
      const ns: ESObject = await import(moduleName);
      if (EmptyUtils.isUndefinedOrNull(ns)) {
        Log.error(tag, `moduleName[${moduleName}] ns is null`);
        return undefined;
      }
      const serviceInit: Function = ns.serviceInit;
      if (!serviceInit) {
        Log.warn(tag, `moduleName[${moduleName}] no serviceInit Property`);
        return undefined;
      }
      if (!TypeUtils.isFunction(serviceInit)) {
        Log.warn(tag, `moduleName[${moduleName}] harInit not function`);
        return undefined;
      }
      await serviceInit(serviceName);
      Log.warn(tag, `[${serviceName}] dynamic import success`);
      return this.constructorMap.get(serviceName);
    } catch (error) {
      Log.logErrorMsg(tag, `dynamicBuild [${serviceName}] error`, error);
      return undefined;
    }
  }
}

let serviceFactory = new ServiceFactory();

export default serviceFactory as ServiceFactory;