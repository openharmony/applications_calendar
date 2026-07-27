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
  DeviceConfig,
  GlobalThis,
  FontSizeScaleUtils,
  CompId
} from '@app/common';

// 日程账户类5.0副标题
const TAG = 'SubTitle'

@Preview
@Component
export struct SubTitle {
  // 显示标题
  @State title: Resource | string = '';

  private compId: string = '';

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  needChangePadding() {
    return (this.compId === CompId.SETTINGS_About) || (this.compId === CompId.SETTINGS_FeedBack) || this.needCommerce;
  }

  build() {
    Row() {
      Row() {
        if ((this.compId !== CompId.SETTINGS_About) && (this.compId !== CompId.SETTINGS_FeedBack)) {
          Text(this.title)
            .align(Alignment.Start)
            .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
              GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
              14
            ))
            .lineHeight(20)
            .id(this.compId)
            .accessibilityLevel('yes')
        }
      }
    }
    .opacity(0.6)
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      top: this.needChangePadding() ? $r('sys.float.padding_level6') : 28,
      bottom: this.needChangePadding() ? 0 : $r('sys.float.padding_level4'),
    })
    .width('100%')
  }
}