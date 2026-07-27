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
import { AllDayEventsDefaultRemindTime } from '../dialogs/AllDayEventsDefaultRemindTime';
import { BigFontSize, CommonInnerEvent, DeviceConfig, EmitterCollector, FontSizeScaleUtils } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { DEFAULT_ALL_DAY_REMINDER_OPTIONS } from '@app/common.components';

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct DefaultReminderTimeForAllDayEvent {
  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') @Watch('onAllDayEventsDefaultRemindTimeChange') allDayEventsDefaultRemindTime: number = 0;

  @State displayAllDayEventsDefaultRemindTime: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

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

  @State menuShow: boolean = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  // 格式化附加信息
  formatExtraInfo() {
    return DEFAULT_ALL_DAY_REMINDER_OPTIONS.find(item => {
      return item.value === this.displayAllDayEventsDefaultRemindTime;
    })?.label;
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  buildContent() {
    Column() {
      Text(this.title)
        .minFontSize(10)
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
      Text(this.formatExtraInfo())
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
        .layoutWeight(this.isChangeLayout() ? 1 : undefined)
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
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  ContentVerticalLayout() {
    Column() {
      this.buildContent()
    }
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
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
      AllDayEventsDefaultRemindTime({
        callback: (value: number) => {
          this.displayAllDayEventsDefaultRemindTime = value;
          this.menuShow = false;
        }
      })
    }
    .width(224)
  }

  build() {
    Row() {
      this.ContentVerticalLayout();

      Row() {
        this.buildContent()
      }
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
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
    }
    .bindMenu(this.menuShow, this.buildMenu(), {
      placement: Placement.BottomRight,
      onDisappear: () => {
        this.menuShow = false;
      }
    })
    // 绑定空点击事件用于触发走焦框的显示
    .onClick(() => {
      this.menuShow = true;
    })
    .borderRadius(14)
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .width('100%')
  }

  aboutToAppear() {
    this.displayAllDayEventsDefaultRemindTime = this.allDayEventsDefaultRemindTime;
    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_STATUSBAR }, () => {
      this.menuShow = false;
    });
    this?.onMounted();
  }

  private onAllDayEventsDefaultRemindTimeChange(): void {
    this.displayAllDayEventsDefaultRemindTime = this.allDayEventsDefaultRemindTime;
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 打开弹框回调
  private openDialog: Function = () => {
  };
}
