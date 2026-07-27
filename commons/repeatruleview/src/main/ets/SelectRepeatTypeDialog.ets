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

import { CompId, DeviceConfig } from '@app/common';
import { RadioListDialog, RadioListDialogOption, RadioListStyle } from '@app/common.components';
import { RepeatType } from '@app/feature.repeatrule/src/main/ets/Constants';
import { Callback } from '@ohos.base';

@Component
export struct SelectRepeatTypeDialog {
  supportTypes: RepeatType[] = [
    RepeatType.NONE,
    RepeatType.DAILY,
    RepeatType.WEEKLY,
    RepeatType.MONTHLY,
    RepeatType.YEARLY,
    RepeatType.LUNAR_YEARLY,
    RepeatType.CUSTOM];

  @State selectValue: RepeatType = RepeatType.NONE;

  private dialogOptions: RadioListDialogOption[] = [];

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  callback: Callback<RepeatType> = () => {
  };

  aboutToAppear(): void {
    this.supportTypes?.forEach((type: RepeatType) => {
      this.dialogOptions.push({ label: this.getLabelByRepeatType(type), value: type, compId: this.getCompId(type) });
    });
  }

  build() {
    RadioListDialog({
      title: $r('app.string.event_add_repeat'),
      options: this.dialogOptions,
      compId: CompId.EVENT_ADD_REPEAT,
      checkValue: this.selectValue,
      style: RadioListStyle.Menu,
      onChange: (value: RepeatType) => {
        this.callback(value);
      },
      cancel: () => {
      }
    })
  }

  private getLabelByRepeatType(type: RepeatType): ResourceStr {
    switch (type) {
      case RepeatType.NONE:
        return $r('app.string.no_repeat');
      case RepeatType.DAILY:
        return $r('app.string.every_day_repeat');
      case RepeatType.WEEKLY:
        return $r('app.string.every_week_repeat');
      case RepeatType.MONTHLY:
        return $r('app.string.every_month_repeat');
      case RepeatType.YEARLY:
        return $r('app.string.every_year_repeat');
      case RepeatType.CUSTOM:
        return $r('app.string.custom_repeat');
      case RepeatType.LUNAR_YEARLY:
        return $r('app.string.every_lunar_year_repeat');
      default:
        return '';
    }
  }

  private getCompId(type: RepeatType): string {
    switch (type) {
      case RepeatType.NONE:
        return CompId.NO_REPEAT;
      case RepeatType.DAILY:
        return CompId.EVERY_DAY_REPEAT;
      case RepeatType.WEEKLY:
        return CompId.EVERY_WEEK_REPEAT;
      case RepeatType.MONTHLY:
        return CompId.EVERY_MONTH_REPEAT;
      case RepeatType.YEARLY:
        return CompId.EVERY_YEAR_REPEAT;
      case RepeatType.LUNAR_YEARLY:
        return CompId.EVERY_LUNAR_YEAR_REPEAT;
      case RepeatType.CUSTOM:
        return CompId.CUSTOM_REPEAT;
      default:
        return '';
    }
  }
}