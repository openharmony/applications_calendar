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

import { Action, eventAction } from '../groupConfig/declare';
import { BigFontSize, CommonInnerEvent, DeviceConfig, EmitterCollector, FontSizeScaleUtils } from '@app/common';
import { RadioListDialogOption } from '@app/common.components';
import { options as startOfWeekOptions, StartOfWeek } from '../dialogs/StartOfWeek';
import { LengthMetrics } from '@kit.ArkUI';

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct StartOfWeekSettingItem {
  // 一周开始日
  @StorageLink('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = 0;

  @State displayStartOfWeek: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State menuShow: boolean = false;

  // 主标题
  private title: ResourceStr = '';

  // 描述
  private description: ResourceStr = '';

  // 触发的行为类型，赋初值防止ArkTS报错
  private action: Action = eventAction.DIALOG;

  // 设置项key值
  private settingKey: string = '';

  // 设置项的默认值
  private defaultVal: string | number = '';

  private compId: string = '';

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  // 格式化附加信息
  formatExtraInfo(): ResourceStr | undefined {
    let that = this;
    return startOfWeekOptions.find((item: RadioListDialogOption) => {
      return item.value === that.displayStartOfWeek;
    })?.label;
  }

  isLargeFontLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  startOfWeekSettingBuilder() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(this.isLargeFontLayout() ? 1 : 2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 8 })
      }
    }
    .flexShrink(this.isLargeFontLayout() ? 0 : 1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: 8 })
    .width(this.isLargeFontLayout() ? '100%' : '50%')

    Row() {
      Text(this.formatExtraInfo())
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(this.isLargeFontLayout() ? TextAlign.Start : TextAlign.End)
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 24 })
      .clip(true)
    }
    .flexShrink(0)
    .width(this.isLargeFontLayout() ? '100%' : '50%')
    .justifyContent(this.isLargeFontLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  StartOfWeekSettingVerticalLayout() {
    Column() {
      this.startOfWeekSettingBuilder();
    }
    .bindMenu(this.menuShow, this.buildMenu(), {
      placement: Placement.TopRight,
      onDisappear: () => {
        this.menuShow = false;
      }
    })
    .onClick(() => {
      this.menuShow = true;
    })
    .borderRadius(14)
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .visibility(this.isLargeFontLayout() ? Visibility.Visible : Visibility.None)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .constraintSize({
      minHeight: this.rowMinHeight
    })
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .stateStyles({
      pressed: {
        .backgroundColor(this.action !== eventAction.SWITCH ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .borderRadius(14)
    .id(this.compId)
  }

  @Builder
  buildMenu() {
    Column() {
      StartOfWeek({
        callback: (value: number) => {
          this.displayStartOfWeek = value;
          this.menuShow = false;
        }
      })
    }
    .width(224)
  }

  build() {
    Row() {
      if (this.isLargeFontLayout()) {
        this.StartOfWeekSettingVerticalLayout();
      } else {
        Row() {
          this.startOfWeekSettingBuilder();
        }
        .bindMenu(this.menuShow, this.buildMenu(), {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.menuShow = false;
          }
        })
        .visibility(this.isLargeFontLayout() ? Visibility.None : Visibility.Visible)
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .constraintSize({
          minHeight: this.rowMinHeight
        })
        .padding({
          top: 4,
          bottom: 4,
          left: 8,
          right: 8
        })
        .stateStyles({
          pressed: {
            .backgroundColor(this.action !== eventAction.SWITCH
              ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
          },
          normal: {
            .backgroundColor(Color.Transparent)
          }
        })
        .onClick(() => {
          this.menuShow = true;
        })
        .focusBox({ margin: LengthMetrics.vp(-2) })
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(14)
        .id(this.compId)
      }
    }.width('100%')
  }

  aboutToAppear() {
    this.displayStartOfWeek = this.startOfWeek;
    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_STATUSBAR }, () => {
      this.menuShow = false;
    });
    this?.onMounted();
  }

  private onStartOfWeekChange(): void {
    this.displayStartOfWeek = this.startOfWeek;
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 打开弹框
  private openDialog: Function = () => {
  };
}
