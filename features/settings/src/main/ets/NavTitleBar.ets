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
  GlobalThis,
  NavPathManager, NavPathName, RouterName
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';

//图片的通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct NaviTitleBar {
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //image fillColor
  @State imgFillColor: string = '#000000';

  title: ResourceStr = '';

  private navPath: string = '';

  private navRouter: string = RouterName.ENTRY_HAP;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  // 关闭半模态
  private onClosePage: () => void = (): void => {
  };

  build() {
    Row() {
      Text(this.title)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE,
          20
        ))
        .minFontSize(10)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize('18vp')
          .fontColor([$r('sys.color.icon_primary')])
      }
      .backgroundColor(this.buttonBackgroundColor)
      .width(40)
      .height(40)
      .margin({ start: LengthMetrics.vp(8) })
      .borderRadius($r('sys.float.corner_radius_level4'))
      .id(CompId.BACK_MAIN)
      .onClick(() => {
        if (this.navPath === NavPathName.SETTING_MAIN) {
          this.onClosePage();
        } else {
          NavPathManager.getInstance().popRouter(this.navRouter);
        }
      })
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.cancel')))
    }
    .height(56)
    .width('100%')
    .padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .margin({ bottom: $r('sys.float.padding_level4') })
    .alignItems(VerticalAlign.Center)
  }
}