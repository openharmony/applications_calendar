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
import { BigFontSize, CommonInnerEvent, DeviceConfig, EmitterCollector, FontSizeScaleUtils, GlobalDataKeys } from '@app/common';
import { RadioListDialogOption } from '@app/common.components';
import { options as startOfWeekOptions } from '../dialogs/StartOfWeek';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';

/**
 * 设置单元(族)单个设置项
 *
 * @since 2022-07-25
 */
@Component
export struct WeekendsSettingItem {
  @Consume navPathStack: NavPathStack;

  // 周末
  @StorageLink('weekends') @Watch('onWeekendsChange') weekends: number[] = [-1];

  @State displayWeekends: number[] = [-1];

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

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

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  weekendsSettingBuilder() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 8 })
      }
    }
    .flexShrink(0)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: 8 })

    Row() {
      Flex({
        justifyContent: this.isChangeLayout() ? FlexAlign.Start
          : FlexAlign.End, wrap: FlexWrap.Wrap
      }) {
        ForEach(this.formatExtraInfo(), (info: string) => {
          Text(info)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ left: this.isChangeLayout() ? 0 : 4 })
        })
      }
      .layoutWeight(1)

      Row() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: $r('sys.float.padding_level2') })
          .width(12)
      }
      .alignItems(VerticalAlign.Center)
    }
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
    })
    .clip(true)
    .flexShrink(1)
    .width(this.isChangeLayout() ? '100%' : '')
    .constraintSize({ minHeight: 32 })
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  nationalHolidayBuilderLayout() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
    }
    .flexShrink(0)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: $r('sys.float.padding_level4') })
    Row() {
      Flex({
        justifyContent: this.isChangeLayout() ? FlexAlign.Start
          : FlexAlign.End, wrap: FlexWrap.Wrap
      }) {
        ForEach(this.formatExtraInfo(), (info: string) => {
          Text(info)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ left: this.isChangeLayout() ? 0 : 4, right: 4 })
        })
      }
      .layoutWeight(1)

      Row() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: $r('sys.float.padding_level2') })
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 24 })
      .clip(true)
    }
    .flexShrink(0)
    .width('100%' )
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  weekendsSettingBuilderLayout() {
    Column() {
      this.nationalHolidayBuilderLayout();
    }
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
    .onClick(event => {
      if (this.openDialog) {
        this.openDialog(this.settingKey);
      }
    })
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .id(this.compId)
  }

  build() {
    if (this.isChangeLayout()) {
      this.weekendsSettingBuilderLayout()
    } else {
      Row() {
        this.weekendsSettingBuilder();
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .constraintSize({
        minHeight: this.rowMinHeight
      })
      .padding({
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
      .focusBox({ margin: LengthMetrics.vp(-2) })
      .onClick(event => {
        if (this.openDialog) {
          this.openDialog(this.settingKey);
        }
      })
      .id(this.compId)
    }
  }

  aboutToAppear() {
    this.displayWeekends = [...this.weekends];
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_WEEKENDS }, this.weekendsChangeHandler);
    this?.onMounted();
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  private weekendsChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const weekends = AppStorage.get<number[]>(GlobalDataKeys.WEEKENDS) ?? [-1];
    this.displayWeekends = [...weekends];
  };

  private onWeekendsChange(): void {
    this.displayWeekends = [...this.weekends];
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 格式化附加信息
  private formatExtraInfo(): ResourceStr[] {
    let result: ResourceStr[] = [];
    const legalWeekends = this.displayWeekends.filter((item: number) => (item !== -1)).sort();
    legalWeekends.forEach((day: number) => {
      startOfWeekOptions.forEach((option: RadioListDialogOption) => {
        if (option.value === day) {
          result.push(option.label)
        }
      })
    })
    return result;
  };

  // 打开弹框
  private openDialog: Function = () => {
  };
}