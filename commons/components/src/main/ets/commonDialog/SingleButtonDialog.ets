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
  DialogParams,
  DeviceConfig,
  CompId,
} from '@app/common';
import { HighlightButton } from '../button/HighlightButton';
import { NormalButton } from '../button/NormalButton';
import measure from '@ohos.measure';

/**
 * 自定义普通类型dialog
 *
 */
@CustomDialog
export struct SingleButtonDialog {
  @StorageLink('themeColor') themeColor: string = '';

  controller: CustomDialogController = new CustomDialogController({ builder: '' });

  title: ResourceStr = '';

  message: ResourceStr = '';

  confirmText: ResourceStr = '';

  isPermissionDialog: boolean = false;

  endText: ResourceStr = '';

  endTextColor: string | Color = '#0A59F7';

  isEndScene: boolean = false;

  private isCenter: boolean = false;

  private isConfirmWarning: boolean = false // 确认按钮是否需要使用警告色

  // 弹窗特定参数
  private dialogParams: DialogParams = DeviceConfig.instance().config.dialogParam;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onConfirmClick: () => void = () => {
  };

  onCancelClick: () => void = () => {
  };

  aboutToAppear() {
    const renderTextWidthPx: number =
      measure.measureText({ textContent: this.message, fontSize: 16, fontWeight: FontWeight.Regular });
    const renderTextWidth = px2vp(renderTextWidthPx);
    this.isCenter = (this.dialogParams.width - 48) < renderTextWidth;
  }

  build() {
    Column() {
      if (this.title) {
        Text(this.title)
          .fontSize($r('sys.float.Title_S'))
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .fontColor($r('sys.color.font_primary'))
          .height(56)
          .margin({ left: 8, right: 8 })
      }
      Text(this.message)
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Regular)
        .alignSelf(this.isCenter ? ItemAlign.Start : ItemAlign.Center)
        .margin({ left: 8, right: 8, top: this.isPermissionDialog ? 0 : 24 })
        .wordBreak(WordBreak.NORMAL)
      Row() {
        this.buildButton();
      }
      .height(40)
      .margin({
        top: this.dialogParams.buttonTopPadding,
        bottom: $r('sys.float.ohos_id_dialog_button_padding_bottom')
      })
    }
    .padding({ left: 16, right: 16 })
    .constraintSize({ maxWidth: this.dialogParams.width })
    .margin({ left: 16, right: 16, bottom: $r('sys.float.padding_level8') })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16'))
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
      label: this.confirmText,
      compId: CompId.CONFIRMS,
      isWarning: this.isConfirmWarning,
      onButtonClick: () => {
        this.controller.close();
        this.onConfirmClick();
      }
    })
  }

  // 商务风弹窗按钮
  @Builder
  buildCommerceDialogButton() {
    HighlightButton({
      label: this.confirmText,
      compId: CompId.CONFIRMS,
      isWarning: this.isConfirmWarning,
      onButtonClick: () => {
        this.controller.close();
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
          this.controller.close();
        }
      })
    } else {
      NormalButton({
        label: this.endText,
        onButtonClick: () => {
          this.controller.close();
        }
      })
    }
  }
}