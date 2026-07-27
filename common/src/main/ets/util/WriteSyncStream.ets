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
import { Log } from '../default/common/Log';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'WriteSyncStream';

export class WriteSyncStream {
  private stream: fileIo.Stream | undefined = undefined;

  create(path: string, mode: string): boolean {
    try {
      this.stream = fileIo.createStreamSync(path, mode);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'createStreamSync', err);
    }
    return false;
  }

  closeSync() {
    try {
      if (this.stream) {
        this.stream.closeSync();
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'closeSync', err);
    }
  }

  writeSync(str: string): number {
    if (!this.stream) {
      return -1;
    }
    try {
      return this.stream.writeSync(str);
    } catch (err) {
      Log.logErrorMsg(TAG, 'writeSync', err);
      return -1;
    }
  }
}