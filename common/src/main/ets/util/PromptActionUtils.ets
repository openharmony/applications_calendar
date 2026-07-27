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
import lazy { promptAction } from '@kit.ArkUI';
import { Log } from '../default/common/Log';

/**
 * 同步等待
 *
 * @param message toast信息
 */
const TAG = 'PromptActionUtils'

export function showToast(message: ResourceStr): void {
  try {
    promptAction.showToast({
      message
    })
  } catch (error) {
    Log.error(TAG, `showToast,error is ${error?.message}`);
  }
}