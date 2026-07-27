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


/*
 * 导出类型
 */
export enum ExportType {
  ACCOUNT_EXPORT = 10000,
  EVENTS_EXPORT = 10001,
  EVENT_VCS_EXPORT = 10002,
  EVENT_TEXT_EXPORT = 10003,
}

/*
 * 导入类型
 */
export enum ImportType {
  ACCOUNT_IMPORT = 20000,
  EVENTS_IMPORT = 20001,
  EVENT_IMPORT = 20002,
}

/*
 * 分享类型
 */
export enum ShareType {
  ONLY_TEXT,
  ONLY_VCS,
  TEXT_AND_VCS,
}

/*
 * 分享类型
 */
export enum ShareFileFormat {
  VCS = '.vcs',
  ICS = '.ics',
}

/*
 * 错误码
 */
export enum ImportExportErrorCode {
  //导入
  IMPORT_FILE_URI_ILLEGAL = 30001,
  IMPORT_FILE_CONTENT_EMPTY = 30002,
  IMPORT_PARSING_FAILED = 30003,
  IMPORT_IS_RUNNING = 30004,

  IMPORT_INSERT_ACCOUNT_FAILED = 30005,

  IMPORT_ACCOUNT_NOT_EXIST = 30006,

  IMPORT_INSERT_EVENTS_FAILED = 30007,

  IMPORT_INSERT_REMINDS_FAILED = 30008,

  IMPORT_INSERT_NO_EVENTS = 30009,

  // 导入时传入的SimpleAccount为空
  IMPORT_ACCOUNT_IS_NULL = 30010,

  // 用户点击取消
  IMPORT_USER_CANCEL = 30011,

  // 任务已经取消,仍然被调用执行
  IMPORT_TASK_HAS_CANCELED = 30012,

  // 保存成功的event的数量少于需要保存的
  IMPORT_INSERT_EVENT_COUNT_NOT_MATCH = 30013,

  //导出
  ACCOUNT_ID_ILLEGAL = 40001,
  NO_SUCH_ACCOUNT = 40002,

  EXPORT_TYPE_NO_MATCH = 40003,
  EXPORT_EVENTS_ILLEGAL = 40004,
  EXPORT_EVENT_ID_ILLEGAL = 40005,
  EXPORT_NO_SUCH_EVENT = 40006,
  EXPORT_NO_SUCH_EVENTS = 40007,
  EXPORT_FILE_PATH_INVALID = 40008,
  EXPORT_NO_MEMORY = 40009,
  EXPORT_BUILD_FILE_FAILED = 40010,
  EXPORT_USER_CANCEL = 40011,
}