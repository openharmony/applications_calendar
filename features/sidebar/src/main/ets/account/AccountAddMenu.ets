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


import {
  CommonInnerEvent,
  GlobalThis,
  CompId,
  DeviceConfig,
  ReportUtil,
  behaviorEvents,
} from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { MenuDividerLine } from '@app/common.components/src/main/ets/MenuDividerLine';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';

const TAG: string = 'AccountAddMenu'

/**
 * 侧边栏添加
 * - 新的日历账户
 * - 添加课程表
 */
@Extend(Menu)
function menuCommerceStyle(needCommerce: boolean) {
  .radius(needCommerce ? 8 : undefined)
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}


@Component
export struct AccountAddMenu {
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  build() {
    Menu() {
      MenuItem({ content: $r('app.string.addAccount') })
        .onClick((event => {
          emitter.emit({ eventId: CommonInnerEvent.EVENT_ACCOUNT_DEFAULT_PAGE_OPEN });
        }))
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.addAccount')))
        .id(CompId.ADD_CALENDAR)
        .menuItemCommerceStyle(this.needCommerce)
      MenuDividerLine()
      MenuItem({ content: $r('app.string.import_agenda') })
        .onClick((event => {
          emitter.emit({ eventId: CommonInnerEvent.EVENT_IMPORT_AGENDA_PAGE_OPEN });
          ReportUtil.reportBehaviorEvent(behaviorEvents.importAgenda);
        }))
        .accessibilityText($r('app.string.import_agenda'))
        .id(CompId.IMPORT_AGENDA)
        .menuItemCommerceStyle(this.needCommerce)
    }.width(this.needCommerce ? 228 : 224)
    .menuCommerceStyle(this.needCommerce)
  }

  aboutToAppear() {
  }
}