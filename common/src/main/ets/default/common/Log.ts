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

import hilog from '@ohos.hilog';

const TAG: string = 'Calendar';
const MAX_LOG_SPACE = 4;
const DOMAIN_ID: number = 0x09732;

/**
 * Global Log class
 *
 * @since 2022-03-01
 */
export class Log {
  public static log(classTag: string, msg: string): void {
    hilog.info(DOMAIN_ID, TAG, '%{public}s:%{public}s', classTag, msg);
  }

  public static debug(classTag: string, msg: string): void {
    hilog.debug(DOMAIN_ID, TAG, '%{public}s:%{private}s', classTag, msg);
  }

  public static info(classTag: string, msg: string): void {
    hilog.info(DOMAIN_ID, TAG, '%{public}s:%{public}s', classTag, msg);
  }

  public static warn(classTag: string, msg: string): void {
    hilog.warn(DOMAIN_ID, TAG, '%{public}s:%{public}s', classTag, msg);
  }

  public static error(classTag: string, msg: string): void {
    hilog.error(DOMAIN_ID, TAG, '%{public}s:%{public}s', classTag, msg);
  }

  public static hilog(classTag: string, format: string, ...args): void {
    hilog.info(DOMAIN_ID, TAG, classTag + ':' + format, args);
  }

  public static hilogDebug(classTag: string, format: string, ...args): void {
    hilog.debug(DOMAIN_ID, TAG, classTag + ':' + format, args);
  }

  public static hilogInfo(classTag: string, format: string, ...args): void {
    hilog.info(DOMAIN_ID, TAG, classTag + ':' + format, args);
  }

  public static hilogWarn(classTag: string, format: string, ...args): void {
    hilog.warn(DOMAIN_ID, TAG, classTag + ':' + format, args);
  }

  public static hilogError(classTag: string, format: string, ...args): void {
    hilog.error(DOMAIN_ID, TAG, classTag + ':' + format, args);
  }

  public static stringify(data: object): string {
    return JSON.stringify(data, null, MAX_LOG_SPACE);
  }

  public static logErrorMsg(logTag: string, methodName: string, error?: ESObject): void {
    Log.error(logTag, `${methodName} error msg ${error?.message} code ${error?.code}`);
  }
}


