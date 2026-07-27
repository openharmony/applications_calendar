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
import { GlobalThis } from '../data/GlobalThis';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { Pair } from '../data/Pair';
import { EmptyUtils } from './EmptyUtils';
import { Log } from '../default/common/Log';
import { FontSizeScaleUtils } from './FontSizeScaleUtils';

const TAG = 'CommonUtils';

/**
 * 同步等待
 *
 * @param waitTime 等待时间 毫秒
 * @return Promise
 */
export async function wait(waitTime: number): Promise<void> {
  let wait: Function | null = null;
  const delayPromise = new Promise<void>((resolve) => {
    wait = resolve;
  })
  setTimeout(() => {
    wait?.();
  }, waitTime);
  return delayPromise;
}

export function equalsIgnoreCase(firstString: string, secString: string): boolean {
  if (firstString && secString) {
    return firstString.toLowerCase() == secString.toLowerCase();
  }
  return false;
}

/**
 * 获取弹窗语音播报内容
 *
 * @param title 主题
 * @param number 数目
 * @returns 播报内容
 */
export function getAccessibilityText(title: ResourceStr, number: number): string {
  // todo 提翻
  if (typeof title === 'object') {
    return `${GlobalThis.getResourceStr(title)}， 1至${number}项， 共${number}项`;
  } else {
    return `${title}， 1至${number}项， 共${number}项`;
  }
}

/**
 * callBackToVoidPromise
 *
 */
export function callBackToVoidPromise<T>(callBack: AsyncCallback<T>, failValue: T, successValue: T)
  : Pair<AsyncCallback<void>, Promise<T>> {
  let waitResolve: Function | undefined = undefined;
  let waitReject: Function | undefined = undefined;
  const delayPromise = new Promise<T>((resolve, reject) => {
    waitResolve = resolve;
    waitReject = reject;
  })
  const asyncCallbackWarp = (error: BusinessError) => {
    if (error) {
      waitReject?.(error);
      callBack(error, failValue);
    } else {
      waitResolve?.(successValue);
      callBack(undefined, successValue);
    }
  }
  return new Pair(asyncCallbackWarp, delayPromise);
}

/**
 * callBackToPromise
 *
 */
export function callBackToPromise<T>(callBack: AsyncCallback<T>, failValue: T, successValue: T)
  : Pair<AsyncCallback<T>, Promise<T>> {
  let waitResolve: Function | undefined = undefined;
  let waitReject: Function | undefined = undefined;
  const delayPromise = new Promise<T>((resolve, reject) => {
    waitResolve = resolve;
    waitReject = reject;
  })
  const asyncCallbackWarp: AsyncCallback<T> = (error: BusinessError, data: T) => {
    if (error) {
      waitReject?.(error);
      callBack(error, failValue);
    } else {
      if (EmptyUtils.isUndefinedOrNull(data)) {
        Log.info(TAG, `callback data is null`);
        data = successValue;
      }
      waitResolve?.(data);
      callBack(undefined, data);
    }
  }
  return new Pair(asyncCallbackWarp, delayPromise);
}

/**
 * canScroll
 * 菜单栏是否可以滑动
 */
export function canScroll(optionLen: number, fontSizeScale: number, windowHeight: number): boolean {
  let tooManyItems = optionLen > 6; // //每项高48, 6项大于最大高度 300
  let caringMode = FontSizeScaleUtils.isGreaterThanStandard(fontSizeScale) // 关怀模式打开
  let windowTooSmall = windowHeight < 300; // 本体窗口太小(手机PAD上下分栏)
  return tooManyItems || caringMode || windowTooSmall;
}

/**
 * 通用重试函数
 * @param functionToRetry - 需要重试的函数
 * @param maxRetries - 最大重试次数
 * @param retryDelay - 重试延迟（毫秒）
 * @param checkFunction - 检查函数，用于验证函数执行结果是否满足条件
 * @returns - 函数的返回值
 */
export async function retryUtil<T>(functionToRetry: () => T | Promise<T>,
                               maxRetries: number = 3,
                               retryDelay: number = 400,
                               checkFunction?: (result: T) => boolean): Promise<T | undefined> {
  let retryCount = 0; // 当前重试次数

  // 确保至少执行一次尝试
  while (retryCount <= Math.max(maxRetries, 0)) {
    try {
      const result = await (functionToRetry() as Promise<T>);
      if (checkFunction && !checkFunction(result)) {
        throw new Error('Check function failed');
      }
      Log.info(TAG, `Success on attempt ${retryCount + 1}`);
      return result;
    } catch (error) { // 重试失败，打印日志、重试次数+1
      Log.error(TAG, `Error occurred: ${error.message}`);
      if (maxRetries > 0) { // 确保在maxRetries为0时不会输出重试信息
        Log.info(TAG, `Retrying... (Attempt ${retryCount + 1}/${maxRetries})`);
      }
      retryCount++;
      if (retryCount < maxRetries) {
        await wait(retryDelay);
      }
    }
  }
  return undefined;
}



