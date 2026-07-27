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
import { ImportData } from './ImportData';
import { SimpleAccount } from './SimpleAccount';

/**
 * 导入回调
 *
 */
export interface ImportCallBack {

  /**
   * 导入任务构建
   *
   * @returns 返回导入任务的任务id
   */
  onImportTaskBuild(jobId: number): void;

  /**
   * 导入开始
   */
  onImportStarted(): void;

  /**
   *
   * 某些日程解析失败
   * @returns 是否终止整个导入任务
   */
  onSomeEventsParseFailed(): boolean;

  /**
   * 导入的vcs解析完成,弹窗
   * @param importData 展示的数据
   * @returns saveAction 用户保存动作 isSave true 保存,false 取消
   */
  onImportParsed(importData: ImportData, saveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void): void;

  /**
   * 导入失败
   * @param errorCode
   */
  onImportFailed(errorCode: number): void;

  /**
   * 导入完成
   */
  onImportFinished(): void;

  /**
   * 开始保存
   */
  onSaveStart(): void;

  /**
   * 保存失败
   * @param errorCode
   */
  onSaveFailed(errorCode: number): void;

  /**
   * 保存成功
   */
  onSaveSuccess(): void;

}