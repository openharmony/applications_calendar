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
import { EmitServiceStateObserver } from '../implements/auditor/EmitServiceStateObserver';
import { Service } from './Service';
import { ServiceErrCode } from './ServiceConsts';

const TAG = '[Service][Management]';

/**
 * 服务管理服务,后期可以每个模块自己定义一个子管理服务，实现树形管理
 */
export class ManagementService extends Service {
  // 服务实例
  private serviceInstances: Map<string, Service> = new Map();

  constructor() {
    super('ManagementService');
  }

  doStart(): Promise<void> {
    Log.info(TAG, 'doStart');
    this.clearInstances();
    return;
  };

  doStop(): Promise<void> {
    Log.info(TAG, 'doStop start');
    this.stopAllService();
    Log.info(TAG, 'doStop stopAllService finished');
    this.clearInstances();
    Log.info(TAG, 'doStop clearInstances finished');
    return;
  };

  /**
   * 添加服务实例到服务实例集合中
   * @param instance 服务实例
   */
  public addService(instance: Service): ServiceErrCode {
    const tag = TAG + '-addService';
    const name = instance.name;
    if (EmptyUtils.isEmptyString(name, true)) {
      Log.warn(tag, 'serviceName INVALID');
      return ServiceErrCode.SERVICE_NAME_INVALID;
    }
    if (this.serviceInstances.has(name)) {
      Log.warn(tag, `${name} already exist`);
      return ServiceErrCode.SERVICE_ALREADY_EXIST;
    }
    instance.statePublisher.addObserver(new EmitServiceStateObserver(name));
    this.serviceInstances.set(name, instance);
    Log.warn(tag, `${name} add success`);
    return ServiceErrCode.SUCCESS;
  }

  /**
   * 移除服务
   */
  public removeService(serviceName: string): ServiceErrCode {
    const tag = TAG + '-removeService';
    if (EmptyUtils.isEmptyString(serviceName, true)) {
      Log.warn(tag, 'serviceName is empty');
      return ServiceErrCode.SERVICE_NAME_INVALID;
    }
    if (!this.serviceInstances.has(serviceName)) {
      Log.warn(tag, `${serviceName} no such service`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    const result = this.serviceInstances.delete(serviceName);
    if (!result) {
      return ServiceErrCode.SERVICE_DELETE_FAILED;
    }
    return ServiceErrCode.SUCCESS;
  }

  private clearInstances(): void {
    this.serviceInstances.clear();
  }

  public stopAllService(): void {
    const tag = TAG + '-stopAllService';
    type ServiceStopResult = {
      name: string;
      result?: ServiceErrCode;
      error?: Error;
    };
    Promise.all(
      Array.from(this.serviceInstances.entries()).map(([name, service]) => {
        Log.warn(tag, `stop service ${name}`);
        return service.stop()
          .then(result => ({ name, result }))
          .catch(error => ({ name, error }));
      })
    ).then((results: ServiceStopResult[]) => {
      // 处理每个服务的返回值或错误
      results.forEach(({ name, result, error }) => {
        if (error) {
          Log.error(tag, `Service ${name} failed to stop: ${error}`);
        } else {
          Log.warn(tag, `Service ${name} stop result: ${result}`);
        }
      });
    }).catch((error) => {
      Log.logErrorMsg(tag, 'Error stopping services:', error);
      throw error;
    });
  }

  /**
   * 启动服务
   * @param info 服务信息
   * @param dynamic 是否动态启动，默认为true
   * @return 返回一个Promise，其解析值为布尔值，表示服务是否成功启动
   * @throws 如果服务启动失败，会抛出异常
   */
  public async startService(name: string, startDelayTime?: number): Promise<ServiceErrCode> {
    const tag = TAG + '-startService';
    const service = this.getService<Service>(name);
    if (!service) {
      Log.warn(tag, `${name} not found`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    if (startDelayTime) {
      const timer = setTimeout(() => {
        service?.start();
        clearTimeout(timer);
      }, startDelayTime);
    } else {
      return await service.start();
    }
    return ServiceErrCode.SUCCESS;
  }

  /**
   * 停止指定名称的服务
   * @param name 需要停止的服务的名称
   * @return 如果服务成功停止，返回true，否则返回false
   */
  public async stopService(name: string, delayTime?: number): Promise<ServiceErrCode> {
    const tag = TAG + '-stopService';
    const instance = this.serviceInstances.get(name);
    if (!instance) {
      Log.warn(tag, `${name} not found`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    return await instance.stop();
  }

  /**
   * 暂停指定名称的服务
   * @param name 需要暂停的服务名称
   * @return 如果服务成功暂停，返回true，否则返回false
   */
  public async pauseService(name: string): Promise<ServiceErrCode> {
    const tag = TAG + '-pauseService';
    const instance = this.serviceInstances.get(name);
    if (!instance) {
      Log.warn(tag, `${name} not found`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    return await instance.pause();
  }


  /**
   * 继续服务
   * @param name 服务名称
   * @return 返回一个布尔值，表示服务是否成功
   */
  public async continueService(name: string): Promise<ServiceErrCode> {
    const tag = TAG + '-continueService';
    const instance = this.serviceInstances.get(name);
    if (!instance) {
      Log.warn(tag, `${name} not found`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    return await instance.continue();
  }

  /**
   * 获取指定服务
   * @param serviceName 服务名称
   * @return 返回获取到的服务实例，如果没有找到则返回undefined
   */
  public getService<T>(serviceName: string): T | undefined {
    const tag = TAG + '-getService';
    if (EmptyUtils.isEmptyString(serviceName)) {
      Log.warn(tag, 'serviceName empty');
      return undefined;
    }
    const instance = this.serviceInstances.get(serviceName);
    if (!instance) {
      Log.warn(tag, `${serviceName} not found`);
      return undefined;
    }
    return instance as T;
  }
}