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
import { util } from '@kit.ArkTS';
import { UTF_8 } from './CharsetUtil';

/**
 * base64工具类
 */

const TAG: string = 'Base64Util';

export function encode(input: string): string {
  let data = new util.TextEncoder('utf-8').encodeInto(input);
  const encode: Uint8Array = new util.Base64Helper().encodeSync(data);
  let textDecoder = util.TextDecoder.create(UTF_8, { ignoreBOM: true });
  const content = textDecoder.decodeWithStream(encode, { stream: false });
  return content;
}
