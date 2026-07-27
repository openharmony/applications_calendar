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
import { AccountUtils, DeviceConfig, FontSizeScaleUtils, GlobalThis, ThrottleFunction } from '@app/common';

export interface AccountRadioListOption {
  color: number;
  label: string;
  value: number;
  checked?: boolean;
}

type Value = string | number;

const TAG: string = 'AccountRadioList';

/**
 * 单选框选框组列表帐户自定义组件
 */
@Component
export struct AccountRadioList {
  // list选中的值
  @Link checkValue: number;

  // 分割线宽度
  @Prop strokeWidth: number;

  // 选项
  private options: AccountRadioListOption[] = [];

  // 群组名称，相同group的Radio只能有一个被选中
  private groupName: string = '';

  private DELAY: number = 400;

  // 加载时视口初始位置的索引值
  private index: number = 0;

  // 用于设置分割线长度的值
  private dividerMargin: number = 20;

  /**
   * 单个选项发生变化
   *
   * @param value 单选框值
   */
  onSingleItemChange(value: number): void {
    this.checkValue = value;
    ThrottleFunction.instance().debounce(TAG, (): void => {
      this.emitChange(value)
    }, this.DELAY);
  };

  build() {
    List({ initialIndex: this.index }) {
      ForEach(this.options, (option: AccountRadioListOption) => {
        ListItem() {
          OptionItem({
            groupName: this.groupName,
            checkValue: this.checkValue,
            color: option.color,
            label: option.label,
            value: option.value,
            onChange: (value: number): void => this.onSingleItemChange(value)
          })
        }
      }, (option: AccountRadioListOption) => option.value.toString())
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .divider({
      strokeWidth: '1px',
      color: $r('sys.color.ohos_id_color_list_separator'),
      startMargin: this.dividerMargin,
      endMargin: this.dividerMargin
    })
  }

  getIndex(value: number) {
    return this.options.findIndex(option => {
      return option.value === value;
    }) ?? -1;
  }

  aboutToAppear() {
    this.index = this.getIndex(this.checkValue);
  }

  // 单选框列表发生变化
  private onChange: (value: number) => void = (value: number): void => {
  };

  // 结合防抖函数，发布选项变更
  private emitChange: Function = (value: number) => {
    this.onChange(value);
  };
}

@Component
struct OptionItem {
  // list选中的值
  @Prop checkValue: number = 0;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 群组名称，相同group的Radio只能有一个被选中
  private groupName: string = '';

  // 帐户项颜色
  private color: number = 0;

  // 帐户项名称
  private label: string = '';

  // 单选框对应的值，每项对应的值唯一
  private value: Value = 0;

  private itemMargin = DeviceConfig.instance().config.popUpItemMargin;

  private itemBorderRadius = DeviceConfig.instance().config.popUpItemBorderRadius;

  build() {
    Row() {
      Row() {
        Circle()
          .width(16)
          .height(16)
          .fill(this.color)
          .margin({ right: 16 })
        Text(AccountUtils.getAccountResourceMap().get(this.label)
          ? AccountUtils.getAccountResourceMap().get(this.label) : this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ right: 10 })
          .layoutWeight(1)
        Radio({ value: this.value + '', group: this.groupName })
          .radioStyle({
            checkedBackgroundColor: this.themeColor
          })
          .hoverEffect(HoverEffect.None)
          .checked(this.value == this.checkValue)
          .margin(0)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.onChange(this.value);
          })
      }
    }
    .hoverEffect(HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .onClick(() => {
      this.onChange(this.value);
    })
    .borderRadius(this.itemBorderRadius)
    .constraintSize({ minHeight: 48 })
    .margin({
      left: this.itemMargin,
      right: this.itemMargin
    })
    .padding({
      left: 8,
      right: 8,
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(GlobalThis.getInstance().fontSizeScale),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(GlobalThis.getInstance().fontSizeScale)
    })
  }

  // 选项发生变化
  private onChange = (value: Value) => {
  };
}
