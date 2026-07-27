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

import { BigFontSize, DeviceConfig, deviceType, FontSizeScaleUtils, CompId } from '@app/common';

import { HighlightButton, NormalButton } from '@app/common.components';

/**
 * 自定义普通类型dialog
 *
 */
const TAG: string = 'ProgressDialog';

@CustomDialog
export struct ProgressDialog {
  // 设备类型
  @StorageLink('deviceType') deviceType: number = deviceType.PHONE;

  @StorageLink('themeColor') themeColor: string = '';

  private controller: CustomDialogController = new CustomDialogController({ builder: '' });

  @Link currentProgressText: string;

  @Link currentProgress: number;

  private confirmText: ResourceStr = '';

  private cancelText: ResourceStr = '';

  private isEndScene: boolean = false;

  private isConfirmWarning: boolean = false; // 确认按钮是否需要使用警告色

  private isFocusLeftButton: boolean = false; // 默认焦点是否在左侧按钮

  private endText: ResourceStr = '';

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  onConfirmClick: () => void = () => {
  };

  onCancelClick: () => void = () => {
  };

  aboutToAppear() {
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.importexport_ready_to_share'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            20
          ))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Regular)
          .wordBreak(WordBreak.NORMAL)
          .id('tv_export_event_progress_des')
          .constraintSize({
            maxWidth: '80%'
          })
        Text(this.currentProgressText)
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            20
          ))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_secondary'))
          .id('tv_export_event_progress')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)


      Progress({ value: this.currentProgress, total: 100, type: ProgressType.Linear })
        .color(this.themeColor)
        .margin({
          top: $r('sys.float.padding_level4'),
          bottom: $r('sys.float.padding_level4')
        })
        .id('export_progress');

      Row() {
        this.buildButton();
      }.constraintSize({ minHeight: 40 })
    }
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      top: $r('sys.float.padding_level12'),
      bottom: $r('sys.float.padding_level8')
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildButton() {
    if (!this.isEndScene) {
      if (this.needCommerce) {
        this.buildCommerceDialogButton();
      } else {
        this.buildDialogButton();
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