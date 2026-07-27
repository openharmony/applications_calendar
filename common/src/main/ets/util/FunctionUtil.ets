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
import HashMap from '@ohos.util.HashMap';
import { Log } from '../default/common/Log';

/**
 * class for common js function
 *
 * @since 2022-03-01
 */

export class ThrottleFunction {
  private static _instance: ThrottleFunction = new ThrottleFunction();
  private queryRunningList: string[] = []; // 正在执行的查询
  private queryPendingList: string[] = []; // 正在等待的查询
  private runningMap: HashMap<string, number> = new HashMap(); //防抖tag表


  static instance(): ThrottleFunction {
    return ThrottleFunction._instance;
  }

  reset() {
    this.runningMap.clear();
  }

  /**
   * 限流器，用于防止快速点击,在第一次执行后,delay时间内所有执行都将被丢弃
   *
   * @param func 要限制调用的方法
   * @param delay 限流间隔时间，默认300ms
   */
  throttle(tag: string, task: Function, delay: number = 300): void {
    if (this.runningMap.get(tag)) {
      return;
    }

    task();
    this.runningMap.set(tag, -1);
    const timeoutId = setTimeout((): void => {
      this.runningMap.remove(tag)
      clearTimeout(timeoutId);
    }, delay);
  }

  /**
   * 防抖,将执行放在delay时间后触发,delay时间内再次执行则取消之前的执行重新设置delay时间后触发最新的执行
   *
   * @param func 要限制调用的方法
   * @param delay 防抖间隔时间，默认300ms
   */
  debounce(tag: string, task: Function, delay: number = 300): void {
    if (this.runningMap.get(tag)) {
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);
    }
    const timerId = setTimeout((): void => {
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);
      task();
    }, delay);
    this.runningMap.set(tag, timerId);
  }

  /**
   * 防抖2,区别在于第一次的执行会立即触发,之后的执行会在delay时间后触发,如果delay时间内再次触发则取消之前的触发并在delay时间后触发最新的执行
   *
   * @param func 要限制调用的方法
   * @param delay 防抖间隔时间，默认300ms
   */
  debounceInstant(tag: string, task: Function, delay: number = 300): void {
    if (this.runningMap.get(tag)) {
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);
      const timerId = setTimeout((): void => {
        clearTimeout(this.runningMap.get(tag));
        this.runningMap.remove(tag);
        task();
      }, delay);
      this.runningMap.set(tag, timerId);
    } else {
      task();
      const timerId = setTimeout((): void => {
        clearTimeout(this.runningMap.get(tag));
        this.runningMap.remove(tag);
      }, delay);
      this.runningMap.set(tag, timerId);
    }
  }

  /**
   * 查询数据库时，防止重复查询，仅用于数据库查询相关函数
   * 涵盖数据库修改、删除相关函数勿用
   *
   * @param tag 标识符
   * @param task 要限制调用的方法
   */
  throttleQuery(tag: string, task: () => Promise<void>): boolean {
    const TAG = 'throttleQuery';

    if (this.queryPendingList.indexOf(tag) >= 0) {
      Log.info(TAG, `${tag} already pending`);
    }

    if (this.queryRunningList.indexOf(tag) >= 0) {
      Log.info(TAG, `${tag} already running`);
      const idx = this.queryPendingList.indexOf(tag);
      if (idx < 0) {
        Log.info(TAG, `${tag} add to pending`);
        this.queryPendingList.push(tag);
      }
      return false;
    }

    Log.info(TAG, `${tag} launch task`);
    this.queryRunningList.push(tag);
    const timer = setTimeout(() => {
      // 60秒任务最大执行时间，超时后 runningList 中清除任务
      Log.info(TAG, `${tag} task timeout`);
      this.queryRunningList = this.queryRunningList.filter(item => item !== tag);
      if (this.queryPendingList.indexOf(tag) >= 0) {
        // 如果等待队列中还有该任务，继续执行
        Log.info(TAG, `${tag} task timeout throttleQuery by pending`);
        this.throttleQuery(tag, task);
      }
    }, 60 * 1000);

    task().then(() => {
      Log.info(TAG, `${tag} finish`);
      clearTimeout(timer);
      this.queryRunningList = this.queryRunningList.filter(item => item !== tag); // 在 runningList 里面清除自己
      if (this.queryPendingList.indexOf(tag) >= 0) {
        Log.info(TAG, `${tag} task finish launch pending`);
        // 先在 pendingList 中清除自己，然后重新发起 pending task
        this.queryPendingList = this.queryPendingList.filter(item => item !== tag);
        setTimeout(() => {
          // 如果等待队列中还有该任务，继续执行
          Log.info(TAG, `${tag} throttleQuery by pending`);
          this.throttleQuery(tag, task);
        }, 0); // 防止堆栈溢出
      }
    })

    return true;
  }
}