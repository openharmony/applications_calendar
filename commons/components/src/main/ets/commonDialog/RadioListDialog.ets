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
  BigFontSize,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  getAccessibilityText,
  GlobalThis,
  Log,
  ThrottleFunction
} from '@app/common';

import { RadioList, RadioListOption } from '../radioList/RadioList';
import { HighlightButton } from '../button/HighlightButton';
import { NormalButton } from '../button/NormalButton';
import { MultiSelectRadioList } from '../radioList/MultiSelectRadioList';
import lazy { KeyCode } from '@kit.InputKit';

/**
 * 弹框公共业务组件
 *
 * @since 2022-08-22
 */

const TAG = 'RadioListDialog';

export enum RadioListStyle {
  Popup = 0,
  Menu = 1
}

@Component
export struct RadioListDialog {
  // list初始选中的值
  @Link checkValue: number;

  // 多选选中的Indexes
  @State checkedIndexes: number[] = [];

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //标记位
  @State isBackToPage: boolean = false;

  @Prop style: RadioListStyle = RadioListStyle.Popup; // 作为弹窗还是 menu
  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;
  // 弹框标题
  private title: ResourceStr = '';
  private compId: string = '';
  // 是否启用多选
  private multiSelect: boolean = false;
  // list选项配置
  private options: RadioListOption[] = [];
  // 单选框的所属群组名称
  private readonly radioGroup: string = '';
  // 延时发布选项变更，避免弹框动画卡顿
  private DELAY: number = 100;
  //弹窗的分割线需要设置为20
  private dividerLength: number = 18;
  //弹窗文字左间距需要设为
  private paddingLeftLength: number = 20;
  private concatAccessibilityText: string = '';
  private showConfirm: boolean = false;
  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @State isShowCustomize: boolean = false;

  @State customizeValue: number | undefined = undefined;

  @BuilderParam customizeTitleView: () => void;

  @BuilderParam customizeContentView: (onValueChange: (value: number) => void) => void;

  optionGenerator?: (value: number) => RadioListOption;

  @Builder
  RadioListDialogText() {
    Text(this.title)
      .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
        px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
      ))
      .minFontSize(8)
      .maxLines(2)
      .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
      .fontWeight(FontWeight.Bold)
      .constraintSize({ minHeight: 56 })
      .textAlign(TextAlign.Start)
      .alignSelf(ItemAlign.Center)
      .margin({
        left: 16,
        right: 16,
        top: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? '12vp' : 0,
        bottom: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? '12vp' : 0
      })
      .id(this.compId)
  }

  build() {
    Column() {
      if (this.style === RadioListStyle.Popup) {
        this.RadioListDialogText();
      }
      Row() {
        if (this.multiSelect) {
          MultiSelectRadioList({
            options: this.options,
            checkedArray: this.checkedIndexes,
            isBackToPage: this.isBackToPage,
            style: this.style,
            isShowCustomize: this.isShowCustomize,
            customizeTitleView: this.customizeTitleView,
            customizeContentView: this.customizeContentView,
            optionGenerator: this.optionGenerator,
            customizeValue: this.customizeValue,
            dividerLength: this.dividerLength,
            onChange: (value: number[]) => {
              Log.info(TAG, `MultiSelectRadioList: ${value}`)
              this.checkedIndexes = value;
            }
          })
        } else {
          RadioList({
            options: this.options,
            groupName: this.radioGroup,
            isBackToPage: this.isBackToPage,
            checkValue: $checkValue,
            style: this.style,
            dividerLength: this.dividerLength,
            paddingLeftLength: this.paddingLeftLength,
            onChange: (value: number) => {
              this.checkValue = value;
              this.cancel();
              this.onChange(value);
            }
          })
        }
      }
      .clip(true)
      .borderRadius(this.needCommerce ?
        this.style === RadioListStyle.Menu ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level4')
        : $r('sys.float.corner_radius_level8'))
      .margin({
        left: this.style === RadioListStyle.Menu ? 0 : 4,
        right: this.style === RadioListStyle.Menu ? 0 : 4
      })
      .layoutWeight(this.multiSelect ? 1 : undefined) // 单选不再计算高度，根据组件自适应

      if (this.style === RadioListStyle.Popup) {
        this.buttonBuilder();
      }
    }
    .accessibilityLevel('no')
    .constraintSize({ maxHeight: this.getMaxHeight(this.style, this.windowHeightInVp) })
    .accessibilityText(this.concatAccessibilityText)
    .onKeyEvent((event) => {
      if (event.keyCode === KeyCode.KEYCODE_ENTER) {
        ThrottleFunction.instance().throttle(TAG + 'keyEvent',
          (): void => {
            this.cancel();
            this.onConfirmClick(this.checkedIndexes);
          },
          500);
      }
    })
  }

  @Builder
  buildConfirmButton() {
    if (this.needCommerce) {
      HighlightButton({
        label: $r('app.string.confirme_information'),
        compId: CompId.CANCEL,
        onButtonClick: () => {
          this.cancel();
          ThrottleFunction.instance().debounce(TAG + 'onConfirm', () => {
            this.onConfirmClick(this.checkedIndexes);
          }, this.DELAY)
        }
      })
    } else {
      NormalButton({
        label: $r('app.string.confirme_information'),
        compId: CompId.CANCEL,
        onButtonClick: () => {
          this.cancel();
          ThrottleFunction.instance().debounce(TAG + 'onConfirm', () => {
            this.onConfirmClick(this.checkedIndexes);
          }, this.DELAY)
        }
      })
    }
  }

  @Builder
  buildCancelButton() {
    if (this.needCommerce) {
      HighlightButton({
        label: $r('app.string.cancel_dialog_button'),
        compId: CompId.CANCEL,
        onButtonClick: () => {
          this.cancel();
        }
      })
    } else {
      NormalButton({
        label: $r('app.string.cancel_dialog_button'),
        compId: CompId.CANCEL,
        onButtonClick: () => {
          this.cancel();
        }
      })
    }
  }

  @Builder
  buttonBuilder() {
    Row() {
      this.buildCancelButton();
      if (this.showConfirm) {
        if (this.needCommerce) {
          Blank().width($r('sys.float.padding_level8'))
        } else {
          Divider()
            .vertical(true)
            .strokeWidth('2px')
            .height(24)
            .color($r('sys.color.comp_divider'))
            .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
        }
        this.buildConfirmButton();
      }
    }
    .defaultFocus(true)
    .margin({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: 8 * this.fontSizeScale,
      bottom: $r('sys.float.ohos_id_dialog_button_padding_bottom')
    })
  }

  aboutToAppear(): void {
    this.concatAccessibilityText = getAccessibilityText(this.title, this.options.length);
  }

  private getMaxHeight(style: RadioListStyle, windowHeightInVp: number): Length | undefined {
    if (style === RadioListStyle.Menu) {
      // 默认菜单高度300,窗口高度小于450后为窗口高度-150,最小50
      return Math.max(Math.min(windowHeightInVp - 150, 300), 50);
    } else {
      return 500;
    }
  }

  private getListHeight(style: RadioListStyle): Length | undefined {
    if (style == RadioListStyle.Menu) {
      // 选项的高度 + 2px高度的分割线
      const dividerHeight = Math.max((this.options.length - 1) * px2vp(2), 0);
      let length = this.options.length * (this.needCommerce ? 40 : 48) + dividerHeight;
      if (length > this.windowHeightInVp - 150) {
        length = this.windowHeightInVp - 150; // 列表高度不能超过窗口高度
      }
      return length;
    } else {
      return undefined;
    }
  }

  private onConfirmClick(values: number[]) {
    if (this.multiSelect && this.isShowCustomize && this.customizeValue !== undefined) {
      if (!values.includes(this.customizeValue)) {
        values.push(this.customizeValue);
      }
    }
    this.onConfirm(values);
  }

  // 关闭弹窗
  private cancel: () => void = () => {
  };

  // 选中项发生变化
  private onChange: (value: number) => void = (value: number) => {
  };

  private onConfirm: (value: number[]) => void = (value: number[]) => {
  }
}
