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
import { emitter } from '@kit.BasicServicesKit';
import { ManagementService } from './ManagementService';
import ServiceFactory from './ServiceFactory';
import { ServiceErrCode, ServiceEvent } from './ServiceConsts';
import { Service, ServiceControl } from './Service';
import { ServiceApi } from './ServiceApi';
import { applyTemplate } from './ReflectUtil';
import { ServiceEnv } from './ServiceGlobalEnv';
import { ServiceConfig } from './ServiceConfig';

const TAG = '[Service][Manager]';

/**
 * Global Service Manager
 */
export class ServiceManager {
  private static instance: ServiceManager;
  private manager: ManagementService = new ManagementService();
  private serviceStartRecord: string[] = [];
  private config: ReadonlyArray<ServiceConfig>;
  private jumperMap: Map<ServiceControl, (name: string, delayTime?: number) => Promise<ServiceErrCode>> = new Map();

  constructor() {
    this.jumperMap = new Map([
      [ServiceControl.START, this.startService],
      [ServiceControl.STOP, this.stopService],
      [ServiceControl.PAUSE, this.pauseService],
      [ServiceControl.CONTINUE, this.continueService],
    ]);
  }

  static getInstance(): ServiceManager {
    if (!ServiceManager.instance) {
      ServiceManager.instance = new ServiceManager();
    }
    return ServiceManager.instance;
  }

  init(config : ReadonlyArray<ServiceConfig>): void {
    Log.info(TAG, 'init');
    this.config = config;
    this.manager.stop();
    this.subscribeEvent(); // 订阅服务管理相关事件
    this.manager.start();
  };

  async deInit(): Promise<void> {
    Log.info(TAG, 'deInit');
    // 按启动顺序依次反初始化
    const serviceList = this.serviceStartRecord.reverse();
    // 逐个等待每个服务停止
    for (const serviceName of serviceList) {
      try {
        await this.stopService(serviceName);
      } catch (error) {
        Log.error(TAG, `Failed to stop service ${serviceName}: ${error}`);
        // 可以选择继续处理下一个服务，或者根据需要抛出错误
      }
    }
    this.manager.stop();
    this.unSubscribeEvent(); // 订阅服务管理相关事件
  };

  public getServiceModule(serviceName: string): string | undefined {
    if (serviceName === '') {
      Log.warn(TAG, 'serviceName empty');
      return undefined;
    }
    for (let config of this.config) {
      if (config.info.name === serviceName) {
        if (config.info.module) {
          return config.info.module;
        }
      }
    }
    return undefined;
  }

  public async controlService(cmd: ServiceControl, name: string, delayTime?: number): Promise<ServiceErrCode> {
    const func = this.jumperMap.get(cmd);
    if (!func) {
      Log.error(TAG, `invalid func for control ${cmd}}`);
      return ServiceErrCode.CONTROL_NOT_FOUND;
    }
    return await func.call(this, name, delayTime);
  }

  /**
   * 启动服务
   * @param info 服务配置信息
   * @return 返回一个Promise，其解析值为布尔值，表示服务是否成功启动
   * @throws 如果服务启动失败，会抛出异常
   */
  public async startService(name: string, delayTime?: number): Promise<ServiceErrCode> {
    const tag = TAG + '-startService';
    const service = await this.getDynamicService<Service>(name);
    if (!service) {
      Log.info(tag, `getDynamicService [${name}] failed`);
      return ServiceErrCode.SERVICE_NOT_EXIST;
    }
    const result = await this.manager.startService(name, delayTime);
    if (result !== ServiceErrCode.SUCCESS) {
      Log.info(tag, `startService [${name}] failed`);
      return result;
    }
    this.serviceStartRecord.push(name);
    return ServiceErrCode.SUCCESS;
  }

  /**
   * 停止指定名称的服务
   * @param name 需要停止的服务的名称
   * @return 如果服务成功停止，返回true，否则返回false
   */
  public async stopService(name: string, delayTime?: number): Promise<ServiceErrCode> {
    return await this.manager.stopService(name, delayTime);
  }

  /**
   * 暂停指定名称的服务
   * @param name 需要暂停的服务名称
   * @return 如果服务成功暂停，返回true，否则返回false
   */
  public async pauseService(name: string): Promise<ServiceErrCode> {
    return await this.manager.pauseService(name);
  }


  /**
   * 继续服务
   * @param name 服务名称
   * @return 返回一个布尔值，表示服务是否成功
   */
  public async continueService(name: string): Promise<ServiceErrCode> {
    return await this.manager.continueService(name);
  }


  /**
   * 获取指定服务
   * @param serviceName 服务名称
   * @return 返回获取到的服务实例，如果没有找到则返回undefined
   */
  public getService<T>(serviceName: string): T | undefined {
    const tag = TAG + '-getService';
    // first get service
    const service = this.manager.getService<T>(serviceName);
    if (service) {
      return service;
    }
    Log.info(tag, `[${serviceName}] not exist, start build`);
    let constructor = ServiceFactory.getConstructor(serviceName);
    // get constructor failed
    if (!constructor) {
      Log.error(tag, `[${serviceName}] get construtor failed failed`);
      return undefined;
    }
    const instance = new constructor();
    this.manager.addService(instance);
    return instance as T;
  }

  /**
   * 获取指定服务，不存在动态加载
   * @param serviceName 服务名称
   * @return 返回获取到的服务实例，如果没有找到则返回undefined
   */
  public async getDynamicService<T>(serviceName: string): Promise<T | undefined> {
    const tag = TAG + '-getDynamicService';
    // first get service
    const service = this.manager.getService<T>(serviceName);
    if (service) {
      return service as T;
    }
    Log.info(tag, `[${serviceName}] instance not exist, start build`);
    const constructor = await ServiceFactory.getConstructorAsync(serviceName);
    if (!constructor) {
      Log.error(tag, `[${serviceName}] get construtor failed`);
      return undefined;
    }
    const instance = new constructor();
    this.manager.addService(instance);
    return instance as T;
  }

  /**
   * 调用指定服务的指定API
   * @param serviceName 服务名称
   * @param api 服务API
   * @param args API参数
   * @return 返回API调用结果
   */
  public callApi<T>(serviceName: string, api: string, ...args: ESObject[]): T | undefined {
    if (!ServiceApi.isRegistered(serviceName, api)) {
      return undefined;
    }
    let instance = this.getService<Service>(serviceName);
    if (!instance) {
      Log.warn(TAG, `callApil getService: ${serviceName} failed`);
      return undefined;
    }
    if (!instance.isRunning()) {
      return undefined;
    }

    return applyTemplate(instance[api], instance, args);
  }

  /**
   * 异步调用指定服务的指定API
   * @param serviceName 服务名称
   * @param api 服务API
   * @param args API参数
   * @return 返回API调用结果
   */
  public async callApiAsync<T>(serviceName: string, api: string, ...args: ESObject[]): Promise<T | undefined> {
    const tag = TAG + 'serviceCallAsync';
    if (!ServiceApi.isRegistered(serviceName, api)) {
      Log.warn(tag, `${serviceName} ${api} invalid`);
      return undefined;
    }
    let instance = this.getService<Service>(serviceName);
    if (instance === undefined) {
      Log.warn(tag, `getService: ${serviceName} failed`);
      return undefined;
    }
    if (!instance.isRunning()) {
      Log.warn(tag, `${serviceName} not running`);
      return undefined;
    }
    return await applyTemplate(instance[api], instance, args) as T;
  }

  private subscribeEvent(): void {
    emitter.on<ServiceEnv>(ServiceEvent.SERVICE_ENV_CHANGE, this.onEnvChange);
  }

  private unSubscribeEvent(): void {
    emitter.off<ServiceEnv>(ServiceEvent.SERVICE_ENV_CHANGE, this.onEnvChange);
  }

  private onEnvChange: (data: emitter.GenericEventData<ServiceEnv>) => void =
    (data: emitter.GenericEventData<ServiceEnv>) => {
      if (!data || !data.data) {
        Log.error(TAG, `onEnvChange data invalid`);
        return;
      }
      const state = data.data.state;
      Log.info(TAG, `onEnvChange ${state}}`);
      this.config.forEach(config => {
        config.controlStrategies.forEach(strategy => {
          if (strategy.triggerEvent === state) {
            ServiceManager.getInstance().controlService(strategy.cmd, config.info.name, strategy.delayTime);
          }
        });
      });
    };
}