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

import { ImportantCardView } from '@app/feature.card/src/main/ets/importantCard/view/pages/ImportantCardView2x4';

let storage: LocalStorage = new LocalStorage();

/**
 * 重要日卡片
 */
@Entry(storage)
@Component
struct ImportantCard2x4 {
  build() {
    Column() {
      ImportantCardView()
    }
    .width('100%')
    .height('100%')
    .accessibilityLevel('no')
  }
}