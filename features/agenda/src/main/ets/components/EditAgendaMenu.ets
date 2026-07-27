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

import { Log, ThrottleFunction, DeviceConfig } from '@app/common';
import { MenuDividerLine } from '@app/common.components/src/main/ets/MenuDividerLine';

const TAG: string = 'EditAgendaMenu'

@Extend(Menu)
function menuCommerceStyle(needCommerce: boolean) {
  .radius(needCommerce ? 8 : undefined)
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}

/**
 * 编辑日程菜单
 */
@Component
export struct EditAgendaMenu {
  @Consume navPathStack: NavPathStack;

  private isFirstRepeatAgenda: boolean = false;

  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 300;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  editThisAgenda: () => void = (): void => {
  };

  editThisAgendaAndBeyond: () => void = (): void => {
  };

  onClickEdit: () => void = (): void => {
  };

  @Builder
  ItemGroupBuilder() {
    MenuItem({ content: $r('app.string.this_agenda') })
      .onClick(() => {
        this.throttleFn(this.editThisAgenda);
      })
      .menuItemCommerceStyle(this.needCommerce)
    MenuDividerLine()

    MenuItem({ content: $r('app.string.this_agenda_and_beyond') })
      .onClick(() => {
        this.throttleFn(this.editThisAgendaAndBeyond);
      })
      .visibility(this.isFirstRepeatAgenda ? Visibility.None : Visibility.Visible)
      .menuItemCommerceStyle(this.needCommerce)
    MenuDividerLine()

    MenuItem({ content: $r('app.string.all_recurring_agendas') })
      .onClick(() => {
        this.throttleFn(this.onClickEdit);
      })
      .menuItemCommerceStyle(this.needCommerce)
  }

  build() {
    Menu() {
      this.ItemGroupBuilder();
    }
    .width(224)
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
    .menuCommerceStyle(this.needCommerce)
  }

  aboutToAppear() {
    Log.info(TAG, 'isshow')
  }

  private throttleFn(fn: () => void) {
    ThrottleFunction.instance().throttle(TAG, (): void => {
      fn();
    }, this.DELAY)
  }
}