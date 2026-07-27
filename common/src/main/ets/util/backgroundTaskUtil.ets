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
import lazy { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { Log } from '../default/common/Log';

const TAG: string = 'BackGroundTaskUtil';
const reason: string = 'task need delay';
const timeout: number = 3000; // 短时任务3s后取消

/**
 * 进入后台时，进程会被冻结，导致申请的资源不被释放
 * 通过增加保活任务在后台释放掉这些资源
 * 保活任务限制：
 * 1.一个应用同一时刻最多申请3个短时任务
 * 2.单日（24小时内）配额默认为10分钟，单次配额最大为3分钟，低电量时单次配额默认为1分钟，配额消耗完后不允许再申请短时任务
 * 3.仅当应用在后台时，对应用下的短时任务计时；同一个应用下的同一个时间段的短时任务，不重复计时
 */
export class BackGroundTaskUtil {
  private static tasks: Set<string> = new Set(); // 需要保活的任务：任务名+时间戳，防止同名任务
  private static id: number = -1; // 短任务Id

  /**
   * 添加后台保活任务
   * @param task 任务名+时间戳
   */
  public static addTask(task: string): void {
    BackGroundTaskUtil.tasks.add(task);
    Log.info(TAG, `tasks.length after add: ${BackGroundTaskUtil.tasks.size}`);
    return;
  }

  /**
   * 任务完成后去掉后台保活任务
   * @param task 任务名+时间戳
   */
  public static removeTask(task: string): void {
    BackGroundTaskUtil.tasks.delete(task);
    Log.info(TAG, `tasks.length after remove: ${BackGroundTaskUtil.tasks.size}`);
    try {
      if (BackGroundTaskUtil.id !== -1 && BackGroundTaskUtil.tasks.size === 0) {
        Log.info(TAG, `cancel task, id: ${BackGroundTaskUtil.id}`);

        backgroundTaskManager.cancelSuspendDelay(BackGroundTaskUtil.id); // 取消短时任务
        BackGroundTaskUtil.id = -1;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, `remove task`, error);
    }
    return;
  }

  /**
   * 进入后台时判断是否需要保活
   */
  public static startTask(): void {
    if (BackGroundTaskUtil.tasks.size === 0) {
      Log.info(TAG, 'No tasks need to continue');
      return;
    }
    try {
      Log.info(TAG, 'start Delay');
      const info: backgroundTaskManager.DelaySuspendInfo = backgroundTaskManager.requestSuspendDelay(reason, () => {
        // 回调函数。应用申请的短时任务即将超时，通过此函数回调应用，执行一些清理和标注工作，并取消短时任务 不需要取消短时任务，杀掉进程释放resultSet
        Log.warn(TAG, 'suspend delay task will timeout');
      });
      BackGroundTaskUtil.id = info.requestId;
    } catch (error) {
      Log.logErrorMsg(TAG, `start task`, error);
    } finally {
      setTimeout(() => {
        // 查询任务一般在2s内即可完成释放resultSet，大致给出3s关闭短时任务
        BackGroundTaskUtil.cancelTask();
      }, timeout);
    }
    return;
  }

  /**
   * 进入前台时退出保活，不然短时任务暂停，后续可保活时间缩短
   */
  public static cancelTask(): void {
    try {
      if (BackGroundTaskUtil.id !== -1) {
        Log.info(TAG, `cancel task, id: ${BackGroundTaskUtil.id}`);
        backgroundTaskManager.cancelSuspendDelay(BackGroundTaskUtil.id); // 取消短时任务
        BackGroundTaskUtil.id = -1;
      }
    } catch (error) {
      Log.logErrorMsg(TAG, `cancel task`, error);
    }
    return;
  }
}