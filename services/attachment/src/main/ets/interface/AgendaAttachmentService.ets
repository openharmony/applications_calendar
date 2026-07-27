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

import { Service } from '@app/common';
import { AttachmentInfo } from '../entity/AttachmentInfo';

export abstract class AgendaAttachmentService extends Service {
  /**
   * 通知存储复制文件到存储沙箱目录
   *
   * @param uri 文件uri
   * @returns 文件的沙箱路径
   */
  abstract addAttachment(uri: string): Promise<string>;

  /**
   * 根据沙箱路径拿到存储的uri路径并获取改uri的授权
   *
   * @param uri 沙箱路径
   * @returns 文件uri路径
   */
  abstract acquireAttachmentUri(uri: string): Promise<string>;

  /**
   * 批量插入附件
   *
   * @param attachmentList 附件集合
   * @param eventUuid 日程的uuid
   * @returns 结果值
   */
  abstract batchInsertAttachments(attachmentList: AttachmentInfo[], eventUuid: string): Promise<number>;

  /**
   * 插入单个附件
   *
   * @param attachment 附件对象
   * @param eventUuid 日程的uuid
   * @returns 结果值
   */
  abstract insertAttachment(attachment: AttachmentInfo, eventUuid: string): Promise<number>;

  /**
   * 删除附件
   *
   * @param attachmentUuids 附件uuid集合
   * @returns 结果值
   */
  abstract deleteAttachment(attachmentUuids: number[]): Promise<number>;

  /**
   * 查询附件
   *
   * @param eventUuid 日程的uuid
   * @returns 附件集合
   */
  abstract queryAttachmentList(eventUuid: string): Promise<AttachmentInfo[]>;

  /**
   * 判断附件有无变化
   *
   * @param newList 新的附件集合
   * @param oldList 老的附件集合
   * @param needUpdate 新老对比不一致的附件是否需要更新到数据库
   * @param eventUuid 日程的uuid
   * @returns 是否变化
   */
  abstract isAttachmentListChange(newList: AttachmentInfo[], oldList: AttachmentInfo[],
                                  needUpdate: boolean, eventUuid: string): boolean;
}