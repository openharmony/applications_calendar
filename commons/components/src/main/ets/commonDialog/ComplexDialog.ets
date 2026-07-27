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
import { BigFontSize, CompId, DeviceConfig, FontSizeScaleUtils, GlobalThis, ThrottleFunction } from '@app/common';
import { HighlightButton } from '../button/HighlightButton';
import { NormalButton } from '../button/NormalButton';
import lazy { KeyCode } from '@kit.InputKit';

/**
 * 弹框公共业务组件
 *
 * @since 2024-02-23
 */

const TAG: string = 'ComplexDialog';

@Component
export struct ComplexDialog {
  // 主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 内容物
  @BuilderParam content: () => void;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 弹框标题
  private title: ResourceStr = '';

  private compId: string = '';

  // 是否存在确定按钮
  private hasConfirmButton: boolean = false;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 弹窗按钮
  @Builder
  buildDialogButton() {
    NormalButton({
      label: $r('app.string.cancel_dialog_button'),
      compId: CompId.CANCEL,
      onButtonClick: () => {
        this.cancel();
      }
    })
    if (this.hasConfirmButton) {
      Divider()
        .vertical(true)
        .strokeWidth('2px')
        .height(24)
        .color($r('sys.color.comp_divider'))
        .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
      NormalButton({
        label: $r('app.string.button_ok'),
        compId: CompId.CONFIRMS,
        onButtonClick: () => {
          this.confirm();
        }
      })
    }
  }

  // 商务风弹窗按钮
  @Builder
  buildCommerceDialogButton() {
    HighlightButton({
      label: $r('app.string.cancel_dialog_button'),
      compId: CompId.CANCEL,
      onButtonClick: () => {
        this.cancel();
      }
    })
    if (this.hasConfirmButton) {
      Blank().width($r('sys.float.padding_level8'))
      HighlightButton({
        label: $r('app.string.button_ok'),
        compId: CompId.CONFIRMS,
        onButtonClick: () => {
          this.confirm();
        }
      })
    }
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
        ))
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Center)
        .constraintSize({ minHeight: 56 })
        .margin({
          left: 24,
          right: 24,
          top: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? 12 : 0,
          bottom: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? 12 : 0
        })
        .id(this.compId)

      Column() {
        this.content()
      }
      .margin({ left: 4, right: 4 })
      .layoutWeight(1)

      Row() {
        if (this.needCommerce) {
          this.buildCommerceDialogButton();
        } else {
          this.buildDialogButton();
        }
      }
      .margin({
        left: 16,
        right: 16,
        top: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? 16 * this.fontSizeScale : 8,
        bottom: $r('sys.float.ohos_id_dialog_button_padding_bottom')
      })
    }
    .onKeyEvent((event) => {
      if (event.keyCode === KeyCode.KEYCODE_ENTER) {
        ThrottleFunction.instance().throttle(TAG + 'keyEvent',
          (): void => {
            this.confirm();
          },
          500);
      }
    })
  }

  // 关闭弹窗
  private cancel: () => void = () => {
  };

  // 确定弹窗
  private confirm: () => void = () => {
  };
}
