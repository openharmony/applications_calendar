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
  deviceType,
  FontSizeScaleUtils,
  GlobalThis,
  ThrottleFunction,
  I18nUtil,
  Log,
} from '@app/common';
import measure from '@ohos.measure';
import { HighlightButton } from './button/HighlightButton';
import { NormalButton } from './button/NormalButton';
import { KeyCode } from '@kit.InputKit';

/**
 * 自定义普通类型dialog
 *
 */
const TAG: string = 'CommonTextDialog';

type MarginStyle = Margin | Length | LocalizedMargin
type PaddingStyle = Padding | Length | LocalizedPadding

@CustomDialog
export struct CommonTextDialog {
  // 设备类型
  @StorageLink('deviceType') deviceType: number = deviceType.PHONE;

  @StorageLink('themeColor') themeColor: string = '';

  private controller: CustomDialogController = new CustomDialogController({ builder: '' });

  private title: ResourceStr = '';

  private message: ResourceStr = '';

  private confirmText: ResourceStr = '';

  private cancelText: ResourceStr = '';

  private isPermissionDialog: boolean = false;

  private endText: ResourceStr = '';

  private isEndScene: boolean = false;

  private isCenter: boolean = false;

  private isConfirmWarning: boolean = false; // 确认按钮是否需要使用警告色

  private marginStyle: MarginStyle | null = null;

  private paddingStyle: PaddingStyle | null = null;

  private isFocusLeftButton: boolean = false; // 默认焦点是否在左侧按钮

  private isEmphasize: boolean = false; // 是否为强调风格的弹窗 true: 是

  @StorageLink('language') @Watch('onLanguageChange') language: string = I18nUtil.getSystemLanguage();

  @State isChinese: boolean = true;

  // 弹窗特定参数Map
  private dialogParamsMap: Map<number, DialogParams> = new Map<number, DialogParams>([
    [deviceType.PHONE, new DialogParams(360, true, '#00ffffff', 8, 16)],
    [deviceType.TABLET, new DialogParams(360, true, '#00ffffff', 8, 16)],
    [deviceType.PC, new DialogParams(394, false, $r('sys.color.comp_background_tertiary'), 16, 24)]]);

  // 弹窗特定参数
  private dialogParams: DialogParams = this.dialogParamsMap.get(this.deviceType) as DialogParams;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  onConfirmClick: () => void = () => {
  };

  onCancelClick: () => void = () => {
  };

  aboutToAppear() {
    const renderTextWidthPx =
      measure.measureText({ textContent: this.message, fontSize: 16, fontWeight: FontWeight.Regular });
    const renderTextWidth = px2vp(renderTextWidthPx);
    this.isCenter = (this.dialogParams.width - 48) < renderTextWidth;
    this.onLanguageChange();
  }

  onLanguageChange() {
    this.isChinese = I18nUtil.isSystemChineseLanguage();
  }

  build() {
    Column() {
      if (this.title) {
        Text(this.title)
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            20
          ))
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Center)
          .fontColor($r('sys.color.font_primary'))
          .margin({ left: 8, right: 8, bottom: this.dialogParams.buttonTopPadding })
      }
      Text(this.message)
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Regular)
        .alignSelf(this.isCenter ? ItemAlign.Start : ItemAlign.Center)
        .margin({ left: 8, right: 8 })
        .wordBreak(WordBreak.NORMAL)
        .textAlign(this.isEmphasize ? TextAlign.Center : TextAlign.Start)
      Row() {
        this.buildButton();
      }
      .constraintSize({ minHeight: 40 })
      .margin({
        top: this.dialogParams.buttonTopPadding,
        bottom: $r('sys.float.ohos_id_dialog_button_padding_bottom')
      })
    }
    .padding(this.paddingStyle ? this.paddingStyle : { left: 16, right: 16, top: this.isPermissionDialog ? 0 : 24 })
    .constraintSize({ maxWidth: this.dialogParams.width })
    .margin(this.marginStyle ? this.marginStyle : { left: 16, right: 16, bottom: $r('sys.float.padding_level8') })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16'))
    .shadow(this.needCommerce ? ShadowStyle.OUTER_DEFAULT_SM : undefined)
  }

  @Builder
  buildButton() {
    if (!this.isEndScene) {
      if (this.needCommerce) {
        this.buildCommerceDialogButton();
      } else {
        if (this.isEmphasize) {
          this.buildEmphasizeDialogButton();
        } else {
          this.buildDialogButton();
        }
      }
    } else {
      this.buildEndScene();
    }
  }

  // 弹窗按钮
  @Builder
  buildDialogButton() {
    NormalButton({
      label: this.cancelText,
      compId: CompId.CANCEL,
      onButtonClick: () => {
        this.controller?.close();
        this.onCancelClick();
      }
    })
    Divider()
      .vertical(true)
      .strokeWidth('2px')
      .height(24)
      .color($r('sys.color.comp_divider'))
      .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
    NormalButton({
      label: this.confirmText,
      compId: CompId.CONFIRMS,
      isWarning: this.isConfirmWarning,
      onButtonClick: () => {
        this.controller?.close();
        this.onConfirmClick();
      }
    })
  }

  // 强调风格弹窗按钮
  @Builder
  buildEmphasizeDialogButton() {
    NormalButton({
      label: this.cancelText,
      compId: CompId.CANCEL,
      onButtonClick: () => {
        this.controller?.close();
        this.onCancelClick();
      }
    })

    Blank().width($r('sys.float.padding_level4'))

    Button() {
      Text(this.confirmText)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          this.isChinese ? 16 : 14))
        .fontColor($r('sys.color.font_on_primary'))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
    }
    .type(ButtonType.Capsule)
    .backgroundColor(this.themeColor)
    .layoutWeight(1)
    .onClick(() => {
      this.controller?.close();
      this.onConfirmClick();
    })
    .constraintSize({ minHeight: 40 })
  }

  // 商务风弹窗按钮
  @Builder
  buildCommerceDialogButton() {
    HighlightButton({
      label: this.cancelText,
      compId: CompId.CANCEL,
      isFocus: this.isFocusLeftButton,
      onButtonClick: () => {
        this.controller?.close();
        this.onCancelClick();
      }
    })
    Blank().width($r('sys.float.padding_level8'))
    HighlightButton({
      label: this.confirmText,
      compId: CompId.CONFIRMS,
      isWarning: this.isConfirmWarning,
      isFocus: !this.isFocusLeftButton,
      onButtonClick: () => {
        this.controller?.close();
        this.onConfirmClick();
      }
    })
  }

  @Builder
  buildEndScene() {
    if (this.needCommerce) {
      HighlightButton({
        label: this.endText,
        onButtonClick: () => {
          this.controller?.close();
        }
      })
    } else {
      NormalButton({
        label: this.endText,
        onButtonClick: () => {
          this.controller?.close();
        }
      })
    }
  }
}

/**
 * 弹窗特定属性（根据设备形态做区分）
 *
 */
class DialogParams {
  // 弹窗宽度
  public width: number;

  // 按钮分割线是否显示
  public dividerShow: boolean;

  // 按钮颜色
  public buttonBackgroundColor: ResourceColor;

  // 按钮上间距
  public buttonTopPadding: number;

  // 按钮下间距
  public buttonBottomPadding: number;

  constructor(width: number, dividerShow: boolean, buttonBackgroundColor: ResourceColor,
              buttonTopPadding: number, buttonBottomPadding: number) {
    this.width = width;
    this.dividerShow = dividerShow;
    this.buttonBackgroundColor = buttonBackgroundColor;
    this.buttonTopPadding = buttonTopPadding;
    this.buttonBottomPadding = buttonBottomPadding;
  }
}