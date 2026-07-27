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

import { BigFontSize, FontSizeScaleUtils, ReminderUtil, Log } from '@app/common';
import {
  CustomizeReminderPicker,
  DEFAULT_REMINDER_OPTIONS,
  RadioListDialog,
  RadioListOption
} from '@app/common.components';

const TAG: string = 'DefaultReminder';

/**
 * 默认事件提醒时间弹框
 *
 * @since 2022-10-15
 */
@Component
export struct DefaultReminder {
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('language') @Watch('onLanguageChanged') language: string = '';

  @Link defaultValue: number;

  private defaultArray: number[] = [];

  // 单选框的所属群组名称
  private readonly RADIO_GROUP = 'defaultReminder';

  private selectableOptions: RadioListOption[] = [...DEFAULT_REMINDER_OPTIONS];

  onLanguageChanged(): void {
    this.adaptReminderLabelLanguage();
  }

  aboutToAppear() {
    this.adaptReminderLabelLanguage();
    this.addCustomizeOptions();
    this.sortOptions();
  }

  build() {
    Column() {
      RadioListDialog({
        title: $r('app.string.event_add_reminder'),
        options: this.selectableOptions,
        radioGroup: this.RADIO_GROUP,
        cancel: this.cancel,
        checkValue: $defaultValue,
        checkedIndexes: this.defaultArray,
        multiSelect: true,
        showConfirm: true,
        isShowCustomize: true,
        customizeTitleView: this.CustomizeTitleView,
        customizeContentView: this.CustomizeContentView,
        optionGenerator: this.generateNewOption,
        onConfirm: (value: number[]) => {
          Log.log(TAG, 'value: ' + value);
          this.transferValue(value);
        }
      })
    }
  }

  @Builder
  CustomizeTitleView() {
    Text($r('app.string.custom_repeat'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
        16
      ))
      .maxLines(2)
      .flexShrink(1)
      .layoutWeight(1)
      .fontWeight(FontWeight.Medium);
  }

  @Builder
  CustomizeContentView(onValueChangeCallback: (value: number) => void) {
    CustomizeReminderPicker({
      onValueChanged: (minute: number) => {
        onValueChangeCallback(minute);
      }
    });
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };

  // 子组件向父组件传值
  private transferValue: (value: number[]) => void = (value: number[]): void => {
  };

  private generateNewOption(minute: number): RadioListOption {
    return {
      value: minute,
      label: ReminderUtil.getReminderText(minute, false, this.language),
      checked: true,
      compId: `customize_reminder_${minute}`
    } as RadioListOption;
  }

  private addCustomizeOptions() {
    for (let index = 0; index < this.defaultArray.length; index++) {
      const minute = this.defaultArray[index];
      const findInOptions = this.selectableOptions.findIndex((option) => option.value === minute);
      if (findInOptions >= 0) {
        // 常规提醒
        continue;
      }
      // 自定义提醒，需要手动加到options中去
      const newOption = this.generateNewOption(minute);
      this.selectableOptions.push(newOption);
    }
  }

  private sortOptions() {
    // 按minute从小到大排序
    this.selectableOptions.sort((optionA: RadioListOption, optionB: RadioListOption) => {
      if (!optionA || !optionB) {
        return 0;
      }
      return optionA.value - optionB.value;
    });
  }

  private adaptReminderLabelLanguage(): void {
    for (let index = 0; index < this.selectableOptions.length; index++) {
      const option = this.selectableOptions[index];
      if (!option) {
        continue;
      }
      option.label = ReminderUtil.getReminderText(option.value, false, this.language);
    }
  }
}