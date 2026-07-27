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

/**
 * 小红点
 */
@Component
export struct RedDot {
  @Prop count: number = 0;

  @Prop fontSize: number | Resource = $r('sys.float.ohos_id_text_size_caption');

  getValue() {
    return this.count > 99 ? '99+' : this.count.toString();
  }

  getPaddingLRSize() {
    return this.count > 9 ? $r('sys.float.padding_level3') : $r('sys.float.padding_level2');
  }

  build() {
    if (this.count > 0) {
      Row() {
        Text(this.getValue())
          .fontSize(this.fontSize)
          .fontColor($r('app.color.red_common'))
      }
      .height(16)
      .constraintSize({
        minWidth: 16
      })
      .padding({
        left: this.getPaddingLRSize(),
        right: this.getPaddingLRSize(),
      })
      .borderRadius($r('sys.float.corner_radius_level4'))
      .margin({
        left: 4,
        right: 4,
      })
      .backgroundColor('rgba(247, 96, 69, 0.1)')
      .justifyContent(FlexAlign.Center)
    }
  }
}

