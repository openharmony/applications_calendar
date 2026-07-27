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
import { CommonInnerEvent } from '@app/common';
import { DialogControllerOptions } from '@app/common/src/main/ets/default/common/declare';
import { emitter } from '@kit.BasicServicesKit';

export enum AccountMenuOpt {
  VIEW, // 查看
  DELETE, // 删除
  CREATE, // 创建
}

export const DEFAULT_ACCOUNT_MENU_OPTS: AccountMenuOpt[] = [
  AccountMenuOpt.VIEW,
  AccountMenuOpt.DELETE,
  AccountMenuOpt.CREATE
];

// 日历账户菜单归一组件，用于如右键弹出的菜单场景
@Component
export struct AccountMenu {
  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 菜单选项
  menuOpts: Array<AccountMenuOpt> = DEFAULT_ACCOUNT_MENU_OPTS;

  menuText: Array<ResourceStr> = [
    $r('app.string.agenda_menu_item_view'),
    $r('app.string.delete_label'),
    $r('app.string.addAccount'),
  ];

  onViewHandle: () => void = (): void => {
  };

  onDeleteHandle: () => void = (): void => {
  };

  onCreateHandle: () => void = (): void => {
    emitter.emit({ eventId: CommonInnerEvent.EVENT_ACCOUNT_DEFAULT_PAGE_OPEN });
  };

  // 菜单选择回调
  onMenuChosen: (op: AccountMenuOpt, id: number) => void = (op: AccountMenuOpt, id: number) => {
  };

  handler: Array<() => void> = [
    () => {
    // 查看
      this.onViewHandle();
    },
    () => {
    // 删除
      this.onDeleteHandle();
    },
    () => {
    // 创建
      this.onCreateHandle();
    }
  ];

  aboutToAppear() {

  }

  aboutToDisappear(): void {

  }

  build() {
    Menu() {
      ForEach(this.menuOpts, (opt: AccountMenuOpt) => {
        if (opt !== AccountMenuOpt.CREATE) {
          MenuItem({ content: this.menuText[opt] })
            .onClick(() => {
              this.handler[opt]();
            })
        } else {
          MenuItemGroup() {
            MenuItem({ content: this.menuText[opt] })
              .onClick(() => {
                this.handler[opt]();
              })
          }
        }
      })
    }
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
  }
}