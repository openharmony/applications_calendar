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
import { Callback, emitter } from '@kit.BasicServicesKit';

/*
 * 使用场景：
 * 在需要注册多个事件，并且需要在一个函数中注册多个事件，然后在另一个函数中批量取消注册的场景下使用
 *
 * 使用方法：
 * 1. 创建一个EmitterCollector实例
 * 2. 使用on方法注册事件
 * 3. 使用off方法批量取消注册的事件
 */
export class EmitterCollector {
  private emitterCallbacks: Map<number, Callback<emitter.EventData>> = new Map();

  public on(event: emitter.InnerEvent, callback: Callback<emitter.EventData>) : boolean {
    if (this.emitterCallbacks.has(event.eventId)) {
      return false;
    }
    emitter.on(event, callback);
    this.emitterCallbacks.set(event.eventId, callback);
    return true;
  }

  public off() : void {
    this.emitterCallbacks.forEach((callback, eventId) => {
      emitter.off(eventId, callback);
    });
    this.emitterCallbacks.clear();
  }
}