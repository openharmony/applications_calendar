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

import type { AsyncCallback, BusinessError } from '@ohos.base';
import { Log } from '../../default/common/Log';
import { commonEventManager } from '@kit.BasicServicesKit';
import { EmptyUtils } from '../EmptyUtils';
import { Result } from '../../templates/Result';
import { callBackToVoidPromise } from '../CommonUtils';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';
import { BroadcastHandler } from './BroadcastHandler';

const TAG = 'BroadcastHelper';


/**
 * 发送广播
 *
 * @param action 广播action
 * @param data 广播携带数据，数据结构参考系统api：CommonEventPublishData
 */
export function sendBroadcast(action: string, options?: commonEventManager.CommonEventPublishData,
                              callback?: AsyncCallback<boolean>): Promise<boolean> {
  const warpCallback = (err: BusinessError): void => {
    if (EmptyUtils.isUndefinedOrNull(err)) {
      Log.info(TAG, `sendBroadcast [${action}] successful`);
      callback?.(err, true);
    } else {
      Log.logErrorMsg(TAG, `sendBroadcast [${action}] err`, err);
      callback?.(err, false);
    }
  };
  const callBackPromisePair = callBackToVoidPromise(warpCallback, false, true);
  const executeCallback = callBackPromisePair.first;
  try {
    if (options) {
      commonEventManager.publish(action, options, executeCallback);
    } else {
      commonEventManager.publish(action, executeCallback);
    }
  } catch (error) {
    Log.logErrorMsg(TAG, `sendBroadcast [${action}] err`, error);
    if (EmptyUtils.isUndefinedOrNull(error)) {
      error = {
        code: ErrorCode.UN_KNOWN,
        name: 'UnknownError',
        message: 'sendBroadcast Unknown error occurred.'
      }
    }
    executeCallback(error);
  }
  return callBackPromisePair.second;
}


export async function registerSubscriber(subscribeInfo: commonEventManager.CommonEventSubscribeInfo,
                                         broadcastHandler: BroadcastHandler):
  Promise<Result<commonEventManager.CommonEventSubscriber | undefined>> {
  if (EmptyUtils.isUndefinedOrNull(broadcastHandler)) {
    return new Result(ErrorCode.NULL_CODE, 'broadcastHandler is null', undefined);
  }
  let subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  try {
    subscriber = await commonEventManager.createSubscriber(subscribeInfo);
  } catch (error) {
    Log.logErrorMsg(TAG, `registerSubscriber createSubscriber events ${subscribeInfo?.events?.toString()}`, error);
    return Result.buildByErrorWithData(error, undefined);
  }
  if (EmptyUtils.isUndefinedOrNull(subscriber)) {
    return new Result(ErrorCode.NULL_CODE, 'createSubscriber success but subscriber is null', undefined);
  }
  Log.info(TAG, `registerSubscriber createSubscriber success`);
  const callBack = (error: Error, commonEventData: commonEventManager.CommonEventData) => {
    if (error) {
      Log.logErrorMsg(TAG, 'registerSubscriber', error);
      broadcastHandler.handleError(error);
      return;
    } else {
      Log.info(TAG, `registerSubscriber subscribe success`);
    }

    if (commonEventData) {
      Log.info(TAG, `receive calendardata event code: ${commonEventData.code}`);
      Log.info(TAG, `registerSubscriber recevice event ${commonEventData.event}`);
      if (broadcastHandler.enableHandleEvent(commonEventData)) {
        broadcastHandler.handleEventData(commonEventData);
      }
    }
  }
  try {
    commonEventManager.subscribe(subscriber, callBack);
    Log.info(TAG, `registerSubscriber subscribe success`);
  } catch (error) {
    Log.logErrorMsg(TAG, `registerSubscriber subscribe error`, error);
    return Result.buildByErrorWithData(error, undefined);
  }
  return Result.buildSuccessResult(subscriber);
}

async function unSubscriberInner(subscriber: commonEventManager.CommonEventSubscriber) {
  const unSubscriberResult = await unSubscriber(subscriber);
  if (!unSubscriberResult.isSuccess()) {
    Log.error(TAG, `unSubscriberInner fail: ${unSubscriberResult?.message} code : ${unSubscriberResult?.code}`);
    return;
  }
  Log.info(TAG, `unSubscriberInner success`);
}


export async function unSubscriber(subscriber: commonEventManager.CommonEventSubscriber):
  Promise<Result<boolean>> {
  const callBack = (error: Error, data: boolean) => {

  }
  const callBackPromisePair = callBackToVoidPromise(callBack, false, true);
  commonEventManager.unsubscribe(subscriber, callBackPromisePair.first);
  try {
    const result = await callBackPromisePair.second;
    return Result.buildSuccessResult(result);
  } catch (error) {
    return Result.buildByErrorWithData(error, false)
  }
}

