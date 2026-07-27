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

export class FileObj {
  public name: string = '';
  public size: number = 0;
  public targetUri: string = '';
  public errorCode: AttachmentErrorCode = AttachmentErrorCode.SUCCESS
}

export enum AttachmentErrorCode {
  /**
   * 通用成功类型
   */
  SUCCESS = 0,

  /**
   * 通用失败类型
   */
  FAILED = 1,

  /**
   * 通用类型-参数错误
   */
  PARAMS_ERROR = 2,

  /**
   * 创建附件目录失败
   */
  CREATE_DIR_FAILED = 3,

  /**
   * 文件本地拷贝失败-无文件权限
   */
  NO_PERMISSION = 4,

  /**
   * 文件本地拷贝失败-拷贝出现IO异常
   */
  IO_EXCEPTION = 5,

  /**
   * 文件本地拷贝失败-设备存储空间不够
   */
  STORAGE_FULL = 6,

  /**
   * 文件本地拷贝失败-单个附件大小超出上限
   */
  SIZE_OVER_LOAD = 7,

  /**
   * 文件不存在
   */
  ATTACHMENT_NOT_EXIST = 8,

  /**
   * 文件超过最大个数
   */
  MAX_COUNT = 9,

  /**
   * 文件总大小超过最大限制
   */
  MAX_SIZE = 10,
}