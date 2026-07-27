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

import lazy taskpool from '@ohos.taskpool';
import lazy process from '@ohos.process';
import lazy common from '@ohos.app.ability.common';
import { GlobalThis } from '../data/GlobalThis';
import { BackGroundTaskUtil } from './backgroundTaskUtil';
import { DBInitializeInterceptor } from '../commoncapability/init/DBInitializeInterceptor';
import { DBUtils } from '../dao/DBUtils';
import { ProxyDBUtils } from '../dao/ProxyDBUtils';
import { PreferencesUtil } from '../default/util/preferences_util/PreferencesUtil';

export async function runTaskAsync(taskRunnable: Function, ...args: Object[]): Promise<Object> {
  if (isMainThread()) {
    const task: taskpool.Task = new taskpool.Task(taskRunnable, ...args);
    task.onReceiveData(notice);
    return await taskpool.execute(task, taskpool.Priority.MEDIUM) as Object;
  } else {
    return taskRunnable(...args);
  }
}

export function isMainThread(): boolean {
  return process.pid === process.tid;
}

export function reInitGlobalContextInTaskPool(context: common.UIAbilityContext) {
  if (!isMainThread()) {
    // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
    GlobalThis.getInstance().context = context;
    GlobalThis.getInstance().abilityStageContext = context;

    PreferencesUtil.init(context);
    DBUtils.INSTANCE.setInitializeInterceptor(new DBInitializeInterceptor());
    ProxyDBUtils.INSTANCE.setInitializeInterceptor(new DBInitializeInterceptor());
  }
}

/**
 * 回调事件
 * @param tag resultSet的tag
 * @param isAdd 添加/移除
 */
export function notice(tag: string, isAdd: boolean): void {
  if (isAdd) {
    BackGroundTaskUtil.addTask(tag);
  } else {
    BackGroundTaskUtil.removeTask(tag);
  }
  return;
}

/**
 * 轮询方法
 */
@Concurrent
export function pollForCompletion(
  checkComplete: () => boolean,
  interval: number = 100, // 轮训间隔（ms）
  maxAttempts: number = 600 // 最大轮询次数
): Promise<boolean> {
  let attempts = 0;

  const poll = (): Promise<boolean> => {
    attempts=attempts+1;
    if (attempts > maxAttempts) {
      return Promise.reject(new Error('Polling exceeded maximum attempts'));
    }
    try {
      const isComplete = checkComplete();
      if (isComplete) {
        return Promise.resolve(true);
      } else {
        return new Promise((resolve) => {
          setTimeout(() => resolve(poll()), interval);
        });
      }
    } catch (error) {
      return Promise.reject(error);
    }
  };

  return poll();
}