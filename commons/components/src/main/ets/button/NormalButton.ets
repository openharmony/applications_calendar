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
import { BigFontSize, FontSizeScaleUtils } from '@app/common';

/**
 * 普通弹框按钮组件
 */
@Component
export struct NormalButton {
  @StorageLink('themeColor') themeColor: string = '';

  @Prop label: ResourceStr;

  private compId: string = '';

  private isWarning: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  build() {
    Button() {
      Text(this.label)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          16))
        .fontColor(this.isWarning ? $r('sys.color.ohos_id_color_warning') : this.themeColor)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
    }
    .type(ButtonType.Capsule)
    .backgroundColor(Color.Transparent)
    .layoutWeight(1)
    .onClick(() => {
      this.onButtonClick();
    })
    .id(this.compId)
    .constraintSize({ minHeight: 40 })
  }

  public onButtonClick: () => void = () => {
  };
}