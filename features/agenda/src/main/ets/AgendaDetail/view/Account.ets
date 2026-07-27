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
import { AccountUtils, BigFontSize, FontSizeScaleUtils } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';

/**
 * 日程账户
 */
@Component
export struct Account {
  // 帐户颜色
  @Prop accountColor: number = 0;

  // 帐户展示名
  @Prop accountDisName: ResourceStr = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Builder
  buildRowAccount() {
    Row() {
      Row() {
        Text($r('app.string.sidebar_account_calendar'))
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
      }
      .margin({ end: LengthMetrics.vp(18) })

      Row() {
        Circle()
          .height(4)
          .width(4)
          .strokeWidth(4)
          .stroke(this.accountColor)
          .margin({ left: 6, right: 6 })

        Text(this.accountDisName)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .fontWeight(FontWeight.Medium)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .flexShrink(1)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
      .padding({ top: 6, bottom: 6 })
      .constraintSize({ minHeight: 56 })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0)
    })
  }

  @Builder
  buildColumnAccount() {
    Column() {
      Row() {
        Text($r('app.string.sidebar_account_calendar'))
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      Row() {
        Circle()
          .height(4)
          .width(4)
          .strokeWidth(4)
          .stroke(this.accountColor)
          .margin({ start: LengthMetrics.vp(2), end: LengthMetrics.vp(6) })
          .flexShrink(1)

        Text(this.accountDisName)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .fontWeight(FontWeight.Medium)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(3)
          .flexShrink(1)
      }
      .width('100%')
      .margin({ start: LengthMetrics.vp(0) })
      .justifyContent(FlexAlign.Start)
      .padding({ top: 6, bottom: 6 })
      .layoutWeight(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 1 : undefined)
    }
    .margin({ top: 10 })
    .constraintSize({ minHeight: 56 })
    .width('100%')
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0)
    })
  }

  build() {
    if (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD) {
      this.buildColumnAccount()
    } else {
      this.buildRowAccount()
    }
  }
}