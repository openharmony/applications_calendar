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
  BigFontSize, CompId, DeviceConfig,
  FontSizeScaleUtils,
  ThrottleFunction
} from '@app/common';
import { addSelectStatusAndButtonParams, broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { RadioListStyle } from '../commonDialog/RadioListDialog';
import { LengthMetrics } from '@kit.ArkUI';

export interface RadioListOption {
  label: ResourceStr;
  value: number;
  checked?: boolean;
  compId?: string;
  text?: string;
  isMutex?: boolean;
  isDefault?: boolean;
}


type Value = string | number;

const TAG: string = 'RadioList';

/**
 * 单选框选框组列表自定义组件
 *
 * @since 2022-08-03
 */
@Component
export struct RadioList {
  // list选中的值
  @Link checkValue: number;

  @Link isBackToPage: boolean;

  @Prop style: RadioListStyle = RadioListStyle.Popup;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;

  // 选项
  @Prop options: RadioListOption[] = [];

  // 群组名称，相同group的Radio只能有一个被选中
  private groupName: string = '';

  private DELAY: number = 400;

  // 加载时视口初始位置的索引值
  private index: number = 0;

  // 用于设置分割线长度的值
  private dividerLength: number = 9;

  // 用于设置间隔
  private paddingLeftLength: number = 8;

  private scroller: Scroller = new Scroller();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  /**
   * 单个选项发生变化
   *
   * @param value 单选框值
   */
  onSingleItemChange = (value: number): void => {
    ThrottleFunction.instance().throttle(TAG, (): void => {
      this.onChange(value)
    }, this.DELAY);
  };

  @Builder
  buildList() {
    List({ initialIndex: this.index, scroller: this.scroller }) {
      ForEach(this.options, (option: RadioListOption) => {
        ListItem() {
          OptionItem({
            selected: this.checkValue === option.value,
            style: this.style,
            label: option.label,
            value: option.value,
            text: option.text,
            compId: option.compId ? option.compId : '',
            groupName: this.groupName,
            isBackToPage: this.isBackToPage,
            paddingLeftLength: this.paddingLeftLength,
            onChange: (value: number): void => {
              this.onSingleItemChange(value)
            }
          })
        }
      }, (option: RadioListOption) => {
        return `${option.value.toString()}-${option.label}`
      })
    }
    .id(CompId.RADIO_LIST_PRIVATE)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
    .divider({
      strokeWidth: '1px',
      color: (this.needCommerce) && this.style === RadioListStyle.Menu ?
      Color.Transparent : $r('sys.color.comp_divider'),
      startMargin: $r('sys.float.padding_level4'),
      endMargin: $r('sys.float.padding_level4')
    })
  }

  build() {
    RelativeContainer() {
      this.buildList();
      ScrollBar({
        scroller: this.scroller,
        direction: ScrollBarDirection.Vertical,
        state: BarState.Auto
      })
        .alignRules({
          left: { anchor: CompId.RADIO_LIST_PRIVATE, align: HorizontalAlign.End },
          bottom: { anchor: CompId.RADIO_LIST_PRIVATE, align: VerticalAlign.Bottom },
          top: { anchor: CompId.RADIO_LIST_PRIVATE, align: VerticalAlign.Top }
        })
        .margin({ top: this.needCommerce ? 4 : 16, bottom: this.needCommerce ? 4 : 16 })
        .width(4)
    }
    .height('auto')
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
  private onChange = (value: number) => {
  };
}

@Component
struct OptionItem {
  // list选中的值
  @Prop selected: boolean = false;

  @Link isBackToPage: boolean;

  @Prop style: RadioListStyle = RadioListStyle.Popup;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 群组名称，相同group的Radio只能有一个被选中
  private groupName: string | undefined = '';

  // 设置项名称
  @Prop label: ResourceStr = '';

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
      Column() {
        Text(this.label)
          .fontSize(16)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SIX)
          .fontWeight(FontWeight.Medium)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .flexShrink(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        if (this.style === RadioListStyle.Popup) {
          this.radioBuilder()
        } else if (this.style === RadioListStyle.Menu && this.isSelected()) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
            .fontSize(FontSizeScaleUtils.fontSizeNumToVp(20))
        }
      }
      .flexShrink(0)
    }
    .width('100%')
    .accessibilityText(this.text)
    .accessibilityRole(48)
    .accessibilitySelected(this.isSelected())
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: this.style === RadioListStyle.Menu ? 8 : this.paddingLeftLength,
      right: this.style === RadioListStyle.Menu ? 8 : this.paddingLeftLength - 4,
      top: this.style === RadioListStyle.Menu ? 12 : this.onChangePadding(),
      bottom: this.style === RadioListStyle.Menu ? 12 : this.onChangePadding()
    })
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onChange(this.value);
      this.isBackToPage = true;
      broadcastSelectStatus(true);
    })
    .borderRadius(this.needCommerce ?
      this.style === RadioListStyle.Menu ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level4')
      : $r('sys.float.corner_radius_level8'))
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .constraintSize({ minHeight: this.needCommerce ? 40 : 48 })
    .id(this.compId)
  }

  // 选项发生变化
  private onChange = (value: Value) => {
  };

  @Builder
  radioBuilder() {
    Radio({ value: this.value + '', group: this.groupName })
      .checked(this.selected)
      .radioStyle({
        checkedBackgroundColor: this.themeColor
      })
      .accessibilityLevel('no')
      .hitTestBehavior(HitTestMode.None)
      .onClick(() => {
        this.onChange(this.value);
        this.isBackToPage = true;
      })
  }
}
