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

import ServiceFactory from './ServiceFactory';
import { ServiceErrCode } from './ServiceConsts';
import { ServiceStatePublisher } from './ServiceStateObserver';
import { ServiceApi } from './ServiceApi';
import { Log } from '../../default/common/Log';

export type Constructor<T> = new (...args: any[]) => T;

const TAG = 'Service'

/*
服务工厂自注册装饰器
 * */
export function factory(serviceName: string) {
  return function register(target: Constructor<Service>) {
    let registerClass = class extends target {
      constructor() {
        super(serviceName);
      }
    };
    ServiceFactory.register(serviceName, registerClass);
  };
}

export function publicApi(target: Object, propertyKey: string, descriptor: PropertyDescriptor) {
  let originalMethod = descriptor.value;
  ServiceApi.registerApi(target.constructor.name, propertyKey);
  descriptor.value = function (...args: any[]) {
    let result = originalMethod.apply(this, args);
    return result;
  };
}

/* 关于服务状态，参考Windows服务状态切换
https://docs.microsoft.com/zh-cn/windows/win32/services/service-status-transitions
采用状态机模型进行状态切换 */

// 服务抽象类
export enum ServiceState {
  STOPPED = 0x0001,
  START_PENDING = 0x0002,
  STOP_PENDING = 0x0003,
  RUNNING = 0x0004,
  CONTINUE_PENDING = 0x0005,
  PAUSE_PENDING = 0x0006,
  PAUSED = 0x0007,
}

export enum ServiceControl {
  STOP,
  START,
  CONTINUE,
  PAUSE,
}

interface stateTransfer {
  curState: ServiceState,
  action: ServiceControl;
  transitionState: ServiceState,
  targetState: ServiceState,
}

const stateTransferTable: ReadonlyArray<stateTransfer> = [
  {
    curState: ServiceState.STOPPED,
    action: ServiceControl.START,
    transitionState: ServiceState.START_PENDING,
    targetState: ServiceState.RUNNING
  },
  {
    curState: ServiceState.STOPPED,
    action: ServiceControl.STOP,
    transitionState: ServiceState.STOPPED,
    targetState: ServiceState.STOPPED
  },
  {
    curState: ServiceState.RUNNING,
    action: ServiceControl.STOP,
    transitionState: ServiceState.STOP_PENDING,
    targetState: ServiceState.STOPPED
  },
  {
    curState: ServiceState.RUNNING,
    action: ServiceControl.START,
    transitionState: ServiceState.RUNNING,
    targetState: ServiceState.RUNNING
  },
  {
    curState: ServiceState.RUNNING,
    action: ServiceControl.PAUSE,
    transitionState: ServiceState.PAUSE_PENDING,
    targetState: ServiceState.PAUSED
  },
  {
    curState: ServiceState.PAUSED,
    action: ServiceControl.CONTINUE,
    transitionState: ServiceState.CONTINUE_PENDING,
    targetState: ServiceState.RUNNING
  },
  {
    curState: ServiceState.PAUSED,
    action: ServiceControl.STOP,
    transitionState: ServiceState.STOP_PENDING,
    targetState: ServiceState.STOPPED
  },
];

export abstract class Service {
  public readonly name: string;
  public statePublisher: ServiceStatePublisher = new ServiceStatePublisher();

  private jumperMap: Map<ServiceControl, () => void> = new Map();

  constructor(name: string) {
    this.name = name;
    this.curState = ServiceState.STOPPED;
    this.jumperMap = new Map([
      [ServiceControl.START, this.doStart],
      [ServiceControl.STOP, this.doStop],
      [ServiceControl.PAUSE, this.doPause],
      [ServiceControl.CONTINUE, this.doContinue],
    ]);
  }

  private _curState: ServiceState;

  public get curState(): ServiceState {
    return this._curState;
  }

  private set curState(state: ServiceState) {
    const lastState = this._curState;
    this._curState = state;
    this.statePublisher.notifyObservers({
      lastState: lastState,
      currentState: state,
      serviceName: this.name
    });
  }

  isRunning(): boolean {
    return this.curState === ServiceState.RUNNING;
  }

  protected async doStart(): Promise<void> {
  };

  protected async doStop(): Promise<void> {
  };

  protected async doPause(): Promise<void> {
  };

  protected async doContinue(): Promise<void> {
  };

  public async start(): Promise<ServiceErrCode> {
    return await this.transferState(ServiceControl.START);
  }

  public async stop(): Promise<ServiceErrCode> {
    return await this.transferState(ServiceControl.STOP);
  }

  public async pause(): Promise<ServiceErrCode> {
    return await this.transferState(ServiceControl.PAUSE);
  }

  public async continue(): Promise<ServiceErrCode> {
    return await this.transferState(ServiceControl.CONTINUE);
  }

  private async transferState(action: ServiceControl): Promise<ServiceErrCode> {
    Log.debug(TAG, `transferState ${this.name}, action ${action}`);
    const curState = this.curState;
    const matchRule = stateTransferTable.find((info) => (info.curState === curState && info.action === action));
    if (!matchRule) {
      Log.error(TAG, `transferState failed, action ${action} not support in state ${curState}`);
      return ServiceErrCode.STATE_TRANSFER_MATCH_FAILED;
    }
    this.curState = matchRule.transitionState;
    Log.debug(TAG, `transferState ${this.name}, curState ${this.curState}`);
    const callback = this.jumperMap.get(action);
    if (!callback) {
      Log.error(TAG, `transferState failed, action ${action} no callback`);
      return ServiceErrCode.STATE_TRANSFER_ACTION_NO_FOUND;
    }
    await callback.call(this);
    this.curState = matchRule.targetState;
    Log.debug(TAG, `transferState ${this.name}, curState ${this.curState}`);
    return ServiceErrCode.SUCCESS;
  }
}
;
