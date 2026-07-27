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
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';

const TAG = 'AgendaResultUtil'

export interface AgendaResultDeal {
  entityId: string,
  instanceId: string,
  instanceUuid: string
}

export class AgendaResultUtil {
  public static getAgendaResult(parameter: Object): AgendaResultDeal {
    const resultEntityId: string[] = [];
    const resultInstanceUuid: string[] = [];
    const resultInstanceId: string[] = [];
    let entityId: string = '';
    let instanceId: string = '';
    let instanceUuid: string = '';
    Object.values(parameter).forEach((items: string) => {
      Object.values(items).forEach((event: string) => {
        let eventEntityId: string = event['entityId'];
        let eventInstanceUuid: string = event['instanceUuid'];
        let eventInstanceId: string = event['instanceId'];
        if (Number.isNaN(Number(eventEntityId))) {
          Log.error(TAG, `event is ${eventEntityId} , illeagl`);
        } else {
          resultEntityId.push(eventEntityId)
        }
        if (EmptyUtils.isEmptyString(eventInstanceUuid)) {
          Log.error(TAG, `event is ${maskString(eventInstanceUuid)}, illegal`);
        } else {
          resultInstanceUuid.push(eventInstanceUuid)
        }
        if (Number.isNaN(Number(eventInstanceId))) {
          Log.error(TAG, `event is ${eventInstanceId}, illegal`);
        } else {
          resultInstanceId.push(eventInstanceId)
        }
      })
    })
    if (resultEntityId.length) {
      entityId = resultEntityId.join(',')
    }
    if (resultInstanceId.length) {
      instanceId = resultInstanceId.join(',')
    }
    if (resultInstanceUuid.length) {
      instanceUuid = resultInstanceUuid.join(',')
    }
    Log.info(TAG, `intent entityId is ${entityId}`);
    Log.info(TAG, `intent instanceId is ${instanceId}`);
    Log.info(TAG, `intent instanceUuid is ${maskString(instanceUuid)}`);
    return {
      entityId, instanceId, instanceUuid
    }
  }
}