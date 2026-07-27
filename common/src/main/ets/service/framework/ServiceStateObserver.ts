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

import { ServiceState } from './Service';
import { EmptyUtils } from '../../util/EmptyUtils';
import { ServiceErrCode } from './ServiceConsts';

export interface ServiceStateChangeInfo {
  serviceName: string;
  lastState: ServiceState,
  currentState: ServiceState,
}

export abstract class ServiceStateObserver {
  public observerName : string;
  abstract onServiceStateChanged(changeInfo: ServiceStateChangeInfo) : void;
  constructor(observerName : string) {
    this.observerName = observerName;
  }
};

export class ServiceStatePublisher {
  private observers: Map<string, ServiceStateObserver> = new Map();

  constructor() {
  }

  public addObserver(observer: ServiceStateObserver) : ServiceErrCode {
    if (this.observers.has(observer.observerName)) {
      return ServiceErrCode.STATE_OBSERVER_ALREADY_EXIST;
    }
    this.observers.set(observer.observerName, observer);
    return ServiceErrCode.SUCCESS;
  }

  public removeObserver(observerName: string) : ServiceErrCode {
    if (EmptyUtils.isEmptyString(observerName, true)) {
      return ServiceErrCode.STATE_OBSERVER_NAME_INVALID;
    }
    if (!this.observers.has(observerName)) {
      return ServiceErrCode.STATE_OBSERVER_NO_FOUND;
    }
    this.observers.delete(observerName);
    return ServiceErrCode.SUCCESS;
  }

  public notifyObservers(changeInfo: ServiceStateChangeInfo):void {
    this.observers.forEach(observer => {
      observer.onServiceStateChanged(changeInfo);
    });
  }
};