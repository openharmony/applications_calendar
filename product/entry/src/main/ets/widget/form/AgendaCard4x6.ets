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

import { AgendaCardView4x6 } from '@app/feature.card/src/main/ets/agendaCard/view/AgendaCardView4x6';

const storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct AgendaCard4x6 {
  build() {
    Column() {
      AgendaCardView4x6()
    }.width('100%').height('100%')
  }
}