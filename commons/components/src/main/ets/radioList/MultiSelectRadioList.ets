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
import { BigFontSize, DeviceConfig, FontSizeScaleUtils, Log, ThrottleFunction } from '@app/common';
import { addSelectStatusAndButtonParams } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { RadioListStyle } from '../commonDialog/RadioListDialog';
import { LengthMetrics } from '@kit.ArkUI';
import { RadioListOption } from './RadioList';


type Value = string | number;

const TAG: string = 'MultiSelectRadioList';

/**
 * 单选框选框组列表自定义组件
 *
 * @since 2024-09-26
 */
@Component
export struct MultiSelectRadioList {
  // list选中的值
  @State checkedIndexes: Set<number> = new Set();

  @Prop checkedArray: number[] = [];

  @Link isBackToPage: boolean;

  @Prop style: RadioListStyle = RadioListStyle.Popup;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 互斥值
  public mutexValue: number | undefined = undefined;

  // 默认值
  private defaultValue: number | undefined = undefined;

  // 选项
  @State options: RadioListOption[] = [];

  private DELAY: number = 100;

  // 加载时视口初始位置的索引值
  private index: number = 0;

  // 用于设置分割线长度的值
  private dividerLength: number = 9;

  private scroller: Scroller = new Scroller();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private maxSelection: number = 5;

  @State isShowCustomize: boolean = false;

  @Link customizeValue: number | undefined;

  @State isCustomizeExpanded: boolean = false;

  @BuilderParam customizeTitleView: () => void;

  @BuilderParam customizeContentView: (onValueChangeCallback: (value: number) => void) => void;

  optionGenerator?: (value: number) => RadioListOption;

  private itemMargin = DeviceConfig.instance().config.popUpItemMargin;

  private itemBorderRadius = DeviceConfig.instance().config.popUpItemBorderRadius;

  /**
   * 选项发生变化
   *
   * @param value 变化之后的选中数组
   */
  onSelectedChange = (values: number[]): void => {
    ThrottleFunction.instance().throttle(TAG, (): void => {
      this.onChange(values)
    }, this.DELAY);
  };

  @Builder
  buildList() {
    List({ initialIndex: this.index, scroller: this.scroller }) {
      ListItemGroup({ footer: this.ListFooterView }) {
        ForEach(this.options, (option: RadioListOption) => {
          ListItem() {
            OptionItem({
              selected: this.checkedIndexes.has(option.value),
              disabled: this.getDisable(option),
              style: this.style,
              label: option.label,
              value: option.value,
              text: option.text,
              compId: option.compId ? option.compId : '',
              groupName: undefined,
              isBackToPage: this.isBackToPage,
              onChange: (value: number): void => {
                this.onValueChange(value);
              }
            })
          }
        }, (option: RadioListOption) => `${option.value.toString()}-${option.checked}`)
      }
      .divider({
        strokeWidth: '1px',
        color: this.needCommerce && this.style === RadioListStyle.Menu ?
          Color.Transparent : $r('sys.color.ohos_id_color_list_separator'),
        startMargin: this.style === RadioListStyle.Menu ? 6 : this.dividerLength,
        endMargin: this.style === RadioListStyle.Menu ? 6 : this.dividerLength
      })
    }
    .enableScrollInteraction(this.options.length >= 6 ||
    FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale)) //每项高48, 6项大于最大高度 300
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }

  @Builder
  ListFooterView() {
    if (this.isShowCustomize) {
      Column() {
        Divider()
          .strokeWidth('1px')
          .color($r('sys.color.ohos_id_color_list_separator'))
          .margin({
            left: this.dividerLength,
            right: this.dividerLength
          });

        Row() {
          this.customizeTitleView();

          SymbolGlyph(this.isCustomizeExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_secondary'))
            .fontSize(FontSizeScaleUtils.fontSizeNumToVp(20))
            .padding(5)
        }
        .constraintSize({ minHeight: this.needCommerce ? 40 : 48 })
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ left: this.itemMargin, right: this.itemMargin })
        .padding({
          left: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
          right: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .borderRadius(this.itemBorderRadius)
        .focusBox({ margin: LengthMetrics.vp(-2) })
        .stateStyles({
          pressed: {
            .backgroundColor(this.checkedIndexes.size >= this.maxSelection ? Color.Transparent :
              $r('sys.color.interactive_click'))
          },
          normal: {
            .backgroundColor(Color.Transparent)
          }
        })
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.isCustomizeExpanded = !this.isCustomizeExpanded;
          if (!this.isCustomizeExpanded) {
            if (this.customizeValue !== undefined) {
              this.onCustomizeConfirmed(this.customizeValue);
            }
          } else {
            this.customizeValue = undefined;
            this.scroller.scrollEdge(Edge.Bottom);
          }
        })

        if (this.isCustomizeExpanded) {
          this.customizeContentView((value: number) => {
            this.customizeValue = value;
          });
        }
      }
      .opacity(this.checkedIndexes.size >= this.maxSelection ?
        $r('sys.float.ohos_id_alpha_disabled') : $r('sys.float.ohos_id_alpha_content_primary'))
      .enabled(this.checkedIndexes.size < this.maxSelection)
    }
  }

  private onCustomizeConfirmed(value: number) {
    if (!this.optionGenerator) {
      return;
    }
    const newOption = this.optionGenerator(value);
    if (!newOption) {
      return;
    }
    this.options.push(newOption);
    if (newOption.checked) {
      // 此处不能直接调onValueChange去add，onValueChange中还有delete的操作，当自定义值与预设值相同时容易把预设值去勾选
      this.checkedIndexes.add(value);
      // 存在自定义值后，需要把存在的互斥值删除
      if (this.mutexValue && this.checkedIndexes.has(this.mutexValue)) {
        this.checkedIndexes.delete(this.mutexValue);
      }
      this.checkedArray = Array.from(this.checkedIndexes);
      this.onSelectedChange(this.checkedArray);
    }
  }

  // 互斥值等价于在什么情况下都可以被选择
  private getDisable(option: RadioListOption): boolean {
    return option.isMutex ? false :
      this.checkedIndexes.size >= this.maxSelection && !this.checkedIndexes.has(option.value);
  }

  private onValueChange(value: number) {
    // 存在互斥值且value为互斥值，则需要清除其他值并加上互斥值
    if (this.mutexValue && value === this.mutexValue) {
      this.checkedIndexes.clear();
      this.checkedIndexes.add(value);
    } else {
      if (this.checkedIndexes.has(value)) {
        this.checkedIndexes.delete(value);
      } else {
        this.checkedIndexes.add(value);
        // 如果存在其他的值，需要把存在的互斥值删除
        if (this.mutexValue && this.checkedIndexes.has(this.mutexValue)) {
          this.checkedIndexes.delete(this.mutexValue);
        }
      }
      this.putDefaultValue();
    }
    this.checkedArray = Array.from(this.checkedIndexes);
    this.onSelectedChange(this.checkedArray);
  }

  build() {
    Stack({ alignContent: Alignment.End }) {
      this.buildList()
      ScrollBar({
        scroller: this.scroller,
        direction: ScrollBarDirection.Vertical,
        state: BarState.Auto
      })
        .margin({ top: this.needCommerce ? 4 : 16, bottom: this.needCommerce ? 4 : 16 })
        .visibility(this.options.length > 6 || FontSizeScaleUtils.isGreaterThan2X(this.fontSizeScale) ?
        Visibility.Visible : Visibility.Hidden) //每项高48, 6项大于最大高度 300
    }
  }

  getIndex(value: number | undefined) {
    return this.options.findIndex(option => {
      return option.value === value;
    }) ?? -1;
  }

  aboutToAppear() {
    this.index = this.getIndex(this.checkedIndexes.values().next().value);
    this.findMutexAndDefaultValue();
    this.checkedIndexes = new Set(this.checkedArray);
    this.putDefaultValue();
  }

  private findMutexAndDefaultValue() {
    for (let optionsElement of this.options) {
      if (optionsElement.isMutex) {
        this.mutexValue = optionsElement.value;
      }
      if (optionsElement.isDefault) {
        this.defaultValue = optionsElement.value;
      }
    }
  }

  // 如果存在默认值并且checkedIndexes为空时，需要把默认值加上
  private putDefaultValue() {
    if (this.defaultValue && this.checkedIndexes.size === 0) {
      this.checkedIndexes.add(this.defaultValue);
    }
  }

  // 单选框列表发生变化
  private onChange = (values: number[]) => {
  };
}


@Component
struct OptionItem {
  // list选中的值
  @Prop selected: boolean = false;

  @Prop disabled: boolean = false;

  @Link isBackToPage: boolean;

  @Prop style: RadioListStyle = RadioListStyle.Popup;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 群组名称，相同group的Radio只能有一个被选中
  private groupName: string | undefined = '';

  // 设置项名称
  private label: ResourceStr = '';

  private text: string = '';

  // 单选框对应的值，每项对应的值唯一
  private value: Value = 0;

  private compId: string = '';

  // 用于设置间隔
  private paddingLeftLength: number = 8;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private itemMargin = DeviceConfig.instance().config.popUpItemMargin;

  private itemBorderRadius = DeviceConfig.instance().config.popUpItemBorderRadius;

  onChangePadding(): number {
    return this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_3X ? 24 :
      this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_2X ? 20 :
        this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? 16 : 0;
  }

  isSelected(): boolean {
    return this.selected;
  }

  build() {
    Row() {
      Row () {
        Text(this.label)
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            16
          ))
          .maxLines(2)
          .flexShrink(1)
          .layoutWeight(1)
          .fontWeight(FontWeight.Medium)
          .opacity(this.disabled ?
          $r('sys.float.ohos_id_alpha_disabled') : $r('sys.float.ohos_id_alpha_content_primary'))
        if (this.style === RadioListStyle.Popup) {
          Row() {
            this.radioBuilder()
          }
          .justifyContent(FlexAlign.End)
        } else if (this.style === RadioListStyle.Menu && this.isSelected()) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
            .fontSize(FontSizeScaleUtils.fontSizeNumToVp(20))
        }

      }.width('100%')
    }
    .accessibilityText(addSelectStatusAndButtonParams(this.text ? 
    this.text : this.label, this.isSelected(), this.value))
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({
      left: this.style === RadioListStyle.Menu ? 0 : this.itemMargin,
      right: this.style === RadioListStyle.Menu ? 0 : this.itemMargin,
    })
    .padding({
      left: this.style === RadioListStyle.Menu ? 8 : this.paddingLeftLength,
      right: this.style === RadioListStyle.Menu ? 8 : this.paddingLeftLength,
      top: this.onChangePadding(),
      bottom: this.onChangePadding()
    })
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
      if (this.disabled) {
        return;
      }
      Log.debug('onClick', `groupName:${this.groupName} value:${this.value}`)
      this.onChange(this.value);
      this.isBackToPage = true;
    })
    .borderRadius(this.itemBorderRadius)
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .constraintSize({ minHeight: this.needCommerce ? 40 : 48 })
    .id(this.compId)
  }

  // 选项发生变化
  private onChange = (value: Value) => {
  };

  @Builder
  radioBuilder() {
    Checkbox()
      .select(this.selected)
      .selectedColor(this.themeColor)
      .accessibilityLevel('no')
      .hitTestBehavior(HitTestMode.None)
      .enabled(!this.disabled)
      .onClick(() => {
        this.onChange(this.value);
        this.isBackToPage = true;
      })
  }
}