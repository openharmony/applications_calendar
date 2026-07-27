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

import { BigFontSize, ButtonImageType } from '@app/common';


export class LongPressConfig {
  public static readonly TIPS_DIALOG_PRESS_TIME: number = 500; // 按压多久显示tips
  public static readonly TIPS_SHOW_SCALE: number = BigFontSize.BIG_FONT_SIZE_SCALE; // 多少倍率需要长按显示tips
}


@CustomDialog
export struct LongPressTipsDialog {
  private controller: CustomDialogController = new CustomDialogController({ builder: '' });
  private tipsText: ResourceStr = '';
  private tipsImage: Resource | undefined = undefined;
  private buttonImageType: ButtonImageType = ButtonImageType.SYMBOL;

  build() {
    Column() {
      if (this.buttonImageType === ButtonImageType.TEXT) {
        Text(this.tipsImage)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.Display_M'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
          .margin({ bottom: 16 })
      } else if (this.buttonImageType === ButtonImageType.IMAGE) {
        Image(this.tipsImage)
          .width(64)
          .height(64)
          .margin({ bottom: 16 })
          .draggable(false)
          .fillColor($r('sys.color.icon_primary'))
      } else {
        SymbolGlyph(this.tipsImage)
          .fontSize('64vp')
          .fontColor([$r('sys.color.icon_primary')])
          .margin({ bottom: 16 })
      }
      Text(this.tipsText)
        .fontSize(32)
        .maxFontScale(1.75)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: 8, right: 8, bottom: 24 })
    }
    .justifyContent(FlexAlign.Center)
    .width(256)
    .height(256)
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .shadow(ShadowStyle.OUTER_DEFAULT_LG)
  }
}