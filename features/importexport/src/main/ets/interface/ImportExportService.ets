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

import { ExportCallBack } from './ExportCallBack';
import { ImportCallBack } from './ImportCallBack';
import { SimpleAccount } from './SimpleAccount';
import { ShareEventTextBean } from './ShareEventTextBean';
import { ShareEventVcsBean } from './ShareEventVcsBean';
import { Service } from '@app/common/src/main/ets/service/framework/Service';

export abstract class ImportExportService extends Service {
  constructor() {
    super('ImportExportService')
  }

  /**
   * 导出单个日程的text
   * @param eventId
   * @param exportListener
   */
  abstract exportTextByEvent(eventId: number, exportCallBack: ExportCallBack<ShareEventTextBean>);

  /**
   * 导出日程的Vcs
   * @param eventIds
   * @param exportListener<string> 返回构造的vcs文件路径
   * @param isBatch 是否批量,分享详情 false,日程选择页true
   */
  abstract exportVcsByEvents(eventIds: Array<number>, exportCallBack: ExportCallBack<ShareEventVcsBean>,
                             isBatch: boolean);


  /**
   * 导出日历账户
   * @param simpleAccount
   * @param exportCallBack
   */
  abstract exportVcsByCalendarAccount(simpleAccount: SimpleAccount,
                                      exportCallBack: ExportCallBack<ShareEventVcsBean>);

  /**
   * 导入日历账户或日程
   * @param uri vcs文件 或uri
   * @param importListener
   * @param 导入节假日的时候的国家码
   */
  abstract import(uri: string, importCallBack: ImportCallBack, countryCode?: string);

  /**
   * 取消任务
   *
   * @param taskId 任务id
   */
  abstract cancelTaskByTaskId(taskId: number);
}




