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

import { behaviorEvents, DeviceConfig, deviceType, ReportHiEventParams } from '@app/common';
import { AllDayReminder } from '../../dialogs/AllDayReminder';
import { DefaultReminder } from '../../dialogs/DefaultReminder';
import { FromType, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';

@CustomDialog
export struct ReminderDialog {
  // 设备类型
  @StorageLink('deviceType') deviceType: number = deviceType.PHONE;

  controller: CustomDialogController = new CustomDialogController({ builder: null });

  @Link mIsAllDay: boolean;

  @Link value: number;

  @Prop type: number;

  @Prop defaultArray: number[] = [];

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 弹窗大小
  private dialogSize: ConstraintSizeOptions = {
    minWidth: 300,
    maxWidth: 400,
    maxHeight: (this.deviceType == deviceType.PHONE) ? 554 : 664
  };

  build() {
    Column() {
      if (this.mIsAllDay) {
        AllDayReminder({
          allDayValue: $value,
          defaultArray: this.defaultArray,
          cancel: () => {
            let params: ReportHiEventParams = {
              TYPE: this.type,
              FROM_TYPE: FromType.MONTH_VIEW
            };
            ReportUtil.reportBehaviorEvent(behaviorEvents.createAgendaCancelRemind, params);
            this.controller.close();
          },
          transferValue: this.transferValue,
        })
      } else {
        DefaultReminder({
          defaultValue: $value,
          defaultArray: this.defaultArray,
          cancel: () => {
            let params: ReportHiEventParams = {
              TYPE: this.type,
              FROM_TYPE: FromType.MONTH_VIEW
            };
            ReportUtil.reportBehaviorEvent(behaviorEvents.createAgendaCancelRemind, params);
            this.controller.close();
          },
          transferValue: this.transferValue,
        })
      }
    }
    .constraintSize(this.dialogSize)
  }

  aboutToAppear() {
    if (this.mIsAllDay) {
      // 增加无和自定义后，增加弹框高度，增加2行，避免自定义展开后撑满了弹框不协调
      this.dialogSize.maxHeight = (this.needCommerce ? (330 + 40 * 2) : (375 + 48 * 2));
    }
  }

  // 子组件向父组件传值
  private transferValue: (value: number[]) => void = (value: number[]): void => {
  };
}