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

import { fileIo } from '@kit.CoreFileKit';
import { EmptyUtils } from '../../../util/EmptyUtils';
import { Log } from '../../common/Log';

export class FileIoUtil {
  static accessSync(filePath: string): boolean {
    return fileIo.accessSync(filePath);
  }

  static writeStringToFile(fileDir: string, fileName: string, fileContent: string, TAG: string): string {
    let writeStreamSync: fileIo.Stream | null = null;
    if (EmptyUtils.isEmptyString(fileDir)) {
      Log.warn(TAG, `writeStringToFile fileDir is empty`);
      return '';
    }
    const path = fileDir + '/' + fileName;
    try {
      writeStreamSync = fileIo.createStreamSync(path, 'w+');
      let number: number = writeStreamSync.writeSync(fileContent);
      Log.debug(TAG, 'writeStringToFile number: ' + number);
      return path;
    } catch (err) {
      Log.warn(TAG, `writeStringToFile error: ${err?.message}`);
    } finally {
      if (writeStreamSync) {
        writeStreamSync.closeSync();
      }
      Log.debug(TAG, 'writeStringToFile close sync');
    }
    return '';
  }
}

class ICalResultInfo {
  public resultcode: number = -1;
  public filename: string = '';
  public version: number = 0;
  public content: string = '';
}