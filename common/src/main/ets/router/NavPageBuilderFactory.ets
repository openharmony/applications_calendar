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

const TAG = 'NavPageBuilderFactory';

export class NavPageBuilderFactory {
  private static builderMap: Map<string, WrappedBuilder<[object]>> = new Map<string, WrappedBuilder<[object]>>();

  // Registering a builder by name.
  public static registerBuilder(builderName: string, builder: WrappedBuilder<[object]>): void {
    Log.info(TAG, `register router builderName ${builderName}`);
    NavPageBuilderFactory.builderMap.set(builderName, builder);
  }

  // Get builder by name.
  public static getBuilder(builderName: string): WrappedBuilder<[object]> | undefined {
    Log.info(TAG, `getBuilder: ${builderName}`);
    const builder = NavPageBuilderFactory.builderMap.get(builderName);
    if (!builder) {
      Log.info(TAG, 'not found builder ' + builderName);
      return undefined;
    }
    return builder;
  }
}
