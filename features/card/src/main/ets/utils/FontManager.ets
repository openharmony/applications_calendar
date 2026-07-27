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

import { font } from '@kit.ArkUI';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG: string = 'FontManager';

export class FontManager {
  public static registerFont(fontId: string, resource: Resource) {
    if (!fontId || !resource) {
      return;
    }

    try {
      font.registerFont({
        familyName: fontId,
        familySrc: resource
      });
    } catch (err) {
      Log.logErrorMsg(TAG, `registerFont ${fontId}`, err);
    }
  }
}