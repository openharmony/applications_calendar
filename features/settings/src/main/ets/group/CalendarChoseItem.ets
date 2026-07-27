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
import { currentSupportOptions as subscriptionCalendarOptions } from '../data/calendar/CalendarConfig';
import { SubscriptionCalendar } from '../dialogs/SubscriptionCalendar';
import { LengthMetrics } from '@kit.ArkUI';

@Component
export struct CalendarChoseItem {
  @Consume navPathStack: NavPathStack;

  // 其它历法 - 直接绑定AppStorage，不依赖@Link链传递
  @StorageLink('subscriptionCalendar') @Watch('onCalendarChange') subscriptionCalendar: number = -1;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State menuShow: boolean = false;

  // 用于UI刷新的显示值
  @State displayCalendarValue: number = -1;

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
  choseItemBuilder() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 8 })
      }
    }
    .flexShrink(this.isChangeLayout() ? 0 : 1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: 8 })

    Row() {
      Text(subscriptionCalendarOptions.find(item => item.value === this.displayCalendarValue)?.label)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SIX,
          14
        ))
        .fontColor($r('sys.color.font_tertiary'))
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
    }.flexShrink(this.isChangeLayout() ? 0 : 1)
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }



  @Builder
  ChoseItemVerticalLayout() {
    Column() {
      this.choseItemBuilder();
    }
    .bindMenu(this.menuShow, this.buildMenu(), {
      placement: Placement.BottomRight,
      onDisappear: () => {
        this.menuShow = false;
      }
    })
    .onClick(() => {
      this.menuShow = true;
    })
    .borderRadius(14)
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None) // 适老化垂直布局
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.SpaceBetween)
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
        .backgroundColor(this.action !== eventAction.SWITCH
          ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
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
      SubscriptionCalendar({
        callback: (value) => {
          this.subscriptionCalendar = value;
          this.displayCalendarValue = value;
          this.menuShow = false;
        }
      })
    }
    .width(224)
  }

  build() {
    Column() {
      if (this.isChangeLayout()) {
        this.ChoseItemVerticalLayout();
      } else {
        Row() {
          this.choseItemBuilder();
        }
        .bindMenu(this.menuShow, this.buildMenu(), {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.menuShow = false;
          }
        })
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
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(14)
        .id(this.compId)
        .onClick(() => {
          this.menuShow = true;
        })
        .focusBox({ margin: LengthMetrics.vp(-2) })
      }
    }.width('100%')
  }

  aboutToAppear() {
    this.displayCalendarValue = this.subscriptionCalendar;
    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_STATUSBAR }, () => {
      this.menuShow = false;
    });
    this?.onMounted();
  }

  private onCalendarChange(): void {
    this.displayCalendarValue = this.subscriptionCalendar;
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 格式化附加信息
  private formatExtraInfo(): ResourceStr | undefined {
    return subscriptionCalendarOptions.find(item => {
      return item.value === this.subscriptionCalendar;
    })?.label;
  }

  // 打开弹框
  private openDialog: Function = () => {
  };
}
