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

/**
 * 导出回调 <T> 导出数据
 */
export interface ExportCallBack<T> {

  /**
   * 导出任务构建
   *
   * @returns 返回导出任务的任务id
   */
  onExportTaskBuild(jobId: number): void;

  /**
   * 开始导出
   *
   */
  onExportStarted(): void;


  /**
   * 导出进度变化回调
   * @param totalEventCount
   * @param processedEventCount
   */
  onExportProgressChanged(totalEventCount: number, processedEventCount: number): void

  /**
   * 导出失败
   *
   * @param errorCode 失败码
   */
  onExportFailed(errorCode: number): void;

  /**
   * 导出解析完成,导出单个日程text是string文本,导出vcs 是文件路径
   */
  onExportFinished(exportContent: T): void;

}