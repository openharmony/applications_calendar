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
import { BigFontSize, DeviceConfig, FontSizeScaleUtils } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
const TAG = '[Schedule][ListItemSampleContent]';

/**
 * 列表项公共组件
 *
 * @since 2025-5-19
 */
@Component
export struct ListItemSampleContent {

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Prop label: ResourceStr;

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  public onClickCallback: Callback<ClickEvent> = () => {
  };

  private compId: string = '';

  @Builder
  buildLabel() {
    Column() {
      Text(this.label)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .flexShrink(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: $r('sys.float.padding_level4') })
  }

  //右箭头
  @Builder
  builderRightArrow() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4) });
    }
    .alignItems(VerticalAlign.Center)
    .constraintSize({ minHeight: 24 })
    .clip(true)
  }

  build() {
      Row() {
        this.buildLabel();
        this.builderRightArrow();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .constraintSize({ minHeight: this.rowMinHeight })
      .borderRadius($r('sys.float.corner_radius_level7'))
      .hoverEffect(HoverEffect.Highlight)
      .padding({
        top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'));
        }
      , normal: {
          .backgroundColor(Color.Transparent);
        }
      })
      .id(this.compId)
      .onClick((event: ClickEvent) => {
        this.onClickCallback(event);
      });
    }
}