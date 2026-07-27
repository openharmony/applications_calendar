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
  behaviorEvents,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  ThrottleFunction,
  traceEvents
} from '@app/common';
import {
  ComplexDialog,
  CheckboxList,
  CheckboxListOption
} from '@app/common.components';
import { SettingStore } from '../Storage';
import { ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import settingKeys from '../settingKeys';
import { emitter } from '@kit.BasicServicesKit';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WeekendsPage';

/**
 * 设置周末
 *
 * @since 2024-02-22
 */
@Component
export struct Weekends {
  // 持久化的周末数据
  @StorageLink('weekends') weekends: number[] = [];

  // 使用默认的周末所对应的持久化值
  private readonly DEFAULT_WEEKENDS_VALUE: number = -1;

  // 使用默认的周末所对应的持久化值
  private readonly DEFAULT_WEEKENDS_OPTIONS: number[] = [-1, 0, 6];

  private weekendSettingDivider: number = DeviceConfig.instance().config.weekendSettingDivider;

  // 默认配置项
  private defaultOptions: CheckboxListOption[] = [
    {
      label: $r('app.string.default_weekend'),
      value: -1,
      checked: true,
      compId: CompId.LOCAL_DEFAULT
    },
    {
      label: $r('app.string.Sunday'),
      value: 0,
      checked: true,
      disabled: true,
      compId: CompId.SUNDAY
    },
    {
      label: $r('app.string.Monday'),
      value: 1,
      disabled: true,
      compId: CompId.MONDAY
    },
    {
      label: $r('app.string.Tuesday'),
      value: 2,
      disabled: true,
      compId: CompId.TUESDAY
    },
    {
      label: $r('app.string.Wednesday'),
      value: 3,
      disabled: true,
      compId: CompId.WEDNESDAY
    },
    {
      label: $r('app.string.Thursday'),
      value: 4,
      disabled: true,
      compId: CompId.THURSDAY
    },
    {
      label: $r('app.string.Friday'),
      value: 5,
      disabled: true,
      compId: CompId.FRIDAY
    },
    {
      label: $r('app.string.Saturday'),
      value: 6,
      checked: true,
      disabled: true,
      compId: CompId.SATURDAY
    }
  ];

  // 周末配置项
  @State options: CheckboxListOption[] = this.defaultOptions.map((item: CheckboxListOption): CheckboxListOption => {
    return { label: item.label, value: item.value, compId: item.compId }
  });

  // 克隆选项
  optionClone = (options: CheckboxListOption[]): CheckboxListOption[] => {
    let newOptions: CheckboxListOption[] = [];
    for (let i = 0; i < options.length; i++) {
      let newOption: CheckboxListOption = {
        label: options[i].label,
        value: options[i].value,
        checked: options[i].checked,
        disabled: options[i].disabled
      };
      newOptions.push(newOption);
    }
    return newOptions;
  };

  // 选中项发生变化
  onChange(options: CheckboxListOption[]) {
    options = this.optionClone(options);
    let weekends: number[] = [];
    const isDefaultChecked: boolean | undefined =
      options.find(item => item.value === this.DEFAULT_WEEKENDS_VALUE)?.checked;

    // 勾选使用默认的周末
    if (isDefaultChecked) {
      weekends = this.DEFAULT_WEEKENDS_OPTIONS;
      // 修改单属性，避免整个list组件刷新，无法设置无障碍焦点
      options.forEach(option => {
        option.checked = this.DEFAULT_WEEKENDS_OPTIONS.includes(option.value as number);
        if (option.value != -1) {
          option.disabled = true;
        }
      });
      this.options = options;
    } else {
      options.forEach(option => {
        option.disabled = false;
      });
      weekends = options.filter(option => option.checked)
        .map(option => option.value as number);
      this.options = options;
    }
  }

  onConfirmClick() {
    if (this.options === undefined) {
      this.cancel();
      return;
    }
    const weekends = this.options.filter(option => option.checked)
      .map(option => option.value as number);
    hiTraceMeter.startTrace(traceEvents.weekendsSettingsChange, 0);
    ThrottleFunction.instance().debounce(TAG, () => {
      GlobalData.instance().set(GlobalDataKeys.WEEKENDS, weekends);
      SettingStore.INSTANCE.set(settingKeys.weekends, JSON.stringify(weekends));
      emitter.emit({ eventId: CommonInnerEvent.SETTINGS_WEEKENDS });
      hiTraceMeter.finishTrace(traceEvents.weekendsSettingsChange, 0);
    }, 180);
    let params: ReportHiEventParams = {
      WEEK_DAYS: weekends
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.settingsWeekSelectWeekend, params);
    this.cancel();
  }

  @Builder
  buildCheckBox() {
    CheckboxList({
      options: $options,
      optionClone: (options: CheckboxListOption[]) => this.optionClone(options),
      weekendSettingDivider: this.weekendSettingDivider,
      onChange: (options: CheckboxListOption[]): void => this.onChange(options)
    })
  }

  build() {
    Column() {
      ComplexDialog({
        title: $r('app.string.preferences_weekend_title'),
        compId: CompId.WEEKENDS,
        cancel: () => {
          this.cancel();
        },
        hasConfirmButton: true,
        confirm: () => {
          this.onConfirmClick();
        }
      }) {
        this.buildCheckBox()
      }
    }
  }

  aboutToAppear() {
    if (this.weekends.includes(this.DEFAULT_WEEKENDS_VALUE)) {
      this.options = this.defaultOptions;
    } else {
      this.options.forEach(option => {
        option.checked = this.weekends.includes(option.value as number);
      });
    }
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };
}
