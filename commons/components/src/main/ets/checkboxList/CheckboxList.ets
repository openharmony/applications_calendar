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

import { BigFontSize, DeviceConfig, GlobalDataKeys, GlobalThis } from '@app/common';
import lazy { accessibility } from '@kit.AccessibilityKit';

export interface CheckboxListOption {
  label: ResourceStr;
  value: string | number;
  checked?: boolean;
  disabled?: boolean;
  compId?: string;
}

/**
 * 多选框组列表自定义组件
 *
 * @since 2022-07-29
 */
@Component
export struct CheckboxList {
  // 选项
  @Watch('onOptionsChange') @Link options: CheckboxListOption[];

  // 记录每次发布options变更前的操作变化，处理快速点击的场景
  private tempOptions: CheckboxListOption[] = [];

  private isCustomWeekList: boolean = false;

  @Prop weekendSettingDivider: number = 18;

  // 克隆选项
  optionClone = (options: CheckboxListOption[]): CheckboxListOption[] => {
    return options;
  };

  /**
   *  单个选项发生变化
   *
   * @param value 复选框值
   * @param isOn 复选框选中态
   */
  onSingleItemChange(value: string | number, isOn: boolean): void {
    let temp: CheckboxListOption | undefined = this.tempOptions.find(option => (option.value === value));
    if (temp !== null && temp !== undefined) {
      temp.checked = isOn;
    }
    this.emitOptions(this.tempOptions)
  };

  onOptionsChange() {
    this.tempOptions = this.optionClone(this.options);
  }

  aboutToAppear() {
    this.onOptionsChange(); // 首次不触发变更，手动调用一次
  }

  build() {
    List() {
      ForEach(this.options, (option: CheckboxListOption) => {
        ListItem() {
          OptionItem({
            label: option.label,
            value: option.value,
            compId: option.compId ? option.compId : '',
            isOn: option.checked ?? false,
            disabled: option.disabled ?? false,
            onChange: (value: string | number, isOn: boolean): void => this.onSingleItemChange(value, isOn),
            isCustomWeekList: this.isCustomWeekList
          })
        }
      }, (option: CheckboxListOption) => JSON.stringify(option))
    }
    .backgroundColor(Color.Transparent)
    .scrollBar(BarState.Off)
    .divider({
      strokeWidth: '2px',
      color: $r('sys.color.comp_divider'),
      startMargin: this.isCustomWeekList ? 8 : 18,
      endMargin: this.isCustomWeekList ? 8 : this.weekendSettingDivider
    })
  }

  // 多选框列表发生变化
  private onChange = (options: CheckboxListOption[]) => {
  };

  // 发布options变更
  private emitOptions: (options: CheckboxListOption[]) => void = (options: CheckboxListOption[]): void => {
    this.onChange(options);
  };
}

@Component
struct OptionItem {
  // 选中态
  @State isOn: boolean = true;

  // 是否禁止操作
  @State disabled: boolean = false;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) isOpenAccessibilityScreenReader: boolean = false;

  // 设置项名称
  private label: ResourceStr = '';

  private compId: string = '';

  // 复选框对应的值，每项对应的值唯一
  private value: number | string = 0;

  private itemMargin = DeviceConfig.instance().config.popUpItemMargin;

  private itemBorderRadius = DeviceConfig.instance().config.popUpItemBorderRadius;

  private isCustomWeekList: boolean = false;

  /**
   * 组件刷新会导致无障碍丢焦点，重新设置
   */
  setAccessibilityFocus() {
    if (!this.isOpenAccessibilityScreenReader) {
      return;
    }
    setTimeout(() => {
      let eventInfo: accessibility.EventInfo = ({
        type: 'requestFocusForAccessibility',
        bundleName: 'com.openharmony.calendar',
        triggerAction: 'common',
        customId: 'my_checkbox_item_' + this.value
      });

      accessibility.sendAccessibilityEvent(eventInfo);
    }, 100);
  }

  getAccessibilityText(): string {
    let label = '';
    if (typeof this.label === 'string') {
      label = String(this.label);
    } else {
      label = GlobalThis.getResourceStr(this.label);
    }
    let checkText = '';
    if (this.isOn) {
      checkText = GlobalThis.getResourceStr($r('app.string.checkbox_checked'));
    } else {
      checkText = GlobalThis.getResourceStr($r('app.string.checkbox_not_checked'));
    }
    return label + checkText;
  }

  onChangePadding(): number {
    return this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_3X ? 24 :
      this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_2X ? 20 :
        this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? 16 : 0;
  }

  build() {
    Row() {
      Column() {
        Text(this.label)
          .fontSize(16)
          .fontColor(this.disabled ? '#a2a2a2' : $r('sys.color.font_primary'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
      }
      .flexShrink(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Toggle({ type: ToggleType.Checkbox, isOn: this.isOn }).selectedColor(this.themeColor)
          .enabled(!this.disabled)
          .onChange((isOn: boolean) => {
            this.isOn = !!isOn; // 实际回调的是number类型，这里将其转换成boolean类型
            this.onChange(this.value, this.isOn);
          })
          .hitTestBehavior(HitTestMode.None)
      }
      .flexShrink(0)
    }
    .width(this.isCustomWeekList ? '100%' : `calc(100% - ${this.itemMargin * 2}vp)`)
    .enabled(!this.disabled)
    .id('my_checkbox_item_' + this.value)
    .accessibilityText(this.getAccessibilityText())
    .accessibilityGroup(true)
    .justifyContent(FlexAlign.SpaceBetween)
    .stateStyles({
      pressed: {
        .backgroundColor(this.disabled ? '' : $r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      if (!this.disabled) {
        this.isOn = !this.isOn;
        this.onChange(this.value, this.isOn);
        this.setAccessibilityFocus();
      }
    })
    .borderRadius(this.itemBorderRadius)
    .constraintSize({ minHeight: 48 })
    .margin({
      left: this.isCustomWeekList ? 0 : this.itemMargin,
      right: this.isCustomWeekList ? 0 : this.itemMargin
    })
    .padding({
      left: 8,
      right: 8,
      top: this.onChangePadding(),
      bottom: this.onChangePadding()
    })
    .id(this.compId)
  }

  // 选项发生变化
  private onChange = (value: string | number, isOn: boolean) => {
  };
}
