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

import { MonthCardView4x4 } from '@app/feature.card/src/main/ets/monthCard/view/pages/MonthCardView4x4';

let storage = new LocalStorage();

@Entry(storage)
@Component
struct MonthCard4x4 {
  build() {
    Column() {
      MonthCardView4x4()
    }
    .width('100%')
    .height('100%')
    .accessibilityLevel('no')
  }
}