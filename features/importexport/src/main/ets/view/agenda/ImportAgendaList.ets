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
import { AgendaEventInfo } from '@app/common/index';
import { ImportAgendaDetail } from './ImportAgendaDetail';

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

const TAG: string = 'ImportAgendaList';

/**
 * 日程列表适应分栏的父组件
 *
 * @since 2022-09-20
 */
@Component
export struct ImportAgendaList {
  @Link agendaList: AgendaEventInfo[];

  @Link mHeadEvents: AgendaEventInfo[];

  @Link accountColor: number;

  build() {
    Row() {
      Column() {
        if (!this.mHeadEvents || this.mHeadEvents.length === 0) {
          ImportAgendaDetail({
            info: undefined,
            accountColor: undefined
          })
        } else {
          ForEach(this.mHeadEvents, (item: AgendaEventInfo, index: number) => {
            ImportAgendaDetail({
              info: item,
              accountColor: this.accountColor
            })
              .margin({ bottom: index === this.mHeadEvents.length - 1 ? 0 : 8 })
          })
        }
      }
    }
  }
}